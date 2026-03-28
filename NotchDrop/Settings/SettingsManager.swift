// SettingsManager.swift
// Manages app settings and preferences

import Foundation
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }
    
    @Published var showBatteryWidget: Bool {
        didSet { defaults.set(showBatteryWidget, forKey: "showBatteryWidget") }
    }
    
    @Published var showMusicWidget: Bool {
        didSet { defaults.set(showMusicWidget, forKey: "showMusicWidget") }
    }
    
    @Published var showCalendarWidget: Bool {
        didSet { defaults.set(showCalendarWidget, forKey: "showCalendarWidget") }
    }
    
    @Published var showSystemMonitorWidget: Bool {
        didSet { defaults.set(showSystemMonitorWidget, forKey: "showSystemMonitorWidget") }
    }
    
    @Published var showNetworkWidget: Bool {
        didSet { defaults.set(showNetworkWidget, forKey: "showNetworkWidget") }
    }
    
    @Published var expandOnHover: Bool {
        didSet { defaults.set(expandOnHover, forKey: "expandOnHover") }
    }
    
    private init() {
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showBatteryWidget = defaults.object(forKey: "showBatteryWidget") as? Bool ?? true
        showMusicWidget = defaults.object(forKey: "showMusicWidget") as? Bool ?? true
        showCalendarWidget = defaults.object(forKey: "showCalendarWidget") as? Bool ?? true
        showSystemMonitorWidget = defaults.object(forKey: "showSystemMonitorWidget") as? Bool ?? true
        showNetworkWidget = defaults.object(forKey: "showNetworkWidget") as? Bool ?? true
        expandOnHover = defaults.object(forKey: "expandOnHover") as? Bool ?? false
    }
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
