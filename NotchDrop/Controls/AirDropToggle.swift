// AirDropToggle.swift
// AirDrop toggle control

import SwiftUI
import Foundation

struct AirDropToggle: View {
    @State private var isEnabled = true
    
    var body: some View {
        ControlButton(
            icon: "airplayaudio",
            label: "AirDrop",
            isActive: isEnabled,
            action: toggleAirDrop
        )
        .onAppear {
            checkAirDropStatus()
        }
    }
    
    private func checkAirDropStatus() {
        // Check AirDrop discoverability using shell command
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "com.apple.sharingd", "DiscoverableMode"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                isEnabled = output != "Off"
            }
        } catch {
            print("Failed to check AirDrop status: \(error)")
        }
    }
    
    private func toggleAirDrop() {
        // Toggle AirDrop using shell command
        let mode = isEnabled ? "Off" : "Contacts Only"
        
        let script = """
        do shell script "defaults write com.apple.sharingd DiscoverableMode -string '\(mode)' && killall sharingd"
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
