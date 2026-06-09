import Foundation
import MindEchoCore

/// 鍏ㄥ眬搴旂敤鐘舵€佺鐞嗗櫒
/// 绠＄悊鐢ㄦ埛浼氳瘽銆佸悓姝ョ姸鎬併€佺郴缁熼厤缃?final class AppStateManager: ObservableObject {
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
