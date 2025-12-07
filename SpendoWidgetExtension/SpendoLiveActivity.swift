//
//  SpendoLiveActivity.swift
//  SpendoWidgetExtension
//
//  灵动岛实时活动 - 完善版
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - 实时活动属性定义
struct SpendoActivityAttributes: ActivityAttributes {
    // 动态内容（可更新）
    public struct ContentState: Codable, Hashable {
        var monthExpense: Double      // 本月支出
        var monthIncome: Double       // 本月收入
        var monthBalance: Double      // 本月结余
        var remainingBudget: Double   // 剩余预算
        var budgetTotal: Double       // 总预算
        var todayExpense: Double      // 今日支出
        var transactionCount: Int     // 本月交易笔数
        var lastUpdateTime: Date      // 最后更新时间
        
        // 计算预算使用百分比
        var budgetProgress: Double {
            guard budgetTotal > 0 else { return 0 }
            return min(monthExpense / budgetTotal, 1.0)
        }
        
        // 预算状态颜色
        var budgetStatusColor: Color {
            let progress = budgetProgress
            if progress < 0.6 { return .green }
            else if progress < 0.85 { return .orange }
            else { return .red }
        }
    }
    
    // 静态内容（创建时确定）
    var periodName: String  // 时间段名称，如"本月"
    var currencySymbol: String  // 货币符号
}

// MARK: - 实时活动Widget
struct SpendoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendoActivityAttributes.self) { context in
            // 锁屏和通知中心视图
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开区域 - 左侧：本月支出
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text("本月支出")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Text("\(context.attributes.currencySymbol)\(context.state.monthExpense, specifier: "%.2f")")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    }
                    .padding(.leading, 4)
                }
                
                // 展开区域 - 右侧：本月收入
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("本月收入")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                        Text("\(context.attributes.currencySymbol)\(context.state.monthIncome, specifier: "%.2f")")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                            .contentTransition(.numericText())
                    }
                    .padding(.trailing, 4)
                }
                
                // 展开区域 - 底部：预算进度和统计
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        // 预算进度条
                        if context.state.budgetTotal > 0 {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("预算使用")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(context.state.budgetProgress * 100))%")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(context.state.budgetStatusColor)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(context.state.budgetStatusColor)
                                            .frame(width: geometry.size.width * context.state.budgetProgress, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        
                        // 统计数据行
                        HStack(spacing: 0) {
                            // 今日支出
                            VStack(spacing: 2) {
                                Text("今日")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("\(context.attributes.currencySymbol)\(context.state.todayExpense, specifier: "%.0f")")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 分隔线
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1, height: 28)
                            
                            // 本月结余
                            VStack(spacing: 2) {
                                Text("结余")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(formatCompactBalance(context.state.monthBalance, symbol: context.attributes.currencySymbol))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(context.state.monthBalance >= 0 ? .green : .red)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 分隔线
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1, height: 28)
                            
                            // 交易笔数
                            VStack(spacing: 2) {
                                Text("交易")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("\(context.state.transactionCount)笔")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 4)
                }
                
                // 展开区域 - 中心：标题
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("Spendo")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(context.attributes.periodName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
            } compactLeading: {
                // 紧凑模式 - 左侧：App图标和今日支出标签
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "yensign")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("今日")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } compactTrailing: {
                // 紧凑模式 - 右侧：今日支出金额
                Text("\(context.attributes.currencySymbol)\(context.state.todayExpense, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            } minimal: {
                // 最小模式：带渐变的圆形图标
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Image(systemName: "yensign")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatCompactBalance(_ value: Double, symbol: String) -> String {
        let absValue = abs(value)
        let prefix = value >= 0 ? "" : "-"
        if absValue >= 10000 {
            return "\(prefix)\(symbol)\(absValue/10000, specifier: "%.1f")万"
        } else if absValue >= 1000 {
            return "\(prefix)\(symbol)\(absValue/1000, specifier: "%.1f")k"
        } else {
            return "\(prefix)\(symbol)\(absValue, specifier: "%.0f")"
        }
    }
}

// MARK: - 锁屏视图
struct LockScreenView: View {
    let context: ActivityViewContext<SpendoActivityAttributes>
    
    var body: some View {
        VStack(spacing: 14) {
            // 标题行
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "yensign")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Spendo")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(context.attributes.periodName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
            }
            
            // 主要收支数据
            HStack(spacing: 16) {
                // 本月支出
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("本月支出")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text("\(context.attributes.currencySymbol)\(context.state.monthExpense, specifier: "%.2f")")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 本月收入
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("本月收入")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text("\(context.attributes.currencySymbol)\(context.state.monthIncome, specifier: "%.2f")")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 预算进度条
            if context.state.budgetTotal > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("预算使用")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(context.attributes.currencySymbol)\(context.state.monthExpense, specifier: "%.0f") / \(context.attributes.currencySymbol)\(context.state.budgetTotal, specifier: "%.0f")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(context.state.budgetStatusColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: context.state.budgetProgress < 0.6 
                                        ? [.green, .green.opacity(0.8)]
                                        : context.state.budgetProgress < 0.85 
                                            ? [.orange, .yellow]
                                            : [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * context.state.budgetProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            
            // 底部统计行
            HStack(spacing: 0) {
                // 今日支出
                VStack(spacing: 4) {
                    Text("今日支出")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(context.attributes.currencySymbol)\(context.state.todayExpense, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 32)
                
                // 本月结余
                VStack(spacing: 4) {
                    Text("本月结余")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatBalance(context.state.monthBalance, symbol: context.attributes.currencySymbol))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(context.state.monthBalance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 32)
                
                // 交易笔数
                VStack(spacing: 4) {
                    Text("交易笔数")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(context.state.transactionCount)笔")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func formatBalance(_ value: Double, symbol: String) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(symbol)\(abs(value), specifier: "%.2f")"
    }
}

// MARK: - 预览
#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: SpendoActivityAttributes(periodName: "本月", currencySymbol: "¥")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 3580.50,
        monthIncome: 8500.00,
        monthBalance: 4919.50,
        remainingBudget: 1419.50,
        budgetTotal: 5000.00,
        todayExpense: 128.00,
        transactionCount: 47,
        lastUpdateTime: Date()
    )
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: SpendoActivityAttributes(periodName: "本月", currencySymbol: "¥")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 3580.50,
        monthIncome: 8500.00,
        monthBalance: 4919.50,
        remainingBudget: 1419.50,
        budgetTotal: 5000.00,
        todayExpense: 128.00,
        transactionCount: 47,
        lastUpdateTime: Date()
    )
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: SpendoActivityAttributes(periodName: "本月", currencySymbol: "¥")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 3580.50,
        monthIncome: 8500.00,
        monthBalance: 4919.50,
        remainingBudget: 1419.50,
        budgetTotal: 5000.00,
        todayExpense: 128.00,
        transactionCount: 47,
        lastUpdateTime: Date()
    )
}

#Preview("Lock Screen", as: .content, using: SpendoActivityAttributes(periodName: "本月", currencySymbol: "¥")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 3580.50,
        monthIncome: 8500.00,
        monthBalance: 4919.50,
        remainingBudget: 1419.50,
        budgetTotal: 5000.00,
        todayExpense: 128.00,
        transactionCount: 47,
        lastUpdateTime: Date()
    )
}

#Preview("Lock Screen - Over Budget", as: .content, using: SpendoActivityAttributes(periodName: "本月", currencySymbol: "¥")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 5800.00,
        monthIncome: 5000.00,
        monthBalance: -800.00,
        remainingBudget: -800.00,
        budgetTotal: 5000.00,
        todayExpense: 350.00,
        transactionCount: 62,
        lastUpdateTime: Date()
    )
}
