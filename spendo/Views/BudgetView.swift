//
//  BudgetView.swift
//  Spendo
//

import SwiftUI
import SwiftData

// MARK: - 存钱方法枚举
enum SavingMethod: String, Identifiable, CaseIterable {
    case fixed = "fixed"           // 定额存钱法
    case flexible = "flexible"     // 灵活存钱法
    case week52 = "week52"         // 52周存钱法
    case day365 = "day365"         // 365存钱法
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .fixed: return "定额存钱法"
        case .flexible: return "灵活存钱法"
        case .week52: return "52周存钱法"
        case .day365: return "365存钱法"
        }
    }
    
    var icon: String {
        switch self {
        case .fixed: return "square.stack.3d.up.fill"
        case .flexible: return "drop.fill"
        case .week52: return "52.circle.fill"
        case .day365: return "365.circle.fill"
        }
    }
    
    var iconText: String? {
        switch self {
        case .week52: return "52"
        case .day365: return "365"
        default: return nil
        }
    }
    
    var iconColor: Color {
        switch self {
        case .fixed: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .flexible: return Color(red: 0.3, green: 0.7, blue: 0.9)
        case .week52: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .day365: return Color(red: 0.3, green: 0.8, blue: 0.5)
        }
    }
    
    var description: String {
        switch self {
        case .fixed: return "每月固定存入相同金额，适合收入稳定的上班族，简单易坚持"
        case .flexible: return "根据每日/每周收支情况灵活存钱，有余钱就存，适合自由职业者"
        case .week52: return "第1周存10元，第2周存20元...第52周存520元，全年可存13780元"
        case .day365: return "第1天存1元，第2天存2元...第365天存365元，全年可存66795元"
        }
    }
    
    // 详细规则说明
    var detailedRules: [String] {
        switch self {
        case .fixed:
            return [
                "每月固定日期存入相同金额",
                "建议设置自动转账，避免遗忘",
                "金额根据收入的10%-30%设定",
                "坚持12个月可养成储蓄习惯"
            ]
        case .flexible:
            return [
                "每天或每周根据实际情况存钱",
                "有余钱就存，金额不限",
                "适合收入不稳定的人群",
                "记录每笔存款，培养理财意识"
            ]
        case .week52:
            return [
                "第1周存10元，第2周存20元",
                "每周递增10元，第52周存520元",
                "全年累计可存13,780元",
                "也可倒序存：第1周520元...递减"
            ]
        case .day365:
            return [
                "第1天存1元，第2天存2元",
                "每天递增1元，第365天存365元",
                "全年累计可存66,795元",
                "可随机打卡，不必按顺序存"
            ]
        }
    }
    
    // 预计年存款金额
    var estimatedYearlyAmount: Double {
        switch self {
        case .fixed: return 0 // 用户自定义
        case .flexible: return 0 // 用户自定义
        case .week52: return 13780
        case .day365: return 66795
        }
    }
    
    // 存款周期
    var period: String {
        switch self {
        case .fixed: return "每月"
        case .flexible: return "灵活"
        case .week52: return "每周"
        case .day365: return "每天"
        }
    }
}

// MARK: - 存钱方法网格
struct SavingMethodsGrid: View {
    @Binding var selectedMethod: SavingMethod?
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SavingMethod.allCases) { method in
                SavingMethodCard(method: method) {
                    selectedMethod = method
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 存钱方法卡片
struct SavingMethodCard: View {
    let method: SavingMethod
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // 图标
                ZStack {
                    Circle()
                        .fill(method.iconColor)
                        .frame(width: 36, height: 36)
                    
                    if let iconText = method.iconText {
                        Text(iconText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: method.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                Text(method.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(SpendoTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - 存钱方法详情视图
struct SavingMethodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let method: SavingMethod
    
    @State private var targetAmount: String = ""
    @State private var startDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 方法介绍
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(method.iconColor)
                                    .frame(width: 64, height: 64)
                                
                                if let iconText = method.iconText {
                                    Text(iconText)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: method.icon)
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(method.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Text(method.description)
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)
                        
                        // 规则说明
                        VStack(alignment: .leading, spacing: 12) {
                            Text("存钱规则")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SpendoTheme.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(method.detailedRules, id: \.self) { rule in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(SpendoTheme.accentGreen)
                                        
                                        Text(rule)
                                            .font(.system(size: 14))
                                            .foregroundColor(SpendoTheme.textPrimary)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(12)
                            
                            // 预计存款金额（仅对52周和365天显示）
                            if method.estimatedYearlyAmount > 0 {
                                HStack {
                                    Text("预计全年可存")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    Spacer()
                                    Text("¥\(method.estimatedYearlyAmount, specifier: "%.0f")")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(SpendoTheme.accentGreen)
                                }
                                .padding()
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 设置表单
                        VStack(spacing: 16) {
                            // 目标金额（仅对定额和灵活存钱法显示）
                            if method == .fixed || method == .flexible {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(method == .fixed ? "每月存款金额" : "目标金额")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    HStack {
                                        Text("¥")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(SpendoTheme.textPrimary)
                                        
                                        TextField("", text: $targetAmount, prompt: Text("0.00").foregroundColor(SpendoTheme.textTertiary))
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(SpendoTheme.textPrimary)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding()
                                    .background(SpendoTheme.cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // 开始日期
                            VStack(alignment: .leading, spacing: 8) {
                                Text("开始日期")
                                    .font(.system(size: 14))
                                    .foregroundColor(SpendoTheme.textSecondary)
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(SpendoTheme.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(SpendoTheme.cardBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 20)
                        
                        // 开始按钮
                        Button(action: {
                            // TODO: 创建存钱计划
                            dismiss()
                        }) {
                            Text("开始存钱")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(SpendoTheme.primary)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(method.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(SpendoTheme.textPrimary)
                }
            }
        }
    }
}

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @State private var showAddBudget = false
    @State private var selectedSavingMethod: SavingMethod?
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 存钱方法预设
                        SavingMethodsGrid(selectedMethod: $selectedSavingMethod)
                        
                        // 存钱目标列表
                        if budgets.isEmpty {
                            // 空状态视图
                            VStack(spacing: 16) {
                                Text("暂无数据")
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            VStack(spacing: 12) {
                                // 总预算
                                if let totalBudget = monthlyTotalBudget {
                                    BudgetCard(
                                        budget: totalBudget,
                                        spent: monthlyTotalSpent,
                                        categoryName: "总预算"
                                    )
                                }
                                
                                // 分类预算
                                ForEach(categoryBudgets) { budget in
                                    if let category = categories.first(where: { $0.id == budget.categoryId }) {
                                        BudgetCard(
                                            budget: budget,
                                            spent: getSpentAmount(for: budget),
                                            categoryName: category.name
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("存钱")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                                .foregroundColor(SpendoTheme.textPrimary)
                        }
                        
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(SpendoTheme.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }
            .sheet(item: $selectedSavingMethod) { method in
                SavingMethodDetailView(method: method)
            }
        }
    }
    
    private var monthlyTotalBudget: Budget? {
        let now = Date()
        return budgets.first { budget in
            budget.period == .monthly &&
            budget.categoryId == nil &&
            budget.startDate <= now &&
            budget.endDate >= now
        }
    }
    
    private var categoryBudgets: [Budget] {
        let now = Date()
        return budgets.filter { budget in
            budget.categoryId != nil &&
            budget.startDate <= now &&
            budget.endDate >= now
        }
    }
    
    private var monthlyTotalSpent: Double {
        let now = Date()
        return transactions.filter { transaction in
            transaction.type == .expense &&
            Calendar.current.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func getSpentAmount(for budget: Budget) -> Double {
        return transactions.filter { transaction in
            transaction.type == .expense &&
            transaction.categoryId == budget.categoryId &&
            transaction.date >= budget.startDate &&
            transaction.date <= budget.endDate
        }.reduce(0) { $0 + $1.amount }
    }
}

struct BudgetCard: View {
    let budget: Budget
    let spent: Double
    let categoryName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryName)
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(Int(progress * 100))% 已使用")
                        .font(.caption)
                        .foregroundColor(progressColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("¥\(spent, specifier: "%.0f")")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(progressColor)
                    Text("/ ¥\(budget.totalAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0))
                        .shadow(color: progressColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 12)
            
            if budget.totalAmount - spent > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("剩余 ¥\(budget.totalAmount - spent, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("已超出预算")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
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

struct AddBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    
    @State private var amount: String = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("金额") {
                    TextField("输入预算金额", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("周期") {
                    Picker("周期", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                }
                
                Section("类别(可选)") {
                    Picker("类别", selection: $selectedCategory) {
                        Text("总预算").tag(nil as Category?)
                        ForEach(categories.filter { $0.type == .expense }) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                }
                
                Section {
                    PrimaryGlowButton(title: "创建预算") {
                        saveBudget()
                    }
                    .disabled(amount.isEmpty)
                    .opacity(amount.isEmpty ? 0.6 : 1.0)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .background(Color.clear)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("添加预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount) else { return }
        
        let (startDate, endDate) = period.dateRange()
        
        let budget = Budget(
            period: period,
            totalAmount: amountValue,
            categoryId: selectedCategory?.id,
            startDate: startDate,
            endDate: endDate
        )
        
        modelContext.insert(budget)
        try? modelContext.save()
        dismiss()
    }
}

extension BudgetPeriod {
    func dateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .weekly:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
        case .monthly:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .yearly:
            let start = calendar.dateInterval(of: .year, for: now)!.start
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }
}

// MARK: - Previews
#Preview("存钱视图") {
    BudgetView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self, Account.self, UserSettings.self])
}

#Preview("存钱方法网格") {
    ZStack {
        SpendoTheme.background.ignoresSafeArea()
        SavingMethodsGrid(selectedMethod: .constant(nil))
    }
}

#Preview("存钱方法详情") {
    SavingMethodDetailView(method: .week52)
}
