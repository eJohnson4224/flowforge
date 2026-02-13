//
//  WaveformTrimView.swift
//  flowforge
//
//  Waveform display with draggable trim handles.
//

import SwiftUI
import AVFoundation
import CoreMedia
import AudioToolbox

struct WaveformTrimView: View {
    let url: URL
    let duration: Double?
    @Binding var trimStart: Double
    @Binding var trimEnd: Double
    var playhead: Double?
    var maxSelectionSeconds: Double? = nil

    @State private var samples: [Float] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectionDragAnchor: (start: Double, end: Double)?
    @State private var startDragAnchor: Double?
    @State private var endDragAnchor: Double?

    private var safeDuration: Double {
        max(duration ?? 0, 0)
    }

    private var effectiveStart: Double {
        guard safeDuration > 0 else { return 0 }
        return max(0, min(trimStart, safeDuration))
    }

    private var effectiveEnd: Double {
        guard safeDuration > 0 else { return 0 }
        let end = trimEnd <= 0 ? safeDuration : trimEnd
        return max(effectiveStart, min(end, safeDuration))
    }

    private var selectionLength: Double {
        max(0, effectiveEnd - effectiveStart)
    }

    private var isOverMaxSelection: Bool {
        guard let maxSelectionSeconds else { return false }
        return selectionLength > maxSelectionSeconds + 0.001
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let height = max(1, proxy.size.height)
                let durationValue = safeDuration
                let startX = durationValue > 0 ? CGFloat(effectiveStart / durationValue) * width : 0
                let endX = durationValue > 0 ? CGFloat(effectiveEnd / durationValue) * width : 0
                let handleWidth: CGFloat = 10
                let handleCorner: CGFloat = 3
                let selectionColor = isOverMaxSelection ? Color.red : Color.orange

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.windowBackgroundColor))

                    if !samples.isEmpty {
                        WaveformShape(samples: samples)
                            .stroke(Color.orange.opacity(0.85), lineWidth: 1)
                    }

                    if durationValue > 0 {
                        let selectionWidth = max(1, endX - startX)
                        Rectangle()
                            .fill(selectionColor.opacity(0.15))
                            .frame(width: selectionWidth, height: height)
                            .position(x: startX + selectionWidth / 2, y: height / 2)
                            .gesture(selectionDragGesture(width: width, duration: durationValue))

                        RoundedRectangle(cornerRadius: handleCorner)
                            .fill(selectionColor.opacity(0.85))
                            .frame(width: handleWidth, height: height)
                            .position(x: clampHandleX(startX, width: width, handleWidth: handleWidth), y: height / 2)
                            .gesture(startHandleDragGesture(width: width, duration: durationValue))

                        RoundedRectangle(cornerRadius: handleCorner)
                            .fill(selectionColor.opacity(0.85))
                            .frame(width: handleWidth, height: height)
                            .position(x: clampHandleX(endX, width: width, handleWidth: handleWidth), y: height / 2)
                            .gesture(endHandleDragGesture(width: width, duration: durationValue))

                        if let playhead, playhead > 0, playhead <= durationValue {
                            let playheadX = CGFloat(playhead / durationValue) * width
                            Rectangle()
                                .fill(Color.primary.opacity(0.7))
                                .frame(width: 1, height: height)
                                .position(x: playheadX, y: height / 2)
                        }
                    }

                    if isLoading {
                        Text("Loading waveform...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if loadError != nil || samples.isEmpty {
                        Text("Waveform unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )

            HStack {
                Text(String(format: "Start %.2fs", effectiveStart))
                Spacer()
                Text(String(format: "End %.2fs", effectiveEnd))
                Spacer()
                Text(String(format: "Len %.2fs", selectionLength))
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if isOverMaxSelection, let maxSelectionSeconds {
                Text("Selection over \(Int(maxSelectionSeconds))s. Trim to transfer.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            if let loadError {
                Text("Waveform error: \(loadError)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
        .onAppear {
            normalizeTrim()
        }
        .onChange(of: duration) { _, _ in
            normalizeTrim()
        }
        .task(id: url) {
            isLoading = true
            loadError = nil
            let result = await Task.detached(priority: .utility) { () async -> (samples: [Float], error: String?) in
                do {
                    let loaded = try await WaveformLoader.load(url: url, targetSamples: 1400)
                    return (loaded, nil)
                } catch {
                    return ([], error.localizedDescription)
                }
            }.value
            if Task.isCancelled { return }
            samples = result.samples
            loadError = result.error
            if let error = result.error {
                print("⚠️ Waveform load failed: \(error) (\(url.path))")
            }
            isLoading = false
        }
    }

    private func normalizeTrim() {
        guard safeDuration > 0 else { return }
        if trimEnd <= 0 {
            trimEnd = safeDuration
        }
        trimStart = max(0, min(trimStart, safeDuration))
        trimEnd = max(trimStart, min(trimEnd, safeDuration))
    }

    private func clampHandleX(_ x: CGFloat, width: CGFloat, handleWidth: CGFloat) -> CGFloat {
        let minX = handleWidth / 2
        let maxX = width - handleWidth / 2
        return min(max(x, minX), maxX)
    }

    private func selectionDragGesture(width: CGFloat, duration: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if selectionDragAnchor == nil {
                    selectionDragAnchor = (start: effectiveStart, end: effectiveEnd)
                }
                guard let anchor = selectionDragAnchor else { return }
                let delta = Double(value.translation.width / width) * duration
                var newStart = anchor.start + delta
                var newEnd = anchor.end + delta
                if newStart < 0 {
                    let offset = -newStart
                    newStart = 0
                    newEnd += offset
                }
                if newEnd > duration {
                    let offset = newEnd - duration
                    newEnd = duration
                    newStart = max(0, newStart - offset)
                }
                trimStart = newStart
                trimEnd = max(newStart, newEnd)
            }
            .onEnded { _ in
                selectionDragAnchor = nil
            }
    }

    private func startHandleDragGesture(width: CGFloat, duration: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if startDragAnchor == nil {
                    startDragAnchor = effectiveStart
                }
                guard let anchor = startDragAnchor else { return }
                let delta = Double(value.translation.width / width) * duration
                let minGap = max(0.01, duration * 0.001)
                let proposed = anchor + delta
                trimStart = max(0, min(proposed, effectiveEnd - minGap))
            }
            .onEnded { _ in
                startDragAnchor = nil
            }
    }

    private func endHandleDragGesture(width: CGFloat, duration: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if endDragAnchor == nil {
                    endDragAnchor = effectiveEnd
                }
                guard let anchor = endDragAnchor else { return }
                let delta = Double(value.translation.width / width) * duration
                let minGap = max(0.01, duration * 0.001)
                let proposed = anchor + delta
                trimEnd = min(duration, max(proposed, effectiveStart + minGap))
            }
            .onEnded { _ in
                endDragAnchor = nil
            }
    }
}

struct WaveformShape: Shape {
    let samples: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count > 1 else { return path }
        let midY = rect.midY
        let width = rect.width
        let step = width / CGFloat(samples.count - 1)
        for (index, sample) in samples.enumerated() {
            let x = rect.minX + CGFloat(index) * step
            let magnitude = CGFloat(sample) * rect.height * 0.45
            path.move(to: CGPoint(x: x, y: midY - magnitude))
            path.addLine(to: CGPoint(x: x, y: midY + magnitude))
        }
        return path
    }
}

private enum WaveformLoader {
    private struct FileInfo {
        let ext: String
        let sizeBytes: Int64
    }

    static func load(url: URL, targetSamples: Int) async throws -> [Float] {
        let info = try preflight(url)

        do {
            return try loadUsingAudioFile(url: url, targetSamples: targetSamples)
        } catch {
            let audioError = describe(error)
            do {
                return try await loadUsingAssetReader(url: url, targetSamples: targetSamples)
            } catch {
                let assetError = describe(error)
                let sizeKB = max(1, info.sizeBytes / 1024)
                let message = "Decode failed (\(info.ext), \(sizeKB)KB). AudioFile: \(audioError). AssetReader: \(assetError)"
                throw NSError(domain: "WaveformLoader", code: 10, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])
            }
        }
    }

    private static func preflight(_ url: URL) throws -> FileInfo {
        let path = url.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            throw NSError(domain: "WaveformLoader", code: 20, userInfo: [
                NSLocalizedDescriptionKey: "file missing"
            ])
        }
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw NSError(domain: "WaveformLoader", code: 21, userInfo: [
                NSLocalizedDescriptionKey: "file not readable"
            ])
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let sizeBytes = attributes[.size] as? Int64 ?? 0
        guard sizeBytes > 0 else {
            throw NSError(domain: "WaveformLoader", code: 22, userInfo: [
                NSLocalizedDescriptionKey: "file is empty"
            ])
        }
        do {
            let handle = try FileHandle(forReadingFrom: url)
            try? handle.close()
        } catch {
            throw NSError(domain: "WaveformLoader", code: 23, userInfo: [
                NSLocalizedDescriptionKey: "file access failed: \(describe(error))"
            ])
        }

        let ext = url.pathExtension.isEmpty ? "unknown" : url.pathExtension.lowercased()
        return FileInfo(ext: ext, sizeBytes: sizeBytes)
    }

    private static func loadUsingAudioFile(url: URL, targetSamples: Int) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let totalFrames = Int(file.length)
        guard totalFrames > 0 else {
            throw NSError(domain: "WaveformLoader", code: 24, userInfo: [
                NSLocalizedDescriptionKey: "no frames in audio file"
            ])
        }
        let format = file.processingFormat
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        guard channelCount > 0 else {
            throw NSError(domain: "WaveformLoader", code: 25, userInfo: [
                NSLocalizedDescriptionKey: "invalid channel count"
            ])
        }
        guard let floatFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: format.channelCount) else {
            throw NSError(domain: "WaveformLoader", code: 26, userInfo: [
                NSLocalizedDescriptionKey: "float format creation failed"
            ])
        }
        let needsFloat = format.commonFormat != .pcmFormatFloat32 || format.isInterleaved
        let converter = needsFloat ? AVAudioConverter(from: format, to: floatFormat) : nil
        if needsFloat && converter == nil {
            throw NSError(domain: "WaveformLoader", code: 27, userInfo: [
                NSLocalizedDescriptionKey: "float converter unavailable"
            ])
        }
        let bufferCapacity: AVAudioFrameCount = 4096
        let bucketCount = max(64, targetSamples)
        let framesPerBucket = max(1, totalFrames / bucketCount)
        var buckets: [Float] = []
        buckets.reserveCapacity(bucketCount + 1)
        var currentMax: Float = 0
        var framesInBucket = 0

        file.framePosition = 0
        while true {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferCapacity) else {
                break
            }
            try file.read(into: buffer, frameCount: bufferCapacity)
            if buffer.frameLength == 0 {
                break
            }

            let floatBuffer: AVAudioPCMBuffer
            if let converter {
                guard let converted = AVAudioPCMBuffer(pcmFormat: floatFormat, frameCapacity: buffer.frameCapacity) else {
                    break
                }
                var error: NSError?
                var consumed = false
                let status = converter.convert(to: converted, error: &error) { _, outStatus in
                    if consumed {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    consumed = true
                    outStatus.pointee = .haveData
                    return buffer
                }
                if status == .error || converted.frameLength == 0 {
                    let message = error?.localizedDescription ?? "float conversion failed"
                    throw NSError(domain: "WaveformLoader", code: 28, userInfo: [
                        NSLocalizedDescriptionKey: message
                    ])
                }
                floatBuffer = converted
            } else {
                floatBuffer = buffer
            }

            guard let channelData = floatBuffer.floatChannelData else {
                throw NSError(domain: "WaveformLoader", code: 29, userInfo: [
                    NSLocalizedDescriptionKey: "channel data unavailable"
                ])
            }
            let channels = Int(floatBuffer.format.channelCount)
            let frames = Int(floatBuffer.frameLength)
            for frame in 0..<frames {
                var sum: Float = 0
                for channel in 0..<channels {
                    sum += channelData[channel][frame]
                }
                let mono = sum / Float(max(1, channels))
                let amp = abs(mono)
                if amp > currentMax {
                    currentMax = amp
                }
                framesInBucket += 1
                if framesInBucket >= framesPerBucket {
                    buckets.append(currentMax)
                    currentMax = 0
                    framesInBucket = 0
                }
            }
        }

        if framesInBucket > 0 {
            buckets.append(currentMax)
        }

        if buckets.isEmpty {
            throw NSError(domain: "WaveformLoader", code: 30, userInfo: [
                NSLocalizedDescriptionKey: "no audio frames decoded"
            ])
        }

        return normalizeBuckets(buckets)
    }

    private static func loadUsingAssetReader(url: URL, targetSamples: Int) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw NSError(domain: "WaveformLoader", code: 31, userInfo: [
                NSLocalizedDescriptionKey: "asset has no audio track"
            ])
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw NSError(domain: "WaveformLoader", code: 32, userInfo: [
                NSLocalizedDescriptionKey: "cannot add asset reader output"
            ])
        }
        reader.add(output)
        guard reader.startReading() else {
            throw reader.error ?? NSError(domain: "WaveformLoader", code: 33, userInfo: [
                NSLocalizedDescriptionKey: "asset reader failed to start"
            ])
        }

        let channelCount = max(1, try await channelCount(for: track))
        let bucketTarget = max(64, targetSamples)
        let chunkFrames = 2048
        var buckets: [Float] = []
        buckets.reserveCapacity(bucketTarget + 1)
        var currentMax: Float = 0
        var framesInBucket = 0

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                CMSampleBufferInvalidate(sampleBuffer)
                continue
            }
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer
            )
            if status != kCMBlockBufferNoErr || dataPointer == nil || length <= 0 {
                CMSampleBufferInvalidate(sampleBuffer)
                continue
            }
            let floatCount = length / MemoryLayout<Float>.size
            if floatCount <= 0 {
                CMSampleBufferInvalidate(sampleBuffer)
                continue
            }
            let frames = floatCount / channelCount
            if frames <= 0 {
                CMSampleBufferInvalidate(sampleBuffer)
                continue
            }

            let floatPointer = dataPointer!.withMemoryRebound(to: Float.self, capacity: floatCount) { $0 }
            var index = 0
            for _ in 0..<frames {
                var sum: Float = 0
                for channel in 0..<channelCount {
                    sum += floatPointer[index + channel]
                }
                let mono = sum / Float(channelCount)
                let amp = abs(mono)
                if amp > currentMax {
                    currentMax = amp
                }
                framesInBucket += 1
                if framesInBucket >= chunkFrames {
                    buckets.append(currentMax)
                    currentMax = 0
                    framesInBucket = 0
                }
                index += channelCount
            }

            CMSampleBufferInvalidate(sampleBuffer)
        }

        if reader.status == .failed {
            throw reader.error ?? NSError(domain: "WaveformLoader", code: 34, userInfo: [
                NSLocalizedDescriptionKey: "asset reader failed"
            ])
        }

        if framesInBucket > 0 {
            buckets.append(currentMax)
        }

        if buckets.isEmpty {
            throw NSError(domain: "WaveformLoader", code: 35, userInfo: [
                NSLocalizedDescriptionKey: "asset reader produced no audio"
            ])
        }

        let downsampled = downsampleBuckets(buckets, targetCount: bucketTarget)
        return normalizeBuckets(downsampled)
    }

    private static func channelCount(for track: AVAssetTrack) async throws -> Int {
        let formatDescriptions = try await track.load(.formatDescriptions)
        guard let formatDesc = formatDescriptions.first,
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee else {
            return 1
        }
        return Int(asbd.mChannelsPerFrame)
    }

    private static func downsampleBuckets(_ buckets: [Float], targetCount: Int) -> [Float] {
        guard targetCount > 0, buckets.count > targetCount else { return buckets }
        var result: [Float] = []
        result.reserveCapacity(targetCount)
        let stride = Double(buckets.count) / Double(targetCount)
        for index in 0..<targetCount {
            let start = Int(Double(index) * stride)
            let end = max(start + 1, Int(Double(index + 1) * stride))
            let clampedEnd = min(end, buckets.count)
            let maxVal = buckets[start..<clampedEnd].max() ?? 0
            result.append(maxVal)
        }
        return result
    }

    private static func normalizeBuckets(_ buckets: [Float]) -> [Float] {
        guard let maxAmp = buckets.max(), maxAmp > 0 else { return buckets }
        var normalized = buckets
        for index in normalized.indices {
            normalized[index] /= maxAmp
        }
        return normalized
    }

    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        let message = nsError.localizedDescription
        return "\(nsError.domain) \(nsError.code): \(message)"
    }
}
