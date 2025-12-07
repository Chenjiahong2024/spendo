//
//  ProfileView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var accounts: [Account]
    
    @State private var showExportAlert = false
    @State private var exportMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头像和用户名
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(SpendoTheme.textSecondary)
                            
                            Text("ledger_title".localized)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Text("my_ledger".localized)
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textTertiary)
                        }
                        .padding(.top, 20)
                        
                        // 统计卡片
                        HStack(spacing: 12) {
                            StatisticCard(
                                title: "total".localized,
                                value: "\(transactions.count)",
                                icon: "list.bullet.rectangle",
                                color: SpendoTheme.primary
                            )
                            
                            StatisticCard(
                                title: "account".localized,
                                value: "\(accounts.count)",
                                icon: "creditcard",
                                color: SpendoTheme.accentGreen
                            )
                        }
                        .padding(.horizontal)
                        
                        // 更多统计
                        HStack(spacing: 12) {
                            StatisticCard(
                                title: "total_expense".localized,
                                value: "¥\(String(format: "%.0f", totalExpense))",
                                icon: "arrow.down.circle",
                                color: SpendoTheme.accentRed
                            )
                            
                            StatisticCard(
                                title: "total_income".localized,
                                value: "¥\(String(format: "%.0f", totalIncome))",
                                icon: "arrow.up.circle",
                                color: SpendoTheme.accentGreen
                            )
                        }
                        .padding(.horizontal)
                        
                        // 功能列表
                        VStack(spacing: 0) {
                            NavigationLink(destination: TransactionListView()) {
                                ProfileMenuItemContent(
                                    icon: "clock.arrow.circlepath",
                                    title: "recent_transactions".localized,
                                    color: .blue
                                )
                            }
                            
                            Divider()
                                .background(SpendoTheme.cardBackgroundLight)
                            
                            NavigationLink(destination: AnalyticsView()) {
                                ProfileMenuItemContent(
                                    icon: "chart.pie",
                                    title: "category_stats".localized,
                                    color: .purple
                                )
                            }
                            
                            Divider()
                                .background(SpendoTheme.cardBackgroundLight)
                            
                            NavigationLink(destination: ReminderSettingsView()) {
                                ProfileMenuItemContent(
                                    icon: "bell",
                                    title: "提醒设置",
                                    color: .orange
                                )
                            }
                            
                            Divider()
                                .background(SpendoTheme.cardBackgroundLight)
                            
                            Button(action: exportData) {
                                ProfileMenuItemContent(
                                    icon: "square.and.arrow.up",
                                    title: "export_data".localized,
                                    color: .green
                                )
                            }
                        }
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(SpendoTheme.cornerRadiusLarge)
                        .padding(.horizontal)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("home".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(SpendoTheme.textPrimary)
                    }
                }
            }
            .alert("export_data".localized, isPresented: $showExportAlert) {
                Button("confirm".localized, role: .cancel) {}
            } message: {
                Text(exportMessage)
            }
        }
    }
    
    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private func exportData() {
        var csvString = "日期,类型,金额,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for transaction in transactions {
            let dateString = dateFormatter.string(from: transaction.date)
            let typeString = transaction.type == .expense ? "支出" : "收入"
            csvString += "\(dateString),\(typeString),\(transaction.amount),\(transaction.note)\n"
        }
        
        // 复制到剪贴板
        UIPasteboard.general.string = csvString
        exportMessage = "已导出 \(transactions.count) 条记录到剪贴板"
        showExportAlert = true
    }
}

// 统计卡片
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(SpendoTheme.textPrimary)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(SpendoTheme.cornerRadiusMedium)
    }
}

// 菜单项内容（用于 NavigationLink 和 Button）
struct ProfileMenuItemContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(SpendoTheme.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// 提醒设置视图
struct ReminderSettingsView: View {
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    
    var body: some View {
        ZStack {
            SpendoTheme.background
                .ignoresSafeArea()
            
            List {
                Section {
                    Toggle("每日记账提醒", isOn: $dailyReminderEnabled)
                        .tint(SpendoTheme.primary)
                } footer: {
                    Text("开启后，每天会在设定时间提醒你记账")
                        .foregroundColor(SpendoTheme.textTertiary)
                }
                
                if dailyReminderEnabled {
                    Section("提醒时间") {
                        DatePicker(
                            "时间",
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Section {
                    Toggle("预算超支提醒", isOn: .constant(true))
                        .tint(SpendoTheme.primary)
                    
                    Toggle("大额支出提醒", isOn: .constant(false))
                        .tint(SpendoTheme.primary)
                } header: {
                    Text("其他提醒")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("提醒设置")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 20
                reminderMinute = components.minute ?? 0
            }
        )
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}
