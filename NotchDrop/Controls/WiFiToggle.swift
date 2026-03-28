// WiFiToggle.swift
// Wi-Fi toggle control

import SwiftUI
import CoreWLAN

struct WiFiToggle: View {
    @State private var isEnabled = true
    
    var body: some View {
        ControlButton(
            icon: "wifi",
            label: "Wi-Fi",
            isActive: isEnabled,
            action: toggleWiFi
        )
        .onAppear {
            checkWiFiStatus()
        }
    }
    
    private func checkWiFiStatus() {
        if let wifiInterface = CWWiFiClient.shared().interface() {
            isEnabled = wifiInterface.powerOn()
        }
    }
    
    private func toggleWiFi() {
        guard let wifiInterface = CWWiFiClient.shared().interface() else { return }
        
        do {
            try wifiInterface.setPower(!isEnabled)
            isEnabled.toggle()
        } catch {
            print("Failed to toggle Wi-Fi: \(error)")
        }
    }
}
