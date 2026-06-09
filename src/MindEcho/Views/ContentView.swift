import SwiftUI

/// 主内容视图 — 根据平台自适应布局
struct ContentView: View {
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - 主标签导航
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            KnowledgeCaptureView()
                .tabItem {
                    Label("采集", systemImage: "plus.circle.fill")
                }

            MemoryGraphView()
                .tabItem {
                    Label("图谱", systemImage: "point.3.connected.trianglepath.dotted")
                }

            ReviewView()
                .tabItem {
                    Label("复习", systemImage: "brain.head.profile")
                }

            AssessmentView()
                .tabItem {
                    Label("评估", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.circle.fill")
                }
        }
        #if os(visionOS)
        .tabViewStyle(.sidebarAdaptable)
        #endif
    }
}
