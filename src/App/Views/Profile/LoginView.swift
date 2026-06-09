import SwiftUI
import AuthenticationServices

/// 登录视图
/// 支持 Apple ID、邮箱密码、验证码三种登录方式
struct LoginView: View {
    @State private var loginMethod: LoginMethod = .appleID
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""

    var body: some View {
        VStack(spacing: 24) {
            // Logo 和标题
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("MindEcho")
                    .font(.largeTitle.bold())
                Text("记忆回声")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("你的第二记忆系统")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            // 登录方式选择
            Picker("登录方式", selection: $loginMethod) {
                ForEach(LoginMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 登录表单
            Group {
                switch loginMethod {
                case .appleID:
                    SignInWithAppleButton(.signIn) { _ in
                        // TODO: 处理 Apple ID 登录
                    } onCompletion: { _ in }
                        .frame(height: 44)
                        .padding(.horizontal)

                case .email:
                    VStack(spacing: 12) {
                        TextField("邮箱", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)

                        SecureField("密码", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)

                        Button("登录") {
                            // TODO: 邮箱密码登录
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal)

                case .verificationCode:
                    VStack(spacing: 12) {
                        TextField("手机号", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)

                        HStack {
                            TextField("验证码", text: $verificationCode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)

                            Button("获取验证码") {
                                // TODO: 发送验证码
                            }
                            .buttonStyle(.bordered)
                        }

                        Button("登录") {
                            // TODO: 验证码登录
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .disabled(verificationCode.isEmpty)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
    }
}

enum LoginMethod: String, CaseIterable {
    case appleID = "Apple ID"
    case email = "邮箱"
    case verificationCode = "验证码"
}
