#import "@preview/touying:0.6.1": *
#import themes.university: *
#import "@preview/cetz:0.4.1"
#import "@preview/fletcher:0.5.8" as fletcher: edge, node
#import "@preview/numbly:0.1.0": numbly
#import "@preview/theorion:0.4.1": *
#import cosmos.clouds: *
#show: show-theorion

// cetz and fletcher bindings for touying
#let cetz-canvas = touying-reducer.with(
  reduce: cetz.canvas,
  cover: cetz.draw.hide.with(bounds: true),
)
#let fletcher-diagram = touying-reducer.with(
  reduce: fletcher.diagram,
  cover: fletcher.hide,
)

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-common(frozen-counters: (theorem-counter,)),
  config-info(
    title: [Noise-Aware Qubit Mapping for Quantum Circuit Compilation],
    subtitle: [A Simulated Annealing Approach],
    author: [Kritchanat Thanapiphatsiri],
    date: datetime(year: 2026, month: 2, day: 20),
    institution: [Department of Computer Engineering \ Kasetsart University],
    logo: box(image("assets/KU_Logo_PNG.png"), width: 1.25cm, baseline: 60%),
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

// Custom title slide with logo at bottom-right instead of top-right
#touying-slide-wrapper(self => {
  self = utils.merge-dicts(self, config-common(freeze-slide-counter: true))
  let info = self.info
  touying-slide(
    self: self,
    {
      place(
        bottom + right,
        dx: -0.5cm,
        dy: -0.5cm,
        image("assets/KU_Logo_PNG.png", width: 2.5cm),
      )
      align(
        center + horizon,
        {
          block(
            inset: 0em,
            breakable: false,
            {
              text(size: 2em, fill: self.colors.primary, strong(info.title))
              parbreak()
              text(size: 1.2em, fill: self.colors.primary, info.subtitle)
            },
          )
          set text(size: .8em)
          text(fill: self.colors.neutral-darkest, info.author)
          v(1em)
          parbreak()
          text(size: .9em, info.institution)
          parbreak()
          text(size: .8em, utils.display-info-date(self))
        },
      )
    },
  )
})

== Outline <touying:hidden>

#components.adaptive-columns(outline(title: none, indent: 1em))


= The Problem

== The Quantum Compilation Challenge

In the NISQ (Noisy Intermediate-Scale Quantum) era, quantum processors have
*limited qubit connectivity*.

#pause

- Two-qubit gates (e.g. CNOT) can only operate on *physically adjacent* qubits
- Quantum circuits assume *all-to-all* logical connectivity
- A *compiler* must map logical qubits to physical qubits and insert SWAP
  operations

#pause

#v(1em)
#align(center)[
  #cetz.canvas(length: 1.5em, {
    import cetz.draw: *
    // Two qubit wires
    line((0, 0), (5, 0), stroke: 0.5pt)
    line((0, -1.5), (5, -1.5), stroke: 0.5pt)
    // CNOT 1: control top, target bottom
    line((1, 0), (1, -1.5), stroke: 0.5pt)
    circle((1, 0), radius: 0.2, fill: blue.lighten(70%), stroke: 0.5pt)
    circle((1, -1.5), radius: 0.12, fill: black)
    // CNOT 2: control bottom, target top
    line((2.5, 0), (2.5, -1.5), stroke: 0.5pt)
    circle((2.5, -1.5), radius: 0.2, fill: blue.lighten(70%), stroke: 0.5pt)
    circle((2.5, 0), radius: 0.12, fill: black)
    // CNOT 3: control top, target bottom
    line((4, 0), (4, -1.5), stroke: 0.5pt)
    circle((4, 0), radius: 0.2, fill: blue.lighten(70%), stroke: 0.5pt)
    circle((4, -1.5), radius: 0.12, fill: black)
  })
]

---

#slide[
  #align(center + horizon)[
    #fletcher-diagram(
      spacing: (2.5em, 1.5em),
      node-stroke: 0.6pt,
      node((0, 0), $q_0$, shape: rect, width: 1.8em, height: 1.3em),
      node((0, 1), $q_1$, shape: rect, width: 1.8em, height: 1.3em),
      node((0, 2), $q_2$, shape: rect, width: 1.8em, height: 1.3em),
      edge((0, 0), (0, 1), "-"),
      edge((0, 0), (0, 2), "-", bend: 45deg),
      edge((0, 1), (0, 2), "-"),
      pause,
      node((1.5, 1), $ arrow.r.double.long^pi $),
      pause,
      node(
        (3, 0.5),
        $Q_0$,
        shape: circle,
        radius: 0.8em,
        fill: blue.lighten(80%),
      ),
      node(
        (4, 0.5),
        $Q_1$,
        shape: circle,
        radius: 0.8em,
        fill: blue.lighten(80%),
      ),
      node(
        (3, 1.5),
        $Q_2$,
        shape: circle,
        radius: 0.8em,
        fill: blue.lighten(80%),
      ),
      node(
        (4, 1.5),
        $Q_3$,
        shape: circle,
        radius: 0.8em,
        fill: blue.lighten(80%),
      ),
      edge((3, 0.5), (4, 0.5), "-"),
      edge((3, 0.5), (3, 1.5), "-"),
      edge((4, 0.5), (4, 1.5), "-"),
      edge((3, 1.5), (4, 1.5), "-"),
    )

    #text(size: 0.8em)[_Logical circuit (left) mapped onto physical coupling
    graph (right)_]
  ]
]


= Problem Formulation

== The Coupling Graph

#definition(title: "Coupling Graph")[
  A *coupling graph* $G_p = (V_p, E_p)$ represents the physical qubit topology
  of a quantum processor, where $V_p$ is the set of physical qubits and $E_p$
  are the allowed two-qubit gate connections.
]

#pause

Each vertex $v in V_p$ has attributes:
- Single-qubit error rate $epsilon_1(v)$ and coherence time $T_("coh")(v)$

Each edge $e in E_p$ has a two-qubit gate error rate $epsilon_2(e)$.

---

=== Coupling Graph Example

#align(center)[
  #text(size: 0.85em)[
    $4 times 3$ grid coupling graph (inspired by IBM devices)
  ]
]

#align(center)[
  #fletcher.diagram(
    spacing: (2.5em, 2.5em),
    node-stroke: 0.6pt,
    // Row 0
    node((0, 0), $Q_0$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    node((1, 0), $Q_1$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    node(
      (2, 0),
      $Q_2$,
      shape: circle,
      radius: 0.8em,
      fill: yellow.lighten(60%),
    ),
    node((3, 0), $Q_3$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    // Row 1
    node(
      (0, 1),
      $Q_4$,
      shape: circle,
      radius: 0.8em,
      fill: yellow.lighten(60%),
    ),
    node((1, 1), $Q_5$, shape: circle, radius: 0.8em, fill: red.lighten(70%)),
    node((2, 1), $Q_6$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    node((3, 1), $Q_7$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    // Row 2
    node((0, 2), $Q_8$, shape: circle, radius: 0.8em, fill: green.lighten(70%)),
    node(
      (1, 2),
      $Q_9$,
      shape: circle,
      radius: 0.8em,
      fill: yellow.lighten(60%),
    ),
    node(
      (2, 2),
      $Q_A$,
      shape: circle,
      radius: 0.8em,
      fill: green.lighten(70%),
    ),
    node((3, 2), $Q_B$, shape: circle, radius: 0.8em, fill: red.lighten(70%)),
    // Horizontal edges
    edge((0, 0), (1, 0), "-"),
    edge((1, 0), (2, 0), "-"),
    edge((2, 0), (3, 0), "-"),
    edge((0, 1), (1, 1), "-"),
    edge((1, 1), (2, 1), "-"),
    edge((2, 1), (3, 1), "-"),
    edge((0, 2), (1, 2), "-"),
    edge((1, 2), (2, 2), "-"),
    edge((2, 2), (3, 2), "-"),
    // Vertical edges
    edge((0, 0), (0, 1), "-"),
    edge((1, 0), (1, 1), "-"),
    edge((2, 0), (2, 1), "-"),
    edge((3, 0), (3, 1), "-"),
    edge((0, 1), (0, 2), "-"),
    edge((1, 1), (1, 2), "-"),
    edge((2, 1), (2, 2), "-"),
    edge((3, 1), (3, 2), "-"),
  )
]

#align(center)[
  #text(size: 0.75em)[
    Color: #text(fill: green.darken(20%))[low error] / #text(
      fill: yellow.darken(20%),
    )[medium] / #text(fill: red.darken(20%))[high error]
  ]
]

== Interaction Graph

#definition(title: "Interaction Graph")[
  An *interaction graph* $G_l = (V_l, E_l, w)$ is derived from a quantum
  circuit, where $V_l$ is the set of logical qubits, $E_l$ are pairs requiring
  two-qubit gates, and $w: E_l arrow.r NN^+$ is the gate count.
]

#pause

#align(center)[
  #grid(
    columns: (auto, auto, auto),
    column-gutter: 1.5em,
    align: horizon,
    // Quantum circuit
    cetz.canvas(length: 1em, {
      import cetz.draw: *
      // Qubit wires
      for (i, label) in ((0, $q_0$), (1, $q_1$), (2, $q_2$)) {
        content((-1.5, -i * 1.5), label)
        line((0, -i * 1.5), (6, -i * 1.5), stroke: 0.5pt)
      }
      // CNOT q0-q1
      line((1.5, 0), (1.5, -1.5), stroke: 0.5pt)
      circle((1.5, 0), radius: 0.25, fill: blue.lighten(70%), stroke: 0.5pt)
      circle((1.5, -1.5), radius: 0.15, fill: black)
      // CNOT q0-q2
      line((3, 0), (3, -3), stroke: 0.5pt)
      circle((3, 0), radius: 0.25, fill: blue.lighten(70%), stroke: 0.5pt)
      circle((3, -3), radius: 0.15, fill: black)
      // CNOT q1-q2
      line((4.5, -1.5), (4.5, -3), stroke: 0.5pt)
      circle((4.5, -1.5), radius: 0.25, fill: blue.lighten(70%), stroke: 0.5pt)
      circle((4.5, -3), radius: 0.15, fill: black)
    }),
    // Arrow
    $ arrow.r.double $,
    // Interaction graph
    fletcher.diagram(
      spacing: 2em,
      node-stroke: 0.6pt,
      node(
        (0, 0),
        $q_0$,
        shape: circle,
        radius: 0.8em,
        fill: orange.lighten(70%),
      ),
      node(
        (1, 0),
        $q_1$,
        shape: circle,
        radius: 0.8em,
        fill: orange.lighten(70%),
      ),
      node(
        (0.5, 1),
        $q_2$,
        shape: circle,
        radius: 0.8em,
        fill: orange.lighten(70%),
      ),
      edge((0, 0), (1, 0), $1$, "-", label-side: left),
      edge((0, 0), (0.5, 1), $1$, "-", label-side: right, label-sep: 2pt),
      edge((1, 0), (0.5, 1), $1$, "-", label-side: left, label-sep: 2pt),
    ),
  )
]

---

#definition(title: "Coherence Deadline")[
  For each logical qubit $i in V_l$ mapped to physical qubit $pi(i)$:
  $
    "depth"(i) dot t_("cx") + "swaps"(i, pi) dot t_("swap") lt.eq T_("coh")(pi(i))
  $
  where
  $"swaps"(i, pi) = sum_(j:(i,j) in E_l) w(i,j) dot max(0, d(pi(i), pi(j)) - 1)$.
]

Qubits *decohere* over time, losing quantum information. If a circuit exceeds
the coherence time, the computation becomes meaningless.


= Related Problems

== Relation to Existing Problems

The Qubit Mapping Problem connects to several well-studied graph-theoretic
problems:

#pause

#theorem(title: "NP-Hardness")[
  The Qubit Mapping Problem is NP-hard. The initial placement subproblem reduces
  to Subgraph Isomorphism (NP-complete), and the full routing problem is NP-hard
  via reduction from Token Swapping on graphs.
]

#pause

#v(0.5em)
#align(center)[
  #grid(
    columns: (1fr, 1fr),
    align: center + horizon,
    // Subgraph Isomorphism example
    [
      #fletcher.diagram(
        spacing: (1.5em, 1.5em),
        node-stroke: 0.5pt,
        // Small graph G_l (triangle)
        node((0, 0), shape: circle, radius: 0.3em, stroke: 1.2pt),
        node((1, 0), [], shape: circle, radius: 0.3em, stroke: 1.2pt),
        node((0.5, 0.8), [], shape: circle, radius: 0.3em, stroke: 1.2pt),
        edge((0, 0), (1, 0), "-"),
        edge((0, 0), (0.5, 0.8), "-"),
        edge((1, 0), (0.5, 0.8), "-"),
        // Subset symbol
        node((1.7, 0.4), $subset.eq$, stroke: none),
        // Larger graph G_p (highlighted triangle = matched subgraph)
        node(
          (2.4, 0),
          shape: circle,
          radius: 0.3em,
          fill: orange.lighten(70%),
          stroke: orange + 1.2pt,
        ),
        node(
          (3.4, 0),
          [],
          shape: circle,
          radius: 0.3em,
          fill: orange.lighten(70%),
          stroke: orange + 1.2pt,
        ),
        node(
          (2.9, 0.8),
          [],
          shape: circle,
          radius: 0.3em,
          fill: orange.lighten(70%),
          stroke: orange + 1.2pt,
        ),
        node(
          (3.9, 0.8),
          [],
          shape: circle,
          radius: 0.3em,
          fill: blue.lighten(80%),
          stroke: blue + 1.2pt,
        ),
        edge((2.4, 0), (3.4, 0), "-", stroke: orange + 1.2pt),
        edge((2.4, 0), (2.9, 0.8), "-", stroke: orange + 1.2pt),
        edge((3.4, 0), (2.9, 0.8), "-", stroke: orange + 1.2pt),
        edge((3.4, 0), (3.9, 0.8), "-", stroke: blue + 1.2pt),
        edge((2.9, 0.8), (3.9, 0.8), "-", stroke: blue + 1.2pt),
      )
    ],
    // Token Swapping example
    [
      #fletcher.diagram(
        spacing: (1.2em, 1.5em),
        node-stroke: 0.5pt,
        // Before
        node(
          (0, 0),
          shape: circle,
          radius: 0.3em,
          fill: red.lighten(70%),
          stroke: red + 1.2pt,
        ),
        node(
          (1, 0),
          shape: circle,
          radius: 0.3em,
          fill: green.lighten(70%),
          stroke: green + 1.2pt,
        ),
        node(
          (2, 0),
          shape: circle,
          radius: 0.3em,
          fill: yellow.lighten(60%),
          stroke: yellow.darken(25%) + 1.2pt,
        ),
        edge(
          (0, 0),
          (1, 0),
          "-",
          stroke: gradient.linear(red, green) + 5pt,
        ),
        edge((1, 0), (2, 0), "-", stroke: black + 1.5pt),
        // Arrow
        node((3, 0), $arrow.r$, stroke: none),
        // After
        node(
          (4, 0),
          shape: circle,
          radius: 0.3em,
          fill: green.lighten(70%),
          stroke: green + 1.2pt,
        ),
        node(
          (5, 0),
          shape: circle,
          radius: 0.3em,
          fill: red.lighten(70%),
          stroke: red + 1.2pt,
        ),
        node(
          (6, 0),
          shape: circle,
          radius: 0.3em,
          fill: yellow.lighten(60%),
          stroke: yellow.darken(25%) + 1.2pt,
        ),
        edge((4, 0), (5, 0), "-", stroke: gradient.linear(green, red) + 5pt),
        edge((5, 0), (6, 0), "-", stroke: black + 1.5pt),
      )
    ],
  )
]

---

*Related problems:*

- *Subgraph Isomorphism* #sym.dash.em finding $G_l$ as a subgraph of $G_p$
- *Token Swapping* #sym.dash.em minimum swaps to reach a target permutation on a
  graph
- *QAP* #sym.dash.em minimising pairwise distance-weighted cost over assignments

#pause

*Our novelty:* Adding *noise-aware cost* and *coherence time deadlines*
transforms this from a pure graph embedding problem into a constrained
multi-objective optimisation problem reflecting NISQ device limitations.


= Objective Function

== Objective Formulation

The objective minimises a weighted combination of routing cost and noise cost:

$
  f(pi) = alpha dot C_"route" (pi) + beta dot C_"noise" (pi)
$

#pause

- *Routing cost* #sym.dash.em total SWAP overhead:
$
  C_"route" (pi) = sum_((i,j) in E_l) w(i,j) dot max(0, d_(G_p)(pi(i), pi(j)) - 1)
$

---

- *Noise cost* #sym.dash.em accumulated gate infidelity from both single and
  two-qubit errors:
$
  C_"noise" (pi) &= underbrace(
    sum_((i,j) in E_l) w(i,j) dot
    (1 - product_(e in "path"(pi(i), pi(j))) (1 - epsilon_2(e))),
    "two-qubit routing errors"
  ) \
  &+ underbrace(sum_(i in V_l) "depth"(i) dot epsilon_1(pi(i)), "single-qubit gate errors")
$

#pause

Infeasible mappings (violating coherence deadlines) receive a large additive
penalty proportional to the violation magnitude.

== Worked Example

#slide(composer: (1fr, 1fr))[
  *Interaction Graph* ($|V_l| = 3$):

  #align(center, fletcher.diagram(
    spacing: 3em,
    node-stroke: 0.6pt,
    node((0, 0), $q_0$, shape: circle, radius: 1em, fill: orange.lighten(70%)),
    node((1, 0), $q_1$, shape: circle, radius: 1em, fill: orange.lighten(70%)),
    node(
      (0.5, 1),
      $q_2$,
      shape: circle,
      radius: 1em,
      fill: orange.lighten(70%),
    ),
    edge((0, 0), (1, 0), $3$, "-", label-side: left),
    edge((0, 0), (0.5, 1), $1$, "-", label-side: right, label-sep: 3pt),
    edge((1, 0), (0.5, 1), $2$, "-", label-side: left, label-sep: 3pt),
  ))
][
  *Coupling Graph* ($|V_p| = 5$):

  #align(center, fletcher.diagram(
    spacing: 3em,
    node-stroke: 0.6pt,
    node((0, 0), $Q_0$, shape: circle, radius: 1em, fill: blue.lighten(80%)),
    node((1, 0), $Q_1$, shape: circle, radius: 1em, fill: blue.lighten(80%)),
    node((2, 0), $Q_2$, shape: circle, radius: 1em, fill: blue.lighten(80%)),
    node((0.5, 1), $Q_3$, shape: circle, radius: 1em, fill: blue.lighten(80%)),
    node((1.5, 1), $Q_4$, shape: circle, radius: 1em, fill: blue.lighten(80%)),
    edge((0, 0), (1, 0), "-"),
    edge((1, 0), (2, 0), "-"),
    edge((0, 0), (0.5, 1), "-"),
    edge((1, 0), (0.5, 1), "-"),
    edge((1, 0), (1.5, 1), "-"),
    edge((0.5, 1), (1.5, 1), "-"),
  ))
]

Mapping $pi = {q_0 arrow.r Q_0, q_1 arrow.r Q_1, q_2 arrow.r Q_3}$:
- $C_"route" = 0$ (all pairs adjacent, $d = 1$)

- $C_"noise" &= underbrace(3 epsilon_2(Q_0 Q_1) + 1 epsilon_2(Q_0 Q_3) + 2 epsilon_2(Q_1 Q_3), epsilon_2) \
  &+ underbrace(sum_i "depth"(q_i) dot epsilon_1(pi(q_i)), epsilon_1)$

#pause

Mapping $pi' = {q_0 arrow.r Q_0, q_1 arrow.r Q_2, q_2 arrow.r Q_4}$ (all pairs
$d = 2$):
- $C_"route" = 3 times 1 + 1 times 1 + 2 times 1 = 6$
- $C_"noise"$ also increases: each routing path traverses an extra edge,
  accumulating more $epsilon_2$ errors


= Solution Representation

== Individual Encoding

#definition(title: "Solution Representation")[
  A solution (individual) is an *injective mapping* $pi: V_l arrow.r V_p$
  encoded as a list where $pi[i]$ is the physical qubit assigned to logical
  qubit $i$.
]

#pause

*Example:* With 3 logical qubits and 5 physical qubits:

#align(center)[
  #table(
    columns: 4,
    inset: 9pt,
    align: center,
    table.header([*Index*], [$i = 0$], [$i = 1$], [$i = 2$]),
    [$pi[i]$], [$Q_3$], [$Q_0$], [$Q_4$],
  )
]

---

- *Constraint:* The mapping must be *injective* #sym.dash.em no two logical
  qubits share the same physical qubit. This is naturally preserved by the
  neighbourhood operators.

#pause

- *Search space size:* $binom(n, m) dot m!$ where $n = |V_p|, m = |V_l|$. For
  $n = 30, m = 10$: $approx 5.6 times 10^(13)$ possible mappings #sym.dash.em
  brute force is infeasible.


= Fitness and Algorithm

== Fitness Evaluation

The fitness function $f(pi)$ is evaluated as:

#align(center)[
  #table(
    columns: 2,
    inset: 8pt,
    align: (left, left),
    table.header([*Step*], [*Description*]),
    [1. Precompute],
    [Floyd-Warshall: all-pairs shortest paths $d(u,v)$ on $G_p$. \ Path error:
      $"err"(u,v) = 1 - product_e (1 - epsilon_2(e))$ for all pairs.],

    [2. Evaluate],
    [Sum routing cost ($C_"route"$) and noise cost ($C_"noise"$, including
      $epsilon_1$ and $epsilon_2$) over the mapping.],

    [3. Penalise],
    [Add $100 dot max(0, t_"total" - T_"coh")$ for each violation.],
  )
]

*Precomputation* is $O(|V_p|^3)$ (once), each *evaluation* is $O(|E_l|)$.
Incremental evaluation after a swap: $O("deg"(i) + "deg"(j))$.


== Simulated Annealing

*Simulated Annealing* is the classical analogue of _Quantum Annealing_. The
Metropolis acceptance criterion mirrors quantum tunnelling through energy
barriers.

#pause

*Neighbourhood operators:*

- *Swap* (60%): Exchange physical qubits of two logical qubits
- *Relocate* (40%): Move one logical qubit to an unoccupied physical qubit

Both preserve injectivity of the mapping.

---

=== Cooling and Acceptance

*Cooling schedule:*
$
  T_(k+1) = gamma dot T_k, quad gamma = 0.9995, quad T_0 = 50, quad T_min = 0.01
$

*Acceptance criterion:*
$
  P("accept") = cases(
    1 & "if" Delta f < 0,
    exp(-Delta f \/ T) & "otherwise"
  )
$

Run with *5 restarts* from different random seeds, returning the best solution
found.


= Solution Decoding

== From Mapping to Compiled Circuit

Given the optimal mapping $pi^*$, the solution is decoded back to a real-world
quantum circuit:

+ *Assign* each logical qubit $q_i$ to physical qubit $Q_(pi^*(i))$

+ *Route* each two-qubit gate: if $d(pi^*(i), pi^*(j)) > 1$, insert SWAP gates
  along the shortest path to bring the qubits adjacent

+ *Verify* that the total circuit depth respects coherence time limits

---

*Quality metrics of the compiled circuit:*

#table(
  columns: 2,
  inset: 8pt,
  align: (left, left),
  table.header([*Metric*], [*Meaning*]),
  [Total SWAPs], [Number of inserted SWAP operations (each = 3 CNOTs)],
  [Circuit fidelity],
  [$product (1 - epsilon)$ over all gates --- probability of correct execution],

  [Feasibility], [Whether all qubits finish before their coherence deadline],
)


#focus-slide([Thank you! \ #text(0.67em, [Any questions?])])
