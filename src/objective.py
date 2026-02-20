from __future__ import annotations

from instance import ProblemInstance


class ObjectiveFunction:
    """Evaluates the quality of a logical-to-physical qubit mapping."""

    def __init__(self, instance: ProblemInstance) -> None:
        self.inst = instance
        self.coupling = instance.coupling
        self.n_logical = instance.n_logical
        self.n_physical = instance.coupling.n
        self.interactions = instance.interactions

        self.dist = self.coupling.floyd_warshall()
        self.path_err = self.coupling.all_pairs_path_error()

        # Build adjacency list for logical interaction graph (for incremental eval)
        self.logical_adj: dict[int, list[tuple[int, int]]] = {
            i: [] for i in range(self.n_logical)
        }
        for i, j, w in self.interactions:
            self.logical_adj[i].append((j, w))
            self.logical_adj[j].append((i, w))

    def routing_cost(self, mapping: list[int]) -> float:
        cost = 0.0
        for i, j, w in self.interactions:
            d = self.dist[mapping[i]][mapping[j]]
            swaps = max(0, d - 1)
            cost += w * swaps
        return cost

    def noise_cost(self, mapping: list[int]) -> float:
        cost = 0.0
        # Two-qubit gate errors along routing paths
        for i, j, w in self.interactions:
            cost += w * self.path_err[mapping[i]][mapping[j]]
        # Single-qubit gate errors: depth(i) * epsilon_1(pi(i))
        for i in range(self.n_logical):
            e1 = self.coupling.vertex_attrs[mapping[i]].get("e1", 0.0)
            cost += self.inst.qubit_depths[i] * e1
        return cost

    def coherence_penalty(self, mapping: list[int]) -> float:
        """Compute penalty for coherence time violations.

        Each logical qubit's total gate time (including inserted SWAPs)
        must not exceed the coherence time of its assigned physical qubit.
        """
        penalty = 0.0
        for i in range(self.n_logical):
            p = mapping[i]
            t_coh = self.coupling.vertex_attrs[p].get("t_coh", float("inf"))
            base_depth = self.inst.qubit_depths[i]
            swap_count = 0
            for j, w in self.logical_adj[i]:
                d = self.dist[p][mapping[j]]
                swap_count += w * max(0, d - 1)
            total_time = base_depth * self.inst.t_cx + swap_count * self.inst.t_swap
            if total_time > t_coh:
                penalty += total_time - t_coh
        return penalty

    def evaluate(self, mapping: list[int]) -> tuple[float, bool]:
        """Evaluate a mapping. Returns (total_cost, is_feasible)."""
        rc = self.routing_cost(mapping)
        nc = self.noise_cost(mapping)
        pen = self.coherence_penalty(mapping)
        feasible = pen == 0.0
        cost = self.inst.alpha * rc + self.inst.beta * nc
        if not feasible:
            cost += 100.0 * pen
        return cost, feasible

    def evaluate_delta_swap(
        self, mapping: list[int], current_cost: float, i: int, j: int
    ) -> float:
        """Incrementally compute the new cost after swapping mapping[i] and mapping[j].

        Only recomputes terms involving logical qubits i and j.
        """
        delta_route = 0.0
        delta_noise = 0.0

        pi = mapping[i]
        pj = mapping[j]

        affected = set()
        for k, w in self.logical_adj[i]:
            affected.add((min(i, k), max(i, k), w))
        for k, w in self.logical_adj[j]:
            affected.add((min(j, k), max(j, k), w))

        for a, b, w in affected:
            old_pa = mapping[a]
            old_pb = mapping[b]

            new_pa = old_pa
            new_pb = old_pb
            if a == i:
                new_pa = pj
            elif a == j:
                new_pa = pi
            if b == i:
                new_pb = pj
            elif b == j:
                new_pb = pi

            old_d = self.dist[old_pa][old_pb]
            new_d = self.dist[new_pa][new_pb]
            delta_route += w * (max(0, new_d - 1) - max(0, old_d - 1))

            old_e = self.path_err[old_pa][old_pb]
            new_e = self.path_err[new_pa][new_pb]
            delta_noise += w * (new_e - old_e)

        # Single-qubit error delta: swapping changes which epsilon_1 each qubit sees
        e1_pi = self.coupling.vertex_attrs[pi].get("e1", 0.0)
        e1_pj = self.coupling.vertex_attrs[pj].get("e1", 0.0)
        depth_i = self.inst.qubit_depths[i]
        depth_j = self.inst.qubit_depths[j]
        # Old: depth_i*e1_pi + depth_j*e1_pj, New: depth_i*e1_pj + depth_j*e1_pi
        delta_noise += depth_i * (e1_pj - e1_pi) + depth_j * (e1_pi - e1_pj)

        delta = self.inst.alpha * delta_route + self.inst.beta * delta_noise

        # Recompute coherence penalty fully (it's fast enough)
        mapping[i], mapping[j] = mapping[j], mapping[i]
        new_pen = self.coherence_penalty(mapping)
        mapping[i], mapping[j] = mapping[j], mapping[i]
        old_pen = self.coherence_penalty(mapping)

        delta += 100.0 * (new_pen - old_pen)
        return delta
