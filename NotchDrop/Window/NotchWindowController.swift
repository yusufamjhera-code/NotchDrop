// NotchWindowController.swift
// Controller for the NotchPanel window

import AppKit
import SwiftUI
import Combine

// Observable state for SwiftUI views
class NotchState: ObservableObject {
    @Published var isExpanded = false
    @Published var isHovering = false
}

class NotchWindowController: NSWindowController {
    private var hostingView: NSHostingView<NotchContentView>?
    private var trackingArea: NSTrackingArea?
    
    let notchState = NotchState()
    
    private var scrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var mouseMonitor: Any?
    private var accumulatedScrollY: CGFloat = 0
    private var accumulatedScrollX: CGFloat = 0
    private var lastScrollTime: Date = Date()
    private var lastSwipeTime: Date = Date.distantPast
    
    convenience init() {
        let panel = NotchPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: panel)
        setupContentView()
        setupTrackingArea()
        setupScrollGestureMonitor()
        setupMouseTrackingForCollapse()
        print("NotchDrop: Controller initialized")
    }
    
    private func setupContentView() {
        guard let panel = window as? NotchPanel else { return }
        let contentView = NotchContentView(notchState: notchState)
        hostingView = NSHostingView(rootView: contentView)
        hostingView?.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = hostingView
    }
    
    private func setupTrackingArea() {
        guard let contentView = window?.contentView else { return }
        trackingArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(trackingArea!)
    }
    
    private func setupScrollGestureMonitor() {
        print("NotchDrop: Setting up scroll monitor...")
        
        scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }
        
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
            return event
        }
        
        print("NotchDrop: Scroll monitor setup complete")
    }
    
    private func setupMouseTrackingForCollapse() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkMousePosition()
        }
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkMousePosition()
            return event
        }
    }
    
    private func checkMousePosition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let screenTop = screen.frame.maxY
        let screenCenterX = screen.frame.midX
        
        // Define the notch hover area
        let hoverWidth: CGFloat = NotchConstants.notchWidth + 100
        let hoverHeight: CGFloat = 50
        
        let isNearNotch = abs(mouseLocation.x - screenCenterX) < (hoverWidth / 2) &&
                          mouseLocation.y > screenTop - hoverHeight
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.notchState.isExpanded {
                // Check if we should collapse
                if let window = self.window {
                    let expandedFrame = window.frame.insetBy(dx: -20, dy: -20)
                    if !NSMouseInRect(mouseLocation, expandedFrame, false) {
                        self.collapsePanel()
                    }
                }
            } else {
                // Update hover state
                if isNearNotch != self.notchState.isHovering {
                    self.notchState.isHovering = isNearNotch
                }
            }
        }
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let screenTop = screen.frame.maxY
        let screenCenterX = screen.frame.midX
        
        let notchAreaWidth: CGFloat = 500
        let topAreaHeight: CGFloat = 150
        
        let isInNotchXArea = abs(mouseLocation.x - screenCenterX) < (notchAreaWidth / 2)
        let isNearTop = mouseLocation.y > screenTop - topAreaHeight
        
        // Reset accumulators if scrolling stopped
        if Date().timeIntervalSince(lastScrollTime) > 0.3 {
            accumulatedScrollY = 0
            accumulatedScrollX = 0
        }
        lastScrollTime = Date()
        
        let deltaY = event.scrollingDeltaY
        let deltaX = event.scrollingDeltaX
        
        // Only process gestures when near the notch area
        guard isInNotchXArea && isNearTop else { return }
        
        // HORIZONTAL SWIPE: Two-finger swipe for track control
        // Only active when notch is COLLAPSED (to avoid conflict with expanded controls)
        if !notchState.isExpanded {
            // Prevent rapid-fire triggers with a cooldown
            let swipeCooldown: TimeInterval = 0.5
            if Date().timeIntervalSince(lastSwipeTime) > swipeCooldown {
                accumulatedScrollX += deltaX
                
                let swipeThreshold: CGFloat = 50
                
                if accumulatedScrollX > swipeThreshold {
                    // Swipe RIGHT → Next track (natural direction)
                    print("NotchDrop: Swipe RIGHT → Next track")
                    MediaController.shared.nextTrack()
                    accumulatedScrollX = 0
                    lastSwipeTime = Date()
                } else if accumulatedScrollX < -swipeThreshold {
                    // Swipe LEFT → Previous track
                    print("NotchDrop: Swipe LEFT → Previous track")
                    MediaController.shared.previousTrack()
                    accumulatedScrollX = 0
                    lastSwipeTime = Date()
                }
            }
        }
        
        // VERTICAL SCROLL: Expand panel (existing logic)
        if !notchState.isExpanded {
            let absScroll = abs(deltaY)
            
            if absScroll > 2 {
                accumulatedScrollY += absScroll
                
                if accumulatedScrollY > 15 {
                    print("NotchDrop: EXPANDING!")
                    expandPanel()
                    accumulatedScrollY = 0
                }
            }
        }
    }
    
    private func expandPanel() {
        guard !notchState.isExpanded else { return }
        
        // Set state and update window directly
        notchState.isExpanded = true
        print("NotchDrop: isExpanded set to TRUE")
        
        // Update window size immediately
        updateWindowSizeForState(expanded: true)
    }
    
    private func collapsePanel() {
        guard notchState.isExpanded else { return }
        
        // Set state and update window directly
        notchState.isExpanded = false
        print("NotchDrop: isExpanded set to FALSE")
        
        // Update window size immediately
        updateWindowSizeForState(expanded: false)
    }
    
    override func mouseEntered(with event: NSEvent) {}
    
    override func mouseExited(with event: NSEvent) {
        collapsePanel()
    }
    
    private func updateWindowSizeForState(expanded: Bool) {
        guard let window = window else { return }
        
        // Calculate window size based on state
        let width: CGFloat
        let height: CGFloat
        
        if expanded {
            width = NotchConstants.expandedWidth
            height = NotchConstants.expandedHeight
        } else {
            width = NotchConstants.notchWidth
            height = NotchConstants.notchHeight
        }
        
        print("NotchDrop: Setting window size to \(width) x \(height)")
        
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.frame
        
        let x: CGFloat
        if expanded {
            x = screenFrame.midX - (width / 2)
        } else {
            x = screenFrame.midX - (width / 2)
        }
        
        let y = screenFrame.maxY - height
        
        let newFrame = NSRect(x: x, y: y, width: width, height: height)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true, animate: true)
        }
    }
    
    func positionWindow() {
        guard let window = window else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let screenFrame = screen.frame
        
        // Use ears width when media is playing
        let width = NotchConstants.notchWidth
        let height = NotchConstants.notchHeight
        
        let x = screenFrame.midX - (width / 2)
        
        let y = screenFrame.maxY - height
        
        let frame = NSRect(x: x, y: y, width: width, height: height)
        window.setFrame(frame, display: true)
    }
    
    func show() {
        positionWindow()
        window?.orderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}
