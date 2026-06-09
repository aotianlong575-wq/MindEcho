import SwiftUI
import MindEchoCore

/// 注册视图
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = UserViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("创建账号")
                        .font(.title2.bold())
                    Text("开始你的第二记忆之旅")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)

                // 表单
                VStack(spacing: 12) {
                    inputField(icon: "person.fill", placeholder: "昵称",
                               text: $vm.registerName, contentType: .name)

                    inputField(icon: "envelope.fill", placeholder: "邮箱",
                               text: $vm.registerEmail, contentType: .emailAddress,
                               keyboard: .emailAddress, autocapitalize: false)

                    inputField(icon: "lock.fill", placeholder: "密码（至少6位）",
                               text: $vm.registerPassword, contentType: .newPassword,
                               isSecure: true)

                    inputField(icon: "lock.shield.fill", placeholder: "确认密码",
                               text: $vm.registerConfirmPassword, contentType: .newPassword,
                               isSecure: true)

                    // 密码强度提示
                    if !vm.registerPassword.isEmpty {
                        PasswordStrengthBar(password: vm.registerPassword)
                    }
                }
                .padding(.horizontal)

                // 协议
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("注册即表示同意")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Link("用户协议", destination: URL(string: "https://mindecho.local/terms")!)
                        .font(.caption2)
                    Text("和")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Link("隐私政策", destination: URL(string: "https://mindecho.local/privacy")!)
                        .font(.caption2)
                }

                // 错误
                if let err = vm.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // 注册按钮
                Button { Task { await vm.register() } } label: {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("注册").fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canRegister || vm.isLoading)
                .padding(.horizontal)

                // 返回登录
                Button("已有账号？返回登录") { dismiss() }
                    .font(.caption)
            }
            .padding(.vertical)
        }
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 输入框组件
    private func inputField(icon: String, placeholder: String,
                            text: Binding<String>,
                            contentType: PlatformTextContentType? = nil,
                            keyboard: PlatformKeyboardType = .default,
                            autocapitalize: Bool = true,
                            isSecure: Bool = false) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.secondary).frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .autocapitalization(autocapitalize ? .sentences : .none)
            .disableAutocorrection(!autocapitalize)
            .textContentType(contentType)
            .keyboardType(keyboard)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 密码强度指示器
struct PasswordStrengthBar: View {
    let password: String

    private var strength: (level: Int, color: Color, label: String) {
        let hasUpper = password.contains { $0.isUppercase }
        let hasDigit = password.contains { $0.isNumber }
        let hasSpecial = password.contains { "!@#$%^&*".contains($0) }
        let score = [password.count >= 6, hasUpper, hasDigit, hasSpecial]
            .filter { $0 }.count

        switch score {
        case 0..<2: return (1, .red, "弱")
        case 2: return (2, .orange, "一般")
        case 3: return (3, .yellow, "较好")
        case 4: return (4, .green, "强")
        default: return (0, .gray, "")
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < strength.level ? strength.color : Color.secondary.opacity(0.2))
                    .frame(height: 4)
            }
            Text(strength.label)
                .font(.caption2)
                .foregroundColor(strength.color)
        }
    }
}
