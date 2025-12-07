//
//  AccountsView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var showAddAccount = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 净资产卡片
                        NetWorthCard(
                            netWorth: totalBalance,
                            totalAssets: totalAssets,
                            totalLiabilities: totalLiabilities
                        )
                        
                        // 收支统计
                        IncomeExpenseCard(totalIncome: 0, totalExpense: 0)
                        
                        // 账户列表
                        if accounts.isEmpty {
                            EmptyAccountsView()
                        } else {
                            AccountListSection(
                                accounts: accounts,
                                onDelete: deleteAccount
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("资产")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showAddAccount = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SpendoTheme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AccountTypeSelectionView()
            }
        }
    }
    
    private var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    private var totalAssets: Double {
        accounts.filter { $0.balance >= 0 }.reduce(0) { $0 + $1.balance }
    }
    
    private var totalLiabilities: Double {
        abs(accounts.filter { $0.balance < 0 }.reduce(0) { $0 + $1.balance })
    }
    
    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
        try? modelContext.save()
    }
}

// MARK: - 净资产卡片
struct NetWorthCard: View {
    let netWorth: Double
    let totalAssets: Double
    let totalLiabilities: Double
    @State private var showBalance = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 净资产
            HStack {
                Text("净资产")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Button(action: { showBalance.toggle() }) {
                    Image(systemName: showBalance ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
            
            Text(showBalance ? "¥\(netWorth, specifier: "%.2f")" : "****")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(SpendoTheme.textPrimary)
            
            // 资产和负债
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("总资产")
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    Text(showBalance ? "¥\(totalAssets, specifier: "%.2f")" : "****")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SpendoTheme.textPrimary)
                }
                
                HStack(spacing: 4) {
                    Text("总负债")
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    Text(showBalance ? "¥\(totalLiabilities, specifier: "%.2f")" : "****")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SpendoTheme.accentRed)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(SpendoTheme.cornerRadiusLarge)
    }
}

// MARK: - 收支统计卡片
struct IncomeExpenseCard: View {
    let totalIncome: Double
    let totalExpense: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // 总收入
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SpendoTheme.accentGreen.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SpendoTheme.accentGreen)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("总收入")
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textSecondary)
                    Text("¥\(totalIncome, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SpendoTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SpendoTheme.cardBackground)
            .cornerRadius(SpendoTheme.cornerRadiusMedium)
            
            // 总支出
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SpendoTheme.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SpendoTheme.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("总支出")
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textSecondary)
                    Text("¥\(totalExpense, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SpendoTheme.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SpendoTheme.cardBackground)
            .cornerRadius(SpendoTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - 空账户视图
struct EmptyAccountsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 50))
                .foregroundColor(SpendoTheme.textTertiary)
            Text("暂无账户")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SpendoTheme.textSecondary)
            Text("点击左上角 + 添加账户")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 账户列表
struct AccountListSection: View {
    let accounts: [Account]
    let onDelete: (Account) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("资金账户 (\(accounts.count))")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("余额: ¥\(accounts.reduce(0) { $0 + $1.balance }, specifier: "%.2f")")
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)
            
            // 账户列表
            VStack(spacing: 0) {
                ForEach(accounts) { account in
                    NewAccountRow(account: account)
                        .swipeActions {
                            Button(role: .destructive) {
                                onDelete(account)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    
                    if account.id != accounts.last?.id {
                        Divider()
                            .background(SpendoTheme.textTertiary.opacity(0.3))
                            .padding(.leading, 64)
                    }
                }
            }
            .background(SpendoTheme.cardBackground)
            .cornerRadius(SpendoTheme.cornerRadiusMedium)
        }
    }
}

// MARK: - 新账户行样式
struct NewAccountRow: View {
    let account: Account
    
    // 安全获取图标背景色
    private var iconBgColor: Color {
        let hex = account.iconBgColorHex
        return hex.isEmpty ? .blue : Color(hex: hex)
    }
    
    // 安全获取图标颜色
    private var iconColor: Color {
        let hex = account.iconColorHex
        return hex.isEmpty ? .white : Color(hex: hex)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: account.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // 名称和副标题
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                if let subtitle = account.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
            
            Spacer()
            
            // 余额
            Text(account.balance >= 0 ? "¥\(account.balance, specifier: "%.2f")" : "-¥\(abs(account.balance), specifier: "%.2f")")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(account.balance >= 0 ? SpendoTheme.textPrimary : SpendoTheme.accentRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - 账户类型选择视图
struct AccountTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: AccountPreset?
    @State private var showAddAccountDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 资金账户分类
                        ForEach(AccountPresetCategory.allCases, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 0) {
                                // 分类标题
                                HStack {
                                    Text(category.displayName)
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                // 预设列表
                                VStack(spacing: 0) {
                                    ForEach(AccountPresets.presets(for: category)) { preset in
                                        PresetAccountRow(preset: preset) {
                                            selectedPreset = preset
                                            showAddAccountDetail = true
                                        }
                                        
                                        if preset.id != AccountPresets.presets(for: category).last?.id {
                                            Divider()
                                                .background(SpendoTheme.textTertiary.opacity(0.2))
                                                .padding(.leading, 64)
                                        }
                                    }
                                }
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(SpendoTheme.cornerRadiusMedium)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("选择类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SpendoTheme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddAccountDetail) {
                if let preset = selectedPreset {
                    AddAccountDetailView(preset: preset)
                }
            }
        }
    }
}

// MARK: - 预设账户行
struct PresetAccountRow: View {
    let preset: AccountPreset
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 图标
                ZStack {
                    Circle()
                        .fill(preset.iconBackgroundColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: preset.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(preset.iconColor)
                }
                
                // 名称
                Text(preset.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - 添加账户详情视图
struct AddAccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let preset: AccountPreset
    
    @State private var accountName: String = ""
    @State private var initialBalance: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 预设图标预览
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(preset.iconBackgroundColor)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: preset.iconName)
                                .font(.system(size: 32))
                                .foregroundColor(preset.iconColor)
                        }
                        
                        Text(preset.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SpendoTheme.textPrimary)
                    }
                    .padding(.top, 20)
                    
                    // 表单
                    VStack(spacing: 16) {
                        // 账户名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("账户名称")
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textSecondary)
                            
                            TextField("", text: $accountName, prompt: Text(preset.name).foregroundColor(SpendoTheme.textTertiary))
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                                .padding()
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(12)
                        }
                        
                        // 初始余额
                        VStack(alignment: .leading, spacing: 8) {
                            Text("初始余额")
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textSecondary)
                            
                            HStack {
                                Text("¥")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                
                                TextField("", text: $initialBalance, prompt: Text("0.00").foregroundColor(SpendoTheme.textTertiary))
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 创建按钮
                    Button(action: saveAccount) {
                        Text("创建账户")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SpendoTheme.primary)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("添加账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(SpendoTheme.textPrimary)
                }
            }
            .onAppear {
                accountName = preset.name
            }
        }
    }
    
    private func saveAccount() {
        let balance = Double(initialBalance) ?? 0.0
        let name = accountName.isEmpty ? preset.name : accountName
        
        let account = Account(from: preset, balance: balance, customName: name)
        
        modelContext.insert(account)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Previews
#Preview("账户列表") {
    AccountsView()
        .modelContainer(for: [Account.self, Transaction.self, Category.self, Budget.self, UserSettings.self])
}

#Preview("净资产卡片") {
    NetWorthCard(netWorth: 12345.67, totalAssets: 15000, totalLiabilities: 2654.33)
        .padding()
        .background(SpendoTheme.background)
}

#Preview("添加账户") {
    AccountTypeSelectionView()
        .modelContainer(for: [Account.self])
}
