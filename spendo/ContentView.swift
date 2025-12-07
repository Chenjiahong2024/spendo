//
//  ContentView.swift
//  Spendo
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddTransaction = false
    @Query private var settingsArray: [UserSettings]
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    
    // 启动时读取的 TabBar 样式（运行时不变）
    @State private var useCustomStyle: Bool = UserDefaults.standard.integer(forKey: "tabBarStyle") == 1
    
    // Tab 配置 - 使用本地化字符串
    private var tabs: [(icon: String, title: String)] {
        [
            ("doc.text", "tab_ledger".localized),
            ("creditcard", "tab_assets".localized),
            ("banknote", "tab_savings".localized),
            ("chart.bar", "tab_stats".localized),
            ("gearshape", "tab_settings".localized)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if useCustomStyle {
                // 自定义 TabBar 模式
                customTabBarContent
            } else {
                // 系统 TabBar 模式
                systemTabBarContent
            }
            
            // 浮动添加按钮 - 右下角
            floatingAddButton
        }
        .id(languageManager.refreshID) // 语言变化时强制刷新
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }
    
    // MARK: - 系统 TabView
    private var systemTabBarContent: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("tab_ledger".localized, systemImage: "doc.text.fill")
                }
                .tag(0)
            
            AccountsView()
                .tabItem {
                    Label("tab_assets".localized, systemImage: "creditcard.fill")
                }
                .tag(1)
            
            BudgetView()
                .tabItem {
                    Label("tab_savings".localized, systemImage: "banknote.fill")
                }
                .tag(2)
            
            AnalyticsViewNew()
                .tabItem {
                    Label("tab_stats".localized, systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("tab_settings".localized, systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(themeManager.currentAccentColor)
    }
    
    // MARK: - 自定义 TabBar 模式
    private var customTabBarContent: some View {
        VStack(spacing: 0) {
            // 内容区域
            Group {
                switch selectedTab {
                case 0: DashboardView()
                case 1: AccountsView()
                case 2: BudgetView()
                case 3: AnalyticsViewNew()
                case 4: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 自定义 Tab Bar
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    CustomTabItem(
                        icon: themeManager.iconName(tabs[index].icon),
                        title: tabs[index].title,
                        isSelected: selectedTab == index,
                        accentColor: themeManager.currentAccentColor
                    )
                    .onTapGesture {
                        if themeManager.animationsEnabled {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        } else {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
            .background(SpendoTheme.background)
        }
    }
    
    // MARK: - 浮动添加按钮
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showAddTransaction = true
                }) {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentAccentColor)
                            .frame(width: 56, height: 56)
                            .shadow(color: themeManager.currentAccentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, useCustomStyle ? 100 : 90)
            }
        }
    }
}

// MARK: - 自定义 Tab Item
struct CustomTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? accentColor : SpendoTheme.textTertiary)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(isSelected ? accentColor : SpendoTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self, Budget.self, UserSettings.self])
}
