import os
import json
import math
import time
import logging
import tempfile
from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Tuple, Optional, Any, Union

logging.basicConfig(level=logging.INFO)

SCHEMA_VERSION = "1.2"

# ---------------------------
# Enums
# ---------------------------

class NodeKind(Enum):
    """Types of nodes in the neuro-symbolic graph."""
    REQUIREMENT = "requirement"
    CONSTRAINT = "constraint"
    ASSUMPTION = "assumption"
    HYPOTHESIS = "hypothesis"
    EVIDENCE = "evidence"
    OBSERVATION = "observation"
    PREDICATE = "predicate"
    FUNCTION = "function"
    ACTION = "action"
    STATE = "state"
    GOAL = "goal"
    REWARD = "reward"
    JUSTIFICATION = "justification"
    ARGUMENT = "argument"
    METRIC = "metric"
    CUSTOM = "custom"
    UNKNOWN = "unknown"

    @staticmethod
    def from_str(s: str) -> "NodeKind":
        s = (s or "").strip().lower()
        for k in NodeKind:
            if k.value == s:
                return k
        return NodeKind.CUSTOM if s else NodeKind.UNKNOWN


class EdgeKind(Enum):
    """Types of edges/relationships."""
    SUPPORTS = "supports"
    CONTRADICTS = "contradicts"
    ENTAILS = "entails"
    REFUTES = "refutes"
    REFINES = "refines"
    TRACES_TO = "traces_to"
    DEPENDS_ON = "depends_on"
    OBSERVED_IN = "observed_in"
    DERIVED_FROM = "derived_from"
    ENABLES = "enables"
    INHIBITS = "inhibits"
    CAUSES = "causes"
    PREVENTS = "prevents"
    SIMILAR = "similar"

    @staticmethod
    def from_str(s: str) -> "EdgeKind":
        s = (s or "").strip().lower()
        for k in EdgeKind:
            if k.value == s:
                return k
        return EdgeKind.SIMILAR if s else EdgeKind.SUPPORTS


# ---------------------------
# Data Structures
# ---------------------------

@dataclass
class NSNode:
    """Neuro-symbolic node representing a cognitive item."""
    id: int
    kind: NodeKind
    label: str
    attributes: Dict[str, Any] = field(default_factory=dict)
    confidence: float = 0.75  # [0,1]
    weight: float = 1.0
    activation: float = 0.0
    timestamp: float = field(default_factory=lambda: time.time())
    source: Optional[str] = None
    custom_kind: Optional[str] = None
    activation_score: float = 0.0 # Alias for confidence in renamed mode


@dataclass
class NSEdge:
    """Neuro-symbolic edge."""
    src: int
    dst: int
    kind: EdgeKind
    weight: float = 1.0


@dataclass
class ConditionalProbabilityTable:
    """CPT for Bayesian Network node."""
    node_id: int
    parent_ids: List[int]
    probabilities: Dict[Tuple[bool, ...], float]


# ---------------------------
# Core Graph Class
# ---------------------------

class NeuroSymGraph:
    """
    Neuro-symbolic graph with support for heuristic and Bayesian reasoning.
    """
    
    def __init__(self):
        self.nodes: Dict[int, NSNode] = {}
        self.edges: List[NSEdge] = []
        self._next_id = 0
        
        # Bayesian extensions
        self.cpts: Dict[int, ConditionalProbabilityTable] = {}
        self.evidence: Dict[int, bool] = {}

    # ---- Node/Edge Ops ----
    def add_node(self, kind: Union[NodeKind, str], label: str, **kwargs) -> int:
        nk = NodeKind.from_str(kind) if isinstance(kind, str) else kind
        custom_kind = kwargs.pop("custom_kind", None)
        if isinstance(kind, str) and nk in (NodeKind.CUSTOM, NodeKind.UNKNOWN):
            custom_kind = kind
        nid = self._next_id
        self.nodes[nid] = NSNode(id=nid, kind=nk, label=label, custom_kind=custom_kind, **kwargs)
        self._next_id += 1
        return nid

    def add_edge(self, src: int, dst: int, kind: Union[EdgeKind, str], weight: float = 1.0) -> None:
        ek = EdgeKind.from_str(kind) if isinstance(kind, str) else kind
        self.edges.append(NSEdge(src=src, dst=dst, kind=ek, weight=weight))

    def neighbors_in(self, nid: int) -> List[NSEdge]:
        return [e for e in self.edges if e.dst == nid]

    def neighbors_out(self, nid: int) -> List[NSEdge]:
        return [e for e in self.edges if e.src == nid]

    # ---- Inference ----

    def propagate_beliefs(self, damping: float = 0.85, iters: int = 10) -> None:
        """Heuristic belief propagation (signed message passing)."""
        conf = {nid: n.confidence for nid, n in self.nodes.items()}
        for _ in range(iters):
            new_conf = conf.copy()
            for nid in self.nodes:
                incoming = 0.0
                total_w = 0.0
                for e in self.neighbors_in(nid):
                    src_c = conf[e.src]
                    sgn = 1.0
                    if e.kind in (EdgeKind.CONTRADICTS, EdgeKind.REFUTES, EdgeKind.INHIBITS, EdgeKind.PREVENTS):
                        sgn = -1.0
                    incoming += sgn * e.weight * (src_c - 0.5)
                    total_w += abs(e.weight)
                if total_w > 0:
                    delta = damping * (incoming / total_w)
                    new_conf[nid] = max(0.0, min(1.0, conf[nid] + delta))
            conf = new_conf
        for nid, val in conf.items():
            self.nodes[nid].confidence = val

    # ---- Bayesian Extensions ----

    def add_cpt(self, node_id: int, parent_ids: List[int], probabilities: Dict[Tuple[bool, ...], float]):
        self.cpts[node_id] = ConditionalProbabilityTable(node_id, parent_ids, probabilities)

    def compute_posterior(self, query_node_id: int) -> float:
        """Compute posterior probability using simple Bayesian inference."""
        if query_node_id in self.evidence:
            return 1.0 if self.evidence[query_node_id] else 0.0
        
        if query_node_id not in self.cpts:
            return self.nodes[query_node_id].confidence
        
        cpt = self.cpts[query_node_id]
        parent_states = []
        for parent_id in cpt.parent_ids:
            parent_prob = self.compute_posterior(parent_id) # Recursive call (tree assumption)
            parent_states.append(parent_prob > 0.5)
        
        parent_tuple = tuple(parent_states)
        return cpt.probabilities.get(parent_tuple, self.nodes[query_node_id].confidence)

    def propagate_beliefs_bayesian(self, max_iters: int = 10) -> None:
        """Bayesian belief propagation."""
        for _ in range(max_iters):
            updated = False
            for nid, node in self.nodes.items():
                if nid in self.evidence: continue
                if nid in self.cpts:
                    new_conf = self.compute_posterior(nid)
                    if abs(new_conf - node.confidence) > 0.001:
                        node.confidence = new_conf
                        updated = True
            if not updated: break

    # ---- IO/Export ----

    def export_graphml(self, path: str) -> None:
        """Export to GraphML."""
        def esc(s: str) -> str:
            return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        with open(path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write('<graphml xmlns="http://graphml.graphdrawing.org/xmlns">\n')
            f.write('  <graph edgedefault="directed">\n')
            for nid, n in self.nodes.items():
                k = n.custom_kind or n.kind.value
                f.write(f'    <node id="n{nid}"><data key="label">{esc(n.label)}</data>'
                        f'<data key="kind">{k}</data><data key="confidence">{n.confidence}</data></node>\n')
            for i, e in enumerate(self.edges):
                f.write(f'    <edge id="e{i}" source="n{e.src}" target="n{e.dst}">'
                        f'<data key="kind">{e.kind.value}</data><data key="weight">{e.weight}</data></edge>\n')
            f.write("  </graph>\n</graphml>\n")

    def visualize(self, output_file: str = "graph.html") -> None:
        """Visualize using pyvis (if available)."""
        try:
            from pyvis.network import Network
            net = Network(height="900px", width="100%", directed=True, bgcolor="#222222", font_color="white")
            for nid, node in self.nodes.items():
                net.add_node(nid, label=node.label, title=f"{node.kind.value}\nConf: {node.confidence:.2f}")
            for edge in self.edges:
                net.add_edge(edge.src, edge.dst, label=edge.kind.value)
            net.show(output_file, notebook=False)
        except ImportError:
            logging.warning("pyvis not installed. Skipping visualization.")


# ---------------------------
# Helper Functions
# ---------------------------

def rename_confidence_to_activation(graph: NeuroSymGraph) -> NeuroSymGraph:
    """Rename 'confidence' to 'activation_score'."""
    for _, node in graph.nodes.items():
        node.activation_score = node.confidence
    return graph

def convert_to_bayesian_network(graph: NeuroSymGraph) -> NeuroSymGraph:
    """Convert heuristic graph to Bayesian network by adding CPTs."""
    for edge in graph.edges:
        # Simple logic: Supports -> High prob, Contradicts -> Low prob
        prob_true = 0.8 if edge.kind in (EdgeKind.SUPPORTS, EdgeKind.ENTAILS) else 0.2
        graph.add_cpt(edge.dst, [edge.src], {(True,): prob_true, (False,): 1-prob_true})
    return graph


def build_rover_neurosym_graph() -> "NeuroSymGraph":
    """Build a pre-configured rover problem graph."""
    g = NeuroSymGraph()
    
    # Core requirements and objectives
    req_time = g.add_node("requirement", "Reach destination-1 and dock within 120 minutes", confidence=0.95)
    obj_batt = g.add_node("reward", "Maximize final battery at docking", confidence=0.9)
    
    # Constraints
    con_drive = g.add_node("constraint", "Driving takes 30..40 minutes; faster costs 2% per minute saved", confidence=0.9)
    con_charge = g.add_node("constraint", "Charging: +1%/min to 80%, then 1% per 2 min", confidence=0.9)
    
    # Actions
    opt_diag = g.add_node("action", "Optional diagnostics 10 minutes; no benefit", confidence=0.8)
    act_drive = g.add_node("action", "Drive(duration) with energy trade-off", confidence=0.85)
    act_charge = g.add_node("action", "Charge(minutes) piecewise rate", confidence=0.85)
    act_dock = g.add_node("action", "Dock 20 minutes; requires arrival", confidence=0.95)

    # Relationships
    g.add_edge(act_drive, obj_batt, "contradicts", 0.6)
    g.add_edge(act_charge, obj_batt, "supports", 0.7)
    g.add_edge(opt_diag, req_time, "contradicts", 0.4)
    g.add_edge(con_drive, act_drive, "entails", 0.8)
    g.add_edge(con_charge, act_charge, "entails", 0.8)
    g.add_edge(req_time, act_dock, "depends_on", 0.9)
    g.add_edge(act_dock, obj_batt, "supports", 0.5)

    # Propagate beliefs
    g.propagate_beliefs()
    return g


