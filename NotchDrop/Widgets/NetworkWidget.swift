// NetworkWidget.swift
// Displays network status

import SwiftUI

struct NetworkWidget: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: networkIcon)
                    .font(.system(size: 14))
                    .foregroundColor(networkManager.isConnected ? .green : .red)
                
                Text("Network")
                    .font(AppFonts.widgetTitle)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(networkManager.connectionType)
                    .font(AppFonts.widgetValue)
                    .foregroundColor(AppColors.text)
                
                if networkManager.connectionType == "Wi-Fi" && !networkManager.wifiSSID.isEmpty {
                    HStack(spacing: 4) {
                        Text(networkManager.wifiSSID)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(1)
                        
                        SignalStrengthIndicator(bars: networkManager.signalBars())
                    }
                }
            }
        }
        .widgetStyle()
        .hoverEffect()
    }
    
    private var networkIcon: String {
        if !networkManager.isConnected {
            return "wifi.slash"
        }
        
        switch networkManager.connectionType {
        case "Wi-Fi":
            return "wifi"
        case "Ethernet":
            return "cable.connector"
        case "Cellular":
            return "antenna.radiowaves.left.and.right"
        default:
            return "network"
        }
    }
}

struct SignalStrengthIndicator: View {
    let bars: Int
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < bars ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + index * 2))
            }
        }
        .frame(height: 10, alignment: .bottom)
    }
}
