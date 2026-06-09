import SwiftUI
import AuthenticationServices
import MindEchoCore

/// 登录视图 — Apple ID / 邮箱 / 验证码三种方式
struct LoginView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var vm = UserViewModel()
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    logoSection

                    Picker("登录方式", selection: $vm.loginMethod) {
                        ForEach(UserViewModel.LoginMethod.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    loginForm

                    if let err = vm.errorMessage {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    Button("没有账号？去注册") { showRegister = true }
                        .font(.caption)

                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView().environmentObject(appState)
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("MindEcho").font(.largeTitle.bold())
            Text("记忆回声 · 你的第二记忆系统")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var loginForm: some View {
        switch vm.loginMethod {
        case .appleID: appleIDSection
        case .email: emailSection
        case .code: codeSection
        }
    }

    private var appleIDSection: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(.signIn) { req in
                req.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    switch result {
                    case .success(let auth):
                        if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                            await vm.handleAppleIDLogin(
                                userIdentifier: cred.user,
                                token: cred.identityToken,
                                authCode: cred.authorizationCode)
                        }
                    case .failure(let err):
                        vm.errorMessage = err.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 44).padding(.horizontal, 20)
        }
    }

    private var emailSection: some View {
        VStack(spacing: 14) {
            inputField(icon: "envelope.fill", placeholder: "邮箱地址",
                       text: $vm.email, contentType: .emailAddress,
                       keyboard: .emailAddress, noAuto: true)
            inputField(icon: "lock.fill", placeholder: "密码",
                       text: $vm.password, contentType: .password,
                       isSecure: true)

            Button { Task { await vm.login() } } label: {
                Group {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text("登录").fontWeight(.semibold) }
                }
                .frame(maxWidth: .infinity).frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canLogin || vm.isLoading)
        }
        .padding(.horizontal)
    }

    private var codeSection: some View {
        VStack(spacing: 14) {
            inputField(icon: "phone.fill", placeholder: "手机号",
                       text: $vm.phone, keyboard: .phonePad)
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "number").foregroundColor(.secondary)
                    TextField("验证码", text: $vm.verificationCode)
                        .keyboardType(.numberPad)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("发送验证码") { }.buttonStyle(.bordered).controlSize(.small)
            }

            Button { Task { await vm.login() } } label: {
                Group {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text("登录").fontWeight(.semibold) }
                }
                .frame(maxWidth: .infinity).frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canLogin || vm.isLoading)
        }
        .padding(.horizontal)
    }

    private func inputField(icon: String, placeholder: String,
                            text: Binding<String>,
                            contentType: PlatformTextContentType? = nil,
                            keyboard: PlatformKeyboardType = .default,
                            noAuto: Bool = false,
                            isSecure: Bool = false) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.secondary)
            Group {
                if isSecure { SecureField(placeholder, text: text) }
                else { TextField(placeholder, text: text) }
            }
            .autocapitalization(noAuto ? .none : .sentences)
            .disableAutocorrection(noAuto)
            .textContentType(contentType)
            .keyboardType(keyboard)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
