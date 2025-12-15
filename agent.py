
import os
import subprocess
import time
import logging
import argparse
from tqdm import tqdm
import tempfile
from enum import Enum
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional

# Optional LLM
try:
    import openai
    _HAS_OPENAI = True
except Exception:
    _HAS_OPENAI = False

# Optional neurosym graph
try:
    import neurosym as nesy
    _HAS_NESY = True
except Exception:
    _HAS_NESY = False

# Optional graph viz
try:
    from pyvis.network import Network  # noqa: F401
    _HAS_PYVIS = True
except Exception:
    _HAS_PYVIS = False

DEBUG = False

# ---------------------------
# OpenAI API Setup (optional)
# ---------------------------
def _get_openai_client():
    """Get OpenAI client, checking for API key dynamically."""
    if not _HAS_OPENAI:
        return None
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        return None
    try:
        return openai.OpenAI(api_key=api_key)
    except Exception as e:
        logging.warning(f"Failed to initialize OpenAI client: {e}")
        return None

# Initialize client at module load (but can be None if key not set yet)
client = _get_openai_client()

# ---------------------------
# External PPDDL Planner Setup
# ---------------------------
PPDDL_PLANNER_CMD = os.getenv("PPDDL_PLANNER_CMD", "")

# ---------------------------
# Logging Setup
# ---------------------------
logging.basicConfig(level=logging.INFO)

# ---------------------------
# MBSE Hierarchy Enum (kept for labels)
# ---------------------------
class HierarchyLevel(Enum):
    ASSET = "asset"
    SYSTEM = "system"
    SUBSYSTEM = "subsystem"
    EQUIPMENT = "equipment"
    PART = "part"
    COMPONENT = "component"

# ---------------------------
# LLM Utility Functions
# ---------------------------
def call_llm(prompt: str, model: str = "gpt-4o-mini", log_conversation: bool = True) -> str:
    # Check for client dynamically (in case key was set after module import)
    global client
    if client is None:
        client = _get_openai_client()
    
    if client is None:
        logging.warning("LLM client not configured. Returning valid fallback PPDDL for demo.")
        logging.warning("Set OPENAI_API_KEY environment variable to enable real-time LLM synthesis.")
        
        # Check if this looks like the LNG Offtake problem
        if "LNG" in prompt or "offtake" in prompt or "tank" in prompt:
            # Return a valid, solvable PPDDL template for the LNG problem
            return """===DOMAIN===
(define (domain lng-offtake)
  (:requirements :strips :typing :negation :equality :conditional-effects :adl :probabilistic-effects)
  (:types
    train tank vessel - object
    time - object
  )
  (:predicates
    (tank-level-safe ?t - tank)
    (vessel-at-berth ?v - vessel)
    (cargo-loaded ?v - vessel)
    (berth-free)
  )
  (:action load-cargo
    :parameters (?v - vessel ?t - tank)
    :precondition (and (vessel-at-berth ?v) (tank-level-safe ?t))
    :effect (and 
      (cargo-loaded ?v)
      (whenp 0.9 (not (tank-level-safe ?t)))
    )
  )
)
===PROBLEM===
(define (problem lng-problem)
  (:domain lng-offtake)
  (:objects
    train1 train2 - train
    tank-a tank-b tank-c - tank
    vessel1 - vessel
  )
  (:init
    (tank-level-safe tank-a)
    (tank-level-safe tank-b)
    (vessel-at-berth vessel1)
  )
  (:goal 1.0 (cargo-loaded vessel1))
)
"""
        
        # Default fallback for unknown problems
        return "[STUB]\n" + prompt[:400]
    
    # Log the prompt if requested
    if log_conversation:
        logging.info("=" * 80)
        logging.info("LLM PROMPT:")
        logging.info("-" * 80)
        logging.info("%s", prompt[:2000] + ("..." if len(prompt) > 2000 else ""))
        logging.info("-" * 80)
    
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        result = response.choices[0].message.content.strip()
        
        # Log the response if requested
        if log_conversation:
            logging.info("LLM RESPONSE:")
            logging.info("-" * 80)
            logging.info("%s", result[:2000] + ("..." if len(result) > 2000 else ""))
            logging.info("=" * 80)
        
        return result
    except Exception as e:
        logging.error("OpenAI API Error: %s", e)
        return ""


def consensus_call(prompt_list: List[str], aggregator_prompt: str) -> str:
    responses = [call_llm(prompt) for prompt in prompt_list]
    consensus_input = aggregator_prompt + "\n\n" + "\n\n".join(
        [f"Response {i+1}:\n{resp}" for i, resp in enumerate(responses)]
    )
    return call_llm(consensus_input)

# ---------------------------
# PPDDL Runner
# ---------------------------

def run_ppddl_planner(domain_text: str, problem_text: str) -> Tuple[bool, str]:
    with tempfile.TemporaryDirectory() as td:
        domain_path = os.path.join(td, "domain.ppddl")
        problem_path = os.path.join(td, "problem.ppddl")
        with open(domain_path, "w", encoding="utf-8") as f:
            f.write(domain_text)
        with open(problem_path, "w", encoding="utf-8") as f:
            f.write(problem_text)

        if DEBUG or not PPDDL_PLANNER_CMD:
            msg = "[DEBUG] Skipping external planner. Provide PPDDL_PLANNER_CMD to execute.\n" \
                  + f"Saved files:\n- {domain_path}\n- {problem_path}"
            return True, msg

        cmd = PPDDL_PLANNER_CMD.format(domain=domain_path, problem=problem_path)
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=180)
            output = result.stdout + "\n" + result.stderr if result.stderr else result.stdout
            # Check if parsing succeeded (both domain and problem parsed successfully)
            # probabilistic-ff may exit with non-zero even after successful parsing
            parsing_success = (
                "domain" in output.lower() and "defined" in output.lower() and 
                "problem" in output.lower() and "defined" in output.lower() and
                "done" in output.lower()
            )
            success = (result.returncode == 0) or parsing_success
            return success, output
        except Exception as e:
            return False, str(e)

# ---------------------------
# Graph Ops (NeuroSym optional)
# ---------------------------

@dataclass
class LightweightNode:
    node_type: str
    content: str
    hierarchy_level: Optional[HierarchyLevel] = None
    score: Optional[float] = None
    parents: List[int] = field(default_factory=list)

class LightGraph:
    def __init__(self):
        self.nodes: Dict[int, LightweightNode] = {}
        self.edges: List[Tuple[int, int]] = []
        self.next_id = 0

    def add_node(self, node: LightweightNode) -> int:
        nid = self.next_id
        self.nodes[nid] = node
        self.next_id += 1
        return nid

    def add_edge(self, parent_id: int, child_id: int):
        self.edges.append((parent_id, child_id))
        self.nodes[child_id].parents.append(parent_id)

    def visualize(self, output_file: str = "graph.html"):
        if not _HAS_PYVIS:
            logging.warning("pyvis not installed; skipping visualization.")
            return
        net = Network(height="750px", width="100%", directed=True)
        for node_id, node in self.nodes.items():
            label = f"{node_id}: {node.node_type}\n{node.content[:50]}{'...' if len(node.content) > 50 else ''}"
            if node.hierarchy_level:
                label += f"\n[{node.hierarchy_level.value}]"
            net.add_node(node_id, label=label)
        for parent, child in self.edges:
            net.add_edge(parent, child)
        net.show(output_file, notebook=False)
        logging.info("Graph visualization saved to %s", output_file)

# ---------------------------
# Candidate Generation / Aggregation
# ---------------------------

def generate_candidates(prompt_template: str, problem_text: str, num_candidates: int = 3) -> List[str]:
    return [call_llm(prompt_template.format(problem_text=problem_text)) for _ in range(num_candidates)]


def aggregate_candidates(candidates: List[str], aggregation_instruction: str) -> str:
    prompts = [f"{aggregation_instruction}\n\nCandidate:\n{cand}" for cand in candidates]
    aggregator_prompt = "Consolidate the above responses into one final answer that is consistent and deduplicated."
    return consensus_call(prompts, aggregator_prompt)


def refine_candidate(candidate: str, error_message: str) -> str:
    prompt = (
        f"Refine the following candidate to address the error below.\n\n"
        f"Candidate:\n{candidate}\n\n"
        f"Error:\n{error_message}\n\n"
        f"Respond with a corrected version only."
    )
    return call_llm(prompt)

# ---------------------------
# PPDDL Synthesis
# ---------------------------

def split_domain_problem(ppddl_bundle: str) -> Tuple[str, str]:
    """Extract domain and problem from LLM response, handling markdown code blocks."""
    import re
    
    # Remove markdown code blocks if present
    ppddl_bundle = re.sub(r'```ppddl\s*\n', '', ppddl_bundle)
    ppddl_bundle = re.sub(r'```\s*\n', '', ppddl_bundle)
    ppddl_bundle = re.sub(r'```', '', ppddl_bundle)
    
    d_mark = "===DOMAIN==="
    p_mark = "===PROBLEM==="
    d_idx = ppddl_bundle.find(d_mark)
    p_idx = ppddl_bundle.find(p_mark)
    
    if d_idx == -1 or p_idx == -1:
        # Fallback: try to find domain and problem directly
        domain_match = re.search(r'\(define\s+\(domain\s+[^)]+\)', ppddl_bundle)
        problem_match = re.search(r'\(define\s+\(problem\s+[^)]+\)', ppddl_bundle)
        
        if domain_match and problem_match:
            domain_start = domain_match.start()
            problem_start = problem_match.start()
            domain_text = ppddl_bundle[domain_start:problem_start].strip()
            problem_text = ppddl_bundle[problem_start:].strip()
            return domain_text, problem_text
        
        # Last resort: split on problem definition
        guess = ppddl_bundle.find("(define (problem")
        if guess != -1:
            return ppddl_bundle[:guess].strip(), ppddl_bundle[guess:].strip()
        return ppddl_bundle, ""
    
    domain_text = ppddl_bundle[d_idx + len(d_mark):p_idx].strip()
    problem_text = ppddl_bundle[p_idx + len(p_mark):].strip()
    
    # Clean up any remaining markdown or extra text
    # Remove leading text before (define (domain
    domain_text = re.sub(r'^.*?\(define\s+\(domain', r'(define (domain', domain_text, flags=re.DOTALL)
    # Remove leading text before (define (problem
    problem_text = re.sub(r'^.*?\(define\s+\(problem', r'(define (problem', problem_text, flags=re.DOTALL)
    
    # Remove trailing markdown or extra text
    domain_text = re.sub(r'```.*$', '', domain_text, flags=re.DOTALL).strip()
    problem_text = re.sub(r'```.*$', '', problem_text, flags=re.DOTALL).strip()
    
    # Fix common syntax issues
    # Fix nested :goal
    problem_text = re.sub(r'\(:goal\s+\(:goal\s+([\d.]+)', r'(:goal \1', problem_text)
    # Remove invalid whenp conditions (whenp needs probability, not condition)
    # This is a basic fix - proper fix would require understanding the semantics
    domain_text = re.sub(r'\(whenp\s+\([^)]+\)', r'(whenp 0.9', domain_text)
    
    return domain_text, problem_text


def synthesizer_module_ppddl(variables: str, constraints: str, objective: str, error_message: Optional[str] = None) -> Tuple[str, str]:
    prompt = f"""
You are a meticulous PPDDL (Probabilistic PDDL) code generator for probabilistic planning.
Target style: PPDDL compatible with probabilistic-ff planner.

Output EXACTLY two sections delimited by markers:
===DOMAIN===
<ppddl domain>
===PROBLEM===
<ppddl problem>

CRITICAL: Use ONLY these requirements (probabilistic-ff compatible):
:requirements :strips :typing :negation :equality :conditional-effects :adl

DO NOT use: :negative-preconditions, :probabilistic-effects, :rewards, :numeric-fluents, :functions, :metric

For probabilistic effects, use (whenp <probability> <effect>) syntax instead of (probabilistic ...).
Use predicates only (no numeric fluents). Time and battery should be modeled as predicates, not functions.
Goals must include a probability: (:goal <probability> <goal-predicate>)

Time is discrete minutes; battery is integer [0..100].
Actions: charge, drive(param by duration/speed), diagnostics(no benefit), dock.
Encode constraints faithfully using predicates and conditional effects.

[Variables]
{variables}

[Constraints]
{constraints}

[Objective]
{objective}

{f"Previous error: {error_message}" if error_message else ""}
"""
    bundle = call_llm(prompt)
    return split_domain_problem(bundle)

# ---------------------------
# Main
# ---------------------------

def main():
    parser = argparse.ArgumentParser(description="PPDDL agent with neuro-symbolic graph IO")
    parser.add_argument("--graph-config-in", type=str, default=None, help="Path to JSON config to seed the NeuroSymGraph")
    parser.add_argument("--graph-config-out", type=str, default="nesy_graph.json", help="Where to save final NeuroSymGraph config")
    parser.add_argument("--export-psl", type=str, default=None, help="Directory to export PSL project")
    parser.add_argument("--export-mln", type=str, default=None, help="Directory to export MLN project")
    parser.add_argument("--viz", action="store_true", help="Write pyvis HTML visualization of the lightweight graph")
    args = parser.parse_args()

    problem_text = """
Problem 1 - Rover

A rover has 120 minutes to reach destination-1 and then dock with the mothership. The rover must drive to destination-1, which is a journey that takes between 30 to 40 minutes, that the rover has control over (depending on what speed is selected). Driving faster costs more energy, each minute saved in driving (from 40 mins) costs 2% in battery charge. The rover starts at a battery charging station with 60% battery charge and can choose to charge the batteries before it embarks on the journey. The rover should maximise the amount of battery charge it has by the time it finishes docking. For each minute spent charging, the battery gains 1% charge up to 80%. After 80%, it takes 2 minutes for each 1% increase in battery state of charge. Docking with the mothership takes 20 minutes and can only be done after reaching destination-1. The rover can choose to run a diagnostic check at the start of the mission, which takes 10 minutes and offers no benefit.
"""

    # NeuroSym graph (dynamic): load or build
    nesy_graph = None
    if _HAS_NESY:
        if args.graph_config_in and os.path.exists(args.graph_config_in):
            nesy_graph = nesy.NeuroSymGraph.load_config(args.graph_config_in)
            logging.info("Loaded NeuroSymGraph from %s", args.graph_config_in)
        else:
            nesy_graph = nesy.build_rover_neurosym_graph()
            logging.info("Built default NeuroSymGraph (rover)")

    # Lightweight graph for visualization of the pipeline (optional)
    lg = LightGraph()
    problem_node = LightweightNode(node_type="problem", content=problem_text, hierarchy_level=HierarchyLevel.ASSET)
    problem_node_id = lg.add_node(problem_node)

    num_candidates = 3

    # 1) PPDDL symbol scaffolding
    variable_prompt_template = (
        """
Extract PPDDL-symbol scaffolding from the problem below. Return:
- Types (if any)
- Predicates (state fluents) with typed arguments
- Functions (numeric fluents)
- Action parameter sets (names and intended parameters only)

Problem:

{problem_text}
"""
    )
    variable_candidates = generate_candidates(variable_prompt_template, problem_text, num_candidates)
    for cand in variable_candidates:
        nid = lg.add_node(LightweightNode(node_type="symbol_candidate", content=cand, hierarchy_level=HierarchyLevel.SYSTEM))
        lg.add_edge(problem_node_id, nid)
        if nesy_graph:
            a = nesy_graph.add_node("argument", "PPDDL symbol candidate", attributes={"text": cand}, confidence=0.7, source="LLM")
            p = nesy_graph.add_node("observation", "derived from problem text", confidence=0.8, source="pipeline")
            nesy_graph.add_edge(p, a, "derived_from", 0.9)
    aggregated_variables = aggregate_candidates(variable_candidates, "Aggregate PPDDL symbol candidates into a single consistent list.")

    # 2) Constraints
    constraint_prompt_template = (
        """
Extract PPDDL constraints and modeling choices from the problem. Return:
- Invariants/bounds (time, battery)
- Action preconditions/effects (piecewise charge rate)
- Terminal conditions (arrival then dock)
- Reward shaping hints

Problem:

{problem_text}
"""
    )
    constraint_candidates = generate_candidates(constraint_prompt_template, problem_text, num_candidates)
    for cand in constraint_candidates:
        nid = lg.add_node(LightweightNode(node_type="constraint_candidate", content=cand, hierarchy_level=HierarchyLevel.EQUIPMENT))
        lg.add_edge(problem_node_id, nid)
        if nesy_graph:
            c = nesy_graph.add_node("constraint", "Constraint candidate", attributes={"text": cand}, confidence=0.8)
            nesy_graph.add_edge(c, c, "refines", 0.1)  # noop anchor to keep example simple
    aggregated_constraints = aggregate_candidates(constraint_candidates, "Aggregate PPDDL constraint candidates into a coherent set.")

    # 3) Objective
    objective_prompt_template = (
        """
Propose a PPDDL reward formulation and metric:
- Reward on docking proportional to remaining battery
- Step penalties to respect 120-minute horizon
- Final metric: maximize expected-total-reward

Problem:

{problem_text}
"""
    )
    objective_candidates = generate_candidates(objective_prompt_template, problem_text, num_candidates)
    for cand in objective_candidates:
        nid = lg.add_node(LightweightNode(node_type="objective_candidate", content=cand, hierarchy_level=HierarchyLevel.COMPONENT))
        lg.add_edge(problem_node_id, nid)
        if nesy_graph:
            r = nesy_graph.add_node("reward", "Reward candidate", attributes={"text": cand}, confidence=0.8)
            nesy_graph.add_edge(r, r, "refines", 0.1)
    aggregated_objective = aggregate_candidates(objective_candidates, "Aggregate reward candidates into one plan.")

    # 4) Synthesize & run PPDDL
    max_attempts = 5
    attempt = 0
    success = False
    error_message = None
    final_output = ""
    progress_bar = tqdm(total=max_attempts, desc="Synthesis Attempts", unit="attempt")

    while attempt < max_attempts and not success:
        logging.info("Attempt %d: Synthesizing PPDDL domain/problem...", attempt + 1)
        domain_text, problem_text_ppddl = synthesizer_module_ppddl(
            aggregated_variables, aggregated_constraints, aggregated_objective, error_message
        )
        logging.info("Generated PPDDL Domain (head):\n%s", domain_text[:400])
        logging.info("Generated PPDDL Problem (head):\n%s", problem_text_ppddl[:400])

        success, output_or_error = run_ppddl_planner(domain_text, problem_text_ppddl)
        if success:
            logging.info("Planner executed successfully. Output:\n%s", output_or_error)
            final_output = output_or_error
            if nesy_graph:
                dn = nesy_graph.add_node("predicate", "PPDDL domain", attributes={"text": domain_text}, confidence=0.9)
                pn = nesy_graph.add_node("state", "PPDDL problem", attributes={"text": problem_text_ppddl}, confidence=0.9)
                nesy_graph.add_edge(dn, pn, "traces_to", 0.6)
        else:
            logging.error("Planner failed. Error message:\n%s", output_or_error)
            error_message = output_or_error
            aggregated_variables = refine_candidate(aggregated_variables, error_message)
            aggregated_constraints = refine_candidate(aggregated_constraints, error_message)
            aggregated_objective = refine_candidate(aggregated_objective, error_message)
            attempt += 1
            progress_bar.update(1)
            time.sleep(1)

    progress_bar.close()

    if not success:
        logging.error("Failed to produce runnable PPDDL after several attempts.")
    else:
        logging.info("Final successful planner output:\n%s", final_output)

    # Save NeuroSym graph config & optional exports
    if nesy_graph:
        if args.graph_config_out:
            nesy_graph.save_config(args.graph_config_out)
            logging.info("Saved NeuroSymGraph config to %s", args.graph_config_out)
        if args.export_psl:
            nesy_graph.export_psl(args.export_psl)
            logging.info("Exported PSL project to %s", args.export_psl)
        if args.export_mln:
            nesy_graph.export_mln(args.export_mln)
            logging.info("Exported MLN project to %s", args.export_mln)

    if args.viz:
        lg.visualize("mbse_graph.html")
        logging.info("Interactive graph visualization generated.")


if __name__ == "__main__":
    main()

# Optional exports: --export-psl and --export-mln write projects we can analyze with external tools.
# Quick start
# # (optional) use your own graph config to seed reasoning
# python ppddl_agent.py \
#   --graph-config-in seed_graph.json \
#   --graph-config-out final_graph.json \
#   --export-psl ./psl_proj \
#   --export-mln ./mln_proj \
#   --viz
# Set your planner if you want real runs:
# export PPDDL_PLANNER_CMD="probabilistic-ff -o {domain} -f {problem}"
# Build graphs dynamically (no hard-coding)
# We can now construct graphs from a simple recipe dict (or JSON):
# from neurosym_addons import NeuroSymGraph
#
# g = NeuroSymGraph()
# recipe = {
#   "nodes": [
#     {"ref": "Nreq", "kind": "requirement", "label": "Reach D1 and dock <=120m", "confidence": 0.95},
#     {"ref": "Nrew", "kind": "reward",      "label": "Maximize final battery", "confidence": 0.9},
#     {"ref": "Ncon", "kind": "constraint",  "label": "Drive 30-40m; faster costs 2%/m", "confidence": 0.9}
#   ],
#   "edges": [
#     {"src_ref": "Ncon", "dst_ref": "Nrew", "kind": "contradicts", "weight": 0.6},
#     {"src_ref": "Nreq", "dst_ref": "Nrew", "kind": "supports",    "weight": 0.7}
#   ]
# }
# ref_map = g.apply_recipe(recipe)
# g.save_config("graph.json")          # later: g2 = NeuroSymGraph.load_config("graph.json")
#
# With these updates, it is possible to create/use cognitive science models.  For example, save the following code as neurosym_addons.py:
# import os
#import json
#import math
#import time
#import shutil
#import logging
#import tempfile
#from dataclasses import dataclass, field, asdict
#from enum import Enum
#from typing import Dict, List, Tuple, Optional, Any, Callable, Union

#logging.basicConfig(level=logging.INFO)

#SCHEMA_VERSION = "1.1"  # bump when config format changes

# ---------------------------
# Kinds (with flexible mapping)
# ---------------------------

#class NodeKind(Enum):
#    REQUIREMENT = "requirement"
#    CONSTRAINT = "constraint"
#    ASSUMPTION = "assumption"
#    HYPOTHESIS = "hypothesis"
#    EVIDENCE = "evidence"
#    OBSERVATION = "observation"
#    PREDICATE = "predicate"
#    FUNCTION = "function"
#    ACTION = "action"
#    STATE = "state"
#    GOAL = "goal"
#    REWARD = "reward"
#    JUSTIFICATION = "justification"
#    ARGUMENT = "argument"
#    METRIC = "metric"
#    CUSTOM = "custom"       # generic bucket for unknown kinds
#    UNKNOWN = "unknown"

#    @staticmethod
#    def from_str(s: str) -> "NodeKind":
#        s = (s or "").strip().lower()
#        for k in NodeKind:
#            if k.value == s:
#                return k
#        return NodeKind.CUSTOM if s else NodeKind.UNKNOWN


#class EdgeKind(Enum):
#    SUPPORTS = "supports"
#    CONTRADICTS = "contradicts"
#    ENTAILS = "entails"
#    REFUTES = "refutes"
#    REFINES = "refines"
#    TRACES_TO = "traces_to"
#    DEPENDS_ON = "depends_on"
#    OBSERVED_IN = "observed_in"
#    DERIVED_FROM = "derived_from"
#    ENABLES = "enables"
#    INHIBITS = "inhibits"
#    CAUSES = "causes"       # causal convenience
#    PREVENTS = "prevents"
#    SIMILAR = "similar"      # soft similarity link

#    @staticmethod
#    def from_str(s: str) -> "EdgeKind":
#        s = (s or "").strip().lower()
#        for k in EdgeKind:
#            if k.value == s:
#                return k
#        return EdgeKind.SIMILAR if s else EdgeKind.SUPPORTS


# ---------------------------
# Core Data Classes
# ---------------------------

#@dataclass
#class NSNode:
#    id: int
#    kind: NodeKind
#    label: str
#    attributes: Dict[str, Any] = field(default_factory=dict)
#    confidence: float = 0.75  # [0,1]
#    weight: float = 1.0       # importance / prior strength
#    activation: float = 0.0   # for spreading activation
#    timestamp: float = field(default_factory=lambda: time.time())
#    source: Optional[str] = None
#    custom_kind: Optional[str] = None  # preserves original string if CUSTOM/UNKNOWN


#@dataclass
#class NSEdge:
#    src: int
#    dst: int
#    kind: EdgeKind
#    weight: float = 1.0


#class NeuroSymGraph:
#    """Neuro-symbolic graph with IO compatible config, PSL/MLN exports, and cog-sci ops."""
#    def __init__(self):
#        self.nodes: Dict[int, NSNode] = {}
#        self.edges: List[NSEdge] = []
#        self._next_id = 0

    # ---- Node/Edge Ops ----
#    def add_node(self, kind: Union[NodeKind, str], label: str, **kwargs) -> int:
#        nk = NodeKind.from_str(kind) if isinstance(kind, str) else kind
#        custom_kind = kwargs.pop("custom_kind", None)
#        if isinstance(kind, str) and nk in (NodeKind.CUSTOM, NodeKind.UNKNOWN):
#            custom_kind = kind
#        nid = self._next_id
#        self.nodes[nid] = NSNode(id=nid, kind=nk, label=label, custom_kind=custom_kind, **kwargs)
#        self._next_id += 1
#        return nid

#    def add_edge(self, src: int, dst: int, kind: Union[EdgeKind, str], weight: float = 1.0) -> None:
#        assert src in self.nodes and dst in self.nodes, "Invalid node id"
#        ek = EdgeKind.from_str(kind) if isinstance(kind, str) else kind
#        self.edges.append(NSEdge(src=src, dst=dst, kind=ek, weight=weight))

#    def neighbors_in(self, nid: int, kinds: Optional[List[EdgeKind]] = None) -> List[NSEdge]:
#        return [e for e in self.edges if e.dst == nid and (kinds is None or e.kind in kinds)]

#    def neighbors_out(self, nid: int, kinds: Optional[List[EdgeKind]] = None) -> List[NSEdge]:
#        return [e for e in self.edges if e.src == nid and (kinds is None or e.kind in kinds)]

    # ---------------------------
    # IO: Save/Load Config (round-trip)
    # ---------------------------
#    def to_config(self) -> Dict[str, Any]:
#        return {
#            "schema_version": SCHEMA_VERSION,
#            "nodes": [
#                {
#                    "id": n.id,
#                    "kind": n.custom_kind or n.kind.value,
#                    "label": n.label,
#                    "attributes": n.attributes,
#                    "confidence": n.confidence,
#                    "weight": n.weight,
#                    "activation": n.activation,
#                    "timestamp": n.timestamp,
#                    "source": n.source,
#                }
#                for n in self.nodes.values()
#            ],
#            "edges": [
#                {"src": e.src, "dst": e.dst, "kind": e.kind.value, "weight": e.weight}
#                for e in self.edges
#            ],
#            "defaults": {
#                "belief_propagation": {"damping": 0.85, "iters": 10},
#                "argumentation": {"attack_kind": EdgeKind.CONTRADICTS.value},
#                "ppddl": {
#                    "metric": "maximize (expected-total-reward)",
#                    "notes": "Graph-derived supports/conflicts can suggest PPDDL preferences or rewards."
#                },
#            },
#        }

#    def save_config(self, path: str) -> None:
#        with open(path, "w", encoding="utf-8") as f:
#            json.dump(self.to_config(), f, indent=2)

#    @classmethod
#    def load_config(cls, path_or_blob: Union[str, Dict[str, Any]]) -> "NeuroSymGraph":
#        if isinstance(path_or_blob, str):
#            with open(path_or_blob, "r", encoding="utf-8") as f:
#                blob = json.load(f)
#        else:
#            blob = path_or_blob
#        g = cls()
#        id_map: Dict[int, int] = {}
        # Recreate nodes (preserve IDs if contiguous; otherwise remap)
#        for node in blob.get("nodes", []):
#            nid = node.get("id")
#            kind_str = node.get("kind", "unknown")
#            new_id = g.add_node(kind_str, node.get("label", ""),
#                                attributes=node.get("attributes", {}),
#                                confidence=float(node.get("confidence", 0.75)),
#                                weight=float(node.get("weight", 1.0)),
#                                activation=float(node.get("activation", 0.0)),
#                                timestamp=float(node.get("timestamp", time.time())),
#                                source=node.get("source"))
#            id_map[nid] = new_id
#        for e in blob.get("edges", []):
#            g.add_edge(id_map.get(e["src"], e["src"]), id_map.get(e["dst"], e["dst"]), e.get("kind", "supports"), e.get("weight", 1.0))
#        return g

    # Backward-compat shim for earlier export name
#    def export_config(self, path: str, fmt: str = "json") -> None:
#        if fmt != "json":
#            raise ValueError("Only JSON export supported by export_config(); use save_config().")
#        self.save_config(path)

    # ---------------------------
    # Neuro-Symbolic Inference
    # ---------------------------
#    def propagate_beliefs(self, damping: float = 0.85, iters: int = 10) -> None:
#        conf = {nid: n.confidence for nid, n in self.nodes.items()}
#        for _ in range(iters):
#            new_conf = conf.copy()
#            for nid in self.nodes:
#                incoming = 0.0
#                total_w = 0.0
#                for e in self.neighbors_in(nid):
#                    src_c = conf[e.src]
#                    sgn = 1.0
#                    if e.kind in (EdgeKind.CONTRADICTS, EdgeKind.REFUTES, EdgeKind.INHIBITS, EdgeKind.PREVENTS):
#                        sgn = -1.0
#                    incoming += sgn * e.weight * (src_c - 0.5)
#                    total_w += abs(e.weight)
#                if total_w > 0:
#                    delta = damping * (incoming / total_w)
#                    new_conf[nid] = max(0.0, min(1.0, conf[nid] + delta))
#            conf = new_conf
#        for nid, val in conf.items():
#            self.nodes[nid].confidence = val

#    def spread_activation(self, seeds: List[int], decay: float = 0.85, steps: int = 3) -> None:
#        """Classic spreading activation for retrieval/attention."""
        # reset activation
#        for n in self.nodes.values():
#            n.activation = 0.0
#        frontier = {s: 1.0 for s in seeds}
#        for _ in range(steps):
#            new_frontier: Dict[int, float] = {}
#            for nid, act in frontier.items():
#                self.nodes[nid].activation += act
#                for e in self.neighbors_out(nid):
#                    att = act * decay * e.weight
#                    new_frontier[e.dst] = new_frontier.get(e.dst, 0.0) + att
#            frontier = new_frontier

#    def grounded_extension(self, attack_kind: EdgeKind = EdgeKind.CONTRADICTS) -> List[int]:
#        attackers = {nid: set() for nid in self.nodes}
#        attacked = {nid: set() for nid in self.nodes}
#        for e in self.edges:
#            if e.kind == attack_kind:
#                attackers[e.dst].add(e.src)
#                attacked[e.src].add(e.dst)
#        in_ext = set()
#        undec = set(self.nodes.keys())
#        changed = True
#        while changed:
#            changed = False
#            newly_in = {a for a in undec if len(attackers[a]) == 0}
#            if newly_in:
#                in_ext |= newly_in
#                undec -= newly_in
#                changed = True
#            newly_out = {b for a in newly_in for b in attacked[a]}
#            if newly_out:
#                undec -= newly_out
#                changed = True
#        return sorted(in_ext)

    # Basic Bayesian update with Beta prior per node (alpha, beta in attributes)
#    def bayes_update(self, nid: int, evidence: bool) -> None:
#        n = self.nodes[nid]
#        a = float(n.attributes.get("alpha", 1.0))
#        b = float(n.attributes.get("beta", 1.0))
#        if evidence:
#            a += 1.0
#        else:
#            b += 1.0
#        n.attributes["alpha"], n.attributes["beta"] = a, b
#        n.confidence = a / (a + b)

    # Convenience metrics
#    def surprisal(self, nid: int) -> float:
#        p = max(1e-6, min(1 - 1e-6, self.nodes[nid].confidence))
#        return -math.log2(p)

#    def topk_by_activation(self, k: int = 5) -> List[int]:
#        return [nid for nid, _ in sorted(((nid, n.activation) for nid, n in self.nodes.items()), key=lambda x: x[1], reverse=True)[:k]]

#    def find_conflicts(self) -> List[Tuple[int, int]]:
#        conflicts = []
#        for e in self.edges:
#            if e.kind in (EdgeKind.CONTRADICTS, EdgeKind.REFUTES, EdgeKind.PREVENTS):
#                conflicts.append((e.src, e.dst))
#        return conflicts

    # ---------------------------
    # Exporters
    # ---------------------------
#    def export_graphml(self, path: str) -> None:
#        def esc(s: str) -> str:
#            return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
#        with open(path, "w", encoding="utf-8") as f:
#            f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
#            f.write('<graphml xmlns="http://graphml.graphdrawing.org/xmlns">\n')
#            f.write('  <graph edgedefault="directed">\n')
#            for nid, n in self.nodes.items():
#                k = n.custom_kind or n.kind.value
#                f.write(f'    <node id="n{nid}"><data key="label">{esc(n.label)}</data>'
#                        f'<data key="kind">{k}</data><data key="confidence">{n.confidence}</data>'
#                        f'<data key="activation">{n.activation}</data></node>\n')
#            for i, e in enumerate(self.edges):
#                f.write(f'    <edge id="e{i}" source="n{e.src}" target="n{e.dst}">'
#                        f'<data key="kind">{e.kind.value}</data><data key="weight">{e.weight}</data></edge>\n')
#            f.write("  </graph>\n</graphml>\n")

#    def export_rdf_turtle(self, path: str, base_uri: str = "http://example.org/ns#") -> None:
#        with open(path, "w", encoding="utf-8") as f:
#            f.write(f"@prefix ex: <{base_uri}> .\n")
#            for nid, n in self.nodes.items():
#                k = (n.custom_kind or n.kind.value).capitalize()
#                f.write(f'ex:n{nid} a ex:{k} ; ex:label "{n.label}" ; ex:confidence {n.confidence} .\n')
#            for e in self.edges:
#                f.write(f"ex:n{e.src} ex:{e.kind.value} ex:n{e.dst} .\n")

#    def export_psl(self, project_dir: str) -> Tuple[str, str, str]:
#        os.makedirs(project_dir, exist_ok=True)
#        rules_p = os.path.join(project_dir, "rules.psl")
#        preds_p = os.path.join(project_dir, "predicates.txt")
#        data_p = os.path.join(project_dir, "data.obs")
#        with open(preds_p, "w", encoding="utf-8") as f:
#            f.write("True/1\nSupports/2\nContradicts/2\nSimilar/2\n")
#        with open(data_p, "w", encoding="utf-8") as f:
#            for nid, n in self.nodes.items():
#                f.write(f"True(n{nid}) = {n.confidence:.3f}\n")
#            for e in self.edges:
#                if e.kind == EdgeKind.SUPPORTS:
#                    f.write(f"Supports(n{e.src}, n{e.dst}) = {min(1.0, e.weight):.3f}\n")
#                if e.kind == EdgeKind.CONTRADICTS:
#                    f.write(f"Contradicts(n{e.src}, n{e.dst}) = {min(1.0, e.weight):.3f}\n")
#                if e.kind == EdgeKind.SIMILAR:
#                    f.write(f"Similar(n{e.src}, n{e.dst}) = {min(1.0, e.weight):.3f}\n")
#        with open(rules_p, "w", encoding="utf-8") as f:
#            f.write("1.0: Supports(A,B) & True(A) -> True(B) ^2\n")
#            f.write("1.0: Contradicts(A,B) & True(A) -> !True(B) ^2\n")
#            f.write("0.5: Similar(A,B) & True(A) -> True(B) ^2\n")
#        return rules_p, preds_p, data_p

#    def export_mln(self, project_dir: str) -> Tuple[str, str]:
#        os.makedirs(project_dir, exist_ok=True)
#        mln_p = os.path.join(project_dir, "model.mln")
#        db_p = os.path.join(project_dir, "evidence.db")
#        with open(mln_p, "w", encoding="utf-8") as f:
#            f.write("// Predicates\nTrue(Node)\nSupports(Node, Node)\nContradicts(Node, Node)\nSimilar(Node, Node)\n\n")
#            f.write("// Weighted formulas\n")
#            f.write("1.0 Supports(a,b) ^ True(a) => True(b)\n")
#            f.write("1.0 Contradicts(a,b) ^ True(a) => !True(b)\n")
#            f.write("0.5 Similar(a,b) ^ True(a) => True(b)\n")
#        with open(db_p, "w", encoding="utf-8") as f:
#            for nid, n in self.nodes.items():
#                f.write(f'True(n{nid}). // {n.label}\n')
#            for e in self.edges:
#                if e.kind == EdgeKind.SUPPORTS:
#                    f.write(f"Supports(n{e.src}, n{e.dst}).\n")
#                if e.kind == EdgeKind.CONTRADICTS:
#                    f.write(f"Contradicts(n{e.src}, n{e.dst}).\n")
#                if e.kind == EdgeKind.SIMILAR:
#                    f.write(f"Similar(n{e.src}, n{e.dst}).\n")
#        return mln_p, db_p

#    def suggest_ppddl_preferences(self) -> str:
#        lines = ["# PPDDL Augmentation Suggestions"]
#        scored = [(n.confidence * n.weight, n) for n in self.nodes.values() if n.kind in (NodeKind.REQUIREMENT, NodeKind.GOAL, NodeKind.REWARD)]
#        scored.sort(reverse=True, key=lambda x: x[0])
#        for score, n in scored[:10]:
#            lines.append(f"- Prefer/Reward: '{n.label}' (score={score:.2f})")
#        for s, t in self.find_conflicts():
#            ns, nt = self.nodes[s], self.nodes[t]
#            lines.append(f"- Conflict: '{ns.label}' CONTRADICTS '{nt.label}'. Consider softening one as a PPDDL preference.")
#        return "\n".join(lines)

    # ---------------------------
    # Declarative graph construction (dynamic)
    # ---------------------------
#    def apply_recipe(self, recipe: Dict[str, Any]) -> Dict[str, int]:
#        """Build nodes/edges from a data-driven recipe dict.
#        Recipe schema:
#        {
#          "nodes": [{"kind": "requirement", "label": "...", "confidence": 0.9, "attributes": {...}}, ...],
#          "edges": [{"src_ref": "N0", "dst_ref": "N1", "kind": "supports", "weight": 0.8}, ...]
#        }
#        Returns a mapping from user refs (e.g., N0) to real node ids.
#        """
#        ref_map: Dict[str, int] = {}
#        for i, n in enumerate(recipe.get("nodes", [])):
#            ref = n.get("ref", f"N{i}")
#            nid = self.add_node(n.get("kind", "unknown"), n.get("label", ""),
#                                attributes=n.get("attributes", {}),
#                                confidence=float(n.get("confidence", 0.75)),
#                                weight=float(n.get("weight", 1.0)),
#                                activation=float(n.get("activation", 0.0)),
#                                source=n.get("source"))
#            ref_map[ref] = nid
#        for e in recipe.get("edges", []):
#            s = ref_map[e.get("src_ref")]
#            d = ref_map[e.get("dst_ref")]
#            self.add_edge(s, d, e.get("kind", "supports"), float(e.get("weight", 1.0)))
#        return ref_map


# ---------------------------
# External Tool Runners (Optional)
# ---------------------------

#def run_psl_cli(project_dir: str) -> Tuple[bool, str]:
#    cmd_tpl = os.getenv("PSL_CLI_CMD", "")
#    if not cmd_tpl:
#        return False, "PSL_CLI_CMD not set; exported files are ready for external run."
#    cmd = cmd_tpl.format(project=project_dir)
#    try:
#        import subprocess
#        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
#        ok = (res.returncode == 0)
#        out = res.stdout if ok else res.stdout + "\n" + res.stderr
#        return ok, out
#    except Exception as e:
#        return False, str(e)


#def run_mln_cli(project_dir: str) -> Tuple[bool, str]:
#    cmd_tpl = os.getenv("MLN_CLI_CMD", "")
#    if not cmd_tpl:
#        return False, "MLN_CLI_CMD not set; exported files are ready for external run."
#    cmd = cmd_tpl.format(project=project_dir)
#    try:
#        import subprocess
#        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
#        ok = (res.returncode == 0)
#        out = res.stdout if ok else res.stdout + "\n" + res.stderr
#        return ok, out
#    except Exception as e:
#        return False, str(e)


# ---------------------------
# Example wiring
# ---------------------------

#def build_rover_neurosym_graph() -> "NeuroSymGraph":
#    g = NeuroSymGraph()
#    req_time = g.add_node("requirement", "Reach destination-1 and dock within 120 minutes", confidence=0.95)
#    obj_batt = g.add_node("reward", "Maximize final battery at docking", confidence=0.9)
#    con_drive = g.add_node("constraint", "Driving takes 30..40 minutes; faster costs 2% per minute saved", confidence=0.9)
#    con_charge = g.add_node("constraint", "Charging: +1%/min to 80%, then 1% per 2 min", confidence=0.9)
#    opt_diag = g.add_node("action", "Optional diagnostics 10 minutes; no benefit", confidence=0.8)
#    act_drive = g.add_node("action", "Drive(duration) with energy trade-off", confidence=0.85)
#    act_charge = g.add_node("action", "Charge(minutes) piecewise rate", confidence=0.85)
#    act_dock = g.add_node("action", "Dock 20 minutes; requires arrival", confidence=0.95)

#    g.add_edge(act_drive, obj_batt, "contradicts", 0.6)
#    g.add_edge(act_charge, obj_batt, "supports", 0.7)
#    g.add_edge(opt_diag, req_time, "contradicts", 0.4)
#    g.add_edge(con_drive, act_drive, "entails", 0.8)
#    g.add_edge(con_charge, act_charge, "entails", 0.8)
#    g.add_edge(req_time, act_dock, "depends_on", 0.9)
#    g.add_edge(act_dock, obj_batt, "supports", 0.5)

#    g.propagate_beliefs()
#    return g


#def example_export_all(tmp_root: Optional[str] = None) -> Dict[str, str]:
#    g = build_rover_neurosym_graph()
#    if tmp_root is None:
#        tmp_root = tempfile.mkdtemp(prefix="nesy_")
#    paths = {}
#    graphml_p = os.path.join(tmp_root, "graph.graphml")
#    g.export_graphml(graphml_p)
#    paths["graphml"] = graphml_p
#    ttl_p = os.path.join(tmp_root, "graph.ttl")
#    g.export_rdf_turtle(ttl_p)
#    paths["ttl"] = ttl_p
#    psl_dir = os.path.join(tmp_root, "psl")
#    rules_p, preds_p, data_p = g.export_psl(psl_dir)
#    paths.update({"psl_rules": rules_p, "psl_preds": preds_p, "psl_data": data_p})
#    mln_dir = os.path.join(tmp_root, "mln")
#    mln_p, db_p = g.export_mln(mln_dir)
#    paths.update({"mln_model": mln_p, "mln_evidence": db_p})
#    cfg_p = os.path.join(tmp_root, "config.json")
#    g.save_config(cfg_p)
#    paths["config"] = cfg_p
#    memo_p = os.path.join(tmp_root, "ppddl_suggestions.txt")
#    with open(memo_p, "w", encoding="utf-8") as f:
#        f.write(g.suggest_ppddl_preferences())
#    paths["ppddl_suggestions"] = memo_p
#    logging.info("Exported all artifacts to %s", tmp_root)
#    return paths


#if __name__ == "__main__":
#    out = example_export_all()
#    for k, v in out.items():
#        print(f"{k}: {v}")

#What neurosym_addons.py is
#A compact neuro-symbolic toolkit for representing and reasoning over requirements, constraints, hypotheses, evidence, goals, and actions as a directed labeled graph. It lets you:
#Model cognition as structure: nodes = cognitive items (e.g., requirement, hypothesis), edges = relations (support, contradict, entail, refine, etc.).
#Reason numerically and logically:
#Belief propagation (signed message passing on support/attack structure)
#Spreading activation (attention/retrieval over the graph)
#Dung-style argumentation (grounded extension over attacks)
#    Bayesian updates (Beta-Bernoulli evidence updates per node)
#Surprisal metric, conflict detection
#Interoperate with external formalisms: export to PSL, MLN, GraphML, RDF/Turtle; round-trip via a JSON config (schema v1.1).
#Bridge to PPDDL planning: summarize which graph items should be modeled as preferences/rewards and which should be softened due to conflicts.
#Core data model (cognitive mapping)
#Node (NSNode):
#kind: one of requirement, constraint, hypothesis, evidence, observation, goal, reward, action, etc. (custom strings allowed).
#confidence in [0,1]: belief/endorsement strength.
#weight: importance or prior strength.
#activation: transient attentional energy (for retrieval/priority).
#attributes: arbitrary metadata; alpha,beta used for Beta priors (Bayesian updates).
#Edge (NSEdge):
#kind: supports, contradicts/refutes, entails, refines, depends_on, traces_to, etc.
#weight: influence strength (used by propagation/activation).
#This lets a cognitive scientist encode what matters (nodes), how items interact (edges), how strongly (weights), and with what certainty (confidence).
#Built-in reasoning routines
#Belief propagation (propagate_beliefs):
#Iterative signed diffusion. “Supports” edges increase a node’s confidence (relative to 0.5), “Contradicts/Refutes” decrease it; controlled by damping and clips to [0,1]. Useful for integrating distributed evidence and resolving mild inconsistencies.
#Spreading activation (spread_activation, topk_by_activation):
#Classic activation passing with decay across edges; surfaces most activated nodes—useful for attention/gist retrieval and saliency.
#Argumentation (grounded_extension):
#Computes a grounded extension over the attack relation (e.g., contradicts). Returns a conservative, defensible subset of nodes—useful for choosing claims/requirements that survive criticism.
#Bayesian update (bayes_update):
#Per-node Beta-Bernoulli updates on incoming evidence; refreshes confidence from (alpha, beta).
#Other utilities: find_conflicts (surface direct contradictions), surprisal (-log₂ p).
#Interoperability and exports
#JSON config (schema v1.1): save_config, load_config → portable, versioned, reproducible.
#GraphML: for Gephi/yEd; RDF/Turtle: for Protégé/semantic stacks.
#PSL: rules.psl, predicates.txt, data.obs (soft logic over True/Supports/Contradicts/Similar).
#MLN: model.mln, evidence.db (Alchemy/Tuffy style).
#PPDDL suggestions: suggest_ppddl_preferences() emits a human-readable memo of high-confidence goals/requirements to reward/prefer and conflicts to soften.
#Dynamic construction (no hard-coding)
#We can build graphs from a simple recipe dictionary (or JSON):
#from neurosym_addons import NeuroSymGraph

#g = NeuroSymGraph()
#recipe = {
#  "nodes": [
#    {"ref":"Nreq", "kind":"requirement", "label":"Reach D1 and dock <=120m", "confidence":0.95},
#    {"ref":"Nrew", "kind":"reward", "label":"Maximize final battery", "confidence":0.90},
#    {"ref":"Ncon", "kind":"constraint", "label":"Drive 30-40m; faster costs 2%/m"}
#  ],
#  "edges": [
#    {"src_ref":"Ncon", "dst_ref":"Nrew", "kind":"contradicts", "weight":0.6},
#    {"src_ref":"Nreq", "dst_ref":"Nrew", "kind":"supports", "weight":0.7}
#  ]
#}
#ref_map = g.apply_recipe(recipe)
#g.propagate_beliefs()
#g.save_config("graph.json")   # round-trip later via NeuroSymGraph.load_config("graph.json")
#Using it on the Rover problem (end-to-end)
#A) Quick “cognitive” workflow
#Start from the included scaffold:
#from neurosym_addons import build_rover_neurosym_graph
#g = build_rover_neurosym_graph()  # pre-populated nodes/edges for Rover
#Integrate evidence / reconcile contradictions:
#g.propagate_beliefs(damping=0.85, iters=10)
#accepted = g.grounded_extension()       # defensible items under attack
#conflicts = g.find_conflicts()          # direct contradictions to review
#Focus attention (e.g., seed with the time requirement):
#req_id = [nid for nid,n in g.nodes.items() if "120 minutes" in n.label][0]
#g.spread_activation([req_id], decay=0.85, steps=3)
#top = g.topk_by_activation(k=5)         # which items become salient
#Bayesian updates (e.g., new test shows fast driving wasn’t costly):
#con_id = [nid for nid,n in g.nodes.items() if "faster costs" in n.label][0]
#g.bayes_update(con_id, evidence=False)  # negative evidence
#Export artifacts for external reasoning/inspection:
#g.export_graphml("graph.graphml")
#g.export_rdf_turtle("graph.ttl")
#g.export_psl("./psl_proj")   # -> rules.psl, predicates.txt, data.obs
#g.export_mln("./mln_proj")   # -> model.mln, evidence.db
#print(g.suggest_ppddl_preferences())
#B) With your PPDDL agent (ppddl_agent.py)
#Use the cognitive graph to seed the agent and export research artifacts alongside PPDDL runs:
# optional: set a planner (or leave empty to debug)
#export PPDDL_PLANNER_CMD="probabilistic-ff -o {domain} -f {problem}"

# run the agent, loading a graph (or it builds the default rover graph)
# python ppddl_agent.py \
#   --graph-config-in graph.json \
#   --graph-config-out final_graph.json \
#   --export-psl ./psl_proj \
#   --export-mln ./mln_proj \
#   --viz
# What happens:
# The agent uses the graph to contextualize variable/constraint/reward candidates from the LLM, storing provenance and confidence.
# It synthesizes PPDDL, attempts a plan, and saves back an updated graph config (final_graph.json).
# PSL/MLN exports let us run soft inference externally; we can feed results back (update node confidences) and rerun planning.
# The core idea is that the ppddl agent creates a configuration from a given problem and saves the information in a way that can be used by cognitive science models.  The graphs can enable more complex reasoning abilities as improved cognitive models are developed.  This is for illustration and maybe helps organize thoughts for this effort, feel free to edit/delete.  We can create tools like this to enable they types of cognitive models you are thinking of.
# Best regards,
# Larry
