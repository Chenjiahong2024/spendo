//
//  SettingsSubViews2.swift
//  Spendo
//
//  设置页面的更多子视图
//

import SwiftUI
import SwiftData
import MapKit

// MARK: - 资产设置视图
struct AssetSettingsView: View {
    @AppStorage("showAssetTotal") private var showAssetTotal = true
    @AppStorage("showLiabilities") private var showLiabilities = true
    @AppStorage("assetDisplayMode") private var assetDisplayMode = 0
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "显示设置") {
                        VStack(spacing: 12) {
                            Toggle("显示资产总额", isOn: $showAssetTotal)
                                .tint(SpendoTheme.accentGreen)
                            Toggle("显示负债", isOn: $showLiabilities)
                                .tint(SpendoTheme.accentGreen)
                        }
                    }
                    
                    SettingsCard(title: "资产展示方式") {
                        Picker("展示方式", selection: $assetDisplayMode) {
                            Text("按类型分组").tag(0)
                            Text("按金额排序").tag(1)
                            Text("自定义排序").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    NavigationLink(destination: AccountsView()) {
                        HStack {
                            Text("管理账户")
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
        .navigationTitle("asset_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 统计设置视图
struct StatisticsSettingsView: View {
    @AppStorage("defaultStatsPeriod") private var defaultStatsPeriod = 0
    @AppStorage("showPercentage") private var showPercentage = true
    @AppStorage("chartStyle") private var chartStyle = 0
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "默认统计周期") {
                        Picker("周期", selection: $defaultStatsPeriod) {
                            Text("本周").tag(0)
                            Text("本月").tag(1)
                            Text("本年").tag(2)
                            Text("全部").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    SettingsCard(title: "显示设置") {
                        VStack(spacing: 12) {
                            Toggle("显示百分比", isOn: $showPercentage)
                                .tint(SpendoTheme.accentGreen)
                        }
                    }
                    
                    SettingsCard(title: "图表样式") {
                        Picker("样式", selection: $chartStyle) {
                            Text("环形图").tag(0)
                            Text("饼图").tag(1)
                            Text("柱状图").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("statistics_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 模板设置视图
struct TemplateSettingsView: View {
    @State private var templates: [TransactionTemplate] = [
        TransactionTemplate(name: "早餐", amount: 15, category: "餐饮"),
        TransactionTemplate(name: "午餐", amount: 25, category: "餐饮"),
        TransactionTemplate(name: "地铁", amount: 4, category: "交通"),
    ]
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "快捷记账模板") {
                        VStack(spacing: 0) {
                            ForEach(templates) { template in
                                HStack {
                                    Text(template.name)
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("¥\(template.amount, specifier: "%.0f")")
                                        .foregroundColor(SpendoTheme.textSecondary)
                                    
                                    Text(template.category)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SpendoTheme.primary.opacity(0.8))
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 10)
                                
                                if template.id != templates.last?.id {
                                    Divider()
                                        .background(SpendoTheme.textTertiary.opacity(0.2))
                                }
                            }
                        }
                    }
                    
                    Button(action: { showAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加模板")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SpendoTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("template_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TransactionTemplate: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let category: String
}

// MARK: - 退款设置视图
struct RefundSettingsView: View {
    @AppStorage("autoLinkRefund") private var autoLinkRefund = true
    @AppStorage("refundNotification") private var refundNotification = true
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "退款关联") {
                        VStack(spacing: 12) {
                            Toggle("自动关联原交易", isOn: $autoLinkRefund)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("记录退款时自动匹配相关的原始消费")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    SettingsCard(title: "通知") {
                        Toggle("退款到账提醒", isOn: $refundNotification)
                            .tint(SpendoTheme.accentGreen)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("refund_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 记账位置视图
struct LocationSettingsView: View {
    @AppStorage("locationEnabled") private var locationEnabled = false
    @AppStorage("autoLocation") private var autoLocation = true
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "位置记录") {
                        VStack(spacing: 12) {
                            Toggle("启用位置记录", isOn: $locationEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            if locationEnabled {
                                Toggle("自动获取位置", isOn: $autoLocation)
                                    .tint(SpendoTheme.accentGreen)
                            }
                            
                            Text("记录消费地点，方便回顾和分析")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    if !locationEnabled {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(SpendoTheme.textTertiary)
                            Text("开启后可在记账地图查看消费分布")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                        }
                        .padding()
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("location_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 账单图片视图
struct BillImageSettingsView: View {
    @AppStorage("saveImages") private var saveImages = true
    @AppStorage("imageQuality") private var imageQuality = 1
    @AppStorage("autoCleanOldImages") private var autoCleanOldImages = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "图片保存") {
                        VStack(spacing: 12) {
                            Toggle("保存账单图片", isOn: $saveImages)
                                .tint(SpendoTheme.accentGreen)
                        }
                    }
                    
                    if saveImages {
                        SettingsCard(title: "图片质量") {
                            Picker("质量", selection: $imageQuality) {
                                Text("低").tag(0)
                                Text("中").tag(1)
                                Text("高").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        SettingsCard(title: "存储管理") {
                            VStack(spacing: 12) {
                                Toggle("自动清理旧图片", isOn: $autoCleanOldImages)
                                    .tint(SpendoTheme.accentGreen)
                                
                                if autoCleanOldImages {
                                    Text("超过3个月的账单图片将被自动清理")
                                        .font(.system(size: 13))
                                        .foregroundColor(SpendoTheme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("bill_image".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 时间设置视图
struct TimeSettingsView: View {
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    @AppStorage("defaultTime") private var defaultTime = 0
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "时间格式") {
                        Picker("格式", selection: $use24HourFormat) {
                            Text("12小时制").tag(false)
                            Text("24小时制").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    SettingsCard(title: "默认记账时间") {
                        Picker("时间", selection: $defaultTime) {
                            Text("当前时间").tag(0)
                            Text("今天 00:00").tag(1)
                            Text("今天 12:00").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("time_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 记账地图视图
struct BookkeepingMapView: View {
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    
    var body: some View {
        ZStack {
            Map(position: $position)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    Text("暂无位置数据")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textSecondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
        .navigationTitle("bookkeeping_map".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 备份与恢复视图
struct BackupRestoreView: View {
    @State private var lastBackupDate: Date?
    @State private var isBackingUp = false
    @State private var showRestoreAlert = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 备份状态
                    SettingsCard(title: "备份状态") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("上次备份")
                                    .font(.system(size: 14))
                                    .foregroundColor(SpendoTheme.textSecondary)
                                
                                if let date = lastBackupDate {
                                    Text(date.formatted(.dateTime))
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                } else {
                                    Text("从未备份")
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textTertiary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(lastBackupDate != nil ? SpendoTheme.accentGreen : SpendoTheme.textTertiary)
                        }
                    }
                    
                    // 备份按钮
                    Button(action: performBackup) {
                        HStack {
                            if isBackingUp {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            Text("立即备份")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SpendoTheme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isBackingUp)
                    
                    // 恢复按钮
                    Button(action: { showRestoreAlert = true }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("从备份恢复")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SpendoTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // 说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 备份数据将加密存储在本地")
                        Text("• 恢复操作会覆盖当前所有数据")
                        Text("• 建议定期备份重要数据")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(SpendoTheme.textSecondary)
                    .padding()
                }
                .padding(16)
            }
        }
        .navigationTitle("backup_restore".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认恢复", isPresented: $showRestoreAlert) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive) {
                // 执行恢复
            }
        } message: {
            Text("恢复操作会覆盖当前所有数据，确定继续吗？")
        }
    }
    
    private func performBackup() {
        isBackingUp = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastBackupDate = Date()
            isBackingUp = false
        }
    }
}

// MARK: - 效率视图
struct EfficiencySettingsView: View {
    @AppStorage("quickAddEnabled") private var quickAddEnabled = true
    @AppStorage("gestureEnabled") private var gestureEnabled = true
    @AppStorage("keyboardShortcuts") private var keyboardShortcuts = true
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "快捷记账") {
                        VStack(spacing: 12) {
                            Toggle("启用快捷添加", isOn: $quickAddEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("长按首页加号按钮快速记账")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    SettingsCard(title: "手势操作") {
                        VStack(spacing: 12) {
                            Toggle("启用手势", isOn: $gestureEnabled)
                                .tint(SpendoTheme.accentGreen)
                            
                            Text("左滑删除、右滑编辑交易记录")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    SettingsCard(title: "键盘快捷键") {
                        Toggle("启用键盘快捷键", isOn: $keyboardShortcuts)
                            .tint(SpendoTheme.accentGreen)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("efficiency".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 个性化视图
struct PersonalizationView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 主题色选择
                    SettingsCard(title: "主题色") {
                        HStack(spacing: 16) {
                            ForEach(0..<ThemeManager.themeColors.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        themeManager.accentColorIndex = index
                                    }
                                }) {
                                    Circle()
                                        .fill(ThemeManager.themeColors[index])
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: themeManager.accentColorIndex == index ? 3 : 0)
                                        )
                                        .scaleEffect(themeManager.accentColorIndex == index ? 1.1 : 1.0)
                                }
                            }
                        }
                    }
                    
                    // 当前主题预览
                    SettingsCard(title: "预览") {
                        VStack(spacing: 12) {
                            // 按钮预览
                            Button(action: {}) {
                                Text("主题按钮效果")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(themeManager.currentAccentColor)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    // TabBar 样式
                    SettingsCard(title: "TabBar 样式") {
                        VStack(spacing: 12) {
                            Picker("样式", selection: $themeManager.tabBarStyle) {
                                Text("系统样式").tag(0)
                                Text("自定义").tag(1)
                            }
                            .pickerStyle(.segmented)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                Text("切换后需重启App生效")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(SpendoTheme.accentOrange)
                            
                            Text(themeManager.useCustomTabBar ? "自定义样式支持图标风格切换" : "系统样式使用原生TabBar")
                                .font(.system(size: 12))
                                .foregroundColor(SpendoTheme.textTertiary)
                        }
                    }
                    
                    // 图标风格 - 仅在自定义 TabBar 时显示
                    if themeManager.useCustomTabBar {
                        SettingsCard(title: "图标风格") {
                            VStack(spacing: 16) {
                                Picker("风格", selection: $themeManager.iconStyle) {
                                    Text("填充").tag(0)
                                    Text("线条").tag(1)
                                }
                                .pickerStyle(.segmented)
                                
                                // 图标预览对比
                                HStack(spacing: 0) {
                                    // 填充图标
                                    VStack(spacing: 8) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "house.fill")
                                            Image(systemName: "creditcard.fill")
                                            Image(systemName: "gearshape.fill")
                                        }
                                        .font(.system(size: 22))
                                        .foregroundColor(themeManager.iconStyle == 0 ? themeManager.currentAccentColor : SpendoTheme.textTertiary)
                                        
                                        Text("填充")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.iconStyle == 0 ? themeManager.currentAccentColor : SpendoTheme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(themeManager.iconStyle == 0 ? themeManager.currentAccentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(8)
                                    
                                    // 线条图标
                                    VStack(spacing: 8) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "house")
                                            Image(systemName: "creditcard")
                                            Image(systemName: "gearshape")
                                        }
                                        .font(.system(size: 22))
                                        .foregroundColor(themeManager.iconStyle == 1 ? themeManager.currentAccentColor : SpendoTheme.textTertiary)
                                        
                                        Text("线条")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.iconStyle == 1 ? themeManager.currentAccentColor : SpendoTheme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(themeManager.iconStyle == 1 ? themeManager.currentAccentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // 动画效果
                    SettingsCard(title: "动画效果") {
                        VStack(spacing: 12) {
                            Toggle("启用动画", isOn: $themeManager.animationsEnabled)
                                .tint(themeManager.currentAccentColor)
                            
                            Text("关闭后将禁用界面过渡动画")
                                .font(.system(size: 13))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("personalization".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 常见问题视图
struct FAQView: View {
    let faqs = [
        ("如何导入其他记账App的数据？", "进入设置 > 账单导入，选择对应的App格式，上传CSV文件即可。"),
        ("如何设置预算提醒？", "进入设置 > 预算功能，开启预算提醒并设置阈值。"),
        ("数据会自动同步吗？", "开启iCloud同步后，数据会自动在您的设备间同步。"),
        ("如何备份数据？", "进入设置 > 备份与恢复，点击立即备份。"),
        ("如何修改分类？", "进入设置 > 分类管理，可以添加、编辑或删除分类。"),
    ]
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(faqs.indices, id: \.self) { index in
                        FAQItem(question: faqs[index].0, answer: faqs[index].1)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("faq".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(question)
                        .font(.system(size: 15))
                        .foregroundColor(SpendoTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(SpendoTheme.textTertiary)
                }
                .padding(16)
            }
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(SpendoTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(SpendoTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - 使用指南视图
struct UserGuideView: View {
    // GitHub Pages 使用指南网址（基于 GitHub 仓库 Chenjiahong2024/spendo）
    // 启用 Pages 后，会是：https://chenjiahong2024.github.io/spendo/
    private let userGuideURL = URL(string: "https://chenjiahong2024.github.io/spendo/")!
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("guide_description".localized)
                    .font(.system(size: 15))
                    .foregroundColor(SpendoTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Link(destination: userGuideURL) {
                    HStack {
                        Image(systemName: "safari")
                            .font(.system(size: 18, weight: .medium))
                        Text("view_guide".localized)
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(SpendoTheme.textPrimary)
                    .padding(16)
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("user_guide".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 帮助与反馈视图
struct HelpFeedbackView: View {
    @State private var feedbackText = ""
    @State private var contactEmail = ""
    @State private var showSubmitAlert = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "问题反馈") {
                        VStack(spacing: 12) {
                            TextEditor(text: $feedbackText)
                                .frame(height: 120)
                                .padding(8)
                                .background(SpendoTheme.cardBackgroundLight)
                                .cornerRadius(8)
                            
                            TextField("联系邮箱（选填）", text: $contactEmail)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(SpendoTheme.cardBackgroundLight)
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(action: { showSubmitAlert = true }) {
                        Text("提交反馈")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SpendoTheme.primary)
                            .cornerRadius(12)
                    }
                    .disabled(feedbackText.isEmpty)
                    
                    // 其他联系方式
                    SettingsCard(title: "其他方式") {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(SpendoTheme.primary)
                                Text("support@spendo.app")
                                    .foregroundColor(SpendoTheme.textPrimary)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("help_feedback".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("提交成功", isPresented: $showSubmitAlert) {
            Button("确定") {
                feedbackText = ""
                contactEmail = ""
            }
        } message: {
            Text("感谢您的反馈，我们会尽快处理！")
        }
    }
}

// MARK: - 分享给朋友视图
struct ShareAppView: View {
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App图标
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(SpendoTheme.primary)
                
                Text("Spendo")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(SpendoTheme.textPrimary)
                
                Text("简洁高效的记账应用")
                    .font(.system(size: 16))
                    .foregroundColor(SpendoTheme.textSecondary)
                
                Spacer()
                
                // 分享按钮
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享给朋友")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SpendoTheme.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
        .navigationTitle("share_app".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["推荐一款好用的记账App - Spendo"])
        }
    }
}

// MARK: - 语言设置视图
struct LanguageSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "system"
    @ObservedObject private var languageManager = LanguageManager.shared
    
    // 按区域分组的语言列表
    let languageGroups: [(String, [(String, String)])] = [
        ("常用", [
            ("system", "跟随系统 / System"),
            ("zh-Hans", "简体中文"),
            ("zh-Hant", "繁體中文"),
            ("en", "English"),
        ]),
        ("东亚", [
            ("ja", "日本語"),
            ("ko", "한국어"),
        ]),
        ("欧洲", [
            ("fr", "Français"),
            ("de", "Deutsch"),
            ("es", "Español"),
            ("pt", "Português"),
            ("it", "Italiano"),
            ("nl", "Nederlands"),
            ("pl", "Polski"),
            ("ru", "Русский"),
            ("tr", "Türkçe"),
            ("uk", "Українська"),
            ("el", "Ελληνικά"),
        ]),
        ("中东/南亚", [
            ("ar", "العربية"),
            ("hi", "हिन्दी"),
            ("fa", "فارسی"),
            ("he", "עברית"),
        ]),
        ("东南亚", [
            ("th", "ไทย"),
            ("vi", "Tiếng Việt"),
            ("id", "Bahasa Indonesia"),
            ("ms", "Bahasa Melayu"),
            ("fil", "Filipino"),
        ]),
        ("北欧", [
            ("sv", "Svenska"),
            ("nb", "Norsk"),
            ("da", "Dansk"),
            ("fi", "Suomi"),
        ]),
    ]
    
    var body: some View {
        ZStack {
            SpendoTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(languageGroups, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            // 分组标题
                            Text(group.0)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SpendoTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                            
                            // 语言列表
                            VStack(spacing: 0) {
                                ForEach(group.1, id: \.0) { lang in
                                    Button(action: { selectLanguage(lang.0) }) {
                                        HStack {
                                            Text(lang.1)
                                                .foregroundColor(SpendoTheme.textPrimary)
                                            
                                            Spacer()
                                            
                                            if appLanguage == lang.0 {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(SpendoTheme.primary)
                                            }
                                        }
                                        .padding(16)
                                    }
                                    
                                    if lang.0 != group.1.last?.0 {
                                        Divider()
                                            .background(SpendoTheme.textTertiary.opacity(0.2))
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("language_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func selectLanguage(_ code: String) {
        appLanguage = code
        if let language = AppLanguage(rawValue: code) {
            languageManager.currentLanguage = language
        }
        // 延迟刷新确保设置已保存
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            languageManager.forceRefresh()
        }
    }
}
