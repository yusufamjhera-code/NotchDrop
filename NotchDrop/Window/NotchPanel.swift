// NotchPanel.swift
// Custom NSPanel subclass for the notch overlay

import AppKit
import SwiftUI

class NotchPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configurePanel()
    }
    
    private func configurePanel() {
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar + 1
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        styleMask.insert(.nonactivatingPanel)
        acceptsMouseMovedEvents = true
        hasShadow = false
        ignoresMouseEvents = false
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
