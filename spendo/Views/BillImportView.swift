//
//  BillImportView.swift
//  Spendo
//
//  账单导入视图
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - 账单导入主视图
struct BillImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    
    @State private var selectedSource: BillImportSource?
    @State private var selectedFileURL: URL?
    @State private var selectedFileName = ""
    @State private var selectedAccountId: UUID?
    @State private var identifyByTailNumber = true
    
    @State private var showSourcePicker = false
    @State private var showFilePicker = false
    @State private var showImportPreview = false
    @State private var showTemplateInfo = false
    
    @State private var importResult: BillImportResult?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        mainContent
            .navigationTitle("bill_import".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSourcePicker) { sourcePickerSheet }
            .sheet(isPresented: $showFilePicker) { filePickerSheet }
            .sheet(isPresented: $showImportPreview) { previewSheet }
            .sheet(isPresented: $showTemplateInfo) { templateSheet }
            .alert("import_error".localized, isPresented: $showError) {
                Button("confirm".localized, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "未知错误")
            }
            .overlay { processingOverlay }
    }
    
    // MARK: - 主内容
    private var mainContent: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    templateButtonsSection
                    instructionText
                    fileSelectionSection
                    sourceSelectionSection
                    accountSelectionSection
                    optionsSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - 模板按钮区
    private var templateButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("记录与模板")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            
            HStack(spacing: 12) {
                ImportActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "导入记录",
                    color: SpendoTheme.primary
                ) { }
                
                ImportActionButton(
                    icon: "sparkles",
                    title: "下载模板文件",
                    color: .orange
                ) { showTemplateInfo = true }
            }
        }
    }
    
    private var instructionText: some View {
        Text("请按步骤顺序操作")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(SpendoTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }
    
    // MARK: - 文件选择
    private var fileSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择数据文件 (xlsx/xls/csv)")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            
            SettingsRowButton(
                title: "文件路径",
                value: selectedFileName.isEmpty ? "点此选择" : selectedFileName,
                valueColor: selectedFileName.isEmpty ? SpendoTheme.textSecondary : SpendoTheme.primary
            ) { showFilePicker = true }
        }
    }
    
    // MARK: - 来源选择
    private var sourceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择导入来源")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            
            SettingsRowButton(
                title: "导入来源",
                value: selectedSource?.displayName ?? "点此选择",
                valueColor: selectedSource != nil ? SpendoTheme.primary : SpendoTheme.textSecondary
            ) { showSourcePicker = true }
        }
    }
    
    // MARK: - 账户选择
    private var accountSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择账户或账本")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            
            SettingsRowButton(
                title: "关联账本",
                value: "默认账本",
                valueColor: SpendoTheme.textSecondary
            ) { }
        }
    }
    
    // MARK: - 其他选项
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("其他选项")
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
            
            HStack {
                Text("根据尾号识别账户")
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Toggle("", isOn: $identifyByTailNumber)
                    .labelsHidden()
                    .tint(SpendoTheme.accentGreen)
            }
            .padding()
            .background(SpendoTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - 工具栏
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("解析") { parseFile() }
                .foregroundColor(canParse ? SpendoTheme.primary : SpendoTheme.textTertiary)
                .disabled(!canParse)
        }
    }
    
    // MARK: - Sheets
    private var sourcePickerSheet: some View {
        BillSourcePickerView(selectedSource: $selectedSource)
            .presentationDetents([.medium, .large])
    }
    
    private var filePickerSheet: some View {
        DocumentPicker(selectedURL: $selectedFileURL, selectedFileName: $selectedFileName)
    }
    
    @ViewBuilder
    private var previewSheet: some View {
        if let result = importResult {
            BillImportPreviewView(
                result: result,
                categories: Array(categories),
                defaultAccountId: selectedAccountId
            ) { transactions in
                importTransactions(transactions)
            }
        }
    }
    
    private var templateSheet: some View {
        TemplateInfoView()
            .presentationDetents([.medium])
    }
    
    // MARK: - 处理中遮罩
    @ViewBuilder
    private var processingOverlay: some View {
        if isProcessing {
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView("解析中...")
                    .padding()
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 计算属性
    private var canParse: Bool {
        selectedFileURL != nil && selectedSource != nil
    }
    
    // MARK: - 方法
    private func parseFile() {
        guard let url = selectedFileURL, let source = selectedSource else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "BillImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法访问文件"])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let result = try BillImportService.shared.parseCSV(from: url, source: source)
                
                DispatchQueue.main.async {
                    isProcessing = false
                    if result.transactions.isEmpty {
                        errorMessage = "未能解析出任何有效记录，请检查文件格式是否正确"
                        showError = true
                    } else {
                        importResult = result
                        showImportPreview = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = "解析失败: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func importTransactions(_ transactions: [ImportedTransaction]) {
        BillImportService.shared.importTransactions(
            transactions,
            context: modelContext,
            categories: Array(categories),
            defaultAccountId: selectedAccountId ?? accounts.first?.id
        )
        dismiss()
    }
}

// MARK: - 导入操作按钮
struct ImportActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(SpendoTheme.cardBackground)
            .cornerRadius(10)
        }
    }
}

// MARK: - 设置行按钮
struct SettingsRowButton: View {
    let title: String
    let value: String
    let valueColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(SpendoTheme.textPrimary)
                Spacer()
                Text(value)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .foregroundColor(SpendoTheme.textTertiary)
                    .font(.system(size: 14))
            }
            .padding()
            .background(SpendoTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - 来源选择器
struct BillSourcePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSource: BillImportSource?
    
    var body: some View {
        NavigationStack {
            pickerContent
                .navigationTitle("导入来源")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { pickerToolbar }
        }
    }
    
    private var pickerContent: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                sourceList
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
                    .padding(16)
            }
        }
    }
    
    private var sourceList: some View {
        VStack(spacing: 0) {
            ForEach(BillImportSource.allCases, id: \.self) { source in
                SourceRowView(
                    source: source,
                    isSelected: selectedSource == source
                ) {
                    selectedSource = source
                    dismiss()
                }
                
                if source != BillImportSource.allCases.last {
                    Divider()
                        .background(SpendoTheme.textTertiary.opacity(0.3))
                        .padding(.leading, 74)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var pickerToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(SpendoTheme.textSecondary)
            }
        }
    }
}

// MARK: - 来源行视图
struct SourceRowView: View {
    let source: BillImportSource
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                sourceIcon
                
                Text(source.displayName)
                    .font(.system(size: 16))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(SpendoTheme.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var sourceIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: source.iconColor).opacity(0.15))
                .frame(width: 44, height: 44)
            
            Image(systemName: source.iconName)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: source.iconColor))
        }
    }
}

// MARK: - 导入预览视图
struct BillImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let result: BillImportResult
    let categories: [Category]
    let defaultAccountId: UUID?
    let onImport: ([ImportedTransaction]) -> Void
    
    @State private var transactions: [ImportedTransaction]
    @State private var selectAll = true
    
    init(result: BillImportResult, categories: [Category], defaultAccountId: UUID?, onImport: @escaping ([ImportedTransaction]) -> Void) {
        self.result = result
        self.categories = categories
        self.defaultAccountId = defaultAccountId
        self.onImport = onImport
        _transactions = State(initialValue: result.transactions)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    statsHeader
                    selectAllRow
                    transactionList
                    importButton
                }
            }
            .navigationTitle("预览导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(SpendoTheme.textSecondary)
                }
            }
        }
    }
    
    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("解析成功")
                    .font(.system(size: 13))
                    .foregroundColor(SpendoTheme.textSecondary)
                Text("\(result.successCount) 条")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(SpendoTheme.accentGreen)
            }
            
            Spacer()
            
            if result.failedCount > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("解析失败")
                        .font(.system(size: 13))
                        .foregroundColor(SpendoTheme.textSecondary)
                    Text("\(result.failedCount) 条")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(SpendoTheme.accentRed)
                }
            }
        }
        .padding()
        .background(SpendoTheme.cardBackground)
    }
    
    private var selectAllRow: some View {
        HStack {
            Button(action: toggleSelectAll) {
                HStack(spacing: 8) {
                    Image(systemName: selectAll ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectAll ? SpendoTheme.primary : SpendoTheme.textSecondary)
                    Text(selectAll ? "取消全选" : "全选")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Text("已选 \(selectedCount) 条")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    ImportedTransactionRow(
                        transaction: transaction,
                        isSelected: transaction.isSelected
                    ) {
                        transactions[index].isSelected.toggle()
                        updateSelectAll()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var importButton: some View {
        Button(action: {
            onImport(transactions.filter { $0.isSelected })
            dismiss()
        }) {
            Text("导入 \(selectedCount) 条记录")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedCount > 0 ? SpendoTheme.primary : SpendoTheme.textTertiary)
                .cornerRadius(12)
        }
        .disabled(selectedCount == 0)
        .padding()
    }
    
    private var selectedCount: Int {
        transactions.filter { $0.isSelected }.count
    }
    
    private func toggleSelectAll() {
        selectAll.toggle()
        for i in transactions.indices {
            transactions[i].isSelected = selectAll
        }
    }
    
    private func updateSelectAll() {
        selectAll = transactions.allSatisfy { $0.isSelected }
    }
}

// MARK: - 导入交易行
struct ImportedTransactionRow: View {
    let transaction: ImportedTransaction
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? SpendoTheme.primary : SpendoTheme.textTertiary)
                    .font(.system(size: 22))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textSecondary)
                    Text(transaction.categoryName)
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
                
                Spacer()
                
                amountText
            }
            .padding()
            .background(SpendoTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var amountText: some View {
        let prefix = transaction.type == .expense ? "-¥" : "+¥"
        let color = transaction.type == .expense ? SpendoTheme.accentRed : SpendoTheme.accentGreen
        return Text("\(prefix)\(String(format: "%.2f", transaction.amount))")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(color)
    }
}

// MARK: - 文档选择器
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedFileName: String
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let csvType = UTType.commaSeparatedText
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [csvType])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedURL = url
            parent.selectedFileName = url.lastPathComponent
        }
    }
}

// MARK: - 模板信息视图
struct TemplateInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("支持的导入格式")
                            .font(.headline)
                            .foregroundColor(SpendoTheme.textPrimary)
                        
                        formatList
                        
                        Divider().padding(.vertical, 8)
                        
                        Text("导出账单方法")
                            .font(.headline)
                            .foregroundColor(SpendoTheme.textPrimary)
                        
                        exportGuide
                    }
                    .padding()
                }
            }
            .navigationTitle("帮助")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(SpendoTheme.primary)
                }
            }
        }
    }
    
    private var formatList: some View {
        VStack(alignment: .leading, spacing: 12) {
            FormatRow(title: "支付宝", desc: "从支付宝App导出的账单CSV文件")
            FormatRow(title: "微信", desc: "从微信支付导出的账单CSV文件")
            FormatRow(title: "钱迹", desc: "钱迹App导出的标准格式")
            FormatRow(title: "随手记", desc: "随手记App导出的Excel/CSV格式")
            FormatRow(title: "Moze", desc: "Moze App导出的CSV格式")
            FormatRow(title: "通用CSV", desc: "包含日期、金额、分类列的CSV文件")
        }
    }
    
    private var exportGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("**支付宝：**")
                .foregroundColor(SpendoTheme.textPrimary)
            Text("我的 → 账单 → 右上角「...」→ 开具交易流水证明")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
            
            Text("**微信：**")
                .foregroundColor(SpendoTheme.textPrimary)
                .padding(.top, 4)
            Text("我 → 服务 → 钱包 → 账单 → 常见问题 → 下载账单")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
        }
    }
}

struct FormatRow: View {
    let title: String
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(SpendoTheme.textPrimary)
            Text(desc)
                .font(.system(size: 13))
                .foregroundColor(SpendoTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview("账单导入") {
    BillImportView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self])
}
