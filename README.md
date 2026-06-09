# MindEcho（记忆回声）

> 基于空间计算与认知科学的个人数字记忆增强平台

## 项目简介

MindEcho 是一个个人数字记忆增强平台，利用人工智能、认知科学和空间计算技术，
帮助用户构建"第二记忆系统"，实现知识记录、关联、遗忘预测、智能复习和空间可视化。

## 技术栈

| 类别 | 技术 |
|------|------|
| 开发语言 | Swift |
| UI 框架 | SwiftUI |
| AI 引擎 | CoreML / Vision / Natural Language |
| 空间计算 | RealityKit / ARKit |
| 目标平台 | iOS 16+ / iPadOS 16+ / visionOS 1+ |

## 项目结构

```
MindEcho/
├── docs/                    # 文档
│   ├── api/                 # API 文档
│   └── architecture/        # 架构设计文档
├── src/MindEcho/
│   ├── App/                 # 应用入口
│   ├── Models/              # 数据模型
│   ├── ViewModels/          # 视图模型
│   ├── Views/               # UI 视图
│   │   ├── Dashboard/       # 首页看板
│   │   ├── KnowledgeCapture/# 知识采集
│   │   ├── MemoryGraph/     # 记忆图谱
│   │   ├── Review/          # 智能复习
│   │   ├── Assessment/      # 能力评估
│   │   ├── Profile/         # 个人中心
│   │   └── VisionOS/        # 记忆宇宙
│   ├── Services/            # 业务服务层
│   ├── CoreML/              # ML 模型
│   ├── RealityKit/          # AR/VR 资源
│   ├── Extensions/          # 扩展工具
│   └── Resources/           # 资源文件
├── tests/MindEchoTests/     # 单元测试
├── scripts/                 # 构建脚本
└── .vscode/                 # VSCode 配置
```

## 核心功能模块

1. **用户管理** — 注册登录、个人中心
2. **知识采集** — 手动录入、OCR 识别、文档导入
3. **AI 知识解析** — 知识树、标签、关联、难度评估
4. **记忆图谱** — 节点展示、关系图、路径搜索、聚类
5. **遗忘预测** — 艾宾浩斯曲线 + ML 模型
6. **智能复习** — 每日复习计划、AI 出题
7. **能力评估** — 学习画像、多维指标
8. **记忆宇宙 (visionOS)** — 3D 空间知识探索

## 开发环境要求

- **macOS** 14+ (必需 — Xcode 仅支持 macOS)
- Xcode 16+
- iOS 16+ / iPadOS 16+ / visionOS 1+ Simulator
- Swift 5.9+
- Git 2.40+

> ⚠️ **重要**：本项目依赖 Apple 原生技术栈，**必须**在 macOS 上编译和运行。

## 快速开始

```bash
# 克隆仓库
git clone <repo-url>
cd MindEcho

# 打开 Xcode 项目
open MindEcho.xcodeproj

# 或使用 Swift Package Manager
swift build
swift test
```
