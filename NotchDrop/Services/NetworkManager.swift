// NetworkManager.swift
// Monitors network connectivity status

import Foundation
import SystemConfiguration
import Network
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected: Bool = false
    @Published var connectionType: String = "Unknown"
    @Published var wifiSSID: String = ""
    @Published var wifiSignalStrength: Int = 0
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "Wi-Fi"
                    self?.fetchWiFiInfo()
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "Ethernet"
                } else {
                    self?.connectionType = path.status == .satisfied ? "Connected" : "Disconnected"
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func fetchWiFiInfo() {
        // Get Wi-Fi SSID using CoreWLAN (requires entitlement)
        // For personal use, we can use a simpler approach
        if let interfaces = CWWiFiClient.shared().interfaces(),
           let wifiInterface = interfaces.first {
            DispatchQueue.main.async { [weak self] in
                self?.wifiSSID = wifiInterface.ssid() ?? "Unknown"
                self?.wifiSignalStrength = wifiInterface.rssiValue()
            }
        }
    }
    
    func signalBars() -> Int {
        // Convert RSSI to bars (1-4)
        let rssi = wifiSignalStrength
        if rssi >= -50 { return 4 }
        if rssi >= -60 { return 3 }
        if rssi >= -70 { return 2 }
        if rssi >= -80 { return 1 }
        return 0
    }
}

import CoreWLAN
