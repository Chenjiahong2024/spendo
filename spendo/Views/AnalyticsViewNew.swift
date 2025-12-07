//
//  AnalyticsViewNew.swift
//  Spendo
//
//  重新设计的统计视图
//

import SwiftUI
import SwiftData
import Charts

// MARK: - 时间筛选枚举
enum StatsPeriod: String, CaseIterable {
    case week = "stats_week"
    case month = "stats_month"
    case year = "stats_year"
    case all = "stats_all"
    case custom = "stats_range"
    
    var displayName: String {
        return rawValue.localized
    }
}

// MARK: - 分类数据模型
struct CategoryStatsData: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let amount: Double
    let count: Int
    let percentage: Double
}

// MARK: - 统计视图
struct AnalyticsViewNew: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var selectedPeriod: StatsPeriod = .all
    @State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showExpense = true  // true=支出, false=收入
    @State private var showAllCategories = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 时间筛选器
                        periodSelector
                        
                        // 日期范围
                        dateRangeSelector
                        
                        // 收支统计卡片
                        incomeExpenseStatsCard
                        
                        // 报销统计
                        reimbursementCard
                        
                        // 流转统计
                        transferCard
                        
                        // 分类详情
                        categoryDetailSection
                        
                        // 账单汇总
                        billSummarySection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("tab_stats".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("filter".localized) {
                        // 筛选操作
                    }
                    .foregroundColor(SpendoTheme.textPrimary)
                }
            }
        }
    }
    
    // MARK: - 时间选择器
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button(action: { 
                    selectedPeriod = period
                    updateDateRange(for: period)
                }) {
                    Text(period.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : SpendoTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPeriod == period ? SpendoTheme.primary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - 日期范围选择器
    private var dateRangeSelector: some View {
        HStack {
            DateButton(date: startDate, label: "start".localized)
            
            Text("~")
                .foregroundColor(SpendoTheme.textSecondary)
            
            DateButton(date: endDate, label: "end".localized)
        }
    }
    
    // MARK: - 收支统计卡片
    private var incomeExpenseStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("income_expense_stats".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(SpendoTheme.textTertiary)
                    .font(.system(size: 14))
            }
            
            // 支出和收入
            HStack(spacing: 20) {
                StatValueColumn(label: "expense".localized, value: totalExpense, color: SpendoTheme.textPrimary, showArrow: true)
                StatValueColumn(label: "income".localized, value: totalIncome, color: SpendoTheme.textPrimary, showArrow: true)
            }
            
            // 结余和年均支出
            HStack(spacing: 20) {
                StatValueColumn(
                    label: "结余",
                    value: abs(balance),
                    color: balance >= 0 ? SpendoTheme.accentGreen : SpendoTheme.accentRed,
                    showArrow: true,
                    prefix: balance >= 0 ? "" : "-"
                )
                StatValueColumn(label: "年均支出", value: averageYearlyExpense, color: SpendoTheme.textPrimary, showArrow: true)
            }
        }
        .padding(16)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - 报销统计
    private var reimbursementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("报销统计")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(SpendoTheme.textTertiary)
                    .font(.system(size: 14))
            }
            
            HStack(spacing: 20) {
                StatValueColumn(label: "待报销", value: 0, color: SpendoTheme.textPrimary, showArrow: true)
                StatValueColumn(label: "报销入账", value: 0, color: SpendoTheme.textPrimary, showArrow: true)
            }
        }
        .padding(16)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - 流转统计
    private var transferCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.purple)
                Text("流转统计")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(SpendoTheme.textTertiary)
                    .font(.system(size: 14))
            }
            
            HStack(spacing: 20) {
                StatValueColumn(label: "还款", value: 0, color: SpendoTheme.textPrimary, showArrow: true)
                StatValueColumn(label: "收款", value: 0, color: SpendoTheme.textPrimary, showArrow: true)
            }
        }
        .padding(16)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - 分类详情
    private var categoryDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                Text(showExpense ? "支出分类详情" : "收入分类详情")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Button("全部分类") {
                    // 查看全部分类
                }
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            }
            
            // 环形图
            if !categoryStats.isEmpty {
                CategoryDonutChart(
                    data: categoryStats,
                    totalAmount: showExpense ? totalExpense : totalIncome,
                    isExpense: showExpense
                )
                .frame(height: 280)
                .id(showExpense) // 强制刷新
                .animation(.easeInOut(duration: 0.3), value: showExpense)
            } else {
                // 无分类数据时显示提示
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundColor(SpendoTheme.textTertiary)
                    Text("暂无\(showExpense ? "支出" : "收入")分类数据")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
            
            // 支出/收入切换
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button(action: { showExpense = true }) {
                        Text("支出")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(showExpense ? .white : SpendoTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(showExpense ? SpendoTheme.cardBackgroundLight : Color.clear)
                            .cornerRadius(6)
                    }
                    
                    Button(action: { showExpense = false }) {
                        Text("收入")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(!showExpense ? .white : SpendoTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(!showExpense ? SpendoTheme.cardBackgroundLight : Color.clear)
                            .cornerRadius(6)
                    }
                }
                .background(SpendoTheme.cardBackground)
                .cornerRadius(8)
                Spacer()
            }
            
            // 分类列表
            if !categoryStats.isEmpty {
                VStack(spacing: 0) {
                    let displayCategories = showAllCategories ? categoryStats : Array(categoryStats.prefix(5))
                    ForEach(displayCategories) { item in
                        CategoryStatsRow(data: item)
                        
                        if item.id != displayCategories.last?.id {
                            Divider()
                                .background(SpendoTheme.textTertiary.opacity(0.2))
                        }
                    }
                }
                .id(showExpense) // 强制刷新
                
                // 展开全部按钮
                if categoryStats.count > 5 {
                    Button(action: { showAllCategories.toggle() }) {
                        Text(showAllCategories ? "收起" : "展开全部")
                            .font(.system(size: 14))
                            .foregroundColor(SpendoTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .padding(16)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - 账单汇总
    private var billSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.orange)
                Text("账单汇总 (CNY)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Button("显示结余颜色") {
                    // 切换颜色
                }
                .font(.system(size: 12))
                .foregroundColor(SpendoTheme.textSecondary)
            }
            
            // 表头
            HStack {
                Text("日期")
                    .frame(width: 60, alignment: .leading)
                Text("支出")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("收入")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("结余")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 13))
            .foregroundColor(SpendoTheme.textSecondary)
            
            Divider().background(SpendoTheme.textTertiary.opacity(0.3))
            
            // 总计行
            BillSummaryRow(
                label: "总计",
                expense: totalExpense,
                income: totalIncome,
                balance: balance
            )
            
            // 年均行
            BillSummaryRow(
                label: "年均",
                expense: averageYearlyExpense,
                income: averageYearlyIncome,
                balance: averageYearlyBalance
            )
            
            // 按年分组
            ForEach(yearlyStats.sorted(by: { $0.key > $1.key }), id: \.key) { year, stats in
                BillSummaryRow(
                    label: "\(year)",
                    expense: stats.expense,
                    income: stats.income,
                    balance: stats.income - stats.expense
                )
            }
            
            // 分享按钮
            Button(action: {}) {
                HStack {
                    Text("分享当前页面")
                        .font(.system(size: 14))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(SpendoTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - 计算属性
    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
    }
    
    private var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpense
    }
    
    private var yearCount: Int {
        let years = Set(filteredTransactions.map { Calendar.current.component(.year, from: $0.date) })
        return max(years.count, 1)
    }
    
    private var averageYearlyExpense: Double {
        totalExpense / Double(yearCount)
    }
    
    private var averageYearlyIncome: Double {
        totalIncome / Double(yearCount)
    }
    
    private var averageYearlyBalance: Double {
        balance / Double(yearCount)
    }
    
    private var yearlyStats: [Int: (expense: Double, income: Double)] {
        var stats: [Int: (expense: Double, income: Double)] = [:]
        for transaction in filteredTransactions {
            let year = Calendar.current.component(.year, from: transaction.date)
            var current = stats[year] ?? (expense: 0, income: 0)
            if transaction.type == .expense {
                current.expense += transaction.amount
            } else {
                current.income += transaction.amount
            }
            stats[year] = current
        }
        return stats
    }
    
    private var categoryStats: [CategoryStatsData] {
        let targetTransactions = filteredTransactions.filter { 
            showExpense ? $0.type == .expense : $0.type == .income 
        }
        let total = targetTransactions.reduce(0) { $0 + $1.amount }
        
        // 使用可选UUID作为key，nil表示未分类
        var categoryAmounts: [UUID?: (amount: Double, count: Int)] = [:]
        
        for transaction in targetTransactions {
            let categoryId = transaction.categoryId // 可能为nil
            var current = categoryAmounts[categoryId] ?? (amount: 0, count: 0)
            current.amount += transaction.amount
            current.count += 1
            categoryAmounts[categoryId] = current
        }
        
        let colors: [Color] = [.green, .blue, .orange, .purple, .pink, .cyan, .yellow, .red]
        
        return categoryAmounts.enumerated().map { index, item in
            let category = item.key != nil ? categories.first { $0.id == item.key } : nil
            return CategoryStatsData(
                id: item.key ?? UUID(), // 未分类使用新的UUID
                name: category?.name ?? "未分类",
                icon: category?.iconName ?? "questionmark",
                color: colors[index % colors.count],
                amount: item.value.amount,
                count: item.value.count,
                percentage: total > 0 ? (item.value.amount / total) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - 方法
    private func updateDateRange(for period: StatsPeriod) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            endDate = now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            endDate = now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            endDate = now
        case .all:
            startDate = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            endDate = now
        case .custom:
            // 保持当前选择
            break
        }
    }
}

// MARK: - 日期按钮
struct DateButton: View {
    let date: Date
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(date.formatted(.dateTime.year().month().day()))
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textPrimary)
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(SpendoTheme.textTertiary)
        }
    }
}

// MARK: - 统计数值列
struct StatValueColumn: View {
    let label: String
    let value: Double
    let color: Color
    var showArrow: Bool = false
    var prefix: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(SpendoTheme.textSecondary)
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
            
            Text("\(prefix)¥\(value, specifier: "%.2f")")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 环形图
struct CategoryDonutChart: View {
    let data: [CategoryStatsData]
    let totalAmount: Double
    let isExpense: Bool
    
    var body: some View {
        ZStack {
            // 环形图
            Chart(data) { item in
                SectorMark(
                    angle: .value("金额", item.amount),
                    innerRadius: .ratio(0.65),
                    angularInset: 1
                )
                .foregroundStyle(item.color)
            }
            
            // 中心文字
            VStack(spacing: 4) {
                Text(isExpense ? "总支出" : "总收入")
                    .font(.system(size: 12))
                    .foregroundColor(SpendoTheme.textSecondary)
                Text("¥\(totalAmount, specifier: "%.2f")")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(SpendoTheme.textPrimary)
            }
            
            // 标注
            ForEach(data.prefix(3)) { item in
                let angle = angleFor(item)
                let labelPosition = labelPositionFor(angle: angle, radius: 140)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(item.name) \(item.percentage, specifier: "%.1f")%")
                        .font(.system(size: 10))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
                .offset(x: labelPosition.x, y: labelPosition.y)
            }
        }
    }
    
    private func angleFor(_ item: CategoryStatsData) -> Double {
        let total = data.reduce(0) { $0 + $1.amount }
        var currentAngle: Double = 0
        
        for d in data {
            if d.id == item.id {
                return currentAngle + (d.amount / total * 180)
            }
            currentAngle += d.amount / total * 360
        }
        return 0
    }
    
    private func labelPositionFor(angle: Double, radius: CGFloat) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        return CGPoint(
            x: CGFloat(Foundation.cos(radians)) * radius,
            y: CGFloat(Foundation.sin(radians)) * radius
        )
    }
}

// MARK: - 分类统计行
struct CategoryStatsRow: View {
    let data: CategoryStatsData
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(data.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: data.icon)
                    .font(.system(size: 16))
                    .foregroundColor(data.color)
            }
            
            // 名称和百分比
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(data.name)
                        .font(.system(size: 15))
                        .foregroundColor(SpendoTheme.textPrimary)
                    Text("\(data.percentage, specifier: "%.2f")%")
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // 金额和笔数
            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(data.amount, specifier: "%.2f")")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                Text("\(data.count)笔")
                    .font(.system(size: 12))
                    .foregroundColor(SpendoTheme.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(SpendoTheme.textTertiary)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 账单汇总行
struct BillSummaryRow: View {
    let label: String
    let expense: Double
    let income: Double
    let balance: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textPrimary)
                .frame(width: 60, alignment: .leading)
            
            Text("¥\(expense, specifier: "%.2f")")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("¥\(income, specifier: "%.2f")")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text("\(balance >= 0 ? "" : "-")¥\(abs(balance), specifier: "%.2f")")
                .font(.system(size: 13))
                .foregroundColor(balance >= 0 ? SpendoTheme.accentGreen : SpendoTheme.accentRed)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
#Preview("统计视图") {
    AnalyticsViewNew()
        .modelContainer(for: [Transaction.self, Category.self, Account.self])
}
