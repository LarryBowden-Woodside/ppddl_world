
import numpy as np
from dataclasses import dataclass
from typing import Optional, Tuple, Dict, List
import json
import os
import logging

try:
    from neurosym import NeuroSymGraph, NodeKind, EdgeKind, build_rover_neurosym_graph
    _HAS_NESY = True
except ImportError:
    _HAS_NESY = False
    logging.warning("neurosym_addons not available. Graph integration disabled.")

# Configuration
TRUE_COST = 2.0  # True cost: 2% battery per minute saved
INITIAL_BATTERY = 60  # Starting battery level


@dataclass
class LearningResult:
    """Results from parameter learning with uncertainty quantification."""
    estimated_cost: float
    true_cost: float
    r_squared: float
    fit_quality: float  # 0-1 confidence in fit quality
    uncertainty: float = 0.0  # Standard error of the estimate
    confidence_interval: Tuple[float, float] = (0.0, 0.0)  # 95% CI
    variance: float = 0.0  # Parameter variance


def simulate_rover_runs(n: int = 30, true_cost: float = TRUE_COST,
                        noise_std: float = 1.0) -> Tuple[np.ndarray, np.ndarray]:
    """
    Simulate rover runs with energy cost model.
    
    Model: battery_after = 60 - k * (40 - drive_time)
    where k is the cost per minute saved.
    
    Returns:
        drive_times: Array of drive times (30-40 minutes)
        battery_end: Array of battery levels after driving
    """
    drive_times = np.random.uniform(30, 40, n)
    battery_end = INITIAL_BATTERY - true_cost * (40 - drive_times)
    battery_end += np.random.normal(0, noise_std, n)
    battery_end = np.clip(battery_end, 0, 100)
    return drive_times, battery_end


def learn_cost_parameter(drive_times: np.ndarray, battery_end: np.ndarray) -> LearningResult:
    """
    Learn the energy cost parameter from observed data with uncertainty quantification.
    
    Fits: battery_end = 60 - k*(40 - drive_time)
    which rearranges to: (60 - battery_end) = k*(40 - drive_time)
    
    Returns:
        LearningResult with estimated cost, fit quality, and uncertainty metrics
    """
    X = (40 - drive_times).reshape(-1, 1)
    y = (INITIAL_BATTERY - battery_end)
    
    n = len(X)
    if n < 2:
        # Not enough data for uncertainty estimation
        return LearningResult(
            estimated_cost=2.0,
            true_cost=TRUE_COST,
            r_squared=0.0,
            fit_quality=0.0,
            uncertainty=1.0,
            confidence_interval=(0.0, 4.0),
            variance=1.0
        )
    
    # Least squares estimation
    k_est, residuals, rank, s = np.linalg.lstsq(X, y, rcond=None)
    k_est = k_est[0]
    
    # Prediction and residuals
    y_pred = k_est * X.flatten()
    residuals_vec = y - y_pred
    
    # R-squared
    ss_res = np.sum(residuals_vec ** 2)
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0.0
    
    # Uncertainty quantification
    # Standard error of the estimate
    mse = ss_res / (n - 1) if n > 1 else ss_res
    x_mean = np.mean(X)
    x_var = np.var(X.flatten())
    
    # Standard error of coefficient
    if x_var > 0 and n > 1:
        se_k = np.sqrt(mse / (x_var * n))
        # 95% confidence interval (t-distribution, approximate with normal for n>30)
        t_critical = 1.96 if n > 30 else 2.0  # Approximate
        ci_lower = k_est - t_critical * se_k
        ci_upper = k_est + t_critical * se_k
        variance = se_k ** 2
    else:
        se_k = np.sqrt(mse) if mse > 0 else 1.0
        ci_lower = k_est - 2 * se_k
        ci_upper = k_est + 2 * se_k
        variance = se_k ** 2
    
    # Fit quality (inverse of relative uncertainty)
    relative_uncertainty = abs(se_k / k_est) if abs(k_est) > 0.01 else 1.0
    fit_quality = max(0.0, min(1.0, 1.0 / (1.0 + relative_uncertainty)))
    
    return LearningResult(
        estimated_cost=k_est,
        true_cost=TRUE_COST,
        r_squared=r_squared,
        fit_quality=fit_quality,
        uncertainty=se_k,
        confidence_interval=(ci_lower, ci_upper),
        variance=variance
    )


def update_neurosym_graph(graph: NeuroSymGraph, result: LearningResult, n_samples: int = 30) -> Optional[int]:
    """
    Update the NeuroSym graph with learned evidence.
    
    Adds a new EVIDENCE node with the learned parameter and creates
    a SUPPORTS edge to the drive cost constraint node.
    
    Args:
        graph: The NeuroSym graph
        result: LearningResult with learned parameters
        n_samples: Number of samples used for learning
        
    Returns:
        ID of the created evidence node, or None if update failed
    """
    if not _HAS_NESY:
        return None
    
    try:
        drive_constraint_id = None
        for node_id, node in graph.nodes.items():
            if (node.kind == NodeKind.CONSTRAINT and 
                "costs" in node.label.lower() and "minute" in node.label.lower()):
                drive_constraint_id = node_id
                break
        
        if drive_constraint_id is None:
            return None
        
        evidence_label = (
            f"Learned from {n_samples} runs: "
            f"energy cost = {result.estimated_cost:.2f}% per minute saved "
            f"(R²={result.r_squared:.3f})"
        )
        
        evidence_id = graph.add_node(
            NodeKind.EVIDENCE,
            evidence_label,
            confidence=result.fit_quality,
            attributes={
                "estimated_cost": result.estimated_cost,
                "true_cost": result.true_cost,
                "r_squared": result.r_squared,
                "fit_quality": result.fit_quality,
                "n_samples": n_samples
            }
        )
        
        graph.add_edge(
            evidence_id,
            drive_constraint_id,
            EdgeKind.SUPPORTS,
            weight=result.fit_quality
        )
        
        constraint_node = graph.nodes[drive_constraint_id]
        new_confidence = min(0.99, constraint_node.confidence + (result.fit_quality * 0.1))
        constraint_node.confidence = new_confidence
        
        graph.propagate_beliefs()
        
        return evidence_id
        
    except Exception as e:
        logging.error(f"Failed to update NeuroSym graph: {e}")
        return None


def overlay_learned_cost(domain_text: str, learned_cost: float, uncertainty: float = 0.1, 
                        use_uncertainty_in_effects: bool = True) -> str:
    """
    Inject the learned cost parameter into a PPDDL drive action with uncertainty-aware probabilistic effects.
    
    Creates a probabilistic drive action that accounts for:
    - Normal energy consumption (probability based on uncertainty)
    - Higher energy consumption due to terrain/conditions (probability based on uncertainty)
    - Uncertainty-based probability distribution
    
    Args:
        domain_text: PPDDL domain text
        learned_cost: Learned energy cost parameter
        uncertainty: Uncertainty factor (default 0.1 = 10% variation)
        use_uncertainty_in_effects: If True, use uncertainty to set probabilities
    """
    # Calculate probabilistic outcomes based on uncertainty
    if use_uncertainty_in_effects and uncertainty > 0:
        # Higher uncertainty -> more probability of adverse outcomes
        # Normalize uncertainty to [0, 1] range (assuming max uncertainty ~0.5)
        uncertainty_normalized = min(1.0, uncertainty / 0.5)
        # Probability of normal outcome decreases with uncertainty
        prob_normal = max(0.5, 1.0 - uncertainty_normalized * 0.3)  # 0.5 to 0.95
        prob_adverse = 1.0 - prob_normal
    else:
        prob_normal = 0.9
        prob_adverse = 0.1
    
    normal_cost = learned_cost
    high_cost = learned_cost * (1.0 + uncertainty * 2.0)  # Higher in bad conditions
    
    marker = ":action drive"
    if marker in domain_text:
        # Replace existing drive action with probabilistic version
        # Find the drive action block (handle nested parentheses)
        import re
        
        # Match from :action drive to the closing paren of the action
        # This pattern finds the start and matches balanced parentheses
        start_pattern = r'\(:action drive'
        start_match = re.search(start_pattern, domain_text)
        
        if start_match:
            start_pos = start_match.start()
            # Find matching closing paren by counting
            paren_count = 0
            pos = start_pos
            while pos < len(domain_text):
                if domain_text[pos] == '(':
                    paren_count += 1
                elif domain_text[pos] == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        # Found the closing paren
                        end_pos = pos + 1
                        break
                pos += 1
            else:
                end_pos = len(domain_text)
            
            # Build probabilistic drive action using whenp syntax (probabilistic-ff format)
            # Use types that exist in the domain: automaton, state, time
            # Probabilities reflect uncertainty: higher uncertainty -> more adverse outcomes
            probabilistic_drive = f"""    (:action drive
        :parameters (?r - automaton ?dest - state ?duration - time)
        :precondition (and
            (at ?r ?dest)
        )
        :effect (and
            ; Normal conditions: {prob_normal:.2f} probability (uncertainty={uncertainty:.3f})
            (whenp {prob_normal:.2f} (and
                (at ?r connected)
            ))
            ; Adverse conditions: {prob_adverse:.2f} probability (uncertainty={uncertainty:.3f})
            (whenp {prob_adverse:.2f} (and
                (at ?r error_state)
            ))
        )
    )"""
            
            # Replace the action
            domain_text = domain_text[:start_pos] + probabilistic_drive + domain_text[end_pos:]
        else:
            # Fallback: just add comment
            domain_text = domain_text.replace(
                marker,
                f"{marker}\n        ; learned energy cost ~ {learned_cost:.2f}% per minute saved (probabilistic)",
                1,
            )
        return domain_text

    # If no drive action exists, inject a probabilistic one INSIDE the domain
    # Find the last closing paren (end of domain) and insert before it
    last_paren = domain_text.rstrip().rfind(")")
    if last_paren == -1:
        # Fallback: append at end
        return domain_text + f"\n    (:action drive ...)\n"
    
    # Insert the action before the final closing paren
    # Use whenp syntax for probabilistic-ff (no numeric fluents)
    # Use types that exist in the domain: automaton, state, time
    before_close = domain_text[:last_paren].rstrip()
    probabilistic_drive = f"""
    (:action drive
        :parameters (?r - automaton ?dest - state ?duration - time)
        :precondition (and
            (at ?r ?dest)
        )
        :effect (and
            ; Normal conditions: {prob_normal:.2f} probability (uncertainty={uncertainty:.3f})
            (whenp {prob_normal:.2f} (and
                (at ?r connected)
            ))
            ; Adverse conditions: {prob_adverse:.2f} probability (uncertainty={uncertainty:.3f})
            (whenp {prob_adverse:.2f} (and
                (at ?r error_state)
            ))
        )
    )"""
    
    return before_close + probabilistic_drive + "\n" + domain_text[last_paren:]

