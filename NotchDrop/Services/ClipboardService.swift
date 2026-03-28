// ClipboardService.swift
// Monitors the system pasteboard and maintains clipboard history

import Foundation
import AppKit
import Combine

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let preview: String // Truncated preview for display
    
    init(content: String) {
        self.content = content
        self.timestamp = Date()
        // Create a preview (first 50 chars, single line)
        let singleLine = content.replacingOccurrences(of: "\n", with: " ")
        self.preview = singleLine.count > 50 ? String(singleLine.prefix(50)) + "…" : singleLine
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.content == rhs.content
    }
}

class ClipboardService: ObservableObject {
    static let shared = ClipboardService()
    
    @Published var history: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 10
    
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        // Poll pasteboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        
        // Only process if pasteboard changed
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        // Get string content from pasteboard
        guard let content = pasteboard.string(forType: .string), !content.isEmpty else { return }
        
        // Don't add duplicates (if same as most recent)
        if let first = history.first, first.content == content { return }
        
        let newItem = ClipboardItem(content: content)
        
        DispatchQueue.main.async {
            // Add to front of history
            self.history.insert(newItem, at: 0)
            
            // Keep only last maxItems
            if self.history.count > self.maxItems {
                self.history = Array(self.history.prefix(self.maxItems))
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        
        // Update change count so we don't re-add it
        lastChangeCount = pasteboard.changeCount
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.history.removeAll()
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.history.removeAll { $0.id == item.id }
        }
    }
}
