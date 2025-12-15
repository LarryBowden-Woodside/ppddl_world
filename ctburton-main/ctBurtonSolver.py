import minizinc
from minizinc import Instance, Model, Solver
import graphviz
import sys

# Load ctBurton problem model from file
ctBurton = Model("./ctBurtonTrellis_v2.mzn")
# Find the MiniZinc solver configuration for Gecode
gecode = Solver.lookup("gecode")
# Create an Instance of the model for Gecode
instance = Instance(gecode, ctBurton)
# Assign the adjustable parameters
instance["Fupper"] = 1000 # This is the upper bound on floating point numbers
instance["h"] = 5         # This is the horizon length
result = instance.solve()

# Check if the output is unsatisfiable
if result.status == minizinc.Status.UNSATISFIABLE:
    print("UNSATISFIABLE")
    sys.exit()

#  Output the solution as text, in lists:
print("Events: " + str(result["e"]))

print("Computer Automata location variables: " + str(result["compl"]))
print("Connection Automata location variables: " + str(result["connl"]))
print("Projector Automata location variables: " + str(result["projl"]))

print("Computer Automata control variables: " + str(result["compu"]))
print("Connection Automata control variables: " + str(result["connu"]))
print("Projector Automata control variables: " + str(result["proju"]))

print("Clock: " + str(result["c"]))

print("Clock Offset: " + str(result["co"]))

print("Clock LowerBound: " + str(result["cl"]))
print("Clock UpperBound: " + str(result["cu"]))

print("Open interval enablement: " + str(result["Eno"]))
print("End interval enablement: " + str(result["Ene"]))

# Output the solution as a .DOT plot for GraphViz
dot = graphviz.Digraph('ctBurton Solution', comment='Solution')

# TODO: Complete this translation from variable to dot graph


# Output the dot source as plain text, to the console
print(dot.source)


# Output the dot file as a PDF
dot.render(directory='').replace('\\', '/')



