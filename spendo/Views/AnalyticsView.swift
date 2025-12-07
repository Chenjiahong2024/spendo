//
//  AnalyticsView.swift
//  Spendo
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedTab: AnalyticsTab = .overview
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 周期选择器
                    Picker("周期", selection: $selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Tab切换
                    Picker("视图", selection: $selectedTab) {
                        Text("概览").tag(AnalyticsTab.overview)
                        Text("趋势").tag(AnalyticsTab.trend)
                        Text("洞察").tag(AnalyticsTab.insights)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 内容
                    if filteredTransactions.isEmpty {
                        // 空状态视图
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "chart.pie")
                                .font(.system(size: 60))
                                .foregroundColor(SpendoTheme.textTertiary)
                            Text("无统计数据")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(SpendoTheme.textSecondary)
                            Text("添加交易后即可查看统计分析")
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                switch selectedTab {
                                case .overview:
                                    OverviewAnalytics(transactions: filteredTransactions, categories: categories)
                                case .trend:
                                    TrendAnalytics(transactions: filteredTransactions, period: selectedPeriod)
                                case .insights:
                                    InsightsAnalytics(transactions: filteredTransactions, categories: categories)
                                }
                            }
                            .padding()
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationTitle("统计分析")
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let now = Date()
        return transactions.filter { transaction in
            selectedPeriod.contains(transaction.date, relativeTo: now)
        }
    }
}

// 概览分析
struct OverviewAnalytics: View {
    let transactions: [Transaction]
    let categories: [Category]
    
    var body: some View {
        VStack(spacing: 20) {
            // 收支对比
            HStack(spacing: 16) {
                AnalyticsCard(title: "总收入", amount: totalIncome, color: .green)
                AnalyticsCard(title: "总支出", amount: totalExpense, color: .red)
            }
            
            // Top支出类别
            TopCategoriesView(transactions: expenses, categories: categories, title: "Top 支出类别")
            
            // 类别饼图
            if !expenses.isEmpty {
                CategoryPieChart(transactions: expenses, categories: categories)
            }
        }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var expenses: [Transaction] {
        transactions.filter { $0.type == .expense }
    }
}

// 趋势分析
struct TrendAnalytics: View {
    let transactions: [Transaction]
    let period: AnalyticsPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("支出趋势")
                .font(.headline)
            
            if !dailyExpenses.isEmpty {
                Chart {
                    ForEach(dailyExpenses) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("金额", item.amount)
                        )
                        .foregroundStyle(Color.red)
                        
                        AreaMark(
                            x: .value("日期", item.date),
                            y: .value("金额", item.amount)
                        )
                        .foregroundStyle(Color.red.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: SpendoTheme.cornerRadiusMedium)
                .fill(SpendoTheme.cardBackground)
                .shadow(color: SpendoTheme.shadowColor, radius: 10, x: 0, y: 4)
        )
    }
    
    private var dailyExpenses: [DailyAmount] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        
        return grouped.map { date, trans in
            DailyAmount(date: date, amount: trans.reduce(0) { $0 + $1.amount })
        }.sorted { $0.date < $1.date }
    }
}

struct DailyAmount: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

// AI洞察
struct InsightsAnalytics: View {
    let transactions: [Transaction]
    let categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 洞察")
                .font(.headline)
            
            ForEach(insights, id: \.self) { insight in
                InsightCard(insight: insight)
            }
        }
    }
    
    private var insights: [String] {
        var result: [String] = []
        
        // 洞察1：最大支出类别
        if let topCategory = topExpenseCategory {
            let percentage = Int((topCategory.amount / totalExpense) * 100)
            result.append("本期\(topCategory.name)支出占总支出的 \(percentage)%")
        }
        
        // 洞察2：平均每日支出
        if !transactions.isEmpty {
            let avgDaily = totalExpense / Double(dayCount)
            result.append("平均每天支出 ¥\(String(format: "%.2f", avgDaily))")
        }
        
        // 洞察3：对比提示
        if totalExpense > totalIncome {
            result.append("⚠️ 本期支出超过收入 ¥\(String(format: "%.2f", totalExpense - totalIncome))")
        }
        
        return result
    }
    
    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var dayCount: Int {
        let dates = transactions.map { Calendar.current.startOfDay(for: $0.date) }
        return Set(dates).count
    }
    
    private var topExpenseCategory: (name: String, amount: Double)? {
        let expenses = transactions.filter { $0.type == .expense }
        var categoryAmounts: [UUID: Double] = [:]
        
        for transaction in expenses {
            if let categoryId = transaction.categoryId {
                categoryAmounts[categoryId, default: 0] += transaction.amount
            }
        }
        
        guard let topCategoryId = categoryAmounts.max(by: { $0.value < $1.value })?.key,
              let category = categories.first(where: { $0.id == topCategoryId }) else {
            return nil
        }
        
        return (category.name, categoryAmounts[topCategoryId]!)
    }
}

struct InsightCard: View {
    let insight: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            Text(insight)
                .font(.subheadline)
                .foregroundColor(SpendoTheme.textPrimary)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(SpendoTheme.cardBackground))
    }
}

struct AnalyticsCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(SpendoTheme.textSecondary)
            Text("¥\(amount, specifier: "%.2f")")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(SpendoTheme.cardBackground))
    }
}

struct TopCategoriesView: View {
    let transactions: [Transaction]
    let categories: [Category]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(SpendoTheme.textPrimary)
            
            ForEach(topCategories.prefix(5)) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(SpendoTheme.primary)
                    Text(item.name)
                        .foregroundColor(SpendoTheme.textPrimary)
                    Spacer()
                    Text("¥\(item.amount, specifier: "%.0f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SpendoTheme.accentRed)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(SpendoTheme.cardBackground))
    }
    
    private var topCategories: [CategoryAmount] {
        var categoryAmounts: [UUID: Double] = [:]
        
        for transaction in transactions {
            if let categoryId = transaction.categoryId {
                categoryAmounts[categoryId, default: 0] += transaction.amount
            }
        }
        
        return categoryAmounts.map { categoryId, amount in
            let category = categories.first { $0.id == categoryId }
            return CategoryAmount(
                id: categoryId,
                name: category?.name ?? "未分类",
                icon: category?.iconName ?? "questionmark",
                amount: amount
            )
        }.sorted { $0.amount > $1.amount }
    }
}

struct CategoryAmount: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let amount: Double
}

struct CategoryPieChart: View {
    let transactions: [Transaction]
    let categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("类别分布")
                .font(.headline)
                .foregroundColor(SpendoTheme.textPrimary)
            
            Chart(categoryData.prefix(8)) { item in
                SectorMark(
                    angle: .value("金额", item.amount),
                    innerRadius: .ratio(0.5)
                )
                .foregroundStyle(by: .value("类别", item.name))
            }
            .frame(height: 250)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(SpendoTheme.cardBackground))
    }
    
    private var categoryData: [CategoryData] {
        var dataDict: [UUID: Double] = [:]
        
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
                percentage: 0
            )
        }.sorted { $0.amount > $1.amount }
    }
}

enum AnalyticsPeriod: CaseIterable {
    case week, month, year
    
    var displayName: String {
        switch self {
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "本年"
        }
    }
    
    func contains(_ date: Date, relativeTo now: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

enum AnalyticsTab {
    case overview, trend, insights
}

// MARK: - Previews
#Preview("统计分析") {
    AnalyticsView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}

#Preview("分析卡片") {
    HStack(spacing: 16) {
        AnalyticsCard(title: "总收入", amount: 8500, color: .green)
        AnalyticsCard(title: "总支出", amount: 6200, color: .red)
    }
    .padding()
    .background(SpendoTheme.background)
}

#Preview("洞察卡片") {
    InsightCard(insight: "本期餐饮支出占总支出的 35%")
        .padding()
        .background(SpendoTheme.background)
}
