// NotchDropApp.swift
// Main entry point for the NotchDrop application

import SwiftUI
import AppKit

@main
struct NotchDropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        checkAccessibility()
    }
    
    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        print("NotchDrop: App Trusted in Accessibility: \(isTrusted)")
    }
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
