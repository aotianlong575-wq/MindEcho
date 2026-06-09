import Foundation

// 平台适配图片类型
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#else
/// 非 Apple 平台使用 Data 作为图片占位
public struct PlatformImage {
    public let data: Data
    public init(data: Data) { self.data = data }
}
#endif

/// OCR 识别服务
/// 封装 Vision 框架进行文字识别
/// 使用 Natural Language 框架提取关键词和知识点
public final class OCRService {

    public init() {}

    // MARK: - 文字识别
    /// 识别图片中的文字
    /// - Parameter image: 输入图片（跨平台兼容）
    /// - Returns: 识别出的文字内容
    public func recognizeText(from image: PlatformImage) async throws -> String {
        #if canImport(Vision)
        // Vision 框架实际调用（在 iOS/macOS 设备上）
        return try await recognizeWithVision(image)
        #else
        // 非 Apple 平台：返回模拟结果用于测试
        return try await mockRecognize()
        #endif
    }

    #if canImport(Vision)
    private func recognizeWithVision(_ image: PlatformImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            #if canImport(UIKit)
            guard let cgImage = (image as PlatformImage).cgImage else {
                continuation.resume(throwing: OCRServiceError.imageConversionFailed)
                return
            }
            #elseif canImport(AppKit)
            guard let cgImage = (image as PlatformImage).cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continuation.resume(throwing: OCRServiceError.imageConversionFailed)
                return
            }
            #else
            continuation.resume(throwing: OCRServiceError.unsupportedPlatform)
            return
            #endif

            // Vision 框架识别
            let request = createTextRecognitionRequest()
            // Note: VNImageRequestHandler 在实际 iOS/macOS 上调用
            // 此处简化：直接返回占位文本（集成时替换为实际 Vision 调用）
            continuation.resume(returning: "Placeholder: Vision OCR result")
        }
    }
    #endif

    private func mockRecognize() async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        return """
        人工智能是计算机科学的一个分支，它企图了解智能的实质，
        并生产出一种新的能以人类智能相似的方式做出反应的智能机器。
        该领域的研究包括机器学习、自然语言处理和计算机视觉等。
        """
    }

    #if canImport(Vision)
    private func createTextRecognitionRequest() /* -> VNRecognizeTextRequest */ -> Any? {
        // 实际实现:
        // let request = VNRecognizeTextRequest()
        // request.recognitionLevel = .accurate
        // request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        // request.usesLanguageCorrection = true
        // return request
        return nil
    }
    #endif

    // MARK: - 知识点提取
    /// 从文本中自动提取知识点
    /// - Parameter text: 输入文本
    /// - Returns: 提取的知识点候选列表
    public func extractKnowledgeNodes(from text: String) async throws -> [KnowledgeCandidate] {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        // 分句
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".。!！?？\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 10 }

        var candidates: [KnowledgeCandidate] = []

        for sentence in sentences {
            // 提取关键词
            let keywords = extractKeywords(from: sentence)
            // 判断知识类型
            let category = classifyCategory(for: sentence)
            // 判断难度
            let difficulty = estimateDifficulty(for: sentence)

            let title = keywords.first ?? String(sentence.prefix(30))
            candidates.append(KnowledgeCandidate(
                title: title,
                content: sentence,
                suggestedTags: keywords,
                category: category,
                difficulty: difficulty,
                confidence: min(0.5 + Double(keywords.count) * 0.1, 0.95)
            ))
        }

        return candidates
    }

    /// 从文本中提取关键词
    public func extractKeywords(from text: String) -> [String] {
        // 中文关键词提取（基于词频和位置）
        // 简单实现：提取双字和三字组合，过滤停用词

        let stopWords: Set<String> = ["的", "是", "了", "在", "和", "也", "就", "都", "而", "及",
                                       "与", "着", "或", "一个", "没有", "我们", "你们", "他们",
                                       "这个", "那个", "什么", "自己", "可以", "因为", "所以",
                                       "但是", "如果", "虽然", "而且", "之后", "然后", "the",
                                       "is", "a", "an", "in", "on", "at", "to", "for", "of"]

        let chars = Array(text)
        var keywords: [String: Int] = [:]

        // 双字组合
        for i in 0..<(chars.count - 1) {
            let word = String(chars[i...i+1])
            if !stopWords.contains(word) && word.rangeOfCharacter(from: .letters) != nil {
                keywords[word, default: 0] += 1
            }
        }

        // 加权：开头位置的关键词权重更高
        for i in 0..<min(chars.count - 2, 20) {
            let word = String(chars[i...i+1])
            if keywords[word] != nil { keywords[word, default: 0] += 2 }
        }

        // 按权重排序返回前 5
        return keywords.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }

    /// 判断文本属于哪种知识类型
    public func classifyCategory(for text: String) -> KnowledgeCategory {
        let lowerText = text.lowercased()

        if lowerText.contains("步骤") || lowerText.contains("方法") || lowerText.contains("流程") ||
           lowerText.contains("操作") || lowerText.contains("how to") || lowerText.contains("process") {
            return .procedure
        }
        if lowerText.contains("定义") || lowerText.contains("是指") || lowerText.contains("指的是") ||
           lowerText.contains("概念") || lowerText.contains("definition") || lowerText.contains("refers") {
            return .concept
        }
        if lowerText.contains("原理") || lowerText.contains("因为") || lowerText.contains("规律") ||
           lowerText.contains("定律") || lowerText.contains("principle") || lowerText.contains("because") {
            return .principle
        }
        if lowerText.contains("年") || lowerText.contains("事件") || lowerText.contains("事实") ||
           lowerText.contains("记录") || lowerText.contains("fact") {
            return .fact
        }
        if lowerText.contains("技巧") || lowerText.contains("能力") || lowerText.contains("熟练") ||
           lowerText.contains("技能") || lowerText.contains("skill") || lowerText.contains("technique") {
            return .skill
        }
        return .concept
    }

    /// 根据文本特征估计知识难度
    public func estimateDifficulty(for text: String) -> DifficultyLevel {
        let wordCount = text.count
        let techTerms = countTechnicalTerms(in: text)
        let complexity = Double(techTerms) / Double(max(wordCount, 1))

        switch complexity {
        case ..<0.02: return .beginner
        case ..<0.05: return .elementary
        case ..<0.08: return .intermediate
        case ..<0.12: return .advanced
        default: return .expert
        }
    }

    private func countTechnicalTerms(in text: String) -> Int {
        let techPatterns = [
            "算法", "模型", "架构", "框架", "协议", "接口",
            "神经网络", "深度学习", "数据结构", "编译",
            "向量", "矩阵", "函数", "变量", "参数", "递归",
            "并发", "异步", "缓存", "索引", "加密", "签名",
            "algorithm", "model", "architecture", "framework",
            "protocol", "interface", "neural", "deep learning",
            "vector", "matrix", "function", "variable", "recursion"
        ]
        let lowerText = text.lowercased()
        return techPatterns.reduce(0) { count, term in
            count + (lowerText.contains(term.lowercased()) ? 1 : 0)
        }
    }

    // MARK: - 类型
    /// 知识点提取候选
    public struct KnowledgeCandidate {
        public let title: String
        public let content: String
        public let suggestedTags: [String]
        public let category: KnowledgeCategory
        public let difficulty: DifficultyLevel
        public let confidence: Double
    }

    public enum InputType: String, CaseIterable {
        case textbook = "教材"
        case ppt = "PPT"
        case blackboard = "板书"
        case exam = "试题"
        case note = "手写笔记"
    }
}

// MARK: - 错误
public enum OCRServiceError: Error {
    case imageConversionFailed
    case recognitionFailed
    case unsupportedPlatform
    case noTextFound
}
