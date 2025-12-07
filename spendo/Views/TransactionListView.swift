//
//  TransactionListView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    
    @State private var selectedFilter: FilterType = .all
    @State private var searchText = ""
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                if filteredTransactions.isEmpty {
                    // 空状态视图
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(SpendoTheme.textTertiary)
                        Text("无账单记录")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(SpendoTheme.textSecondary)
                        Text("点击右下角 + 添加第一笔交易")
                            .font(.system(size: 14))
                            .foregroundColor(SpendoTheme.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                                // 日期头部
                                HStack {
                                    Text(formatSectionDate(date))
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("支出: ¥\(dailyExpense(for: date), specifier: "%.2f")")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                // 交易列表
                                ForEach(groupedTransactions[date] ?? []) { transaction in
                                    TransactionRow(transaction: transaction, categories: categories)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteTransaction(transaction)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("账单")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索交易")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(SpendoTheme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterView(selectedFilter: $selectedFilter)
            }
        }
    }
    
    private func dailyExpense(for date: Date) -> Double {
        (groupedTransactions[date] ?? [])
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var filteredTransactions: [Transaction] {
        var result = transactions
        
        // 应用筛选器
        switch selectedFilter {
        case .all:
            break
        case .expense:
            result = result.filter { $0.type == .expense }
        case .income:
            result = result.filter { $0.type == .income }
        }
        
        // 应用搜索
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.note.localizedCaseInsensitiveContains(searchText) ||
                categories.first { $0.id == transaction.categoryId }?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return result
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
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
    
    private func deleteTransaction(_ transaction: Transaction) {
        // 如果有关联账户，恢复余额
        if let accountId = transaction.accountId,
           let account = accounts.first(where: { $0.id == accountId }) {
            if transaction.type == .expense {
                account.balance += transaction.amount
            } else {
                account.balance -= transaction.amount
            }
            account.updatedAt = Date()
        }
        
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

// 交易行视图
struct TransactionRow: View {
    let transaction: Transaction
    let categories: [Category]
    @Query private var accounts: [Account]
    
    var body: some View {
        HStack(spacing: 12) {
            // 类别图标
            ZStack {
                Circle()
                    .fill(transaction.type == .expense ? SpendoTheme.accentRed : SpendoTheme.accentGreen)
                    .frame(width: 44, height: 44)
                
                Image(systemName: category?.iconName ?? "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "未分类")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                    
                    if let account = account {
                        Text("·")
                            .foregroundColor(SpendoTheme.textTertiary)
                        Text(account.name)
                            .font(.system(size: 13))
                            .foregroundColor(SpendoTheme.textTertiary)
                    }
                    
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
                
                if let account = account {
                    Text(account.name)
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
    
    private var category: Category? {
        categories.first { $0.id == transaction.categoryId }
    }
    
    private var account: Account? {
        accounts.first { $0.id == transaction.accountId }
    }
}

// 筛选视图
struct FilterView: View {
    @Binding var selectedFilter: FilterType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                List {
                    Section("交易类型") {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                dismiss()
                            }) {
                                HStack {
                                    Text(filter.displayName)
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    Spacer()
                                    if selectedFilter == filter {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(SpendoTheme.primary)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(SpendoTheme.primary)
                }
            }
        }
    }
}

enum FilterType: CaseIterable {
    case all
    case expense
    case income
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .expense: return "支出"
        case .income: return "收入"
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}
