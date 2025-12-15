
import logging
from typing import Dict, List, Tuple, Optional
import agent as sa


def minizinc_to_ppddl_via_llm(
    minizinc_code: str,
    problem_description: str,
    learned_parameters: Optional[Dict] = None
) -> Tuple[str, str]:
    """
    Translate MiniZinc to PPDDL using LLM, with structured constraints.
    
    This approach reduces hallucination by:
    1. Using formal MiniZinc constraints (already extracted)
    2. LLM only needs to translate, not invent constraints
    3. Structured input → more reliable output
    
    Args:
        minizinc_code: Structured MiniZinc constraint code
        problem_description: Natural language problem description (for context)
        learned_parameters: Optional learned parameters to inject
        
    Returns:
        (domain_text, problem_text) PPDDL tuple
    """
    
    # Extract key information from MiniZinc
    constraints = _extract_minizinc_constraints(minizinc_code)
    variables = _extract_minizinc_variables(minizinc_code)
    objectives = _extract_minizinc_objectives(minizinc_code)
    
    # Build structured prompt with formal constraints
    prompt = f"""
You are translating structured MiniZinc constraints to PPDDL.

The problem is: {problem_description}

STRUCTURED CONSTRAINTS (from MiniZinc - these are FORMAL and CORRECT):
{constraints}

VARIABLES (from MiniZinc):
{variables}

OBJECTIVES (from MiniZinc):
{objectives}

{_format_learned_parameters(learned_parameters) if learned_parameters else ""}

TASK: Translate these STRUCTURED constraints to PPDDL.
- DO NOT invent new constraints (use only what's provided)
- DO NOT hallucinate (constraints are already formalized)
- DO translate MiniZinc syntax to PPDDL syntax
- DO preserve constraint semantics exactly

Output EXACTLY two sections delimited by markers (NO markdown, NO code blocks):
===DOMAIN===
(define (domain ...)
  ... PPDDL domain code ...
)

===PROBLEM===
(define (problem ...)
  ... PPDDL problem code ...
)

CRITICAL REQUIREMENTS:
- Use ONLY: :requirements :strips :typing :negation :equality :conditional-effects :adl
- NO markdown code blocks (```ppddl```)
- NO extra text before markers
- For probabilistic effects: (whenp <probability> <effect>) where probability is a number (0.0-1.0)
- Use predicates only (NO numeric fluents, NO functions)
- Goal format: (:goal <probability> <predicate>) where probability is a number
- Types must be defined in (:types ...) section
- Actions must use defined types
"""
    
    bundle = sa.call_llm(prompt)
    domain_text, problem_text = sa.split_domain_problem(bundle)
    
    # Post-process to fix common syntax issues
    from ppddl_postprocess import fix_ppddl_syntax
    domain_text, problem_text = fix_ppddl_syntax(domain_text, problem_text)
    
    # ROBUSTNESS FIX #5: Apply safety buffers for discretized variables
    # This prevents tank-top events at discretization boundaries
    try:
        from robustness.pipeline import RobustnessPipeline
        robustness = RobustnessPipeline(enable_safety_buffers=True)
        domain_text, problem_text = robustness.apply_safety_buffers(domain_text, problem_text)
        logging.info("Applied safety buffers to discretized variables")
    except Exception as e:
        logging.warning(f"Failed to apply safety buffers: {e}")
        # Continue without safety buffers (backward compatible)
    
    return domain_text, problem_text


def _extract_minizinc_constraints(minizinc_code: str) -> str:
    """Extract constraint declarations from MiniZinc."""
    lines = minizinc_code.split('\n')
    constraints = []
    in_constraint = False
    current_constraint = []
    
    for line in lines:
        line = line.strip()
        if line.startswith('constraint'):
            if current_constraint:
                constraints.append(' '.join(current_constraint))
            current_constraint = [line]
            in_constraint = True
        elif in_constraint:
            if line.endswith(';'):
                current_constraint.append(line.rstrip(';'))
                constraints.append(' '.join(current_constraint))
                current_constraint = []
                in_constraint = False
            else:
                current_constraint.append(line)
    
    if current_constraint:
        constraints.append(' '.join(current_constraint))
    
    return '\n'.join(constraints) if constraints else "No explicit constraints found"


def _extract_minizinc_variables(minizinc_code: str) -> str:
    """Extract variable declarations from MiniZinc."""
    lines = minizinc_code.split('\n')
    variables = []
    
    for line in lines:
        line = line.strip()
        if line.startswith('var ') or line.startswith('int:') or line.startswith('float:'):
            variables.append(line)
    
    return '\n'.join(variables) if variables else "No explicit variables found"


def _extract_minizinc_objectives(minizinc_code: str) -> str:
    """Extract objective declarations from MiniZinc."""
    lines = minizinc_code.split('\n')
    objectives = []
    
    for line in lines:
        line = line.strip()
        if 'solve' in line.lower():
            objectives.append(line)
    
    return '\n'.join(objectives) if objectives else "No explicit objectives found"


def _format_learned_parameters(learned_parameters: Dict) -> str:
    """Format learned parameters for inclusion in prompt."""
    if not learned_parameters:
        return ""
    
    lines = ["\nLEARNED PARAMETERS (from world model learning):"]
    for key, value in learned_parameters.items():
        if isinstance(value, dict) and 'value' in value and 'uncertainty' in value:
            lines.append(f"  {key}: {value['value']:.3f} ± {value['uncertainty']:.3f}")
        else:
            lines.append(f"  {key}: {value}")
    
    return '\n'.join(lines)


def hybrid_ctburton_llm_ppddl(
    problem_description: str,
    ctburton_problem,
    learned_parameters: Optional[Dict] = None
) -> Tuple[str, str]:
    """
    Hybrid approach: CTBurton extracts constraints → LLM translates to PPDDL.
    
    Flow:
    1. CTBurton extracts constraints deterministically → MiniZinc
    2. LLM translates structured MiniZinc → PPDDL
    3. Reduces hallucination (constraints already formalized)
    
    Args:
        problem_description: Natural language problem description
        ctburton_problem: CTBurtonProblem object
        learned_parameters: Optional learned parameters
        
    Returns:
        (domain_text, problem_text) PPDDL tuple
    """
    from ctburton import export_for_minizinc, create_unified_problem_format
    
    # Step 1: CTBurton extracts constraints → MiniZinc (deterministic)
    unified_format = create_unified_problem_format()
    unified_format['problem_definition'] = {
        'name': ctburton_problem.name,
        'description': problem_description
    }
    unified_format['entities'] = {
        'automata': [
            {'name': at, 'states': ['idle', 'active', 'completed'], 'type': at}
            for at in ctburton_problem.automata_types
        ],
        'resources': []
    }
    unified_format['constraints'] = [
        {'type': 'temporal', 'description': c, 'expression': c} 
        for c in ctburton_problem.constraints
    ]
    unified_format['objectives'] = [
        {'type': 'minimize' if 'minimize' in o.lower() else 'maximize', 'target': o, 'weight': 1.0}
        for o in ctburton_problem.objectives
    ]
    unified_format['temporal_specification'] = {
        'horizon': ctburton_problem.time_horizon,
        'time_units': 'minutes',
        'discrete': True,
        'granularity': 1
    }
    
    minizinc_code = export_for_minizinc(unified_format)
    
    logging.info("Extracted MiniZinc constraints (structured, formal)")
    logging.info(f"MiniZinc preview: {minizinc_code[:500]}...")
    
    # Step 2: LLM translates structured MiniZinc → PPDDL (less hallucination)
    domain_text, problem_text = minizinc_to_ppddl_via_llm(
        minizinc_code,
        problem_description,
        learned_parameters
    )
    
    logging.info("Translated MiniZinc → PPDDL via LLM (with structured constraints)")
    
    # ROBUSTNESS FIX #1: Model checking - verify MiniZinc invariants are enforced
    # This checks that global constraints are properly translated to action preconditions
    try:
        from robustness.pipeline import RobustnessPipeline
        robustness = RobustnessPipeline(enable_model_checking=True)
        is_valid, violations = robustness.check_ppddl_translation(
            minizinc_code,
            ctburton_problem.constraints,
            domain_text
        )
        
        if violations:
            logging.warning(f"Model checking found {len(violations)} potential constraint violations:")
            for v in violations[:3]:  # Show first 3
                logging.warning(f"  - {v['message']}")
            if len(violations) > 3:
                logging.warning(f"  ... and {len(violations) - 3} more")
        else:
            logging.info("✓ Model checking: All MiniZinc invariants properly enforced")
    except Exception as e:
        logging.warning(f"Model checking failed (non-critical): {e}")
        # Continue without model checking (backward compatible)
    
    return domain_text, problem_text

