//
//  FolderManager.swift
//  flowforge
//
//  Handles folder selection, file scanning, and file operations
//

import Foundation
import AppKit

class FolderManager {
    
    // MARK: - Folder Selection
    
    /// Present folder picker for user to select a folder
    @MainActor
    static func selectFolder(prompt: String) -> URL? {
        let panel = NSOpenPanel()
        panel.message = prompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK {
            return panel.url
        }
        return nil
    }

	/// Present file picker for user to select a single file (e.g., an external CLI executable).
	@MainActor
	static func selectFile(prompt: String) -> URL? {
		let panel = NSOpenPanel()
		panel.message = prompt
		panel.canChooseFiles = true
		panel.canChooseDirectories = false
		panel.allowsMultipleSelection = false
		panel.canCreateDirectories = false
		
		if panel.runModal() == .OK {
			return panel.url
		}
		return nil
	}

    // MARK: - Security-scoped bookmarks (macOS sandbox friendly)

    /// Create a security-scoped bookmark for a folder URL so access can be restored on next launch.
    ///
    /// Note: This is safe to call even if the app is not sandboxed; the bookmark will simply not be used.
    static func createSecurityScopedBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// Resolve a previously stored security-scoped bookmark into a URL.
    static func resolveSecurityScopedBookmark(_ data: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    /// Validate we can read the folder (useful for startup checks / boot gating).
    static func validateFolderReadable(_ url: URL) throws {
        _ = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
    }
    
    // MARK: - File Scanning
    
    /// Scan a folder and return all audio/project files (non-recursive, top-level only)
    static func scanFolder(at url: URL) -> [AudioFile] {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        var files: [AudioFile] = []
        
        for case let fileURL as URL in enumerator {
            // Skip subdirectories (flat scanning only)
            enumerator.skipDescendants()
            
            // Filter for supported file types
            if isSupportedFile(fileURL) {
                let audioFile = AudioFile(url: fileURL)
                files.append(audioFile)
            }
        }
        
        // Sort by date modified (newest first)
        return files.sorted { $0.dateModified > $1.dateModified }
    }
    
    /// Check if file is a supported audio/project file
    private static func isSupportedFile(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        // Allow folders (treat as projects)
        if isDirectory.boolValue {
            return true
        }
        
        // Check file extension
        let ext = url.pathExtension.lowercased()
        let supportedExtensions = [
            // Audio formats
            "wav", "mp3", "aiff", "m4a", "flac", "ogg", "aif",
            // Project formats
            "als", "flp", "logic", "ptx", "rpp"
        ]
        
        return supportedExtensions.contains(ext)
    }
    
    // MARK: - File Operations
    
    /// Move a file from one folder to another
    static func moveFile(from sourceURL: URL, to destinationFolder: URL) throws {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = destinationFolder.appendingPathComponent(fileName)
        
        // Check if file already exists at destination
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            throw FileOperationError.fileAlreadyExists
        }
        
        // Perform the move
        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
    }
    
    /// Check if a folder has reached its file limit
    static func isFolderFull(at url: URL, limit: Int) -> Bool {
        let files = scanFolder(at: url)
        return files.count >= limit
    }
    
    // MARK: - Errors
    
    enum FileOperationError: LocalizedError {
        case fileAlreadyExists
        case folderNotFound
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .fileAlreadyExists:
                return "A file with that name already exists in the destination folder"
            case .folderNotFound:
                return "The destination folder could not be found"
            case .permissionDenied:
                return "Permission denied to access this folder"
            }
        }
    }
}

