// NotchWindowManager.swift
// Singleton manager for the notch window

import AppKit
import Combine

class NotchWindowManager: ObservableObject {
    static let shared = NotchWindowManager()
    
    private var windowController: NotchWindowController?
    private var displayChangeObserver: Any?
    
    @Published var isVisible = false
    
    private init() {
        setupDisplayChangeObserver()
    }
    
    deinit {
        if let observer = displayChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupDisplayChangeObserver() {
        displayChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDisplayChange()
        }
    }
    
    private func handleDisplayChange() {
        windowController?.positionWindow()
    }
    
    func showWindow() {
        if windowController == nil {
            windowController = NotchWindowController()
        }
        windowController?.show()
        isVisible = true
        print("NotchDrop: Window shown")
    }
    
    func hideWindow() {
        windowController?.hide()
        isVisible = false
    }
    
    func toggleWindow() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}
