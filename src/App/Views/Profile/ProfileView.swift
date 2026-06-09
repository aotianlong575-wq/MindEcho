import SwiftUI
import MindEchoCore

/// 个人中心
struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var vm = UserViewModel()
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section { profileHeader }

                Section {
                    LabeledContent("学习方向",
                                   value: vm.currentUser?.learningDirection.rawValue ?? "未设置")
                    LabeledContent("目标考试",
                                   value: vm.currentUser?.targetExam ?? "未设置")
                    LabeledContent("学习目标",
                                   value: vm.currentUser?.learningGoal ?? "未设置")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("资料完整度").font(.caption).foregroundColor(.secondary)
                        ProgressView(value: Double(vm.profileCompletionPercent), total: 100)
                            .tint(vm.profileCompletionPercent < 50 ? .orange : .green)
                    }
                } header: { Text("学习设置") }

                Section {
                    Button { } label: {
                        Label("导出学习数据", systemImage: "square.and.arrow.up")
                    }
                    Button { } label: {
                        Label("同步到 iCloud", systemImage: "icloud")
                    }
                } header: { Text("数据管理") }

                Section {
                    Toggle(isOn: $vm.isDarkMode) {
                        Label("深色模式", systemImage: "moon.fill")
                    }
                    Toggle(isOn: $vm.isOfflineMode) {
                        Label("离线模式", systemImage: "wifi.slash")
                    }
                    Toggle(isOn: $vm.enableNotifications) {
                        Label("复习提醒", systemImage: "bell.fill")
                    }
                } header: { Text("系统设置") }

                Section {
                    HStack {
                        Text("版本"); Spacer()
                        Text("1.0.0 (Beta)").foregroundColor(.secondary)
                    }
                    Link(destination: URL(string: "https://mindecho.local/terms")!) {
                        Label("用户协议", systemImage: "doc.text")
                    }
                    Link(destination: URL(string: "https://mindecho.local/privacy")!) {
                        Label("隐私政策", systemImage: "hand.raised")
                    }
                } header: { Text("关于") }

                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("个人中心")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.syncEditForm(); showingEditProfile = true } label: {
                        Text("编辑")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(vm: vm)
            }
            .confirmationDialog("确定退出登录？", isPresented: $showingLogoutAlert,
                                titleVisibility: .visible) {
                Button("退出登录", role: .destructive) {
                    vm.logout()
                    appState.isAuthenticated = false
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                Text(String(vm.userDisplayName.prefix(1)).uppercased())
                    .font(.title3.bold()).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.userDisplayName).font(.headline)
                Text(vm.userDisplayEmail).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 编辑资料弹窗
struct EditProfileSheet: View {
    @ObservedObject var vm: UserViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    HStack {
                        Text("昵称")
                        TextField("请输入昵称", text: $vm.editNickname)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("学习目标") {
                    Picker("学习方向", selection: $vm.editLearningDirection) {
                        ForEach(LearningDirection.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    HStack {
                        Text("目标考试")
                        TextField("如：考研、雅思、PMP", text: $vm.editTargetExam)
                            .multilineTextAlignment(.trailing)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("学习目标").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $vm.editLearningGoal)
                            .frame(minHeight: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3)))
                    }
                }
                if let err = vm.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await vm.updateProfile()
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(!vm.profileChanged || vm.isLoading)
                }
            }
        }
    }
}
