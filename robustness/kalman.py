"""
Kalman Filter for Non-Stationary HHV Learning

Addresses Critique #2: The Stationarity Fallacy in Bayesian Learning

Replaces static Bayesian update with Kalman filter to track moving mean
as Field 2 ramps up and HHV shifts over time.
"""

import numpy as np
from typing import Tuple, Optional, List
from dataclasses import dataclass
import logging


@dataclass
class KalmanHHVState:
    """State of Kalman filter for HHV tracking."""
    mean: float  # Current mean estimate μ_t
    variance: float  # Current variance estimate σ²_t
    process_variance: float  # Process noise (how much mean can change per step)
    observation_variance: float  # Observation noise (measurement uncertainty)
    trend: float  # Estimated trend (change per observation)
    confidence: float  # Confidence in estimate [0, 1]


class KalmanHHVLearner:
    """
    Kalman filter for tracking non-stationary HHV distribution.
    
    Model:
        μ_t = μ_{t-1} + trend + w_t  (state evolution with trend)
        y_t = μ_t + v_t              (observation)
    
    Where:
        w_t ~ N(0, Q)  (process noise)
        v_t ~ N(0, R)  (observation noise)
        trend ~ estimated from data
    """
    
    def __init__(self, 
                 initial_mean: float = 1090.0,
                 initial_std: float = 10.0,
                 process_noise: float = 2.0,  # How much mean can change per observation
                 observation_noise: float = 10.0,  # Measurement uncertainty
                 damping_factor: float = 0.9):  # Damping factor for trend (0 < phi < 1)
        """
        Initialize Kalman filter.
        
        Args:
            initial_mean: Initial HHV estimate
            initial_std: Initial uncertainty
            process_noise: Process variance Q (how much mean can drift)
            observation_noise: Observation variance R (measurement error)
            damping_factor: Factor to dampen trend projection (avoids overshoot)
        """
        self.state = KalmanHHVState(
            mean=initial_mean,
            variance=initial_std ** 2,
            process_variance=process_noise ** 2,
            observation_variance=observation_noise ** 2,
            trend=0.0,  # Initially no trend
            confidence=0.5  # Low initial confidence
        )
        self.damping_factor = damping_factor
        self.observations: List[float] = []
        self.estimates: List[Tuple[float, float]] = []  # (mean, std) over time
    
    def update(self, observation: float) -> Tuple[float, float, float]:
        """
        Update Kalman filter with new observation.
        
        Kalman filter equations:
        1. Predict: μ_{t|t-1} = μ_{t-1} + trend, P_{t|t-1} = P_{t-1} + Q
        2. Update: K = P_{t|t-1} / (P_{t|t-1} + R)
                   μ_t = μ_{t|t-1} + K * (y_t - μ_{t|t-1})
                   P_t = (1 - K) * P_{t|t-1}
        
        Args:
            observation: New HHV measurement
            
        Returns:
            (mean, std, confidence)
        """
        self.observations.append(observation)
        n = len(self.observations)
        
        # Estimate trend from recent observations (if we have enough data)
        if n >= 3:
            # Use linear regression on last 10 observations to estimate trend
            window_size = min(10, n)
            recent_obs = np.array(self.observations[-window_size:])
            x = np.arange(window_size)
            
            # Linear regression: y = a + b*x
            # b = trend per observation
            if window_size > 1:
                trend_estimate = np.polyfit(x, recent_obs, 1)[0]  # Slope
                # Smooth trend estimate (exponential moving average)
                self.state.trend = 0.7 * self.state.trend + 0.3 * trend_estimate
            else:
                self.state.trend = 0.0
        else:
            self.state.trend = 0.0
        
        # Predict step
        # Apply damping to trend projection: mu_{t|t-1} = mu_{t-1} + phi * trend
        # This prevents overshoot when the trend stabilizes (sigmoid behavior)
        predicted_mean = self.state.mean + self.state.trend * self.damping_factor
        predicted_variance = self.state.variance + self.state.process_variance
        
        # Update step (Kalman gain)
        kalman_gain = predicted_variance / (predicted_variance + self.state.observation_variance)
        
        # Innovation (residual)
        innovation = observation - predicted_mean
        
        # Update state
        self.state.mean = predicted_mean + kalman_gain * innovation
        self.state.variance = (1 - kalman_gain) * predicted_variance
        
        # Update confidence based on number of observations and variance
        # Confidence increases with more observations, decreases with high variance
        effective_n = min(n, 50)  # Cap at 50 for confidence calculation
        variance_factor = 1.0 / (1.0 + self.state.variance / (self.state.observation_variance ** 2))
        self.state.confidence = min(0.95, 0.5 + 0.45 * (effective_n / 50) * variance_factor)
        
        # Store estimate
        std = np.sqrt(self.state.variance)
        self.estimates.append((self.state.mean, std))
        
        return self.state.mean, std, self.state.confidence
    
    def batch_update(self, observations: np.ndarray) -> Tuple[float, float, float]:
        """
        Update with multiple observations at once.
        
        Args:
            observations: Array of HHV measurements
            
        Returns:
            (mean, std, confidence) after all updates
        """
        for obs in observations:
            self.update(obs)
        
        return self.state.mean, np.sqrt(self.state.variance), self.state.confidence
    
    def get_current_estimate(self) -> Tuple[float, float, float]:
        """Get current estimate without updating."""
        return (self.state.mean, 
                np.sqrt(self.state.variance), 
                self.state.confidence)
    
    def get_trend(self) -> float:
        """Get estimated trend (change per observation)."""
        return self.state.trend
    
    def predict_future(self, steps_ahead: int = 1) -> Tuple[float, float]:
        """
        Predict future HHV mean and uncertainty.
        
        Args:
            steps_ahead: Number of steps to predict ahead
            
        Returns:
            (predicted_mean, predicted_std)
        """
        # Apply damping to future predictions too
        # trend contribution decays over time: sum(phi^i * trend)
        trend_contribution = 0.0
        current_trend = self.state.trend
        for _ in range(steps_ahead):
            current_trend *= self.damping_factor
            trend_contribution += current_trend
            
        predicted_mean = self.state.mean + trend_contribution
        # Uncertainty grows with prediction horizon
        predicted_variance = self.state.variance + self.state.process_variance * steps_ahead
        predicted_std = np.sqrt(predicted_variance)
        
        return predicted_mean, predicted_std


def learn_hhv_kalman(observations: np.ndarray,
                     prior_mean: float = 1090.0,
                     prior_std: float = 10.0,
                     process_noise: float = 2.0,
                     observation_noise: float = 10.0) -> Tuple[float, float, float, float]:
    """
    Learn HHV distribution using Kalman filter (non-stationary).
    
    This replaces the static Bayesian update with a dynamic model that
    tracks trends (e.g., Field 2 ramping up → HHV decreasing).
    
    Args:
        observations: Observed HHV values
        prior_mean: Initial mean estimate
        prior_std: Initial standard deviation
        process_noise: Process variance (how much mean can change)
        observation_noise: Observation variance (measurement error)
        
    Returns:
        Tuple of (posterior_mean, posterior_std, confidence, trend)
    """
    learner = KalmanHHVLearner(
        initial_mean=prior_mean,
        initial_std=prior_std,
        process_noise=process_noise,
        observation_noise=observation_noise
    )
    
    mean, std, confidence = learner.batch_update(observations)
    trend = learner.get_trend()
    
    logging.info(f"Kalman filter: μ={mean:.2f} ± {std:.2f}, trend={trend:.3f} BTU/scf per obs, conf={confidence:.3f}")
    
    return mean, std, confidence, trend

