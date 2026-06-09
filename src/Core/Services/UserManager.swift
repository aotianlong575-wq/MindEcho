import Foundation

// 条件导入 Keychain（macOS 和 iOS 都有 Security framework）
#if canImport(Security)
import Security
#endif

/// 用户管理器
/// 管理用户认证、Token、会话持久化
@MainActor
public final class UserManager: ObservableObject {
    @Published public var currentUser: User?
    @Published public var isAuthenticated = false
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let tokenKey = "com.mindecho.auth.token"
    private let refreshTokenKey = "com.mindecho.auth.refresh"
    private let userDefaultsKey = "com.mindecho.user.profile"

    public init() {
        trySilentLogin()
    }

    // MARK: - 登录

    /// Apple ID 登录
    public func loginWithAppleID(userIdentifier: String, identityToken: Data?, authorizationCode: Data?) async throws {
        isLoading = true; defer { isLoading = false }
        // 验证流程
        guard let tokenData = identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            throw UserError.invalidToken
        }
        // 模拟验证成功
        let authToken = AuthToken(
            accessToken: tokenString,
            refreshToken: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try saveToken(authToken)
        let user = try await fetchUserProfile()
        setCurrentUser(user)
    }

    /// 邮箱密码登录
    public func loginWithEmail(email: String, password: String) async throws {
        isLoading = true; defer { isLoading = false }
        guard isValidEmail(email) else { throw UserError.invalidEmail }
        guard password.count >= 6 else { throw UserError.passwordTooShort }

        // 模拟 API 请求
        let token = AuthToken(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try saveToken(token)
        let user = User(
            id: UUID(), name: email.components(separatedBy: "@").first ?? "User",
            email: email, phone: nil, avatarURL: nil,
            learningDirection: .other, targetExam: nil, learningGoal: nil,
            createdAt: Date(), lastLoginAt: Date(), cognitiveProfile: nil
        )
        setCurrentUser(user)
    }

    /// 验证码登录
    public func loginWithVerificationCode(phone: String, code: String) async throws {
        isLoading = true; defer { isLoading = false }
        guard phone.count >= 11 else { throw UserError.invalidPhone }
        guard code.count >= 4 else { throw UserError.invalidCode }

        let token = AuthToken(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try saveToken(token)
        let user = User(
            id: UUID(), name: "用户\(phone.suffix(4))",
            email: "\(phone)@mock.local", phone: phone, avatarURL: nil,
            learningDirection: .other, targetExam: nil, learningGoal: nil,
            createdAt: Date(), lastLoginAt: Date(), cognitiveProfile: nil
        )
        setCurrentUser(user)
    }

    // MARK: - 注册
    public func register(name: String, email: String, password: String) async throws {
        isLoading = true; defer { isLoading = false }
        guard !name.isEmpty else { throw UserError.invalidName }
        guard isValidEmail(email) else { throw UserError.invalidEmail }
        guard password.count >= 6 else { throw UserError.passwordTooShort }

        try await loginWithEmail(email: email, password: password)
    }

    // MARK: - 登出
    public func logout() {
        currentUser = nil
        isAuthenticated = false
        removeToken()
    }

    // MARK: - 更新资料
    public func updateProfile(name: String? = nil, direction: LearningDirection? = nil,
                               exam: String? = nil, goal: String? = nil) async throws {
        guard var user = currentUser else { return }
        if let n = name { user.name = n }
        if let d = direction { user.learningDirection = d }
        if let e = exam { user.targetExam = e }
        if let g = goal { user.learningGoal = g }
        setCurrentUser(user)
        try saveUserToDisk(user)
    }

    // MARK: - Token 管理
    private func saveToken(_ token: AuthToken) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(token)
        UserDefaults.standard.set(data, forKey: tokenKey)
    }

    public func getAccessToken() -> String? {
        guard let data = UserDefaults.standard.data(forKey: tokenKey),
              let token = try? JSONDecoder().decode(AuthToken.self, from: data) else { return nil }
        if token.isExpired {
            // TODO: 用 refresh token 刷新
            return nil
        }
        return token.accessToken
    }

    private func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    public func trySilentLogin() {
        guard let data = UserDefaults.standard.data(forKey: tokenKey),
              let token = try? JSONDecoder().decode(AuthToken.self, from: data),
              !token.isExpired,
              let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else { return }
        setCurrentUser(user)
    }

    // MARK: - 用户信息
    private func fetchUserProfile() async throws -> User {
        // 模拟网络请求
        try await Task.sleep(nanoseconds: 500_000_000)
        return User(
            id: UUID(), name: "Apple User", email: "apple@mindecho.local",
            phone: nil, avatarURL: nil,
            learningDirection: .other, targetExam: nil, learningGoal: nil,
            createdAt: Date(), lastLoginAt: Date(), cognitiveProfile: nil
        )
    }

    private func setCurrentUser(_ user: User) {
        var u = user
        u.lastLoginAt = Date()
        currentUser = u
        isAuthenticated = true
        try? saveUserToDisk(u)
    }

    private func saveUserToDisk(_ user: User) throws {
        let data = try JSONEncoder().encode(user)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    // MARK: - 验证
    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".") && email.count > 5
    }
}

// MARK: - 错误类型
public enum UserError: Error, LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidToken
    case invalidPhone
    case invalidCode
    case invalidName
    case passwordTooShort
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidEmail: return "请输入有效的邮箱地址"
        case .invalidPassword: return "密码错误"
        case .invalidToken: return "Token 无效或已过期"
        case .invalidPhone: return "请输入有效的手机号"
        case .invalidCode: return "验证码错误"
        case .invalidName: return "请输入昵称"
        case .passwordTooShort: return "密码至少 6 位"
        case .networkError(let msg): return "网络错误: \(msg)"
        }
    }
}
