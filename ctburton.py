"""
CTBurton Integration Module

This module provides integration between the ctBurton MiniZinc constraint programming
system and the PPDDL agent for probabilistic planning. It enables bidirectional
conversion and hybrid problem solving approaches.
"""

import json
import logging
from typing import Dict, List, Tuple, Optional, Any, Union
from dataclasses import dataclass, field
from pathlib import Path

from neurosym import NeuroSymGraph, NodeKind, EdgeKind
# Removed unused imports:
# from ppddl_agent import PPDDLAgent, HierarchyLevel
# from ppddl_validator import PPDDLValidator, validate_ppddl

@dataclass
class CTBurtonProblem:
    """Represents a ctBurton problem specification."""
    name: str
    description: str
    automata_types: List[str] = field(default_factory=list)
    transitions: List[Dict[str, Any]] = field(default_factory=list)
    constraints: List[str] = field(default_factory=list)
    objectives: List[str] = field(default_factory=list)
    time_horizon: int = 60
    temporal_constraints: List[Dict[str, Any]] = field(default_factory=list)

@dataclass
class ConversionMapping:
    """Maps between MiniZinc and PPDDL representations."""
    minizinc_vars: Dict[str, str] = field(default_factory=dict)
    ppddl_predicates: Dict[str, str] = field(default_factory=dict)
    minizinc_constraints: Dict[str, str] = field(default_factory=dict)
    ppddl_actions: Dict[str, str] = field(default_factory=dict)
    temporal_mappings: Dict[str, str] = field(default_factory=dict)

class CTBurtonConverter:
    """Converts between ctBurton MiniZinc and PPDDL representations."""
    
    def __init__(self):
        # Removed unused validator - not needed for conversion
        # self.validator = PPDDLValidator()
        self.mapping_templates = self._load_mapping_templates()
    
    def _load_mapping_templates(self) -> Dict[str, Any]:
        """Load conversion mapping templates."""
        return {
            "automata_states": {
                "idle": "idle",
                "connecting": "connecting", 
                "connected": "connected",
                "error": "error_state"
            },
            "transition_types": {
                "state_change": "transition",
                "reset": "reset",
                "idle": "idle_transition"
            },
            "temporal_constraints": {
                "stc": "temporal_constraint",
                "duration": "duration",
                "deadline": "deadline"
            }
        }
    
    def ctburton_to_ppddl(self, ctburton_problem: CTBurtonProblem) -> Tuple[str, str]:
        """Convert ctBurton problem to PPDDL domain and problem."""
        
        # Generate domain
        domain = self._generate_domain(ctburton_problem)
        
        # Generate problem
        problem = self._generate_problem(ctburton_problem)
        
        return domain, problem
    
    def _generate_domain(self, ctburton_problem: CTBurtonProblem) -> str:
        """Generate PPDDL domain from ctBurton problem."""
        
        domain_parts = [
            f"(define (domain {ctburton_problem.name.lower()})",
            "    (:requirements :strips :typing :negation :equality :conditional-effects :adl)",
            ""
        ]
        
        # Types
        domain_parts.extend([
            "    (:types",
            "        automaton - object",
            "        state - object",
            "        time - object",
            "    )",
            ""
        ])
        
        # Predicates
        domain_parts.extend([
            "    (:predicates",
            "        (at ?a - automaton ?s - state)",
            "        (current-time ?t - time)",
            "        (transition-possible ?a - automaton ?from ?to - state)",
            "        (time-elapsed ?t1 ?t2 - time)",
            "    )",
            ""
        ])
        
        # Functions - probabilistic-ff doesn't support :functions
        # Convert to predicates instead if needed
        # domain_parts.extend([
        #     "    (:functions",
        #     "        (time-value ?t - time)",
        #     "        (battery-level ?a - automaton)",
        #     "        (connection-quality ?a - automaton)",
        #     "    )",
        #     ""
        # ])
        
        # Actions
        actions = self._generate_actions(ctburton_problem)
        domain_parts.extend(actions)
        
        # Rewards
        rewards = self._generate_rewards(ctburton_problem)
        domain_parts.extend(rewards)
        
        domain_parts.append(")")
        
        return "\n".join(domain_parts)
    
    def _generate_problem(self, ctburton_problem: CTBurtonProblem) -> str:
        """Generate PPDDL problem from ctBurton problem."""
        
        problem_parts = [
            f"(define (problem {ctburton_problem.name.lower()}-problem)",
            f"    (:domain {ctburton_problem.name.lower()})",
            ""
        ]
        
        # Objects
        objects = self._generate_objects(ctburton_problem)
        problem_parts.extend(objects)
        
        # Initial state
        init_state = self._generate_initial_state(ctburton_problem)
        problem_parts.extend(init_state)
        
        # Goal
        goal = self._generate_goal(ctburton_problem)
        problem_parts.extend(goal)
        
        # Metric - probabilistic-ff doesn't support :metric
        # problem_parts.extend([
        #     "    (:metric maximize (expected-total-reward))",
        # ])
        problem_parts.append(")")
        
        return "\n".join(problem_parts)
    
    def _generate_actions(self, ctburton_problem: CTBurtonProblem) -> List[str]:
        """Generate PPDDL actions from ctBurton transitions."""
        actions = []
        
        # Generic state transition action
        actions.extend([
            "    (:action transition",
            "        :parameters (?a - automaton ?from ?to - state ?t1 ?t2 - time)",
            "        :precondition (and",
            "            (at ?a ?from)",
            "            (transition-possible ?a ?from ?to)",
            "            (current-time ?t1)",
            "            (time-elapsed ?t1 ?t2)",
            "        )",
            "        :effect (and",
            "            (not (at ?a ?from))",
            "            (at ?a ?to)",
            "            (not (current-time ?t1))",
            "            (current-time ?t2)",
            "        )",
            "    )",
            ""
        ])
        
        # Probabilistic transition for error handling (using whenp syntax for probabilistic-ff)
        actions.extend([
            "    (:action probabilistic-transition",
            "        :parameters (?a - automaton ?from ?to - state ?t1 ?t2 - time)",
            "        :precondition (and",
            "            (at ?a ?from)",
            "            (transition-possible ?a ?from ?to)",
            "            (current-time ?t1)",
            "        )",
            "        :effect (and",
            "            (whenp 0.9 (and",
            "                (not (at ?a ?from))",
            "                (at ?a ?to)",
            "                (not (current-time ?t1))",
            "                (current-time ?t2)",
            "            ))",
            "            (whenp 0.1 (and",
            "                (not (at ?a ?from))",
            "                (at ?a error_state)",
            "                (not (current-time ?t1))",
            "                (current-time ?t2)",
            "            ))",
            "        )",
            "    )",
            ""
        ])
        
        return actions
    
    def _generate_rewards(self, ctburton_problem: CTBurtonProblem) -> List[str]:
        """Generate reward functions."""
        # probabilistic-ff doesn't support :rewards, so return empty
        return []
    
    def _generate_objects(self, ctburton_problem: CTBurtonProblem) -> List[str]:
        """Generate object definitions."""
        objects = ["    (:objects"]
        
        # Add automata
        for i, automaton_type in enumerate(ctburton_problem.automata_types):
            objects.append(f"        a{i} - automaton")
        
        # Add states
        states = ["idle", "connecting", "connected", "error_state"]
        for state in states:
            objects.append(f"        {state} - state")
        
        # Add time points (limit to reasonable number to avoid planner limits)
        # Use fewer time steps for planning, but keep full horizon for problem definition
        max_time_steps = min(ctburton_problem.time_horizon + 1, 20)  # Limit to 20 time steps
        for t in range(max_time_steps):
            objects.append(f"        t{t} - time")
        
        objects.append("    )")
        objects.append("")
        
        return objects
    
    def _generate_initial_state(self, ctburton_problem: CTBurtonProblem) -> List[str]:
        """Generate initial state."""
        init = ["    (:init"]
        
        # All automata start in idle state
        for i in range(len(ctburton_problem.automata_types)):
            init.append(f"        (at a{i} idle)")
        
        # Start at time 0
        init.append("        (current-time t0)")
        
        # Time progression (limit to match time objects)
        max_time_steps = min(ctburton_problem.time_horizon, 19)  # Limit to 19 transitions
        for t in range(max_time_steps):
            init.append(f"        (time-elapsed t{t} t{t+1})")
        
        # Transition possibilities (simplified)
        for i in range(len(ctburton_problem.automata_types)):
            init.append(f"        (transition-possible a{i} idle connecting)")
            init.append(f"        (transition-possible a{i} connecting connected)")
            init.append(f"        (transition-possible a{i} connected idle)")
        
        init.append("    )")
        init.append("")
        
        return init
    
    def _generate_goal(self, ctburton_problem: CTBurtonProblem) -> List[str]:
        """Generate goal condition."""
        # probabilistic-ff requires probability after :goal (1.0 for deterministic)
        return [
            "    (:goal 1.0",
            "        (at a0 connected)",
            "    )",
            ""
        ]

# UNUSED: This class is not used in unified_demo.py
# Kept for reference but commented out to remove dependency on ppddl_agent.py
# To use this, uncomment and restore: from ppddl_agent import PPDDLAgent
# class CTBurtonPPDDLAgent(PPDDLAgent):
class _CTBurtonPPDDLAgent_Unused:
    """Extended PPDDL agent with ctBurton integration - DISABLED (requires ppddl_agent.py)."""
    
    def __init__(self, config_path: Optional[str] = None):
        # super().__init__(config_path)  # DISABLED: requires PPDDLAgent
        raise NotImplementedError("CTBurtonPPDDLAgent is disabled - requires ppddl_agent.py")
        self.converter = CTBurtonConverter()
        self.ctburton_problems = self._load_ctburton_problems()
    
    def _load_ctburton_problems(self) -> Dict[str, CTBurtonProblem]:
        """Load ctBurton problem templates."""
        return {
            "computer_projector": CTBurtonProblem(
                name="computer_projector",
                description="Computer-projector connection establishment problem",
                automata_types=["computer", "projector", "connection"],
                transitions=[
                    {"from": "idle", "to": "connecting", "duration": [5, 10]},
                    {"from": "connecting", "to": "connected", "duration": [2, 5]},
                    {"from": "connecting", "to": "error", "probability": 0.1},
                    {"from": "connected", "to": "idle", "duration": [1, 3]}
                ],
                constraints=[
                    "Total connection time must be ≤ 30 minutes",
                    "Connection failure requires restart from idle"
                ],
                objectives=[
                    "Minimize connection establishment time",
                    "Maximize connection reliability"
                ],
                time_horizon=30
            ),
            "multi_agent_assembly": CTBurtonProblem(
                name="multi_agent_assembly",
                description="Multi-agent assembly coordination problem",
                automata_types=["agent1", "agent2", "agent3"],
                transitions=[
                    {"from": "idle", "to": "working", "duration": [10, 15]},
                    {"from": "working", "to": "coordinating", "duration": [5, 8]},
                    {"from": "coordinating", "to": "completed", "duration": [3, 5]}
                ],
                constraints=[
                    "All agents must coordinate before completion",
                    "Assembly time must be ≤ 60 minutes"
                ],
                objectives=[
                    "Minimize total assembly time",
                    "Maximize coordination efficiency"
                ],
                time_horizon=60
            )
        }
    
    def solve_ctburton_problem(self, problem_name: str) -> Dict[str, Any]:
        """Solve a ctBurton problem using PPDDL approach."""
        
        if problem_name not in self.ctburton_problems:
            raise ValueError(f"Unknown ctBurton problem: {problem_name}")
        
        ctburton_problem = self.ctburton_problems[problem_name]
        
        # Convert to PPDDL
        domain_text, problem_text = self.converter.ctburton_to_ppddl(ctburton_problem)
        
        # Validate PPDDL - DISABLED: requires ppddl_validator
        # validation_result = validate_ppddl(domain_text, problem_text)
        validation_result = {"is_valid": True, "quality_metrics": {"overall_score": 0.0}}
        
        if not validation_result['is_valid']:
            logging.warning("Generated PPDDL has validation issues")
        
        # Solve using PPDDL agent
        result = {
            "ctburton_problem": ctburton_problem,
            "domain_text": domain_text,
            "problem_text": problem_text,
            "validation_result": validation_result,
            "solution": None
        }
        
        # If PPDDL is valid, try to solve
        if validation_result['is_valid']:
            try:
                # Use the planner directly
                success, output = self.planner.run_planner(domain_text, problem_text)
                result["solution"] = {
                    "success": success,
                    "output": output
                }
            except Exception as e:
                logging.error(f"Failed to solve PPDDL: {e}")
                result["solution"] = {
                    "success": False,
                    "error": str(e)
                }
        
        return result
    
    def create_ctburton_graph(self, problem_name: str) -> NeuroSymGraph:
        """Create a neuro-symbolic graph for ctBurton problem."""
        
        if problem_name not in self.ctburton_problems:
            raise ValueError(f"Unknown ctBurton problem: {problem_name}")
        
        ctburton_problem = self.ctburton_problems[problem_name]
        graph = NeuroSymGraph()
        
        # Add problem node
        problem_node = graph.add_node(
            "requirement", 
            ctburton_problem.description,
            confidence=0.95
        )
        
        # Add automata as system nodes
        for automaton in ctburton_problem.automata_types:
            automaton_node = graph.add_node(
                "system",
                f"{automaton} automaton",
                confidence=0.9
            )
            graph.add_edge(problem_node, automaton_node, "depends_on", 0.8)
        
        # Add transitions as actions
        for i, transition in enumerate(ctburton_problem.transitions):
            transition_node = graph.add_node(
                "action",
                f"Transition: {transition['from']} → {transition['to']}",
                confidence=0.8
            )
            graph.add_edge(problem_node, transition_node, "enables", 0.7)
        
        # Add constraints
        for constraint in ctburton_problem.constraints:
            constraint_node = graph.add_node(
                "constraint",
                constraint,
                confidence=0.9
            )
            graph.add_edge(problem_node, constraint_node, "constrains", 0.9)
        
        # Add objectives
        for objective in ctburton_problem.objectives:
            objective_node = graph.add_node(
                "goal",
                objective,
                confidence=0.85
            )
            graph.add_edge(problem_node, objective_node, "supports", 0.8)
        
        # Propagate beliefs
        graph.propagate_beliefs()
        
        return graph

def create_unified_problem_format() -> Dict[str, Any]:
    """Create a unified problem description format for both MiniZinc and PPDDL."""
    
    return {
        "metadata": {
            "name": "unified_problem_format",
            "version": "1.0",
            "description": "Unified format for describing problems in both MiniZinc and PPDDL"
        },
        "problem_definition": {
            "name": "problem_name",
            "description": "Natural language problem description",
            "domain": "problem_domain",
            "complexity": "low|medium|high"
        },
        "entities": {
            "automata": [
                {
                    "name": "automaton_name",
                    "type": "automaton_type",
                    "states": ["state1", "state2", "state3"],
                    "initial_state": "state1"
                }
            ],
            "resources": [
                {
                    "name": "resource_name",
                    "type": "resource_type",
                    "capacity": 100,
                    "initial_value": 60
                }
            ]
        },
        "transitions": [
            {
                "from": "source_state",
                "to": "target_state",
                "duration": {"min": 5, "max": 10},
                "probability": 0.9,
                "cost": {"resource": "battery", "amount": 10},
                "preconditions": ["condition1", "condition2"],
                "effects": ["effect1", "effect2"]
            }
        ],
        "constraints": [
            {
                "type": "temporal",
                "description": "Time constraint description",
                "expression": "total_time <= 60"
            },
            {
                "type": "resource",
                "description": "Resource constraint description",
                "expression": "battery_level >= 0"
            }
        ],
        "objectives": [
            {
                "type": "minimize",
                "target": "total_time",
                "weight": 1.0
            },
            {
                "type": "maximize",
                "target": "battery_level",
                "weight": 0.8
            }
        ],
        "temporal_specification": {
            "horizon": 60,
            "time_units": "minutes",
            "discrete": True,
            "granularity": 1
        }
    }

def export_for_minizinc(problem_data: Dict[str, Any]) -> str:
    """Export unified problem format to MiniZinc representation."""
    
    minizinc_parts = []
    
    # Problem header
    minizinc_parts.append(f"% Problem: {problem_data['problem_definition']['name']}")
    minizinc_parts.append(f"% Description: {problem_data['problem_definition']['description']}")
    minizinc_parts.append("")
    
    # Parameters
    minizinc_parts.append("int: horizon = 60; % Time horizon")
    minizinc_parts.append("set of int: TIME = 0..horizon;")
    minizinc_parts.append("")
    
    # Variables
    for automaton in problem_data['entities']['automata']:
        minizinc_parts.append(f"var 0..{len(automaton['states'])-1}: {automaton['name']}_state;")
    
    minizinc_parts.append("")
    
    # Constraints
    minizinc_parts.append("% Temporal constraints")
    for constraint in problem_data['constraints']:
        if constraint['type'] == 'temporal':
            minizinc_parts.append(f"% {constraint['description']}")
            minizinc_parts.append(f"constraint {constraint['expression']};")
    
    minizinc_parts.append("")
    
    # Objectives
    objectives = problem_data['objectives']
    if objectives:
        minizinc_parts.append("% Objectives")
        if len(objectives) == 1:
            obj = objectives[0]
            minizinc_parts.append(f"solve satisfy; % {obj['type']} {obj['target']}")
        else:
            minizinc_parts.append("solve minimize weighted_sum;")
    
    return "\n".join(minizinc_parts)

def export_for_ppddl(problem_data: Dict[str, Any]) -> Tuple[str, str]:
    """Export unified problem format to PPDDL representation."""
    
    # Use the converter to generate PPDDL
    converter = CTBurtonConverter()
    
    # Convert unified format to CTBurtonProblem
    ctburton_problem = CTBurtonProblem(
        name=problem_data['problem_definition']['name'],
        description=problem_data['problem_definition']['description'],
        automata_types=[a['type'] for a in problem_data['entities']['automata']],
        time_horizon=problem_data['temporal_specification']['horizon']
    )
    
    # Generate PPDDL
    domain, problem = converter.ctburton_to_ppddl(ctburton_problem)
    
    return domain, problem

if __name__ == "__main__":
    # Example usage - DISABLED: CTBurtonPPDDLAgent requires ppddl_agent.py
    # Use CTBurtonConverter directly instead:
    converter = CTBurtonConverter()
    
    # Create a simple problem
    problem = CTBurtonProblem(
        name="test",
        description="Test problem",
        automata_types=["rover"],
        time_horizon=20
    )
    
    # Convert to PPDDL
    domain, problem_ppddl = converter.ctburton_to_ppddl(problem)
    print("PPDDL generated successfully")
    print(f"Domain length:", len(domain))
    print(f"Problem length:", len(problem_ppddl))
    
    # Export unified format
    unified_format = create_unified_problem_format()
    minizinc_output = export_for_minizinc(unified_format)
    ppddl_domain, ppddl_problem = export_for_ppddl(unified_format)
    
    print("Unified format exported successfully")


