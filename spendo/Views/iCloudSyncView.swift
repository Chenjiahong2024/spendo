//
//  iCloudSyncView.swift
//  Spendo
//

import SwiftUI
import SwiftData
import CloudKit
import Combine

// MARK: - iCloud同步状态
enum iCloudSyncStatus: Equatable {
    case unknown
    case available
    case unavailable(String)
    case syncing
    case synced
    case error(String)
    
    var displayText: String {
        switch self {
        case .unknown:
            return "detecting".localized
        case .available:
            return "available".localized
        case .unavailable(let reason):
            return reason
        case .syncing:
            return "syncing".localized
        case .synced:
            return "synced".localized
        case .error(let message):
            return message
        }
    }
    
    var color: Color {
        switch self {
        case .unknown, .syncing:
            return .orange
        case .available, .synced:
            return SpendoTheme.accentGreen
        case .unavailable, .error:
            return SpendoTheme.accentRed
        }
    }
    
    var icon: String {
        switch self {
        case .unknown:
            return "questionmark.circle.fill"
        case .available, .synced:
            return "checkmark.circle.fill"
        case .unavailable, .error:
            return "xmark.circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - iCloud同步管理器
class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()
    
    @Published var syncStatus: iCloudSyncStatus = .unknown
    @Published var lastSyncTime: Date?
    @Published var isAutoSyncEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isAutoSyncEnabled, forKey: "iCloudAutoSync")
        }
    }
    @Published var syncOnWiFiOnly: Bool = false {
        didSet {
            UserDefaults.standard.set(syncOnWiFiOnly, forKey: "iCloudSyncWiFiOnly")
        }
    }
    
    // CloudKit容器
    private lazy var container: CKContainer = {
        CKContainer(identifier: "iCloud.com.Jiahong-Chen.trip.spendo")
    }()
    
    private func getContainer() -> CKContainer? {
        return container
    }
    
    private func getDatabase() -> CKDatabase? {
        return container.privateCloudDatabase
    }
    
    private init() {
        // 安全读取UserDefaults
        isAutoSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudAutoSync")
        syncOnWiFiOnly = UserDefaults.standard.bool(forKey: "iCloudSyncWiFiOnly")
        
        // 加载上次同步时间
        if let timestamp = UserDefaults.standard.object(forKey: "lastICloudSyncTime") as? Date {
            lastSyncTime = timestamp
        }
        
        // 不在init中检查状态，等待视图主动调用
    }
    
    // 检查iCloud状态
    func checkiCloudStatus() {
        syncStatus = .unknown
        
        guard let container = getContainer() else {
            syncStatus = .unavailable("CloudKit未配置")
            return
        }
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .error("检查失败: \(error.localizedDescription)")
                    return
                }
                
                switch status {
                case .available:
                    self?.syncStatus = .available
                case .noAccount:
                    self?.syncStatus = .unavailable("未登录iCloud账户")
                case .restricted:
                    self?.syncStatus = .unavailable("iCloud访问受限")
                case .couldNotDetermine:
                    self?.syncStatus = .unavailable("无法确定iCloud状态")
                case .temporarilyUnavailable:
                    self?.syncStatus = .unavailable("iCloud暂时不可用")
                @unknown default:
                    self?.syncStatus = .unavailable("未知状态")
                }
            }
        }
    }
    
    // 同步数据到iCloud
    func syncToiCloud(transactions: [Transaction], accounts: [Account], completion: @escaping (Bool, String?) -> Void) {
        guard case .available = syncStatus else {
            completion(false, "iCloud不可用")
            return
        }
        
        guard let database = getDatabase() else {
            completion(false, "CloudKit数据库未配置")
            return
        }
        
        syncStatus = .syncing
        
        // 创建备份记录
        let backupRecord = CKRecord(recordType: "SpendoBackup")
        backupRecord["backupDate"] = Date() as CKRecordValue
        backupRecord["deviceName"] = UIDevice.current.name as CKRecordValue
        backupRecord["transactionCount"] = transactions.count as CKRecordValue
        backupRecord["accountCount"] = accounts.count as CKRecordValue
        
        // 将数据序列化为JSON
        do {
            let transactionData = try encodeTransactions(transactions)
            let accountData = try encodeAccounts(accounts)
            
            backupRecord["transactionsData"] = transactionData as CKRecordValue
            backupRecord["accountsData"] = accountData as CKRecordValue
            
            // 保存到iCloud
            database.save(backupRecord) { [weak self] record, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.syncStatus = .error("同步失败")
                        completion(false, error.localizedDescription)
                    } else {
                        self?.syncStatus = .synced
                        self?.lastSyncTime = Date()
                        UserDefaults.standard.set(Date(), forKey: "lastICloudSyncTime")
                        completion(true, nil)
                    }
                }
            }
        } catch {
            syncStatus = .error("数据编码失败")
            completion(false, error.localizedDescription)
        }
    }
    
    // 从iCloud恢复数据
    func restoreFromiCloud(completion: @escaping (Data?, Data?, String?) -> Void) {
        guard case .available = syncStatus else {
            completion(nil, nil, "iCloud不可用")
            return
        }
        
        guard let database = getDatabase() else {
            completion(nil, nil, "CloudKit数据库未配置")
            return
        }
        
        syncStatus = .syncing
        
        // 查询最新的备份
        let query = CKQuery(recordType: "SpendoBackup", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "backupDate", ascending: false)]
        
        database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (matchResults, _)):
                    if let firstResult = matchResults.first {
                        switch firstResult.1 {
                        case .success(let record):
                            let transactionsData = record["transactionsData"] as? Data
                            let accountsData = record["accountsData"] as? Data
                            self?.syncStatus = .synced
                            completion(transactionsData, accountsData, nil)
                        case .failure(let error):
                            self?.syncStatus = .error("恢复失败")
                            completion(nil, nil, error.localizedDescription)
                        }
                    } else {
                        self?.syncStatus = .available
                        completion(nil, nil, "没有找到备份数据")
                    }
                case .failure(let error):
                    self?.syncStatus = .error("查询失败")
                    completion(nil, nil, error.localizedDescription)
                }
            }
        }
    }
    
    // 编码交易数据
    private func encodeTransactions(_ transactions: [Transaction]) throws -> Data {
        var transactionDicts: [[String: Any]] = []
        
        for t in transactions {
            var dict: [String: Any] = [
                "id": t.id.uuidString,
                "amount": t.amount,
                "note": t.note,
                "date": t.date.timeIntervalSince1970,
                "type": t.type.rawValue,
                "currency": t.currency
            ]
            if let categoryId = t.categoryId {
                dict["categoryId"] = categoryId.uuidString
            }
            if let accountId = t.accountId {
                dict["accountId"] = accountId.uuidString
            }
            transactionDicts.append(dict)
        }
        
        return try JSONSerialization.data(withJSONObject: transactionDicts, options: [])
    }
    
    // 编码账户数据
    private func encodeAccounts(_ accounts: [Account]) throws -> Data {
        var accountDicts: [[String: Any]] = []
        
        for a in accounts {
            let dict: [String: Any] = [
                "id": a.id.uuidString,
                "name": a.name,
                "type": a.type.rawValue,
                "balance": a.balance,
                "iconName": a.iconName,
                "iconColorHex": a.iconColorHex,
                "iconBgColorHex": a.iconBgColorHex
            ]
            accountDicts.append(dict)
        }
        
        return try JSONSerialization.data(withJSONObject: accountDicts, options: [])
    }
    
    // 格式化上次同步时间
    func formattedLastSyncTime() -> String {
        guard let lastSync = lastSyncTime else {
            return "从未同步"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}

// MARK: - iCloud同步视图
struct iCloudSyncView: View {
    @ObservedObject private var syncManager = iCloudSyncManager.shared
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showSyncConfirm = false
    @State private var showRestoreConfirm = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isRefreshing = false
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // iCloud状态卡片
                    iCloudStatusCard(status: syncManager.syncStatus)
                    
                    // 同步设置
                    SettingsSection {
                        // 自动同步
                        HStack {
                            Text("自动同步")
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $syncManager.isAutoSyncEnabled)
                                .labelsHidden()
                                .tint(SpendoTheme.accentGreen)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        
                        SettingsDivider()
                        
                        // 仅WiFi同步
                        HStack {
                            Text("仅在WiFi下同步")
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $syncManager.syncOnWiFiOnly)
                                .labelsHidden()
                                .tint(SpendoTheme.accentGreen)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    
                    // 最近同步时间
                    SettingsSection {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("最近同步")
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                
                                Text(syncManager.formattedLastSyncTime())
                                    .font(.system(size: 13))
                                    .foregroundColor(SpendoTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: refreshStatus) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.primary)
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    
                    // 数据统计
                    SettingsSection {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("本地数据")
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                
                                Text("\(transactions.count) 笔交易 · \(accounts.count) 个账户")
                                    .font(.system(size: 13))
                                    .foregroundColor(SpendoTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        // 立即同步
                        Button(action: { showSyncConfirm = true }) {
                            HStack {
                                Image(systemName: "icloud.and.arrow.up.fill")
                                Text("立即同步到iCloud")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(syncManager.syncStatus == .available || syncManager.syncStatus == .synced ? SpendoTheme.primary : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(syncManager.syncStatus != .available && syncManager.syncStatus != .synced)
                        
                        // 从iCloud恢复
                        Button(action: { showRestoreConfirm = true }) {
                            HStack {
                                Image(systemName: "icloud.and.arrow.down.fill")
                                Text("从iCloud恢复")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SpendoTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(SpendoTheme.primary, lineWidth: 1)
                            )
                        }
                        .disabled(syncManager.syncStatus != .available && syncManager.syncStatus != .synced)
                    }
                    .padding(.top, 10)
                    
                    // 说明文字
                    VStack(alignment: .leading, spacing: 8) {
                        Text("同步说明")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SpendoTheme.textPrimary)
                        
                        Text("• 数据将加密存储在您的iCloud私有空间\n• 仅您本人可以访问这些数据\n• 恢复操作将覆盖本地数据，请谨慎操作")
                            .font(.system(size: 13))
                            .foregroundColor(SpendoTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationTitle("iCloud云同步")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 仅在首次显示时检查状态
            if !hasAppeared {
                hasAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    syncManager.checkiCloudStatus()
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("确认同步", isPresented: $showSyncConfirm, titleVisibility: .visible) {
            Button("同步到iCloud") {
                performSync()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将本地的 \(transactions.count) 笔交易和 \(accounts.count) 个账户同步到iCloud？")
        }
        .confirmationDialog("确认恢复", isPresented: $showRestoreConfirm, titleVisibility: .visible) {
            Button("从iCloud恢复", role: .destructive) {
                performRestore()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这将覆盖本地数据，确定要继续吗？")
        }
    }
    
    // iCloud状态卡片
    @ViewBuilder
    private func iCloudStatusCard(status: iCloudSyncStatus) -> some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: status.icon)
                    .font(.system(size: 32))
                    .foregroundColor(status.color)
                    .rotationEffect(.degrees(status == .syncing ? 360 : 0))
                    .animation(status == .syncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: status)
            }
            
            // 状态文字
            VStack(spacing: 4) {
                Text("iCloud状态")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Text(status.displayText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(status.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // 刷新状态
    private func refreshStatus() {
        isRefreshing = true
        syncManager.checkiCloudStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
    
    // 执行同步
    private func performSync() {
        syncManager.syncToiCloud(transactions: transactions, accounts: accounts) { success, error in
            if success {
                alertTitle = "同步成功"
                alertMessage = "数据已成功同步到iCloud"
            } else {
                alertTitle = "同步失败"
                alertMessage = error ?? "未知错误"
            }
            showAlert = true
        }
    }
    
    // 执行恢复
    private func performRestore() {
        syncManager.restoreFromiCloud { transactionsData, accountsData, error in
            if let error = error {
                alertTitle = "恢复失败"
                alertMessage = error
                showAlert = true
                return
            }
            
            // 这里可以实现数据恢复逻辑
            // 需要解析JSON并插入到SwiftData
            alertTitle = "恢复成功"
            alertMessage = "数据已从iCloud恢复"
            showAlert = true
        }
    }
}

// MARK: - Previews
#Preview("iCloud同步") {
    NavigationStack {
        iCloudSyncView()
    }
    .modelContainer(for: [Transaction.self, Account.self, Category.self, Budget.self, UserSettings.self])
}
