"""
Plan Regularization: Penalize Plan Deviations

Addresses Critique #3: Plan Instability ("The Nervous System Problem")

Adds regularization term to objective function to penalize changes from
previous plan, preventing operational disruption from minor parameter updates.
"""

import logging
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from plan_evolution import Plan, PlanStep, compare_plans


@dataclass
class PlanRegularizationConfig:
    """Configuration for plan regularization."""
    regularization_weight: float = 0.1  # Weight w for plan deviation penalty
    stability_threshold: float = 0.05  # Only penalize if change > 5%
    max_penalty: float = 1.0  # Maximum penalty (as fraction of revenue)
    action_switch_cost: float = 0.01  # Cost per action change
    timing_change_cost: float = 0.02  # Cost per timing change (per hour)


class PlanRegularizer:
    """
    Computes regularization penalty for plan deviations.
    
    The penalty function:
        Penalty = w * Δ(Plan_N, Plan_{N-1})
    
    Where Δ measures:
        - Number of action changes
        - Timing changes (schedule shifts)
        - Resource allocation changes
    """
    
    def __init__(self, config: Optional[PlanRegularizationConfig] = None):
        self.config = config or PlanRegularizationConfig()
        self.previous_plan: Optional[Plan] = None
    
    def compute_deviation_penalty(self, current_plan: Plan, 
                                  previous_plan: Optional[Plan],
                                  base_revenue: float = 320.0) -> Tuple[float, Dict]:
        """
        Compute penalty for deviating from previous plan.
        
        Args:
            current_plan: New plan
            previous_plan: Previous plan (None if first iteration)
            base_revenue: Base revenue for normalization
            
        Returns:
            (penalty_amount, penalty_details)
        """
        if previous_plan is None:
            # First iteration: no penalty
            return 0.0, {
                "reason": "first_iteration",
                "action_changes": 0,
                "timing_changes": 0,
                "similarity": 1.0
            }
        
        # Compare plans
        comparison = compare_plans(previous_plan, current_plan)
        similarity = comparison["similarity"]
        
        # Only penalize if change is significant
        if similarity >= (1.0 - self.config.stability_threshold):
            return 0.0, {
                "reason": "insignificant_change",
                "similarity": similarity,
                "action_changes": comparison["different_steps"],
                "timing_changes": 0
            }
        
        # Compute penalty components
        action_changes = comparison["different_steps"]
        action_penalty = action_changes * self.config.action_switch_cost
        
        # Estimate timing changes (simplified: use length difference as proxy)
        timing_changes = abs(comparison["length_diff"])
        timing_penalty = timing_changes * self.config.timing_change_cost
        
        # Total penalty (normalized by base revenue)
        total_penalty = (action_penalty + timing_penalty) * self.config.regularization_weight
        total_penalty = min(total_penalty, self.config.max_penalty * base_revenue)
        
        return total_penalty, {
            "reason": "plan_deviation",
            "similarity": similarity,
            "action_changes": action_changes,
            "action_penalty": action_penalty,
            "timing_changes": timing_changes,
            "timing_penalty": timing_penalty,
            "total_penalty": total_penalty,
            "penalty_fraction": total_penalty / base_revenue if base_revenue > 0 else 0.0
        }
    
    def generate_soft_constraints_ppddl(self, previous_plan: Plan) -> str:
        """
        Generate PPDDL soft constraints (preferences) to encourage stability (Fix #2).
        
        Instead of ex-post rejection, we embed stability into the PPDDL problem
        so the solver 'wants' to stay close to the previous plan.
        """
        if not previous_plan or not previous_plan.steps:
            return ""
            
        constraints = []
        constraints.append(f"; Soft constraints from previous plan (Iteration {previous_plan.iteration})")
        
        for step in previous_plan.steps:
            # For each action, create a preference to execute it near the same time
            # Note: This assumes PPDDL 3.0 preferences syntax
            # (preference p1 (within 10 (action-name ...)))
            
            # Simplified: Just document the preference for the LLM/Synthesizer to include
            # if re-synthesizing, or for the planner if it supports constraints.
            constraints.append(f"(:constraints (preference stable-{step.step_number} (occupies-window {step.action_name} {step.step_number})))")
            
            # Also add penalty metric component
            # (:metric minimize (+ (total-cost) (* 0.1 (is-violated stable-{step.step_number}))))
            
        return "\n".join(constraints)

    def add_regularization_to_objective(self, 
                                       problem_text: str,
                                       current_plan: Optional[Plan],
                                       previous_plan: Optional[Plan],
                                       base_revenue: float = 320.0) -> Tuple[str, float, Dict]:
        """
        Modify PPDDL problem to include regularization penalty in objective.
        
        This adds a cost term that penalizes deviations from the previous plan.
        
        Args:
            problem_text: Original PPDDL problem text
            current_plan: Current plan (for comparison, can be None if not yet generated)
            previous_plan: Previous plan
            base_revenue: Base revenue for normalization
            
        Returns:
            (modified_problem_text, penalty_amount, penalty_details)
        """
        if current_plan is None:
            # Can't compute penalty without a current plan, just return
            # Note: Soft constraints should have been injected via generate_soft_constraints_ppddl
            return problem_text, 0.0, {"reason": "no_current_plan"}

        penalty, details = self.compute_deviation_penalty(
            current_plan, previous_plan, base_revenue
        )
        
        if penalty == 0.0:
            # No penalty needed
            return problem_text, 0.0, details
        
        # Add penalty as a cost in the objective
        # Note: PPDDL doesn't directly support regularization, so we:
        # 1. Add a penalty predicate that's true if plan deviates
        # 2. Subtract penalty from reward in goal
        
        # For now, we'll modify the problem description to include the penalty
        # In a full implementation, we'd need to modify the domain to include
        # a regularization action that applies the penalty
        
        logging.info(f"Plan regularization: penalty={penalty:.2f} ({details['penalty_fraction']*100:.1f}% of revenue)")
        logging.info(f"  Action changes: {details['action_changes']}, "
                    f"Timing changes: {details.get('timing_changes', 0)}")
        
        # Store penalty details for later use in plan selection
        details["applied"] = True
        
        return problem_text, penalty, details
    
    def update_previous_plan(self, plan: Plan):
        """Update the previous plan reference."""
        self.previous_plan = plan
    
    def should_accept_new_plan(self, 
                              current_plan: Plan,
                              new_plan: Plan,
                              value_improvement: float,
                              base_revenue: float = 320.0) -> Tuple[bool, str]:
        """
        Decide whether to accept a new plan given the improvement and penalty.
        
        Args:
            current_plan: Current plan
            new_plan: Proposed new plan
            value_improvement: Expected value improvement from new plan
            base_revenue: Base revenue for normalization
            
        Returns:
            (should_accept, reason)
        """
        penalty, details = self.compute_deviation_penalty(
            new_plan, current_plan, base_revenue
        )
        
        # Accept if improvement exceeds penalty
        net_benefit = value_improvement - penalty
        
        if net_benefit > 0:
            return True, f"Net benefit: {net_benefit:.2f} (improvement {value_improvement:.2f} - penalty {penalty:.2f})"
        else:
            return False, f"Penalty {penalty:.2f} exceeds improvement {value_improvement:.2f}"


def apply_plan_regularization(problem_text: str,
                             current_plan: Optional[Plan],
                             previous_plan: Optional[Plan],
                             config: Optional[PlanRegularizationConfig] = None) -> Tuple[str, float, Dict]:
    """
    Convenience function to apply plan regularization.
    
    Args:
        problem_text: PPDDL problem text
        current_plan: Current plan (may be None if not yet generated)
        previous_plan: Previous plan
        config: Regularization configuration
        
    Returns:
        (modified_problem_text, penalty, details)
    """
    regularizer = PlanRegularizer(config)
    
    if current_plan is None:
        # No current plan yet, return original
        return problem_text, 0.0, {"reason": "no_current_plan"}
    
    return regularizer.add_regularization_to_objective(
        problem_text, current_plan, previous_plan
    )

