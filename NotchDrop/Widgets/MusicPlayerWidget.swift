// MusicPlayerWidget.swift
// Now playing widget with playback controls

import SwiftUI

struct MusicPlayerWidget: View {
    @StateObject private var mediaController = MediaController.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if mediaController.hasActivePlayer {
                HStack(spacing: 10) {
                    // Album artwork
                    if let artwork = mediaController.albumArtwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(AppColors.secondaryText)
                            )
                    }
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mediaController.trackName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.text)
                            .lineLimit(1)
                        
                        Text(mediaController.artistName)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                // Playback controls
                HStack(spacing: 16) {
                    Spacer()
                    
                    Button(action: { mediaController.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.text)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaController.togglePlayPause() }) {
                        Image(systemName: mediaController.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.text)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { mediaController.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.text)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            } else {
                // No media playing
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("No media playing")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetStyle()
        .frame(minWidth: 160)
        .hoverEffect()
    }
}
