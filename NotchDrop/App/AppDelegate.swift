// AppDelegate.swift
// Handles app lifecycle and menu bar integration

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var notchWindowManager: NotchWindowManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarManager = MenuBarManager.shared
        notchWindowManager = NotchWindowManager.shared
        menuBarManager?.setup()
        notchWindowManager?.showWindow()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        notchWindowManager?.hideWindow()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
