import Foundation
import UIKit

/// OCR 识别服务
/// 使用 Apple Vision 框架识别图片中的文字
/// 自动提取知识点并生成结构化数据
final class OCRService {
    // MARK: - 文字识别
    /// 识别图片中的文字
    /// - Parameter image: 输入图片
    /// - Returns: 识别出的文字内容
    func recognizeText(from image: UIImage) async throws -> String {
        // TODO: 集成 Vision 框架
        // 1. 创建 VNImageRequestHandler
        // 2. 使用 VNRecognizeTextRequest 识别文字
        // 3. 支持中英文混合识别
        // 4. 返回识别结果
        return ""
    }

    // MARK: - 知识点提取
    /// 从识别文字中自动提取知识点
    /// - Parameter text: OCR 识别文字
    /// - Returns: 提取的知识点列表
    func extractKnowledgeNodes(from text: String) async throws -> [KnowledgeNodeCandidate] {
        // TODO: 集成 Natural Language 框架
        // 1. 使用 NLTokenizer 分词
        // 2. 使用 NLTagger 进行词性标注和命名实体识别
        // 3. 提取关键概念作为知识点候选
        return []
    }

    /// 知识点候选 (处理中状态)
    struct KnowledgeNodeCandidate {
        let title: String
        let content: String
        let suggestedTags: [String]
        let confidence: Double
    }

    // MARK: - 支持的输入类型
    enum InputType {
        case textbook   // 教材
        case ppt        // PPT
        case blackboard // 板书
        case exam       // 试题
        case note       // 手写笔记
    }
}
