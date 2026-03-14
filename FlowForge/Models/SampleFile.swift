//
//  SampleFile.swift
//  flowforge
//
//  Model representing an audio sample with metadata
//

import Foundation
import AVFoundation

/// Represents an audio sample file with metadata about its source projects
struct SampleFile: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let name: String
    let fileSize: Int64
    let dateModified: Date
    let duration: TimeInterval?

    /// Which project folders contain this sample
    let parentProjects: [String]  // Project folder names

    /// Which .als project files reference this sample
    let sourceProjects: [String]

    /// Whether this sample is referenced by any project
    var isReferenced: Bool {
        !sourceProjects.isEmpty
    }

    /// Relative path from the Sketches folder
    let relativePath: String?

    /// Link to custom metadata (if exists)
    var metadataID: UUID?
    
    init(url: URL, parentProjects: [String] = [], sourceProjects: [String] = [], relativePath: String? = nil, metadataID: UUID? = nil) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.parentProjects = parentProjects
        self.sourceProjects = sourceProjects
        self.relativePath = relativePath
        self.metadataID = metadataID
        
        // Get file attributes
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            self.fileSize = attributes[.size] as? Int64 ?? 0
            self.dateModified = attributes[.modificationDate] as? Date ?? Date()
        } else {
            self.fileSize = 0
            self.dateModified = Date()
        }
        
        // Get audio duration
        self.duration = Self.getDuration(for: url)
    }
    
    // MARK: - Computed Properties
    
    /// Formatted file size (e.g., "1.2 MB")
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Formatted duration (e.g., "0:03")
    var formattedDuration: String {
        guard let duration = duration else { return "—" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Display text for parent projects
    var parentProjectsText: String {
        if parentProjects.isEmpty {
            return "Loose file (not in project folder)"
        } else if parentProjects.count == 1 {
            return parentProjects[0]
        } else {
            return "\(parentProjects.count) projects"
        }
    }

    /// Display text for source projects
    var sourceProjectsText: String {
        if sourceProjects.isEmpty {
            return "⚠️ Not used in any project"
        } else if sourceProjects.count == 1 {
            return "from: \(sourceProjects[0])"
        } else {
            return "from: \(sourceProjects.count) projects"
        }
    }
    
    // MARK: - Audio Duration
    
    private static func getDuration(for url: URL) -> TimeInterval? {
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            return nil
        }
        
        let frameCount = Double(audioFile.length)
        let sampleRate = audioFile.fileFormat.sampleRate
        
        guard sampleRate > 0 else { return nil }
        return frameCount / sampleRate
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SampleFile, rhs: SampleFile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Reference (from .als parsing)

/// Represents a sample reference found in an Ableton project
struct SampleReference: Sendable {
    let projectName: String
    let samplePath: String  // Can be relative or absolute
    let isRelative: Bool
    
    /// Resolve the sample path relative to a base URL
    func resolveURL(relativeTo baseURL: URL) -> URL? {
        if isRelative {
            return baseURL.appendingPathComponent(samplePath)
        } else {
            return URL(fileURLWithPath: samplePath)
        }
    }
}

