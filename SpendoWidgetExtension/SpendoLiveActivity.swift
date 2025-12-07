//
//  SpendoLiveActivity.swift
//  SpendoWidgetExtension
//
//  灵动岛实时活动
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
        var lastUpdateTime: Date      // 最后更新时间
    }
    
    // 静态内容（创建时确定）
    var periodName: String  // 时间段名称，如"本月"
}

// MARK: - 实时活动Widget
struct SpendoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendoActivityAttributes.self) { context in
            // 锁屏和通知中心视图
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开区域 - 左侧
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本月支出")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("¥\(context.state.monthExpense, specifier: "%.2f")")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 4)
                }
                
                // 展开区域 - 右侧
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("本月收入")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("¥\(context.state.monthIncome, specifier: "%.2f")")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.trailing, 4)
                }
                
                // 展开区域 - 底部
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // 本月结余
                        VStack(alignment: .leading, spacing: 2) {
                            Text("本月结余")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(formatBalance(context.state.monthBalance))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(context.state.monthBalance >= 0 ? .green : .red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 剩余月预算
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("剩余月预算")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(formatBalance(context.state.remainingBudget))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(context.state.remainingBudget >= 0 ? .green : .red)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 展开区域 - 中心
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Text("收支总览")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(context.attributes.periodName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
            } compactLeading: {
                // 紧凑模式 - 左侧（灵动岛左边）
                HStack(spacing: 4) {
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("本月支出")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } compactTrailing: {
                // 紧凑模式 - 右侧（灵动岛右边）
                Text("¥\(context.state.monthExpense, specifier: "%.2f")")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            } minimal: {
                // 最小模式（只显示图标）
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func formatBalance(_ value: Double) -> String {
        let prefix = value >= 0 ? "" : "-"
        return "\(prefix)¥\(abs(value), specifier: "%.2f")"
    }
}

// MARK: - 锁屏视图
struct LockScreenView: View {
    let context: ActivityViewContext<SpendoActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题行
            HStack {
                Text("收支总览")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(context.attributes.periodName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // 收支数据
            HStack(spacing: 16) {
                // 本月支出
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月支出")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("¥\(context.state.monthExpense, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 本月收入
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月收入")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("¥\(context.state.monthIncome, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 结余和预算
            HStack(spacing: 16) {
                // 本月结余
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月结余")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatBalance(context.state.monthBalance))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(context.state.monthBalance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 剩余月预算
                VStack(alignment: .leading, spacing: 4) {
                    Text("剩余月预算")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(formatBalance(context.state.remainingBudget))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(context.state.remainingBudget >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
    }
    
    private func formatBalance(_ value: Double) -> String {
        let prefix = value >= 0 ? "" : "-"
        return "\(prefix)¥\(abs(value), specifier: "%.2f")"
    }
}

// MARK: - 预览
#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: SpendoActivityAttributes(periodName: "本月")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 1292.27,
        monthIncome: 109.99,
        monthBalance: -1182.28,
        remainingBudget: -1292.27,
        lastUpdateTime: Date()
    )
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: SpendoActivityAttributes(periodName: "本月")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 1292.27,
        monthIncome: 109.99,
        monthBalance: -1182.28,
        remainingBudget: -1292.27,
        lastUpdateTime: Date()
    )
}

#Preview("Lock Screen", as: .content, using: SpendoActivityAttributes(periodName: "本月")) {
    SpendoLiveActivity()
} contentStates: {
    SpendoActivityAttributes.ContentState(
        monthExpense: 1292.27,
        monthIncome: 109.99,
        monthBalance: -1182.28,
        remainingBudget: -1292.27,
        lastUpdateTime: Date()
    )
}
