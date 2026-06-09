import SwiftUI

// MARK: - 跨平台 View 扩展
extension View {
    /// 条件化键盘类型（仅 iOS）
    func keyboardType(_ type: PlatformKeyboardType) -> some View {
        #if os(iOS)
        self.keyboardType(type.uiKitType)
        #else
        self
        #endif
    }

    /// 条件化文本内容类型（仅 iOS）
    func textContentType(_ type: PlatformTextContentType?) -> some View {
        #if os(iOS)
        self.textContentType(type?.uiKitType)
        #else
        self
        #endif
    }
}

// MARK: - 平台无关的键盘类型
enum PlatformKeyboardType {
    case `default`
    case emailAddress
    case phonePad
    case numberPad

    #if os(iOS)
    var uiKitType: UIKit.UIKeyboardType {
        switch self {
        case .default: return .default
        case .emailAddress: return .emailAddress
        case .phonePad: return .phonePad
        case .numberPad: return .numberPad
        }
    }
    #endif
}

// MARK: - 平台无关的文本内容类型
enum PlatformTextContentType {
    case name
    case emailAddress
    case password
    case newPassword

    #if os(iOS)
    var uiKitType: UIKit.UITextContentType {
        switch self {
        case .name: return .name
        case .emailAddress: return .emailAddress
        case .password: return .password
        case .newPassword: return .newPassword
        }
    }
    #endif
}
