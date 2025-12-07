//
//  CustomButtons.swift
//  Spendo
//

import SwiftUI

// MARK: - 1. Primary Glow Button
// "Interactive call-to-action button featuring a right-arrow SVG icon and custom glow effect"
struct PrimaryGlowButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowOffset = CGSize.zero
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .offset(x: isPressed ? 5 : 0) // Arrow shift effect
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Base color
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SpendoTheme.primary) // Solid primary color
                    
                    // Glow effect (reduced)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(SpendoTheme.primary.opacity(0.4))
                        .blur(radius: 10)
                        .offset(y: 4)
                        .opacity(isPressed ? 0.6 : 0.3)
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - 2. Secondary Animated Button
// "Slide-in blur entrance, dynamic mouse-move glow, underline expansion"
struct SecondaryAnimatedButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .offset(x: isPressed ? 4 : 0)
                        .opacity(isPressed ? 1.0 : 0.6)
                }
                
                // Underline expansion
                Rectangle()
                    .fill(SpendoTheme.primary)
                    .frame(height: 2)
                    .frame(maxWidth: isPressed ? .infinity : 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThin) // Slide-in blur feel
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(isPressed ? 0.5 : 0.0), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - 3. Floating Social Icons
// "Glass morphism styling and hover effects"
struct FloatingSocialButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon) // Using SF Symbols instead of SVG for demo
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Material.ultraThinMaterial) // Glassmorphism
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(isPressed ? 1.1 : 1.0) // Hover/Press effect
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
    }
}

// Helper Button Style to track press state
struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// Preview
struct CustomButtons_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background to show glassmorphism
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Design System Components")
                    .font(.headline)
                
                VStack(spacing: 20) {
                    Text("Primary Glow Button")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    PrimaryGlowButton(title: "Get Started") {}
                }
                
                VStack(spacing: 20) {
                    Text("Secondary Animated Button")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecondaryAnimatedButton(title: "Book a Call") {}
                }
                
                VStack(spacing: 20) {
                    Text("Floating Social Icons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 20) {
                        FloatingSocialButton(icon: "message.fill") {} // Twitter/Message placeholder
                        FloatingSocialButton(icon: "envelope.fill") {}
                        FloatingSocialButton(icon: "phone.fill") {}
                    }
                }
            }
        }
    }
}
