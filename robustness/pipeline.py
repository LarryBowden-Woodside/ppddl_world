"""
Robustness Integration: Wires All Fixes Together

This module integrates all five robustness fixes into the main pipeline.
"""

import logging
import numpy as np
from typing import Dict, List, Tuple, Optional, Any
from pathlib import Path

# Import all robustness modules
from robustness.checker import PPDDLModelChecker
from robustness.kalman import learn_hhv_kalman, KalmanHHVLearner
from robustness.regularizer import PlanRegularizer, PlanRegularizationConfig, apply_plan_regularization
from neurosym import convert_to_bayesian_network, rename_confidence_to_activation
from robustness.safety import DiscretizationSafetyManager, setup_lng_safety_buffers
from plan_evolution import Plan

# New modules for Industrial-Grade fixes
from robustness.market import SpotMarketBayesianNetwork
from robustness.mcts import MCTSPlanner

# LNG-specific semantics layer (NeuroSym integration)
from lng_semantics import (
    SemanticModes,
    build_lng_semantic_graph,
    record_hhv_evidence,
    record_spot_market_evidence,
    record_plan_stability_evidence,
    record_model_checker_evidence,
    propagate_semantics,
    derive_modes,
)

# Import core modules needed for integration
import agent as sa
from translator import hybrid_ctburton_llm_ppddl
from ppddl_postprocess import fix_ppddl_syntax
from ctburton import CTBurtonProblem 


class RobustnessPipeline:
    """
    Integrated pipeline with all robustness fixes.
    
    Fixes:
    1. PPDDL Model Checking (verifies invariants & physics) - UPGRADED
    2. Kalman Filter Learning (damped trend) - UPGRADED
    3. Plan Regularization (soft constraints) - UPGRADED
    4. Bayesian Network (Spot Market) - NEW
    5. Solver Viability (MCTS/Determinization admission) - NEW
    6. Safety Buffers (discretization protection) - EXISTING
    """
    
    def __init__(self, 
                 enable_model_checking: bool = True,
                 enable_kalman: bool = True,
                 enable_regularization: bool = True,
                 use_bayesian_network: bool = False,
                 enable_safety_buffers: bool = True,
                 enable_spot_bayes: bool = True,
                 enable_mcts: bool = True,
                 kalman_damping: float = 0.9,
                 enable_semantics: bool = True):
        
        self.logger = logging.getLogger(self.__class__.__name__)
        self.logger.setLevel(logging.INFO)
        
        self.enable_model_checking = enable_model_checking
        self.enable_kalman = enable_kalman
        self.enable_regularization = enable_regularization
        self.use_bayesian_network = use_bayesian_network
        self.enable_safety_buffers = enable_safety_buffers
        self.enable_spot_bayes = enable_spot_bayes
        self.enable_mcts = enable_mcts
        self.kalman_damping = kalman_damping
        self.enable_semantics = enable_semantics
        
        # Initialize components
        self.model_checker = PPDDLModelChecker() if enable_model_checking else None
        self.plan_regularizer = PlanRegularizer() if enable_regularization else None
        self.safety_manager = setup_lng_safety_buffers() if enable_safety_buffers else None
        self.spot_market = SpotMarketBayesianNetwork() if enable_spot_bayes else None
        self.mcts_planner = MCTSPlanner() if enable_mcts else None

        # LNG semantics (NeuroSym graph + modes)
        self.semantic_graph = None
        self.semantic_modes: Optional[SemanticModes] = None
        if self.enable_semantics:
            try:
                self.semantic_graph = build_lng_semantic_graph()
                self.semantic_modes = derive_modes(self.semantic_graph)
                self.logger.info("LNG semantic layer enabled (NeuroSym graph initialized).")
            except Exception as e:
                self.logger.warning(f"Failed to initialize LNG semantic layer: {e}")
                self.semantic_graph = None
                self.semantic_modes = None
        
        # Kalman learners (one per train)
        self.kalman_train1: Optional[KalmanHHVLearner] = None
        self.kalman_train2: Optional[KalmanHHVLearner] = None
        
        self.logger.info("RobustnessPipeline initialized with Industrial-Grade upgrades.")
    
    def check_ppddl_translation(self, 
                                minizinc_code: str,
                                ctburton_constraints: List[str],
                                domain_text: str) -> Tuple[bool, List[Dict]]:
        """
        Fix #1 & #3: Verify invariants and physics.
        """
        if not self.model_checker:
            return True, []
        
        self.logger.info("ROBUSTNESS FIX #1 & #3: PPDDL Model & Physics Checking")
        
        # Load data
        self.model_checker.invariants = self.model_checker.extract_minizinc_invariants(minizinc_code, ctburton_constraints)
        self.model_checker.actions = self.model_checker.parse_ppddl_actions(domain_text)
        
        # Verify
        invariant_violations = self.model_checker.verify_invariants(self.model_checker.invariants, self.model_checker.actions)
        physics_violations = self.model_checker.validate_action_effects(self.model_checker.actions)
        
        all_violations = invariant_violations + physics_violations

        # Record semantics: model checker trust/distrust
        if self.enable_semantics and self.semantic_graph is not None:
            record_model_checker_evidence(self.semantic_graph, len(all_violations))
            propagate_semantics(self.semantic_graph)
            self.semantic_modes = derive_modes(self.semantic_graph)
        
        if all_violations:
            self.logger.warning(f"Found {len(all_violations)} violations (invariants + physics).")
            for v in all_violations:
                self.logger.warning(f"  - {v.get('message', 'Unknown violation')}")
        
        return len(all_violations) == 0, all_violations
    
    def learn_hhv_robust(self, 
                        observations: np.ndarray,
                        train: int,
                        prior_mean: float = 1090.0,
                        prior_std: float = 10.0) -> Tuple[float, float, float, float]:
        """
        Fix #2: Learn HHV using Damped Kalman filter.
        """
        if not self.enable_kalman:
            from main import learn_hhv_distribution
            mean, std, conf = learn_hhv_distribution(observations, prior_mean, prior_std)
            return mean, std, conf, 0.0
        
        # Initialize if needed
        if train == 1:
            if self.kalman_train1 is None:
                self.kalman_train1 = KalmanHHVLearner(
                    initial_mean=prior_mean,
                    initial_std=prior_std,
                    damping_factor=self.kalman_damping
                )
            learner = self.kalman_train1
        else:
            if self.kalman_train2 is None:
                self.kalman_train2 = KalmanHHVLearner(
                    initial_mean=prior_mean,
                    initial_std=prior_std,
                    damping_factor=self.kalman_damping
                )
            learner = self.kalman_train2
            
        mean, std, conf = learner.batch_update(observations)
        trend = learner.get_trend()

        # Record semantics: HHV behavior
        if self.enable_semantics and self.semantic_graph is not None:
            record_hhv_evidence(self.semantic_graph, train, mean, trend, conf)
            propagate_semantics(self.semantic_graph)
            self.semantic_modes = derive_modes(self.semantic_graph)
        
        self.logger.info(f"Kalman (Train {train}): μ={mean:.1f}, trend={trend:.3f} (damped)")
        return mean, std, conf, trend
    
    def regularize_plan(self,
                       problem_text: str,
                       current_plan: Optional[Plan],
                       previous_plan: Optional[Plan]) -> Tuple[str, float, Dict]:
        """
        Fix #2: Apply plan regularization via soft constraints.
        """
        if not self.plan_regularizer:
            return problem_text, 0.0, {}
            
        # Generate soft constraints from previous plan
        if previous_plan:
            soft_constraints = self.plan_regularizer.generate_soft_constraints_ppddl(previous_plan)
            if soft_constraints:
                # Inject into problem file (simple string append for demo)
                problem_text = problem_text.rstrip().rstrip(')') + "\n" + soft_constraints + "\n)"
                self.logger.info("ROBUSTNESS FIX #2: Injected soft constraints from previous plan.")
        
        modified_problem, penalty, details = self.plan_regularizer.add_regularization_to_objective(
            problem_text, current_plan, previous_plan
        )

        # Record semantics: plan stability (if we have comparison info)
        if (
            self.enable_semantics
            and self.semantic_graph is not None
            and isinstance(details, dict)
        ):
            similarity = float(details.get("similarity", 1.0))
            action_changes = int(details.get("action_changes", 0))
            timing_changes = int(details.get("timing_changes", 0))
            record_plan_stability_evidence(
                self.semantic_graph, similarity, action_changes, timing_changes
            )
            propagate_semantics(self.semantic_graph)
            self.semantic_modes = derive_modes(self.semantic_graph)

        return modified_problem, penalty, details
    
    def apply_safety_buffers(self, domain_text: str, problem_text: str) -> Tuple[str, str]:
        """Fix #5: Safety buffers."""
        if not self.enable_safety_buffers or not self.safety_manager:
            return domain_text, problem_text
        return self.safety_manager.apply_safety_buffers_to_ppddl(domain_text, problem_text)

    def sample_spot_market(self) -> Tuple[float, bool]:
        """Fix #4: Sample spot market from Bayesian Network."""
        if self.enable_spot_bayes and self.spot_market:
            price, available = self.spot_market.sample_market_conditions()
        else:
            price, available = 90.0, True  # Default

        # Record semantics: spot market tight/loose
        if self.enable_semantics and self.semantic_graph is not None:
            record_spot_market_evidence(self.semantic_graph, price, available)
            propagate_semantics(self.semantic_graph)
            self.semantic_modes = derive_modes(self.semantic_graph)

        return price, available # Default or sampled

    def run_planner(self, domain_text: str, problem_text: str) -> Tuple[bool, str]:
        """
        Fix #5: Run planner using MCTS or Determinized Re-planning admission.
        """
        if self.enable_mcts and self.mcts_planner:
            # In a real integration, this would invoke the MCTS solver
            # For this demo, we use the wrapper that admits determinization
            # if full MCTS isn't feasible in Python
            result_msg = self.mcts_planner.run_ff_replan("domain.ppddl", "problem.ppddl")
            self.logger.info(f"ROBUSTNESS FIX #5: {result_msg}")
            
            # Fallback to systemagent for actual execution (which wraps ff)
            return sa.run_ppddl_planner(domain_text, problem_text)
        
        return sa.run_ppddl_planner(domain_text, problem_text)

# Convenience
def create_robust_pipeline(**kwargs) -> RobustnessPipeline:
    return RobustnessPipeline(**kwargs)
