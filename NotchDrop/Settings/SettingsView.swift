// SettingsView.swift
// Settings window UI

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            
            WidgetsSettingsView()
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
            
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Expand on Hover", isOn: $settings.expandOnHover)
            
            Text("Swipe down from notch area to expand")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct WidgetsSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        Form {
            Toggle("Battery Status", isOn: $settings.showBatteryWidget)
            Toggle("Music Player", isOn: $settings.showMusicWidget)
            Toggle("Calendar Events", isOn: $settings.showCalendarWidget)
            Toggle("System Monitor", isOn: $settings.showSystemMonitorWidget)
            Toggle("Network Status", isOn: $settings.showNetworkWidget)
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.topthird.inset.filled")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("NotchDrop")
                .font(.title).fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.caption).foregroundColor(.secondary)
            
            Text("A personal-use notch overlay for MacBook")
                .font(.body).foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
