//
//  SamplesListView.swift
//  flowforge
//
//  Displays all samples from Sketches folder with metadata
//

import SwiftUI

struct SamplesListView: View {
    let samples: [SampleFile]
    @EnvironmentObject var appState: AppState

    var body: some View {
        let _ = print("🎨 SamplesListView rendering with \(samples.count) samples")
        let _ = samples.prefix(3).forEach { print("   → \($0.name)") }

        return VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundColor(.orange)

                Text("All Samples")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if appState.isScanningSamples {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(samples.count) samples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))

            Divider()

            // Content
            if appState.isScanningSamples {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Scanning for samples...")
                        .font(.headline)
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
            } else if samples.isEmpty {
                EmptyStateView(
                    message: "No samples found",
                    icon: "waveform.slash",
                    color: .orange
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(samples) { sample in
                            SampleCard(sample: sample)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sample Card

struct SampleCard: View {
    let sample: SampleFile
    @ObservedObject private var audioPreview = AudioPreviewManager.shared
    
    private var isPlaying: Bool {
        audioPreview.isPlaying(url: sample.url)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Waveform icon
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundColor(sample.isReferenced ? .orange : .gray)
                .frame(width: 40)
            
            // Sample info
            VStack(alignment: .leading, spacing: 4) {
                Text(sample.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(sample.sourceProjectsText)
                    .font(.caption)
                    .foregroundColor(sample.isReferenced ? .orange : .secondary)
                
                HStack(spacing: 8) {
                    Text(sample.formattedFileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(sample.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let relativePath = sample.relativePath {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(relativePath)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Play button
            Button(action: {
                audioPreview.togglePlayPause(url: sample.url)
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .help(isPlaying ? "Pause" : "Play")
        }
        .padding(12)
        .background(isPlaying ? Color.orange.opacity(0.15) : Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPlaying ? Color.orange : Color.gray.opacity(0.2), lineWidth: isPlaying ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
        .contextMenu {
            Button(action: {
                audioPreview.togglePlayPause(url: sample.url)
            }) {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.circle" : "play.circle")
            }
            
            Divider()
            
            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.activateFileViewerSelecting([sample.url])
                }
            }) {
                Label("Show in Finder", systemImage: "folder")
            }
            
            Button(action: {
                Task { @MainActor in
                    NSWorkspace.shared.open(sample.url)
                }
            }) {
                Label("Open", systemImage: "arrow.up.forward.app")
            }
        }
    }
}

