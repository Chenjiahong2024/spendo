import SwiftUI

// MARK: - 顶部导航栏
struct DashboardHeaderView: View {
    @State private var showProfile = false
    
    var body: some View {
        HStack {
            // 排序按钮
            Button(action: {}) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(SpendoTheme.cardBackground)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 菜单按钮
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(SpendoTheme.cardBackground)
                    .clipShape(Circle())
            }
            
            // 头像 - 链接到个人主页
            Button(action: { showProfile = true }) {
                SharedAvatarView(size: 40)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

// MARK: - 账本标题和月份选择器
struct LedgerTitleView: View {
    @Binding var selectedDate: Date
    var onCalendarTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 账本名称
            Text("default_ledger".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(SpendoTheme.textPrimary)
            
            // 月份选择器
            HStack {
                Text(monthYearString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SpendoTheme.textSecondary)
                    }
                    
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SpendoTheme.textSecondary)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // 收支日历按钮
                Button(action: onCalendarTap) {
                    Text("收支日历")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: selectedDate)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - 总支出卡片（新设计）
struct ExpenseSummaryCard: View {
    let totalExpense: Double
    let totalIncome: Double
    let monthBalance: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 总支出标题
            HStack(spacing: 6) {
                Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(SpendoTheme.accentRed)
                
                Text("total_expense".localized)
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(SpendoTheme.textTertiary)
            }
            
            // 大额数字
            Text("¥\(totalExpense, specifier: "%.2f")")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(SpendoTheme.textPrimary)
            
            // 收入和月结余
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("total_income".localized)
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    Text("¥\(totalIncome, specifier: "%.2f")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SpendoTheme.accentGreen)
                }
                
                HStack(spacing: 4) {
                    Text("month_balance".localized)
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    Text("\(monthBalance >= 0 ? "" : "-")¥\(abs(monthBalance), specifier: "%.2f")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(monthBalance >= 0 ? SpendoTheme.accentGreen : SpendoTheme.accentRed)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(SpendoTheme.cornerRadiusLarge)
        .padding(.horizontal, 16)
    }
}

// MARK: - 日期分组头部
struct DateSectionHeader: View {
    let date: Date
    let totalExpense: Double
    @State private var isExpanded = true
    
    var body: some View {
        HStack {
            Text(dateString)
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\("expense".localized): ¥\(totalExpense, specifier: "%.2f")")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SpendoTheme.textTertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var dateString: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: date)) 今天"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: date)) 昨天"
        } else {
            formatter.dateFormat = "M/d EEEE"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 新交易行（匹配参考设计）
struct NewTransactionRow: View {
    let transaction: Transaction
    let categoryName: String
    let categoryIcon: String
    let accountName: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // 类别图标
            ZStack {
                Circle()
                    .fill(SpendoTheme.accentRed)
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    
                    if !transaction.note.isEmpty {
                        Text("·")
                            .foregroundColor(SpendoTheme.textTertiary)
                        Text(transaction.note)
                            .font(.system(size: 13))
                            .foregroundColor(SpendoTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 金额和账户
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .expense ? "-" : "+")¥\(transaction.amount, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.type == .expense ? SpendoTheme.accentRed : SpendoTheme.accentGreen)
                
                if let account = accountName {
                    Text(account)
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(SpendoTheme.cardBackground)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: transaction.date)
    }
}

// MARK: - 旧组件保留（兼容性）
struct PeriodSelectorView: View {
    @Binding var selectedPeriod: SpendoTimePeriod
    var animationNamespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SpendoTimePeriod.allCases, id: \.self) { period in
                PeriodButton(
                    period: period,
                    selectedPeriod: $selectedPeriod,
                    animationNamespace: animationNamespace
                )
            }
        }
        .padding(4)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

struct PeriodButton: View {
    let period: SpendoTimePeriod
    @Binding var selectedPeriod: SpendoTimePeriod
    var animationNamespace: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)) {
                selectedPeriod = period
            }
        }) {
            Text(period.displayName)
                .font(.system(size: 14, weight: selectedPeriod == period ? .bold : .medium))
                .foregroundColor(selectedPeriod == period ? .white : SpendoTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if selectedPeriod == period {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(SpendoTheme.primary)
                                .matchedGeometryEffect(id: "PeriodTab", in: animationNamespace)
                        }
                    }
                )
        }
    }
}

struct BalanceCardView: View {
    let selectedPeriod: SpendoTimePeriod
    let totalIncome: Double
    let totalExpense: Double
    
    var body: some View {
        ExpenseSummaryCard(
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            monthBalance: totalIncome - totalExpense
        )
    }
}

// MARK: - Previews
#Preview("顶部导航栏") {
    DashboardHeaderView()
        .background(SpendoTheme.background)
}

#Preview("支出摘要卡片") {
    ExpenseSummaryCard(
        totalExpense: 3256.80,
        totalIncome: 8500.00,
        monthBalance: 5243.20
    )
    .background(SpendoTheme.background)
}

#Preview("日期头部") {
    VStack(spacing: 0) {
        DateSectionHeader(date: Date(), totalExpense: 156.50)
        DateSectionHeader(date: Date().addingTimeInterval(-86400), totalExpense: 89.00)
    }
    .background(SpendoTheme.background)
}

#Preview("账本标题") {
    LedgerTitleView(selectedDate: .constant(Date()), onCalendarTap: {})
        .background(SpendoTheme.background)
}
