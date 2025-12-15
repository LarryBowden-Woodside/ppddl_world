# PPDDL Agent

Generates PPDDL (Probabilistic PDDL) from natural language using LLMs, with optional neuro-symbolic graph reasoning.

Main features:
- Converts problem descriptions to PPDDL domains/problems
- Uses LLM to extract variables, constraints, and objectives
- Optional graph-based reasoning with belief propagation
- Exports to PSL, MLN, GraphML, RDF, and HTML
- Iterative refinement when planner fails

## Installation

Requires Python 3.8+. Install dependencies:

```bash
sudo apt install python3-venv
python3 -m venv .venv
source .venv/bin/activate

./setup_planner_path.sh
./configure_planner.sh
pip install -r requirements.txt
```

Set `OPENAI_API_KEY` if you want LLM functionality (otherwise it runs in stub mode). Set `PPDDL_PLANNER_CMD` if you want to actually run planners.

## Quick Start

Run the LNG demo:

```bash
python main.py --approach all --compare
```

Or use the agent directly:

```bash
python agent.py --viz
```

For graph reasoning:

```python
from neurosym import NeuroSymGraph, build_rover_neurosym_graph

g = build_rover_neurosym_graph()
g.propagate_beliefs()
g.export_graphml("graph.graphml")
```

## Configuration

Set environment variables:
- `OPENAI_API_KEY` - for LLM calls
- `PPDDL_PLANNER_CMD` - planner command template (e.g., `"probabilistic-ff -o {domain} -f {problem}"`)

Problem templates are in `config.json`.

## Problem Templates

Includes rover, computer-projector, search-rescue, and LNG offtake problems. See `config.json` for details.

## Exports

Graphs can be exported to GraphML, RDF/Turtle, PSL, MLN, or HTML. See `neurosym.py` for export methods.

## Testing

Run tests with pytest:

```bash
python -m pytest test_robustness.py -v
```

## How It Works

The agent takes a problem description, uses an LLM to extract variables/constraints/objectives, generates PPDDL, runs a planner, and refines based on errors.

Main components:
- `agent.py` - LLM calls and PPDDL generation
- `main.py` - LNG demo with three approaches (baseline, hybrid, adaptive)
- `neurosym.py` - Graph reasoning with belief propagation
- `problem.py` - Problem definitions
- `translator.py` - MiniZinc to PPDDL translation

## Graph Reasoning

The neuro-symbolic graph supports belief propagation, spreading activation, argumentation frameworks, and Bayesian updates. See `neurosym.py` for details.

## Adding Problems

Add problem templates to `config.json` under `problem_templates`. The agent will use them when generating PPDDL.

## Troubleshooting

If LLM calls fail, check your API key. The system falls back to stub mode if the API isn't available.

If the planner fails, make sure `PPDDL_PLANNER_CMD` is set correctly. The generated PPDDL files are saved even if planning fails.

For visualization, install pyvis: `pip install pyvis`

## References

Based on PPDDL planning (Younes & Littman 2004), neuro-symbolic reasoning, and Dung-style argumentation frameworks.


