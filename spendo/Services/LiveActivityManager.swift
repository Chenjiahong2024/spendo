//
//  LiveActivityManager.swift
//  Spendo
//
//  灵动岛实时活动管理器
//

import Foundation
import ActivityKit
import SwiftUI
import SwiftData
import Combine

// MARK: - 实时活动属性定义（需要与Widget Extension共享）
struct SpendoActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var monthExpense: Double
        var monthIncome: Double
        var monthBalance: Double
        var remainingBudget: Double
        var lastUpdateTime: Date
    }
    
    var periodName: String
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
        periodName: String = "本月"
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
                    periodName: periodName
                )
            }
        } else {
            Task {
                await startNewActivity(
                    monthExpense: monthExpense,
                    monthIncome: monthIncome,
                    monthBalance: monthBalance,
                    remainingBudget: remainingBudget,
                    periodName: periodName
                )
            }
        }
    }
    
    private func startNewActivity(
        monthExpense: Double,
        monthIncome: Double,
        monthBalance: Double,
        remainingBudget: Double,
        periodName: String
    ) async {
        let attributes = SpendoActivityAttributes(periodName: periodName)
        let contentState = SpendoActivityAttributes.ContentState(
            monthExpense: monthExpense,
            monthIncome: monthIncome,
            monthBalance: monthBalance,
            remainingBudget: remainingBudget,
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
        remainingBudget: Double
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
    func updateFromTransactions(_ transactions: [Transaction], budget: Double = 0) async {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // 计算本月数据
        let monthTransactions = transactions.filter { $0.date >= startOfMonth }
        
        let monthExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let monthIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let monthBalance = monthIncome - monthExpense
        let remainingBudget = budget - monthExpense
        
        if isActivityRunning {
            await updateActivity(
                monthExpense: monthExpense,
                monthIncome: monthIncome,
                monthBalance: monthBalance,
                remainingBudget: remainingBudget
            )
        }
    }
}
