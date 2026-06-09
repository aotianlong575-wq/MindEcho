import Foundation

/// 用户管理器
/// 管理用户认证、登录状态、个人资料更新
@MainActor
final class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - 登录
    func loginWithAppleID(userIdentifier: String, identityToken: Data?, authorizationCode: Data?) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: 实现 Apple ID 登录
        // 1. 验证 identity token
        // 2. 发送到后端验证
        // 3. 获取用户信息并创建/更新本地用户
    }

    func loginWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: 实现邮箱登录
        // 1. 校验输入
        // 2. 发送登录请求
        // 3. 保存 token 到 Keychain
    }

    func loginWithVerificationCode(phone: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // TODO: 实现验证码登录
    }

    // MARK: - 注册
    func register(name: String, email: String, password: String) async throws {
        // TODO: 实现注册逻辑
        // 1. 验证输入合法性
        // 2. 发送注册请求
        // 3. 自动登录
    }

    // MARK: - 登出
    func logout() {
        currentUser = nil
        isAuthenticated = false
        // TODO: 清除 Keychain、CoreData 缓存
    }

    // MARK: - 更新资料
    func updateProfile(nickname: String?, learningDirection: LearningDirection?, targetExam: String?) async throws {
        guard var user = currentUser else { return }

        if let nickname = nickname { user.name = nickname }
        if let direction = learningDirection { user.learningDirection = direction }
        user.targetExam = targetExam

        // TODO: 同步到后端

        currentUser = user
    }
}
