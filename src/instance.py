from __future__ import annotations

import random
from dataclasses import dataclass, field

from graph import Graph


def make_grid_coupling(rows: int, cols: int, seed: int = 0) -> Graph:
    """Create a grid coupling graph with realistic noise parameters."""
    rng = random.Random(seed)
    n = rows * cols
    g = Graph(n)

    def idx(r: int, c: int) -> int:
        return r * cols + c

    for r in range(rows):
        for c in range(cols):
            v = idx(r, c)
            g.vertex_attrs[v] = {
                "e1": rng.uniform(1e-4, 5e-3),
                "t_coh": rng.uniform(15.0, 60.0),
            }
            if c + 1 < cols:
                g.add_edge(v, idx(r, c + 1), error=rng.uniform(5e-3, 5e-2))
            if r + 1 < rows:
                g.add_edge(v, idx(r + 1, c), error=rng.uniform(5e-3, 5e-2))
    return g


def make_heavy_hex_coupling(rows: int, cols: int, seed: int = 0) -> Graph:
    """Create an IBM heavy-hex lattice coupling graph.

    Heavy-hex: hexagonal lattice with a bridge qubit on every edge.
    Vertex qubits have degree 3, bridge qubits have degree 2.
    """
    rng = random.Random(seed)
    positions: list[tuple[float, float]] = []
    edges: list[tuple[int, int]] = []

    hex_ids: dict[tuple[int, int], int] = {}
    node_count = 0

    for r in range(rows):
        for c in range(cols):
            hex_ids[(r, c)] = node_count
            positions.append((c * 2.0 + (r % 2), r * 1.73))
            node_count += 1

    bridge_pairs: list[tuple[int, int]] = []
    for r in range(rows):
        for c in range(cols):
            v = hex_ids[(r, c)]
            if c + 1 < cols:
                u = hex_ids[(r, c + 1)]
                bridge_pairs.append((v, u))
            if r + 1 < rows:
                offset = 0 if r % 2 == 0 else -1
                nc = c + offset
                if 0 <= nc < cols:
                    u = hex_ids[(r + 1, nc)]
                    bridge_pairs.append((v, u))
                nc2 = c + offset + 1
                if 0 <= nc2 < cols:
                    u = hex_ids[(r + 1, nc2)]
                    bridge_pairs.append((v, u))

    seen: set[tuple[int, int]] = set()
    unique_pairs: list[tuple[int, int]] = []
    for a, b in bridge_pairs:
        key = (min(a, b), max(a, b))
        if key not in seen:
            seen.add(key)
            unique_pairs.append((a, b))

    for a, b in unique_pairs:
        bridge_id = node_count
        node_count += 1
        edges.append((a, bridge_id))
        edges.append((bridge_id, b))

    g = Graph(node_count)
    for v in range(node_count):
        g.vertex_attrs[v] = {
            "e1": rng.uniform(1e-4, 5e-3),
            "t_coh": rng.uniform(50.0, 200.0),
        }
    for u, v in edges:
        g.add_edge(u, v, error=rng.uniform(5e-3, 5e-2))
    return g


def make_random_interaction(
    n_qubits: int, n_gates: int, seed: int = 0
) -> tuple[int, list[tuple[int, int, int]]]:
    """Generate a random quantum circuit interaction graph.

    Returns (n_qubits, edges) where edges are (i, j, weight).
    Weight is the number of 2-qubit gates between qubits i and j.
    """
    rng = random.Random(seed)
    gate_counts: dict[tuple[int, int], int] = {}
    for _ in range(n_gates):
        i = rng.randrange(n_qubits)
        j = rng.randrange(n_qubits)
        while j == i:
            j = rng.randrange(n_qubits)
        key = (min(i, j), max(i, j))
        gate_counts[key] = gate_counts.get(key, 0) + 1
    edges = [(i, j, w) for (i, j), w in gate_counts.items()]
    return n_qubits, edges


def make_qft_interaction(n_qubits: int) -> tuple[int, list[tuple[int, int, int]]]:
    """Generate interaction graph for a QFT circuit (all-to-all, decreasing weights)."""
    edges: list[tuple[int, int, int]] = []
    for i in range(n_qubits):
        for j in range(i + 1, n_qubits):
            weight = max(1, n_qubits - (j - i))
            edges.append((i, j, weight))
    return n_qubits, edges


@dataclass
class ProblemInstance:
    coupling: Graph
    n_logical: int
    interactions: list[tuple[int, int, int]]  # (logical_i, logical_j, weight)
    alpha: float = 0.6
    beta: float = 0.4
    t_single: float = 0.035  # microseconds
    t_cx: float = 0.3
    t_swap: float = 0.9  # 3 CNOTs
    qubit_depths: list[int] = field(default_factory=list)

    def __post_init__(self) -> None:
        if not self.qubit_depths:
            depths = [0] * self.n_logical
            for i, j, w in self.interactions:
                depths[i] += w
                depths[j] += w
            self.qubit_depths = depths
