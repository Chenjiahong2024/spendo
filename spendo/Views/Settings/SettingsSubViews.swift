//
//  SettingsSubViews.swift
//  Spendo
//
//  设置页面的所有子视图
//

import SwiftUI
import SwiftData

// MARK: - 账单导出视图
struct BillExportView: View {
    @Query private var transactions: [Transaction]
    @State private var exportFormat: ExportFormat = .csv
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 导出格式
                    SettingsCard(title: "export_format".localized) {
                        Picker("格式", selection: $exportFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 日期范围
                    SettingsCard(title: "date_range".localized) {
                        VStack(spacing: 12) {
                            DatePicker("start".localized, selection: $startDate, displayedComponents: .date)
                            DatePicker("end".localized, selection: $endDate, displayedComponents: .date)
                        }
                    }
                    
                    // 统计信息
                    SettingsCard(title: "export_preview".localized) {
                        HStack {
                            Text("transaction_count".localized)
                                .foregroundColor(SpendoTheme.textSecondary)
                            Spacer()
                            Text("\(filteredTransactions.count) 笔")
                                .foregroundColor(SpendoTheme.textPrimary)
                        }
                    }
                    
                    // 导出按钮
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text("bill_export".localized)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SpendoTheme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                }
                .padding(16)
            }
        }
        .navigationTitle("bill_export".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private var filteredTransactions: [Transaction] {
        transactions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let content: String
            let fileName: String
            
            if exportFormat == .csv {
                content = generateCSV()
                fileName = "spendo_export_\(Date().formatted(.dateTime.year().month().day())).csv"
            } else {
                content = generateJSON()
                fileName = "spendo_export_\(Date().formatted(.dateTime.year().month().day())).json"
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try content.write(to: tempURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    exportedFileURL = tempURL
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    isExporting = false
                }
            }
        }
    }
    
    private func generateCSV() -> String {
        var csv = "日期,类型,金额,分类,备注\n"
        for transaction in filteredTransactions {
            let dateStr = transaction.date.formatted(.dateTime.year().month().day())
            let typeStr = transaction.type == .expense ? "支出" : "收入"
            csv += "\(dateStr),\(typeStr),\(transaction.amount),,\(transaction.note)\n"
        }
        return csv
    }
    
    private func generateJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = filteredTransactions.map { t in
            [
                "date": t.date.ISO8601Format(),
                "type": t.type == .expense ? "expense" : "income",
                "amount": String(t.amount),
                "note": t.note
            ]
        }
        
        if let data = try? encoder.encode(exportData),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }
}

// MARK: - 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 截图导入视图
struct ScreenshotImportView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var recognizedText = ""
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    
                    if isProcessing {
                        ProgressView("processing".localized)
                            .foregroundColor(SpendoTheme.textSecondary)
                    } else if !recognizedText.isEmpty {
                        Text(recognizedText)
                            .font(.system(size: 14))
                            .foregroundColor(SpendoTheme.textPrimary)
                            .padding()
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(SpendoTheme.textTertiary)
                        
                        Text("select_screenshot".localized)
                            .font(.system(size: 16))
                            .foregroundColor(SpendoTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text(selectedImage == nil ? "select".localized : "change".localized)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SpendoTheme.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("screenshot_import".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            SettingsImagePicker(image: $selectedImage)
        }
    }
}

// MARK: - 图片选择器（设置用）
struct SettingsImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SettingsImagePicker
        init(_ parent: SettingsImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 智能记账视图
struct SmartBookkeepingView: View {
    @AppStorage("autoCategorizationEnabled") private var autoCategorizationEnabled = true
    @AppStorage("autoNoteEnabled") private var autoNoteEnabled = true
    @AppStorage("smartReminderEnabled") private var smartReminderEnabled = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "智能分类") {
                        VStack(spacing: 12) {
                            Toggle("自动分类", isOn: $autoCategorizationEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("根据交易描述自动匹配最合适的分类")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    SettingsCard(title: "智能备注") {
                        VStack(spacing: 12) {
                            Toggle("自动备注", isOn: $autoNoteEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("根据历史记录自动填充备注")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    SettingsCard(title: "智能提醒") {
                        VStack(spacing: 12) {
                            Toggle("记账提醒", isOn: $smartReminderEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("智能分析消费习惯，在合适时机提醒记账")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("smart_accounting".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 灵动岛管理视图
struct DynamicIslandView: View {
    @Query private var transactions: [Transaction]
    @AppStorage("liveActivityEnabled") private var liveActivityEnabled = false
    @AppStorage("statsTimePeriod") private var statsTimePeriod = 0 // 0=本月收支
    @AppStorage("statsBook") private var statsBook = 0 // 0=全部账本
    @AppStorage("preferredDataType") private var preferredDataType = 0 // 0=支出
    @AppStorage("monthlyBudget") private var monthlyBudget = 5000.0
    
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    @State private var showTimePeriodPicker = false
    @State private var showBookPicker = false
    @State private var showDataTypePicker = false
    
    let timePeriods = ["本月收支", "本周收支", "今日收支", "本年收支"]
    let books = ["全部账本", "默认账本", "信用卡", "现金"]
    let dataTypes = ["支出", "收入", "结余"]
    
    // 计算本月数据
    private var monthStats: (expense: Double, income: Double, balance: Double) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthTransactions = transactions.filter { $0.date >= startOfMonth }
        let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        
        return (expense, income, income - expense)
    }
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // 实时活动状态
                    HStack {
                        Text("实时活动状态")
                            .font(.system(size: 16))
                            .foregroundColor(SpendoTheme.textPrimary)
                        
                        Spacer()
                        
                        Text(liveActivityManager.isSupported ? "可用" : "不可用")
                            .font(.system(size: 15))
                            .foregroundColor(liveActivityManager.isSupported ? SpendoTheme.accentGreen : SpendoTheme.textSecondary)
                    }
                    .padding(16)
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
                    
                    // 收支总览开关和设置
                    VStack(spacing: 0) {
                        // 收支总览开关
                        HStack {
                            Text("收支总览")
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $liveActivityEnabled)
                                .labelsHidden()
                                .tint(SpendoTheme.accentGreen)
                                .onChange(of: liveActivityEnabled) { _, newValue in
                                    handleActivityToggle(newValue)
                                }
                        }
                        .padding(16)
                        
                        if liveActivityEnabled {
                            Divider()
                                .background(SpendoTheme.textTertiary.opacity(0.2))
                                .padding(.leading, 16)
                            
                            // 统计时间段
                            Button(action: { showTimePeriodPicker = true }) {
                                HStack {
                                    Text("统计时间段")
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(timePeriods[statsTimePeriod])
                                        .font(.system(size: 15))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                                .padding(16)
                            }
                            
                            Divider()
                                .background(SpendoTheme.textTertiary.opacity(0.2))
                                .padding(.leading, 16)
                            
                            // 统计账本
                            Button(action: { showBookPicker = true }) {
                                HStack {
                                    Text("统计账本")
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(books[statsBook])
                                        .font(.system(size: 15))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                                .padding(16)
                            }
                            
                            Divider()
                                .background(SpendoTheme.textTertiary.opacity(0.2))
                                .padding(.leading, 16)
                            
                            // 偏好数据
                            Button(action: { showDataTypePicker = true }) {
                                HStack {
                                    Text("偏好数据")
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(dataTypes[preferredDataType])
                                        .font(.system(size: 15))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                                .padding(16)
                            }
                        }
                    }
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
                    
                    // 当前数据预览
                    if liveActivityEnabled {
                        VStack(spacing: 0) {
                            Text("当前数据预览")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            // 预览卡片
                            LiveActivityPreviewCard(
                                expense: monthStats.expense,
                                income: monthStats.income,
                                balance: monthStats.balance,
                                remainingBudget: monthlyBudget - monthStats.expense
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // 提示信息
                    if !liveActivityManager.isSupported {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(SpendoTheme.textTertiary)
                            Text("需要 iPhone 14 Pro 及以上机型支持灵动岛")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                        }
                        .padding()
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("dynamic_island".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTimePeriodPicker) {
            OptionPickerSheet(
                title: "统计时间段",
                options: timePeriods,
                selectedIndex: $statsTimePeriod
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showBookPicker) {
            OptionPickerSheet(
                title: "统计账本",
                options: books,
                selectedIndex: $statsBook
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showDataTypePicker) {
            OptionPickerSheet(
                title: "偏好数据",
                options: dataTypes,
                selectedIndex: $preferredDataType
            )
            .presentationDetents([.height(250)])
        }
        .onAppear {
            // 同步开关状态
            liveActivityEnabled = liveActivityManager.isActivityRunning
        }
    }
    
    private func handleActivityToggle(_ enabled: Bool) {
        if enabled {
            // 启动实时活动
            liveActivityManager.startActivity(
                monthExpense: monthStats.expense,
                monthIncome: monthStats.income,
                monthBalance: monthStats.balance,
                remainingBudget: monthlyBudget - monthStats.expense,
                periodName: "本月"
            )
        } else {
            // 结束实时活动
            Task {
                await liveActivityManager.endActivity()
            }
        }
    }
}

// MARK: - 实时活动预览卡片
struct LiveActivityPreviewCard: View {
    let expense: Double
    let income: Double
    let balance: Double
    let remainingBudget: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题
            HStack {
                Text("收支总览")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("本月")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // 收支数据
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月支出")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("¥\(expense, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月收入")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("¥\(income, specifier: "%.2f")")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 结余和预算
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月结余")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("\(balance >= 0 ? "" : "-")¥\(abs(balance), specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(balance >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("剩余月预算")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Text("\(remainingBudget >= 0 ? "" : "-")¥\(abs(remainingBudget), specifier: "%.2f")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(remainingBudget >= 0 ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Color.black)
        .cornerRadius(16)
    }
}

// MARK: - 选项选择器Sheet
struct OptionPickerSheet: View {
    let title: String
    let options: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { index in
                        Button(action: {
                            selectedIndex = index
                            dismiss()
                        }) {
                            HStack {
                                Text(options[index])
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                
                                Spacer()
                                
                                if selectedIndex == index {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(SpendoTheme.accentGreen)
                                }
                            }
                            .padding(16)
                        }
                        
                        if index < options.count - 1 {
                            Divider()
                                .background(SpendoTheme.textTertiary.opacity(0.2))
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(SpendoTheme.cardBackground)
                .cornerRadius(12)
                .padding(16)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(SpendoTheme.primary)
                }
            }
        }
    }
}

// MARK: - 周期管理视图
struct CycleManagementView: View {
    @AppStorage("billingCycleDay") private var billingCycleDay = 1
    @AppStorage("weekStartDay") private var weekStartDay = 1 // 1=周一, 7=周日
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "账单周期") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("每月账单开始日")
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textSecondary)
                            
                            Picker("账单日", selection: $billingCycleDay) {
                                ForEach(1...28, id: \.self) { day in
                                    Text("每月 \(day) 日").tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                    }
                    
                    SettingsCard(title: "每周开始") {
                        Picker("周开始", selection: $weekStartDay) {
                            Text("周一").tag(1)
                            Text("周日").tag(7)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("cycle_management".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 分期管理视图
struct InstallmentManagementView: View {
    @State private var installments: [InstallmentItem] = []
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            if installments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(SpendoTheme.textTertiary)
                    
                    Text("暂无分期账单")
                        .font(.system(size: 16))
                        .foregroundColor(SpendoTheme.textSecondary)
                    
                    Text("添加分期账单，自动生成每期还款提醒")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(installments) { item in
                    InstallmentRow(item: item)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("installment_management".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(SpendoTheme.primary)
                }
            }
        }
    }
}

struct InstallmentItem: Identifiable {
    let id = UUID()
    let name: String
    let totalAmount: Double
    let periods: Int
    let currentPeriod: Int
    let monthlyAmount: Double
}

struct InstallmentRow: View {
    let item: InstallmentItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SpendoTheme.textPrimary)
            
            HStack {
                Text("¥\(item.monthlyAmount, specifier: "%.2f")/期")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Spacer()
                
                Text("\(item.currentPeriod)/\(item.periods)")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 标签管理视图
struct TagManagementView: View {
    @State private var tags: [String] = ["日常", "工作", "旅行", "购物", "娱乐"]
    @State private var newTag = ""
    @State private var showAddAlert = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 标签列表
                    SettingsCard(title: "我的标签") {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                TagChip(text: tag) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                            
                            Button(action: { showAddAlert = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("添加")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(SpendoTheme.primary.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                    }
                    
                    // 说明
                    Text("标签可以帮助你更灵活地分类和筛选交易记录")
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textTertiary)
                        .padding(.horizontal, 16)
                }
                .padding(16)
            }
        }
        .navigationTitle("tag_management".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("添加标签", isPresented: $showAddAlert) {
            TextField("标签名称", text: $newTag)
            Button("取消", role: .cancel) { newTag = "" }
            Button("添加") {
                if !newTag.isEmpty && !tags.contains(newTag) {
                    tags.append(newTag)
                }
                newTag = ""
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 14))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textTertiary)
            }
        }
        .foregroundColor(SpendoTheme.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(SpendoTheme.cardBackgroundLight)
        .cornerRadius(16)
    }
}

// 简单的FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - 预算功能视图
struct BudgetSettingsView: View {
    @AppStorage("budgetAlertEnabled") private var budgetAlertEnabled = true
    @AppStorage("budgetAlertThreshold") private var budgetAlertThreshold = 80.0
    @AppStorage("showBudgetOnHome") private var showBudgetOnHome = true
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "预算提醒") {
                        VStack(spacing: 16) {
                            Toggle("启用预算提醒", isOn: $budgetAlertEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            if budgetAlertEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("预警阈值: \(Int(budgetAlertThreshold))%")
                                        .font(.system(size: 14))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Slider(value: $budgetAlertThreshold, in: 50...100, step: 5)
                                        .tint(SpendoTheme.primary)
                                }
                            }
                        }
                    }
                    
                    SettingsCard(title: "显示设置") {
                        Toggle("在首页显示预算", isOn: $showBudgetOnHome)
                            .tint(SpendoTheme.accentGreen)
                    }
                    
                    NavigationLink(destination: BudgetView()) {
                        HStack {
                            Text("管理预算")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(SpendoTheme.textTertiary)
                        }
                        .foregroundColor(SpendoTheme.textPrimary)
                        .padding()
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("budget_feature".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 报销功能视图
struct ReimbursementView: View {
    @State private var pendingItems: [ReimbursementItem] = []
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            if pendingItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(SpendoTheme.textTertiary)
                    
                    Text("暂无待报销账单")
                        .font(.system(size: 16))
                        .foregroundColor(SpendoTheme.textSecondary)
                    
                    Text("记账时标记为待报销的账单会显示在这里")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(pendingItems) { item in
                    ReimbursementRow(item: item)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("reimbursement".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReimbursementItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let date: Date
    let status: String
}

struct ReimbursementRow: View {
    let item: ReimbursementItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.system(size: 16))
                Text(item.date.formatted(.dateTime.month().day()))
                    .font(.system(size: 13))
                    .foregroundColor(SpendoTheme.textSecondary)
            }
            
            Spacer()
            
            Text("¥\(item.amount, specifier: "%.2f")")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SpendoTheme.primary)
        }
    }
}

// MARK: - 设置卡片组件
struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SpendoTheme.textSecondary)
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SpendoTheme.cardBackground)
        .cornerRadius(12)
    }
}
