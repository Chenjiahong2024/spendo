//
//  PasswordProtectionView.swift
//  Spendo
//

import SwiftUI
import LocalAuthentication
import Combine

// MARK: - 锁定时间选项
enum LockTiming: String, CaseIterable, Identifiable {
    case immediately = "immediately"
    case oneMinute = "1min"
    case twoMinutes = "2min"
    case threeMinutes = "3min"
    case fiveMinutes = "5min"
    case tenMinutes = "10min"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .immediately: return "lock_immediately".localized
        case .oneMinute: return "minutes_1".localized
        case .twoMinutes: return "minutes_2".localized
        case .threeMinutes: return "minutes_3".localized
        case .fiveMinutes: return "minutes_5".localized
        case .tenMinutes: return "minutes_10".localized
        }
    }
    
    var seconds: Int {
        switch self {
        case .immediately: return 0
        case .oneMinute: return 60
        case .twoMinutes: return 120
        case .threeMinutes: return 180
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        }
    }
}

// MARK: - 密码保护设置视图
struct PasswordProtectionView: View {
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @AppStorage("pinCodeEnabled") private var pinCodeEnabled = false
    @AppStorage("lockTiming") private var lockTimingRaw = LockTiming.immediately.rawValue
    @AppStorage("userPinCode") private var savedPinCode = ""
    
    @State private var showLockTimingPicker = false
    @State private var showPinCodeSetup = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    @State private var isVerifyingBiometric = false
    
    private var lockTiming: LockTiming {
        LockTiming(rawValue: lockTimingRaw) ?? .immediately
    }
    
    var body: some View {
        ZStack {
            SpendoTheme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 解锁方式
                    SettingsSection {
                        // 面容解锁
                        HStack {
                            Text("face_unlock".localized)
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $faceIDEnabled)
                                .labelsHidden()
                                .tint(SpendoTheme.accentGreen)
                                .onChange(of: faceIDEnabled) { _, newValue in
                                    if newValue {
                                        authenticateWithBiometrics()
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        
                        SettingsDivider()
                        
                        // 数字密码解锁
                        HStack {
                            Text("pin_unlock".localized)
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $pinCodeEnabled)
                                .labelsHidden()
                                .tint(SpendoTheme.accentGreen)
                                .onChange(of: pinCodeEnabled) { _, newValue in
                                    if newValue && savedPinCode.isEmpty {
                                        showPinCodeSetup = true
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    
                    // 锁定时间
                    SettingsSection {
                        Button(action: { showLockTimingPicker = true }) {
                            HStack {
                                Text("lock_timing".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                
                                Spacer()
                                
                                Text(lockTiming.displayName)
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
                    
                    // 说明文字
                    if faceIDEnabled || pinCodeEnabled {
                        Text("开启后，每次打开App将需要验证身份")
                            .font(.system(size: 13))
                            .foregroundColor(SpendoTheme.textTertiary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationTitle("password_protection".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLockTimingPicker) {
            LockTimingPickerView(selectedTiming: $lockTimingRaw)
        }
        .sheet(isPresented: $showPinCodeSetup) {
            PinCodeSetupView(savedPinCode: $savedPinCode, pinCodeEnabled: $pinCodeEnabled)
        }
        .alert("生物识别不可用", isPresented: $showBiometricError) {
            Button("确定", role: .cancel) {
                faceIDEnabled = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    // 验证生物识别
    private func authenticateWithBiometrics() {
        guard !isVerifyingBiometric else { return }
        isVerifyingBiometric = true
        
        Task {
            await performBiometricAuth()
        }
    }
    
    @MainActor
    private func performBiometricAuth() async {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        context.localizedFallbackTitle = ""
        var error: NSError?
        
        // 检查设备是否支持生物识别
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isVerifyingBiometric = false
            faceIDEnabled = false
            if let error = error as? LAError {
                switch error.code {
                case .biometryNotAvailable:
                    biometricErrorMessage = "此设备不支持面容ID"
                case .biometryNotEnrolled:
                    biometricErrorMessage = "未设置面容ID，请在系统设置中添加"
                default:
                    biometricErrorMessage = error.localizedDescription
                }
            } else {
                biometricErrorMessage = "此设备不支持面容/指纹识别"
            }
            showBiometricError = true
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "验证身份以启用面容解锁"
            )
            isVerifyingBiometric = false
            if !success {
                faceIDEnabled = false
            }
        } catch let authError as LAError {
            isVerifyingBiometric = false
            faceIDEnabled = false
            switch authError.code {
            case .userCancel:
                biometricErrorMessage = "您取消了验证"
            case .biometryNotAvailable:
                biometricErrorMessage = "面容ID不可用"
            case .biometryNotEnrolled:
                biometricErrorMessage = "未设置面容ID，请在系统设置中添加"
            case .biometryLockout:
                biometricErrorMessage = "面容ID已锁定，请稍后重试"
            default:
                biometricErrorMessage = authError.localizedDescription
            }
            showBiometricError = true
        } catch {
            isVerifyingBiometric = false
            faceIDEnabled = false
            biometricErrorMessage = "验证失败"
            showBiometricError = true
        }
    }
}

// MARK: - 锁定时间选择器
struct LockTimingPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTiming: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(LockTiming.allCases) { timing in
                            Button(action: {
                                selectedTiming = timing.rawValue
                                dismiss()
                            }) {
                                HStack {
                                    Text(timing.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    if selectedTiming == timing.rawValue {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16))
                                            .foregroundColor(SpendoTheme.textPrimary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            
                            if timing != LockTiming.allCases.last {
                                Divider()
                                    .background(SpendoTheme.textTertiary.opacity(0.2))
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    .background(SpendoTheme.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("锁定时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(SpendoTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - PIN码设置视图
struct PinCodeSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedPinCode: String
    @Binding var pinCodeEnabled: Bool
    
    @State private var pinCode = ""
    @State private var confirmPinCode = ""
    @State private var isConfirmStep = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 标题
                    Text(isConfirmStep ? "再次输入密码" : "设置数字密码")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(SpendoTheme.textPrimary)
                    
                    // 密码点
                    HStack(spacing: 20) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(currentPinCode.count > index ? SpendoTheme.primary : SpendoTheme.cardBackground)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(SpendoTheme.textTertiary, lineWidth: 1)
                                )
                        }
                    }
                    
                    if showError {
                        Text("两次密码不一致，请重新输入")
                            .font(.system(size: 14))
                            .foregroundColor(SpendoTheme.accentRed)
                    }
                    
                    Spacer()
                    
                    // 数字键盘
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 24) {
                                ForEach(1...3, id: \.self) { col in
                                    let number = row * 3 + col
                                    NumberButton(number: "\(number)") {
                                        appendNumber("\(number)")
                                    }
                                }
                            }
                        }
                        
                        // 最后一行：空白、0、删除
                        HStack(spacing: 24) {
                            Color.clear
                                .frame(width: 70, height: 70)
                            
                            NumberButton(number: "0") {
                                appendNumber("0")
                            }
                            
                            Button(action: deleteNumber) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("设置密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        pinCodeEnabled = false
                        dismiss()
                    }
                    .foregroundColor(SpendoTheme.textPrimary)
                }
            }
        }
    }
    
    private var currentPinCode: String {
        isConfirmStep ? confirmPinCode : pinCode
    }
    
    private func appendNumber(_ number: String) {
        showError = false
        
        if isConfirmStep {
            if confirmPinCode.count < 4 {
                confirmPinCode += number
                
                if confirmPinCode.count == 4 {
                    if confirmPinCode == pinCode {
                        savedPinCode = pinCode
                        dismiss()
                    } else {
                        showError = true
                        confirmPinCode = ""
                    }
                }
            }
        } else {
            if pinCode.count < 4 {
                pinCode += number
                
                if pinCode.count == 4 {
                    isConfirmStep = true
                }
            }
        }
    }
    
    private func deleteNumber() {
        if isConfirmStep {
            if !confirmPinCode.isEmpty {
                confirmPinCode.removeLast()
            }
        } else {
            if !pinCode.isEmpty {
                pinCode.removeLast()
            }
        }
    }
}

// MARK: - 数字按钮
struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(SpendoTheme.textPrimary)
                .frame(width: 70, height: 70)
                .background(SpendoTheme.cardBackground)
                .clipShape(Circle())
        }
    }
}

// MARK: - 锁屏视图
struct LockScreenView: View {
    @AppStorage("faceIDEnabled") private var faceIDEnabled = false
    @AppStorage("pinCodeEnabled") private var pinCodeEnabled = false
    @AppStorage("userPinCode") private var savedPinCode = ""
    
    @Binding var isLocked: Bool
    @State private var enteredPinCode = ""
    @State private var showError = false
    @State private var isAuthenticating = false
    @State private var biometricFailed = false
    @State private var hasAttemptedAutoAuth = false
    @State private var cachedBiometricType: LABiometryType = .none
    
    // 检查是否有有效的PIN码
    private var hasPinCode: Bool {
        pinCodeEnabled && !savedPinCode.isEmpty
    }
    
    // 获取缓存的生物识别类型
    private var biometricType: LABiometryType {
        cachedBiometricType
    }
    
    private var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "faceid"
        }
    }
    
    private var biometricName: String {
        switch biometricType {
        case .faceID:
            return "面容"
        case .touchID:
            return "指纹"
        default:
            return "生物识别"
        }
    }
    
    var body: some View {
        ZStack {
            SpendoTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 仅Face ID模式（没有PIN码）
                if faceIDEnabled && !hasPinCode {
                    VStack(spacing: 20) {
                        Button(action: authenticateWithBiometrics) {
                            Image(systemName: biometricIconName)
                                .font(.system(size: 60))
                                .foregroundColor(biometricFailed ? SpendoTheme.accentRed : SpendoTheme.primary)
                        }
                        .disabled(isAuthenticating)
                        
                        Text(biometricFailed ? "验证失败，点击重试" : "点击使用\(biometricName)解锁")
                            .font(.system(size: 14))
                            .foregroundColor(biometricFailed ? SpendoTheme.accentRed : SpendoTheme.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // 仅PIN码模式或双重模式
                if hasPinCode {
                    // 如果同时启用了Face ID，显示Face ID图标
                    if faceIDEnabled {
                        Button(action: authenticateWithBiometrics) {
                            Image(systemName: biometricIconName)
                                .font(.system(size: 50))
                                .foregroundColor(SpendoTheme.primary)
                        }
                        .disabled(isAuthenticating)
                        
                        Text("或输入密码")
                            .font(.system(size: 14))
                            .foregroundColor(SpendoTheme.textTertiary)
                            .padding(.top, -10)
                    }
                    
                    // PIN码输入区域
                    VStack(spacing: 20) {
                        if !faceIDEnabled {
                            Text("输入密码")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(SpendoTheme.textPrimary)
                        }
                        
                        // 密码点
                        HStack(spacing: 20) {
                            ForEach(0..<4, id: \.self) { index in
                                Circle()
                                    .fill(enteredPinCode.count > index ? SpendoTheme.primary : SpendoTheme.cardBackground)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle()
                                            .stroke(showError ? SpendoTheme.accentRed : SpendoTheme.textTertiary, lineWidth: 1)
                                    )
                                    .animation(.easeInOut(duration: 0.1), value: enteredPinCode.count)
                            }
                        }
                        .modifier(ShakeEffect(shakes: showError ? 2 : 0))
                        
                        if showError {
                            Text("密码错误，请重试")
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.accentRed)
                        }
                    }
                    
                    Spacer()
                    
                    // 数字键盘
                    VStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 20) {
                                ForEach(1...3, id: \.self) { col in
                                    let number = row * 3 + col
                                    NumberButton(number: "\(number)") {
                                        appendPinNumber("\(number)")
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 20) {
                            if faceIDEnabled {
                                Button(action: authenticateWithBiometrics) {
                                    Image(systemName: biometricIconName)
                                        .font(.system(size: 24))
                                        .foregroundColor(SpendoTheme.textPrimary)
                                        .frame(width: 70, height: 70)
                                }
                            } else {
                                Color.clear
                                    .frame(width: 70, height: 70)
                            }
                            
                            NumberButton(number: "0") {
                                appendPinNumber("0")
                            }
                            
                            Button(action: deletePinNumber) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // 缓存生物识别类型
            let context = LAContext()
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            cachedBiometricType = context.biometryType
            
            // 只在首次出现时自动尝试 Face ID
            if faceIDEnabled && !hasAttemptedAutoAuth && !isAuthenticating {
                hasAttemptedAutoAuth = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    // 震动效果
    struct ShakeEffect: GeometryEffect {
        var shakes: Int
        var animatableData: CGFloat {
            get { CGFloat(shakes) }
            set { shakes = Int(newValue) }
        }
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            let translation = sin(animatableData * .pi * 2) * 10
            return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
        }
    }
    
    private func appendPinNumber(_ number: String) {
        showError = false
        
        if enteredPinCode.count < 4 {
            enteredPinCode += number
            
            if enteredPinCode.count == 4 {
                if enteredPinCode == savedPinCode {
                    isLocked = false
                } else {
                    showError = true
                    enteredPinCode = ""
                }
            }
        }
    }
    
    private func deletePinNumber() {
        if !enteredPinCode.isEmpty {
            enteredPinCode.removeLast()
        }
        showError = false
    }
    
    private func authenticateWithBiometrics() {
        // 防止重复调用
        guard !isAuthenticating else { return }
        
        isAuthenticating = true
        biometricFailed = false
        
        Task {
            await performBiometricAuth()
        }
    }
    
    @MainActor
    private func performBiometricAuth() async {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isAuthenticating = false
            biometricFailed = true
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "解锁Spendo"
            )
            isAuthenticating = false
            if success {
                isLocked = false
            } else {
                biometricFailed = true
            }
        } catch {
            isAuthenticating = false
            biometricFailed = true
        }
    }
}

// MARK: - App锁定管理器
class AppLockManager: ObservableObject {
    static let shared = AppLockManager()
    
    @Published var isLocked = false
    
    private var lastActiveTime: Date?
    
    private init() {
        // 检查是否需要锁定
        checkLockStatus()
    }
    
    private var faceIDEnabled: Bool {
        UserDefaults.standard.bool(forKey: "faceIDEnabled")
    }
    
    private var pinCodeEnabled: Bool {
        UserDefaults.standard.bool(forKey: "pinCodeEnabled")
    }
    
    private var lockTimingRaw: String {
        UserDefaults.standard.string(forKey: "lockTiming") ?? LockTiming.immediately.rawValue
    }
    
    var isProtectionEnabled: Bool {
        faceIDEnabled || pinCodeEnabled
    }
    
    private var lockTiming: LockTiming {
        LockTiming(rawValue: lockTimingRaw) ?? .immediately
    }
    
    func appWillResignActive() {
        lastActiveTime = Date()
    }
    
    func appDidBecomeActive() {
        checkLockStatus()
    }
    
    private func checkLockStatus() {
        guard isProtectionEnabled else {
            isLocked = false
            return
        }
        
        if let lastActive = lastActiveTime {
            let elapsed = Date().timeIntervalSince(lastActive)
            if elapsed >= Double(lockTiming.seconds) {
                isLocked = true
            }
        } else {
            // 首次启动时锁定
            isLocked = true
        }
    }
    
    func lock() {
        if isProtectionEnabled {
            isLocked = true
        }
    }
    
    func unlock() {
        isLocked = false
        lastActiveTime = nil
    }
}

// MARK: - Previews
#Preview("密码保护设置") {
    NavigationStack {
        PasswordProtectionView()
    }
}

#Preview("锁屏界面") {
    LockScreenView(isLocked: .constant(true))
}

#Preview("PIN码设置") {
    PinCodeSetupView(
        savedPinCode: .constant(""),
        pinCodeEnabled: .constant(false)
    )
}
