//
//  VoiceInputView.swift
//  Spendo
//

import SwiftUI
import Speech
import AVFoundation
import Combine

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceRecognizer = VoiceRecognizer()
    let onRecognized: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 状态提示
                    if !voiceRecognizer.permissionGranted {
                        VStack(spacing: 12) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 50))
                                .foregroundColor(SpendoTheme.accentRed)
                            Text("microphone_permission_required".localized)
                                .font(.system(size: 16))
                                .foregroundColor(SpendoTheme.textSecondary)
                            Text("open_settings_hint".localized)
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textTertiary)
                            
                            Button("settings".localized) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundColor(SpendoTheme.primary)
                            .padding(.top, 8)
                        }
                    } else {
                        // 语音动画
                        ZStack {
                            // 外圈动画
                            Circle()
                                .stroke(voiceRecognizer.isRecording ? SpendoTheme.accentRed.opacity(0.3) : SpendoTheme.textTertiary.opacity(0.2), lineWidth: 3)
                                .frame(width: 180, height: 180)
                                .scaleEffect(voiceRecognizer.isRecording ? 1.3 : 1.0)
                                .opacity(voiceRecognizer.isRecording ? 0.5 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceRecognizer.isRecording)
                            
                            // 内圈
                            Circle()
                                .fill(voiceRecognizer.isRecording ? SpendoTheme.accentRed.opacity(0.2) : SpendoTheme.cardBackground)
                                .frame(width: 150, height: 150)
                            
                            Image(systemName: voiceRecognizer.isRecording ? "waveform" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(voiceRecognizer.isRecording ? SpendoTheme.accentRed : SpendoTheme.textSecondary)
                                .symbolEffect(.variableColor, isActive: voiceRecognizer.isRecording)
                        }
                        
                        // 状态文字
                        Text(voiceRecognizer.isRecording ? "listening".localized : "tap_to_record".localized)
                            .font(.system(size: 16))
                            .foregroundColor(SpendoTheme.textSecondary)
                        
                        // 识别结果
                        VStack(spacing: 8) {
                            Text("recognition_result".localized)
                                .font(.system(size: 14))
                                .foregroundColor(SpendoTheme.textTertiary)
                            
                            Text(voiceRecognizer.recognizedText.isEmpty ? "waiting_voice_input".localized : voiceRecognizer.recognizedText)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(voiceRecognizer.recognizedText.isEmpty ? SpendoTheme.textTertiary : SpendoTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .frame(minHeight: 60)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(SpendoTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 提示
                        Text("示例：\"午饭 35块\" 或 \"买咖啡 28元\"")
                            .font(.system(size: 13))
                            .foregroundColor(SpendoTheme.textTertiary)
                    }
                    
                    Spacer()
                    
                    // 录音按钮
                    if voiceRecognizer.permissionGranted {
                        Button(action: {
                            if voiceRecognizer.isRecording {
                                voiceRecognizer.stopRecording()
                            } else {
                                voiceRecognizer.startRecording()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: voiceRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 18))
                                Text(voiceRecognizer.isRecording ? "stop_recording".localized : "start_recording".localized)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(voiceRecognizer.isRecording ? SpendoTheme.accentRed : SpendoTheme.primary)
                            .cornerRadius(30)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("voice_input".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        voiceRecognizer.stopRecording()
                        dismiss()
                    }
                    .foregroundColor(SpendoTheme.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        voiceRecognizer.stopRecording()
                        onRecognized(voiceRecognizer.recognizedText)
                        dismiss()
                    }
                    .foregroundColor(voiceRecognizer.recognizedText.isEmpty ? SpendoTheme.textTertiary : SpendoTheme.primary)
                    .disabled(voiceRecognizer.recognizedText.isEmpty)
                }
            }
            .onAppear {
                // 延迟请求权限，避免 Preview 崩溃
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    voiceRecognizer.requestPermission()
                }
            }
            .onDisappear {
                voiceRecognizer.stopRecording()
            }
        }
    }
}

// 语音识别器
class VoiceRecognizer: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var errorMessage: String = ""
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
    
    func requestPermission() {
        // 检查是否在 Preview 环境中
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            DispatchQueue.main.async {
                self.permissionGranted = true // 在 Preview 中模拟已授权
            }
            return
        }
        #endif
        
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // 请求麦克风权限
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            self?.permissionGranted = granted
                            if !granted {
                                self?.errorMessage = "麦克风权限未授权"
                            }
                        }
                    }
                case .denied:
                    self?.permissionGranted = false
                    self?.errorMessage = "语音识别权限被拒绝"
                case .restricted:
                    self?.permissionGranted = false
                    self?.errorMessage = "语音识别受限"
                case .notDetermined:
                    self?.permissionGranted = false
                    self?.errorMessage = "语音识别权限未确定"
                @unknown default:
                    self?.permissionGranted = false
                }
            }
        }
    }
    
    func startRecording() {
        // 检查是否在 Preview 环境中
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            DispatchQueue.main.async {
                self.isRecording = true
                self.recognizedText = "这是预览模式的模拟文本"
            }
            return
        }
        #endif
        
        guard permissionGranted else {
            errorMessage = "请先授权语音识别和麦克风权限"
            return
        }
        
        // 检查是否已有录音任务
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // 移除之前的 tap
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "音频会话配置失败"
            return
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建识别请求"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 检查语音识别器是否可用
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别服务不可用"
            return
        }
        
        // 创建识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self?.audioEngine.stop()
                self?.audioEngine.inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self?.isRecording = false
                }
            }
        }
        
        // 配置麦克风输入
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.recognizedText = ""
                self.errorMessage = ""
            }
        } catch {
            errorMessage = "音频引擎启动失败"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

#Preview {
    VoiceInputView { text in
        print("识别文本: \(text)")
    }
}
