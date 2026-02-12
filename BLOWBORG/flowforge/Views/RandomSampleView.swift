//
//  RandomSampleView.swift
//  flowforge
//
//  Random sample selector with notes and quick actions
//

import SwiftUI
import AVFoundation

struct RandomSampleView: View {
    let samples: [SampleFile]
    @Binding var isPresented: Bool
    
    @State private var currentSample: SampleFile?
    @State private var notes: String = ""
    @State private var musicalKey: String = ""
    @State private var bpm: String = ""
    @State private var feel: String = ""
    
    @ObservedObject private var audioPreview = AudioPreviewManager.shared
    @EnvironmentObject var appState: AppState
	
	@State private var isTransferringToDigitakt: Bool = false
    
    private var isPlaying: Bool {
        guard let sample = currentSample else { return false }
        return audioPreview.isPlaying(url: sample.url)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🎲 Random Sample Explorer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Current Sample Display
                    if let sample = currentSample {
                        VStack(spacing: 16) {
                            // Sample Info Card
                            VStack(spacing: 12) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.orange)
                                
                                Text(sample.name)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Label(sample.formattedDuration, systemImage: "clock")
                                    Label(sample.formattedFileSize, systemImage: "doc")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                if !sample.parentProjects.isEmpty {
                                    Label(sample.parentProjects.joined(separator: ", "), systemImage: "folder")
                                        .font(.caption)
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                            
                            // Playback Controls
                            HStack(spacing: 20) {
                                Button(action: {
                                    if isPlaying {
                                        audioPreview.stop()
                                    } else {
                                        audioPreview.play(url: sample.url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 32))
                                        Text(isPlaying ? "Stop" : "Play")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    selectRandomSample()
                                }) {
                                    HStack {
                                        Image(systemName: "shuffle.circle.fill")
                                            .font(.system(size: 32))
                                        Text("Random")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider()
                            
                            // Notes Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Notes & Metadata")
                                    .font(.headline)
                                
                                // Musical Key
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Musical Key")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., C minor, A major", text: $musicalKey)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                // BPM
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BPM")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., 120", text: $bpm)
                                        .textFieldStyle(.roundedBorder)
                                }

                                // Feel
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Feel / Vibe")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("e.g., energetic, chill, dark", text: $feel)
                                        .textFieldStyle(.roundedBorder)
                                }

                                // General Notes
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextEditor(text: $notes)
                                        .frame(height: 80)
                                        .font(.body)
                                        .border(Color.gray.opacity(0.2), width: 1)
                                }

                                // Save Notes Button
                                Button(action: {
                                    saveNotes()
                                }) {
                                    Label("Save Notes", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)

                            Divider()

                            // Quick Actions
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick Actions")
                                    .font(.headline)

                                VStack(spacing: 12) {
                                    // Open in Ableton
                                    Button(action: {
                                        // Placeholder
                                        print("🎹 Open in Ableton: \(sample.name)")
                                    }) {
                                        HStack {
                                            Image(systemName: "music.note.list")
                                                .font(.title3)
                                            Text("Open in Ableton Live")
                                                .font(.body)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)

                                    // Open in Koala
                                    Button(action: {
                                        // Placeholder
                                        print("🐨 Open in Koala: \(sample.name)")
                                    }) {
                                        HStack {
                                            Image(systemName: "waveform")
                                                .font(.title3)
                                            Text("Open in Koala Sampler")
                                                .font(.body)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)

                                    // Open in FRMS
                                    Button(action: {
                                        // Placeholder
                                        print("🎛️ Open in FRMS: \(sample.name)")
                                    }) {
                                        HStack {
                                            Image(systemName: "slider.horizontal.3")
                                                .font(.title3)
                                            Text("Open in FRMS")
                                                .font(.body)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundColor(.orange)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)

                                    // Transfer to Digitakt
                                    Button(action: {
                                        transferToDigitakt(sample: sample)
                                    }) {
                                        HStack {
                                            Image(systemName: "square.grid.3x3.fill")
                                                .font(.title3)
                                            Text("Transfer to Digitakt")
                                                .font(.body)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)

                                    // Show in Finder
                                    Button(action: {
                                        NSWorkspace.shared.activateFileViewerSelecting([sample.url])
                                    }) {
                                        HStack {
                                            Image(systemName: "folder")
                                                .font(.title3)
                                            Text("Show in Finder")
                                                .font(.body)
                                            Spacer()
                                            Image(systemName: "arrow.right.circle")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    } else {
                        // No sample selected yet
                        VStack(spacing: 24) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.orange.opacity(0.5))

                            Text("Click Random to get started!")
                                .font(.title2)
                                .foregroundColor(.secondary)

                            Button(action: {
                                selectRandomSample()
                            }) {
                                HStack {
                                    Image(systemName: "shuffle.circle.fill")
                                        .font(.title)
                                    Text("Pick Random Sample")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: 300)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 800)
        .onAppear {
            // Auto-select first random sample on appear
            if currentSample == nil && !samples.isEmpty {
                selectRandomSample()
            }
        }
    }

    // MARK: - Helper Methods

    private func selectRandomSample() {
        guard !samples.isEmpty else { return }

        // Stop current playback
        audioPreview.stop()

        // Select random sample (avoid selecting the same one if possible)
        var newSample: SampleFile
        if samples.count > 1 {
            repeat {
                newSample = samples.randomElement()!
            } while newSample.id == currentSample?.id && samples.count > 1
        } else {
            newSample = samples[0]
        }

        currentSample = newSample

        // Load existing notes if available
        loadNotes()

        print("🎲 Selected random sample: \(newSample.name)")
    }

    private func loadNotes() {
        guard let sample = currentSample else { return }

        // Try to load existing metadata
        if let metadata = try? MetadataManager.loadMetadata(forFileURL: sample.url) {
            notes = metadata.notes
            musicalKey = metadata.musicalKey
            bpm = metadata.bpm != nil ? "\(metadata.bpm!)" : ""
            feel = metadata.feel
        } else {
            // Clear fields for new sample
            notes = ""
            musicalKey = ""
            bpm = ""
            feel = ""
        }
    }

    private func saveNotes() {
        guard let sample = currentSample else { return }

        // Parse BPM
        let bpmValue = Int(bpm.trimmingCharacters(in: .whitespaces))

        // Create or update metadata
        var metadata = (try? MetadataManager.loadMetadata(forFileURL: sample.url)) ?? ProjectMetadata(
            fileURL: sample.url,
            projectName: sample.name
        )

        metadata.notes = notes
        metadata.musicalKey = musicalKey
        metadata.bpm = bpmValue
        metadata.feel = feel
        metadata.touch()  // Update lastModified timestamp

        // Save metadata
        do {
            try MetadataManager.saveMetadata(metadata)
            print("✅ Saved notes for: \(sample.name)")

            // Update app state cache
            appState.metadataCache[metadata.id] = metadata
        } catch {
            print("❌ Failed to save notes: \(error)")
        }
    }

	private func transferToDigitakt(sample: SampleFile) {
		guard !isTransferringToDigitakt else { return }
		isTransferringToDigitakt = true

			let sampleName = sample.name
			let sampleURL = sample.url

			print("🎹 Transfer to Digitakt: \(sampleName)")
			print("📁 Sample path: \(sampleURL.path)")

			let metadata = sample.metadataID.flatMap { appState.metadataCache[$0] }
			let trimRange = SampleTrimExporter.range(from: metadata, duration: sample.duration)
			let fadeOutSeconds = metadata?.fadeOutSeconds
			let fadeInEnabled = metadata?.fadeInEnabled ?? false
			let fadeOutEnabled = metadata?.fadeOutEnabled ?? true

			DispatchQueue.global(qos: .userInitiated).async {
				defer {
					DispatchQueue.main.async {
						isTransferringToDigitakt = false
					}
				}

				do {
					guard ElektroidCLI.shared.isInstalled() else {
						throw TransferError.elektroidNotInstalled
					}

					let routingStatus = try ElektroidCLI.shared.checkDigitaktRouting(deviceID: nil)
					switch routingStatus {
					case .ok:
						break
					case .routingIssue:
						throw TransferError.digitaktRoutingIssue
					case .cliRoutingIssue:
						print("⚠️ CLI routing check unavailable; continuing transfer.")
					}

					guard let deviceID = try ElektroidCLI.shared.resolveDigitaktDeviceID(preferred: "1") else {
						throw TransferError.digitaktNotFound
					}
					let (uploadURL, cleanup) = try SampleTrimExporter.exportTrimmedIfNeeded(
						url: sampleURL,
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
						let useExisting: Bool = DispatchQueue.main.sync {
							let alert = NSAlert()
							alert.messageText = "File Already Exists"
							alert.informativeText = """
							A file named "\(targetName)" already exists in /samples/SKETCHS.

							Choose Overwrite to keep the existing file (no upload), or Cancel to abort.
							"""
							alert.alertStyle = .warning
							alert.addButton(withTitle: "Overwrite")
							alert.addButton(withTitle: "Cancel")
							return alert.runModal() == .alertFirstButtonReturn
						}
						if useExisting {
							DispatchQueue.main.async {
								let alert = NSAlert()
								alert.messageText = "File Already Exists"
								alert.informativeText = """
								A file named "\(targetName)" already exists in /samples/SKETCHS on your Digitakt.

								Kept the existing file and skipped upload.
								"""
								alert.alertStyle = .informational
								alert.addButton(withTitle: "OK")
								alert.runModal()
							}
						}
						return
					}
					// Upload to Digitakt's /samples/SKETCHS and verify by listing
					try ElektroidCLI.shared.transferSample(url: uploadURL, to: deviceID, folder: "/samples/SKETCHS")

					DispatchQueue.main.async {
						let alert = NSAlert()
						alert.messageText = "Transfer Complete"
						alert.informativeText = "Uploaded \(sampleName) to Digitakt (/samples/SKETCHS)."
						alert.alertStyle = .informational
						alert.addButton(withTitle: "OK")
						alert.runModal()
					}
				} catch {
					DispatchQueue.main.async {
						let alert = NSAlert()
						alert.messageText = "Digitakt Transfer Failed"
						if let transferError = error as? TransferError {
							switch transferError {
							case .digitaktRoutingIssue:
								alert.informativeText = """
								elektroid-cli info 1 reported a non-MIDI device. This usually means Digitakt USB routing is set to Overbridge or another non-MIDI mode.

								Switch Digitakt USB config to Audio/MIDI and try again.
								"""
							case .cliRoutingIssue:
								alert.informativeText = """
								No output from elektroid-cli info 1. This suggests a CLI routing issue.

								Check USB connection, cable, and that the device is powered on.
								"""
							default:
								alert.informativeText = transferError.localizedDescription
							}
						} else {
							alert.informativeText = error.localizedDescription
						}
						alert.alertStyle = .warning
						alert.addButton(withTitle: "OK")
						alert.runModal()
					}
				}
			}
    }
}
