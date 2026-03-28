// BatteryWidget.swift
// Displays battery status

import SwiftUI

struct BatteryWidget: View {
    @StateObject private var batteryMonitor = BatteryMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: batteryIconName)
                    .font(.system(size: 14))
                    .foregroundColor(batteryColor)
                
                Text("Battery")
                    .font(AppFonts.widgetTitle)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(batteryMonitor.batteryLevel)")
                    .font(AppFonts.widgetValue)
                    .foregroundColor(AppColors.text)
                
                Text("%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if !batteryMonitor.timeRemaining.isEmpty {
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .widgetStyle()
        .hoverEffect()
    }
    
    private var batteryIconName: String {
        if batteryMonitor.isCharging {
            return "battery.100.bolt"
        }
        
        let level = batteryMonitor.batteryLevel
        if level >= 75 { return "battery.100" }
        if level >= 50 { return "battery.75" }
        if level >= 25 { return "battery.50" }
        if level >= 10 { return "battery.25" }
        return "battery.0"
    }
    
    private var batteryColor: Color {
        if batteryMonitor.isCharging { return .green }
        if batteryMonitor.batteryLevel <= 20 { return .red }
        if batteryMonitor.batteryLevel <= 40 { return .orange }
        return AppColors.text
    }
    
    private var statusText: String {
        if batteryMonitor.isCharging {
            return "⚡ \(batteryMonitor.timeRemaining) until full"
        } else {
            return "\(batteryMonitor.timeRemaining) remaining"
        }
    }
}
