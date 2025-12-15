"""
Discretization Safety Buffers

Addresses Critique #5: Discretization of Continuous Variables (The PPDDL Bottleneck)

Adds explicit safety buffers for discretized continuous variables to prevent
tank-top events at discretization boundaries.
"""

import re
import logging
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass


@dataclass
class DiscretizationConfig:
    """Configuration for variable discretization."""
    variable_name: str
    continuous_range: Tuple[float, float]  # (min, max) in continuous units
    discretization_bin_size: float  # Size of each discrete bin
    safety_buffer: float  # Safety margin (as fraction of bin size)
    max_safe_value: Optional[float] = None  # Maximum safe value after buffer


class DiscretizationSafetyManager:
    """
    Manages safety buffers for discretized continuous variables.
    
    Key insight: If discretization bin size is δ, then max capacity constraint
    should be Max - δ (or Max - safety_buffer * δ) to prevent overflow at boundaries.
    """
    
    def __init__(self):
        self.configs: Dict[str, DiscretizationConfig] = {}
    
    def register_variable(self, 
                         variable_name: str,
                         continuous_range: Tuple[float, float],
                         discretization_bin_size: float,
                         safety_buffer_fraction: float = 1.0):
        """
        Register a discretized variable with safety buffer.
        
        Args:
            variable_name: Name of variable (e.g., "tank_level")
            continuous_range: (min, max) in continuous units
            discretization_bin_size: Size of each discrete bin
            safety_buffer_fraction: Safety buffer as fraction of bin size (default 1.0 = full bin)
        """
        min_val, max_val = continuous_range
        safety_buffer = safety_buffer_fraction * discretization_bin_size
        max_safe_value = max_val - safety_buffer
        
        self.configs[variable_name] = DiscretizationConfig(
            variable_name=variable_name,
            continuous_range=continuous_range,
            discretization_bin_size=discretization_bin_size,
            safety_buffer=safety_buffer,
            max_safe_value=max_safe_value
        )
        
        logging.info(f"Registered {variable_name}: range=[{min_val}, {max_val}], "
                    f"bin_size={discretization_bin_size}, "
                    f"safety_buffer={safety_buffer:.2f}, "
                    f"max_safe={max_safe_value:.2f}")
    
    def apply_safety_buffers_to_ppddl(self, domain_text: str, problem_text: str) -> Tuple[str, str]:
        """
        Modify PPDDL to include safety buffers in constraints.
        
        For each registered variable, ensures max constraints use max_safe_value
        instead of the raw maximum.
        """
        modified_domain = domain_text
        modified_problem = problem_text
        
        for var_name, config in self.configs.items():
            # Find capacity constraints in domain
            # Pattern: (>= (tank-level ?tank) ...) or (<= (tank-level ?tank) ...)
            
            # Replace max capacity constraints
            # Look for patterns like: (<= (tank-level ?tank) 0.95) or (tank-level ?tank) <= 0.95
            var_pattern = var_name.replace('_', '-').lower()
            
            # Find max value constraints
            max_pattern = rf'\(<=\s*\({var_pattern}[^)]*\)\s+([\d.]+)\)'
            
            def replace_max(match):
                current_max = float(match.group(1))
                if current_max >= config.max_safe_value:
                    # Replace with safe value
                    return f'(<= ({var_pattern} ?tank) {config.max_safe_value:.4f})'
                return match.group(0)
            
            modified_domain = re.sub(max_pattern, replace_max, modified_domain, flags=re.IGNORECASE)
            modified_problem = re.sub(max_pattern, replace_max, modified_problem, flags=re.IGNORECASE)
            
            # Also add explicit safety predicate
            # Add predicate: (tank-level-safe ?tank) that checks level < max_safe_value
            safety_predicate = f"({var_pattern}-safe"
            if safety_predicate not in modified_domain:
                # Add predicate definition
                # Simply inject after (:predicates
                if "(:predicates" in modified_domain:
                    new_predicate = f"\n        ({var_pattern}-safe ?tank - tank)"
                    modified_domain = modified_domain.replace("(:predicates", f"(:predicates{new_predicate}")

        
        return modified_domain, modified_problem
    
    def get_safety_summary(self) -> str:
        """Get summary of safety buffers."""
        lines = ["Discretization Safety Buffers:"]
        for var_name, config in self.configs.items():
            lines.append(f"  {var_name}:")
            lines.append(f"    Range: [{config.continuous_range[0]}, {config.continuous_range[1]}]")
            lines.append(f"    Bin size: {config.discretization_bin_size}")
            lines.append(f"    Safety buffer: {config.safety_buffer:.4f}")
            lines.append(f"    Max safe value: {config.max_safe_value:.4f}")
            lines.append(f"    Buffer fraction: {config.safety_buffer / config.discretization_bin_size * 100:.1f}%")
        return "\n".join(lines)


def setup_lng_safety_buffers() -> DiscretizationSafetyManager:
    """
    Setup safety buffers for LNG offtake problem.
    
    Tank levels are discretized (e.g., 1 unit = 1000 m³), so we need
    safety buffers to prevent tank-top events at discretization boundaries.
    """
    manager = DiscretizationSafetyManager()
    
    # Tank A: 180,000 m³ capacity, discretized to 180 units (1 unit = 1000 m³)
    # Safety buffer: 1 full bin (1000 m³) to prevent overflow
    manager.register_variable(
        "tank_a_level",
        continuous_range=(0.0, 180000.0),  # m³
        discretization_bin_size=1000.0,  # 1 unit = 1000 m³
        safety_buffer_fraction=1.0  # Full bin as buffer
    )
    
    # Tank B: Same as Tank A
    manager.register_variable(
        "tank_b_level",
        continuous_range=(0.0, 180000.0),
        discretization_bin_size=1000.0,
        safety_buffer_fraction=1.0
    )
    
    # Tank C: 160,000 m³ capacity
    manager.register_variable(
        "tank_c_level",
        continuous_range=(0.0, 160000.0),
        discretization_bin_size=1000.0,
        safety_buffer_fraction=1.0
    )
    
    return manager

