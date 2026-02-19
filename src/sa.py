from __future__ import annotations

import math
import random

from objective import ObjectiveFunction


class SimulatedAnnealing:
    """Simulated Annealing solver for qubit mapping.

    Simulated Annealing is the classical analogue of Quantum Annealing.
    The Metropolis acceptance criterion mirrors quantum tunnelling through
    energy barriers, allowing escape from local optima.
    """

    def __init__(
        self,
        objective: ObjectiveFunction,
        t_init: float = 50.0,
        t_min: float = 0.01,
        cooling_rate: float = 0.9995,
        max_iter: int = 100_000,
        seed: int = 42,
    ) -> None:
        self.obj = objective
        self.n_logical = objective.n_logical
        self.n_physical = objective.n_physical
        self.t_init = t_init
        self.t_min = t_min
        self.cooling_rate = cooling_rate
        self.max_iter = max_iter
        self.rng = random.Random(seed)

    def initial_solution(self) -> list[int]:
        """Generate a random injective mapping."""
        physicals = list(range(self.n_physical))
        self.rng.shuffle(physicals)
        return physicals[: self.n_logical]

    def neighbor_swap(self, mapping: list[int]) -> tuple[list[int], int, int]:
        """Swap two logical qubits' physical assignments."""
        new = mapping[:]
        i = self.rng.randrange(self.n_logical)
        j = self.rng.randrange(self.n_logical)
        while j == i:
            j = self.rng.randrange(self.n_logical)
        new[i], new[j] = new[j], new[i]
        return new, i, j

    def neighbor_relocate(self, mapping: list[int]) -> tuple[list[int], int, int]:
        """Move one logical qubit to an unoccupied physical qubit."""
        used = set(mapping)
        free = [p for p in range(self.n_physical) if p not in used]
        if not free:
            return self.neighbor_swap(mapping)
        new = mapping[:]
        i = self.rng.randrange(self.n_logical)
        old_p = new[i]
        new[i] = self.rng.choice(free)
        return new, i, -1  # -1 signals relocate (not a swap)

    def solve(self) -> tuple[list[int], float, list[float]]:
        """Run Simulated Annealing. Returns (best_mapping, best_cost, history)."""
        current = self.initial_solution()
        current_cost, _ = self.obj.evaluate(current)

        best = current[:]
        best_cost = current_cost
        temp = self.t_init
        history: list[float] = []

        for it in range(self.max_iter):
            if self.rng.random() < 0.6:
                candidate, si, sj = self.neighbor_swap(current)
                if si >= 0 and sj >= 0:
                    delta = self.obj.evaluate_delta_swap(current, current_cost, si, sj)
                else:
                    cand_cost, _ = self.obj.evaluate(candidate)
                    delta = cand_cost - current_cost
            else:
                candidate, si, sj = self.neighbor_relocate(current)
                cand_cost, _ = self.obj.evaluate(candidate)
                delta = cand_cost - current_cost

            if delta < 0 or self.rng.random() < math.exp(-delta / max(temp, 1e-10)):
                current = candidate
                current_cost += delta

                if current_cost < best_cost:
                    best = current[:]
                    best_cost = current_cost

            temp = max(self.t_min, temp * self.cooling_rate)
            if it % 1000 == 0:
                history.append(best_cost)

        return best, best_cost, history

    def solve_restarts(
        self, n_restarts: int = 5
    ) -> tuple[list[int], float, list[float]]:
        """Run SA multiple times and return the best result."""
        overall_best: list[int] = []
        overall_cost = float("inf")
        overall_history: list[float] = []

        base_seed = self.rng.randint(0, 10**6)
        for r in range(n_restarts):
            self.rng = random.Random(base_seed + r)
            mapping, cost, history = self.solve()
            if cost < overall_cost:
                overall_best = mapping
                overall_cost = cost
                overall_history = history

        return overall_best, overall_cost, overall_history
