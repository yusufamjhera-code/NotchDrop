// NotchContentView.swift
// Main SwiftUI view for the notch overlay

import SwiftUI

struct NotchContentView: View {
    @ObservedObject var notchState: NotchState
    @StateObject private var media = MediaController.shared
    
    var body: some View {
        ZStack {
            // When expanded - show full panel with inner glow
            if notchState.isExpanded {
                ZStack {
                    // Background
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: NotchConstants.cornerRadius,
                        bottomTrailingRadius: NotchConstants.cornerRadius,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(Color.black)
                    
                    // Mood Light - clipped inside notch
                    MoodLightView(isExpanded: true)
                    
                    ExpandedNotchView()
                        .transition(.opacity)
                }
                .frame(
                    width: NotchConstants.expandedWidth,
                    height: NotchConstants.expandedHeight
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: NotchConstants.cornerRadius,
                        bottomTrailingRadius: NotchConstants.cornerRadius,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                )
            }
            // When hovering - show collapsed panel (no mood light)
            else if notchState.isHovering {
                ZStack {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(Color(white: 0.15))
                    
                    CollapsedNotchView()
                }
                .frame(
                    width: NotchConstants.notchWidth,
                    height: NotchConstants.notchHeight
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                )
            }
        }
    }
}

// MARK: - Mood Light (Animated traveling glow)
struct MoodLightView: View {
    let isExpanded: Bool
    
    @State private var currentColor: Color = .blue
    @State private var animationProgress: CGFloat = 0
    @State private var breathingOpacity: Double = 0.4
    
    private let colorTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Static dim border as base
                ThreeSidedBorder(cornerRadius: NotchConstants.cornerRadius)
                    .stroke(currentColor.opacity(0.2), lineWidth: 2)
                
                // Left side filling light (top-left to bottom-center)
                ThreeSidedBorderLeft(cornerRadius: NotchConstants.cornerRadius)
                    .trim(from: 0, to: animationProgress)
                    .stroke(currentColor.opacity(breathingOpacity), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .blur(radius: 5)
                
                // Right side filling light (top-right to bottom-center)
                ThreeSidedBorderRight(cornerRadius: NotchConstants.cornerRadius)
                    .trim(from: 0, to: animationProgress)
                    .stroke(currentColor.opacity(breathingOpacity), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .blur(radius: 5)
                
                // Bright core of left light (solid line)
                ThreeSidedBorderLeft(cornerRadius: NotchConstants.cornerRadius)
                    .trim(from: 0, to: animationProgress)
                    .stroke(currentColor.opacity(breathingOpacity + 0.2), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                
                // Bright core of right light (solid line)
                ThreeSidedBorderRight(cornerRadius: NotchConstants.cornerRadius)
                    .trim(from: 0, to: animationProgress)
                    .stroke(currentColor.opacity(breathingOpacity + 0.2), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            .opacity(breathingOpacity) // Global breathing effect
        }
        .onAppear {
            updateColorForTime()
            startAnimation()
        }
        .onReceive(colorTimer) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                updateColorForTime()
            }
        }
    }
    
    private func startAnimation() {
        // Traveling animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationProgress = 1.0
        }
        
        // Breathing animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            breathingOpacity = 1.0
        }
    }
    
    private func updateColorForTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<7:
            currentColor = Color(hue: 0.08, saturation: 0.7, brightness: 0.9)
        case 7..<10:
            currentColor = Color(hue: 0.12, saturation: 0.6, brightness: 0.95)
        case 10..<12:
            currentColor = Color(hue: 0.15, saturation: 0.4, brightness: 1.0)
        case 12..<17:
            currentColor = Color(hue: 0.55, saturation: 0.6, brightness: 0.9)
        case 17..<20:
            currentColor = Color(hue: 0.85, saturation: 0.5, brightness: 0.85)
        case 20..<23:
            currentColor = Color(hue: 0.7, saturation: 0.6, brightness: 0.7)
        default:
            currentColor = Color(hue: 0.65, saturation: 0.7, brightness: 0.5)
        }
    }
}

// MARK: - Three-Sided Border (Left, Bottom, Right - No Top)
struct ThreeSidedBorder: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cr = min(cornerRadius, min(rect.width, rect.height) / 2)
        
        // Start from top-left, go down left side
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cr))
        
        // Bottom-left corner (arc)
        path.addArc(
            center: CGPoint(x: rect.minX + cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX - cr, y: rect.maxY))
        
        // Bottom-right corner (arc)
        path.addArc(
            center: CGPoint(x: rect.maxX - cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )
        
        // Right side going up
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        return path
    }
}


// MARK: - Left Side Path (Top-Left → Bottom-Center)
struct ThreeSidedBorderLeft: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cr = min(cornerRadius, min(rect.width, rect.height) / 2)
        
        // Start from top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Go down left side
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cr))
        
        // Bottom-left corner (arc)
        path.addArc(
            center: CGPoint(x: rect.minX + cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        // Bottom edge to center
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        return path
    }
}

// MARK: - Right Side Path (Top-Right → Bottom-Center)
struct ThreeSidedBorderRight: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cr = min(cornerRadius, min(rect.width, rect.height) / 2)
        
        // Start from top-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Go down right side
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cr))
        
        // Bottom-right corner (arc)
        path.addArc(
            center: CGPoint(x: rect.maxX - cr, y: rect.maxY - cr),
            radius: cr,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // Bottom edge to center
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        return path
    }
}


struct CollapsedNotchView: View {
    @StateObject private var media = MediaController.shared
    @State private var isHoveringBars = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - App icon when media is active
            if media.hasActivePlayer, let bundleId = media.playingAppBundleIdentifier {
                if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: appUrl.path))
                        .resizable()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.leading, 12)
                        .onTapGesture {
                            media.openPlayingApp()
                        }
                }
            }
            
            Spacer()
            
            // Right side - Audio bars (play/pause control)
            if media.hasActivePlayer {
                AudioBarsView(isPlaying: media.isPlaying, isHovering: isHoveringBars)
                    .frame(width: 24, height: 16)
                    .padding(.trailing, 12)
                    .onHover { hovering in
                        isHoveringBars = hovering
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    .onTapGesture {
                        media.togglePlayPause()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Audio Bars Animation
struct AudioBarsView: View {
    let isPlaying: Bool
    let isHovering: Bool
    
    @State private var barHeights: [CGFloat] = [0.4, 0.7, 0.5]
    
    var body: some View {
        HStack(spacing: 2) {
            if isHovering {
                // Show play/pause icon on hover
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                // Show animated audio bars
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3, height: isPlaying ? barHeights[index] * 16 : 4)
                        .animation(
                            isPlaying ? 
                                Animation.easeInOut(duration: 0.3 + Double(index) * 0.1)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1)
                            : .default,
                            value: isPlaying
                        )
                }
            }
        }
        .onAppear {
            if isPlaying {
                animateBars()
            }
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            if newValue {
                animateBars()
            }
        }
    }
    
    private func animateBars() {
        withAnimation {
            barHeights = [
                CGFloat.random(in: 0.3...1.0),
                CGFloat.random(in: 0.3...1.0),
                CGFloat.random(in: 0.3...1.0)
            ]
        }
        
        // Continue animating if still playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if isPlaying {
                animateBars()
            }
        }
    }
}
