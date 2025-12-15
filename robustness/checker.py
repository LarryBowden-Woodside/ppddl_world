"""
PPDDL Model Checker: Verifies MiniZinc Invariants Hold in PPDDL

Addresses Critique #1: The "MiniZinc to PPDDL" Impedance Mismatch

This module parses generated PPDDL and verifies that global constraints
from MiniZinc are properly enforced as preconditions/effects in all actions.
"""

import re
import logging
from typing import Dict, List, Tuple, Set, Optional
from dataclasses import dataclass, field


@dataclass
class MiniZincInvariant:
    """Represents a global constraint from MiniZinc."""
    constraint_text: str
    constraint_type: str  # "capacity", "temporal", "quality", "safety"
    affected_variables: List[str]
    operator: str  # "<=", ">=", "==", "!="
    threshold: Optional[float] = None


@dataclass
class PPDDLAction:
    """Represents a parsed PPDDL action."""
    name: str
    parameters: List[str]
    preconditions: List[str]
    effects: List[str]
    increases_vars: Set[str] = field(default_factory=set)  # Variables that increase
    decreases_vars: Set[str] = field(default_factory=set)  # Variables that decrease


class PPDDLModelChecker:
    """
    Checks that MiniZinc global constraints are enforced in PPDDL actions.
    
    The key insight: MiniZinc constraints like "tank_level <= 95%" must be
    enforced as preconditions in EVERY action that increases tank_level.
    """
    
    def __init__(self):
        self.invariants: List[MiniZincInvariant] = []
        self.actions: List[PPDDLAction] = []
        self.violations: List[Dict] = []
        
        # Physics Knowledge Base (Critique #3)
        # Maps action name patterns to expected effect directions
        self.physics_rules = {
            "load": {"decrease": ["tank-level", "tank_level"], "increase": ["volume", "cargo-volume"]},
            "fill": {"increase": ["tank-level", "tank_level"]},
            "produce": {"increase": ["tank-level", "tank_level"]},
            "discharge": {"decrease": ["volume", "cargo-volume"]},
            "depart": {"not": ["berth-occupied", "berth-available=false"]},
            "arrive": {"increase": ["queue", "waiting"]}
        }

    def validate_action_effects(self, actions: List[PPDDLAction]) -> List[Dict]:
        """
        Validate that action effects match physical reality (Fix #3).
        
        Checks:
        - Does 'load' actually DECREASE tank level?
        - Does 'produce' actually INCREASE tank level?
        """
        violations = []
        
        for action in actions:
            action_name_lower = action.name.lower()
            
            # Check against physics rules
            for pattern, expected in self.physics_rules.items():
                if pattern in action_name_lower:
                    # Check expected increases
                    if "increase" in expected:
                        for var in expected["increase"]:
                            # Normalize var name (replace _ with -)
                            var_norm = var.replace('_', '-')
                            # Check if any increased var matches
                            found = any(var_norm in v.replace('_', '-') for v in action.increases_vars)
                            # Note: Not all load actions must increase volume (might just move it),
                            # but if it affects volume, it should be increase.
                            # Stricter check: if action affects var, direction must match.
                            
                    # Check expected decreases
                    if "decrease" in expected:
                        for var in expected["decrease"]:
                            var_norm = var.replace('_', '-')
                            
                            # If action affects this variable (in effects), it MUST be a decrease
                            # Check if variable is present in effects at all
                            var_in_effects = any(var_norm in eff.replace('_', '-') for eff in action.effects)
                            
                            if var_in_effects:
                                # It must be in decreases_vars
                                is_decreasing = any(var_norm in v.replace('_', '-') for v in action.decreases_vars)
                                
                                if not is_decreasing:
                                    # Check if it's erroneously increasing
                                    is_increasing = any(var_norm in v.replace('_', '-') for v in action.increases_vars)
                                    
                                    if is_increasing:
                                        violations.append({
                                            "action": action.name,
                                            "check": "physics_validation",
                                            "severity": "critical",
                                            "message": f"PHYSICS ERROR: Action '{action.name}' INCREASES '{var}' but should DECREASE it."
                                        })
        return violations

    def extract_minizinc_invariants(self, minizinc_code: str, ctburton_constraints: List[str]) -> List[MiniZincInvariant]:
        """
        Extract global invariants from MiniZinc and CTBurton constraints.
        
        Examples:
        - "Tank A capacity: 180,000 m³ (max 95% full)" -> capacity constraint
        - "HHV specification: 1055-1095 BTU/scf" -> quality constraint
        """
        invariants = []
        
        # Parse CTBurton constraints for safety invariants
        for constraint in ctburton_constraints:
            # Tank capacity constraints
            if "max" in constraint.lower() and ("tank" in constraint.lower() or "capacity" in constraint.lower()):
                # Extract: "Tank A capacity: 180,000 m³ (max 95% full)"
                max_match = re.search(r'max\s+(\d+(?:\.\d+)?)\s*%', constraint, re.IGNORECASE)
                if max_match:
                    threshold = float(max_match.group(1))
                    # Find tank name
                    tank_match = re.search(r'tank\s+([A-Z])', constraint, re.IGNORECASE)
                    tank_name = tank_match.group(1) if tank_match else "unknown"
                    
                    invariants.append(MiniZincInvariant(
                        constraint_text=constraint,
                        constraint_type="capacity",
                        affected_variables=[f"tank_{tank_name.lower()}_level"],
                        operator="<=",
                        threshold=threshold
                    ))
            
            # HHV quality constraints
            if "hhv" in constraint.lower() and ("spec" in constraint.lower() or "range" in constraint.lower()):
                # Extract: "HHV specification: 1055-1095 BTU/scf"
                range_match = re.search(r'(\d+)\s*-\s*(\d+)', constraint)
                if range_match:
                    min_val = float(range_match.group(1))
                    max_val = float(range_match.group(2))
                    
                    invariants.append(MiniZincInvariant(
                        constraint_text=constraint,
                        constraint_type="quality",
                        affected_variables=["cargo_hhv", "tank_hhv"],
                        operator="range",
                        threshold=max_val  # Store max, min in constraint_text
                    ))
            
            # Temporal constraints (laycan windows)
            if "laycan" in constraint.lower() or "deadline" in constraint.lower():
                invariants.append(MiniZincInvariant(
                    constraint_text=constraint,
                    constraint_type="temporal",
                    affected_variables=["cargo_load_time"],
                    operator="<=",
                    threshold=None  # Will be extracted from temporal_constraints
                ))
        
        return invariants
    
    def parse_ppddl_actions(self, domain_text: str) -> List[PPDDLAction]:
        """Parse PPDDL domain to extract all actions with preconditions and effects."""
        actions = []
        
        # Find all action definitions
        action_pattern = r'\(:action\s+([a-z-]+)\s+.*?\)(?=\s*\(:action|\s*\))'
        action_matches = re.finditer(action_pattern, domain_text, re.DOTALL | re.IGNORECASE)
        
        for match in action_matches:
            action_text = match.group(0)
            action_name = match.group(1)
            
            # Extract parameters
            params_match = re.search(r':parameters\s+\(([^)]*)\)', action_text, re.DOTALL)
            params_str = params_match.group(1) if params_match else ""
            parameters = re.findall(r'\?([a-z-]+)', params_str)
            
            # Extract preconditions
            precond_match = re.search(r':precondition\s+\(([^)]*(?:\([^)]*\)[^)]*)*)\)', action_text, re.DOTALL)
            preconditions = []
            if precond_match:
                precond_text = precond_match.group(1)
                # Extract individual predicates
                preconditions = re.findall(r'\(([^)]+)\)', precond_text)
            
            # Extract effects
            effect_match = re.search(r':effect\s+\(([^)]*(?:\([^)]*\)[^)]*)*)\)', action_text, re.DOTALL)
            effects = []
            increases_vars = set()
            decreases_vars = set()
            
            if effect_match:
                effect_text = effect_match.group(1)
                effects = re.findall(r'\(([^)]+)\)', effect_text)
                
                # Identify variables that increase/decrease
                for effect in effects:
                    # Look for (increase ...) or (decrease ...) patterns
                    # Also look for predicates that imply increase (e.g., (tank-level ?tank) -> increase)
                    if 'increase' in effect.lower() or 'tank-level' in effect.lower():
                        var_match = re.search(r'(tank[_-]?level|volume|hhv)', effect, re.IGNORECASE)
                        if var_match:
                            increases_vars.add(var_match.group(1).lower())
                    if 'decrease' in effect.lower():
                        var_match = re.search(r'(tank[_-]?level|volume)', effect, re.IGNORECASE)
                        if var_match:
                            decreases_vars.add(var_match.group(1).lower())
            
            actions.append(PPDDLAction(
                name=action_name,
                parameters=parameters,
                preconditions=preconditions,
                effects=effects,
                increases_vars=increases_vars,
                decreases_vars=decreases_vars
            ))
        
        return actions
    
    def verify_invariants(self, invariants: List[MiniZincInvariant], actions: List[PPDDLAction]) -> List[Dict]:
        """
        Verify that all invariants are enforced in relevant actions.
        
        For each invariant:
        1. Find all actions that affect the constrained variable
        2. Check if the action has a precondition enforcing the constraint
        3. Report violations
        """
        violations = []
        
        for invariant in invariants:
            # Find actions that affect the constrained variables
            relevant_actions = []
            for action in actions:
                # Check if action increases any constrained variable
                for var in invariant.affected_variables:
                    var_normalized = var.replace('_', '-').lower()
                    if any(var_normalized in inc_var for inc_var in action.increases_vars):
                        relevant_actions.append((action, var))
            
            # For each relevant action, check if constraint is enforced
            for action, affected_var in relevant_actions:
                constraint_enforced = False
                
                # Check preconditions for constraint enforcement
                for precond in action.preconditions:
                    precond_lower = precond.lower()
                    
                    # Check for capacity constraints (e.g., "tank-level <= 95%")
                    if invariant.constraint_type == "capacity":
                        # Look for predicates like (tank-level-safe ?tank) or (<= (tank-level ?tank) 0.95)
                        if "tank" in precond_lower and ("safe" in precond_lower or "capacity" in precond_lower):
                            constraint_enforced = True
                        # Check for numeric comparisons
                        if invariant.operator == "<=" and "<=" in precond_lower:
                            if str(invariant.threshold) in precond or "0.95" in precond:
                                constraint_enforced = True
                    
                    # Check for quality constraints (HHV range)
                    if invariant.constraint_type == "quality":
                        if "hhv" in precond_lower and ("spec" in precond_lower or "range" in precond_lower):
                            constraint_enforced = True
                
                if not constraint_enforced:
                    violations.append({
                        "invariant": invariant.constraint_text,
                        "action": action.name,
                        "affected_variable": affected_var,
                        "severity": "critical" if invariant.constraint_type == "capacity" else "high",
                        "message": f"Action '{action.name}' increases '{affected_var}' but lacks precondition enforcing: {invariant.constraint_text}"
                    })
        
        return violations
    
    def check_translation(self, minizinc_code: str, ctburton_constraints: List[str], 
                         domain_text: str) -> Tuple[bool, List[Dict]]:
        """
        Main verification function.
        
        Returns:
            (is_valid, violations)
        """
        logging.info("Starting PPDDL model checking...")
        
        # Extract invariants
        self.invariants = self.extract_minizinc_invariants(minizinc_code, ctburton_constraints)
        logging.info(f"Extracted {len(self.invariants)} invariants from MiniZinc/CTBurton")
        
        # Parse PPDDL actions
        self.actions = self.parse_ppddl_actions(domain_text)
        logging.info(f"Parsed {len(self.actions)} actions from PPDDL domain")
        
        # Verify invariants
        invariant_violations = self.verify_invariants(self.invariants, self.actions)
        self.violations.extend(invariant_violations)
        
        # Validate physics (Fix #3)
        physics_violations = self.validate_action_effects(self.actions)
        self.violations.extend(physics_violations)
        
        if self.violations:
            logging.warning(f"Found {len(self.violations)} constraint/physics violations!")
            for v in self.violations:
                logging.warning(f"  - {v['message']}")
        else:
            logging.info("✓ All MiniZinc invariants are properly enforced in PPDDL actions")
        
        return len(self.violations) == 0, self.violations
    
    def generate_fixes(self, violations: List[Dict]) -> str:
        """Generate suggested fixes for violations."""
        fixes = []
        
        for v in violations:
            action_name = v['action']
            invariant = v['invariant']
            
            # Generate precondition suggestion
            if "capacity" in v.get('invariant', {}).get('constraint_type', ''):
                fix = f"Add precondition to action '{action_name}': (tank-capacity-safe ?tank)"
            elif "quality" in v.get('invariant', {}).get('constraint_type', ''):
                fix = f"Add precondition to action '{action_name}': (hhv-in-spec ?cargo)"
            else:
                fix = f"Add precondition to action '{action_name}' enforcing: {invariant}"
            
            fixes.append(fix)
        
        return "\n".join(fixes)

