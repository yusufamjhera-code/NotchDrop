// DNDToggle.swift
// Do Not Disturb toggle control

import SwiftUI
import Foundation

struct DNDToggle: View {
    @State private var isEnabled = false
    
    var body: some View {
        ControlButton(
            icon: "moon.fill",
            label: "Focus",
            isActive: isEnabled,
            action: toggleDND
        )
        .onAppear {
            checkDNDStatus()
        }
    }
    
    private func checkDNDStatus() {
        // Check Focus status using defaults
        let dndDefaults = UserDefaults(suiteName: "com.apple.controlcenter")
        isEnabled = dndDefaults?.bool(forKey: "NSStatusItem Visible DoNotDisturb") ?? false
    }
    
    private func toggleDND() {
        // Use AppleScript to toggle Focus mode
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                keystroke "D" using {option down, command down}
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if error == nil {
                isEnabled.toggle()
            }
        }
    }
}
