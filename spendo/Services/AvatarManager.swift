//
//  AvatarManager.swift
//  Spendo
//
//  用户头像管理器 - 全局单例
//

import SwiftUI
import Combine

class AvatarManager: ObservableObject {
    static let shared = AvatarManager()
    
    @Published var avatarImage: UIImage?
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    private init() {
        // 加载用户名
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "用户"
        // 加载头像
        loadAvatarImage()
    }
    
    // 加载头像
    func loadAvatarImage() {
        if let data = UserDefaults.standard.data(forKey: "userAvatarImage"),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
    
    // 保存头像
    func saveAvatarImage(_ image: UIImage?) {
        avatarImage = image
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "userAvatarImage")
        } else {
            UserDefaults.standard.removeObject(forKey: "userAvatarImage")
        }
        // 通知所有观察者
        objectWillChange.send()
    }
    
    // 更新用户名
    func updateUserName(_ name: String) {
        userName = name
    }
}

// MARK: - 共享头像视图组件
struct SharedAvatarView: View {
    @ObservedObject private var avatarManager = AvatarManager.shared
    var size: CGFloat = 40
    var showBadge: Bool = false
    
    var body: some View {
        ZStack {
            if let image = avatarManager.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(SpendoTheme.textSecondary)
            }
        }
    }
}
