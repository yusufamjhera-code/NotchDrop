// BatteryMonitor.swift
// Monitors battery status using IOKit

import Foundation
import Combine
import IOKit.ps

class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()
    
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var timeRemaining: String = ""
    
    private var timer: Timer?
    
    private init() {
        updateBatteryStatus()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
    }
    
    func updateBatteryStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            if let capacity = description[kIOPSCurrentCapacityKey as String] as? Int {
                self?.batteryLevel = capacity
            }
            
            if let isCharging = description[kIOPSIsChargingKey as String] as? Bool {
                self?.isCharging = isCharging
            }
            
            if let powerSource = description[kIOPSPowerSourceStateKey as String] as? String {
                self?.isPluggedIn = (powerSource == kIOPSACPowerValue as String)
            }
            
            if let timeToEmpty = description[kIOPSTimeToEmptyKey as String] as? Int, timeToEmpty > 0 {
                let hours = timeToEmpty / 60
                let minutes = timeToEmpty % 60
                self?.timeRemaining = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
            } else if let timeToFull = description[kIOPSTimeToFullChargeKey as String] as? Int, timeToFull > 0 {
                let hours = timeToFull / 60
                let minutes = timeToFull % 60
                self?.timeRemaining = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
            } else {
                self?.timeRemaining = ""
            }
        }
    }
}
