//
//  SpendoApp.swift
//  Spendo - 极简记账App
//
//  Created by Spendo Team
//

import SwiftUI
import SwiftData
import Combine

@main
struct SpendoApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var lockManager = LockManagerWrapper()
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self,
            UserSettings.self
        ])

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            let previewConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let previewContainer = try? ModelContainer(for: schema, configurations: [previewConfiguration]) {
                return previewContainer
            }
        }

        // 确保 Application Support 目录存在
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupport.path) {
                try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
            }
        }
        
        // 明确禁用 CloudKit，避免因 CloudKit 未配置导致崩溃
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext
            initializeDefaultData(context: context)
            return container
        } catch {
            // 如果创建失败（可能是 schema 不兼容），尝试删除旧数据重新创建
            print("ModelContainer creation failed: \(error). Attempting to reset database...")
            
            // 尝试删除旧的数据库文件
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                let shmURL = appSupport.appendingPathComponent("default.store-shm")
                let walURL = appSupport.appendingPathComponent("default.store-wal")
                
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: shmURL)
                try? fileManager.removeItem(at: walURL)
            }
            
            // 重新尝试创建（使用相同的配置）
            do {
                let retryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    groupContainer: .none,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(for: schema, configurations: [retryConfig])
                let context = container.mainContext
                initializeDefaultData(context: context)
                return container
            } catch {
                // 最后的备选方案：使用内存数据库
                print("Failed to create persistent container, falling back to in-memory: \(error)")
                let inMemoryConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    allowsSave: true,
                    groupContainer: .none,
                    cloudKitDatabase: .none
                )
                do {
                    let inMemoryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                    let context = inMemoryContainer.mainContext
                    initializeDefaultData(context: context)
                    return inMemoryContainer
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(appState)
                } else {
                    OnboardingView()
                        .environmentObject(appState)
                }
                
                // 锁屏覆盖层
                if lockManager.manager.isLocked && lockManager.manager.isProtectionEnabled {
                    LockScreenView(isLocked: Binding(
                        get: { lockManager.manager.isLocked },
                        set: { lockManager.manager.isLocked = $0 }
                    ))
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: lockManager.manager.isLocked)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    lockManager.manager.appDidBecomeActive()
                case .inactive, .background:
                    lockManager.manager.appWillResignActive()
                @unknown default:
                    break
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// LockManager包装器 - 避免在App中直接使用单例
class LockManagerWrapper: ObservableObject {
    let manager = AppLockManager.shared
}

// App状态管理
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// 初始化默认数据
func initializeDefaultData(context: ModelContext) {
    // 检查是否已初始化
    let descriptor = FetchDescriptor<Category>()
    if let count = try? context.fetchCount(descriptor), count > 0 {
        return
    }
    
    // 创建默认类别
    let expenseCategories = [
        ("餐饮", "fork.knife", TransactionType.expense),
        ("交通", "car.fill", TransactionType.expense),
        ("购物", "cart.fill", TransactionType.expense),
        ("娱乐", "gamecontroller.fill", TransactionType.expense),
        ("医疗", "cross.case.fill", TransactionType.expense),
        ("教育", "book.fill", TransactionType.expense),
        ("住房", "house.fill", TransactionType.expense),
        ("通讯", "phone.fill", TransactionType.expense),
        ("其他", "ellipsis.circle.fill", TransactionType.expense)
    ]
    
    let incomeCategories = [
        ("工资", "banknote.fill", TransactionType.income),
        ("奖金", "gift.fill", TransactionType.income),
        ("投资", "chart.line.uptrend.xyaxis", TransactionType.income),
        ("其他", "ellipsis.circle.fill", TransactionType.income)
    ]
    
    for (name, icon, type) in expenseCategories + incomeCategories {
        let category = Category(name: name, iconName: icon, type: type)
        context.insert(category)
    }
    
    // 创建默认账户
    let defaultAccounts = [
        ("现金", "banknote", AccountType.cash, 0.0),
        ("银行卡", "creditcard", AccountType.bankCard, 0.0),
        ("支付宝", "apps.iphone", AccountType.digital, 0.0),
        ("微信", "message.fill", AccountType.digital, 0.0)
    ]
    
    for (name, icon, type, balance) in defaultAccounts {
        let account = Account(name: name, type: type, balance: balance, iconName: icon)
        context.insert(account)
    }
    
    // 创建默认用户设置
    let settings = UserSettings()
    context.insert(settings)
    
    try? context.save()
}
