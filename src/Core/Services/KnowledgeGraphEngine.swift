import Foundation

/// 知识图谱引擎
/// 管理知识节点的关联关系，提供图分析、路径搜索、聚类、推荐等功能
public final class KnowledgeGraphEngine {
    // MARK: - 存储
    private var nodes: [UUID: KnowledgeNode] = [:]
    /// 邻接表（无向图）
    private var adjacencyList: [UUID: Set<UUID>] = [:]
    /// 边权重（用于 Dijkstra 和 PageRank）
    private var edgeWeights: [EdgeKey: Double] = [:]

    public struct EdgeKey: Hashable {
        let from: UUID
        let to: UUID
    }

    // MARK: - 初始化
    public init() {}

    /// 从节点列表批量加载图
    public func load(nodes: [KnowledgeNode]) {
        for node in nodes { addNode(node) }
        for node in nodes {
            for rel in node.relatedNodes {
                addEdge(from: node.id, to: rel.nodeId, weight: rel.strength)
            }
        }
    }

    // MARK: - 基本操作
    public func addNode(_ node: KnowledgeNode) {
        nodes[node.id] = node
        if adjacencyList[node.id] == nil { adjacencyList[node.id] = [] }
    }

    public func removeNode(_ id: UUID) {
        nodes.removeValue(forKey: id)
        adjacencyList.removeValue(forKey: id)
        for source in adjacencyList.keys { adjacencyList[source]?.remove(id) }
        edgeWeights = edgeWeights.filter { $0.key.from != id && $0.key.to != id }
    }

    public func addEdge(from source: UUID, to target: UUID, weight: Double = 1.0) {
        adjacencyList[source, default: []].insert(target)
        adjacencyList[target, default: []].insert(source)
        edgeWeights[EdgeKey(from: source, to: target)] = weight
        edgeWeights[EdgeKey(from: target, to: source)] = weight
    }

    public var nodeCount: Int { nodes.count }
    public var edgeCount: Int { edgeWeights.count / 2 }
    public func getNode(_ id: UUID) -> KnowledgeNode? { nodes[id] }
    public func getAllNodes() -> [KnowledgeNode] { Array(nodes.values) }

    // MARK: - 路径搜索
    /// BFS 最短路径
    public func findShortestPath(from sourceId: UUID, to targetId: UUID) -> [UUID]? {
        guard nodes[sourceId] != nil, nodes[targetId] != nil else { return nil }
        if sourceId == targetId { return [sourceId] }

        var visited: Set<UUID> = [sourceId]
        var queue: [(UUID, [UUID])] = [(sourceId, [sourceId])]

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            for neighbor in adjacencyList[current, default: []] where !visited.contains(neighbor) {
                let newPath = path + [neighbor]
                if neighbor == targetId { return newPath }
                visited.insert(neighbor)
                queue.append((neighbor, newPath))
            }
        }
        return nil
    }

    /// Dijkstra 加权最短路径
    public func findWeightedShortestPath(from sourceId: UUID, to targetId: UUID) -> [UUID]? {
        guard nodes[sourceId] != nil, nodes[targetId] != nil else { return nil }
        if sourceId == targetId { return [sourceId] }

        var distances: [UUID: Double] = [sourceId: 0]
        var previous: [UUID: UUID] = [:]
        var unvisited = Set(nodes.keys)

        while !unvisited.isEmpty {
            guard let current = unvisited.min(by: {
                distances[$0, default: .infinity] < distances[$1, default: .infinity]
            }) else { break }

            if current == targetId { break }
            unvisited.remove(current)

            for neighbor in adjacencyList[current, default: []] where unvisited.contains(neighbor) {
                let edgeKey = EdgeKey(from: current, to: neighbor)
                // 关系越强距离越短
                let weight = 2.0 - (edgeWeights[edgeKey] ?? 0.5)
                let alt = distances[current, default: .infinity] + max(weight, 0.1)
                if alt < distances[neighbor, default: .infinity] {
                    distances[neighbor] = alt
                    previous[neighbor] = current
                }
            }
        }

        // 回溯路径
        var current = targetId
        var path: [UUID] = [current]
        while let prev = previous[current] {
            path.insert(prev, at: 0)
            current = prev
            if current == sourceId { return path }
        }
        return path.count > 1 ? path : nil
    }

    // MARK: - 连通分量（聚类）
    public func connectedComponents() -> [[KnowledgeNode]] {
        var visited: Set<UUID> = []
        var components: [[KnowledgeNode]] = []

        for nodeId in nodes.keys where !visited.contains(nodeId) {
            var component: [KnowledgeNode] = []
            var stack: [UUID] = [nodeId]

            while !stack.isEmpty {
                let current = stack.removeLast()
                guard !visited.contains(current), let node = nodes[current] else { continue }
                visited.insert(current)
                component.append(node)
                for neighbor in adjacencyList[current, default: []] where !visited.contains(neighbor) {
                    stack.append(neighbor)
                }
            }
            if !component.isEmpty { components.append(component) }
        }
        return components
    }

    /// 基于标签相似度的社区聚类
    public func labelBasedClusters() -> [[KnowledgeNode]] {
        let allNodes = Array(nodes.values)
        var clusters: [String: [KnowledgeNode]] = [:]

        for node in allNodes {
            let key = node.tags.first ?? node.category.rawValue
            clusters[key, default: []].append(node)
        }

        var result: [[KnowledgeNode]] = []
        var orphans: [KnowledgeNode] = []
        let minSize = 3

        for (_, members) in clusters {
            if members.count >= minSize { result.append(members) }
            else { orphans.append(contentsOf: members) }
        }

        for orphan in orphans {
            var bestIdx = -1
            var bestScore = 0.0
            for (i, cluster) in result.enumerated() {
                let s = tagOverlap(orphan, cluster)
                if s > bestScore { bestScore = s; bestIdx = i }
            }
            if bestIdx >= 0 { result[bestIdx].append(orphan) }
            else { result.append([orphan]) }
        }
        return result
    }

    private func tagOverlap(_ node: KnowledgeNode, _ cluster: [KnowledgeNode]) -> Double {
        let nt = Set(node.tags)
        let ct = Set(cluster.flatMap { $0.tags })
        guard !ct.isEmpty else { return 0 }
        return Double(nt.intersection(ct).count) / Double(ct.count)
    }

    // MARK: - PageRank
    public func pageRank(dampingFactor: Double = 0.85, iterations: Int = 50) -> [UUID: Double] {
        let allIds = Array(nodes.keys)
        let n = Double(allIds.count)
        guard n > 1 else { return allIds.isEmpty ? [:] : [allIds[0]: 1.0] }

        var ranks: [UUID: Double] = [:]
        for id in allIds { ranks[id] = 1.0 / n }

        for _ in 0..<iterations {
            var newRanks: [UUID: Double] = [:]
            for id in allIds {
                let inbound = allIds
                    .filter { adjacencyList[$0]?.contains(id) ?? false }
                    .reduce(0.0) { acc, srcId in
                        let outDeg = max(adjacencyList[srcId]?.count ?? 1, 1)
                        return acc + (ranks[srcId, default: 0] / Double(outDeg))
                    }
                newRanks[id] = (1.0 - dampingFactor) / n + dampingFactor * inbound
            }
            ranks = newRanks
        }
        return ranks
    }

    // MARK: - 中心性
    public func degreeCentrality() -> [UUID: Double] {
        let maxDeg = Double(adjacencyList.values.map { $0.count }.max() ?? 1)
        guard maxDeg > 0 else { return [:] }
        return adjacencyList.mapValues { Double($0.count) / maxDeg }
    }

    public func betweennessCentrality() -> [UUID: Double] {
        var bc: [UUID: Double] = [:]
        for id in nodes.keys { bc[id] = 0 }
        let allIds = Array(nodes.keys)
        let samples = allIds.count > 50 ? Array(allIds.shuffled().prefix(30)) : allIds

        for source in samples {
            var stack: [UUID] = []
            var pred: [UUID: [UUID]] = [:]
            var sigma: [UUID: Double] = [source: 1]
            var dist: [UUID: Int] = [source: 0]
            var queue: [UUID] = [source]

            while !queue.isEmpty {
                let v = queue.removeFirst()
                stack.append(v)
                for w in adjacencyList[v, default: []] {
                    if dist[w] == nil { dist[w] = dist[v]! + 1; queue.append(w) }
                    if dist[w] == dist[v]! + 1 {
                        sigma[w, default: 0] += sigma[v, default: 0]
                        pred[w, default: []].append(v)
                    }
                }
            }

            var delta: [UUID: Double] = [:]
            for v in stack.reversed() {
                for p in pred[v, default: []] {
                    delta[p, default: 0] += (sigma[p, default: 0] / sigma[v, default: 1]) * (1.0 + delta[v, default: 0])
                }
                if v != source { bc[v, default: 0] += delta[v, default: 0] }
            }
        }
        return bc
    }

    // MARK: - 关联推荐
    public func suggestConnections(for nodeId: UUID, topK: Int = 5) -> [UUID] {
        guard let src = nodes[nodeId] else { return [] }
        let srcTags = Set(src.tags)

        var scores: [(UUID, Double)] = []
        for (otherId, other) in nodes where otherId != nodeId {
            if adjacencyList[nodeId]?.contains(otherId) == true { continue }

            let ot = Set(other.tags)
            let union = srcTags.union(ot)
            let tagSim = union.isEmpty ? 0 : Double(srcTags.intersection(ot).count) / Double(union.count)
            let catBonus = src.category == other.category ? 0.3 : 0.0
            let contentSim = wordOverlap(src.content, other.content)
            let score = tagSim * 0.4 + catBonus * 0.2 + contentSim * 0.4

            if score > 0.05 { scores.append((otherId, score)) }
        }
        return scores.sorted { $0.1 > $1.1 }.prefix(topK).map { $0.0 }
    }

    private func wordOverlap(_ t1: String, _ t2: String) -> Double {
        let w1 = Set(t1.lowercased().split(separator: " ").filter { $0.count > 1 })
        let w2 = Set(t2.lowercased().split(separator: " ").filter { $0.count > 1 })
        guard !w1.isEmpty, !w2.isEmpty else { return 0 }
        return Double(w1.intersection(w2).count) / Double(w1.union(w2).count)
    }

    // MARK: - 知识树
    public func buildKnowledgeTree(from rootIds: [UUID]? = nil) -> [KnowledgeTreeNode] {
        (rootIds ?? findRootNodes()).compactMap {
            buildTreeRecursive(nodeId: $0, depth: 0, visited: [])
        }
    }

    private func buildTreeRecursive(nodeId: UUID, depth: Int, visited: Set<UUID>) -> KnowledgeTreeNode? {
        guard let node = nodes[nodeId], !visited.contains(nodeId) else { return nil }
        var v = visited; v.insert(nodeId)
        let children = adjacencyList[nodeId, default: []]
            .filter { !visited.contains($0) }
            .compactMap { buildTreeRecursive(nodeId: $0, depth: depth + 1, visited: v) }
        return KnowledgeTreeNode(id: UUID(), node: node, children: children, depth: depth, weight: 1.0 / Double(depth + 1))
    }

    public func findRootNodes() -> [UUID] {
        var indeg: [UUID: Int] = [:]
        for id in nodes.keys { indeg[id] = 0 }
        for (_, neighbors) in adjacencyList {
            for nb in neighbors { indeg[nb, default: 0] += 1 }
        }
        return indeg.filter { $0.value == 0 }.map { $0.key }
    }
}
