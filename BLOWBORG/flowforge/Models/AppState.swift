//
//  AppState.swift
//  flowforge
//
//  Central state management for the app
//  Manages folder paths and file data across all workflow states
//

import SwiftUI
import Combine

/// The three workflow states that define the creative flow
enum WorkflowState: String, CaseIterable {
    case sketches = "Sketches"
    case active = "Active"
    case archive = "Archive"

    var color: Color {
        switch self {
        case .sketches: return .orange
        case .active: return .blue
        case .archive: return .gray
        }
    }

    var icon: String {
        switch self {
        case .sketches: return "lightbulb.fill"
        case .active: return "flame.fill"
        case .archive: return "archivebox.fill"
        }
    }
}

/// Represents a file in the workflow
struct AudioFile: Identifiable, Equatable, Sendable {
    let id = UUID()
    let url: URL
    let name: String
    let dateModified: Date
    let fileType: FileType

    // NEW: Link to metadata (if exists)
    var metadataID: UUID?

    enum FileType: Sendable {
        case audio      // .wav, .mp3, .aiff, .m4a
        case project    // .als, .flp, etc.
        case folder     // Treat folders as projects

        var icon: String {
            switch self {
            case .audio: return "waveform"
            case .project: return "doc.fill"
            case .folder: return "folder.fill"
            }
        }
    }

    /// Create from URL with automatic type detection
    init(url: URL, metadataID: UUID? = nil) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.metadataID = metadataID

        // Get modification date
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let modDate = attributes[.modificationDate] as? Date {
            self.dateModified = modDate
        } else {
            self.dateModified = Date()
        }

        // Determine file type
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            self.fileType = .folder
        } else {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "wav", "mp3", "aiff", "m4a", "flac", "ogg", "aif":
                self.fileType = .audio
            case "als", "flp", "logic", "ptx", "rpp":
                self.fileType = .project
            default:
                self.fileType = .audio // Default to audio
            }
        }
    }

    /// Check if this file has associated metadata
    var hasMetadata: Bool {
        metadataID != nil
    }
}

/// Main app state - single source of truth
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var sketchesFiles: [AudioFile] = []
    @Published var activeFiles: [AudioFile] = []
    @Published var archiveFiles: [AudioFile] = []

    @Published var sketchesFolderURL: URL?
    @Published var activeFolderURL: URL?
    @Published var archiveFolderURL: URL?

    @Published var isScanning: Bool = false
    @Published var isScanningSamples: Bool = false
    @Published var showingSettings: Bool = false
    @Published var currentState: WorkflowState = .sketches
    @Published var scanError: String? = nil

    // Boot gating (used to show a startup screen until folders/metadata are loaded or an error occurs)
    @Published var isBootLoading: Bool = true
    @Published var bootErrorMessage: String? = nil
	@Published var bootStatusMessage: String? = nil

	private let bootMaxAttempts: Int = 5
	private let bootTimeoutSeconds: TimeInterval = 25
	private var bootstrapRunID: UUID = UUID()

    // Default state to show on launch (separate from current state)
    @Published var defaultState: WorkflowState = .sketches {
        didSet {
            // Persist default state preference
            UserDefaults.standard.set(defaultState.rawValue, forKey: defaultStateKey)
        }
    }

    // NEW: Metadata cache (loaded on demand)
    @Published var metadataCache: [UUID: ProjectMetadata] = [:]

    // NEW: Samples from Sketches folder
    @Published var sketchesSamples: [SampleFile] = []

    // MARK: - Constants

    let maxActiveSlots = 5

    // MARK: - UserDefaults Keys

    private let sketchesPathKey = "sketchesFolderPath"
    private let activePathKey = "activeFolderPath"
    private let archivePathKey = "archiveFolderPath"
    private let sketchesBookmarkKey = "sketchesFolderBookmark"
    private let activeBookmarkKey = "activeFolderBookmark"
    private let archiveBookmarkKey = "archiveFolderBookmark"
    private let defaultStateKey = "defaultWorkflowState"

    // MARK: - Security-scoped access

    /// Tracks which URLs we've started security-scoped access for so we can stop on teardown.
    private var securityScopedAccessedPaths: Set<String> = []
    private var securityScopedAccessedURLs: [URL] = []

    // MARK: - Initialization

    init() {
        // Initialize storage directories
        try? MetadataManager.initializeStorage()

        Task { @MainActor in
            await bootstrap()
        }
    }

    deinit {
        // Best-effort cleanup (no-op if not sandboxed)
        for url in securityScopedAccessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    // MARK: - Metadata Management

    /// Retry the full boot sequence (useful if folder permissions are missing).
    func retryBootstrap() {
        Task { @MainActor in
            await bootstrap()
        }
    }

    private enum BootError: LocalizedError {
        case folderNotReadable(name: String, url: URL, underlying: Error)

        var errorDescription: String? {
            switch self {
            case let .folderNotReadable(name, url, underlying):
                return "Cannot access the \(name) folder at:\n\(url.path)\n\n\(underlying.localizedDescription)\n\nPlease re-select the folder in Settings.\n\nIf App Sandbox is enabled, ensure Signing & Capabilities → App Sandbox → User Selected File is enabled (Read/Write)."
            }
        }
    }

    /// Boot sequence: restore folders (incl. security-scoped bookmarks), validate access, load metadata, and scan folders.
    private func bootstrap() async {
		let runID = UUID()
		bootstrapRunID = runID

        isBootLoading = true
        bootErrorMessage = nil
		bootStatusMessage = "Starting…"
		print("🚀 [Boot] Starting bootstrap run \(runID)")

		// Restore folder URLs (incl bookmarks)
		bootStatusMessage = "Restoring folders…"
		loadFolderPaths()

		do {
				try await withTimeout(seconds: bootTimeoutSeconds) { @MainActor in
					try await self.withRetry(maxAttempts: self.bootMaxAttempts, baseDelaySeconds: 0.5) { attempt in
					if self.bootstrapRunID != runID { throw CancellationError() }
					self.bootStatusMessage = "Validating folders (attempt \(attempt)/\(self.bootMaxAttempts))…"
					print("🔁 [Boot] Validate attempt \(attempt)/\(self.bootMaxAttempts)")
					// Re-load each attempt in case stale bookmarks need refreshing
					self.loadFolderPaths()
					try await self.validateConfiguredFoldersReadable()
				}
			}
		} catch {
			print("❌ [Boot] Bootstrap failed: \(error)")
			bootErrorMessage = error.localizedDescription
			bootStatusMessage = nil
			isBootLoading = false
			return
		}

		guard bootstrapRunID == runID else { return }
		bootStatusMessage = "Loading metadata…"
		await refreshMetadataCacheFromDisk()

		guard bootstrapRunID == runID else { return }
		bootStatusMessage = "Scanning folders…"
		await scanAllFoldersAsync()

		guard bootstrapRunID == runID else { return }
		bootStatusMessage = nil
		isBootLoading = false
		print("✅ [Boot] Bootstrap completed run \(runID)")
    }

	private struct BootTimeoutError: LocalizedError {
		let seconds: TimeInterval
		var errorDescription: String? {
			"Startup timed out after \(Int(seconds))s."
		}
	}

	private func withTimeout<T>(seconds: TimeInterval, operation: @escaping @MainActor @Sendable () async throws -> T) async throws -> T {
		try await withThrowingTaskGroup(of: T.self) { group in
			group.addTask {
				try await operation()
			}
			group.addTask {
				try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
				throw BootTimeoutError(seconds: seconds)
			}

			let result = try await group.next()!
			group.cancelAll()
			return result
		}
	}

	private func withRetry<T>(maxAttempts: Int, baseDelaySeconds: TimeInterval, operation: @escaping @MainActor (_ attempt: Int) async throws -> T) async throws -> T {
		precondition(maxAttempts >= 1)
		var lastError: Error?

		for attempt in 1...maxAttempts {
			do {
				if Task.isCancelled { throw CancellationError() }
				return try await operation(attempt)
			} catch {
				lastError = error
				if attempt >= maxAttempts { break }

				let delay = baseDelaySeconds * pow(1.8, Double(attempt - 1))
				print("⚠️ [Boot] Attempt \(attempt) failed: \(error). Retrying in \(String(format: "%.1f", delay))s")
				try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
			}
		}

		throw lastError ?? BootTimeoutError(seconds: 0)
	}

    private func validateConfiguredFoldersReadable() async throws {
        if let url = sketchesFolderURL {
            try await validateFolderReadable(url, name: "Sketches")
        }
        if let url = activeFolderURL {
            try await validateFolderReadable(url, name: "Active")
        }
        if let url = archiveFolderURL {
            try await validateFolderReadable(url, name: "Archive")
        }
    }

    private func validateFolderReadable(_ url: URL, name: String) async throws {
        startAccessingIfNeeded(url)
        do {
            try await Task.detached(priority: .userInitiated) { @Sendable in
                try FolderManager.validateFolderReadable(url)
            }.value
        } catch {
            throw BootError.folderNotReadable(name: name, url: url, underlying: error)
        }
    }

    private func refreshMetadataCacheFromDisk() async {
        do {
            let allMetadata = try await Task.detached(priority: .utility) { @Sendable in
                try MetadataManager.loadAllMetadata()
            }.value

            // Replace cache in one shot
            var newCache: [UUID: ProjectMetadata] = [:]
            for metadata in allMetadata {
                newCache[metadata.id] = metadata
            }
            metadataCache = newCache
        } catch {
            print("❌ Failed to load metadata: \(error.localizedDescription)")
        }
    }

    /// Get metadata for a file
    func getMetadata(for file: AudioFile) -> ProjectMetadata? {
        guard let metadataID = file.metadataID else { return nil }
        return metadataCache[metadataID]
    }

    /// Save metadata and update cache
    func saveMetadata(_ metadata: ProjectMetadata) {
        Task { @MainActor in
            do {
                try MetadataManager.saveMetadata(metadata)
                metadataCache[metadata.id] = metadata
            } catch {
                print("❌ Failed to save metadata: \(error.localizedDescription)")
            }
        }
    }

    /// Create or update metadata for a file
    func createOrUpdateMetadata(for file: AudioFile, update: (inout ProjectMetadata) -> Void) {
        var metadata: ProjectMetadata

        if let existingID = file.metadataID, let existing = metadataCache[existingID] {
            metadata = existing
        } else {
            metadata = ProjectMetadata(fileURL: file.url, projectName: file.name)
        }

        update(&metadata)
        saveMetadata(metadata)

        // Update file's metadata ID if needed
        updateFileMetadataID(file, metadataID: metadata.id)
    }

    /// Update a file's metadata ID reference
    private func updateFileMetadataID(_ file: AudioFile, metadataID: UUID) {
        // Update in appropriate array
        if let index = sketchesFiles.firstIndex(where: { $0.id == file.id }) {
            var updatedFile = sketchesFiles[index]
            updatedFile.metadataID = metadataID
            sketchesFiles[index] = updatedFile
        } else if let index = activeFiles.firstIndex(where: { $0.id == file.id }) {
            var updatedFile = activeFiles[index]
            updatedFile.metadataID = metadataID
            activeFiles[index] = updatedFile
        } else if let index = archiveFiles.firstIndex(where: { $0.id == file.id }) {
            var updatedFile = archiveFiles[index]
            updatedFile.metadataID = metadataID
            archiveFiles[index] = updatedFile
        }
    }
    
    // MARK: - Folder Management
    
    func loadFolderPaths() {
        // Prefer security-scoped bookmarks when available (required for sandboxed apps)
        sketchesFolderURL = loadFolderURL(bookmarkKey: sketchesBookmarkKey, pathKey: sketchesPathKey)
        activeFolderURL = loadFolderURL(bookmarkKey: activeBookmarkKey, pathKey: activePathKey)
        archiveFolderURL = loadFolderURL(bookmarkKey: archiveBookmarkKey, pathKey: archivePathKey)

        // Load default state preference
        if let stateRaw = UserDefaults.standard.string(forKey: defaultStateKey),
           let state = WorkflowState(rawValue: stateRaw) {
            defaultState = state
            currentState = state  // Set current state to default on launch
        }
    }

    func saveFolderPaths() {
        saveFolderURL(sketchesFolderURL, bookmarkKey: sketchesBookmarkKey, pathKey: sketchesPathKey)
        saveFolderURL(activeFolderURL, bookmarkKey: activeBookmarkKey, pathKey: activePathKey)
        saveFolderURL(archiveFolderURL, bookmarkKey: archiveBookmarkKey, pathKey: archivePathKey)
        // Note: defaultState is saved automatically via didSet
    }

    private func loadFolderURL(bookmarkKey: String, pathKey: String) -> URL? {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            do {
                let (url, isStale) = try FolderManager.resolveSecurityScopedBookmark(bookmarkData)
                startAccessingIfNeeded(url)

                // Refresh stale bookmarks so future launches keep working
                if isStale {
                    saveFolderURL(url, bookmarkKey: bookmarkKey, pathKey: pathKey)
                }
                return url
            } catch {
                print("❌ Failed to resolve bookmark for \(bookmarkKey): \(error)")
                // Fall back to path string if present
            }
        }

        if let path = UserDefaults.standard.string(forKey: pathKey) {
            let url = URL(fileURLWithPath: path)
            startAccessingIfNeeded(url)
            return url
        }

        return nil
    }

    private func saveFolderURL(_ url: URL?, bookmarkKey: String, pathKey: String) {
        guard let url else {
            UserDefaults.standard.removeObject(forKey: pathKey)
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            return
        }

        // Keep a human-readable fallback
        UserDefaults.standard.set(url.path, forKey: pathKey)

        // Start security-scoped access early (important for sandbox + bookmark creation)
        startAccessingIfNeeded(url)

        // Persist security-scoped bookmark when possible
        do {
            let bookmark = try FolderManager.createSecurityScopedBookmark(for: url)
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        } catch {
            // If bookmark creation fails, we still keep the path.
            print("⚠️ Failed to create bookmark for \(url.path): \(error)")
        }
    }

	@discardableResult
	private func startAccessingIfNeeded(_ url: URL) -> Bool {
        let path = url.path
		guard !securityScopedAccessedPaths.contains(path) else { return true }

		let ok = url.startAccessingSecurityScopedResource()
		if ok {
            securityScopedAccessedPaths.insert(path)
            securityScopedAccessedURLs.append(url)
        }
		return ok
    }
    
    func scanAllFolders() {
        Task { @MainActor in
            await scanAllFoldersAsync()
        }
    }

    private func scanAllFoldersAsync() async {
        isScanning = true
        defer { isScanning = false }

        let metadataPathIndex = buildMetadataPathIndex()

        async let sketches = scanFolderDetached(sketchesFolderURL, metadataPathIndex: metadataPathIndex)
        async let active = scanFolderDetached(activeFolderURL, metadataPathIndex: metadataPathIndex)
        async let archive = scanFolderDetached(archiveFolderURL, metadataPathIndex: metadataPathIndex)

        sketchesFiles = await sketches
        activeFiles = await active
        archiveFiles = await archive

        // Scan samples from Sketches folder (runs in its own background task)
        scanSketchesSamples()
    }

    private func buildMetadataPathIndex() -> [String: UUID] {
        var index: [String: UUID] = [:]
        for metadata in metadataCache.values {
            index[metadata.fileURL.path] = metadata.id
        }
        return index
    }

    private func scanFolderDetached(_ url: URL?, metadataPathIndex: [String: UUID]) async -> [AudioFile] {
        guard let url else { return [] }
        startAccessingIfNeeded(url)

        return await Task.detached(priority: .userInitiated) { @Sendable in
            var files = FolderManager.scanFolder(at: url)

            // Link metadata (from in-memory cache) by matching file paths
            for index in files.indices {
                if let metadataID = metadataPathIndex[files[index].url.path] {
                    files[index].metadataID = metadataID
                }
            }
            return files
        }.value
    }

    /// Scan Sketches folder for all samples (recursively)
    func scanSketchesSamples() {
        print("🔍 [AppState] scanSketchesSamples() called")

        guard let folderURL = sketchesFolderURL else {
            print("❌ [AppState] No sketches folder URL set")
            sketchesSamples = []
            return
        }

        // Ensure we have access (important when restored via security-scoped bookmark)
        startAccessingIfNeeded(folderURL)

        print("🔍 [AppState] Sketches folder URL: \(folderURL.path)")

        Task { @MainActor in
            print("🔍 [AppState] Starting Task on MainActor")
            isScanningSamples = true
            scanError = nil
            defer {
                print("🔍 [AppState] Scan complete, setting isScanningSamples = false")
                isScanningSamples = false
            }

            print("🔍 [AppState] Starting sample scan...")

            // Check if folder is accessible
            guard FileManager.default.fileExists(atPath: folderURL.path) else {
                scanError = "Folder not accessible. If files are in iCloud, please download them first."
                print("❌ [AppState] Folder not accessible: \(folderURL.path)")
                return
            }

            print("✅ [AppState] Folder exists and is accessible")

            // Run scanning in background with timeout (increased to 120 seconds)
            do {
                print("🔍 [AppState] Starting background scan with 120s timeout...")
                let samples = try await withTimeout(seconds: 120) {
                    await Task.detached { @Sendable in
                        await SampleScanner.scanSamples(in: folderURL)
                    }.value
                }

                print("🔍 [AppState] Background scan completed, got \(samples.count) samples")

                // Link metadata to samples (using in-memory cache)
                let metadataPathIndex = buildMetadataPathIndex()
                let samplesWithMetadata = samples.map { sample -> SampleFile in
                    if let metadataID = metadataPathIndex[sample.url.path] {
                        return SampleFile(
                            url: sample.url,
                            parentProjects: sample.parentProjects,
                            sourceProjects: sample.sourceProjects,
                            relativePath: sample.relativePath,
                            metadataID: metadataID
                        )
                    }
                    return sample
                }

                sketchesSamples = samplesWithMetadata
                print("✅ Loaded \(samplesWithMetadata.count) audio files from Sketches")

                if samples.isEmpty {
                    scanError = "No audio files found (.wav, .mp3, .mp4)"
                }
            } catch {
                scanError = "Scan timeout (120s). Large folder or iCloud files downloading. Try clicking refresh button."
                print("❌ Sample scan error: \(error)")
                print("💡 Tip: If you have many files or iCloud files, the scan may take longer. Try the refresh button again.")
            }
        }
    }

    /// Helper to run async task with timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }

    // Note: folder scanning now runs in a background task via `scanFolderDetached`.
}

struct TimeoutError: Error {}


