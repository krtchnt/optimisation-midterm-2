# Noise-Aware Qubit Mapping for Quantum Circuit Compilation

Author: _6814001748 Kritchanat Thanapiphatsiri_

<!-- prettier-ignore -->
> [!IMPORTANT]
> This report was made under the **01204596 Optimisation** course of
> **Department of Computer Engineering**, **Faculity of Engineering**,
> **Kasetsart University**.

## Overview

This project tackles the **qubit mapping problem** in the NISQ era: given a
quantum circuit and a noisy physical processor with limited connectivity, find
an assignment of logical qubits to physical qubits that minimises both routing
overhead (SWAP insertions) and accumulated gate noise, while respecting
coherence-time constraints.

The solver uses **Simulated Annealing** with two neighbourhood operators (swap
and relocate), incremental delta evaluation, and multi-start restarts.

## Problem Formulation

| Symbol              | Meaning                                                                                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| $G_p = (V_p, E_p)$  | Physical coupling graph with per-qubit error $\varepsilon_1(v)$, per-edge error $\varepsilon_2(e)$, and coherence time $T_\text{coh}(v)$ |
| $G_l = (V_l, E_l)$  | Logical interaction graph extracted from the circuit, with gate counts as edge weights                                                   |
| $\pi : V_l \to V_p$ | Injective mapping from logical to physical qubits                                                                                        |

**Objective** (weighted combination):

$$\min_\pi \; \alpha \cdot C_\text{route}(\pi) + \beta \cdot C_\text{noise}(\pi)$$

subject to the coherence constraint for every logical qubit $i$:

$$\text{depth}_i \cdot t_\text{CX} + \text{swaps}_i \cdot t_\text{SWAP} \le T_\text{coh}(\pi(i))$$

## Project Structure

```ada
src/
  main.py        -- entry point: problem setup, solver invocation, result display
  graph.py       -- weighted undirected graph with Floyd-Warshall and path-error precomputation
  instance.py    -- coupling-graph generators (grid, heavy-hex) and interaction-graph generators
  objective.py   -- multi-objective evaluation with incremental delta updates
  sa.py          -- Simulated Annealing solver with swap/relocate moves and multi-restart
slides/
  main.typ       -- presentation source (Typst)
  main.pdf       -- compiled slides
```

## Usage

```bash
python src/main.py
```

The script generates a random problem instance (5x6 grid coupling graph, 10
logical qubits, 30 random gates), runs Simulated Annealing with 5 restarts, and
prints the mapping, cost breakdown, convergence plot, and comparison against
random baselines.

## Attributions

- The slide [KU logo](./slides/assets/KU_Logo_PNG.png) is owned by
  [Kasetsart University](https://ku.ac.th/th/kulogo).
