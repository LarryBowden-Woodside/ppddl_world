# ctBurton

There are two ways to 'solve' for the ctBurton Computer-Projector-Automata enconding:

FIRST, Use minizinc.
* Open "ctBurtonTrellis_v2.mzn"
* In the top menu, under "Solver configuration" select "Gecode 6.3.0".
* In the top menu, click "Run".


SECOND, Use Python
The ctburton directory is also acts as PyCharm project directory.

* Install Pycharm and open the root-level ctburton gitrepo as a PyCharm project.
* PyCharm will automatically start a virtual environment
* In Pycharm, open the Terminal in the bottom status bar.
* Enter the command "pip install -r requirements.txt"
---- Executing the above command, automatically executes the following two commands:
---- pip install minizinc
---- pip install graphviz
