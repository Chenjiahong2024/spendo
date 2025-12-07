//
//  AddTransactionView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    
    @State private var amount: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case voiceInput
        case ocrScanner
        
        var id: Int { hashValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                Form {
                    // 收入/支出切换
                    Section {
                        Picker("类型", selection: $type) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 金额输入
                    Section {
                        HStack {
                            Text("¥")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(type == .expense ? .red : .green)
                            
                            TextField("0.00", text: $amount)
                                .font(.system(size: 32, weight: .bold))
                                .keyboardType(.decimalPad)
                                .foregroundColor(type == .expense ? .red : .green)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("金额")
                    }
                    
                    // 类别选择
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filteredCategories) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("类别")
                    }
                    
                    // 账户选择
                    Section {
                        Picker("账户", selection: $selectedAccount) {
                            Text("未选择").tag(nil as Account?)
                            ForEach(accounts) { account in
                                HStack {
                                    Image(systemName: account.iconName)
                                    Text(account.name)
                                }
                                .tag(account as Account?)
                            }
                        }
                    } header: {
                        Text("账户")
                    }
                    
                    // 备注
                    Section {
                        TextField("添加备注", text: $note)
                    } header: {
                        Text("备注")
                    }
                    
                    // 日期
                    Section {
                        DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    } header: {
                        Text("日期时间")
                    }
                    
                    // 高级功能
                    Section {
                        HStack(spacing: 12) {
                            Button(action: { activeSheet = .voiceInput }) {
                                HStack(spacing: 6) {
                                    Text("语音记账")
                                        .font(.system(size: 15, weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(SpendoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(12)
                            }
                            
                            Button(action: { activeSheet = .ocrScanner }) {
                                HStack(spacing: 6) {
                                    Text("扫描小票")
                                        .font(.system(size: 15, weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(SpendoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("快捷输入")
                    }
                    
                    Section {
                        PrimaryGlowButton(title: "保存交易") {
                            saveTransaction()
                        }
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.6)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .background(Color.clear)
                        .padding(.vertical, 10)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .voiceInput:
                    VoiceInputView { recognizedText in
                        parseVoiceInput(recognizedText)
                    }
                case .ocrScanner:
                    OCRScannerView { receiptData in
                        applyReceiptData(receiptData)
                    }
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        categories.filter { $0.type == type }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return true
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            amount: amountValue,
            type: type,
            categoryId: selectedCategory?.id,
            accountId: selectedAccount?.id,
            date: date,
            note: note
        )
        
        modelContext.insert(transaction)
        
        // 更新账户余额
        if let account = selectedAccount {
            if type == .expense {
                account.balance -= amountValue
            } else {
                account.balance += amountValue
            }
            account.updatedAt = Date()
        }
        
        try? modelContext.save()
        
        // 更新实时活动
        updateLiveActivity()
        
        dismiss()
    }
    
    private func updateLiveActivity() {
        let budget = UserDefaults.standard.double(forKey: "monthlyBudget")
        
        Task {
            await LiveActivityManager.shared.updateFromTransactions(
                transactions,
                budget: budget > 0 ? budget : 5000
            )
        }
    }
    
    private func parseVoiceInput(_ text: String) {
        // 简单的语音输入解析逻辑
        // 例如:"午饭 50 块" 或 "Lunch 15 dollars"
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        
        if let firstNumber = Double(numbers.prefix(10)) {
            amount = String(format: "%.2f", firstNumber)
        }
        
        // 提取备注（去除数字部分）
        let noteText = text.replacingOccurrences(of: numbers, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !noteText.isEmpty {
            note = noteText
        }
        
        // 自动分类（简单的关键词匹配）
        if let autoCategory = AutoClassificationService.shared.suggestCategory(for: text, type: type, categories: categories) {
            selectedCategory = autoCategory
        }
    }
    
    // 应用小票识别结果
    private func applyReceiptData(_ data: ReceiptData) {
        // 设置金额
        if let receiptAmount = data.amount {
            amount = String(format: "%.2f", receiptAmount)
        }
        
        // 设置日期
        if let receiptDate = data.date {
            date = receiptDate
        }
        
        // 设置备注（商家 + 商品信息）
        var noteComponents: [String] = []
        if let merchant = data.merchant, !merchant.isEmpty {
            noteComponents.append(merchant)
        }
        if let receiptNote = data.note, !receiptNote.isEmpty {
            noteComponents.append(receiptNote)
        }
        if !noteComponents.isEmpty {
            note = noteComponents.joined(separator: " - ")
        }
        
        // 基于备注自动分类
        let combinedText = noteComponents.joined(separator: " ")
        if let autoCategory = AutoClassificationService.shared.suggestCategory(for: combinedText, type: type, categories: categories) {
            selectedCategory = autoCategory
        }
    }
}

// 类别按钮
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    )
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}
