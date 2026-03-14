//
//  ProjectMetadata.swift
//  flowforge
//
//  Rich metadata model for projects across all workflow states
//

import Foundation
import AVFoundation

/// Rich metadata for a project/file
struct ProjectMetadata: Identifiable, Codable, Sendable {
    let id: UUID
    let fileURL: URL  // Reference to the actual file
    var projectName: String
    let createdDate: Date
    var lastModified: Date
    
    // Preview files
    var previewFileURL: URL?  // Main preview (archive export or latest session)
    var previewHistory: [PreviewSnapshot] = []  // Session-based previews
    
    // Basic metadata (all states)
    var notes: String = ""
    var tags: [String] = []
    var rating: Int? = nil  // 1-5 stars
    
    // Archive-specific prompts (rich reflection)
    var archivePrompts: ArchivePrompts?
    
    // Active-specific tracking
    var sessionCount: Int = 0
    var lastSessionDate: Date?
    var needsPreviewUpdate: Bool = false
    
    // Additional details
    var genre: String = ""
    var bpm: Int? = nil
    var musicalKey: String = ""
    var feel: String = ""  // Vibe/mood (e.g., "energetic", "chill", "dark")

    // Sample trim (seconds). Optional; if nil, preview uses default padding.
    var trimStartSeconds: Double? = nil
    var trimEndSeconds: Double? = nil
    var fadeOutSeconds: Double? = nil
    var fadeInEnabled: Bool = false
    var fadeOutEnabled: Bool = true
    
    init(id: UUID = UUID(), fileURL: URL, projectName: String) {
        self.id = id
        self.fileURL = fileURL
        self.projectName = projectName
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    /// Update last modified timestamp
    mutating func touch() {
        self.lastModified = Date()
    }
    
    /// Add a new preview snapshot (for Active projects)
    mutating func addPreviewSnapshot(_ snapshot: PreviewSnapshot) {
        previewHistory.append(snapshot)
        previewFileURL = snapshot.previewURL  // Update main preview to latest
        sessionCount += 1
        lastSessionDate = snapshot.date
        needsPreviewUpdate = false
        touch()
    }
    
    /// Mark that a new preview is needed
    mutating func markNeedsPreviewUpdate() {
        needsPreviewUpdate = true
        touch()
    }
}

/// A snapshot of a project preview (session-based)
struct PreviewSnapshot: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let previewURL: URL
    var sessionNotes: String
    var duration: TimeInterval?
    
    init(id: UUID = UUID(), previewURL: URL, sessionNotes: String = "") {
        self.id = id
        self.date = Date()
        self.previewURL = previewURL
        self.sessionNotes = sessionNotes
        
        // Try to get audio duration
        self.duration = AudioFileHelper.getDuration(for: previewURL)
    }
}

/// Archive-specific reflection prompts
struct ArchivePrompts: Codable, Sendable {
    var completionNotes: String = ""  // "What did you accomplish?"
    var challenges: String = ""  // "What challenges did you face?"
    var learnings: String = ""  // "What did you learn?"
    var nextSteps: String = ""  // "What would you do differently next time?"
    var mood: String = ""  // "How do you feel about this project?"
    
    /// Check if any prompts have been filled
    var hasContent: Bool {
        !completionNotes.isEmpty ||
        !challenges.isEmpty ||
        !learnings.isEmpty ||
        !nextSteps.isEmpty ||
        !mood.isEmpty
    }
}

/// Helper for audio file operations
struct AudioFileHelper {
    /// Get duration of an audio file
    static func getDuration(for url: URL) -> TimeInterval? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }

        let sampleRate = audioFile.fileFormat.sampleRate
        let frameCount = Double(audioFile.length)
        return frameCount / sampleRate
    }
    
    /// Get file size in bytes
    static func getFileSize(for url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
    
    /// Format file size for display
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Format duration for display
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
