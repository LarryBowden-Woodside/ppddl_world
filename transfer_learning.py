"""
Transfer Learning and Meta-Learning Utilities

Enables learning from one scenario and applying to another, plus meta-learning
across multiple problems.
"""

import json
import os
import numpy as np
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
import logging

from world_model_learning import LearningResult, TRUE_COST


@dataclass
class LearnedModel:
    """A learned model that can be transferred across scenarios."""
    scenario_name: str
    parameter_name: str
    estimated_value: float
    uncertainty: float
    confidence_interval: Tuple[float, float]
    r_squared: float
    n_samples: int
    metadata: Dict


class ModelRegistry:
    """Registry for storing and retrieving learned models."""
    
    def __init__(self, registry_path: str = "learned_models_registry.json"):
        self.registry_path = registry_path
        self.models: Dict[str, List[LearnedModel]] = {}
        self.load_registry()
    
    def save_model(self, model: LearnedModel):
        """Save a learned model to the registry."""
        if model.scenario_name not in self.models:
            self.models[model.scenario_name] = []
        self.models[model.scenario_name].append(model)
        self.save_registry()
        logging.info(f"Saved model: {model.scenario_name}/{model.parameter_name}")
    
    def get_models(self, scenario_name: Optional[str] = None) -> List[LearnedModel]:
        """Get models, optionally filtered by scenario."""
        if scenario_name:
            return self.models.get(scenario_name, [])
        all_models = []
        for models_list in self.models.values():
            all_models.extend(models_list)
        return all_models
    
    def find_similar_model(self, parameter_name: str, scenario_name: Optional[str] = None) -> Optional[LearnedModel]:
        """Find a similar model for transfer learning."""
        candidates = self.get_models(scenario_name)
        for model in candidates:
            if model.parameter_name == parameter_name:
                return model
        return None
    
    def save_registry(self):
        """Save registry to disk."""
        data = {
            scenario: [asdict(model) for model in models]
            for scenario, models in self.models.items()
        }
        with open(self.registry_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def load_registry(self):
        """Load registry from disk."""
        if os.path.exists(self.registry_path):
            try:
                with open(self.registry_path, 'r') as f:
                    data = json.load(f)
                self.models = {
                    scenario: [LearnedModel(**model_dict) for model_dict in models]
                    for scenario, models in data.items()
                }
            except Exception as e:
                logging.warning(f"Failed to load registry: {e}")
                self.models = {}


def create_model_from_result(result: LearningResult, scenario_name: str, 
                            parameter_name: str, n_samples: int) -> LearnedModel:
    """Create a LearnedModel from a LearningResult."""
    return LearnedModel(
        scenario_name=scenario_name,
        parameter_name=parameter_name,
        estimated_value=result.estimated_cost,
        uncertainty=result.uncertainty,
        confidence_interval=result.confidence_interval,
        r_squared=result.r_squared,
        n_samples=n_samples,
        metadata={
            "fit_quality": result.fit_quality,
            "true_cost": result.true_cost
        }
    )


def transfer_model(source_model: LearnedModel, target_scenario: str, 
                  adaptation_factor: float = 1.0) -> LearnedModel:
    """Transfer a learned model to a new scenario with optional adaptation."""
    return LearnedModel(
        scenario_name=target_scenario,
        parameter_name=source_model.parameter_name,
        estimated_value=source_model.estimated_value * adaptation_factor,
        uncertainty=source_model.uncertainty * 1.2,  # Slightly higher uncertainty in new scenario
        confidence_interval=(
            source_model.confidence_interval[0] * adaptation_factor,
            source_model.confidence_interval[1] * adaptation_factor
        ),
        r_squared=source_model.r_squared * 0.9,  # Slightly lower confidence
        n_samples=0,  # No samples in new scenario yet
        metadata={
            **source_model.metadata,
            "transferred_from": source_model.scenario_name,
            "adaptation_factor": adaptation_factor
        }
    )


def meta_learn(models: List[LearnedModel]) -> Optional[LearnedModel]:
    """Meta-learn across multiple models to find common patterns."""
    if not models:
        return None
    
    # Weighted average based on confidence (inverse uncertainty)
    weights = [1.0 / (m.uncertainty + 0.01) for m in models]
    total_weight = sum(weights)
    
    if total_weight == 0:
        return None
    
    # Weighted mean
    meta_value = sum(m.estimated_value * w for m, w in zip(models, weights)) / total_weight
    
    # Combined uncertainty (weighted average)
    meta_uncertainty = sum(m.uncertainty * w for m, w in zip(models, weights)) / total_weight
    
    # Combined confidence interval (conservative: widest range)
    ci_lower = min(m.confidence_interval[0] for m in models)
    ci_upper = max(m.confidence_interval[1] for m in models)
    
    # Average R²
    avg_r_squared = sum(m.r_squared for m in models) / len(models)
    
    return LearnedModel(
        scenario_name="meta_learned",
        parameter_name=models[0].parameter_name,
        estimated_value=meta_value,
        uncertainty=meta_uncertainty,
        confidence_interval=(ci_lower, ci_upper),
        r_squared=avg_r_squared,
        n_samples=sum(m.n_samples for m in models),
        metadata={
            "meta_learned_from": [m.scenario_name for m in models],
            "n_models": len(models)
        }
    )


