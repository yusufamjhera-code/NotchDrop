// ExpandedNotchView.swift
// Expanded state showing all widgets and controls matched to design

import SwiftUI
import AVFoundation

// MARK: - Expanded View
struct ExpandedNotchView: View {
    @State private var showMirror = false
    @State private var selectedTab: NotchTab = .main
    
    enum NotchTab {
        case main
        case clipboard
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                TabButton(title: "Main", icon: "square.grid.2x2", isSelected: selectedTab == .main) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .main }
                }
                
                TabButton(title: "Clipboard", icon: "doc.on.clipboard", isSelected: selectedTab == .clipboard) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .clipboard }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Content
            if selectedTab == .main {
                MainContentView(showMirror: $showMirror)
            } else {
                ClipboardView()
            }
        }
        .frame(width: 620, height: 160)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main Content (Original Layout)
struct MainContentView: View {
    @Binding var showMirror: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Music Player matched to design
            DetailedMusicPlayer()
                .frame(width: 250)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 10)
            
            // Center: Mirror/Camera (Moved here)
            MirrorSection(showMirror: $showMirror)
                .frame(width: 100)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 10)
            
            // Right: Scrollable Calendar (Moved here)
            ScrollableCalendarWidget()
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Clipboard View
struct ClipboardView: View {
    @StateObject private var clipboard = ClipboardService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if clipboard.history.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("No clipboard history")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("Copy something to see it here")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Clipboard history list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(clipboard.history) { item in
                            ClipboardItemCard(item: item) {
                                clipboard.copyToClipboard(item)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxHeight: .infinity)
                
                // Clear button
                HStack {
                    Spacer()
                    Button(action: { clipboard.clearHistory() }) {
                        Text("Clear All")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Clipboard Item Card
struct ClipboardItemCard: View {
    let item: ClipboardItem
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.preview)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(timeAgo(item.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(width: 140, height: 70, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovering ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = hovering }
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}

// MARK: - Detailed Music Player
struct DetailedMusicPlayer: View {
    @StateObject private var media = MediaController.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art with source icon
            ZStack(alignment: .bottomTrailing) {
                if let artwork = media.albumArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                
                // Source App Icon
                if let bundleId = media.playingAppBundleIdentifier {
                    // Dynamic App Icon
                    Image(nsImage: NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.path ?? ""))
                        .resizable()
                        .frame(width: 16, height: 16)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                        .offset(x: -4, y: -4)
                        .shadow(radius: 2)
                }
            }
            .onTapGesture {
                media.openPlayingApp()
            }
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            
            // Text Info & Controls
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(media.hasActivePlayer ? media.trackName : "Not Playing")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(media.hasActivePlayer ? media.artistName : "No Artist")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    Button(action: media.previousTrack) {
                        Image(systemName: "backward.fill").font(.system(size: 12))
                    }
                    Button(action: media.togglePlayPause) {
                        Image(systemName: media.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 16))
                    }
                    Button(action: media.nextTrack) {
                        Image(systemName: "forward.fill").font(.system(size: 12))
                    }
                }
                .foregroundColor(.white)
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Scrollable Calendar
struct ScrollableCalendarWidget: View {
    private let calendar = Calendar.current
    @State private var today = Date()
    @StateObject private var calendarService = CalendarService.shared
    
    // Generate dates: Today +/- 7 days
    private var daysStream: [DayInfo] {
        var days: [DayInfo] = []
        let calendar = Calendar.current
        
        // Start from -7 days ago
        if let startDate = calendar.date(byAdding: .day, value: -7, to: today) {
            // Generate 15 days total (7 back + today + 7 forward)
            for i in 0..<15 {
                if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                    days.append(DayInfo(date: date))
                }
            }
        }
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                // Month Name - tappable to open Calendar
                Text(DateFormatter.monthOnly.string(from: today))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, alignment: .leading)
                    .padding(.trailing, 8)
                    .onTapGesture {
                        calendarService.openCalendarApp()
                    }
                
                // Scrolling Days
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 10) {
                            ForEach(daysStream, id: \.self) { day in
                                VStack(spacing: 4) {
                                    Text(day.isToday ? day.weekdayFull.uppercased() : day.weekday)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(day.isToday ? .white : (day.isWeekend ? .red : .gray))
                                    
                                    Text(day.day)
                                        .font(.system(size: day.isToday ? 16 : 14, weight: day.isToday ? .bold : .medium))
                                        .foregroundColor(day.isToday ? .white : (day.isWeekend ? .red : .gray.opacity(0.8)))
                                        .frame(width: day.isToday ? 28 : 24, height: day.isToday ? 28 : 24)
                                        .background(day.isToday ? Color.blue : Color.clear)
                                        .clipShape(Circle())
                                }
                                .onTapGesture {
                                    calendarService.openCalendarApp()
                                }
                                .id(day.date) // Identify by date for scrolling
                            }
                        }
                        .padding(.horizontal, 4)
                        .onAppear {
                            // Ensure we scroll to today with a slight delay to allow layout to settle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(daysStream.first(where: { $0.isToday })?.date, anchor: .center)
                                }
                            }
                        }
                    }
                }
                .mask(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black, .black, .clear]), startPoint: .leading, endPoint: .trailing)
                )
            }
            
            // Bottom Events - Show real events
            if calendarService.hasCalendarAccess {
                if calendarService.todaysEvents.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                        Text("Nothing for today")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        calendarService.openCalendarApp()
                    }
                } else {
                    HStack(spacing: 8) {
                        ForEach(calendarService.todaysEvents.prefix(2)) { event in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(event.calendarColor))
                                    .frame(width: 6, height: 6)
                                Text(event.title)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(1)
                            }
                        }
                        if calendarService.todaysEvents.count > 2 {
                            Text("+\(calendarService.todaysEvents.count - 2) more")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    .onTapGesture {
                        calendarService.openCalendarApp()
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    Text("Grant Calendar Access")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                .onTapGesture {
                    calendarService.requestAccess()
                }
            }
        }
    }
    
    struct DayInfo: Hashable {
        let date: Date
        let weekday: String      // Single letter (T, F, S, etc.)
        let weekdayFull: String  // Three letters (Thu, Fri, Sat, etc.)
        let day: String
        let isToday: Bool
        let isWeekend: Bool
        
        init(date inputDate: Date) {
            let calendar = Calendar.current
            // Strip time for consistent ID matching
            let components = calendar.dateComponents([.year, .month, .day], from: inputDate)
            let strippedDate = calendar.date(from: components) ?? inputDate
            self.date = strippedDate
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEEE"
            self.weekday = formatter.string(from: strippedDate).uppercased()
            formatter.dateFormat = "EEE"
            self.weekdayFull = formatter.string(from: strippedDate)
            formatter.dateFormat = "d"
            self.day = formatter.string(from: strippedDate)
            self.isToday = calendar.isDateInToday(strippedDate)
            
            // Check if weekend (Saturday = 7, Sunday = 1)
            let weekdayNumber = calendar.component(.weekday, from: strippedDate)
            self.isWeekend = weekdayNumber == 1 || weekdayNumber == 7
        }
    }
}

// MARK: - Mirror Section
struct MirrorSection: View {
    @Binding var showMirror: Bool
    
    var body: some View {
        VStack {
            if showMirror {
                MirrorView()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 3)
                    )
                    .shadow(radius: 5)
                    .onTapGesture {
                        withAnimation { showMirror = false }
                    }
            } else {
                Button(action: {
                    withAnimation { showMirror = true }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text("Mirror")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Mirror Implementation
// MARK: - Mirror Implementation
struct MirrorView: View {
    @StateObject private var model = MirrorModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
                if let session = model.session {
                    CameraPreview(session: session)
                        .scaleEffect(x: -1, y: 1) // Flip horizontally for true mirror effect
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else if model.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "video.slash")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear { model.checkPermission() }
        .onDisappear { model.stopSession() }
    }
}

class MirrorModel: ObservableObject {
    @Published var session: AVCaptureSession?
    @Published var permissionDenied = false
    @Published var isLoading = true
    
    func checkPermission() {
        print("NotchDrop: Checking camera permission...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupSession() }
                else { 
                    DispatchQueue.main.async { self.permissionDenied = true; self.isLoading = false }
                }
            }
        case .denied, .restricted:
            permissionDenied = true
            isLoading = false
        @unknown default:
            break
        }
    }
    
    func setupSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("NotchDrop: Starting session setup...")
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high // Increased quality for compatibility
            
            // Try explicit discovery first
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external],
                mediaType: .video,
                position: .unspecified
            )
            
            var camera: AVCaptureDevice? = discoverySession.devices.first
            
            // Fallback: Default device
            if camera == nil {
                print("NotchDrop: Discovery failed, trying default...")
                camera = AVCaptureDevice.default(for: .video)
            }
            
            guard let device = camera else {
                print("NotchDrop: No camera found!")
                session.commitConfiguration()
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            print("NotchDrop: Using camera: \(device.localizedName)")
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                session.commitConfiguration()
                session.startRunning()
                
                DispatchQueue.main.async {
                    self.session = session
                    self.isLoading = false
                }
            } catch {
                print("NotchDrop: Camera setup error: \(error)")
                session.commitConfiguration()
                DispatchQueue.main.async { self.isLoading = false }
            }
        }
    }
    
    func stopSession() {
        guard let session = session else { return }
        DispatchQueue.global(qos: .background).async {
            if session.isRunning { session.stopRunning() }
        }
    }
}

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> CaptureVideoPreviewView {
        let view = CaptureVideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateNSView(_ nsView: CaptureVideoPreviewView, context: Context) {}
}

class CaptureVideoPreviewView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = AVCaptureVideoPreviewLayer()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer = AVCaptureVideoPreviewLayer()
    }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

extension DateFormatter {
    static let monthOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()
}
