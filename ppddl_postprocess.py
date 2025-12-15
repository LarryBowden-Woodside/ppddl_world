"""
Fix syntax issues in LLM-generated PPDDL for probabilistic-ff compatibility.
"""

import re


def fix_ppddl_syntax(domain_text, problem_text):
    # Clean up LLM-generated PPDDL: remove markdown, fix whenp syntax, etc.
    # Raises ValueError if input is a stub/placeholder
    
    # Detect and handle stub responses
    if domain_text.strip() in ["<ppddl domain>", "[STUB]", ""] or domain_text.strip().startswith("[STUB]"):
        raise ValueError("Domain text is a stub/placeholder. LLM synthesis failed or API key not configured.")
    
    if problem_text.strip() in ["<ppddl problem>", "[STUB]", ""] or problem_text.strip().startswith("[STUB]"):
        raise ValueError("Problem text is a stub/placeholder. LLM synthesis failed or API key not configured.")
    
    # Remove markdown code blocks
    domain_text = re.sub(r'```ppddl\s*\n?', '', domain_text)
    domain_text = re.sub(r'```\s*\n?', '', domain_text)
    problem_text = re.sub(r'```ppddl\s*\n?', '', problem_text)
    problem_text = re.sub(r'```\s*\n?', '', problem_text)
    
    # Fix nested :goal (e.g., (:goal (:goal 0.95 ...)) -> (:goal 0.95 ...))
    problem_text = re.sub(r'\(:goal\s+\(:goal\s+([\d.]+)', r'(:goal \1', problem_text)
    # Also fix :goal with extra nesting: (:goal\n    (:goal 1.0 ...))
    problem_text = re.sub(r'\(:goal\s+\n\s+\(:goal\s+([\d.]+)', r'(:goal \1', problem_text)
    
    # Fix invalid whenp syntax
    # whenp needs a probability number (0.0-1.0), not a condition
    # Pattern: (whenp (condition) effect) -> (whenp 0.9 effect)
    # This is a heuristic - proper fix would require semantic understanding
    def fix_whenp(match):
        condition = match.group(1)
        effect = match.group(2)
        # Heuristic: if condition looks like a comparison, use default probability
        if any(op in condition for op in ['>=', '<=', '>', '<', '=', 'and', 'or', 'not']):
            return f'(whenp 0.9 {effect})'
        # If it's already a number, keep it
        try:
            prob = float(condition.strip())
            if 0.0 <= prob <= 1.0:
                return f'(whenp {prob} {effect})'
        except:
            pass
        # Default to 0.9
        return f'(whenp 0.9 {effect})'
    
    # Fix whenp with conditions - simple character-by-character parser
    # Pattern: (whenp (condition) (effect)) -> (whenp 0.9 (effect))
    # Also handles: (whenp 0.9 0.9 0.0194 (effect)) -> (whenp 0.9 (effect))
    def fix_whenp_simple(text):
        """Fix whenp expressions: replace condition with probability 0.9, remove duplicate numbers."""
        result = []
        i = 0
        while i < len(text):
            if text[i:i+7] == '(whenp ':
                # Replace with (whenp 0.9 
                result.append('(whenp 0.9 ')
                i += 7
                # Skip whitespace
                while i < len(text) and text[i] in ' \n\t':
                    i += 1
                
                # Handle multiple cases:
                # 1. (whenp (condition) effect) - skip condition
                # 2. (whenp 0.9 0.9 0.0194 effect) - skip all numbers until we find effect
                # 3. (whenp 0.9 effect) - already correct, skip number
                
                # Check if next char is '(' - it's a condition
                if i < len(text) and text[i] == '(':
                    paren_count = 0
                    while i < len(text):
                        if text[i] == '(':
                            paren_count += 1
                        elif text[i] == ')':
                            paren_count -= 1
                            if paren_count == 0:
                                i += 1  # Skip closing paren
                                break
                        i += 1
                else:
                    # It's a number or multiple numbers - skip all numbers and whitespace
                    # until we find the effect (which starts with '(')
                    while i < len(text):
                        if text[i] in ' \n\t':
                            i += 1
                        elif text[i] in '0123456789.-':
                            # Skip the number
                            while i < len(text) and text[i] in '0123456789.-':
                                i += 1
                        elif text[i] == '(':
                            # Found the effect, stop here
                            break
                        else:
                            # Unexpected character, stop
                            break
                
                # Skip whitespace after condition/numbers
                while i < len(text) and text[i] in ' \n\t':
                    i += 1
                # Rest (effect) stays as-is, continue from here
            else:
                result.append(text[i])
                i += 1
        return ''.join(result)
    
    domain_text = fix_whenp_simple(domain_text)
    
    # Remove numeric fluents (probabilistic-ff doesn't support them)
    # Remove (increase ...) statements from effects
    domain_text = re.sub(r'\(\s*increase\s+\([^)]+\)\s+[^)]+\)', '', domain_text)
    # Remove numeric comparisons from preconditions (>=, <=, >, <)
    # Be careful - only remove if they're standalone comparisons
    domain_text = re.sub(r'\(\s*(>=|<=|>|<)\s+\?[a-z]+\s+[^)]+\)', '', domain_text)
    domain_text = re.sub(r'\(\s*(>=|<=|>|<)\s+\([^)]+\)\s+[^)]+\)', '', domain_text)
    # Remove predicates with unbound variables from preconditions/effects
    # (e.g., (total-time ?time) where ?time is not in parameters)
    # This is a heuristic - remove predicates that reference variables not in action parameters
    domain_text = re.sub(r'\(\s*([a-z-]+)\s+\?[a-z]+\s*\)\s*\n', '', domain_text)
    # Also fix predicates in effects that reference undefined variables
    # Pattern: (predicate ?var) where ?var is not in action parameters -> (predicate)
    # But be careful - only do this for predicates that don't need parameters
    # For now, just remove the variable if it's clearly unbound
    domain_text = re.sub(r'\(\s*(energy-cost|total-time)\s+\?[a-z]+\s*\)', r'(\1)', domain_text)
    # Fix empty preconditions: if precondition is just (and) with nothing, make it a simple true condition
    domain_text = re.sub(r':precondition\s+\(and\s*\)', ':precondition (and)', domain_text)
    # If precondition is empty after cleaning, add a dummy true condition
    domain_text = re.sub(r':precondition\s+\(and\s+\)', ':precondition (and)', domain_text)
    # Remove numeric predicates that use 'number', 'int', 'float' types from predicate definitions
    # But keep the predicate name - just remove the typed parameter
    domain_text = re.sub(r'\(\s*([a-z-]+)\s+\?[a-z]+\s*-\s*(number|int|float)\s*\)', r'(\1)', domain_text, flags=re.IGNORECASE)
    
    # Remove invalid type references in parameters (int, float, number)
    domain_text = re.sub(r'\?[a-z]+\s*-\s*(int|float|number)', '', domain_text, flags=re.IGNORECASE)
    
    # Remove predicates with numeric values in effects (e.g., (energy-cost 1.95))
    # Pattern: (predicate-name numeric-value) -> (predicate-name)
    domain_text = re.sub(r'\(\s*([a-z-]+)\s+[\d.]+\s*\)', r'(\1)', domain_text)
    
    # Remove arithmetic operations (e.g., (+ ?time ?duration))
    domain_text = re.sub(r'\(\s*[+\-*/]\s+[^)]+\)', '', domain_text)
    
    # Clean up empty predicates in effects (e.g., (total-time ) -> remove)
    domain_text = re.sub(r'\(\s*([a-z-]+)\s+\)', r'(\1)', domain_text)
    # Remove predicates with just whitespace
    domain_text = re.sub(r'\(\s*([a-z-]+)\s+\s*\)', r'(\1)', domain_text)
    
    # Fix malformed actions with empty :precondition or :effect
    # Pattern: :precondition\n    :effect -> :precondition (and)\n    :effect (and)
    domain_text = re.sub(r':precondition\s*\n\s*:effect\s*\)', ':precondition (and)\n    :effect (and)\n    )', domain_text)
    # Pattern: :precondition\n    :effect   ) -> :precondition (and)\n    :effect (and)\n    )
    domain_text = re.sub(r':precondition\s*\n\s*:effect\s+\)', ':precondition (and)\n    :effect (and)\n    )', domain_text)
    # Pattern: :precondition (empty line) :effect -> :precondition (and) :effect (and)
    domain_text = re.sub(r':precondition\s+\)', ':precondition (and)\n    )', domain_text)
    domain_text = re.sub(r':effect\s+\)', ':effect (and)\n    )', domain_text)
    
    # Fix :precondition followed directly by :effect on same or next line (missing value)
    # Pattern: :precondition     :effect (and -> :precondition (and)\n    :effect (and
    domain_text = re.sub(r':precondition\s+:effect\s+\(and', ':precondition (and)\n    :effect (and', domain_text)
    # Pattern: :precondition     :effect -> :precondition (and)\n    :effect (and)
    domain_text = re.sub(r':precondition\s+:effect', ':precondition (and)\n    :effect (and)', domain_text)
    
    # Fix actions with empty parameters: :parameters () -> :parameters (?x - object)
    # But only if the action has no other parameters defined
    domain_text = re.sub(r':parameters\s+\(\)', ':parameters (?x - object)', domain_text)
    
    # Fix problem file: remove numeric comparisons from goal, replace with simple predicate
    # If goal has numeric comparisons, replace with a simple predicate goal
    if re.search(r'\(:goal\s+[\d.]+\s+\(and\s+.*(>=|<=|>|<)', problem_text, flags=re.DOTALL):
        # Replace complex numeric goal with simple predicate goal
        # Match from (:goal to the closing paren, handling nested parens
        goal_pattern = r'\(:goal\s+[\d.]+\s+\(and[^)]*(?:\([^)]*\)[^)]*)*\)\s*\)'
        # Try to find a valid object from the problem
        objects_match = re.search(r'\(:objects\s+([^)]+)\)', problem_text)
        if objects_match:
            objects_text = objects_match.group(1)
            first_obj_match = re.search(r'(\w+)\s+-', objects_text)
            if first_obj_match:
                first_obj = first_obj_match.group(1)
                problem_text = re.sub(
                    goal_pattern,
                    f'(:goal 1.0 (at-rover {first_obj}))',
                    problem_text,
                    flags=re.DOTALL
                )
            else:
                problem_text = re.sub(
                    goal_pattern,
                    '(:goal 1.0 (at-rover rover1))',
                    problem_text,
                    flags=re.DOTALL
                )
        else:
            problem_text = re.sub(
                goal_pattern,
                '(:goal 1.0 (at-rover rover1))',
                problem_text,
                flags=re.DOTALL
            )
    # Also remove any remaining numeric comparisons from goal (fallback)
    problem_text = re.sub(r'\(\s*(>=|<=|>|<)\s+\([^)]+\)\s+[^)]+\)', '', problem_text)
    # Fix empty goals: if goal is empty or just (and), replace with valid predicate
    # Use objects that exist in the problem (extract first object of each type)
    if re.search(r'\(:goal\s+[\d.]+\s+\(and\s*\)', problem_text):
        # Try to find a valid object from the problem
        objects_match = re.search(r'\(:objects\s+([^)]+)\)', problem_text)
        if objects_match:
            objects_text = objects_match.group(1)
            # Extract first object name (e.g., "rover1" from "rover1 - rover_state_type")
            first_obj_match = re.search(r'(\w+)\s+-', objects_text)
            if first_obj_match:
                first_obj = first_obj_match.group(1)
                # Use a simple predicate that likely exists
                problem_text = re.sub(
                    r'\(:goal\s+[\d.]+\s+\(and\s*\)',
                    f'(:goal 1.0 (at-rover {first_obj})',
                    problem_text
                )
            else:
                problem_text = re.sub(
                    r'\(:goal\s+[\d.]+\s+\(and\s*\)',
                    '(:goal 1.0 (at-rover rover1)',
                    problem_text
                )
        else:
            problem_text = re.sub(
                r'\(:goal\s+[\d.]+\s+\(and\s*\)',
                '(:goal 1.0 (at-rover rover1)',
                problem_text
            )
    # Remove numeric fluent assignments from init (e.g., (total-time 0))
    problem_text = re.sub(r'\(\s*([a-z-]+)\s+\d+\s*\)', '', problem_text)
    
    # Remove (not ...) from :init section (probabilistic-ff doesn't support negative literals in init)
    # Simple approach: remove lines containing (not ...) within :init section
    lines = problem_text.split('\n')
    in_init = False
    cleaned_lines = []
    for line in lines:
        if ':init' in line:
            in_init = True
            cleaned_lines.append(line)
        elif in_init and line.strip().startswith(')'):
            in_init = False
            cleaned_lines.append(line)
        elif in_init:
            # Skip lines with (not ...)
            if not re.search(r'\(\s*not\s+\(', line, re.IGNORECASE):
                cleaned_lines.append(line)
        else:
            cleaned_lines.append(line)
    problem_text = '\n'.join(cleaned_lines)
    
    # Remove predicates with numeric values in goal (e.g., (total-time ?time) where ?time is unbound)
    # If goal has unbound variables, replace with simple predicate using existing objects
    if re.search(r'\(:goal\s+[\d.]+\s+\([^)]*\?[a-z]+[^)]*\)', problem_text):
        objects_match = re.search(r'\(:objects\s+([^)]+)\)', problem_text)
        if objects_match:
            objects_text = objects_match.group(1)
            first_obj_match = re.search(r'(\w+)\s+-', objects_text)
            if first_obj_match:
                first_obj = first_obj_match.group(1)
                # Replace goal with simple predicate
                problem_text = re.sub(
                    r'\(:goal\s+[\d.]+\s+\([^)]+\)',
                    f'(:goal 1.0 (at-rover {first_obj})',
                    problem_text
                )
    
    # Fix extra closing parentheses in problem (common LLM error)
    # Count and balance parentheses in goal section
    goal_match = re.search(r'\(:goal[^)]*\)', problem_text, re.DOTALL)
    if goal_match:
        goal_text = goal_match.group(0)
        open_parens = goal_text.count('(')
        close_parens = goal_text.count(')')
        # If there are extra closing parens, remove them
        if close_parens > open_parens:
            # Find the goal section and fix it
            problem_text = re.sub(
                r'\(:goal\s+([\d.]+)\s+\(([^)]+)\)\)+',
                r'(:goal \1 (\2))',
                problem_text
            )
    
    # Fix goal with missing closing paren: (:goal 1.0 (at-rover rover1)\n  )
    problem_text = re.sub(r'\(:goal\s+([\d.]+)\s+\(([^)]+)\)\s*\n\s*\)', r'(:goal \1 (\2))', problem_text)
    
    # Remove trailing extra closing parentheses (common LLM error)
    # Pattern: ))) at end -> )
    problem_text = re.sub(r'\)\s*\)\s*\)\s*$', ')', problem_text)  # Remove triple closing
    problem_text = re.sub(r'\)\s*\)\s*$', ')', problem_text)  # Remove double closing at end
    
    # Balance parentheses in problem file (must be done after other fixes)
    open_count = problem_text.count('(')
    close_count = problem_text.count(')')
    if close_count > open_count:
        # Remove extra closing parentheses from the end
        diff = close_count - open_count
        # Remove trailing closing parens (but keep at least one for the problem definition)
        # Find the problem definition closing
        problem_end = problem_text.rfind(')')
        if problem_end != -1 and diff > 0:
            # Remove extra closing parens before the final one
            # Keep the structure: ... (:goal ...)) <- final closing for problem
            # Count how many closing parens are at the very end
            trailing_parens = len(problem_text) - len(problem_text.rstrip(')'))
            if trailing_parens > 1:
                # Remove all but one
                problem_text = problem_text.rstrip(')') + ')'
    elif close_count < open_count:
        # Add missing closing parentheses at the end
        diff = open_count - close_count
        problem_text = problem_text.rstrip() + ')' * diff
    
    # Ensure types are properly defined (add object type if missing)
    if '(:types' in domain_text:
        # Check if types are just names without "object" base
        types_match = re.search(r'\(:types\s+([^)]+)\)', domain_text)
        if types_match:
            types_content = types_match.group(1)
            # If no "object" type is mentioned, add it
            if 'object' not in types_content.lower():
                # Add object as base type
                types_content = 'object\n        ' + types_content.replace('\n', '\n        ')
                domain_text = re.sub(
                    r'\(:types\s+[^)]+\)',
                    f'(:types\n        {types_content}\n    )',
                    domain_text
                )
    
    # Fix predicate usage in whenp (predicates can't be used as conditions in whenp)
    # This is complex - for now, just ensure whenp has numeric probability
    
    # Remove any trailing explanatory text
    domain_text = re.sub(r'\)\s*```.*$', ')', domain_text, flags=re.DOTALL).strip()
    problem_text = re.sub(r'\)\s*```.*$', ')', problem_text, flags=re.DOTALL).strip()
    
    return domain_text, problem_text

