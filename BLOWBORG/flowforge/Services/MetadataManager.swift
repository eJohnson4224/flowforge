//
//  MetadataManager.swift
//  flowforge
//
//  Manages project metadata storage and retrieval
//  Uses JSON files for persistence
//

import Foundation

class MetadataManager {

    // MARK: - Storage Paths
    
    /// Base directory for FlowForge data
    static var baseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("FlowForge", isDirectory: true)
    }
    
    /// Directory for metadata JSON files
    static var metadataDirectory: URL {
        baseDirectory.appendingPathComponent("metadata", isDirectory: true)
    }
    
    /// Directory for preview audio files
    static var previewsDirectory: URL {
        baseDirectory.appendingPathComponent("previews", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    /// Ensure storage directories exist
    static func initializeStorage() throws {
        let fileManager = FileManager.default
        
        // Create base directory
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
        
        // Create metadata directory
        if !fileManager.fileExists(atPath: metadataDirectory.path) {
            try fileManager.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        }
        
        // Create previews directory
        if !fileManager.fileExists(atPath: previewsDirectory.path) {
            try fileManager.createDirectory(at: previewsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Metadata Operations
    
    /// Save metadata to JSON file
    static func saveMetadata(_ metadata: ProjectMetadata) throws {
        try initializeStorage()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(metadata)
        let fileURL = metadataDirectory.appendingPathComponent("\(metadata.id.uuidString).json")
        
        try data.write(to: fileURL)
    }
    
    /// Load metadata from JSON file
    static func loadMetadata(id: UUID) throws -> ProjectMetadata? {
        let fileURL = metadataDirectory.appendingPathComponent("\(id.uuidString).json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ProjectMetadata.self, from: data)
    }
    
    /// Load metadata by file URL (searches all metadata files)
    static func loadMetadata(forFileURL fileURL: URL) throws -> ProjectMetadata? {
        let fileManager = FileManager.default

        // Ensure directory exists
        if !fileManager.fileExists(atPath: metadataDirectory.path) {
            return nil
        }

        guard let enumerator = fileManager.enumerator(at: metadataDirectory, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let metadataFileURL as URL in enumerator {
            guard metadataFileURL.pathExtension == "json" else { continue }

            do {
                let data = try Data(contentsOf: metadataFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let metadata = try decoder.decode(ProjectMetadata.self, from: data)

                // Check if this metadata matches the file URL
                if metadata.fileURL.path == fileURL.path {
                    return metadata
                }
            } catch {
                // Skip corrupted files
                continue
            }
        }
        
        return nil
    }
    
    /// Delete metadata file
    static func deleteMetadata(id: UUID) throws {
        let fileURL = metadataDirectory.appendingPathComponent("\(id.uuidString).json")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Load all metadata files
    static func loadAllMetadata() throws -> [ProjectMetadata] {
        let fileManager = FileManager.default

        // Ensure directory exists
        if !fileManager.fileExists(atPath: metadataDirectory.path) {
            return []
        }

        guard let enumerator = fileManager.enumerator(at: metadataDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        var allMetadata: [ProjectMetadata] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "json" else { continue }

            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let metadata = try decoder.decode(ProjectMetadata.self, from: data)
                allMetadata.append(metadata)
            } catch {
                print("⚠️ Failed to load metadata from \(fileURL.lastPathComponent): \(error.localizedDescription)")
                // Continue loading other files
            }
        }

        return allMetadata
    }
    
    // MARK: - Preview File Operations
    
    /// Get preview directory for a specific project
    static func previewDirectory(for projectID: UUID) -> URL {
        previewsDirectory.appendingPathComponent(projectID.uuidString, isDirectory: true)
    }
    
    /// Copy preview file to project's preview directory
    static func copyPreviewFile(from sourceURL: URL, for projectID: UUID, as filename: String) throws -> URL {
        let projectPreviewDir = previewDirectory(for: projectID)
        
        // Create project preview directory if needed
        if !FileManager.default.fileExists(atPath: projectPreviewDir.path) {
            try FileManager.default.createDirectory(at: projectPreviewDir, withIntermediateDirectories: true)
        }
        
        let destinationURL = projectPreviewDir.appendingPathComponent(filename)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // Copy file
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL
    }
}

