// DarkModeToggle.swift
// Dark mode toggle control

import SwiftUI
import Foundation

struct DarkModeToggle: View {
    @State private var isDarkMode = true
    
    var body: some View {
        ControlButton(
            icon: isDarkMode ? "moon.stars.fill" : "sun.max.fill",
            label: "Dark Mode",
            isActive: isDarkMode,
            action: toggleDarkMode
        )
        .onAppear {
            checkDarkModeStatus()
        }
    }
    
    private func checkDarkModeStatus() {
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        isDarkMode = appearance == "Dark"
    }
    
    private func toggleDarkMode() {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to not dark mode
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if error == nil {
                isDarkMode.toggle()
            }
        }
    }
}

// Reusable control button component
struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isActive ? AppColors.controlActive : AppColors.controlInactive)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isActive ? .white : AppColors.secondaryText)
                }
                
                Text(label)
                    .font(AppFonts.controlLabel)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
