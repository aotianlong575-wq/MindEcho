import Foundation

/// 知识图谱引擎
/// 管理知识节点之间的关联关系，提供图分析功能
final class KnowledgeGraphEngine {
    private var nodes: [UUID: KnowledgeNode] = [:]
    private var adjacencyList: [UUID: Set<UUID>] = [:]

    // MARK: - 图谱构建
    func addNode(_ node: KnowledgeNode) {
        nodes[node.id] = node
        if adjacencyList[node.id] == nil {
            adjacencyList[node.id] = []
        }
    }

    func addEdge(from sourceId: UUID, to targetId: UUID) {
        adjacencyList[sourceId, default: []].insert(targetId)
        adjacencyList[targetId, default: []].insert(sourceId)
    }

    // MARK: - 路径搜索
    /// BFS 最短路径搜索
    func findShortestPath(from sourceId: UUID, to targetId: UUID) -> [UUID]? {
        guard nodes[sourceId] != nil, nodes[targetId] != nil else { return nil }

        var visited: Set<UUID> = [sourceId]
        var queue: [(UUID, [UUID])] = [(sourceId, [sourceId])]

        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()

            if current == targetId {
                return path
            }

            for neighbor in adjacencyList[current, default: []] where !visited.contains(neighbor) {
                visited.insert(neighbor)
                queue.append((neighbor, path + [neighbor]))
            }
        }

        return nil
    }

    // MARK: - 聚类分析
    /// 基于标签和关系的简单聚类
    func clusterNodes() -> [[KnowledgeNode]] {
        var visited: Set<UUID> = []
        var clusters: [[KnowledgeNode]] = []

        for nodeId in nodes.keys where !visited.contains(nodeId) {
            var cluster: [KnowledgeNode] = []
            var stack: [UUID] = [nodeId]

            while !stack.isEmpty {
                let current = stack.removeLast()
                guard !visited.contains(current), let node = nodes[current] else { continue }
                visited.insert(current)
                cluster.append(node)
                stack.append(contentsOf: adjacencyList[current, default: []])
            }

            if !cluster.isEmpty {
                clusters.append(cluster)
            }
        }

        return clusters
    }

    // MARK: - 关联推荐
    /// 基于共同标签和内容相似度推荐关联知识点
    func suggestConnections(for nodeId: UUID, topK: Int = 5) -> [UUID] {
        guard let sourceNode = nodes[nodeId] else { return [] }

        var scores: [(UUID, Double)] = []

        for (otherId, otherNode) in nodes where otherId != nodeId {
            let tagOverlap = Set(sourceNode.tags).intersection(Set(otherNode.tags))
            let tagScore = Double(tagOverlap.count) / Double(max(sourceNode.tags.count, 1))

            let categoryBonus = sourceNode.category == otherNode.category ? 0.3 : 0.0
            let totalScore = tagScore * 0.7 + categoryBonus

            if totalScore > 0 {
                scores.append((otherId, totalScore))
            }
        }

        return scores
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { $0.0 }
    }
}
