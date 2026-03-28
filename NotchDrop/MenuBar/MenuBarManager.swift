// MenuBarManager.swift
// Manages the menu bar status item

import AppKit
import SwiftUI

class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    private override init() { super.init() }
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchDrop")
            button.image?.size = NSSize(width: 18, height: 18)
            button.action = #selector(togglePanel)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: "Toggle Panel", action: #selector(togglePanel), keyEquivalent: "n")
        toggleItem.keyEquivalentModifierMask = [.command, .option]
        toggleItem.target = self
        menu?.addItem(toggleItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu?.addItem(settingsItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = SettingsManager.shared.launchAtLogin ? .on : .off
        menu?.addItem(launchAtLoginItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit NotchDrop", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
    }
    
    @objc private func togglePanel() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            NotchWindowManager.shared.toggleWindow()
        }
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        SettingsManager.shared.launchAtLogin.toggle()
        sender.state = SettingsManager.shared.launchAtLogin ? .on : .off
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
