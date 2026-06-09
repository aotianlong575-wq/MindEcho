import SwiftUI

/// 个人中心
struct ProfileView: View {
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                // 头像与基本信息
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: nil) { image in
                            image.resizable()
                        } placeholder: {
                            Circle()
                                .fill(.blue.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("用户名")
                                .font(.headline)
                            Text("dev@mindecho.local")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        Button("编辑") {
                            showingEditProfile = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }

                // 学习设置
                Section("学习设置") {
                    HStack {
                        Text("学习方向")
                        Spacer()
                        Text("计算机科学")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("目标考试")
                        Spacer()
                        Text("未设置")
                            .foregroundColor(.secondary)
                    }
                }

                // 数据管理
                Section("数据管理") {
                    Button("导出数据") {}
                    Button("同步到云端") {}
                    Button("清除缓存") {}
                        .foregroundColor(.orange)
                }

                // 系统设置
                Section("系统设置") {
                    Toggle("深色模式", isOn: .constant(false))
                    Toggle("离线模式", isOn: .constant(false))
                    NavigationLink("无障碍设置") {}
                    NavigationLink("隐私设置") {}
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("用户协议") {}
                    NavigationLink("隐私政策") {}
                }

                // 退出登录
                Section {
                    Button("退出登录", role: .destructive) {
                        // TODO: 登出逻辑
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("个人中心")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
}

struct EditProfileView: View {
    @State private var nickname = ""
    @State private var learningDirection: LearningDirection = .computerScience
    @State private var targetExam = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("昵称", text: $nickname)
                }
                Section("学习目标") {
                    Picker("学习方向", selection: $learningDirection) {
                        ForEach(LearningDirection.allCases, id: \.self) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    TextField("目标考试", text: $targetExam)
                }
            }
            .navigationTitle("编辑资料")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        // TODO: 保存逻辑
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", role: .cancel) {}
                }
            }
        }
    }
}
