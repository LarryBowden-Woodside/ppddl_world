
import logging
from dataclasses import dataclass
from typing import Optional

from neurosym import NeuroSymGraph, NodeKind, EdgeKind


logger = logging.getLogger(__name__)


@dataclass
class SemanticModes:
    """High-level semantic flags derived from the NeuroSym graph."""

    hhv_stable: bool = False
    hhv_trend_down: bool = False
    storage_risk_high: bool = False
    spot_tight: bool = False
    spot_loose: bool = False
    plan_unstable: bool = False
    model_trust_low: bool = False


def _add_or_get_node(graph: NeuroSymGraph, kind: str, label: str) -> int:
    """
    Idempotently add or retrieve a node by label.

    We treat label as a unique key for semantics nodes to keep the
    graph stable across updates.
    """
    for nid, node in graph.nodes.items():
        if node.label == label:
            return nid
    return graph.add_node(kind, label)


def build_lng_semantic_graph() -> NeuroSymGraph:
    """
    Build a base LNG semantics graph with core conceptual nodes and edges.

    This is a lightweight prior; evidence updates will adjust confidences.
    """
    g = NeuroSymGraph()

    # HHV / field state
    n_hhv_stable = g.add_node(NodeKind.STATE, "Field2_HHV_Stable", confidence=0.5)
    n_hhv_trend_down = g.add_node(NodeKind.STATE, "Field2_HHV_DecreasingFast", confidence=0.5)

    # Storage / operational risk
    n_storage_risk_high = g.add_node(NodeKind.STATE, "Storage_Risk_High", confidence=0.3)
    n_storage_buffer_ok = g.add_node(NodeKind.STATE, "Storage_Buffer_Comfortable", confidence=0.7)

    # Spot market
    n_spot_tight = g.add_node(NodeKind.STATE, "Spot_Market_Tight", confidence=0.3)
    n_spot_loose = g.add_node(NodeKind.STATE, "Spot_Market_Loose", confidence=0.3)

    # Planning behavior
    n_plan_stable = g.add_node(NodeKind.STATE, "Plan_Stable", confidence=0.7)
    n_plan_unstable = g.add_node(NodeKind.STATE, "Plan_FlipFlopping", confidence=0.3)

    # Model trust
    n_model_trust = g.add_node(NodeKind.ASSUMPTION, "Physics_Model_Trusted", confidence=0.8)
    n_model_distrust = g.add_node(NodeKind.ASSUMPTION, "Physics_Model_Suspect", confidence=0.2)

    # Basic relationships
    g.add_edge(n_hhv_trend_down, n_storage_risk_high, EdgeKind.SUPPORTS, weight=0.7)
    g.add_edge(n_storage_buffer_ok, n_storage_risk_high, EdgeKind.CONTRADICTS, weight=0.7)

    g.add_edge(n_spot_tight, n_storage_risk_high, EdgeKind.SUPPORTS, weight=0.5)
    g.add_edge(n_spot_loose, n_storage_risk_high, EdgeKind.CONTRADICTS, weight=0.4)

    g.add_edge(n_plan_unstable, n_plan_stable, EdgeKind.CONTRADICTS, weight=0.8)
    g.add_edge(n_plan_stable, n_plan_unstable, EdgeKind.CONTRADICTS, weight=0.4)

    g.add_edge(n_model_trust, n_model_distrust, EdgeKind.CONTRADICTS, weight=0.8)

    # Initial propagation to settle priors
    g.propagate_beliefs()
    logger.info("Initialized LNG semantic NeuroSym graph.")
    return g


def record_hhv_evidence(
    graph: Optional[NeuroSymGraph],
    train: int,
    mean: float,
    trend: float,
    confidence: float,
) -> None:
    """
    Record evidence about HHV behavior into the semantics graph.

    For now we do not distinguish trains semantically; we focus on the
    qualitative pattern: stable vs decreasing fast.
    """
    if graph is None:
        return

    try:
        # Thresholds are heuristic and can be tuned later.
        trend_abs = abs(trend)
        stable = trend_abs < 0.1 and confidence > 0.6
        decreasing_fast = trend < -0.3 and confidence > 0.6

        nid_stable = _add_or_get_node(graph, NodeKind.STATE, "Field2_HHV_Stable")
        nid_down = _add_or_get_node(graph, NodeKind.STATE, "Field2_HHV_DecreasingFast")

        node_stable = graph.nodes[nid_stable]
        node_down = graph.nodes[nid_down]

        if stable:
            node_stable.confidence = min(0.95, node_stable.confidence + 0.1)
            node_down.confidence = max(0.0, node_down.confidence - 0.1)
        elif decreasing_fast:
            node_down.confidence = min(0.95, node_down.confidence + 0.15)
            node_stable.confidence = max(0.0, node_stable.confidence - 0.15)
        else:
            # Mild evidence: nudge towards neutral
            node_stable.confidence = 0.5 * node_stable.confidence + 0.5 * 0.5
            node_down.confidence = 0.5 * node_down.confidence + 0.5 * 0.5
    except Exception as e:
        logger.warning(f"Failed to record HHV evidence in semantics graph: {e}")


def record_spot_market_evidence(
    graph: Optional[NeuroSymGraph],
    price: float,
    available: bool,
) -> None:
    """Record evidence about spot market tightness/looseness."""
    if graph is None:
        return

    try:
        nid_tight = _add_or_get_node(graph, NodeKind.STATE, "Spot_Market_Tight")
        nid_loose = _add_or_get_node(graph, NodeKind.STATE, "Spot_Market_Loose")

        tight = price > 95.0 and not available
        loose = price < 85.0 and available

        node_tight = graph.nodes[nid_tight]
        node_loose = graph.nodes[nid_loose]

        if tight:
            node_tight.confidence = min(0.98, node_tight.confidence + 0.15)
            node_loose.confidence = max(0.0, node_loose.confidence - 0.1)
        elif loose:
            node_loose.confidence = min(0.98, node_loose.confidence + 0.15)
            node_tight.confidence = max(0.0, node_tight.confidence - 0.1)
        else:
            # Neutral update
            node_tight.confidence = 0.5 * node_tight.confidence + 0.5 * 0.5
            node_loose.confidence = 0.5 * node_loose.confidence + 0.5 * 0.5
    except Exception as e:
        logger.warning(f"Failed to record spot market evidence in semantics graph: {e}")


def record_plan_stability_evidence(
    graph: Optional[NeuroSymGraph],
    similarity: float,
    action_changes: int,
    timing_changes: int,
) -> None:
    """Record evidence about plan stability vs flip-flopping."""
    if graph is None:
        return

    try:
        nid_stable = _add_or_get_node(graph, NodeKind.STATE, "Plan_Stable")
        nid_unstable = _add_or_get_node(graph, NodeKind.STATE, "Plan_FlipFlopping")

        node_stable = graph.nodes[nid_stable]
        node_unstable = graph.nodes[nid_unstable]

        significant_changes = (1.0 - similarity) > 0.1 or action_changes > 2 or timing_changes > 0

        if significant_changes:
            node_unstable.confidence = min(0.98, node_unstable.confidence + 0.15)
            node_stable.confidence = max(0.0, node_stable.confidence - 0.1)
        else:
            node_stable.confidence = min(0.98, node_stable.confidence + 0.1)
            node_unstable.confidence = max(0.0, node_unstable.confidence - 0.05)
    except Exception as e:
        logger.warning(f"Failed to record plan stability evidence in semantics graph: {e}")


def record_model_checker_evidence(
    graph: Optional[NeuroSymGraph],
    num_violations: int,
) -> None:
    """Record evidence about model physics/invariant trust."""
    if graph is None:
        return

    try:
        nid_trust = _add_or_get_node(graph, NodeKind.ASSUMPTION, "Physics_Model_Trusted")
        nid_suspect = _add_or_get_node(graph, NodeKind.ASSUMPTION, "Physics_Model_Suspect")

        node_trust = graph.nodes[nid_trust]
        node_suspect = graph.nodes[nid_suspect]

        if num_violations == 0:
            node_trust.confidence = min(0.99, node_trust.confidence + 0.05)
            node_suspect.confidence = max(0.0, node_suspect.confidence - 0.05)
        else:
            # Scale distrust with violation count but keep bounded
            delta = min(0.3, 0.05 * num_violations)
            node_suspect.confidence = min(0.99, node_suspect.confidence + delta)
            node_trust.confidence = max(0.0, node_trust.confidence - delta * 0.8)
    except Exception as e:
        logger.warning(f"Failed to record model checker evidence in semantics graph: {e}")


def propagate_semantics(graph: Optional[NeuroSymGraph]) -> None:
    """Run heuristic belief propagation on the semantics graph."""
    if graph is None:
        return
    try:
        graph.propagate_beliefs()
    except Exception as e:
        logger.warning(f"Failed to propagate semantics graph beliefs: {e}")


def derive_modes(graph: Optional[NeuroSymGraph]) -> SemanticModes:
    """
    Derive high-level semantic flags from the current graph state.

    If graph is None, returns default (all False) modes.
    """
    modes = SemanticModes()
    if graph is None:
        return modes

    def conf(label: str) -> float:
        for node in graph.nodes.values():
            if node.label == label:
                return float(getattr(node, "confidence", 0.0))
        return 0.0

    try:
        modes.hhv_stable = conf("Field2_HHV_Stable") > 0.7
        modes.hhv_trend_down = conf("Field2_HHV_DecreasingFast") > 0.6
        modes.storage_risk_high = conf("Storage_Risk_High") > 0.6
        modes.spot_tight = conf("Spot_Market_Tight") > 0.6
        modes.spot_loose = conf("Spot_Market_Loose") > 0.6
        modes.plan_unstable = conf("Plan_FlipFlopping") > 0.6
        modes.model_trust_low = conf("Physics_Model_Suspect") > 0.6
    except Exception as e:
        logger.warning(f"Failed to derive semantic modes: {e}")

    return modes


