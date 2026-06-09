import SwiftUI

/// MindEcho 应用入口
/// 支持 iOS / iPadOS / visionOS 多平台
@main
struct MindEchoApp: App {
    @StateObject private var appState = AppStateManager()
    @StateObject private var userManager = UserManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(userManager)
        }
        #if os(visionOS)
        .defaultSize(width: 800, height: 600)

        ImmersiveSpace(id: "MemoryUniverse") {
            MemoryUniverseView()
                .environmentObject(appState)
        }
        #endif
    }
}
