"""
LNG Offtake Demo: Executive Demonstration

This demo showcases the probabilistic planning system applied to real-world
LNG offtake optimization with uncertainty in quality, vessel arrivals, and spot prices.

Three approaches are compared:
1. Baseline: Pure LLM synthesis (natural language → PPDDL)
2. Hybrid: CTBurton + LLM (structured constraints → PPDDL)
3. Adaptive: Continuous learning with HHV uncertainty

Usage:
    # Quick demo (baseline only)
    python lng_offtake_demo.py --approach baseline
    
    # Compare all approaches
    python lng_offtake_demo.py --approach all --compare
    
    # Adaptive learning with visualization
    python lng_offtake_demo.py --approach adaptive --live-viz --iterations 10
"""

import os
import sys
import json
import logging
import argparse
import time
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional
import numpy as np

# Import core modules
import agent as sa
from ctburton import CTBurtonConverter
from problem import (
    create_lng_offtake_ctburton_problem,
    get_lng_offtake_learned_parameters,
    get_lng_offtake_kpis
)
from translator import hybrid_ctburton_llm_ppddl
from ppddl_postprocess import fix_ppddl_syntax

# Import learning modules
from world_model_learning import LearningResult
from plan_evolution import PlanEvolutionTracker, extract_plan_from_output
from transfer_learning import ModelRegistry

# Import robustness fixes
from robustness.pipeline import RobustnessPipeline

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)


def simulate_hhv_observations(
    n_samples: int,
    train: int = 1,
    true_mean: float = 1090.0,
    true_std: float = 10.0
) -> np.ndarray:
    """
    Simulate HHV observations for a train.
    
    In production, these would be real measurements from the plant.
    
    Args:
        n_samples: Number of observations to simulate
        train: Train number (1 or 2)
        true_mean: True mean HHV (unknown to learner initially)
        true_std: True standard deviation
        
    Returns:
        Array of HHV observations
    """
    # Add measurement noise
    observations = np.random.normal(true_mean, true_std, n_samples)
    return observations


def learn_hhv_distribution(
    observations: np.ndarray,
    prior_mean: float = 1090.0,
    prior_std: float = 10.0
) -> Tuple[float, float, float]:
    """
    Learn HHV distribution from observations using Bayesian updating.
    
    Args:
        observations: Observed HHV values
        prior_mean: Prior mean estimate
        prior_std: Prior standard deviation
        
    Returns:
        Tuple of (posterior_mean, posterior_std, confidence)
    """
    n = len(observations)
    if n == 0:
        return prior_mean, prior_std, 0.0
    
    # Bayesian update with normal-normal conjugate prior
    sample_mean = np.mean(observations)
    sample_std = np.std(observations) if n > 1 else prior_std
    
    # Simple Bayesian update (assuming known variance for simplicity)
    # In production, use full Bayesian inference
    posterior_mean = (prior_mean / prior_std**2 + n * sample_mean / sample_std**2) / \
                     (1 / prior_std**2 + n / sample_std**2)
    posterior_var = 1 / (1 / prior_std**2 + n / sample_std**2)
    posterior_std = np.sqrt(posterior_var)
    
    # Confidence based on sample size
    confidence = min(0.95, 0.5 + 0.45 * (n / 100))  # Asymptotes to 0.95
    
    return posterior_mean, posterior_std, confidence


def run_baseline_approach(
    problem_text: str,
    output_dir: Path
) -> Dict[str, Any]:
    """
    Baseline approach: Pure LLM synthesis from natural language.
    
    This is the simplest approach - just give the LLM the problem description
    and let it generate PPDDL directly.
    
    Args:
        problem_text: Natural language problem description
        output_dir: Directory to save outputs
        
    Returns:
        Results dictionary
    """
    logging.info("\n" + "=" * 80)
    logging.info("BASELINE APPROACH: Pure LLM Synthesis")
    logging.info("=" * 80)
    
    start_time = time.time()
    
    # Generate PPDDL using SystemAgent's cognitive pipeline
    logging.info("Generating PPDDL candidates...")
    
    # Step 1: Extract variables
    variable_template = (
        "Extract PPDDL types, predicates, and functions from the LNG offtake problem below.\n"
        "Focus on:\n"
        "- Types: trains, tanks, vessels, cargoes, time periods\n"
        "- Predicates: states (tank levels, berth occupied, vessel arrived)\n"
        "- Functions: numeric fluents (HHV, volume, revenue, costs)\n\n"
        "Problem:\n\n{problem_text}"
    )
    
    variable_candidates = sa.generate_candidates(variable_template, problem_text, num_candidates=3)
    aggregated_variables = sa.aggregate_candidates(
        variable_candidates,
        "Aggregate into a consistent PPDDL type/predicate/function list for LNG offtake."
    )
    
    # Step 2: Extract constraints
    constraint_template = (
        "Extract PPDDL constraints and action preconditions from the LNG offtake problem.\n"
        "Focus on:\n"
        "- Tank capacity limits and connectivity\n"
        "- Berth scheduling (no overlap, turnaround time)\n"
        "- Laycan windows for term contracts\n"
        "- HHV quality specifications\n"
        "- Tidal restrictions\n\n"
        "Problem:\n\n{problem_text}"
    )
    
    constraint_candidates = sa.generate_candidates(constraint_template, problem_text, num_candidates=3)
    aggregated_constraints = sa.aggregate_candidates(
        constraint_candidates,
        "Aggregate into coherent PPDDL action preconditions and invariants."
    )
    
    # Step 3: Extract objectives
    objective_template = (
        "Formulate PPDDL reward structure for LNG offtake optimization.\n"
        "The objective is to maximize expected net value:\n"
        "- Revenues from term and spot cargoes\n"
        "- Costs (demurrage, boil-off)\n"
        "- Penalties (off-spec HHV, tank-top events)\n"
        "- Probabilistic effects for uncertainties\n\n"
        "Problem:\n\n{problem_text}"
    )
    
    objective_candidates = sa.generate_candidates(objective_template, problem_text, num_candidates=3)
    aggregated_objective = sa.aggregate_candidates(
        objective_candidates,
        "Aggregate into a single PPDDL reward formulation."
    )
    
    # Step 4: Synthesize PPDDL
    logging.info("Synthesizing PPDDL domain and problem...")
    domain_text, problem_text_ppddl = sa.synthesizer_module_ppddl(
        aggregated_variables,
        aggregated_constraints,
        aggregated_objective
    )
    
    # Post-process
    domain_text, problem_text_ppddl = fix_ppddl_syntax(domain_text, problem_text_ppddl)
    
    elapsed_time = time.time() - start_time
    
    # Save outputs
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "domain_baseline.ppddl").write_text(domain_text, encoding="utf-8")
    (output_dir / "problem_baseline.ppddl").write_text(problem_text_ppddl, encoding="utf-8")
    
    logging.info(f"✓ Baseline synthesis complete in {elapsed_time:.2f}s")
    logging.info(f"  Domain: {len(domain_text)} chars")
    logging.info(f"  Problem: {len(problem_text_ppddl)} chars")
    
    # Run planner
    logging.info("Running planner on baseline PPDDL...")
    planner_success, planner_output = sa.run_ppddl_planner(domain_text, problem_text_ppddl)
    
    (output_dir / "planner_output_baseline.txt").write_text(planner_output, encoding="utf-8")
    
    return {
        "approach": "baseline",
        "domain": domain_text,
        "problem": problem_text_ppddl,
        "planner_success": planner_success,
        "planner_output": planner_output,
        "synthesis_time": elapsed_time,
        "domain_size": len(domain_text),
        "problem_size": len(problem_text_ppddl)
    }


def run_hybrid_approach(
    problem_text: str,
    ctburton_problem: Any,
    output_dir: Path
) -> Dict[str, Any]:
    """
    Hybrid approach: CTBurton → MiniZinc → LLM → PPDDL.
    
    This approach uses CTBurton to extract constraints deterministically,
    reducing LLM hallucination.
    
    Args:
        problem_text: Natural language problem description
        ctburton_problem: Structured CTBurton problem
        output_dir: Directory to save outputs
        
    Returns:
        Results dictionary
    """
    logging.info("\n" + "=" * 80)
    logging.info("HYBRID APPROACH: CTBurton + LLM")
    logging.info("=" * 80)
    
    start_time = time.time()
    
    # Use hybrid conversion
    logging.info("Converting CTBurton → MiniZinc → PPDDL via LLM...")
    domain_text, problem_text_ppddl = hybrid_ctburton_llm_ppddl(
        problem_text,
        ctburton_problem,
        learned_parameters=None  # No learning in this phase
    )
    
    # Post-process
    domain_text, problem_text_ppddl = fix_ppddl_syntax(domain_text, problem_text_ppddl)
    
    elapsed_time = time.time() - start_time
    
    # Save outputs
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "domain_hybrid.ppddl").write_text(domain_text, encoding="utf-8")
    (output_dir / "problem_hybrid.ppddl").write_text(problem_text_ppddl, encoding="utf-8")
    
    logging.info(f"✓ Hybrid synthesis complete in {elapsed_time:.2f}s")
    logging.info(f"  Domain: {len(domain_text)} chars")
    logging.info(f"  Problem: {len(problem_text_ppddl)} chars")
    
    # Run planner
    logging.info("Running planner on hybrid PPDDL...")
    planner_success, planner_output = sa.run_ppddl_planner(domain_text, problem_text_ppddl)
    
    (output_dir / "planner_output_hybrid.txt").write_text(planner_output, encoding="utf-8")
    
    return {
        "approach": "hybrid",
        "domain": domain_text,
        "problem": problem_text_ppddl,
        "planner_success": planner_success,
        "planner_output": planner_output,
        "synthesis_time": elapsed_time,
        "domain_size": len(domain_text),
        "problem_size": len(problem_text_ppddl),
        "constraints_extracted": len(ctburton_problem.constraints)
    }


def run_adaptive_approach(
    problem_text: str,
    ctburton_problem: Any,
    output_dir: Path,
    n_iterations: int = 5,
    n_observations_per_iter: int = 10,
    live_viz: bool = False
) -> Dict[str, Any]:
    """
    Adaptive approach: Continuous learning with HHV uncertainty.
    
    This approach learns HHV distributions from observations and adapts
    the planning model over time.
    
    Args:
        problem_text: Natural language problem description
        ctburton_problem: Structured CTBurton problem
        output_dir: Directory to save outputs
        n_iterations: Number of adaptation iterations
        n_observations_per_iter: Observations per iteration
        live_viz: Enable live visualization
        
    Returns:
        Results dictionary
    """
    logging.info("\n" + "=" * 80)
    logging.info("ADAPTIVE APPROACH: Continuous Learning + HHV Uncertainty")
    logging.info("=" * 80)
    logging.info(f"Iterations: {n_iterations}, Observations per iteration: {n_observations_per_iter}")
    
    # Initialize robustness pipeline (with all fixes enabled)
    robustness = RobustnessPipeline(
        enable_model_checking=True,
        enable_kalman=True,  # Fix 1: Damped Trend
        enable_regularization=True,  # Fix 2: Soft Constraints
        use_bayesian_network=False,
        enable_safety_buffers=True,  # Fix 5: Safety Buffers
        enable_spot_bayes=True,      # Fix 4: Bayesian Spot Market
        enable_mcts=True,            # Fix 5: Solver Viability
        kalman_damping=0.9
    )
    
    # Initialize learning
    learnable_params = get_lng_offtake_learned_parameters()
    
    # Track learning history
    learning_history = []
    all_observations_train1 = []
    all_observations_train2 = []
    
    # Current estimates
    train1_mean = learnable_params["hhv_train1"]["initial_mean"]
    train1_std = learnable_params["hhv_train1"]["initial_std"]
    train2_mean = learnable_params["hhv_train2"]["initial_mean"]
    train2_std = learnable_params["hhv_train2"]["initial_std"]
    
    # True values (unknown to learner)
    train1_true_mean = 1088.0  # Slightly off from initial estimate
    train2_true_mean = 1062.0  # Slightly off from initial estimate
    
    plan_tracker = PlanEvolutionTracker()
    previous_plan = None  # For plan regularization
    
    # Adaptive loop
    for iteration in range(n_iterations):
        logging.info(f"\n--- Iteration {iteration + 1}/{n_iterations} ---")
        
        # 1. Observe: Get new HHV measurements
        obs_train1 = simulate_hhv_observations(
            n_observations_per_iter,
            train=1,
            true_mean=train1_true_mean,
            true_std=10.0
        )
        obs_train2 = simulate_hhv_observations(
            n_observations_per_iter,
            train=2,
            true_mean=train2_true_mean,
            true_std=10.0
        )
        
        all_observations_train1.extend(obs_train1)
        all_observations_train2.extend(obs_train2)
        
        # 2. Learn: Update HHV distributions using Kalman filter (non-stationary)
        # ROBUSTNESS FIX #2: Kalman filter tracks moving mean (trend-aware)
        train1_mean, train1_std, train1_conf, train1_trend = robustness.learn_hhv_robust(
            np.array(all_observations_train1),
            train=1,
            prior_mean=learnable_params["hhv_train1"]["initial_mean"],
            prior_std=learnable_params["hhv_train1"]["initial_std"]
        )
        
        train2_mean, train2_std, train2_conf, train2_trend = robustness.learn_hhv_robust(
            np.array(all_observations_train2),
            train=2,
            prior_mean=learnable_params["hhv_train2"]["initial_mean"],
            prior_std=learnable_params["hhv_train2"]["initial_std"]
        )
        
        learning_history.append({
            "iteration": iteration + 1,
            "n_observations": len(all_observations_train1),
            "train1_mean": train1_mean,
            "train1_std": train1_std,
            "train1_error": abs(train1_mean - train1_true_mean),
            "train1_confidence": train1_conf,
            "train1_trend": train1_trend,  # Kalman filter trend
            "train2_mean": train2_mean,
            "train2_std": train2_std,
            "train2_error": abs(train2_mean - train2_true_mean),
            "train2_confidence": train2_conf,
            "train2_trend": train2_trend  # Kalman filter trend
        })
        
        logging.info(f"  Train 1 HHV: {train1_mean:.1f} ± {train1_std:.1f} BTU/scf "
                    f"(true={train1_true_mean:.1f}, error={learning_history[-1]['train1_error']:.1f}, "
                    f"trend={train1_trend:.3f} BTU/scf per obs)")
        logging.info(f"  Train 2 HHV: {train2_mean:.1f} ± {train2_std:.1f} BTU/scf "
                    f"(true={train2_true_mean:.1f}, error={learning_history[-1]['train2_error']:.1f}, "
                    f"trend={train2_trend:.3f} BTU/scf per obs)")
        
        # Fix 4: Sample Spot Market from Bayesian Network
        spot_price, spot_available = robustness.sample_spot_market()
        logging.info(f"  Spot Market: Price=${spot_price:.1f}M, Available={spot_available}")
        
        # 3. Adapt: Regenerate PPDDL with learned parameters
        learned_params = {
            "hhv_train1": {
                "value": train1_mean,
                "uncertainty": train1_std,
                "confidence": train1_conf
            },
            "hhv_train2": {
                "value": train2_mean,
                "uncertainty": train2_std,
                "confidence": train2_conf
            }
        }
        
        # Update problem description with learned values
        adapted_problem_text = problem_text.replace(
            "Train 1 (Shell Mixed Refrigerant): 41-59% Field 1:Field 2 ratio (HHV: 1080-1100 BTU/scf, mean=1090, uncertainty ±10)",
            f"Train 1 (Shell Mixed Refrigerant): 41-59% Field 1:Field 2 ratio (HHV: {train1_mean-2*train1_std:.0f}-{train1_mean+2*train1_std:.0f} BTU/scf, mean={train1_mean:.0f}, uncertainty ±{train1_std:.0f})"
        ).replace(
            "Train 2 (ConocoPhillips Cascade): 100% Field 2, leaner gas (HHV: 1050-1070 BTU/scf, mean=1060, uncertainty ±10)",
            f"Train 2 (ConocoPhillips Cascade): 100% Field 2, leaner gas (HHV: {train2_mean-2*train2_std:.0f}-{train2_mean+2*train2_std:.0f} BTU/scf, mean={train2_mean:.0f}, uncertainty ±{train2_std:.0f})"
        )
        
        # Inject Spot Market Conditions (Fix 4)
        if not spot_available:
            adapted_problem_text += "\n(NOTE: Spot market unavailable due to high prices/tight supply.)"
            # In a real system, we'd update the PPDDL probabilistic effects here
        
        # Regenerate PPDDL
        domain_text, problem_text_ppddl = hybrid_ctburton_llm_ppddl(
            adapted_problem_text,
            ctburton_problem,
            learned_params
        )
        
        domain_text, problem_text_ppddl = fix_ppddl_syntax(domain_text, problem_text_ppddl)
        
        # ROBUSTNESS FIX #1: Model checking - verify MiniZinc invariants are enforced
        from ctburton import export_for_minizinc, create_unified_problem_format
        unified_format = create_unified_problem_format()
        unified_format['constraints'] = [
            {'type': 'temporal', 'description': c, 'expression': c} 
            for c in ctburton_problem.constraints
        ]
        minizinc_code = export_for_minizinc(unified_format)
        
        is_valid, violations = robustness.check_ppddl_translation(
            minizinc_code,
            ctburton_problem.constraints,
            domain_text
        )
        
        if violations:
            logging.warning(f"Found {len(violations)} constraint violations (non-critical for demo)")
            # In production, would regenerate or apply fixes
        
        # ROBUSTNESS FIX #5: Apply safety buffers for discretized variables
        domain_text, problem_text_ppddl = robustness.apply_safety_buffers(
            domain_text, problem_text_ppddl
        )
        
        # ROBUSTNESS FIX #3: Plan regularization (before planning)
        # Note: Full integration requires modifying PPDDL domain, so we track penalty for now
        current_plan_for_regularization = None  # Will be set after planning
        problem_text_ppddl, penalty, penalty_details = robustness.regularize_plan(
            problem_text_ppddl,
            current_plan_for_regularization,
            previous_plan
        )
        
        if penalty > 0:
            logging.info(f"  Plan regularization penalty: {penalty:.2f} ({penalty_details.get('penalty_fraction', 0)*100:.1f}% of revenue)")
        
        # 4. Plan: Run planner (using robustness wrapper for MCTS/Determinization admission)
        planner_success, planner_output = robustness.run_planner(domain_text, problem_text_ppddl)
        
        # Track plan evolution
        plan = extract_plan_from_output(planner_output)
        if plan:
            plan.iteration = iteration + 1
            plan.metadata = {
                "train1_mean": train1_mean,
                "train1_std": train1_std,
                "train2_mean": train2_mean,
                "train2_std": train2_std,
                "n_observations": len(all_observations_train1),
                "regularization_penalty": penalty,
                "penalty_details": penalty_details
            }
            plan_tracker.add_plan(plan, iteration + 1)
            
            # ROBUSTNESS FIX #3: Check if plan should be accepted given regularization
            if previous_plan and penalty > 0:
                # Estimate value improvement (simplified - in production would compute actual value)
                value_improvement = 0.0  # Placeholder
                should_accept, reason = robustness.plan_regularizer.should_accept_new_plan(
                    previous_plan, plan, value_improvement, base_revenue=320.0
                )
                if not should_accept:
                    logging.warning(f"  Plan rejected due to regularization: {reason}")
            
            previous_plan = plan  # Update for next iteration
            
            if plan.success:
                logging.info(f"  ✓ Plan found: {plan.plan_length} steps")
            else:
                logging.info(f"  ✗ No plan found")
    
    # Save final outputs
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "domain_adaptive.ppddl").write_text(domain_text, encoding="utf-8")
    (output_dir / "problem_adaptive.ppddl").write_text(problem_text_ppddl, encoding="utf-8")
    (output_dir / "planner_output_adaptive.txt").write_text(planner_output, encoding="utf-8")
    
    # Save learning history
    with open(output_dir / "learning_history.json", "w") as f:
        json.dump(learning_history, f, indent=2)
    
    logging.info(f"\n✓ Adaptive learning complete")
    logging.info(f"  Final Train 1 HHV: {train1_mean:.1f} ± {train1_std:.1f} BTU/scf")
    logging.info(f"  Final Train 2 HHV: {train2_mean:.1f} ± {train2_std:.1f} BTU/scf")
    logging.info(f"  Total observations: {len(all_observations_train1)}")
    
    return {
        "approach": "adaptive",
        "domain": domain_text,
        "problem": problem_text_ppddl,
        "planner_success": planner_success,
        "planner_output": planner_output,
        "learning_history": learning_history,
        "plan_evolution": plan_tracker,
        "final_train1_mean": train1_mean,
        "final_train1_std": train1_std,
        "final_train2_mean": train2_mean,
        "final_train2_std": train2_std,
        "convergence_train1": learning_history[-1]["train1_error"],
        "convergence_train2": learning_history[-1]["train2_error"],
        "robustness_enabled": True,
        "model_checking_violations": len(violations) if 'violations' in locals() else 0,
        "final_train1_trend": learning_history[-1].get("train1_trend", 0.0),
        "final_train2_trend": learning_history[-1].get("train2_trend", 0.0)
    }


def compare_approaches(results: List[Dict[str, Any]], output_dir: Path):
    """
    Compare results from different approaches.
    
    Args:
        results: List of result dictionaries from each approach
        output_dir: Directory to save comparison
    """
    logging.info("\n" + "=" * 80)
    logging.info("APPROACH COMPARISON")
    logging.info("=" * 80)
    
    comparison = {
        "approaches": [],
        "synthesis_time": {},
        "domain_size": {},
        "problem_size": {},
        "planner_success": {},
        "special_features": {}
    }
    
    for result in results:
        approach = result["approach"]
        comparison["approaches"].append(approach)
        comparison["synthesis_time"][approach] = result.get("synthesis_time", 0)
        comparison["domain_size"][approach] = result.get("domain_size", 0)
        comparison["problem_size"][approach] = result.get("problem_size", 0)
        comparison["planner_success"][approach] = result.get("planner_success", False)
        
        if approach == "hybrid":
            comparison["special_features"][approach] = {
                "constraints_extracted": result.get("constraints_extracted", 0),
                "hallucination_reduction": "Deterministic constraint extraction"
            }
        elif approach == "adaptive":
            comparison["special_features"][approach] = {
                "learning_iterations": len(result.get("learning_history", [])),
                "convergence_train1": result.get("convergence_train1", 0),
                "convergence_train2": result.get("convergence_train2", 0),
                "adaptive_planning": "HHV uncertainty learning"
            }
    
    # Print comparison
    print("\n" + "-" * 80)
    print("Metric Comparison:")
    print("-" * 80)
    print(f"{'Approach':<15} {'Time (s)':<12} {'Domain':<10} {'Problem':<10} {'Planner':<10}")
    print("-" * 80)
    
    for approach in comparison["approaches"]:
        time_val = comparison["synthesis_time"][approach]
        domain_val = comparison["domain_size"][approach]
        problem_val = comparison["problem_size"][approach]
        planner_val = "✓" if comparison["planner_success"][approach] else "✗"
        
        print(f"{approach:<15} {time_val:<12.2f} {domain_val:<10} {problem_val:<10} {planner_val:<10}")
    
    print("-" * 80)
    
    # Save comparison
    with open(output_dir / "comparison.json", "w") as f:
        json.dump(comparison, f, indent=2)
    
    logging.info(f"✓ Comparison saved to {output_dir / 'comparison.json'}")


def main():
    """Main entry point for LNG offtake demo."""
    parser = argparse.ArgumentParser(
        description="LNG Offtake Optimization Demo - Executive Demonstration"
    )
    parser.add_argument("--approach", choices=["baseline", "hybrid", "adaptive", "all"],
                       default="all", help="Which approach to run")
    parser.add_argument("--output-dir", type=str, default="lng_offtake_output",
                       help="Output directory")
    parser.add_argument("--iterations", type=int, default=5,
                       help="Number of adaptation iterations (adaptive only)")
    parser.add_argument("--obs-per-iter", type=int, default=10,
                       help="Observations per iteration (adaptive only)")
    parser.add_argument("--live-viz", action="store_true",
                       help="Enable live visualization (adaptive only)")
    parser.add_argument("--compare", action="store_true",
                       help="Generate comparison report")
    
    args = parser.parse_args()
    
    # Setup
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Load problem
    logging.info("Loading LNG offtake problem...")
    with open("config.json", "r") as f:
        config = json.load(f)
    
    problem_text = config["problem_templates"]["lng_offtake"]
    ctburton_problem = create_lng_offtake_ctburton_problem()
    
    logging.info(f"Problem: {ctburton_problem.name}")
    logging.info(f"Time horizon: {ctburton_problem.time_horizon} hours ({ctburton_problem.time_horizon/24:.0f} days)")
    
    # Run approaches
    results = []
    
    if args.approach in ["baseline", "all"]:
        result = run_baseline_approach(problem_text, output_dir)
        results.append(result)
    
    if args.approach in ["hybrid", "all"]:
        result = run_hybrid_approach(problem_text, ctburton_problem, output_dir)
        results.append(result)
    
    if args.approach in ["adaptive", "all"]:
        result = run_adaptive_approach(
            problem_text,
            ctburton_problem,
            output_dir,
            n_iterations=args.iterations,
            n_observations_per_iter=args.obs_per_iter,
            live_viz=args.live_viz
        )
        results.append(result)
    
    # Compare
    if args.compare and len(results) > 1:
        compare_approaches(results, output_dir)
    
    # Summary
    logging.info("\n" + "=" * 80)
    logging.info("DEMO COMPLETE")
    logging.info("=" * 80)
    logging.info(f"Results saved to: {output_dir}")
    logging.info(f"Approaches run: {[r['approach'] for r in results]}")
    logging.info("\nNext steps:")
    logging.info("  1. Review generated PPDDL files in output directory")
    logging.info("  2. Examine planner outputs for plan quality")
    logging.info("  3. Compare approaches using comparison.json")
    logging.info("  4. Review learning convergence in learning_history.json (adaptive)")
    
    return results


if __name__ == "__main__":
    main()

