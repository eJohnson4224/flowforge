//
//  SampleDetailView.swift
//  flowforge
//
//  Detail view for sample preview and metadata editing
//

import SwiftUI
import AVFoundation

struct SampleDetailView: View {
    let sample: SampleFile
    @EnvironmentObject var appState: AppState
    @ObservedObject private var audioPreview = AudioPreviewManager.shared

    @State private var isEditingMetadata = false
    @State private var digitaktStatus: DigitaktStatus = .checking
    @State private var isTransferring = false
    @State private var trimStartSeconds: Double = 0
    @State private var trimEndSeconds: Double = 0
    @State private var fadeOutSeconds: Double = 0
    @State private var fadeInEnabled: Bool = false
    @State private var fadeOutEnabled: Bool = true
    @State private var preflightInfo: SamplePreflightInfo?
    @State private var showPreflightDetails = false

    // Get or create metadata for this sample
    private var metadata: ProjectMetadata? {
        if let metadataID = sample.metadataID {
            return appState.metadataCache[metadataID]
        }
        return nil
    }

    private var isPlaying: Bool {
        audioPreview.isPlaying(url: sample.url)
    }

    // Computed properties for Digitakt button styling
    private var digitaktButtonBackground: Color {
        switch digitaktStatus {
        case .connected:
            return Color.green.opacity(0.1)
        case .cliRoutingIssue:
            return Color.orange.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }

    private var digitaktButtonForeground: Color {
        switch digitaktStatus {
        case .connected:
            return Color.green
        case .cliRoutingIssue:
            return Color.orange
        default:
            return Color.secondary
        }
    }

    private var digitaktButtonStroke: Color {
        switch digitaktStatus {
        case .connected:
            return Color.green.opacity(0.3)
        case .cliRoutingIssue:
            return Color.orange.opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    private var digitaktButtonOpacity: Double {
        (digitaktStatus.isAvailable && !isTransferring) ? 1.0 : 0.6
    }

    private var digitaktButtonDisabled: Bool {
        !digitaktStatus.isAvailable || isTransferring
    }

    private var effectiveTrimRange: SampleTrimExporter.TrimRange? {
        SampleTrimExporter.range(from: metadata, duration: sample.duration)
    }
    
    private func clampTrimValues() {
        guard let duration = sample.duration else { return }
        trimStartSeconds = max(0.0, min(trimStartSeconds, duration))
        trimEndSeconds = max(trimStartSeconds, min(trimEndSeconds, duration))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sample.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(sample.parentProjectsText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Audio Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if isPlaying {
                                audioPreview.stop()
                            } else {
                                if let range = effectiveTrimRange {
                                    audioPreview.play(url: sample.url, start: range.start, end: range.end)
                                } else {
                                    audioPreview.play(url: sample.url)
                                }
                            }
                        }) {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sample.formattedDuration)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            if isPlaying {
                                Text("Playing...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                if let range = effectiveTrimRange {
                                    Text(String(format: "Preview: %.2fs → %.2fs", range.start, range.end))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Ready to play")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }

                Divider()

                // Transfer Preflight
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Transfer Preflight")
                            .font(.headline)
                        Spacer()
                        Button(showPreflightDetails ? "Hide" : "Show") {
                            showPreflightDetails.toggle()
                        }
                        .buttonStyle(.bordered)
                    }

                    if let info = preflightInfo {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(info.formattedDuration)
                                    .font(.body)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Size")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(info.formattedSize)
                                    .font(.body)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Format")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(info.formatSummary)
                                    .font(.body)
                            }
                            Spacer()
                        }

                        if info.durationSeconds > 30.0 {
                            Text("⚠️ Over 30s. Transfer will warn; consider trimming to 30s.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        let targetRate = SampleTrimExporter.digitaktSampleRate
                        let rateKnown = info.sampleRate > 0
                        let bitDepthKnown = info.bitDepth > 0
                        let needsRate = !rateKnown || abs(info.sampleRate - targetRate) > 0.1
                        let needsChannels = info.channelCount != 1
                        let needsBitDepth = !bitDepthKnown || info.bitDepth != 16
                        if needsRate || needsChannels || needsBitDepth {
                            Text("ℹ️ Will convert to \(Int(targetRate)) Hz • 1ch • 16-bit for Digitakt transfer.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if info.sizeBytes > 64 * 1024 * 1024 {
                            Text("⚠️ Over 64MB. Digitakt project RAM limit may block import.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }

                        if let range = effectiveTrimRange,
                           let duration = sample.duration,
                           range.start > 0.001 || range.end < duration - 0.001 {
                            Text("✅ Trim-to-export enabled for transfer.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }

                        if showPreflightDetails {
                            Text(info.debugSummary)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("Loading sample details…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Trim Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trim for Preview / Transfer")
                        .font(.headline)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start (s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", value: $trimStartSeconds, formatter: SampleDetailView.secondsFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End (s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", value: $trimEndSeconds, formatter: SampleDetailView.secondsFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fade out (s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("", value: $fadeOutSeconds, formatter: SampleDetailView.secondsFormatter)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 90)
                        }

                        Spacer()
                    }

                    HStack(spacing: 16) {
                        Toggle("Fade-in", isOn: $fadeInEnabled)
                            .toggleStyle(.switch)
                        Toggle("Fade-out", isOn: $fadeOutEnabled)
                            .toggleStyle(.switch)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button("Apply 3s Padding") {
                            if let range = SampleTrimExporter.defaultRange(duration: sample.duration) {
                                trimStartSeconds = range.start
                                trimEndSeconds = range.end
                            }
                            clampTrimValues()
                        }
                        .buttonStyle(.bordered)

                        Button("Save Trim") {
                            clampTrimValues()
                            let audioFile = AudioFile(url: sample.url)
                            appState.createOrUpdateMetadata(for: audioFile) { metadata in
                                metadata.trimStartSeconds = trimStartSeconds
                                metadata.trimEndSeconds = trimEndSeconds
                                metadata.fadeOutSeconds = fadeOutSeconds
                                metadata.fadeInEnabled = fadeInEnabled
                                metadata.fadeOutEnabled = fadeOutEnabled
                                metadata.touch()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear") {
                            trimStartSeconds = 0
                            trimEndSeconds = sample.duration ?? 0
                            fadeOutSeconds = 0
                            let audioFile = AudioFile(url: sample.url)
                            appState.createOrUpdateMetadata(for: audioFile) { metadata in
                                metadata.trimStartSeconds = nil
                                metadata.trimEndSeconds = nil
                                metadata.fadeOutSeconds = nil
                                metadata.fadeInEnabled = false
                                metadata.fadeOutEnabled = true
                                metadata.touch()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("Preview uses these endpoints. Transfer uses trimmed export if range is set.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // File Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Information")
                        .font(.headline)
                    
                    InfoRow(label: "Size", value: sample.formattedFileSize)
                    InfoRow(label: "Duration", value: sample.formattedDuration)
                    InfoRow(label: "Modified", value: formatDate(sample.dateModified))
                    
                    if let relativePath = sample.relativePath {
                        InfoRow(label: "Path", value: relativePath)
                    }
                }
                
                Divider()
                
                // Project References
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.headline)

                    if !sample.parentProjects.isEmpty {
                        ForEach(sample.parentProjects, id: \.self) { project in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.orange.opacity(0.7))
                                Text(project)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.gray.opacity(0.7))
                            Text("Root folder (not in subfolder)")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Divider()

                // Custom Metadata
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Metadata")
                            .font(.headline)

                        Spacer()

                        Button(action: {
                            createOrEditMetadata()
                        }) {
                            Image(systemName: metadata == nil ? "plus.circle.fill" : "pencil.circle.fill")
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                    }

                    if let metadata = metadata {
                        // Musical Key
                        InfoRow(
                            label: "Musical Key",
                            value: metadata.musicalKey.isEmpty ? "N/A" : metadata.musicalKey
                        )

                        // BPM
                        InfoRow(
                            label: "BPM",
                            value: metadata.bpm != nil ? "\(metadata.bpm!)" : "N/A"
                        )

                        // Feel/Vibe
                        InfoRow(
                            label: "Feel / Vibe",
                            value: metadata.feel.isEmpty ? "N/A" : metadata.feel
                        )

                        // Notes
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(metadata.notes.isEmpty ? "N/A" : metadata.notes)
                                .font(.body)
                                .foregroundColor(metadata.notes.isEmpty ? .secondary : .primary)
                        }

                        // Tags
                        if !metadata.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tags")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(metadata.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }

                        // Rating
                        if let rating = metadata.rating {
                            HStack {
                                Text("Rating")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        // Show empty fields when no metadata exists
                        InfoRow(label: "Musical Key", value: "N/A")
                        InfoRow(label: "BPM", value: "N/A")
                        InfoRow(label: "Feel / Vibe", value: "N/A")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("N/A")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        Text("Click + to add metadata")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        .tint(.orange)
                    }
                }

                Divider()

                // Actions
                VStack(spacing: 12) {
                    // Digitakt Transfer Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Send to Hardware")
                                .font(.headline)
                            Spacer()

                            // Status indicator
                            HStack(spacing: 4) {
                                Image(systemName: digitaktStatus.icon)
                                    .foregroundColor(digitaktStatus.color)
                                    .font(.caption)
                                Text(digitaktStatus.statusText)
                                    .font(.caption)
                                    .foregroundColor(digitaktStatus.color)
                            }
                        }

                        // Debug Info (temporary)
                        Button("Test Elektroid Routing") {
                            testElektroidDetection()
                        }
                        .buttonStyle(.bordered)

                        // Digitakt Transfer Button
                        Button(action: {
                            transferToDigitakt()
                        }) {
                            DigitaktTransferButtonContent(
                                status: digitaktStatus,
                                isTransferring: isTransferring
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(digitaktButtonDisabled)
                        .opacity(digitaktButtonOpacity)
                    }

                    Divider()

                    // File Actions
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([sample.url])
                    }) {
                        Label("Show in Finder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            checkDigitaktStatus()
            loadTrimState()
            loadPreflightInfo()
        }
        .onChange(of: sample.id) {
            checkDigitaktStatus()
            loadTrimState()
            loadPreflightInfo()
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func createOrEditMetadata() {
        appState.createOrUpdateMetadata(for: AudioFile(url: sample.url)) { metadata in
            // This will open a metadata editor in the future
            // For now, just create the metadata entry
        }
    }

    private func loadTrimState() {
        if let metadata, let start = metadata.trimStartSeconds, let end = metadata.trimEndSeconds {
            trimStartSeconds = start
            trimEndSeconds = end
            fadeOutSeconds = metadata.fadeOutSeconds ?? 0
            fadeInEnabled = metadata.fadeInEnabled
            fadeOutEnabled = metadata.fadeOutEnabled
        } else if let range = SampleTrimExporter.defaultRange(duration: sample.duration) {
            trimStartSeconds = range.start
            trimEndSeconds = range.end
            fadeOutSeconds = 0
            fadeInEnabled = false
            fadeOutEnabled = true
        } else {
            trimStartSeconds = 0
            trimEndSeconds = 0
            fadeOutSeconds = 0
            fadeInEnabled = false
            fadeOutEnabled = true
        }
        clampTrimValues()
    }

    private func loadPreflightInfo() {
        preflightInfo = SamplePreflightInfo.from(url: sample.url, sizeBytes: sample.fileSize, durationSeconds: sample.duration ?? 0)
    }

    // MARK: - Digitakt Transfer

    private func checkDigitaktStatus() {
        digitaktStatus = .checking

        // Run check in background
        Task(priority: .utility) {
            let status = await checkDigitaktStatusAsync()
            await MainActor.run {
                digitaktStatus = status
            }
        }
    }

    private func checkDigitaktStatusAsync() async -> DigitaktStatus {
        print("🔍 Checking Digitakt status...")

        // Check if Elektroid is installed
        let isInstalled = ElektroidCLI.shared.isInstalled()
        print("  - Elektroid installed: \(isInstalled)")

        guard isInstalled else {
            print("  ❌ Elektroid not installed")
            return .notInstalled
        }

        // Check routing with elektroid-cli info 1
        do {
            let routingStatus = try ElektroidCLI.shared.checkDigitaktRouting(deviceID: nil)
            switch routingStatus {
            case .ok:
                return .connected
            case .routingIssue:
                return .routingIssue
            case .cliRoutingIssue:
                return .cliRoutingIssue
            }
        } catch {
            return .notConnected
        }
    }

    @MainActor
    private func testElektroidDetection() {
        var info = ""

        // Check if installed
        var isInstalled = ElektroidCLI.shared.isInstalled()
        info += "Elektroid Installed: \(isInstalled)\n\n"

        if !isInstalled {
            if let url = FolderManager.selectFile(prompt: "Select elektroid-cli executable") {
                do {
                    try ElektroidCLI.shared.setUserConfiguredCliURL(url)
                    isInstalled = ElektroidCLI.shared.isInstalled()
                    info += "Elektroid Installed After Selection: \(isInstalled)\n\n"
                } catch {
                    let nsError = error as NSError
                    info += """
                    ❌ Could not save elektroid-cli selection: \(error.localizedDescription)
                    domain: \(nsError.domain)
                    code: \(nsError.code)
                    userInfo: \(nsError.userInfo)
                    Tip: Copy elektroid-cli to ~/bin, select that file, and ensure it is executable (chmod +x).

                    """
                }
            } else {
                info += "⚠️ No elektroid-cli selected.\n\n"
            }
        }

        info += "--- CLI Access Debug ---\n"
        info += ElektroidCLI.shared.debugCliAccessReport()
        info += "\n\n"

        let baseInfo = info
        let shouldCheckRouting = isInstalled

        DispatchQueue.global(qos: .utility).async {
            var info = baseInfo

            if shouldCheckRouting {
                do {
                    let rawList = try ElektroidCLI.shared.listDevicesRaw(timeout: 8.0)
                    info += "elektroid-cli ld (exit \(rawList.exitCode) reason \(rawList.terminationReason))\n"
                    if !rawList.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        info += "stderr:\n\(rawList.stderr)\n"
                    }
                    info += "stdout:\n\(rawList.stdout)\n\n"

                    let resolvedID = ElektroidCLI.shared.resolveDigitaktDeviceID(fromListOutput: rawList.stdout)
                    info += "Resolved Digitakt ID: \(resolvedID ?? "none")\n\n"

                    if let resolvedID {
                        do {
                            let rawInfo = try ElektroidCLI.shared.getInfoRaw(deviceID: resolvedID, timeout: 4.0)
                            info += "elektroid-cli info \(resolvedID) (exit \(rawInfo.exitCode) reason \(rawInfo.terminationReason))\n"
                            if !rawInfo.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                info += "stderr:\n\(rawInfo.stderr)\n"
                            }
                            info += "stdout:\n\(rawInfo.stdout)\n\n"
                        } catch {
                            info += "elektroid-cli info \(resolvedID) error: \(error)\n\n"
                        }
                    }

                    if let resolvedID {
                        let routingStatus = try ElektroidCLI.shared.checkDigitaktRouting(deviceID: resolvedID)
                        switch routingStatus {
                        case .ok(let infoObj):
                            info += "✅ Routing OK\n"
                            info += "type: \(infoObj.type ?? "unknown")\n"
                            info += "name: \(infoObj.name ?? "unknown")\n"
                        case .routingIssue(let infoObj):
                            info += "⚠️ Routing Issue\n"
                            info += "type: \(infoObj.type ?? "unknown")\n"
                            info += "name: \(infoObj.name ?? "unknown")\n"
                            info += "\nSet Digitakt USB config to Audio/MIDI and try again."
                        case .cliRoutingIssue:
                            info += "⚠️ CLI Routing Issue\n"
                            info += "No output from elektroid-cli info."
                        }
                    } else {
                        info += "⚠️ Skipping routing check (no Digitakt ID).\n"
                    }
                } catch {
                    info += "❌ Error: \(error)"
                }
            }

            DispatchQueue.main.async {
                presentLongTextAlert(title: "Elektroid Routing Test", text: info)
            }
        }
    }

    private func transferToDigitakt() {
        print("🎹 Transfer to Digitakt: \(sample.name)")

        // Handle different states
        switch digitaktStatus {
        case .notInstalled:
            showElektroidNotInstalledAlert()
            return
        case .checking:
            return
        case .notConnected:
            showDigitaktNotConnectedAlert()
            return
        case .routingIssue:
            showDigitaktRoutingIssueAlert()
            return
        case .cliRoutingIssue:
            print("⚠️ CLI routing check unavailable; continuing transfer.")
        case .connected:
            break
        }

        // Start transfer
        isTransferring = true

        Task(priority: .utility) {
            do {
                // Transfer sample to /samples/SKETCHS and verify via list
                guard let deviceID = try ElektroidCLI.shared.resolveDigitaktDeviceID(preferred: "1") else {
                    throw TransferError.digitaktNotFound
                }

                let trimRange = SampleTrimExporter.clampedRange(
                    start: trimStartSeconds,
                    end: trimEndSeconds,
                    duration: sample.duration
                )
                let (uploadURL, cleanup) = try SampleTrimExporter.exportTrimmedIfNeeded(
                    url: sample.url,
                    duration: sample.duration,
                    range: trimRange,
                    fadeOutSeconds: fadeOutSeconds,
                    fadeInEnabled: fadeInEnabled,
                    fadeOutEnabled: fadeOutEnabled
                )
                defer { cleanup() }

                let targetName = uploadURL.lastPathComponent
                let exists = try ElektroidCLI.shared.remoteFileExists(
                    deviceID: deviceID,
                    folder: "/samples/SKETCHS",
                    targetName: targetName
                )
                if exists {
                    let useExisting = await confirmUseExistingFile(fileName: targetName, folder: "/samples/SKETCHS")
                    if useExisting {
                        await MainActor.run {
                            isTransferring = false
                            showTransferExistingAlert(fileName: targetName)
                        }
                    } else {
                        await MainActor.run {
                            isTransferring = false
                        }
                    }
                    return
                }

                try ElektroidCLI.shared.transferSample(
                    url: uploadURL,
                    to: deviceID,
                    folder: "/samples/SKETCHS"
                )

                await MainActor.run {
                    isTransferring = false
                    showTransferSuccessAlert()
                }

            } catch {
                print("❌ Transfer error: \(error)")
                await MainActor.run {
                    isTransferring = false
                    showTransferFailedAlert(error: error)
                }
            }
        }
    }

    // MARK: - Alerts

    private func presentAlert(_ alert: NSAlert, onResponse: ((NSApplication.ModalResponse) -> Void)? = nil) {
        if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                onResponse?(response)
            }
        } else {
            let response = alert.runModal()
            onResponse?(response)
        }
    }

    private func presentLongTextAlert(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 320))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .bezelBorder

        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.string = text
        scrollView.documentView = textView

        alert.accessoryView = scrollView
        alert.addButton(withTitle: "Copy")
        alert.addButton(withTitle: "Close")

        let copyAction = {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(text, forType: .string)
        }

        if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    copyAction()
                }
            }
        } else {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                copyAction()
            }
        }
    }

    private func showElektroidNotInstalledAlert() {
        let alert = NSAlert()
        alert.messageText = "Elektroid Not Installed"
        alert.informativeText = """
        To transfer samples to Digitakt, you need to install Elektroid CLI.

        Installation:
        1. Open Terminal
        2. Run: brew install elektroid
           (or compile from source)
        3. Connect your Digitakt via USB
        4. Restart FlowForge

        Visit github.com/dagargo/elektroid for more info.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open GitHub")

        presentAlert(alert) { response in
            if response == .alertSecondButtonReturn {
                NSWorkspace.shared.open(URL(string: "https://github.com/dagargo/elektroid")!)
            }
        }
    }

    private func showDigitaktNotConnectedAlert() {
        let alert = NSAlert()
        alert.messageText = "Digitakt Not Connected"
        alert.informativeText = """
        Could not find Digitakt connected via USB.

        Make sure:
        • Digitakt is powered on
        • USB cable is connected
        • Digitakt is recognized by your computer

        Try disconnecting and reconnecting the USB cable, then click the refresh button.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Refresh")

        presentAlert(alert) { response in
            if response == .alertSecondButtonReturn {
                checkDigitaktStatus()
            }
        }
    }

    private func showDigitaktRoutingIssueAlert() {
        let alert = NSAlert()
        alert.messageText = "Digitakt Routing Issue"
        alert.informativeText = """
        elektroid-cli info 1 reported a non-MIDI device.

        Set Digitakt USB config to Audio/MIDI (not Overbridge) and try again.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Refresh")

        presentAlert(alert) { response in
            if response == .alertSecondButtonReturn {
                checkDigitaktStatus()
            }
        }
    }

    private func showCliRoutingIssueAlert() {
        let alert = NSAlert()
        alert.messageText = "CLI Routing Issue"
        alert.informativeText = """
        No output from elektroid-cli info.

        Check USB connection, cable, and power, then try again.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Refresh")

        presentAlert(alert) { response in
            if response == .alertSecondButtonReturn {
                checkDigitaktStatus()
            }
        }
    }

    private func showTransferSuccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Transfer Complete! ✅"
        alert.informativeText = """
        Sample "\(sample.name)" has been transferred to your Digitakt.

        You can find it in the /samples/SKETCHS folder on your Digitakt.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        presentAlert(alert)
    }

    private func showTransferFailedAlert(error: Error) {
        let details = """
        Failed to transfer sample to Digitakt.

        Error: \(error.localizedDescription)

        Make sure your Digitakt is connected and has enough storage space.
        """
        presentLongTextAlert(title: "Transfer Failed", text: details)
    }

    private func showTransferExistingAlert(fileName: String) {
        let alert = NSAlert()
        alert.messageText = "File Already Exists"
        alert.informativeText = """
        A file named "\(fileName)" already exists in /samples/SKETCHS on your Digitakt.

        Kept the existing file and skipped upload.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        presentAlert(alert)
    }

    @MainActor
    private func confirmUseExistingFile(fileName: String, folder: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let alert = NSAlert()
            alert.messageText = "File Already Exists"
            alert.informativeText = """
            A file named "\(fileName)" already exists in \(folder).

            Choose Overwrite to keep the existing file (no upload), or Cancel to abort.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Overwrite")
            alert.addButton(withTitle: "Cancel")
            presentAlert(alert) { response in
                continuation.resume(returning: response == .alertFirstButtonReturn)
            }
        }
    }
}

private struct SamplePreflightInfo {
    let durationSeconds: Double
    let sizeBytes: Int64
    let sampleRate: Double
    let channelCount: Int
    let bitDepth: Int

    var formattedDuration: String {
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    var formatSummary: String {
        "\(Int(sampleRate)) Hz • \(channelCount)ch • \(bitDepth)-bit"
    }

    var debugSummary: String {
        "duration=\(durationSeconds)s\nsize=\(sizeBytes) bytes\nsampleRate=\(sampleRate)\nchannels=\(channelCount)\nbitDepth=\(bitDepth)"
    }

    static func from(url: URL, sizeBytes: Int64, durationSeconds: Double) -> SamplePreflightInfo {
        var sampleRate: Double = 0
        var channels: Int = 0
        var bitDepth: Int = 0

        if let audioFile = try? AVAudioFile(forReading: url) {
            sampleRate = audioFile.fileFormat.sampleRate
            channels = Int(audioFile.fileFormat.channelCount)
            if let bit = audioFile.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int {
                bitDepth = bit
            }
        }

        return SamplePreflightInfo(
            durationSeconds: durationSeconds,
            sizeBytes: sizeBytes,
            sampleRate: sampleRate,
            channelCount: channels,
            bitDepth: bitDepth
        )
    }
}

extension SampleDetailView {
    static let secondsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.body)

            Spacer()
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Digitakt Status

enum DigitaktStatus {
    case checking
    case notInstalled
    case notConnected
    case routingIssue
    case cliRoutingIssue
    case connected
}

extension DigitaktStatus {
    var icon: String {
        switch self {
        case .checking:
            return "antenna.radiowaves.left.and.right"
        case .notInstalled:
            return "exclamationmark.triangle"
        case .notConnected:
            return "bolt.horizontal.circle"
        case .routingIssue:
            return "bolt.horizontal.circle.badge.exclamationmark"
        case .cliRoutingIssue:
            return "bolt.horizontal.circle.badge.exclamationmark"
        case .connected:
            return "bolt.horizontal.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .checking:
            return Color.gray
        case .notInstalled:
            return Color.red
        case .notConnected:
            return Color.orange
        case .routingIssue:
            return Color.orange
        case .cliRoutingIssue:
            return Color.orange
        case .connected:
            return Color.green
        }
    }

    var statusText: String {
        switch self {
        case .checking:
            return "Checking..."
        case .notInstalled:
            return "Not Installed"
        case .notConnected:
            return "Not Connected"
        case .routingIssue:
            return "Routing Issue"
        case .cliRoutingIssue:
            return "CLI Routing Issue"
        case .connected:
            return "Connected"
        }
    }

    var isAvailable: Bool {
        self == .connected || self == .cliRoutingIssue
    }

    var subtitleText: String {
        switch self {
        case .checking:
            return ""
        case .notInstalled:
            return "Install Elektroid CLI"
        case .notConnected:
            return "Connect Digitakt via USB"
        case .routingIssue:
            return "Switch USB to Audio/MIDI"
        case .cliRoutingIssue:
            return "Check CLI routing"
        case .connected:
            return "Ready to send"
        }
    }
}

// MARK: - Digitakt Transfer Button Content

struct DigitaktTransferButtonContent: View {
    let status: DigitaktStatus
    let isTransferring: Bool

    private var baseColor: Color {
        switch status {
        case .connected:
            return Color.green
        case .cliRoutingIssue:
            return Color.orange
        default:
            return Color.gray
        }
    }

    private var backgroundColor: Color {
        baseColor.opacity(0.1)
    }

    private var foregroundColor: Color {
        switch status {
        case .connected:
            return Color.green
        case .cliRoutingIssue:
            return Color.orange
        default:
            return Color.secondary
        }
    }

    private var strokeColor: Color {
        switch status {
        case .connected:
            return Color.green.opacity(0.3)
        case .cliRoutingIssue:
            return Color.orange.opacity(0.3)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    private var subtitleText: String {
        if isTransferring {
            return "Transferring..."
        }
        return status.subtitleText
    }

    var body: some View {
        HStack {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Transfer to Digitakt")
                    .font(.body)
                    .fontWeight(.medium)

                if !subtitleText.isEmpty {
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isTransferring {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}
