// DateTimeWidget.swift
// Displays current date and time

import SwiftUI

struct DateTimeWidget: View {
    @State private var currentDate = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeString)
                .font(AppFonts.time)
                .foregroundColor(AppColors.text)
                .monospacedDigit()
            
            Text(dateString)
                .font(AppFonts.date)
                .foregroundColor(AppColors.secondaryText)
        }
        .widgetStyle()
        .hoverEffect()
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentDate)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentDate)
    }
}
