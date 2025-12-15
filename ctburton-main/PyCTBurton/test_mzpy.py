from minizinc import Instance, Model, Solver

gecode = Solver.lookup("gecode")

str_list = []

str_list.append("include \"all_different.mzn\";")
str_list.append("set of int: A;")
str_list.append("set of int: B;")
str_list.append("array[A] of var B: arr;")

str_list.append("")

str_list.append("var set of B: X;")
str_list.append("var set of B: Y;")
str_list.append("constraint all_different(arr);")
str_list.append("constraint forall (i in index_set(arr)) ( arr[i] in X );")
str_list.append("constraint forall (i in index_set(arr)) ( (arr[i] mod 2 = 0) <-> arr[i] in Y );")

str_list.append("solve satisfy;")

full_str = "\n".join(str_list)

mzn_file = open("test_encoding.mzn", "w")
mzn_file.write(full_str)
mzn_file.close()

model = Model("./test_encoding.mzn")

instance = Instance(gecode, model)
instance["A"] = range(3, 8)  # MiniZinc: 3..7
instance["B"] = {4, 3, 2, 1, 0}  # MiniZinc: {4, 3, 2, 1, 0}

result = instance.solve()
print(result["X"])  # range(0, 5)
assert isinstance(result["X"], range)
print(result["Y"])  # {0, 2, 4}
assert isinstance(result["Y"], set)

print(full_str)