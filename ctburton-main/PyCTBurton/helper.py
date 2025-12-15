'''
Set of helper functions for creating MZN model strings
Author : Marlyse Reeves
Edited by : Anoopkumar Sonar
'''
import os.path
from typing import Union, Literal, Iterable, Dict
from minizinc import Model, Solver, Instance
import os
from workload_management import MODULE_PATH

def mzn_var(name: str, lb: Union[int, float], ub: Union[int, float]):
    return f'var {lb}..{ub}: {name};'

def mzn_vars_from_list(V: list[str], lb: Union[int, float], ub: Union[int, float]):
    return [mzn_var(name, lb, ub) for name in V]

def mzn_par(name: str, type: Literal['float', 'int'], val: Union[int, float]):
    return f'{type}: {name} = {val};'

def mzn_constraint(expr: str):
    return f'constraint {expr};'

# Not using this functtion for now
# def mzn_stc(start, end, lb, ub):
#     return f'stc({start}, {end}, {lb}, {ub})'

def mzn_implication(expr1: str, expr2: str):
    return f'{expr1} -> {expr2}'

def mzn_and(expr1: str, expr2: str):
    return f'({expr1} /\\ {expr2})'

def mzn_or(expr1: str, expr2: str):
    return f'({expr1} \\/ {expr2})'

def mzn_solve(how: Literal['satisfy', 'maximize', 'minimize'], obj: str = None, annotation: str = None):
    assert how == 'satisfy' or obj is not None, "Maximize/minimize requires an objective expression"
    sol_str = f'solve :: {annotation}\n' if annotation is not None else f'solve\n'
    sol_str = sol_str + f'\t{how} {obj};' if how != 'satisfy' else sol_str + f'\t{how};'
    return sol_str

def mzn_model_string(model_elems: Iterable[str]):
    return '\n'.join(model_elems)

def save_model(model_file, model_string, files: Iterable[str] = []):
    include_str = []
    
    for f in files:
        fname = os.path.basename(f)
        include_str.append(f'include "{fname}";')
    
    include_str = '\n'.join(include_str)
    full_model = '\n'.join([include_str, model_string])
    model_path = os.path.join(MODULE_PATH, 'data', 'models', f'{model_file}')
    
    with open(model_path, 'w') as f:
        f.write(full_model)
    
    return

def solve_model(model_string, solver='gecode', files: Iterable[str] = [], params: Dict = {}, model_file='', outfile = ''):
    model = Model()
    s = Solver.lookup(solver)
    model.add_string(model_string)
    
    for f in files:
        assert ".mzn" in os.path.basename(f), "Only .mzn files can be added to the model."
        model.add_file(f)
    
    if model_file:
        save_model(model_file, model_string, files)
    
    instance = Instance(s, model)
    for k, v in params:
        instance[k] = v
    
    result = instance.solve()
    
    return result


#TODO create output type for storing solutions
async def async_solve_model(model_string, solver='gecode', files: Iterable[str] = [], params: Dict = {}, model_file='', outfile = ''):
    model = Model()
    s = Solver.lookup(solver)
    model.add_string(model_string)
    
    for f in files:
        assert ".mzn" in os.path.basename(f), "Only .mzn files can be added to the model."
        model.add_file(f)
    
    if model_file:
        save_model(model_file, model_string, files)
    
    instance = Instance(s, model)
    for k, v in params:
        instance[k] = v
        
    return await instance.solve_async()
