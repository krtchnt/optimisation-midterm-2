from __future__ import annotations

from collections import deque


class Graph:
    """Weighted undirected graph with vertex and edge attributes."""

    def __init__(self, n: int) -> None:
        self.n = n
        self.adj: dict[int, dict[int, float]] = {i: {} for i in range(n)}
        self.vertex_attrs: dict[int, dict[str, float]] = {i: {} for i in range(n)}
        self.edge_attrs: dict[tuple[int, int], dict[str, float]] = {}

    def add_edge(self, u: int, v: int, weight: float = 1.0, **attrs: float) -> None:
        self.adj[u][v] = weight
        self.adj[v][u] = weight
        key = (min(u, v), max(u, v))
        self.edge_attrs[key] = attrs

    def neighbors(self, u: int) -> list[int]:
        return list(self.adj[u])

    def degree(self, u: int) -> int:
        return len(self.adj[u])

    def edges(self) -> list[tuple[int, int]]:
        seen: set[tuple[int, int]] = set()
        result: list[tuple[int, int]] = []
        for u in self.adj:
            for v in self.adj[u]:
                key = (min(u, v), max(u, v))
                if key not in seen:
                    seen.add(key)
                    result.append(key)
        return result

    def get_edge_attr(self, u: int, v: int, attr: str) -> float:
        key = (min(u, v), max(u, v))
        return self.edge_attrs.get(key, {}).get(attr, 0.0)

    def floyd_warshall(self) -> list[list[float]]:
        """Compute all-pairs shortest path distances."""
        INF = float("inf")
        dist = [[INF] * self.n for _ in range(self.n)]
        for v in range(self.n):
            dist[v][v] = 0
        for u in self.adj:
            for v, w in self.adj[u].items():
                dist[u][v] = w
        for k in range(self.n):
            dk = dist[k]
            for i in range(self.n):
                dik = dist[i][k]
                if dik == INF:
                    continue
                di = dist[i]
                for j in range(self.n):
                    d = dik + dk[j]
                    if d < di[j]:
                        di[j] = d
        return dist

    def bfs_path(self, src: int, dst: int) -> list[int]:
        """Find shortest unweighted path from src to dst via BFS."""
        if src == dst:
            return [src]
        visited = [False] * self.n
        prev = [-1] * self.n
        visited[src] = True
        queue: deque[int] = deque([src])
        while queue:
            u = queue.popleft()
            for v in self.adj[u]:
                if not visited[v]:
                    visited[v] = True
                    prev[v] = u
                    if v == dst:
                        path = []
                        cur = dst
                        while cur != -1:
                            path.append(cur)
                            cur = prev[cur]
                        path.reverse()
                        return path
                    queue.append(v)
        return []

    def path_error(self, src: int, dst: int) -> float:
        """Compute accumulated two-qubit gate error along shortest path.

        Returns the probability of error: 1 - product of (1 - e2) along path.
        """
        path = self.bfs_path(src, dst)
        if len(path) <= 1:
            return 0.0
        fidelity = 1.0
        for i in range(len(path) - 1):
            e2 = self.get_edge_attr(path[i], path[i + 1], "error")
            fidelity *= 1.0 - e2
        return 1.0 - fidelity

    def all_pairs_path_error(self) -> list[list[float]]:
        """Precompute path error for all pairs of vertices."""
        err = [[0.0] * self.n for _ in range(self.n)]
        for i in range(self.n):
            for j in range(i + 1, self.n):
                e = self.path_error(i, j)
                err[i][j] = e
                err[j][i] = e
        return err
