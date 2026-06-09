import SwiftUI
import MindEchoCore

/// 涓汉涓績
struct ProfileView: View {
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                // 澶村儚涓庡熀鏈俊鎭?                Section {
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
                            Text("鐢ㄦ埛鍚?)
                                .font(.headline)
                            Text("dev@mindecho.local")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        Button("缂栬緫") {
                            showingEditProfile = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }

                // 瀛︿範璁剧疆
                Section("瀛︿範璁剧疆") {
                    HStack {
                        Text("瀛︿範鏂瑰悜")
                        Spacer()
                        Text("璁＄畻鏈虹瀛?)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("鐩爣鑰冭瘯")
                        Spacer()
                        Text("鏈缃?)
                            .foregroundColor(.secondary)
                    }
                }

                // 鏁版嵁绠＄悊
                Section("鏁版嵁绠＄悊") {
                    Button("瀵煎嚭鏁版嵁") {}
                    Button("鍚屾鍒颁簯绔?) {}
                    Button("娓呴櫎缂撳瓨") {}
                        .foregroundColor(.orange)
                }

                // 绯荤粺璁剧疆
                Section("绯荤粺璁剧疆") {
                    Toggle("娣辫壊妯″紡", isOn: .constant(false))
                    Toggle("绂荤嚎妯″紡", isOn: .constant(false))
                    NavigationLink("鏃犻殰纰嶈缃?) {}
                    NavigationLink("闅愮璁剧疆") {}
                }

                // 鍏充簬
                Section("鍏充簬") {
                    HStack {
                        Text("鐗堟湰")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    NavigationLink("鐢ㄦ埛鍗忚") {}
                    NavigationLink("闅愮鏀跨瓥") {}
                }

                // 閫€鍑虹櫥褰?                Section {
                    Button("閫€鍑虹櫥褰?, role: .destructive) {
                        // TODO: 鐧诲嚭閫昏緫
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("涓汉涓績")
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
                Section("鍩烘湰淇℃伅") {
                    TextField("鏄电О", text: $nickname)
                }
                Section("瀛︿範鐩爣") {
                    Picker("瀛︿範鏂瑰悜", selection: $learningDirection) {
                        ForEach(LearningDirection.allCases, id: \.self) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    TextField("鐩爣鑰冭瘯", text: $targetExam)
                }
            }
            .navigationTitle("缂栬緫璧勬枡")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("淇濆瓨") {
                        // TODO: 淇濆瓨閫昏緫
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("鍙栨秷", role: .cancel) {}
                }
            }
        }
    }
}
