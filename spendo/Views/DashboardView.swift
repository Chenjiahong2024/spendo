//
//  DashboardView.swift
//  Spendo
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    
    @State private var selectedDate: Date = Date()
    @Namespace private var animationNamespace
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 纯黑背景
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 顶部导航栏
                        DashboardHeaderView()
                            .padding(.top, 8)
                        
                        // 账本标题和月份选择器
                        LedgerTitleView(
                            selectedDate: $selectedDate,
                            onCalendarTap: {}
                        )
                        .padding(.top, 16)
                        
                        // 总支出卡片
                        ExpenseSummaryCard(
                            totalExpense: monthExpenses,
                            totalIncome: monthIncome,
                            monthBalance: monthIncome - monthExpenses
                        )
                        .padding(.top, 20)
                        
                        // 交易列表（按日期分组）
                        if monthTransactions.isEmpty {
                            // 空状态视图
                            VStack(spacing: 16) {
                                Spacer().frame(height: 60)
                                Image(systemName: "tray")
                                    .font(.system(size: 50))
                                    .foregroundColor(SpendoTheme.textTertiary)
                                Text("本月无交易记录")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(SpendoTheme.textSecondary)
                                Text("点击右下角 + 开始记账")
                                    .font(.system(size: 13))
                                    .foregroundColor(SpendoTheme.textTertiary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                ForEach(groupedTransactionsByDay.keys.sorted(by: >), id: \.self) { date in
                                    Section {
                                        // 日期头部
                                        DateSectionHeader(
                                            date: date,
                                            totalExpense: dailyExpense(for: date)
                                        )
                                        
                                        // 交易列表
                                        ForEach(groupedTransactionsByDay[date] ?? []) { transaction in
                                            NewTransactionRow(
                                                transaction: transaction,
                                                categoryName: categoryName(for: transaction),
                                                categoryIcon: categoryIcon(for: transaction),
                                                accountName: accountName(for: transaction)
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                        
                        // 底部留白
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 当月交易筛选
    private var monthTransactions: [Transaction] {
        transactions.filter { transaction in
            Calendar.current.isDate(transaction.date, equalTo: selectedDate, toGranularity: .month)
        }
    }
    
    // MARK: - 按日期分组
    private var groupedTransactionsByDay: [Date: [Transaction]] {
        Dictionary(grouping: monthTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    // MARK: - 月支出
    private var monthExpenses: Double {
        monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - 月收入
    private var monthIncome: Double {
        monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - 某日支出
    private func dailyExpense(for date: Date) -> Double {
        (groupedTransactionsByDay[date] ?? [])
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - 辅助方法
    private func categoryName(for transaction: Transaction) -> String {
        categories.first { $0.id == transaction.categoryId }?.name ?? "未分类"
    }
    
    private func categoryIcon(for transaction: Transaction) -> String {
        categories.first { $0.id == transaction.categoryId }?.iconName ?? "questionmark.circle"
    }
    
    private func accountName(for transaction: Transaction) -> String? {
        guard let accountId = transaction.accountId else { return nil }
        return accounts.first { $0.id == accountId }?.name
    }
}

// 注意：OverviewCards 结构体在上面的新设计中被内联替代了，可以删除或保留备用。
// 下面保留其他组件


// 统计卡片
struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(SpendoTheme.textSecondary)
                Spacer()
            }
            
            Text("¥\(amount, specifier: "%.2f")")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: isWide ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: SpendoTheme.cornerRadiusLarge)
                .fill(SpendoTheme.cardBackground)
        )
    }
}

// 预算进度卡片
struct BudgetProgressCard: View {
    let budget: Budget
    let spent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(SpendoTheme.accentOrange)
                Text("本月预算")
                    .font(.headline)
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Text("¥\(spent, specifier: "%.0f") / ¥\(budget.totalAmount, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(SpendoTheme.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SpendoTheme.cardBackgroundLight)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(Int(progress * 100))% 已使用")
                    .font(.caption)
                    .foregroundColor(SpendoTheme.textTertiary)
                Spacer()
                Text("剩余 ¥\(max(budget.totalAmount - spent, 0), specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(SpendoTheme.textTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SpendoTheme.cornerRadiusLarge)
                .fill(SpendoTheme.cardBackground)
        )
    }
    
    private var progress: Double {
        budget.totalAmount > 0 ? spent / budget.totalAmount : 0
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

// 支出分类饼图
struct ExpenseByCategoryChart: View {
    let transactions: [Transaction]
    let categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支出分类")
                .font(.headline)
                .foregroundColor(SpendoTheme.textPrimary)
                .padding(.horizontal)
            
            if categoryData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(SpendoTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart(categoryData) { item in
                    SectorMark(
                        angle: .value("金额", item.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("类别", item.name))
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // 图例
                VStack(spacing: 8) {
                    ForEach(categoryData.prefix(5)) { item in
                        HStack {
                            Circle()
                                .fill(SpendoTheme.accentOrange)
                                .frame(width: 10, height: 10)
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(SpendoTheme.textPrimary)
                            Spacer()
                            Text("¥\(item.amount, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(SpendoTheme.textSecondary)
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(SpendoTheme.textTertiary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: SpendoTheme.cornerRadiusLarge)
                .fill(SpendoTheme.cardBackground)
        )
    }
    
    private var categoryData: [CategoryData] {
        var dataDict: [UUID: Double] = [:]
        let total = transactions.reduce(0) { $0 + $1.amount }
        
        for transaction in transactions {
            if let categoryId = transaction.categoryId {
                dataDict[categoryId, default: 0] += transaction.amount
            }
        }
        
        return dataDict.map { categoryId, amount in
            let category = categories.first { $0.id == categoryId }
            return CategoryData(
                id: categoryId,
                name: category?.name ?? "未分类",
                amount: amount,
                percentage: total > 0 ? (amount / total) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }
}

struct CategoryData: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let percentage: Double
}

// 最近交易
struct RecentTransactionsSection: View {
    let transactions: [Transaction]
    @Query private var categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.headline)
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                NavigationLink("查看全部") {
                    TransactionListView()
                }
                .font(.subheadline)
                .foregroundColor(SpendoTheme.textSecondary)
            }
            .padding(.horizontal)
            
            if transactions.isEmpty {
                Text("暂无交易记录")
                    .foregroundColor(SpendoTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction, categories: categories)
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: SpendoTheme.cornerRadiusLarge)
                .fill(SpendoTheme.cardBackground)
        )
    }
}

// 时间周期枚举


#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}
