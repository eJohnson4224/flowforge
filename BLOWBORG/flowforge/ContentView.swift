//
//  ContentView.swift
//  flowforge - Phase 1: Real Folder Integration
//
//  3-Panel Layout: Sketches | Active (4-5 slots) | Archive
//

import SwiftUI
import AppKit

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen state view
            currentStateView
                .padding(.top, 60) // Space for navigation bar

            // Top navigation bar
            VStack(spacing: 0) {
                HStack {
                    // State navigation tabs
                    HStack(spacing: 0) {
                        ForEach(WorkflowState.allCases, id: \.self) { state in
                            StateTab(
                                state: state,
                                isSelected: appState.currentState == state,
                                fileCount: fileCount(for: state),
                                maxCount: state == .active ? appState.maxActiveSlots : nil
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appState.currentState = state
                                }
                            }
                        }
                    }

                    Spacer()

                    // macOS-style toolbar buttons
                    HStack(spacing: 12) {
                        // Rescan button
                        Button(action: {
                            appState.scanAllFolders()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Rescan folders (⌘R)")

                        // Settings button
                        Button(action: {
                            appState.showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Settings (⌘,)")
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 12)
                .padding(.leading, 16)
                .background(.ultraThinMaterial)

                Divider()
            }

            // Boot/loading overlay (covers the UI until folders/metadata are ready or an error occurs)
            if appState.isBootLoading || appState.bootErrorMessage != nil {
                BootScreenView(
                    isLoading: appState.isBootLoading,
					statusMessage: appState.bootStatusMessage,
                    errorMessage: appState.bootErrorMessage,
                    onOpenSettings: {
                        appState.showingSettings = true
                    },
                    onRetry: {
                        appState.retryBootstrap()
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .environmentObject(appState)
        .sheet(isPresented: $appState.showingSettings) {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 600, height: 500)
        }
        .onReceive(NotificationCenter.default.publisher(for: .rescanFolders)) { _ in
            Task { @MainActor in
                appState.scanAllFolders()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            Task { @MainActor in
                appState.showingSettings = true
            }
        }
    }

    // MARK: - Current State View
    @ViewBuilder
    private var currentStateView: some View {
        switch appState.currentState {
        case .sketches:
            SketchesPanel(
                files: appState.sketchesFiles,
                folderURL: appState.sketchesFolderURL,
                onPromote: { file in
                    promoteToActive(file)
                }
            )

        case .active:
            ActivePanel(
                files: appState.activeFiles,
                folderURL: appState.activeFolderURL,
                maxSlots: appState.maxActiveSlots,
                onArchive: { file in
                    archiveFile(file)
                }
            )

        case .archive:
            ArchivePanel(
                files: appState.archiveFiles,
                folderURL: appState.archiveFolderURL,
                onRestore: { file in
                    restoreToActive(file)
                }
            )
        }
    }

    // MARK: - Helper
    private func fileCount(for state: WorkflowState) -> Int {
        switch state {
        case .sketches: return appState.sketchesFiles.count
        case .active: return appState.activeFiles.count
        case .archive: return appState.archiveFiles.count
        }
    }
    
    // MARK: - File Operations

    private func promoteToActive(_ file: AudioFile) {
        guard let activeFolder = appState.activeFolderURL else {
            print("⚠️ Folders not configured")
            return
        }

        guard appState.activeFiles.count < appState.maxActiveSlots else {
            print("⚠️ Active slots full! Archive a project first.")
            return
        }

        Task {
            do {
                try FolderManager.moveFile(from: file.url, to: activeFolder)
                appState.scanAllFolders()
            } catch {
                print("❌ Failed to promote file: \(error.localizedDescription)")
            }
        }
    }

    private func archiveFile(_ file: AudioFile) {
        guard let archiveFolder = appState.archiveFolderURL else {
            print("⚠️ Archive folder not configured")
            return
        }

        Task {
            do {
                try FolderManager.moveFile(from: file.url, to: archiveFolder)
                appState.scanAllFolders()
            } catch {
                print("❌ Failed to archive file: \(error.localizedDescription)")
            }
        }
    }

    private func restoreToActive(_ file: AudioFile) {
        guard let activeFolder = appState.activeFolderURL else {
            print("⚠️ Active folder not configured")
            return
        }

        guard appState.activeFiles.count < appState.maxActiveSlots else {
            print("⚠️ Active slots full! Archive a project first.")
            return
        }

        Task {
            do {
                try FolderManager.moveFile(from: file.url, to: activeFolder)
                appState.scanAllFolders()
            } catch {
                print("❌ Failed to restore file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Boot Screen Overlay

private struct BootScreenView: View {
    let isLoading: Bool
    let statusMessage: String?
    let errorMessage: String?
    let onOpenSettings: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            // Opaque enough to hide the app UI behind it
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("FlowForge")
                    .font(.title)
                    .fontWeight(.semibold)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading…")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(statusMessage ?? "Restoring folders and scanning projects")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)

                    Text("Startup failed")
                        .font(.headline)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)

                    HStack(spacing: 12) {
                        Button("Open Settings") {
                            onOpenSettings()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Retry") {
                            onRetry()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Sketches Panel
struct SketchesPanel: View {
    let files: [AudioFile]
    let folderURL: URL?
    let onPromote: (AudioFile) -> Void

    @EnvironmentObject var appState: AppState
    @State private var selectedSample: SampleFile?
    @State private var showRandomSampleExplorer = false

    var body: some View {
        HSplitView {
            // Left: Sample List
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: WorkflowState.sketches.icon)
                        .foregroundColor(.orange)
                    Text("AUDIO FILES")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Spacer()

                    if appState.isScanningSamples {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(appState.sketchesSamples.count) files")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Random Sample Explorer Button
                        Button(action: {
                            showRandomSampleExplorer = true
                        }) {
                            Image(systemName: "dice.fill")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Random Sample Explorer")

                        Button(action: {
                            print("🔄 Manual refresh triggered")
                            appState.scanSketchesSamples()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Refresh audio files")
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))

                Divider()

                // Content
                if folderURL == nil {
                    EmptyStateView(
                        message: "No folder selected",
                        icon: "folder.badge.questionmark",
                        color: .orange
                    )
                } else if appState.isScanningSamples {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Scanning for audio files...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Looking for .wav, .mp3, .mp4 files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("This may take a moment if files are in iCloud")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = appState.scanError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange.opacity(0.5))

                        Text("Scan Error")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Retry") {
                            appState.scanSketchesSamples()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.sketchesSamples.isEmpty {
                    EmptyStateView(
                        message: "No audio files found",
                        icon: "waveform.slash",
                        color: .orange
                    )
                } else {
                    // Sample list
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(appState.sketchesSamples) { sample in
                                SampleListRow(
                                    sample: sample,
                                    isSelected: selectedSample?.id == sample.id,
                                    onSelect: {
                                        selectedSample = sample
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 350, maxWidth: 500)

            // Right: Sample Detail
            if let selectedSample = selectedSample {
                SampleDetailView(sample: selectedSample)
                    .frame(minWidth: 300, idealWidth: 400)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.orange.opacity(0.3))

                    Text("Select an audio file to preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showRandomSampleExplorer) {
            RandomSampleView(
                samples: appState.sketchesSamples,
                isPresented: $showRandomSampleExplorer
            )
            .environmentObject(appState)
        }
        .onAppear {
            // Trigger sample scan if we have a folder and haven't scanned yet
            if folderURL != nil && appState.sketchesSamples.isEmpty && !appState.isScanningSamples {
                print("🔄 SketchesPanel appeared - triggering sample scan")
                appState.scanSketchesSamples()
            }
        }
    }
}

// MARK: - Sample List Row

struct SampleListRow: View {
    let sample: SampleFile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundColor(sample.isReferenced ? .orange : .gray)
                    .frame(width: 30)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(sample.name)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(sample.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(sample.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !sample.parentProjects.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(sample.parentProjectsText)
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.orange.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Active Panel
struct ActivePanel: View {
    let files: [AudioFile]
    let folderURL: URL?
    let maxSlots: Int
    let onArchive: (AudioFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: WorkflowState.active.icon)
                    .foregroundColor(.blue)
                Text("ACTIVE")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text("\(files.count)/\(maxSlots)")
                    .font(.caption)
                    .foregroundColor(files.count >= maxSlots ? .red : .secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))

            // Content
            if folderURL == nil {
                EmptyStateView(
                    message: "No folder selected",
                    icon: "folder.badge.questionmark",
                    color: .blue
                )
            } else {
                // Active project cards
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(files) { file in
                            ActiveFileCard(file: file, onArchive: {
                                onArchive(file)
                            })
                        }

                        // Empty slots
                        ForEach(0..<(maxSlots - files.count), id: \.self) { _ in
                            EmptySlotCard()
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Archive Panel
struct ArchivePanel: View {
    let files: [AudioFile]
    let folderURL: URL?
    let onRestore: (AudioFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: WorkflowState.archive.icon)
                    .foregroundColor(.gray)
                Text("ARCHIVE")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(files.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Content
            if folderURL == nil {
                EmptyStateView(
                    message: "No folder selected",
                    icon: "folder.badge.questionmark",
                    color: .gray
                )
            } else if files.isEmpty {
                EmptyStateView(
                    message: "No archived files yet",
                    icon: "archivebox",
                    color: .gray
                )
            } else {
                // Archive list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(files) { file in
                            ArchiveFileCard(file: file, onRestore: {
                                onRestore(file)
                            })
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card Components

/// Sketches file card with audio preview
struct SketchesFileCard: View {
    let file: AudioFile
    let onPromote: () -> Void

    @StateObject private var audioPreview = AudioPreviewManager.shared

    private var isPlaying: Bool {
        audioPreview.isPlaying(url: file.url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // File type icon
            HStack {
                Image(systemName: file.fileType.icon)
                    .font(.title2)
                    .foregroundColor(.orange.opacity(0.6))

                Spacer()

                // Audio preview button (only for audio files)
                if file.fileType == .audio {
                    Button(action: {
                        audioPreview.togglePlayPause(url: file.url)
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help(isPlaying ? "Pause" : "Play")
                }
            }

            Spacer()

            // File name
            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Promote button
            Button(action: onPromote) {
                HStack {
                    Text("Promote")
                        .font(.caption2)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .help("Move to Active")
        }
        .padding(12)
        .frame(height: 140)
        .background(isPlaying ? Color.orange.opacity(0.25) : Color.orange.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPlaying ? Color.orange : Color.orange.opacity(0.3), lineWidth: isPlaying ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .contextMenu {
            // macOS right-click context menu
            if file.fileType == .audio {
                Button(action: {
                    audioPreview.togglePlayPause(url: file.url)
                }) {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.circle" : "play.circle")
                }
            }

            Button(action: onPromote) {
                Label("Promote to Active", systemImage: "arrow.right.circle")
            }

            Divider()

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }
            }) {
                Label("Show in Finder", systemImage: "folder")
            }

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.open(file.url)
                }
            }) {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
        }
    }
}

/// Generic file card for other panels
struct FileCard: View {
    let file: AudioFile
    let color: Color
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // File type icon
            Image(systemName: file.fileType.icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.6))

            Spacer()

            // File name
            Text(file.name)
                .font(.caption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Action button
            Button(action: onAction) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(color)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(height: 120)
        .background(color.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Active file card with archive button
struct ActiveFileCard: View {
    let file: AudioFile
    let onArchive: () -> Void

    var body: some View {
        HStack {
            // File type icon
            Image(systemName: file.fileType.icon)
                .font(.title2)
                .foregroundColor(.blue.opacity(0.6))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onArchive) {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("Archive this project")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .contextMenu {
            Button(action: onArchive) {
                Label("Archive", systemImage: "archivebox")
            }

            Divider()

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }
            }) {
                Label("Show in Finder", systemImage: "folder")
            }

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.open(file.url)
                }
            }) {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
        }
    }
}

/// Empty slot placeholder for Active panel
struct EmptySlotCard: View {
    var body: some View {
        HStack {
            Text("Empty Slot")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: "plus.circle.dashed")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}

/// Archive file card with restore button
struct ArchiveFileCard: View {
    let file: AudioFile
    let onRestore: () -> Void

    var body: some View {
        HStack {
            // File type icon
            Image(systemName: file.fileType.icon)
                .foregroundColor(.gray.opacity(0.6))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline)
                Text("Archived")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRestore) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .help("Restore to Active")
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .contextMenu {
            Button(action: onRestore) {
                Label("Restore to Active", systemImage: "arrow.uturn.backward")
            }

            Divider()

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.activateFileViewerSelecting([file.url])
                }
            }) {
                Label("Show in Finder", systemImage: "folder")
            }

            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.open(file.url)
                }
            }) {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
        }
    }
}

/// Empty state view when no folder is selected or no files found
struct EmptyStateView: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.3))

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Configure folders in settings")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - State Tab Component
struct StateTab: View {
    let state: WorkflowState
    let isSelected: Bool
    let fileCount: Int
    let maxCount: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: state.icon)
                        .font(.title3)

                    Text(state.rawValue.uppercased())
                        .font(.headline)

                    // File count badge
                    if let max = maxCount {
                        Text("\(fileCount)/\(max)")
                            .font(.caption)
                            .foregroundColor(fileCount >= max ? .red : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("\(fileCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(isSelected ? state.color : .secondary)

                // Selection indicator
                Rectangle()
                    .fill(isSelected ? state.color : Color.clear)
                    .frame(height: 3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .frame(width: 1200, height: 700)
}
