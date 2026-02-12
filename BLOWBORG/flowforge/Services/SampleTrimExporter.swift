//
//  SampleTrimExporter.swift
//  flowforge
//
//  Creates trimmed audio exports for transfer.
//

import Foundation
import AVFoundation

struct SampleTrimExporter {
    static let digitaktSampleRate: Double = 48_000

    struct TrimRange {
        let start: Double
        let end: Double
    }

    enum SampleTrimError: LocalizedError {
        case invalidRange
        case exportFailed(details: String)

        var errorDescription: String? {
            switch self {
            case .invalidRange:
                return "Invalid trim range"
            case .exportFailed(let details):
                return "Failed to export trimmed sample: \(details)"
            }
        }
    }

    static func defaultRange(duration: Double?) -> TrimRange? {
        guard let duration else { return nil }
        if duration > 6.0 {
            return TrimRange(start: 3.0, end: max(0.0, duration - 3.0))
        }
        return TrimRange(start: 0.0, end: max(0.0, duration))
    }

    static func range(from metadata: ProjectMetadata?, duration: Double?) -> TrimRange? {
        if let metadata,
           let start = metadata.trimStartSeconds,
           let end = metadata.trimEndSeconds {
            return clampedRange(start: start, end: end, duration: duration)
        }
        return defaultRange(duration: duration)
    }

    static func clampedRange(start: Double, end: Double, duration: Double?) -> TrimRange? {
        guard let duration else { return nil }
        let clampedStart = max(0.0, min(start, duration))
        let clampedEnd = max(clampedStart, min(end, duration))
        return TrimRange(start: clampedStart, end: clampedEnd)
    }

    static func exportTrimmedIfNeeded(
        url: URL,
        duration: Double?,
        range: TrimRange?,
        fadeOutSeconds: Double?,
        fadeInEnabled: Bool,
        fadeOutEnabled: Bool,
        targetSampleRate: Double = SampleTrimExporter.digitaktSampleRate
    ) throws -> (url: URL, cleanup: () -> Void) {
        let inputFile = try AVAudioFile(forReading: url)
        let inputSampleRate = inputFile.fileFormat.sampleRate
        let fileDuration = duration ?? (Double(inputFile.length) / inputSampleRate)
        let resolvedRange = range ?? TrimRange(start: 0.0, end: max(0.0, fileDuration))
        let fadeSeconds = max(0.0, fadeOutSeconds ?? 0.0)
        let needsFade = (fadeInEnabled || fadeOutEnabled) && fadeSeconds > 0.0
        let isFullRange = resolvedRange.start <= 0.001 && resolvedRange.end >= fileDuration - 0.001
        let isPCM16Mono = inputFile.fileFormat.commonFormat == .pcmFormatInt16
            && inputFile.fileFormat.channelCount == 1
        let isTargetSampleRate = abs(inputSampleRate - targetSampleRate) < 0.1

        if isFullRange && isPCM16Mono && isTargetSampleRate && !needsFade {
            return (url, {})
        }

        guard resolvedRange.end > resolvedRange.start else {
            throw SampleTrimError.invalidRange
        }

        let startFrame = AVAudioFramePosition(resolvedRange.start * inputSampleRate)
        let endFrame = AVAudioFramePosition(resolvedRange.end * inputSampleRate)
        let totalFrames = max(AVAudioFramePosition(0), endFrame - startFrame)

        if totalFrames == 0 {
            throw SampleTrimError.invalidRange
        }

        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent("FlowForgeTrim", isDirectory: true)
        let tempDir = tempRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)

        let baseName = url.deletingPathExtension().lastPathComponent
        let outURL = tempDir.appendingPathComponent(baseName).appendingPathExtension("wav")

        let outputSampleRate = targetSampleRate
        let inputFormat = inputFile.processingFormat
        let inputChannels = inputFormat.channelCount
        guard let monoFloatFormat = AVAudioFormat(standardFormatWithSampleRate: inputSampleRate, channels: 1) else {
            throw SampleTrimError.exportFailed(details: "mono format allocation failed")
        }
        guard let inputFloatFormat = AVAudioFormat(standardFormatWithSampleRate: inputSampleRate, channels: inputChannels) else {
            throw SampleTrimError.exportFailed(details: "input float format allocation failed")
        }
        guard let targetFloatFormat = AVAudioFormat(standardFormatWithSampleRate: outputSampleRate, channels: 1) else {
            throw SampleTrimError.exportFailed(details: "target format allocation failed")
        }
        let needsFloatConversion = inputFormat.commonFormat != .pcmFormatFloat32 || inputFormat.isInterleaved
        let toFloatConverter = needsFloatConversion ? AVAudioConverter(from: inputFormat, to: inputFloatFormat) : nil
        if needsFloatConversion && toFloatConverter == nil {
            throw SampleTrimError.exportFailed(details: "float converter init failed")
        }
        let needsResample = abs(inputSampleRate - outputSampleRate) > 0.1
        let resampler = needsResample ? AVAudioConverter(from: monoFloatFormat, to: targetFloatFormat) : nil
        if needsResample && resampler == nil {
            throw SampleTrimError.exportFailed(details: "resampler init failed")
        }
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: outputSampleRate, channels: 1, interleaved: false) else {
            throw SampleTrimError.exportFailed(details: "output format creation failed")
        }

        inputFile.framePosition = startFrame
        let bufferCapacity: AVAudioFrameCount = 4096
        var framesRemaining = AVAudioFrameCount(totalFrames)
        let fadeFrames = AVAudioFramePosition(fadeSeconds * inputSampleRate)
        let fadeStartFrame = max(AVAudioFramePosition(0), totalFrames - fadeFrames)
        var framesWritten: AVAudioFramePosition = 0

        var pcmData = Data()
        pcmData.reserveCapacity(Int(totalFrames) * MemoryLayout<Int16>.size)

        while framesRemaining > 0 {
            let framesToRead = min(bufferCapacity, framesRemaining)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: framesToRead) else {
                throw SampleTrimError.exportFailed(details: "input buffer allocation failed")
            }
            try inputFile.read(into: buffer, frameCount: framesToRead)
            if buffer.frameLength == 0 {
                break
            }

            let floatBuffer: AVAudioPCMBuffer
            if let converter = toFloatConverter {
                guard let converted = AVAudioPCMBuffer(pcmFormat: inputFloatFormat, frameCapacity: buffer.frameCapacity) else {
                    throw SampleTrimError.exportFailed(details: "float buffer allocation failed")
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
                    let message = error?.localizedDescription ?? "unknown float conversion error"
                    throw SampleTrimError.exportFailed(details: "float conversion failed: \(message)")
                }
                floatBuffer = converted
            } else {
                floatBuffer = buffer
            }

            // Downmix to mono float buffer
            guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFloatFormat, frameCapacity: floatBuffer.frameCapacity) else {
                throw SampleTrimError.exportFailed(details: "mono buffer allocation failed")
            }
            monoBuffer.frameLength = floatBuffer.frameLength
            let channels = Int(floatBuffer.format.channelCount)
            let frames = Int(floatBuffer.frameLength)
            guard let outData = monoBuffer.floatChannelData else {
                throw SampleTrimError.exportFailed(details: "mono float channel data unavailable")
            }
            guard let inData = floatBuffer.floatChannelData else {
                throw SampleTrimError.exportFailed(details: "float channel data missing after conversion")
            }
            for frame in 0..<frames {
                var sum: Float = 0
                for ch in 0..<channels {
                    sum += inData[ch][frame]
                }
                outData[0][frame] = sum / Float(max(1, channels))
            }

            // Apply fade-in/out if enabled
            if (fadeInEnabled || fadeOutEnabled), let outData = monoBuffer.floatChannelData {
                let frameLength = AVAudioFramePosition(monoBuffer.frameLength)
                for frame in 0..<frameLength {
                    let globalFrame = framesWritten + frame
                    var gain: Double = 1.0
                    if fadeInEnabled && fadeFrames > 0 && globalFrame < fadeFrames {
                        gain = min(gain, Double(globalFrame) / Double(fadeFrames))
                    }
                    if fadeOutEnabled && fadeFrames > 0 && globalFrame >= fadeStartFrame {
                        let remaining = max(AVAudioFramePosition(0), totalFrames - globalFrame)
                        gain = min(gain, Double(remaining) / Double(fadeFrames))
                    }
                    outData[0][Int(frame)] *= Float(gain)
                }
            }

            let floatBufferForWrite: AVAudioPCMBuffer
            if let resampler = resampler {
                let ratio = outputSampleRate / inputSampleRate
                let outCapacity = AVAudioFrameCount(ceil(Double(monoBuffer.frameLength) * ratio) + 16.0)
                guard let resampledBuffer = AVAudioPCMBuffer(pcmFormat: targetFloatFormat, frameCapacity: outCapacity) else {
                    throw SampleTrimError.exportFailed(details: "resampled buffer allocation failed")
                }
                var error: NSError?
                var consumed = false
                let status = resampler.convert(to: resampledBuffer, error: &error) { _, outStatus in
                    if consumed {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    consumed = true
                    outStatus.pointee = .haveData
                    return monoBuffer
                }
                if status == .error || resampledBuffer.frameLength == 0 {
                    let message = error?.localizedDescription ?? "unknown resample error"
                    throw SampleTrimError.exportFailed(details: "resampler error: \(message)")
                }
                floatBufferForWrite = resampledBuffer
            } else {
                floatBufferForWrite = monoBuffer
            }

            guard let int16Buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: floatBufferForWrite.frameCapacity) else {
                throw SampleTrimError.exportFailed(details: "output buffer allocation failed")
            }
            int16Buffer.frameLength = floatBufferForWrite.frameLength
            if let inData = floatBufferForWrite.floatChannelData, let outData = int16Buffer.int16ChannelData {
                let frameCount = Int(floatBufferForWrite.frameLength)
                for frame in 0..<frameCount {
                    let clamped = max(-1.0, min(1.0, Double(inData[0][frame])))
                    outData[0][frame] = Int16(clamped * Double(Int16.max))
                }
            } else {
                throw SampleTrimError.exportFailed(details: "int16 conversion failed")
            }

            if int16Buffer.frameLength > 0, let outData = int16Buffer.int16ChannelData {
                let byteCount = Int(int16Buffer.frameLength) * MemoryLayout<Int16>.size
                let chunk = Data(bytes: outData[0], count: byteCount)
                pcmData.append(chunk)
            }
            framesRemaining -= buffer.frameLength
            framesWritten += AVAudioFramePosition(buffer.frameLength)
        }

        guard !pcmData.isEmpty else {
            throw SampleTrimError.exportFailed(details: "no audio data written")
        }

        var header = Data()
        func appendUInt16(_ value: UInt16) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { header.append(contentsOf: $0) }
        }
        func appendUInt32(_ value: UInt32) {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { header.append(contentsOf: $0) }
        }

        let dataSize = UInt32(min(pcmData.count, Int(UInt32.max)))
        let riffSize = UInt32(36) &+ dataSize
        let byteRate = UInt32(outputSampleRate) * 1 * UInt32(16 / 8)
        let blockAlign = UInt16(1 * (16 / 8))

        header.append(contentsOf: [82, 73, 70, 70]) // "RIFF"
        appendUInt32(riffSize)
        header.append(contentsOf: [87, 65, 86, 69]) // "WAVE"
        header.append(contentsOf: [102, 109, 116, 32]) // "fmt "
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(outputSampleRate))
        appendUInt32(byteRate)
        appendUInt16(blockAlign)
        appendUInt16(16)
        header.append(contentsOf: [100, 97, 116, 97]) // "data"
        appendUInt32(dataSize)

        var fileData = Data()
        fileData.reserveCapacity(header.count + pcmData.count)
        fileData.append(header)
        fileData.append(pcmData)
        try fileData.write(to: outURL, options: .atomic)

        return (outURL, {
            try? FileManager.default.removeItem(at: outURL)
        })
    }
}
