// MediaController.swift
// Controls and monitors media playback using dynamic loading + AppleScript fallback

import Foundation
import Combine
import AppKit

// Dynamic loading of MediaRemote framework
private let mediaRemoteBundle: CFBundle? = {
    let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
    guard let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, true) else {
        return nil
    }
    return CFBundleCreate(kCFAllocatorDefault, url)
}()

// Function type definitions
private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool

// MediaRemote commands
private enum MRCommand: UInt32 {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case stop = 3
    case nextTrack = 4
    case previousTrack = 5
}

class MediaController: ObservableObject {
    static let shared = MediaController()
    
    @Published var isPlaying: Bool = false
    @Published var trackName: String = ""
    @Published var artistName: String = ""
    @Published var albumName: String = ""
    @Published var albumArtwork: NSImage?
    @Published var hasActivePlayer: Bool = false
    @Published var playingAppBundleIdentifier: String?
    
    private var timer: Timer?
    private let backgroundQueue = DispatchQueue(label: "com.notchnook.mediaMonitor", qos: .background)
    
    // Function pointers
    private var getNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private var getIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?
    private var sendCommand: MRMediaRemoteSendCommandFunction?
    
    private init() {
        loadFunctions()
        updateNowPlaying()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func loadFunctions() {
        guard let bundle = mediaRemoteBundle else { return }
        
        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) {
            getNowPlayingInfo = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        }
        
        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) {
            getIsPlaying = unsafeBitCast(pointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
        }
        
        if let pointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) {
            sendCommand = unsafeBitCast(pointer, to: MRMediaRemoteSendCommandFunction.self)
        }
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNowPlaying()
        }
    }
    
    func updateNowPlaying() {
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Step 1: Check Spotify and Apple Music directly via AppleScript
            // These are the most reliable sources of truth
            let spotifyInfo = self.runAppleScript(appName: "Spotify")
            let musicInfo = self.runAppleScript(appName: "Music")
            
            // If Spotify is actively playing, show it
            if let spotify = spotifyInfo, spotify.state == "playing" {
                self.updateUI(track: spotify.track, artist: spotify.artist, state: "playing", bundleId: "com.spotify.client", artworkData: nil, artworkUrl: spotify.artworkUrl)
                return
            }
            
            // If Apple Music is actively playing, show it
            if let music = musicInfo, music.state == "playing" {
                self.updateUI(track: music.track, artist: music.artist, state: "playing", bundleId: "com.apple.Music", artworkData: nil, artworkUrl: music.artworkUrl)
                return
            }
            
            // Step 2: Neither Spotify nor Apple Music is playing
            // Check MediaRemote for other sources (browsers, video players, etc.)
            let semaphore = DispatchSemaphore(value: 0)
            var systemInfo: [String: Any]?
            
            self.getNowPlayingInfo?(self.backgroundQueue) { info in
                systemInfo = info
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 0.5)
            
            let title = systemInfo?["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = systemInfo?["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let bundleId = systemInfo?["kMRMediaRemoteNowPlayingInfoClientBundleIdentifier"] as? String
            let playbackRate = systemInfo?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0.0
            
            // Check if system reports active playback (playbackRate > 0)
            if playbackRate > 0 {
                if !title.isEmpty {
                    self.updateUI(track: title, artist: artist, state: "playing", bundleId: bundleId, artworkData: systemInfo?["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data, artworkUrl: nil)
                } else {
                    // Playing but no title (e.g., Netflix)
                    self.updateUI(track: "Media Playing", artist: "Video", state: "playing", bundleId: bundleId ?? "com.google.Chrome", artworkData: nil, artworkUrl: nil)
                }
                return
            }
            
            // Step 3: Check for frontmost app that might be playing media
            // (browsers, video players, etc.) - show their icon as fallback
            var foundActiveApp = false
            
            DispatchQueue.main.sync {
                if let frontApp = NSWorkspace.shared.frontmostApplication {
                    let appName = frontApp.localizedName ?? "App"
                    let bundleId = frontApp.bundleIdentifier ?? ""
                    
                    // Check if it's a media-capable app (browsers, video players)
                    let mediaApps = ["chrome", "safari", "firefox", "arc", "vlc", "iina", "quicktime", "netflix"]
                    let isMediaApp = mediaApps.contains { bundleId.lowercased().contains($0) || appName.lowercased().contains($0) }
                    
                    if isMediaApp {
                        // Show the app icon with "Playing on [App]" message
                        self.updateUI(track: "Playing on \(appName)", artist: "", state: "playing", bundleId: bundleId, artworkData: nil, artworkUrl: nil)
                        foundActiveApp = true
                    }
                }
            }
            
            if foundActiveApp { return }
            
            // Step 4: Nothing is actively playing - show "Not Playing"
            self.resetUI()
        }
    }
    
    // Helper to fetch synchronous fallback info (AppleScript)
    // Prioritizes the app that is ACTIVELY PLAYING over paused apps
    private func getFallbackInfo() -> (track: String, artist: String, state: String, artworkUrl: String?, bundleId: String)? {
        // Check both apps and prioritize the one that's actually playing
        let spotifyInfo = runAppleScript(appName: "Spotify")
        let musicInfo = runAppleScript(appName: "Music")
        
        // Priority 1: Return whichever app is actively playing
        if let s = spotifyInfo, s.state == "playing" {
            return (s.track, s.artist, s.state, s.artworkUrl, "com.spotify.client")
        }
        if let m = musicInfo, m.state == "playing" {
            return (m.track, m.artist, m.state, m.artworkUrl, "com.apple.Music")
        }
        
        // Priority 2: If neither is playing, return first paused one (most recent)
        if let s = spotifyInfo {
            return (s.track, s.artist, s.state, s.artworkUrl, "com.spotify.client")
        }
        if let m = musicInfo {
            return (m.track, m.artist, m.state, m.artworkUrl, "com.apple.Music")
        }
        
        return nil
    }
    
    private var lastBundleId: String?
    
    private func updateUI(track: String, artist: String, state: String, bundleId: String?, artworkData: Data?, artworkUrl: String?) {
        DispatchQueue.main.async {
            self.hasActivePlayer = true
            self.trackName = track
            self.artistName = artist
            self.isPlaying = (state == "playing")
            
            // Detect app switch - clear artwork for fresh update
            let appSwitched = (bundleId != self.lastBundleId)
            if appSwitched {
                self.albumArtwork = nil
                self.lastArtworkUrl = nil
            }
            self.lastBundleId = bundleId
            self.playingAppBundleIdentifier = bundleId
            
            if let data = artworkData {
                self.albumArtwork = NSImage(data: data)
            } else if let urlString = artworkUrl, let url = URL(string: urlString) {
                // Download usage logic
                 if urlString != self.lastArtworkUrl {
                     self.lastArtworkUrl = urlString
                     DispatchQueue.global(qos: .background).async {
                         if let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                             DispatchQueue.main.async { self.albumArtwork = image }
                         }
                     }
                 }
            } else if bundleId == "com.apple.finder" {
                // generic icon
                self.albumArtwork = nil
            } else if let bundleId = bundleId, self.albumArtwork == nil {
                // FALLBACK: Use the App Icon itself as Large Artwork if no song cover exists
                if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    self.albumArtwork = NSWorkspace.shared.icon(forFile: appUrl.path)
                }
            }
        }
    }
    
    private func resetUI() {
        DispatchQueue.main.async {
            self.hasActivePlayer = false
            self.trackName = "Not Playing"
            self.artistName = "No music detected"
            self.albumArtwork = nil
            self.isPlaying = false
        }
    }
    
    private func runAppleScript(appName: String) -> (track: String, artist: String, state: String, artworkUrl: String?)? {
        // debug: check running apps
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" && appName == "Spotify" || 
                                             $0.bundleIdentifier == "com.apple.Music" && appName == "Music" }
        
        guard isRunning else {
            return nil
        }
        
        // 2. Direct AppleScript to the app
        var script = ""
        if appName == "Spotify" {
            script = """
            tell application "Spotify"
                if player state is playing then
                    return {name of current track, artist of current track, "playing", artwork url of current track}
                else if player state is paused then
                    return {name of current track, artist of current track, "paused", artwork url of current track}
                end if
            end tell
            """
        } else {
             // Apple Music (no easy/fast URL property, stick to basic)
             script = """
             tell application "Music"
                 if player state is playing then
                     return {name of current track, artist of current track, "playing", ""}
                 else if player state is paused then
                     return {name of current track, artist of current track, "paused", ""}
                 end if
             end tell
             """
        }
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("NotchDrop: Direct AppleScript Error for \(appName): \(error)")
                return nil
            }
            
            if output.numberOfItems >= 3 {
                let track = output.atIndex(1)?.stringValue ?? ""
                let artist = output.atIndex(2)?.stringValue ?? ""
                let state = output.atIndex(3)?.stringValue ?? ""
                let artworkUrl = (output.numberOfItems >= 4) ? output.atIndex(4)?.stringValue : nil
                return (track, artist, state, artworkUrl)
            }
        }
        return nil
    }
    
    // Track last loaded artwork URL to avoid redownloading
    private var lastArtworkUrl: String?
    
    private func updateWithFallbackInfo(_ info: (track: String, artist: String, state: String, artworkUrl: String?), bundleId: String) {
        self.hasActivePlayer = true
        self.trackName = info.track
        self.artistName = info.artist
        self.isPlaying = (info.state == "playing")
        self.playingAppBundleIdentifier = bundleId
        
        // Artwork Handling
        if let urlString = info.artworkUrl, let url = URL(string: urlString) {
             // Only download if URL changed
             if urlString != lastArtworkUrl {
                 print("NotchDrop: Downloading new artwork from \(urlString)")
                 self.lastArtworkUrl = urlString
                 
                 DispatchQueue.global(qos: .background).async {
                     if let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                         DispatchQueue.main.async { self.albumArtwork = image }
                     }
                 }
             }
        } else if info.artworkUrl == nil {
            // Reset if no artwork available (e.g. Apple Music fallback with no URL)
             if bundleId == "com.spotify.client" {
                 // Keep existing if Spotify fails temporarily, identifying mostly by track
             }
        }
    }
    
    func togglePlayPause() {
        print("NotchDrop: Toggle Play/Pause pressed...")
        
        // 1. Try MediaRemote (System Control)
        let mrSuccess = sendCommand?(MRCommand.togglePlayPause.rawValue, nil) ?? false
        print("NotchDrop: MediaRemote success check: \(mrSuccess)")
        
        // 2. Logic Change: Don't force AppleScript even if we identify as Spotify.
        // If MR failed (or claimed success but didn't work), we fall back to Physical Key.
        // Physical Key (F8) is the most reliable way to target "Whatever is playing".
        
        // We only use AppleScript if we are sure physical key isn't viable or if explicitly requested,
        // but for "User switched apps", physical key is safer.
        
        if !mrSuccess {
            print("NotchDrop: MediaRemote failed/unreliable. Simulating F8 (Play/Pause).")
            simulateMediaKey(subtype: 16) // NX_KEYTYPE_PLAY
        } else {
             // Even if MR returned true, sometimes it lies.
             // If the user reports "Not working", it's safer to just Simulate Key?
             // But simulating key might double-trigger if MR worked.
             // Let's trust MR first, but if the user keeps saying it fails... 
             // Current strict sequence: MR -> (If Fail) -> Simulate Key.
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateNowPlaying()
        }
    }
    
    func nextTrack() {
        let mrSuccess = sendCommand?(MRCommand.nextTrack.rawValue, nil) ?? false
        if !mrSuccess { simulateMediaKey(subtype: 19) } // NX_KEYTYPE_NEXT
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.updateNowPlaying() }
    }
    
    func previousTrack() {
        let mrSuccess = sendCommand?(MRCommand.previousTrack.rawValue, nil) ?? false
        if !mrSuccess { simulateMediaKey(subtype: 20) } // NX_KEYTYPE_PREVIOUS
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.updateNowPlaying() }
    }
    
    // Simulates a system-wide media key press (like pressing F8/F7/F9)
    // Requires Accessibility permissions or non-sandboxed environment
    private func simulateMediaKey(subtype: Int32) {
        // Accessibility Check
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if !isTrusted {
            print("NotchDrop: Accessibility permission MISSING. Cannot simulate media keys.")
            return
        }
        
        print("NotchDrop: Simulating Media Key (Subtype: \(subtype))")
        
        func postKey(down: Bool) {
            let flags = NSEvent.ModifierFlags(rawValue: (down ? 0xa00 : 0xb00))
            let data1 = Int((subtype << 16) | (down ? 0xa : 0xb))
            
            if let event = NSEvent.otherEvent(with: .systemDefined,
                                              location: .zero,
                                              modifierFlags: flags,
                                              timestamp: 0,
                                              windowNumber: 0,
                                              context: nil,
                                              subtype: 8,
                                              data1: data1,
                                              data2: -1) {
                event.cgEvent?.post(tap: .cghidEventTap)
            }
        }
        
        postKey(down: true)
        postKey(down: false)
    }
    
    func openPlayingApp() {
        guard let bundleId = playingAppBundleIdentifier, !bundleId.isEmpty else { return }
        
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.open(url)
        }
    }
    
    // Helper to check for specific apps for UI logic
    var isSpotify: Bool { playingAppBundleIdentifier?.contains("spotify") ?? false }
    var isAppleMusic: Bool { playingAppBundleIdentifier?.contains("Music") ?? false }
}
