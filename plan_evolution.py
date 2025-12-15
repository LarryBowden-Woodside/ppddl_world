"""
Plan Evolution Tracking

Tracks how plans change across adaptation iterations, enabling analysis of
plan convergence and evolution.
"""

import re
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
import logging


@dataclass
class PlanStep:
    """A single step in a plan."""
    step_number: int
    action_name: str
    parameters: List[str] = field(default_factory=list)
    
    def __str__(self):
        params_str = " ".join(self.parameters) if self.parameters else ""
        return f"{self.step_number}: {self.action_name} {params_str}".strip()
    
    def __eq__(self, other):
        if not isinstance(other, PlanStep):
            return False
        return (self.action_name == other.action_name and 
                self.parameters == other.parameters)


@dataclass
class Plan:
    """A complete plan with metadata."""
    iteration: int
    steps: List[PlanStep] = field(default_factory=list)
    raw_output: str = ""
    success: bool = False
    plan_length: int = 0
    metadata: Dict = field(default_factory=dict)
    
    def __str__(self):
        if not self.steps:
            return f"Plan (iteration {self.iteration}): No plan found"
        steps_str = "\n".join(str(step) for step in self.steps)
        return f"Plan (iteration {self.iteration}, length={self.plan_length}):\n{steps_str}"


def extract_plan_from_output(planner_output: str) -> Optional[Plan]:
    """Extract plan from probabilistic-ff output."""
    # probabilistic-ff output format varies, try multiple patterns
    plan_steps = []
    
    # Pattern 1: "step    0: START-DRIVING A0" and indented continuation lines
    # probabilistic-ff format:
    #   step    0: START-DRIVING A0
    #           1: ARRIVE A0
    #           2: DOCK A0
    lines = planner_output.split('\n')
    in_plan_section = False
    
    for line in lines:
        # Check if we're in the plan section
        if 'found legal plan' in line.lower():
            in_plan_section = True
            continue
        
        if in_plan_section:
            # Look for "step N: ACTION ..." or indented "N: ACTION ..."
            # Pattern: "step    0: ACTION" or "        1: ACTION"
            step_match = re.search(r'(?:step\s+)?(\d+):\s+([A-Za-z][A-Za-z0-9_-]+)(?:\s+([A-Za-z0-9_-]+(?:\s+[A-Za-z0-9_-]+)*))', line)
            if step_match:
                step_num = int(step_match.group(1))
                action_name = step_match.group(2).lower()
                params_str = step_match.group(3) if step_match.lastindex >= 3 and step_match.group(3) else ""
                # Filter out single-digit numbers (likely false positives from indentation)
                params = [p for p in params_str.split() if not (p.isdigit() and len(p) == 1)] if params_str else []
                
                plan_steps.append(PlanStep(
                    step_number=step_num,
                    action_name=action_name,
                    parameters=params
                ))
            # Stop when we hit statistics or other sections
            elif 'statistics:' in line.lower() or line.strip() and not line.strip().startswith(('step', ' ', '\t')):
                break
    
    # Pattern 2: Action lines with parentheses (common format)
    # Example: "0: (drive rover1 destination1)"
    if not plan_steps:
        action_pattern = r'(\d+):\s*\(([^\s]+)(?:\s+([^)]+))?\)'
        matches = re.findall(action_pattern, planner_output)
        
        for match in matches:
            step_num = int(match[0])
            action_name = match[1]
            params_str = match[2] if len(match) > 2 and match[2] else ""
            params = params_str.split() if params_str else []
            
            plan_steps.append(PlanStep(
                step_number=step_num,
                action_name=action_name,
                parameters=params
            ))
    
    # Pattern 2: Simple action list
    if not plan_steps:
        # Look for lines with action names
        lines = planner_output.split('\n')
        for i, line in enumerate(lines):
            line = line.strip()
            # Skip empty lines and common planner output
            if not line or line.startswith('ff:') or 'parsing' in line.lower():
                continue
            # Skip file paths (e.g., /tmp/tmp...)
            if line.startswith('/') or 'tmp' in line.lower():
                continue
            # Try to extract action
            action_match = re.search(r'\(?([a-z-]+)(?:\s+[^)]+)?\)?', line, re.I)
            if action_match:
                action_name = action_match.group(1)
                # Filter out common non-action words
                skip_words = ['domain', 'problem', 'define', 'requirements', 'tmp', 'file', 'error', 'syntax', 'done', 'parsing', 'defined']
                if action_name.lower() not in skip_words and len(action_name) > 2:
                    plan_steps.append(PlanStep(
                        step_number=len(plan_steps),
                        action_name=action_name
                    ))
    
    # Check if plan was found
    success = "plan found" in planner_output.lower() or "solution" in planner_output.lower()
    if not plan_steps and not success:
        # Check for explicit "no plan" messages
        if "no plan" in planner_output.lower() or "unsolvable" in planner_output.lower():
            return Plan(iteration=-1, success=False, raw_output=planner_output)
    
    return Plan(
        iteration=-1,  # Will be set by caller
        steps=plan_steps,
        raw_output=planner_output,
        success=success or len(plan_steps) > 0,
        plan_length=len(plan_steps)
    )


def compare_plans(plan1: Plan, plan2: Plan) -> Dict:
    """Compare two plans and return similarity metrics."""
    if not plan1.steps and not plan2.steps:
        return {
            "similarity": 1.0,
            "both_empty": True,
            "length_diff": 0,
            "common_steps": 0,
            "different_steps": 0
        }
    
    if not plan1.steps or not plan2.steps:
        return {
            "similarity": 0.0,
            "both_empty": False,
            "length_diff": abs(len(plan1.steps) - len(plan2.steps)),
            "common_steps": 0,
            "different_steps": max(len(plan1.steps), len(plan2.steps))
        }
    
    # Compare step by step
    common_steps = 0
    max_len = max(len(plan1.steps), len(plan2.steps))
    
    for i in range(min(len(plan1.steps), len(plan2.steps))):
        if plan1.steps[i] == plan2.steps[i]:
            common_steps += 1
    
    similarity = common_steps / max_len if max_len > 0 else 1.0
    
    return {
        "similarity": similarity,
        "both_empty": False,
        "length_diff": abs(len(plan1.steps) - len(plan2.steps)),
        "common_steps": common_steps,
        "different_steps": max_len - common_steps,
        "plan1_length": len(plan1.steps),
        "plan2_length": len(plan2.steps)
    }


class PlanEvolutionTracker:
    """Tracks plan evolution across iterations."""
    
    def __init__(self):
        self.plans: List[Plan] = []
        self.comparisons: List[Dict] = []
    
    def add_plan(self, plan: Plan, iteration: int):
        """Add a plan from a specific iteration."""
        plan.iteration = iteration
        self.plans.append(plan)
        
        # Compare with previous plan
        if len(self.plans) > 1:
            comparison = compare_plans(self.plans[-2], self.plans[-1])
            comparison["iteration"] = iteration
            comparison["prev_iteration"] = iteration - 1
            self.comparisons.append(comparison)
            logging.info(f"Plan comparison (iter {iteration-1} vs {iteration}): "
                        f"similarity={comparison['similarity']:.3f}, "
                        f"length_diff={comparison['length_diff']}")
    
    def get_convergence_metrics(self) -> Dict:
        """Calculate convergence metrics across all plans."""
        if len(self.plans) < 2:
            return {"converged": False, "stability": 0.0}
        
        # Check if plans are converging (similarity increasing)
        if len(self.comparisons) >= 2:
            recent_similarities = [c["similarity"] for c in self.comparisons[-3:]]
            stability = sum(recent_similarities) / len(recent_similarities)
            converged = stability > 0.9 and len(recent_similarities) >= 2
        else:
            stability = self.comparisons[-1]["similarity"] if self.comparisons else 0.0
            converged = False
        
        return {
            "converged": converged,
            "stability": stability,
            "n_plans": len(self.plans),
            "avg_similarity": sum(c["similarity"] for c in self.comparisons) / len(self.comparisons) if self.comparisons else 0.0
        }
    
    def get_evolution_summary(self) -> str:
        """Get a human-readable summary of plan evolution."""
        if not self.plans:
            return "No plans tracked yet."
        
        lines = [f"Plan Evolution Summary ({len(self.plans)} iterations):"]
        lines.append("-" * 60)
        
        for i, plan in enumerate(self.plans):
            status = "✓" if plan.success else "✗"
            lines.append(f"Iteration {plan.iteration}: {status} Length={plan.plan_length}")
        
        if self.comparisons:
            lines.append("\nConvergence:")
            for comp in self.comparisons[-5:]:  # Last 5 comparisons
                lines.append(f"  Iter {comp['prev_iteration']}→{comp['iteration']}: "
                           f"similarity={comp['similarity']:.3f}, "
                           f"length_diff={comp['length_diff']}")
        
        metrics = self.get_convergence_metrics()
        lines.append(f"\nOverall: stability={metrics['stability']:.3f}, "
                    f"converged={metrics['converged']}")
        
        return "\n".join(lines)


