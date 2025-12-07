//
//  SettingsView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [UserSettings]
    @Query private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    
    // 功能开关
    @AppStorage("multiBookEnabled") private var multiBookEnabled = true
    @AppStorage("savingEnabled") private var savingEnabled = true
    
    private var settings: UserSettings? {
        settingsArray.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 用户头像区域
                        UserProfileHeader()
                        
                        // 安全与同步
                        SettingsSection {
                            NavigationLink(destination: PasswordProtectionView()) {
                                SettingsRowContent(icon: "lock.fill", iconColor: .blue, title: "密码保护")
                            }
                        }
                        
                        SettingsSection {
                            NavigationLink(destination: iCloudSyncView()) {
                                SettingsRowContent(icon: "icloud.fill", iconColor: .blue, title: "iCloud云同步")
                            }
                        }
                        
                        // 数据导入导出
                        SettingsSection {
                            NavigationLink(destination: BillImportView()) {
                                SettingsRowContent(icon: "square.and.arrow.down.fill", iconColor: .orange, title: "账单导入")
                            }
                            SettingsDivider()
                            NavigationLink(destination: BillExportView()) {
                                SettingsRowContent(icon: "square.and.arrow.up.fill", iconColor: .yellow, title: "账单导出")
                            }
                        }
                        
                        // 智能功能
                        SettingsSection {
                            NavigationLink(destination: ScreenshotImportView()) {
                                SettingsRowContent(icon: "photo.fill", iconColor: .green, title: "截图导入")
                            }
                        }
                        
                        SettingsSection {
                            NavigationLink(destination: SmartBookkeepingView()) {
                                SettingsRowContent(icon: "brain.head.profile", iconColor: .purple, title: "智能记账")
                            }
                        }
                        
                        SettingsSection {
                            NavigationLink(destination: DynamicIslandView()) {
                                SettingsRowContent(icon: "platter.filled.top.and.arrow.up.iphone", iconColor: .purple, title: "灵动岛管理")
                            }
                        }
                        
                        // 管理功能
                        SettingsSection {
                            NavigationLink(destination: CycleManagementView()) {
                                SettingsRowContent(icon: "arrow.trianglehead.2.clockwise.rotate.90", iconColor: .green, title: "周期管理")
                            }
                            SettingsDivider()
                            NavigationLink(destination: InstallmentManagementView()) {
                                SettingsRowContent(icon: "square.split.2x2.fill", iconColor: .purple, title: "分期管理")
                            }
                            SettingsDivider()
                            NavigationLink(destination: CategoryManagementView()) {
                                SettingsRowContent(icon: "square.grid.2x2.fill", iconColor: .blue, title: "分类管理")
                            }
                            SettingsDivider()
                            NavigationLink(destination: TagManagementView()) {
                                SettingsRowContent(icon: "tag.fill", iconColor: .cyan, title: "标签管理")
                            }
                            SettingsDivider()
                            NavigationLink(destination: BudgetSettingsView()) {
                                SettingsRowContent(icon: "chart.bar.fill", iconColor: .orange, title: "预算功能")
                            }
                            SettingsDivider()
                            NavigationLink(destination: ReimbursementView()) {
                                SettingsRowContent(icon: "doc.text.fill", iconColor: .blue, title: "报销功能")
                            }
                            SettingsDivider()
                            NavigationLink(destination: CurrencySettingView()) {
                                SettingsRowContent(icon: "dollarsign.circle.fill", iconColor: .purple, title: "货币和汇率")
                            }
                        }
                        
                        // 设置项
                        SettingsSection {
                            NavigationLink(destination: AssetSettingsView()) {
                                SettingsRowContent(icon: "creditcard.fill", iconColor: .teal, title: "资产设置")
                            }
                            SettingsDivider()
                            NavigationLink(destination: StatisticsSettingsView()) {
                                SettingsRowContent(icon: "chart.pie.fill", iconColor: .indigo, title: "统计设置")
                            }
                            SettingsDivider()
                            NavigationLink(destination: TemplateSettingsView()) {
                                SettingsRowContent(icon: "doc.on.doc.fill", iconColor: .purple, title: "模板设置")
                            }
                            SettingsDivider()
                            NavigationLink(destination: RefundSettingsView()) {
                                SettingsRowContent(icon: "arrow.uturn.backward.circle.fill", iconColor: .blue, title: "退款设置")
                            }
                        }
                        
                        // 开关功能
                        SettingsSection {
                            SettingsToggleRow(icon: "books.vertical.fill", iconColor: .indigo, title: "多账本功能", isOn: $multiBookEnabled)
                            SettingsDivider()
                            SettingsToggleRow(icon: "banknote.fill", iconColor: .green, title: "存钱功能", isOn: $savingEnabled)
                        }
                        
                        // 位置与图片
                        SettingsSection {
                            NavigationLink(destination: LocationSettingsView()) {
                                SettingsRowContent(icon: "location.fill", iconColor: .blue, title: "记账位置")
                            }
                            SettingsDivider()
                            NavigationLink(destination: BillImageSettingsView()) {
                                SettingsRowContent(icon: "photo.on.rectangle.angled", iconColor: .pink, title: "账单图片")
                            }
                            SettingsDivider()
                            NavigationLink(destination: TimeSettingsView()) {
                                SettingsRowContent(icon: "clock.fill", iconColor: .blue, title: "时间设置")
                            }
                        }
                        
                        // 地图与备份
                        SettingsSection {
                            NavigationLink(destination: BookkeepingMapView()) {
                                SettingsRowContent(icon: "map.fill", iconColor: .purple, title: "记账地图")
                            }
                        }
                        
                        SettingsSection {
                            NavigationLink(destination: BackupRestoreView()) {
                                SettingsRowContent(icon: "arrow.triangle.2.circlepath", iconColor: .green, title: "备份与恢复")
                            }
                        }
                        
                        // 个性化
                        SettingsSection {
                            NavigationLink(destination: EfficiencySettingsView()) {
                                SettingsRowContent(icon: "bolt.fill", iconColor: .teal, title: "效率")
                            }
                            SettingsDivider()
                            NavigationLink(destination: PersonalizationView()) {
                                SettingsRowContent(icon: "paintpalette.fill", iconColor: .blue, title: "个性化")
                            }
                            SettingsDivider()
                            NavigationLink(destination: ThemeSettingView()) {
                                SettingsRowContent(icon: "sun.max.fill", iconColor: .orange, title: "外观")
                            }
                        }
                        
                        // 帮助
                        SettingsSection {
                            NavigationLink(destination: FAQView()) {
                                SettingsRowContent(icon: "questionmark.circle.fill", iconColor: .blue, title: "常见问题")
                            }
                            SettingsDivider()
                            NavigationLink(destination: UserGuideView()) {
                                SettingsRowContent(icon: "book.fill", iconColor: .indigo, title: "使用指南")
                            }
                        }
                        
                        SettingsSection {
                            NavigationLink(destination: HelpFeedbackView()) {
                                SettingsRowContent(icon: "bubble.left.and.bubble.right.fill", iconColor: .green, title: "帮助与反馈")
                            }
                            SettingsDivider()
                            NavigationLink(destination: ShareAppView()) {
                                SettingsRowContent(icon: "person.2.fill", iconColor: .blue, title: "分享给朋友")
                            }
                        }
                        
                        // 语言
                        SettingsSection {
                            NavigationLink(destination: LanguageSettingsView()) {
                                SettingsRowWithValueContent(icon: "globe", iconColor: .green, title: "语言设置", value: "跟随系统")
                            }
                        }
                        
                        // 版本信息
                        Text("版本 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(SpendoTheme.textTertiary)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 用户头像区域
struct UserProfileHeader: View {
    @AppStorage("userName") private var userName = "用户"
    @State private var showImagePicker = false
    @State private var showNameEditor = false
    @State private var avatarImage: UIImage?
    @State private var tempName = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // 头像
            Button(action: { showImagePicker = true }) {
                ZStack {
                    if let image = avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(SpendoTheme.cardBackground)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(SpendoTheme.textSecondary)
                    }
                    
                    // 相机图标
                    Circle()
                        .fill(SpendoTheme.primary)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        )
                        .offset(x: 28, y: 28)
                    
                    // 永久免费标签
                    Text("永久免费")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(4)
                        .offset(y: 45)
                }
            }
            
            // 用户名（可点击编辑）
            Button(action: {
                tempName = userName
                showNameEditor = true
            }) {
                HStack(spacing: 6) {
                    Text(userName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(SpendoTheme.textPrimary)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            loadAvatarImage()
        }
        .sheet(isPresented: $showImagePicker) {
            AvatarImagePicker(image: $avatarImage, onImageSelected: saveAvatarImage)
        }
        .alert("修改用户名", isPresented: $showNameEditor) {
            TextField("用户名", text: $tempName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                if !tempName.isEmpty {
                    userName = tempName
                }
            }
        }
    }
    
    // 加载头像
    private func loadAvatarImage() {
        if let data = UserDefaults.standard.data(forKey: "userAvatarImage"),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
    
    // 保存头像
    private func saveAvatarImage(_ image: UIImage?) {
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "userAvatarImage")
        }
    }
}

// MARK: - 头像选择器
struct AvatarImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AvatarImagePicker
        
        init(_ parent: AvatarImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // 优先使用编辑后的图片
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                parent.onImageSelected(originalImage)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 设置区块容器
struct SettingsSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(SpendoTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - 设置行
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        Button(action: {}) {
            SettingsRowContent(icon: icon, iconColor: iconColor, title: title)
        }
    }
}

// MARK: - 设置行内容
struct SettingsRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(SpendoTheme.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - 带值的设置行
struct SettingsRowWithValue: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - 带值的设置行内容（用于NavigationLink）
struct SettingsRowWithValueContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(SpendoTheme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - 开关设置行
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(SpendoTheme.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SpendoTheme.accentGreen)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - 分割线
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(SpendoTheme.textTertiary.opacity(0.2))
            .padding(.leading, 58)
    }
}

// MARK: - 分类管理视图（占位）
struct CategoryManagementView: View {
    var body: some View {
        ZStack {
            SpendoTheme.background
                .ignoresSafeArea()
            
            Text("分类管理功能开发中...")
                .foregroundColor(SpendoTheme.textSecondary)
        }
        .navigationTitle("分类管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CurrencySettingView: View {
    @Query private var settingsArray: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var currencyService = CurrencyService.shared
    @State private var searchText = ""
    @State private var showingUpdateAlert = false
    @State private var updateMessage = ""
    
    private var settings: UserSettings? {
        settingsArray.first
    }
    
    // 按地区分组的货币
    private var groupedCurrencies: [(region: String, currencies: [CurrencyInfo])] {
        let all = CurrencyService.allCurrencies
        let filtered = searchText.isEmpty ? all : all.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        // 定义地区分组
        let regions: [(name: String, codes: [String])] = [
            ("常用", ["CNY", "USD", "EUR", "GBP", "JPY", "SGD", "HKD"]),
            ("亚洲", ["CNY", "HKD", "TWD", "MOP", "JPY", "KRW", "SGD", "MYR", "THB", "VND", "PHP", "IDR", "INR", "PKR", "BDT", "LKR", "NPR", "MMK", "KHR", "LAK", "BND"]),
            ("中东", ["AED", "SAR", "QAR", "KWD", "BHD", "OMR", "ILS", "TRY"]),
            ("欧洲", ["EUR", "GBP", "CHF", "RUB", "SEK", "NOK", "DKK", "PLN", "CZK", "HUF", "RON", "BGN", "HRK", "UAH", "ISK"]),
            ("美洲", ["USD", "CAD", "MXN", "BRL", "ARS", "CLP", "COP", "PEN"]),
            ("大洋洲", ["AUD", "NZD", "FJD"]),
            ("非洲", ["ZAR", "EGP", "NGN", "KES", "MAD", "TND", "GHS"])
        ]
        
        if !searchText.isEmpty {
            return [("搜索结果", filtered)]
        }
        
        return regions.compactMap { region in
            let regionCurrencies = filtered.filter { region.codes.contains($0.code) }
            return regionCurrencies.isEmpty ? nil : (region.name, regionCurrencies)
        }
    }
    
    var body: some View {
        List {
            // 汇率更新区域
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("实时汇率")
                            .font(.system(size: 15))
                        Text("上次更新: \(currencyService.lastUpdateTimeString)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        updateRates()
                    }) {
                        if currencyService.isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.primary)
                        }
                    }
                    .disabled(currencyService.isUpdating)
                }
            } header: {
                Text("汇率")
            } footer: {
                Text("汇率数据来自欧洲央行，每小时自动更新")
            }
            
            // 货币列表
            ForEach(groupedCurrencies, id: \.region) { group in
                Section(header: Text(group.region)) {
                    ForEach(group.currencies, id: \.code) { currency in
                        Button(action: {
                            updateCurrency(currency.code)
                        }) {
                            HStack {
                                Text(currency.symbol)
                                    .font(.system(size: 18))
                                    .frame(width: 40, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency.name)
                                        .font(.system(size: 15))
                                    
                                    HStack(spacing: 4) {
                                        Text(currency.code)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        // 显示实时汇率
                                        if let rate = currencyService.liveRates[currency.code] {
                                            Text("• 1 CNY = \(String(format: "%.4f", rate))")
                                                .font(.system(size: 11))
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if settings?.primaryCurrency == currency.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(SpendoTheme.primary)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索货币")
        .navigationTitle("选择主币种")
        .onAppear {
            // 如果需要更新汇率
            if currencyService.needsUpdate {
                updateRates()
            }
        }
        .alert("汇率更新", isPresented: $showingUpdateAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(updateMessage)
        }
    }
    
    private func updateRates() {
        currencyService.updateExchangeRates { success in
            if success {
                updateMessage = "汇率已更新为最新数据"
            } else {
                updateMessage = "更新失败，请检查网络连接"
            }
            showingUpdateAlert = true
        }
    }
    
    private func updateCurrency(_ currency: String) {
        if let settings = settings {
            settings.primaryCurrency = currency
            settings.updatedAt = Date()
            try? modelContext.save()
        }
    }
}

struct ThemeSettingView: View {
    @Query private var settingsArray: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    
    private var settings: UserSettings? {
        settingsArray.first
    }
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    updateTheme(theme)
                }) {
                    HStack {
                        Text(theme.displayName)
                        Spacer()
                        if settings?.theme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(SpendoTheme.primary)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("选择主题")
    }
    
    private func updateTheme(_ theme: AppTheme) {
        if let settings = settings {
            settings.theme = theme
            settings.updatedAt = Date()
            try? modelContext.save()
        }
    }
}

// MARK: - Previews
#Preview("设置") {
    SettingsView()
        .modelContainer(for: [UserSettings.self, Transaction.self, Category.self, Account.self, Budget.self])
}

#Preview("用户头像") {
    UserProfileHeader()
        .background(SpendoTheme.background)
}

#Preview("设置行组件") {
    VStack(spacing: 0) {
        SettingsSection {
            SettingsRow(icon: "lock.fill", iconColor: .blue, title: "密码保护")
            SettingsDivider()
            SettingsToggleRow(icon: "icloud.fill", iconColor: .blue, title: "iCloud同步", isOn: .constant(true))
        }
    }
    .padding()
    .background(SpendoTheme.background)
}
