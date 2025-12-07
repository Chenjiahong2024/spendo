//
//  OnboardingView.swift
//  Spendo
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var selectedCurrency = "CNY"
    
    let currencies = ["CNY", "USD", "EUR", "GBP", "JPY", "HKD"]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                // 第一页：欢迎
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("欢迎使用 Spendo")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("极简记账，数据洞察\n让每一笔花费都清晰可见")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .tag(0)
                
                // 第二页：功能介绍
                VStack(spacing: 40) {
                    Spacer()
                    
                    FeatureCard(
                        icon: "bolt.fill",
                        title: "快速记账",
                        description: "支持语音、扫描小票等多种方式"
                    )
                    
                    FeatureCard(
                        icon: "chart.bar.fill",
                        title: "智能分析",
                        description: "自动分类，AI洞察消费趋势"
                    )
                    
                    FeatureCard(
                        icon: "target",
                        title: "预算管理",
                        description: "设置预算，实时追踪支出"
                    )
                    
                    Spacer()
                }
                .tag(1)
                
                // 第三页：设置
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("选择主币种")
                        .font(.system(size: 28, weight: .bold))
                    
                    Picker("币种", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    
                    PrimaryGlowButton(title: "开始使用") {
                        appState.completeOnboarding()
                    }
                    .padding(.bottom, 50)
                    
                    Spacer()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 页面指示器
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? SpendoTheme.primary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 50)
        }
        .background(SpendoTheme.background)
        .ignoresSafeArea()
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
