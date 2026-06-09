# MindEcho 环境配置说明

## Windows 端配置完成情况

> 配置日期：2026-06-09

### ✅ 已完成配置

| 工具 | 路径 | 版本 | 说明 |
|------|------|------|------|
| Git | `D:\Git\cmd\git.exe` | 2.49.0 | 版本控制 |
| VSCode | `D:\Microsoft VS Code\` | - | 代码编辑器 |
| VSCode 扩展 | `D:\vscode-extensions\` | - | 扩展安装目录 |
| 项目代码 | `D:\MindEcho\` | - | 项目根目录 |

### 已安装的 VSCode 扩展

| 扩展 | 用途 |
|------|------|
| `sswg.swift-lang` | Swift 语法高亮、代码补全、Language Server |
| `vknabel.vscode-swiftformat` | Swift 代码格式化 |
| `vadimcn.vscode-lldb` | LLDB 调试器 |
| `eamodio.gitlens` | Git 增强工具 |
| `shd101wyy.markdown-preview-enhanced` | Markdown 预览增强 |
| `gruntfuggly.todo-tree` | TODO 任务树 |
| `yzhang.markdown-all-in-one` | Markdown 编辑增强 |
| `bierner.markdown-mermaid` | Mermaid 图表支持 |
| `pkief.material-icon-theme` | 图标主题 |
| `github.copilot` | AI 代码助手 |
| `github.copilot-chat` | AI 对话助手（内置） |

### 启动 VSCode 时使用 D: 盘扩展

```powershell
# 已自动添加 Git 到用户 PATH
# 打开项目（扩展目录指向 D 盘）
code --extensions-dir D:\vscode-extensions D:\MindEcho
```

---

## 🚨 macOS 端待配置（必须先获取 Mac）

### 必需软件

| 软件 | 安装方式 | 说明 |
|------|----------|------|
| Xcode 16+ | Mac App Store | IDE + 编译工具链 |
| Xcode Command Line Tools | `xcode-select --install` | 命令行工具 |
| Swift 5.9+ | 随 Xcode 安装 | 编译语言 |
| Git | `brew install git` | 版本控制 |

### 可选工具

| 工具 | 安装方式 | 用途 |
|------|----------|------|
| Homebrew | `https://brew.sh` | macOS 包管理器 |
| SwiftLint | `brew install swiftlint` | 代码规范检查 |
| Fastlane | `brew install fastlane` | 自动化构建发布 |
| Proxyman | `https://proxyman.io` | 网络调试 |
| SF Symbols | 苹果官网下载 | 图标资源 |

### 首次启动项目

```bash
# 1. 克隆或复制项目到 Mac
git clone <repo-url> ~/Developer/MindEcho
# 或从 D:\MindEcho 复制到 Mac

# 2. 打开 Xcode 项目
cd ~/Developer/MindEcho
xed .  # 或 open Package.swift

# 3. 选择 target: MindEchoApp -> iOS Simulator

# 4. 按 Cmd+R 运行
```

---

## 关于当前 Windows 环境

Windows 上仅能做：
- ✍️ 编写 Swift 代码（语法高亮 + 格式化）
- 📝 编写文档和设计
- 🔍 代码审查和搜索
- 📊 项目管理（TODO、路线图）

Windows 上**不能**做：
- ❌ 编译 Swift 代码
- ❌ 运行 iOS/visionOS 模拟器
- ❌ 使用 Xcode 调试
- ❌ 使用 CoreML 模型训练
- ❌ 使用 RealityKit 预览
- ❌ 真机部署和测试

---

## 最低 Mac 配置建议

| 配置项 | 最低要求 | 推荐配置 |
|--------|----------|----------|
| 芯片 | Apple M1 | Apple M4 |
| 内存 | 8 GB | 16 GB |
| 存储 | 256 GB | 512 GB+ |
| macOS | Sonoma 14 | Sequoia 15 |
| Xcode | 16.0 | 16.x 最新版 |

💡 **性价比推荐**：Mac mini M4 (16G/256G) ≈ ¥3500-4000
