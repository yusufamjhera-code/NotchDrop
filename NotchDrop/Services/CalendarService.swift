// CalendarService.swift
// Fetches calendar events using EventKit

import Foundation
import EventKit
import Combine
import AppKit

class CalendarService: ObservableObject {
    static let shared = CalendarService()
    
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var todaysEvents: [CalendarEvent] = []
    @Published var hasCalendarAccess: Bool = false
    
    private let eventStore = EKEventStore()
    private var timer: Timer?
    
    struct CalendarEvent: Identifiable {
        let id = UUID()
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let calendarColor: NSColor
        
        var timeString: String {
            if isAllDay {
                return "All day"
            }
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: startDate)
        }
        
        var isHappeningSoon: Bool {
            let minutesUntil = Date().distance(to: startDate) / 60
            return minutesUntil <= 30 && minutesUntil > 0
        }
    }
    
    private init() {
        requestAccess()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.fetchEvents()
                        self?.fetchTodaysEvents()
                        self?.startMonitoring()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.fetchEvents()
                        self?.fetchTodaysEvents()
                        self?.startMonitoring()
                    }
                }
            }
        }
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchEvents()
            self?.fetchTodaysEvents()
        }
    }
    
    func fetchEvents() {
        guard hasCalendarAccess else { return }
        
        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
            .prefix(5)
            .map { event in
                CalendarEvent(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarColor: event.calendar.color
                )
            }
        
        DispatchQueue.main.async { [weak self] in
            self?.upcomingEvents = Array(events)
        }
    }
    
    func fetchTodaysEvents() {
        guard hasCalendarAccess else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { event in
                CalendarEvent(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarColor: event.calendar.color
                )
            }
        
        DispatchQueue.main.async { [weak self] in
            self?.todaysEvents = Array(events)
        }
    }
    
    func eventsForDate(_ date: Date) -> [CalendarEvent] {
        guard hasCalendarAccess else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )
        
        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarColor: event.calendar.color
                )
            }
    }
    
    func openCalendarApp() {
        if let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
            NSWorkspace.shared.open(calendarURL)
        }
    }
}
