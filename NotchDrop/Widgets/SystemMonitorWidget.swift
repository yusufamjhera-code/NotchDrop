// SystemMonitorWidget.swift
// Displays CPU and RAM usage

import SwiftUI

struct SystemMonitorWidget: View {
    @StateObject private var systemMonitor = SystemMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // CPU
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 10))
                        .foregroundColor(cpuColor)
                    
                    Text("CPU")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", systemMonitor.cpuUsage))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.text)
                }
                
                ProgressBar(value: systemMonitor.cpuUsage / 100, color: cpuColor)
            }
            
            // RAM
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .font(.system(size: 10))
                        .foregroundColor(memoryColor)
                    
                    Text("RAM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f/%.0f GB", systemMonitor.memoryUsed, systemMonitor.memoryTotal))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.text)
                }
                
                ProgressBar(value: systemMonitor.memoryUsage / 100, color: memoryColor)
            }
        }
        .widgetStyle()
        .hoverEffect()
    }
    
    private var cpuColor: Color {
        if systemMonitor.cpuUsage > 80 { return .red }
        if systemMonitor.cpuUsage > 50 { return .orange }
        return .green
    }
    
    private var memoryColor: Color {
        if systemMonitor.memoryUsage > 80 { return .red }
        if systemMonitor.memoryUsage > 60 { return .orange }
        return .blue
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * CGFloat(min(value, 1.0))))
            }
        }
        .frame(height: 4)
    }
}
