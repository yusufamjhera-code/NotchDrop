// CalendarWidget.swift
// Shows upcoming calendar events

import SwiftUI

struct CalendarWidget: View {
    @StateObject private var calendarService = CalendarService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.accent)
                
                Text("Upcoming")
                    .font(AppFonts.widgetTitle)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
            }
            
            if calendarService.hasCalendarAccess {
                if calendarService.upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(calendarService.upcomingEvents.prefix(3)) { event in
                            CalendarEventRow(event: event)
                        }
                    }
                }
            } else {
                Button(action: { calendarService.requestAccess() }) {
                    Text("Grant Calendar Access")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .widgetStyle()
        .hoverEffect()
    }
}

struct CalendarEventRow: View {
    let event: CalendarService.CalendarEvent
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(event.calendarColor))
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11, weight: event.isHappeningSoon ? .semibold : .regular))
                    .foregroundColor(AppColors.text)
                    .lineLimit(1)
                
                Text(event.timeString)
                    .font(.system(size: 9))
                    .foregroundColor(event.isHappeningSoon ? AppColors.accent : AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
}
