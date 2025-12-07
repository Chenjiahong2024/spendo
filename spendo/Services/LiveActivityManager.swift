//
//  LiveActivityManager.swift
//  Spendo
//
//  灵动岛实时活动管理器 - 完善版
//

import Foundation
import ActivityKit
import SwiftUI
import SwiftData
import Combine

// MARK: - 实时活动属性定义（需要与Widget Extension共享）
struct SpendoActivityAttributes: ActivityAttributes {
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
    
    var periodName: String      // 时间段名称
    var currencySymbol: String  // 货币符号
}

// MARK: - 实时活动管理器
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var isActivityRunning = false
    @Published var currentActivity: Activity<SpendoActivityAttributes>?
    
    private init() {
        // 检查是否有正在运行的活动
        checkForExistingActivity()
    }
    
    // MARK: - 检查设备是否支持
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    // MARK: - 检查现有活动
    private func checkForExistingActivity() {
        for activity in Activity<SpendoActivityAttributes>.activities {
            currentActivity = activity
            isActivityRunning = true
            break
        }
    }
    
    // MARK: - 启动实时活动
    func startActivity(
        monthExpense: Double,
        monthIncome: Double,
        monthBalance: Double,
        remainingBudget: Double,
        budgetTotal: Double = 0,
        todayExpense: Double = 0,
        transactionCount: Int = 0,
        periodName: String = "本月",
        currencySymbol: String = "¥"
    ) {
        guard isSupported else {
            print("设备不支持实时活动")
            return
        }
        
        // 如果已有活动在运行，先结束它
        if isActivityRunning {
            Task {
                await endActivity()
                // 稍等后再启动新活动
                try? await Task.sleep(nanoseconds: 500_000_000)
                await startNewActivity(
                    monthExpense: monthExpense,
                    monthIncome: monthIncome,
                    monthBalance: monthBalance,
                    remainingBudget: remainingBudget,
                    budgetTotal: budgetTotal,
                    todayExpense: todayExpense,
                    transactionCount: transactionCount,
                    periodName: periodName,
                    currencySymbol: currencySymbol
                )
            }
        } else {
            Task {
                await startNewActivity(
                    monthExpense: monthExpense,
                    monthIncome: monthIncome,
                    monthBalance: monthBalance,
                    remainingBudget: remainingBudget,
                    budgetTotal: budgetTotal,
                    todayExpense: todayExpense,
                    transactionCount: transactionCount,
                    periodName: periodName,
                    currencySymbol: currencySymbol
                )
            }
        }
    }
    
    private func startNewActivity(
        monthExpense: Double,
        monthIncome: Double,
        monthBalance: Double,
        remainingBudget: Double,
        budgetTotal: Double,
        todayExpense: Double,
        transactionCount: Int,
        periodName: String,
        currencySymbol: String
    ) async {
        let attributes = SpendoActivityAttributes(
            periodName: periodName,
            currencySymbol: currencySymbol
        )
        let contentState = SpendoActivityAttributes.ContentState(
            monthExpense: monthExpense,
            monthIncome: monthIncome,
            monthBalance: monthBalance,
            remainingBudget: remainingBudget,
            budgetTotal: budgetTotal,
            todayExpense: todayExpense,
            transactionCount: transactionCount,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            
            currentActivity = activity
            isActivityRunning = true
            print("实时活动已启动: \(activity.id)")
        } catch {
            print("启动实时活动失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 更新实时活动
    func updateActivity(
        monthExpense: Double,
        monthIncome: Double,
        monthBalance: Double,
        remainingBudget: Double,
        budgetTotal: Double = 0,
        todayExpense: Double = 0,
        transactionCount: Int = 0
    ) async {
        guard let activity = currentActivity else {
            print("没有正在运行的实时活动")
            return
        }
        
        let contentState = SpendoActivityAttributes.ContentState(
            monthExpense: monthExpense,
            monthIncome: monthIncome,
            monthBalance: monthBalance,
            remainingBudget: remainingBudget,
            budgetTotal: budgetTotal,
            todayExpense: todayExpense,
            transactionCount: transactionCount,
            lastUpdateTime: Date()
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        await activity.update(activityContent)
        print("实时活动已更新")
    }
    
    // MARK: - 结束实时活动
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalContent = SpendoActivityAttributes.ContentState(
            monthExpense: 0,
            monthIncome: 0,
            monthBalance: 0,
            remainingBudget: 0,
            budgetTotal: 0,
            todayExpense: 0,
            transactionCount: 0,
            lastUpdateTime: Date()
        )
        
        await activity.end(
            ActivityContent(state: finalContent, staleDate: nil),
            dismissalPolicy: .immediate
        )
        
        currentActivity = nil
        isActivityRunning = false
        print("实时活动已结束")
    }
    
    // MARK: - 结束所有活动
    func endAllActivities() async {
        for activity in Activity<SpendoActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        isActivityRunning = false
    }
}

// MARK: - 与交易数据集成的扩展
extension LiveActivityManager {
    /// 根据交易数据更新实时活动
    func updateFromTransactions(
        _ transactions: [Transaction],
        budget: Double = 0,
        currencySymbol: String = "¥"
    ) async {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfToday = calendar.startOfDay(for: now)
        
        // 计算本月数据
        let monthTransactions = transactions.filter { $0.date >= startOfMonth }
        
        let monthExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let monthIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        // 计算今日支出
        let todayExpense = transactions
            .filter { $0.date >= startOfToday && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let monthBalance = monthIncome - monthExpense
        let remainingBudget = budget > 0 ? budget - monthExpense : monthBalance
        let transactionCount = monthTransactions.count
        
        if isActivityRunning {
            await updateActivity(
                monthExpense: monthExpense,
                monthIncome: monthIncome,
                monthBalance: monthBalance,
                remainingBudget: remainingBudget,
                budgetTotal: budget,
                todayExpense: todayExpense,
                transactionCount: transactionCount
            )
        }
    }
    
    /// 启动并从交易数据初始化实时活动
    func startFromTransactions(
        _ transactions: [Transaction],
        budget: Double = 0,
        currencySymbol: String = "¥"
    ) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfToday = calendar.startOfDay(for: now)
        
        // 计算本月数据
        let monthTransactions = transactions.filter { $0.date >= startOfMonth }
        
        let monthExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let monthIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        // 计算今日支出
        let todayExpense = transactions
            .filter { $0.date >= startOfToday && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let monthBalance = monthIncome - monthExpense
        let remainingBudget = budget > 0 ? budget - monthExpense : monthBalance
        let transactionCount = monthTransactions.count
        
        startActivity(
            monthExpense: monthExpense,
            monthIncome: monthIncome,
            monthBalance: monthBalance,
            remainingBudget: remainingBudget,
            budgetTotal: budget,
            todayExpense: todayExpense,
            transactionCount: transactionCount,
            periodName: "本月",
            currencySymbol: currencySymbol
        )
    }
}
