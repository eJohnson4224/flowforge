//
//  SampleScanner.swift
//  flowforge
//
//  Scans folders for audio samples and matches them to source projects
//

import Foundation

/// Scans folders for audio samples and builds metadata
class SampleScanner {

    // MARK: - Public Methods

    /// Scan a folder for all audio samples (.wav, .WAV, .mp3, .mp4)
    static func scanSamples(in folderURL: URL) async -> [SampleFile] {
        print("🔍 [SampleScanner] Starting scan in: \(folderURL.path)")
        print("🔍 [SampleScanner] Folder exists: \(FileManager.default.fileExists(atPath: folderURL.path))")

        // Check if folder is accessible
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("❌ [SampleScanner] Folder not accessible or not a directory")
            return []
        }

        print("🔍 [SampleScanner] Folder is directory: \(isDirectory.boolValue)")

        // Find all audio files recursively (.wav, .WAV, .mp3, .mp4)
        print("🔍 [SampleScanner] Starting audio file search...")
        let allAudioFiles = findAudioFiles(in: folderURL)
        print("🎵 [SampleScanner] Found \(allAudioFiles.count) audio files")

        // Print first few files for debugging
        if !allAudioFiles.isEmpty {
            print("🎵 [SampleScanner] Audio files found:")
            for (index, file) in allAudioFiles.prefix(5).enumerated() {
                print("   \(index + 1). \(file.lastPathComponent)")
            }
            if allAudioFiles.count > 5 {
                print("   ... and \(allAudioFiles.count - 5) more")
            }
        }

        // If no audio files, return early
        guard !allAudioFiles.isEmpty else {
            print("⚠️ No audio files found in \(folderURL.path)")
            print("   Looking for: .wav, .WAV, .mp3, .mp4")
            print("   Check if files are downloaded from iCloud")
            return []
        }

        // Build SampleFile objects
        var samples: [SampleFile] = []

        for audioURL in allAudioFiles {
            // Calculate relative path from folder
            let relativePath = audioURL.path.replacingOccurrences(
                of: folderURL.path + "/",
                with: ""
            )

            // Determine parent project folder(s)
            let parentProjects = getParentProjects(for: audioURL, baseFolder: folderURL)

            print("📦 Creating sample: \(audioURL.lastPathComponent) (parent: \(parentProjects.joined(separator: ", ")))")

            let sample = SampleFile(
                url: audioURL,
                parentProjects: parentProjects,
                sourceProjects: [],  // No .als parsing
                relativePath: relativePath
            )
            samples.append(sample)
        }

        // Sort by name
        samples.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        print("✅ Created \(samples.count) sample objects")
        return samples
    }

    // MARK: - Helper Methods

    /// Determine which project folder(s) contain this sample
    private static func getParentProjects(for sampleURL: URL, baseFolder: URL) -> [String] {
        var parentProjects: [String] = []

        // Get the path components between base folder and sample
        let basePath = baseFolder.path
        let samplePath = sampleURL.path

        // Remove base path to get relative path
        guard samplePath.hasPrefix(basePath) else {
            return []
        }

        let relativePath = String(samplePath.dropFirst(basePath.count + 1))
        let components = relativePath.split(separator: "/").map(String.init)

        // If sample is directly in base folder (no subdirectories)
        if components.count == 1 {
            return []  // Loose file
        }

        // First component is the project folder name
        let projectFolder = components[0]
        parentProjects.append(projectFolder)

        return parentProjects
    }

    // MARK: - File Finding

    /// Find all audio files recursively in folder (.wav, .WAV, .mp3, .mp4)
    private static func findAudioFiles(in folderURL: URL) -> [URL] {
        print("🔍 [SampleScanner] Creating file enumerator...")

        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey, .ubiquitousItemDownloadingStatusKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("❌ Failed to create enumerator for: \(folderURL.path)")
            return []
        }

        var audioFiles: [URL] = []
        var cloudFileCount = 0
        var totalFilesScanned = 0

        // Supported audio extensions
        let supportedExtensions = ["wav", "mp3", "mp4", "m4a"]

        print("🔍 [SampleScanner] Starting file enumeration...")

        for case let fileURL as URL in enumerator {
            totalFilesScanned += 1

            // Progress update every 100 files
            if totalFilesScanned % 100 == 0 {
                print("🔍 [SampleScanner] Scanned \(totalFilesScanned) files, found \(audioFiles.count) audio files so far...")
            }

            // Check if it's a directory
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
               let isDirectory = resourceValues.isDirectory,
               isDirectory {
                // Continue into subdirectories
                continue
            }

            // Check for audio extensions (case-insensitive)
            let ext = fileURL.pathExtension.lowercased()
            if supportedExtensions.contains(ext) {
                // Check if file is in iCloud and not downloaded
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
                   let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus,
                   downloadStatus == .notDownloaded {
                    cloudFileCount += 1
                    print("☁️ File in iCloud (not downloaded): \(fileURL.lastPathComponent)")
                } else {
                    audioFiles.append(fileURL)
                }
            }
        }

        print("🔍 [SampleScanner] Enumeration complete. Scanned \(totalFilesScanned) total files")

        if cloudFileCount > 0 {
            print("⚠️ Found \(cloudFileCount) files in iCloud that are not downloaded")
        }

        return audioFiles
    }
}

