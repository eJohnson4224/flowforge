//
//  AudioPreviewManager.swift
//  flowforge
//
//  Manages audio playback for file previews
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPreviewManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPlaying: Bool = false
    @Published var currentlyPlayingURL: URL?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var playbackEndTime: TimeInterval?
    
    // MARK: - Singleton
    
    static let shared = AudioPreviewManager()

    private init() {
        // Configure audio session (iOS only)
        #if os(iOS)
        configureAudioSession()
        #endif
    }

    // MARK: - Audio Session Configuration

    #if os(iOS)
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: - Playback Control
    
    /// Play audio file at URL
    func play(url: URL) {
        play(url: url, start: nil, end: nil)
    }

    /// Play audio file at URL with optional trim range.
    func play(url: URL, start: TimeInterval?, end: TimeInterval?) {
        // If already playing this file, just resume
        if currentlyPlayingURL == url && audioPlayer != nil {
            audioPlayer?.play()
            isPlaying = true
            startTimer()
            return
        }
        
        // Stop current playback
        stop()
        
        // Load new audio file
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            
            currentlyPlayingURL = url
            duration = audioPlayer?.duration ?? 0
            if let start, start > 0 {
                audioPlayer?.currentTime = start
                currentTime = start
            } else {
                currentTime = 0
            }
            playbackEndTime = end
            
            audioPlayer?.play()
            isPlaying = true
            startTimer()
            
        } catch {
            print("❌ Failed to play audio: \(error.localizedDescription)")
            isPlaying = false
            currentlyPlayingURL = nil
        }
    }
    
    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    /// Stop playback and reset
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingURL = nil
        currentTime = 0
        duration = 0
        playbackEndTime = nil
        stopTimer()
    }
    
    /// Toggle play/pause for a specific file
    func togglePlayPause(url: URL) {
        if currentlyPlayingURL == url && isPlaying {
            pause()
        } else if currentlyPlayingURL == url && !isPlaying {
            play(url: url)
        } else {
            play(url: url)
        }
    }
    
    /// Check if a specific file is currently playing
    func isPlaying(url: URL) -> Bool {
        return currentlyPlayingURL == url && isPlaying
    }
    
    // MARK: - Playback Timer
    
    private func startTimer() {
        stopTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateCurrentTime()
            }
        }
    }
    
    private func stopTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateCurrentTime() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime

        if let end = playbackEndTime, currentTime >= end {
            stop()
            return
        }
        
        // Auto-stop when finished
        if !player.isPlaying && currentTime > 0 {
            stop()
        }
    }
    
    // MARK: - Seek
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    // MARK: - Cleanup

    deinit {
        // Cleanup must be nonisolated - directly stop player and timer
        audioPlayer?.stop()
        playbackTimer?.invalidate()
    }
}
