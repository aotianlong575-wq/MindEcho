import Foundation

/// 全局应用状态管理器
/// 管理用户会话、同步状态、系统配置
final class AppStateManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var syncStatus: SyncStatus = .idle
    @Published var isOfflineMode: Bool = false
    @Published var preferredColorScheme: ColorSchemeType = .system

    enum SyncStatus {
        case idle
        case syncing
        case completed
        case error(String)
    }

    enum ColorSchemeType {
        case light
        case dark
        case system
    }
}
