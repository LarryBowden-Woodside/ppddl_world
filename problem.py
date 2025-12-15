

from ctburton import CTBurtonProblem
from typing import Dict, List, Any

def create_lng_offtake_ctburton_problem() -> CTBurtonProblem:
    """
    Create a CTBurton problem definition for LNG offtake optimization.
    
    This structured representation enables:
    1. Deterministic constraint extraction (reduces LLM hallucination)
    2. Clear separation of decisions, constraints, and objectives
    3. Explicit uncertainty modeling
    4. Temporal constraint handling
    
    Returns:
        CTBurtonProblem instance with full LNG offtake specification
    """
    
    problem = CTBurtonProblem(
        name="lng_offtake",
        description="LNG offtake optimization with probabilistic quality, vessel arrivals, and spot opportunities",
        
        # Automata types represent the key entities in the system
        automata_types=[
            "train",      # LNG production trains (Train 1, Train 2)
            "tank",       # Storage tanks (Tank A, B, C)
            "vessel",     # Cargo vessels (term + spot)
            "cargo",      # Loading operations
            "berth",      # Loading berth
        ],
        
        # State transitions model the system dynamics
        transitions=[
            # Production: trains continuously fill tanks
            {
                "from": "producing",
                "to": "filling_tank",
                "automaton": "train",
                "duration": [24, 24],  # Continuous 24hr operation
                "probabilistic": True,
                "probability": 0.95,   # 95% uptime (maintenance/trips)
                "effects": {
                    "tank_level": "increase",
                    "hhv": "update_distribution"  # HHV evolves with feed blend
                }
            },
            
            # Vessel arrival: scheduled arrival with uncertainty
            {
                "from": "en_route",
                "to": "arrived",
                "automaton": "vessel",
                "duration": [0, 48],   # ±2 days ETA uncertainty
                "probabilistic": True,
                "probability": 0.85,   # 85% on-time arrival
                "effects": {
                    "berth_queue": "add_vessel"
                }
            },
            
            # Berth allocation: assign vessel to berth
            {
                "from": "arrived",
                "to": "berthed",
                "automaton": "vessel",
                "duration": [2, 4],    # 2-4hr berthing operation
                "preconditions": {
                    "berth_available": True,
                    "turnaround_complete": True,  # 24hr since last vessel
                    "tidal_window": True          # 6hr/day suitable
                },
                "effects": {
                    "berth_occupied": True
                }
            },
            
            # Loading: withdraw from tanks to vessel
            {
                "from": "berthed",
                "to": "loading",
                "automaton": "cargo",
                "duration": [6, 10],   # 6-10hr loading (8-12k m³/hr, weather dependent)
                "probabilistic": True,
                "probability": 0.90,   # 90% nominal conditions
                "preconditions": {
                    "tank_connectivity": True,
                    "tank_level_sufficient": True,
                    "hhv_in_spec_expected": True
                },
                "effects": {
                    "tank_level": "decrease",
                    "cargo_hhv": "mix_from_tanks",
                    "cargo_volume": "increase"
                }
            },
            
            # Departure: complete loading and depart
            {
                "from": "loading",
                "to": "departed",
                "automaton": "cargo",
                "duration": [1, 2],    # 1-2hr departure procedures
                "effects": {
                    "berth_occupied": False,
                    "revenue": "realize",
                    "turnaround_timer": "start_24hr"
                }
            },
            
            # Spot opportunity: optional decision to accept
            {
                "from": "spot_available",
                "to": "spot_accepted",
                "automaton": "cargo",
                "duration": [0, 0],    # Instantaneous decision
                "optional": True,      # Key: this is a decision variable
                "probabilistic": True,
                "probability": 0.70,   # 70% spot cargo materializes if accepted
                "preconditions": {
                    "tank_capacity_available": True,
                    "berth_slot_available": True,
                    "expected_value_positive": True
                },
                "effects": {
                    "spot_cargo_scheduled": True,
                    "expected_revenue": "spot_price_distribution"
                }
            }
        ],
        
        # Constraints define the operational limits
        constraints=[
            # Production constraints
            "Train 1 blend ratio: 41-59% Field 1:Field 2 (fixed, non-negotiable)",
            "Train 2 blend ratio: 100% Field 2 (fixed)",
            "Train 1 production rate: 4.5 MTPA ± 5% (maintenance variance)",
            "Train 2 production rate: 5.0 MTPA ± 5% (maintenance variance)",
            "Train 1 HHV: 1080-1100 BTU/scf (mean=1090, std=10)",
            "Train 2 HHV: 1050-1070 BTU/scf (mean=1060, std=10)",
            "Field 2 ramp-up: +5% production per week",
            "Field 1 ramp-down: -5% production per week",
            
            # Storage constraints
            "Tank A capacity: 180,000 m³ (min 10% heel, max 95% full)",
            "Tank B capacity: 180,000 m³ (min 10% heel, max 95% full)",
            "Tank C capacity: 160,000 m³ (min 10% heel, max 95% full)",
            "Tank connectivity: Train 1 → Tank A, B; Train 2 → Tank B, C",
            "Tank withdrawal: All tanks → Berth (via manifold)",
            "Tank-top risk: penalty $5M if tank >95% full",
            "Operational buffer: maintain 20% headroom in at least one tank",
            "Boil-off cost: $200k/day for excess tank holding",
            
            # Berth and marine constraints
            "Berth capacity: 1 vessel at a time (no overlap)",
            "Berth turnaround: 24hr clearance between vessels",
            "Loading rate: 8,000-12,000 m³/hr (weather dependent, mean=10,000)",
            "Tidal windows: 6hr/day no-sail restrictions",
            "Demurrage cost: $50k/day if loading delayed beyond laytime",
            
            # Commercial constraints
            "Term contracts: 4 cargoes, 75,000 m³ each, fixed revenue $80M",
            "Term laycan windows: ±2 days flexibility around scheduled date",
            "Term laycan compliance: must load within window (hard constraint)",
            "Spot opportunities: 5 available over 30-day horizon, 70,000 m³ each",
            "Spot prices: $85-95M per cargo (uniform distribution, market volatility)",
            "Spot acceptance probability: 70% if accepted (cargo may not materialize)",
            "Spot decision: binary (accept/reject), optional",
            
            # Quality constraints
            "HHV specification: 1055-1095 BTU/scf (contractual range)",
            "HHV compliance probability: ≥95% within spec",
            "HHV penalty: $2M if cargo delivered out-of-spec",
            "Cargo HHV: weighted average of contributing tanks",
            "Tank HHV evolution: updated as trains fill, cargoes withdraw",
            
            # Temporal constraints
            "Planning horizon: 30 days (rolling)",
            "Time discretization: 6-hour blocks (4 per day, 120 total)",
            "Vessel ETA uncertainty: ±1-2 days (48hr window)",
            
            # Uncertainty sources (explicit probabilistic modeling)
            "Uncertainty 1: HHV per train (normal distribution, σ=10 BTU/scf)",
            "Uncertainty 2: Vessel ETAs (uniform ±2 days)",
            "Uncertainty 3: Spot prices (uniform $85-95M)",
            "Uncertainty 4: Production rates (normal ±5%)",
            "Uncertainty 5: Loading rates (weather-dependent, 8-12k m³/hr)",
            "Uncertainty 6: Spot cargo materialization (Bernoulli p=0.70)"
        ],
        
        # Objectives define what we're optimizing
        objectives=[
            "PRIMARY: Maximize expected net value over 30-day horizon",
            "Expected net value = revenues - costs - penalties",
            "Revenues: term cargoes ($80M × 4) + spot cargoes ($85-95M × accepted spots)",
            "Costs: demurrage ($50k/day × delays) + boil-off ($200k/day × excess holding)",
            "Penalties: off-spec HHV ($2M × violations) + tank-top risk ($5M × events)",
            "Risk-adjusted: weight spot opportunities by 70% acceptance probability",
            "Constraint: all 4 term contracts must be satisfied (hard constraint)",
            "Maximize spot opportunities: accept if E[spot_value] > E[costs + risks]",
            "Minimize downside risk: track P10/P50/P90 value outcomes",
            "Stability preference: minimize changes from prior plan (if available)"
        ],
        
        # Time horizon
        time_horizon=720,  # 30 days × 24 hours = 720 hours
        
        # Temporal constraints (structured)
        temporal_constraints=[
            {
                "type": "deadline",
                "description": "Term cargo 1 laycan",
                "start_time": 120,  # Day 5, ±2 days
                "end_time": 216,
                "flexibility": 48   # ±2 days = 48 hours
            },
            {
                "type": "deadline",
                "description": "Term cargo 2 laycan",
                "start_time": 264,  # Day 11, ±2 days
                "end_time": 360,
                "flexibility": 48
            },
            {
                "type": "deadline",
                "description": "Term cargo 3 laycan",
                "start_time": 408,  # Day 17, ±2 days
                "end_time": 504,
                "flexibility": 48
            },
            {
                "type": "deadline",
                "description": "Term cargo 4 laycan",
                "start_time": 552,  # Day 23, ±2 days
                "end_time": 648,
                "flexibility": 48
            },
            {
                "type": "recurring",
                "description": "Tidal no-sail windows",
                "frequency": 24,    # Every 24 hours
                "duration": 18,     # 18hr available (6hr restricted)
                "offset": 6         # Restrictions at hours 6-12 each day
            },
            {
                "type": "minimum_separation",
                "description": "Berth turnaround time",
                "entities": ["vessel"],
                "separation": 24    # 24hr between vessels
            }
        ]
    )
    
    return problem


def get_lng_offtake_learned_parameters() -> Dict[str, Dict[str, Any]]:
    """
    Define parameters that can be learned from observations.
    
    In a real deployment, these would be learned from:
    - Historical HHV measurements
    - Vessel arrival records
    - Spot market prices
    - Production logs
    
    Returns:
        Dictionary of learnable parameters with initial estimates
    """
    
    return {
        "hhv_train1": {
            "description": "HHV distribution for Train 1 (Field 1:Field 2 mix)",
            "parameter_type": "normal_distribution",
            "initial_mean": 1090.0,
            "initial_std": 10.0,
            "true_value": None,  # Unknown, to be learned
            "units": "BTU/scf",
            "learning_method": "bayesian_update",
            "observation_frequency": "daily"
        },
        "hhv_train2": {
            "description": "HHV distribution for Train 2 (100% Field 2)",
            "parameter_type": "normal_distribution",
            "initial_mean": 1060.0,
            "initial_std": 10.0,
            "true_value": None,
            "units": "BTU/scf",
            "learning_method": "bayesian_update",
            "observation_frequency": "daily"
        },
        "field2_ramp_rate": {
            "description": "Field 2 production ramp-up rate",
            "parameter_type": "linear_trend",
            "initial_value": 0.05,  # 5% per week
            "initial_uncertainty": 0.01,
            "true_value": None,
            "units": "fraction/week",
            "learning_method": "linear_regression",
            "observation_frequency": "weekly"
        },
        "vessel_eta_uncertainty": {
            "description": "Vessel ETA deviation from schedule",
            "parameter_type": "uniform_distribution",
            "initial_range": [-48, 48],  # ±2 days
            "initial_mean": 0,
            "true_value": None,
            "units": "hours",
            "learning_method": "distribution_fitting",
            "observation_frequency": "per_vessel"
        },
        "spot_price_mean": {
            "description": "Mean spot cargo price",
            "parameter_type": "continuous",
            "initial_value": 90.0,  # $90M midpoint
            "initial_uncertainty": 5.0,
            "true_value": None,
            "units": "million_usd",
            "learning_method": "exponential_smoothing",
            "observation_frequency": "per_spot_opportunity"
        },
        "spot_acceptance_probability": {
            "description": "Probability that accepted spot cargo materializes",
            "parameter_type": "bernoulli",
            "initial_value": 0.70,
            "initial_uncertainty": 0.10,
            "true_value": None,
            "units": "probability",
            "learning_method": "beta_bernoulli",
            "observation_frequency": "per_spot_decision"
        },
        "loading_rate_mean": {
            "description": "Mean loading rate (weather-dependent)",
            "parameter_type": "continuous",
            "initial_value": 10000.0,  # 10k m³/hr
            "initial_range": [8000, 12000],
            "initial_uncertainty": 1000.0,
            "true_value": None,
            "units": "cubic_meters_per_hour",
            "learning_method": "exponential_smoothing",
            "observation_frequency": "per_loading"
        }
    }


def get_lng_offtake_kpis() -> List[Dict[str, Any]]:
    """
    Define Key Performance Indicators for the LNG offtake problem.
    
    These KPIs are what we'll report to management and track over time.
    
    Returns:
        List of KPI definitions with targets and thresholds
    """
    
    return [
        {
            "name": "Total Net Value (Expected)",
            "description": "Expected net value over planning horizon",
            "unit": "million_usd",
            "target": 320.0,  # 4 term @ $80M = $320M baseline
            "calculation": "sum(revenues) - sum(costs) - sum(penalties)",
            "importance": "critical"
        },
        {
            "name": "Value at Risk (P10)",
            "description": "10th percentile outcome (downside risk)",
            "unit": "million_usd",
            "target": 280.0,  # $40M downside tolerance
            "calculation": "percentile(net_value_distribution, 10)",
            "importance": "critical"
        },
        {
            "name": "Spot Cargoes Accepted",
            "description": "Number of spot opportunities accepted",
            "unit": "count",
            "target": 3.0,  # Accept 3 out of 5 if favorable
            "calculation": "sum(spot_acceptance_decisions)",
            "importance": "high"
        },
        {
            "name": "Expected Demurrage",
            "description": "Expected demurrage costs from delays",
            "unit": "million_usd",
            "target": 0.5,  # <$500k target
            "calculation": "sum(delay_days × $50k)",
            "importance": "high"
        },
        {
            "name": "HHV Compliance Rate",
            "description": "Probability that all cargoes meet HHV spec",
            "unit": "probability",
            "target": 0.95,  # 95% confidence target
            "calculation": "product(P(hhv_in_spec) for all cargoes)",
            "importance": "critical"
        },
        {
            "name": "Tank-Top Events",
            "description": "Expected number of tank >95% full events",
            "unit": "count",
            "target": 0.0,  # Zero tolerance
            "calculation": "sum(P(tank_level > 0.95) × time_periods)",
            "importance": "critical"
        },
        {
            "name": "Berth Utilization",
            "description": "Percentage of time berth is occupied",
            "unit": "percentage",
            "target": 0.65,  # 65% target (not too low, not too high)
            "calculation": "sum(berth_occupied_time) / total_time",
            "importance": "medium"
        },
        {
            "name": "Term Contract Compliance",
            "description": "All term contracts loaded within laycan",
            "unit": "boolean",
            "target": True,  # Must be 100%
            "calculation": "all(loaded_within_laycan for term_cargoes)",
            "importance": "critical"
        },
        {
            "name": "Plan Stability",
            "description": "Similarity to previous plan (minimize churn)",
            "unit": "percentage",
            "target": 0.80,  # 80% similarity preferred
            "calculation": "similarity(current_plan, previous_plan)",
            "importance": "medium"
        }
    ]


if __name__ == "__main__":
    # Demo: create and display the problem
    problem = create_lng_offtake_ctburton_problem()
    
    print("=" * 80)
    print("LNG OFFTAKE PROBLEM DEFINITION")
    print("=" * 80)
    print(f"\nProblem: {problem.name}")
    print(f"Description: {problem.description}")
    print(f"\nAutomata types: {len(problem.automata_types)}")
    for automaton in problem.automata_types:
        print(f"  - {automaton}")
    
    print(f"\nTransitions: {len(problem.transitions)}")
    for i, trans in enumerate(problem.transitions[:3]):  # Show first 3
        print(f"  {i+1}. {trans['from']} → {trans['to']} ({trans.get('automaton', 'general')})")
    if len(problem.transitions) > 3:
        print(f"  ... and {len(problem.transitions) - 3} more")
    
    print(f"\nConstraints: {len(problem.constraints)}")
    for i, constraint in enumerate(problem.constraints[:5]):  # Show first 5
        print(f"  {i+1}. {constraint}")
    if len(problem.constraints) > 5:
        print(f"  ... and {len(problem.constraints) - 5} more")
    
    print(f"\nObjectives: {len(problem.objectives)}")
    for i, objective in enumerate(problem.objectives):
        print(f"  {i+1}. {objective}")
    
    print(f"\nTemporal constraints: {len(problem.temporal_constraints)}")
    for tc in problem.temporal_constraints:
        print(f"  - {tc['type']}: {tc['description']}")
    
    print(f"\nTime horizon: {problem.time_horizon} hours ({problem.time_horizon/24:.1f} days)")
    
    print("\n" + "=" * 80)
    print("LEARNABLE PARAMETERS")
    print("=" * 80)
    params = get_lng_offtake_learned_parameters()
    for name, param in params.items():
        print(f"\n{name}:")
        print(f"  Description: {param['description']}")
        print(f"  Type: {param['parameter_type']}")
        print(f"  Learning method: {param['learning_method']}")
    
    print("\n" + "=" * 80)
    print("KEY PERFORMANCE INDICATORS")
    print("=" * 80)
    kpis = get_lng_offtake_kpis()
    for kpi in kpis:
        print(f"\n{kpi['name']} ({kpi['importance']})")
        print(f"  Target: {kpi['target']} {kpi['unit']}")
        print(f"  {kpi['description']}")

