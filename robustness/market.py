"""
Spot Market Bayesian Network

Addresses Critique #4: The "Independent Probability" Fallacy.

Models the correlation between Spot Price and Spot Availability using a simple
Bayesian Network (Condition Probability Table).

P(Availability=High | Price=High) is LOW (Tight market)
P(Availability=High | Price=Low) is HIGH (Oversupply)
"""

import numpy as np
from typing import Tuple

class SpotMarketBayesianNetwork:
    """
    Models joint distribution of Spot Price and Availability.
    
    Network Structure:
    Price -> Availability
    
    CPT (Availability | Price):
    - High Price (> $95M): Low Availability (0.3)
    - Med Price ($85-95M): Med Availability (0.5)
    - Low Price (< $85M): High Availability (0.8)
    """
    
    def __init__(self):
        self.price_mean = 90.0
        self.price_std = 5.0
    
    def sample_market_conditions(self) -> Tuple[float, bool]:
        """
        Sample a spot market scenario (Price, Available).
        
        Returns:
            (price_in_millions, is_available)
        """
        # 1. Sample Price (root node)
        price = np.random.normal(self.price_mean, self.price_std)
        
        # 2. Determine Availability Probability based on Price (child node)
        if price > 95.0:
            # High price -> Tight market -> Low availability
            p_available = 0.3
        elif price < 85.0:
            # Low price -> Oversupply -> High availability
            p_available = 0.8
        else:
            # Medium price -> Medium availability
            p_available = 0.5
            
        # 3. Sample Availability
        is_available = np.random.random() < p_available
        
        return price, is_available

    def get_conditional_probability(self, price: float) -> float:
        """Get P(Available | Price)."""
        if price > 95.0: return 0.3
        if price < 85.0: return 0.8
        return 0.5

