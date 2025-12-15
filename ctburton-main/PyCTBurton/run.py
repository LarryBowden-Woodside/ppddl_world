from minizinc import Model, Solver, Instance

from PyCTBurton import generate_minizinc

mzn_model_string = generate_minizinc('system_config.json', 'experiment_config_2.json')

mzn_file = open("ctburton_encoding.mzn", "w")
mzn_file.write(mzn_model_string)
mzn_file.close()

gecode = Solver.lookup("gecode")

model = Model("./ctburton_encoding.mzn")
instance = Instance(gecode, model)
# result = instance.solve()