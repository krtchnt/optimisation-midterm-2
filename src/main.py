"""Noise-Aware Qubit Mapping for Quantum Circuit Compilation.

Solves the problem of mapping logical qubits to physical qubits on a
quantum processor's coupling graph, minimising routing cost (SWAP overhead)
and accumulated gate noise, subject to coherence time constraints.

Solved using Simulated Annealing - the classical analogue of Quantum Annealing.
"""

from __future__ import annotations

import random
import time

from instance import (
    ProblemInstance,
    make_grid_coupling,
    make_random_interaction,
)
from objective import ObjectiveFunction
from sa import SimulatedAnnealing


def print_instance_info(inst: ProblemInstance) -> None:
    g = inst.coupling
    print("=" * 60)
    print("PROBLEM INSTANCE")
    print("=" * 60)
    print(f"  Physical qubits:  {g.n}")
    print(f"  Physical links:   {len(g.edges())}")
    print(f"  Logical qubits:   {inst.n_logical}")
    print(f"  Interactions:     {len(inst.interactions)}")
    total_gates = sum(w for _, _, w in inst.interactions)
    print(f"  Total 2Q gates:   {total_gates}")
    print(f"  Alpha (routing):  {inst.alpha}")
    print(f"  Beta (noise):     {inst.beta}")
    print()


def print_mapping(inst: ProblemInstance, mapping: list[int]) -> None:
    print("QUBIT MAPPING (logical -> physical)")
    print("-" * 40)
    for i, p in enumerate(mapping):
        e1 = inst.coupling.vertex_attrs[p].get("e1", 0)
        t_coh = inst.coupling.vertex_attrs[p].get("t_coh", 0)
        print(f"  q{i} -> Q{p}  (e1={e1:.4f}, T_coh={t_coh:.1f} us)")
    print()


def print_cost_breakdown(obj: ObjectiveFunction, mapping: list[int]) -> None:
    rc = obj.routing_cost(mapping)
    nc = obj.noise_cost(mapping)
    pen = obj.coherence_penalty(mapping)
    total, feasible = obj.evaluate(mapping)

    print("COST BREAKDOWN")
    print("-" * 40)
    print(f"  Routing cost:     {rc:.4f}")
    print(f"  Noise cost:       {nc:.4f}")
    print(f"  Coherence penalty:{pen:.4f}")
    print(f"  Total cost:       {total:.4f}")
    print(f"  Feasible:         {'Yes' if feasible else 'No'}")
    print()


def print_convergence(history: list[float]) -> None:
    if not history:
        return
    print("CONVERGENCE (best cost over iterations)")
    print("-" * 40)
    n = len(history)
    width = 40
    lo = min(history)
    hi = max(history)
    span = hi - lo if hi > lo else 1.0
    for idx in range(0, n, max(1, n // 10)):
        val = history[idx]
        bar_len = int((val - lo) / span * width)
        bar = "#" * bar_len
        iteration = idx * 1000
        print(f"  {iteration:6d} | {bar:<{width}} {val:.4f}")
    print()


def main() -> None:
    seed = 42

    # --- Generate problem instance ---
    coupling = make_grid_coupling(rows=5, cols=6, seed=seed)
    n_logical, interactions = make_random_interaction(
        n_qubits=10, n_gates=30, seed=seed
    )

    inst = ProblemInstance(
        coupling=coupling,
        n_logical=n_logical,
        interactions=interactions,
        alpha=0.6,
        beta=0.4,
    )
    print_instance_info(inst)

    # --- Build objective ---
    obj = ObjectiveFunction(inst)

    # --- Run Simulated Annealing ---
    print("Running Simulated Annealing (5 restarts)...")
    sa = SimulatedAnnealing(
        obj,
        t_init=50.0,
        t_min=0.01,
        cooling_rate=0.9995,
        max_iter=100_000,
        seed=seed,
    )

    start = time.time()
    best_mapping, best_cost, history = sa.solve_restarts(n_restarts=5)
    elapsed = time.time() - start
    print(f"  Completed in {elapsed:.2f}s")
    print()

    # --- Display results ---
    print_mapping(inst, best_mapping)
    print_cost_breakdown(obj, best_mapping)
    print_convergence(history)

    # --- Random baseline comparison ---
    rng = random.Random(seed)
    random_costs: list[float] = []
    random_feasible = 0
    for _ in range(1000):
        physicals = list(range(coupling.n))
        rng.shuffle(physicals)
        rand_map = physicals[:n_logical]
        cost, feas = obj.evaluate(rand_map)
        random_costs.append(cost)
        if feas:
            random_feasible += 1

    mean_random = sum(random_costs) / len(random_costs)
    min_random = min(random_costs)

    print("COMPARISON VS RANDOM BASELINE (1000 samples)")
    print("-" * 40)
    print(f"  SA best cost:          {best_cost:.4f}")
    print(f"  Random mean cost:      {mean_random:.4f}")
    print(f"  Random best cost:      {min_random:.4f}")
    print(f"  Random feasibility:    {random_feasible}/1000")
    improvement = (1 - best_cost / mean_random) * 100 if mean_random > 0 else 0
    print(f"  SA improvement:        {improvement:.1f}% over random mean")


if __name__ == "__main__":
    main()
