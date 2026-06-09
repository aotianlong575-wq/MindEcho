import SwiftUI
import MindEchoCore

/// 用户认证与资料管理 ViewModel
/// 桥接 UserManager 与 SwiftUI 视图层
@MainActor
final class UserViewModel: ObservableObject {
    // MARK: - 状态
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?

    // MARK: - 登录表单
    @Published var email = ""
    @Published var password = ""
    @Published var phone = ""
    @Published var verificationCode = ""
    @Published var loginMethod: LoginMethod = .appleID

    // MARK: - 注册表单
    @Published var registerName = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""

    // MARK: - 编辑资料表单
    @Published var editNickname = ""
    @Published var editLearningDirection: LearningDirection = .other
    @Published var editTargetExam = ""
    @Published var editLearningGoal = ""

    // MARK: - 系统设置
    @Published var isDarkMode = false
    @Published var isOfflineMode = false
    @Published var enableNotifications = true

    private let userManager = UserManager()

    enum LoginMethod: String, CaseIterable {
        case appleID = "Apple ID"
        case email = "邮箱"
        case code = "验证码"
    }

    // MARK: - 初始化
    init() {
        // 尝试自动登录
        isAuthenticated = userManager.isAuthenticated
        currentUser = userManager.currentUser
    }

    // MARK: - 登录
    func login() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            switch loginMethod {
            case .appleID:
                // Apple ID 需要 SignInWithApple 按钮回调
                errorMessage = "请使用 Apple ID 按钮登录"
                return
            case .email:
                try await userManager.loginWithEmail(email: email, password: password)
            case .code:
                try await userManager.loginWithVerificationCode(phone: phone, code: verificationCode)
            }
            onLoginSuccess()
        } catch {
            handleError(error)
        }
    }

    func handleAppleIDLogin(userIdentifier: String, token: Data?, authCode: Data?) async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            try await userManager.loginWithAppleID(
                userIdentifier: userIdentifier,
                identityToken: token,
                authorizationCode: authCode
            )
            onLoginSuccess()
        } catch {
            handleError(error)
        }
    }

    // MARK: - 注册
    func register() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        // 前端校验
        guard !registerName.isEmpty else { errorMessage = "请输入昵称"; return }
        guard registerEmail.contains("@"), registerEmail.contains(".") else {
            errorMessage = "请输入有效邮箱"; return
        }
        guard registerPassword.count >= 6 else { errorMessage = "密码至少6位"; return }
        guard registerPassword == registerConfirmPassword else {
            errorMessage = "两次密码不一致"; return
        }

        do {
            try await userManager.register(name: registerName, email: registerEmail, password: registerPassword)
            onLoginSuccess()
        } catch {
            handleError(error)
        }
    }

    // MARK: - 登出
    func logout() {
        userManager.logout()
        isAuthenticated = false
        currentUser = nil
        resetForms()
    }

    // MARK: - 更新资料
    func updateProfile() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }

        do {
            try await userManager.updateProfile(
                name: editNickname.isEmpty ? nil : editNickname,
                direction: editLearningDirection,
                exam: editTargetExam.isEmpty ? nil : editTargetExam,
                goal: editLearningGoal.isEmpty ? nil : editLearningGoal
            )
            currentUser = userManager.currentUser
            // 加载当前值到编辑表单
            syncEditForm()
        } catch {
            handleError(error)
        }
    }

    // MARK: - 表单同步
    func syncEditForm() {
        guard let user = currentUser else { return }
        editNickname = user.name
        editLearningDirection = user.learningDirection
        editTargetExam = user.targetExam ?? ""
        editLearningGoal = user.learningGoal ?? ""
    }

    // MARK: - 表单验证
    var canLogin: Bool {
        switch loginMethod {
        case .email:
            return email.contains("@") && password.count >= 6
        case .code:
            return phone.count >= 11 && verificationCode.count >= 4
        case .appleID:
            return true // 由系统按钮控制
        }
    }

    var canRegister: Bool {
        !registerName.isEmpty &&
        registerEmail.contains("@") &&
        registerPassword.count >= 6 &&
        registerPassword == registerConfirmPassword
    }

    var profileChanged: Bool {
        guard let user = currentUser else { return false }
        return editNickname != user.name ||
               editLearningDirection != user.learningDirection ||
               editTargetExam != (user.targetExam ?? "") ||
               editLearningGoal != (user.learningGoal ?? "")
    }

    var userDisplayEmail: String {
        currentUser?.email ?? ""
    }

    var userDisplayName: String {
        currentUser?.name ?? "未登录"
    }

    var profileCompletionPercent: Int {
        guard let user = currentUser else { return 0 }
        var score = 0
        if !user.name.isEmpty { score += 25 }
        if user.learningGoal != nil { score += 25 }
        if user.targetExam != nil { score += 25 }
        if user.learningDirection != .other { score += 25 }
        return score
    }

    // MARK: - Private
    private func onLoginSuccess() {
        isAuthenticated = true
        currentUser = userManager.currentUser
        errorMessage = nil
        resetForms()
        syncEditForm()
    }

    private func resetForms() {
        email = ""; password = ""; phone = ""; verificationCode = ""
        registerName = ""; registerEmail = ""; registerPassword = ""; registerConfirmPassword = ""
    }

    private func handleError(_ error: Error) {
        if let userError = error as? UserError {
            errorMessage = userError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
