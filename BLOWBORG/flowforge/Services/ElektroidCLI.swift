//
//  ElektroidCLI.swift
//  flowforge
//
//  Elektroid CLI wrapper for Digitakt sample transfer
//

import Foundation
#if canImport(CoreMIDI)
import CoreMIDI
#endif

class ElektroidCLI {
    static let shared = ElektroidCLI()

    private struct Keys {
        static let userCliBookmark = "elektroidCliBookmark"
        static let userCliPath = "elektroidCliPath"
    }

    private static let defaultElektronDevicesJSON = """
    [
      {
        "id": 4,
        "name": "Elektron Analog Four",
        "filesystems": {
          "data": null,
          "project": [
            "afprj"
          ],
          "sound": [
            "afsnd"
          ]
        },
        "storage": []
      },
      {
        "id": 6,
        "name": "Elektron Analog Keys",
        "filesystems": {
          "data": null,
          "project": [
            "akprj"
          ],
          "sound": [
            "aksnd"
          ]
        },
        "storage": []
      },
      {
        "id": 8,
        "name": "Elektron Analog Rytm",
        "filesystems": {
          "sample": null,
          "data": null,
          "project": [
            "arprj"
          ],
          "sound": [
            "arsnd"
          ]
        },
        "storage": [
          "+Drive",
          "RAM"
        ]
      },
      {
        "id": 10,
        "name": "Elektron Analog Heat",
        "filesystems": {
          "data": null,
          "preset": [
            "ahpst"
          ]
        },
        "storage": []
      },
      {
        "id": 12,
        "name": "Elektron Digitakt",
        "filesystems": {
          "sample": null,
          "data": null,
          "project": [
            "dtprj"
          ],
          "sound": [
            "dtsnd"
          ]
        },
        "storage": [
          "+Drive",
          "RAM"
        ]
      },
      {
        "id": 14,
        "name": "Elektron Analog Four MKII",
        "filesystems": {
          "data": null,
          "project": [
            "afprj"
          ],
          "sound": [
            "afsnd"
          ]
        },
        "storage": []
      },
      {
        "id": 16,
        "name": "Elektron Analog Rytm MKII",
        "filesystems": {
          "sample": null,
          "data": null,
          "project": [
            "arprj"
          ],
          "sound": [
            "arsnd"
          ]
        },
        "storage": [
          "+Drive",
          "RAM"
        ]
      },
      {
        "id": 20,
        "name": "Elektron Digitone",
        "filesystems": {
          "data": null,
          "project": [
            "dnprj"
          ],
          "sound": [
            "dnsnd"
          ]
        },
        "storage": []
      },
      {
        "id": 22,
        "name": "Elektron Analog Heat MKII",
        "filesystems": {
          "data": null,
          "preset": [
            "ahpst"
          ]
        },
        "storage": []
      },
      {
        "id": 28,
        "name": "Elektron Digitone Keys",
        "filesystems": {
          "data": null,
          "project": [
            "dnprj"
          ],
          "sound": [
            "dnsnd"
          ]
        },
        "storage": []
      },
      {
        "id": 25,
        "name": "Elektron Model:Samples",
        "filesystems": {
          "sample": null,
          "data": null,
          "project": [
            "msprj"
          ],
          "sound": [
            "mssnd"
          ]
        },
        "storage": [
          "+Drive",
          "RAM"
        ]
      },
      {
        "id": 27,
        "name": "Elektron Model:Cycles",
        "filesystems": {
          "raw": null,
          "preset-raw": [
            "mcpst"
          ],
          "data": null,
          "project": [
            "mcprj"
          ]
        },
        "storage": [
          "+Drive"
        ]
      },
      {
        "id": 30,
        "name": "Elektron Syntakt",
        "filesystems": {
          "data": null,
          "project": [
            "stprj"
          ],
          "sound": [
            "stsnd"
          ]
        },
        "storage": []
      },
      {
        "id": 32,
        "name": "Elektron Analog Heat +FX",
        "filesystems": {
          "data": null,
          "preset": [
            "ahfxpst",
            "ahpst"
          ]
        },
        "storage": []
      },
      {
        "id": 42,
        "name": "Elektron Digitakt II",
        "filesystems": {
          "data": null,
          "project": [
            "dt2prj",
            "dtprj"
          ],
          "sample-stereo": null,
          "preset-takt-ii": [
            "dt2pst",
            "dtsnd"
          ]
        },
        "storage": [
          "+Drive",
          "RAM"
        ]
      },
      {
        "id": 43,
        "name": "Elektron Digitone II",
        "filesystems": {
          "data": null,
          "project": [
            "dn2prj",
            "dnprj"
          ],
          "preset-takt-ii": [
            "dn2pst",
            "dnsnd"
          ]
        },
        "storage": []
      }
    ]
    """
    
    private var commonPaths: [String] {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(homeDir)/elektroid/src/elektroid-cli",  // User's custom build
            "/opt/homebrew/bin/elektroid-cli",
            "/usr/local/bin/elektroid-cli",
            "/usr/bin/elektroid-cli"
        ]
    }

    private var cachedDigitakt: MIDIDevice?
    private var lastCheckTime: Date?
    private let cacheTimeout: TimeInterval = 5.0 // Re-check every 5 seconds
    private var cachedCliPath: String?
    private var sessionScopedCliURL: URL?

    // MARK: - Installation Check

    func isInstalled() -> Bool {
        return getCliPath() != nil
    }

    func debugCliAccessReport() -> String {
        var lines: [String] = []
        let storedPath = UserDefaults.standard.string(forKey: Keys.userCliPath) ?? "(none)"
        let hasBookmark = UserDefaults.standard.data(forKey: Keys.userCliBookmark) != nil
        let hasSessionScoped = sessionScopedCliURL != nil
        let bundledPath = bundledCliPath() ?? "(none)"
        let activePath = getCliPath() ?? "(none)"
        lines.append("userCliPath: \(storedPath)")
        lines.append("bookmarkStored: \(hasBookmark)")
        lines.append("sessionScopedURL: \(hasSessionScoped)")
        lines.append("bundledCliPath: \(bundledPath)")
        lines.append("activeCliPath: \(activePath)")

        if let url = resolveUserConfiguredCliURL() {
            lines.append("resolvedURL: \(url.path)")
            let ok = url.startAccessingSecurityScopedResource()
            lines.append("startAccessingSecurityScopedResource: \(ok)")
            defer {
                if ok { url.stopAccessingSecurityScopedResource() }
            }

            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            lines.append("fileExists: \(exists) (isDir: \(isDir.boolValue))")
            let isExec = FileManager.default.isExecutableFile(atPath: url.path)
            lines.append("isExecutableFile: \(isExec)")
            if let statInfo = try? runSystemCommand("/usr/bin/stat", ["-f", "%Sp %Su:%Sg", url.path]) {
                lines.append("stat: \(statInfo)")
            }
            if let lsInfo = try? runSystemCommand("/bin/ls", ["-l", url.path]) {
                lines.append("ls -l: \(lsInfo)")
            }

            do {
                let values = try url.resourceValues(forKeys: [.isReadableKey, .isExecutableKey, .isRegularFileKey])
                lines.append("resourceValues: readable=\(values.isReadable ?? false) executable=\(values.isExecutable ?? false) regularFile=\(values.isRegularFile ?? false)")
            } catch {
                lines.append("resourceValues error: \(error)")
            }
        } else {
            lines.append("resolvedURL: nil")
        }

        let devicePaths = elektronDevicesJSONPaths()
        for path in devicePaths {
            let exists = FileManager.default.fileExists(atPath: path)
            lines.append("elektroid devices.json: \(exists ? "present" : "missing")")
            lines.append("elektroid devices.json path: \(path)")
        }

        if let path = findInPath() {
            lines.append("which elektroid-cli: \(path)")
        } else {
            lines.append("which elektroid-cli: not found")
        }

        return lines.joined(separator: "\n")
    }

    func cliDiagnosticsSummary() -> String {
        var lines: [String] = []
        lines.append(debugCliAccessReport())
        lines.append("\n--- CoreMIDI Probe ---")
        lines.append(coreMIDIProbeReport())

        var listOutput: CLIResult?
        do {
            listOutput = try listDevicesRaw(timeout: 8.0)
        } catch {
            lines.append("\n--- elektroid-cli ld ---")
            lines.append("error: \(error)")
        }

        if let devices = listOutput {
            lines.append("\n--- elektroid-cli ld ---")
            lines.append("exit: \(devices.exitCode) reason: \(devices.terminationReason)")
            if !devices.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("stderr:\n\(devices.stderr)")
            }
            lines.append("stdout:\n\(devices.stdout)")
        }

        let deviceID = listOutput.flatMap { resolveDigitaktDeviceID(fromListOutput: $0.stdout) }
        if let deviceID {
            do {
                let info = try getInfoRaw(deviceID: deviceID, timeout: 4.0)
                lines.append("\n--- elektroid-cli info \(deviceID) ---")
                lines.append("exit: \(info.exitCode) reason: \(info.terminationReason)")
                if !info.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lines.append("stderr:\n\(info.stderr)")
                }
                lines.append("stdout:\n\(info.stdout)")
            } catch {
                lines.append("\n--- elektroid-cli info \(deviceID) ---")
                lines.append("error: \(error)")
            }
        } else {
            lines.append("\n--- elektroid-cli info ---")
            lines.append("No Digitakt device ID resolved from ld output.")
        }

        return lines.joined(separator: "\n")
    }

    func sandboxExecutableProbe(for url: URL) -> String {
        var lines: [String] = []
        lines.append("probeURL: \(url.path)")
        let ok = url.startAccessingSecurityScopedResource()
        lines.append("startAccessingSecurityScopedResource: \(ok)")
        defer {
            if ok { url.stopAccessingSecurityScopedResource() }
        }

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        lines.append("fileExists: \(exists) (isDir: \(isDir.boolValue))")
        lines.append("isExecutableFile: \(FileManager.default.isExecutableFile(atPath: url.path))")

        if let statInfo = try? runSystemCommand("/usr/bin/stat", ["-f", "%Sp %Su:%Sg", url.path]) {
            lines.append("stat: \(statInfo)")
        }
        if let lsInfo = try? runSystemCommand("/bin/ls", ["-l", url.path]) {
            lines.append("ls -l: \(lsInfo)")
        }

        do {
            let values = try url.resourceValues(forKeys: [.isReadableKey, .isExecutableKey, .isRegularFileKey, .fileSizeKey])
            lines.append("resourceValues: readable=\(values.isReadable ?? false) executable=\(values.isExecutable ?? false) regularFile=\(values.isRegularFile ?? false) size=\(values.fileSize ?? -1)")
        } catch {
            lines.append("resourceValues error: \(error)")
        }

        do {
            _ = try FileHandle(forReadingFrom: url)
            lines.append("fileHandleRead: success")
        } catch {
            lines.append("fileHandleRead error: \(error)")
        }

        do {
            _ = try runSystemCommand("/usr/bin/test", ["-x", url.path])
            lines.append("test -x: success")
        } catch {
            lines.append("test -x error: \(error)")
        }

        return lines.joined(separator: "\n")
    }

    private func runSystemCommand(_ path: String, _ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.environment = cliEnvironment()

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw TransferError.systemCommandFailed(command: path, stderr: stderr)
        }
        return stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Probe helpers used by ElektroidSandboxProbe
    func runSystemCommandForProbe(_ path: String, _ args: [String]) throws -> String {
        try runSystemCommand(path, args)
    }

    func runCLIForProbe(executablePath: String, arguments: [String], timeout: TimeInterval) throws -> CLIResult {
        try runCLI(executablePath: executablePath, arguments: arguments, timeout: timeout)
    }

    /// Returns the currently configured CLI path (if the user selected it in Settings).
    /// This is intended for UI display only (does not verify executability).
    func userConfiguredCliPathForDisplay() -> String? {
        UserDefaults.standard.string(forKey: Keys.userCliPath)
    }

    /// Returns the CLI path FlowForge will actually try to use (bundled > user-selected > common paths).
    func activeCliPathForDisplay() -> String? {
        getCliPath()
    }

    /// Store/clear a user-selected elektroid-cli executable location.
    /// For sandboxed builds, this persists a security-scoped bookmark.
    func setUserConfiguredCliURL(_ url: URL?) throws {
        if let existing = sessionScopedCliURL {
            existing.stopAccessingSecurityScopedResource()
            sessionScopedCliURL = nil
        }
        cachedCliPath = nil
        cachedDigitakt = nil
        lastCheckTime = nil

        guard let url else {
            UserDefaults.standard.removeObject(forKey: Keys.userCliPath)
            UserDefaults.standard.removeObject(forKey: Keys.userCliBookmark)
            return
        }

        // Keep a human-readable path for debugging/UI.
        UserDefaults.standard.set(url.path, forKey: Keys.userCliPath)

        // Persist bookmark so the selection survives relaunch in sandbox.
        let ok = url.startAccessingSecurityScopedResource()
        if !ok {
            throw TransferError.securityScopeAccessFailed
        }

        do {
            let bookmark = try FolderManager.createSecurityScopedBookmark(for: url)
            UserDefaults.standard.set(bookmark, forKey: Keys.userCliBookmark)
            url.stopAccessingSecurityScopedResource()
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && (nsError.code == 256 || nsError.code == 4) {
                // Fall back to session-only access when app-scoped bookmarks are not granted.
                UserDefaults.standard.removeObject(forKey: Keys.userCliBookmark)
                sessionScopedCliURL = url
                print("⚠️ Bookmark creation failed (session-only access): \(error)")
            } else {
                url.stopAccessingSecurityScopedResource()
                throw error
            }
        }
    }

    func clearUserConfiguredCli() {
        try? setUserConfiguredCliURL(nil)
    }

    private func getCliPath() -> String? {
        // Return cached path if available
        if let cached = cachedCliPath {
            return cached
        }

        print("🔍 Searching for elektroid-cli...")

        // Prefer bundled CLI if present
        if let bundled = bundledCliPath() {
            print("✅ Using bundled elektroid-cli at: \(bundled)")
            cachedCliPath = bundled
            return bundled
        }

        // Prefer user-configured CLI path (sandbox friendly)
        if let url = resolveUserConfiguredCliURL() {
            let ok = url.startAccessingSecurityScopedResource()
            defer {
                if ok { url.stopAccessingSecurityScopedResource() }
            }

            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            if exists && !isDirectory.boolValue {
                print("✅ Using user-selected elektroid-cli at: \(url.path)")
                cachedCliPath = url.path
                return url.path
            } else {
                print("⚠️ User-selected elektroid-cli not found or is a directory: \(url.path)")
            }
        }

        // Check common paths
        for path in commonPaths {
            print("  Checking: \(path)")

            // Check if file exists
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)

            if exists {
                if isDirectory.boolValue {
                    print("  ⚠️ Found but it's a directory, not a file")
                    continue
                }

                // Accept the path and let Process.run report any execution error.
                print("✅ Found elektroid-cli at: \(path)")
                cachedCliPath = path
                return path
            } else {
                print("  ❌ Not found")
            }
        }

        // Try using 'which' to find it in PATH
        print("  Trying 'which' command...")
        if let path = findInPath() {
            print("✅ Found elektroid-cli via PATH: \(path)")
            cachedCliPath = path
            return path
        }

        print("❌ elektroid-cli not found in any known location")
        print("   Searched paths:")
        for path in commonPaths {
            print("   - \(path)")
        }

        // List what's actually in the elektroid directory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let elektroidDir = "\(homeDir)/elektroid/src"
        print("   Contents of \(elektroidDir):")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: elektroidDir) {
            for item in contents {
                print("     - \(item)")
            }
        } else {
            print("     (directory doesn't exist or can't be read)")
        }

        return nil
    }

    private func resolveUserConfiguredCliURL() -> URL? {
        if let sessionURL = sessionScopedCliURL {
            return sessionURL
        }
        if let bookmarkData = UserDefaults.standard.data(forKey: Keys.userCliBookmark) {
            do {
                let (url, isStale) = try FolderManager.resolveSecurityScopedBookmark(bookmarkData)

                // Refresh stale bookmark to keep future launches working.
                if isStale {
                    try? setUserConfiguredCliURL(url)
                }
                return url
            } catch {
                print("⚠️ Failed to resolve elektroid-cli bookmark: \(error)")
                // fall back to stored path
            }
        }

        if let path = UserDefaults.standard.string(forKey: Keys.userCliPath) {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    private func bundledCliPath() -> String? {
        if let execURL = Bundle.main.executableURL {
            let macosDir = execURL.deletingLastPathComponent()
            let cliURL = macosDir.appendingPathComponent("elektroid-cli")
            if FileManager.default.fileExists(atPath: cliURL.path) {
                return cliURL.path
            }
        }
        if let url = Bundle.main.url(forResource: "elektroid-cli", withExtension: nil) {
            return url.path
        }
        return nil
    }

    struct CLIResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        let terminationReason: String

        init(exitCode: Int32, stdout: String, stderr: String, terminationReason: String = "exit") {
            self.exitCode = exitCode
            self.stdout = stdout
            self.stderr = stderr
            self.terminationReason = terminationReason
        }
    }

    private func formatCLIResult(_ result: CLIResult) -> String {
        var parts: [String] = []
        parts.append("exit: \(result.exitCode) reason: \(result.terminationReason)")
        if !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("stdout:\n\(result.stdout)")
        }
        if !result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("stderr:\n\(result.stderr)")
        }
        return parts.joined(separator: "\n")
    }

    private func runCLI(executablePath: String, arguments: [String], timeout: TimeInterval = 8.0) throws -> CLIResult {
        ensureElektronDevicesJSON()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.environment = cliEnvironment()

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        let semaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            semaphore.signal()
        }

        try process.run()

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            throw TransferError.cliTimeout
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let reason: String
        switch process.terminationReason {
        case .exit:
            reason = "exit"
        case .uncaughtSignal:
            reason = "signal"
        @unknown default:
            reason = "unknown"
        }

        return CLIResult(
            exitCode: process.terminationStatus,
            stdout: String(data: outData, encoding: .utf8) ?? "",
            stderr: String(data: errData, encoding: .utf8) ?? "",
            terminationReason: reason
        )
    }

    private func cliEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let fallbackPath = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        let existingPath = env["PATH"]
        env["PATH"] = [existingPath, fallbackPath].compactMap { $0 }.joined(separator: ":")
        let containerHome = NSHomeDirectory()
        env["HOME"] = containerHome
        if let configDir = elektroidConfigHomeURL() {
            env["XDG_CONFIG_HOME"] = configDir.path
            env["XDG_DATA_HOME"] = configDir.path
        }
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let flowforgeCache = cacheDir.appendingPathComponent("FlowForge", isDirectory: true)
            try? FileManager.default.createDirectory(at: flowforgeCache, withIntermediateDirectories: true, attributes: nil)
            env["XDG_CACHE_HOME"] = flowforgeCache.path
        }
        if env["TMPDIR"] == nil {
            env["TMPDIR"] = FileManager.default.temporaryDirectory.path
        }
        return env
    }

    private func elektroidConfigHomeURL() -> URL? {
        let home = NSHomeDirectory()
        let configDir = URL(fileURLWithPath: home).appendingPathComponent(".config", isDirectory: true)
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true, attributes: nil)
        return configDir
    }

    private func elektronDevicesJSONPaths() -> [String] {
        var paths: [String] = []
        if let configDir = elektroidConfigHomeURL() {
            let path = configDir
                .appendingPathComponent("elektroid", isDirectory: true)
                .appendingPathComponent("elektron", isDirectory: true)
                .appendingPathComponent("devices.json")
                .path
            paths.append(path)
        }
        return paths
    }

    private func ensureElektronDevicesJSON() {
        let paths = elektronDevicesJSONPaths()
        guard !paths.isEmpty else { return }
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                continue
            }
            let targetURL = URL(fileURLWithPath: path)
            let elektronDir = targetURL.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(at: elektronDir, withIntermediateDirectories: true, attributes: nil)
                try ElektroidCLI.defaultElektronDevicesJSON.write(to: targetURL, atomically: true, encoding: .utf8)
                print("✅ Wrote elektroid devices.json to \(targetURL.path)")
            } catch {
                print("⚠️ Failed to write elektroid devices.json: \(error)")
            }
        }
    }

    private func coreMIDIProbeReport() -> String {
        #if canImport(CoreMIDI)
        var lines: [String] = []
        let deviceCount = MIDIGetNumberOfDevices()
        lines.append("deviceCount: \(deviceCount)")

        for index in 0..<deviceCount {
            let device = MIDIGetDevice(index)
            let name = midiObjectName(device)
            lines.append("device[\(index)]: \(name)")
            let entityCount = MIDIDeviceGetNumberOfEntities(device)
            lines.append("  entities: \(entityCount)")
        }

        let sourceCount = MIDIGetNumberOfSources()
        lines.append("sources: \(sourceCount)")
        for index in 0..<sourceCount {
            let source = MIDIGetSource(index)
            let name = midiObjectName(source)
            lines.append("  source[\(index)]: \(name)")
        }

        let destinationCount = MIDIGetNumberOfDestinations()
        lines.append("destinations: \(destinationCount)")
        for index in 0..<destinationCount {
            let destination = MIDIGetDestination(index)
            let name = midiObjectName(destination)
            lines.append("  destination[\(index)]: \(name)")
        }

        return lines.joined(separator: "\n")
        #else
        return "CoreMIDI unavailable on this platform."
        #endif
    }

    #if canImport(CoreMIDI)
    private func midiObjectName(_ object: MIDIObjectRef) -> String {
        var nameRef: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(object, kMIDIPropertyName, &nameRef)
        guard status == noErr, let nameRef else {
            return "(unknown)"
        }
        return nameRef.takeRetainedValue() as String
    }
    #endif

    struct DigitaktInfo {
        let type: String?
        let name: String?
        let raw: String
    }

    enum DigitaktRoutingStatus {
        case ok(info: DigitaktInfo)
        case routingIssue(info: DigitaktInfo)
        case cliRoutingIssue
    }

    private func stageSampleIntoContainerTemp(_ url: URL) throws -> URL {
        let fm = FileManager.default
        let stagingRoot = fm.temporaryDirectory.appendingPathComponent("FlowForgeStaging", isDirectory: true)
        let stagingDir = stagingRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true, attributes: nil)

        let destURL = stagingDir.appendingPathComponent(url.lastPathComponent)

        if fm.fileExists(atPath: destURL.path) {
            try? fm.removeItem(at: destURL)
        }
        try fm.copyItem(at: url, to: destURL)
        return destURL
    }

    private func ensureRemoteFolderExists(executablePath: String, deviceID: String, folder: String) throws {
        let normalized = folder.hasPrefix("/") ? folder : "/" + folder
        let components = normalized.split(separator: "/").map(String.init)
        guard let leaf = components.last, components.count >= 2 else {
            return
        }
        let parent = "/" + components.dropLast().joined(separator: "/")

        // Check if folder exists via list
        let lsResult = try runCLI(
            executablePath: executablePath,
            arguments: [
                "elektron:sample:ls",
                "\(deviceID):\(parent)"
            ]
        )

        if lsResult.exitCode == 0 {
            let lines = lsResult.stdout.lowercased().split(separator: "\n")
            let exists = lines.contains { $0.trimmingCharacters(in: .whitespaces).lowercased() == leaf.lowercased() }
            if exists {
                return
            }
        }

        // Create folder if missing (ignore errors in case it already exists)
        let mkdirResult = try runCLI(
            executablePath: executablePath,
            arguments: [
                "elektron:sample:mkdir",
                "\(deviceID):\(normalized)"
            ]
        )

        if mkdirResult.exitCode != 0 {
            print("⚠️ elektroid-cli mkdir non-zero (ignored):\n\(mkdirResult.stderr)")
        }
    }

    private func listOutputContains(_ output: String, targetName: String) -> Bool {
        let targetLower = targetName.lowercased()
        let targetBase = URL(fileURLWithPath: targetLower).deletingPathExtension().lastPathComponent
        let lines = output.split(separator: "\n")

        for line in lines {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard parts.count >= 4 else { continue }
            let entryType = String(parts[0]).lowercased()
            if entryType != "f" {
                continue
            }
            let nameParts = parts[3...]
            let nameField = nameParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if nameField == targetLower || nameField == targetBase {
                return true
            }
            if targetBase.count >= 6 && nameField.contains(targetBase) {
                return true
            }
        }
        return false
    }

    private func findInPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["elektroid-cli"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return output?.isEmpty == false ? output : nil
        } catch {
            return nil
        }
    }
    
    // MARK: - Device Detection
    
    func listDevices() throws -> [MIDIDevice] {
        guard let path = getCliPath() else {
            print("❌ Elektroid CLI not found at expected paths")
            throw TransferError.elektroidNotInstalled
        }

        print("✅ Found Elektroid CLI at: \(path)")

        // NOTE: Some Elektroid builds emit RtAudio warnings to stderr even when the command succeeds.
        // Treat exitCode as the success signal.
        let result = try runCLI(executablePath: path, arguments: ["ld"])

        if !result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ Elektroid stderr (may be non-fatal):\n\(result.stderr)")
        }

        print("📋 Elektroid output:\n\(result.stdout)")

        guard result.exitCode == 0 else {
            let trimmed = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = trimmed.isEmpty ? "exit \(result.exitCode) (no stderr)" : trimmed
            print("❌ Elektroid error: \(message) reason=\(result.terminationReason)")
            throw TransferError.deviceListFailed
        }

        let devices = parseMIDIDevices(from: result.stdout)
        print("🔍 Found \(devices.count) MIDI devices")
        for device in devices {
            print("  - [\(device.id)] \(device.name)")
        }

        return devices
    }

    func getDigitaktInfo(deviceID: String = "1", timeout: TimeInterval = 6.0) throws -> DigitaktInfo? {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }

        let result = try runCLI(executablePath: path, arguments: ["info", deviceID], timeout: timeout)

        if result.exitCode != 0 {
            throw TransferError.deviceInfoFailed
        }

        let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if output.isEmpty {
            return nil
        }

        var typeValue: String?
        var nameValue: String?

        for line in output.split(separator: "\n") {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)
            let lower = lineStr.lowercased()
            if lower.hasPrefix("type:") {
                typeValue = String(lineStr.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if lower.hasPrefix("name:") {
                nameValue = String(lineStr.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }

        return DigitaktInfo(type: typeValue, name: nameValue, raw: output)
    }

    func checkDigitaktRouting(deviceID: String? = nil) throws -> DigitaktRoutingStatus {
        let resolvedID = try (deviceID ?? resolveDigitaktDeviceID(preferred: "1"))

        guard let resolvedID else {
            throw TransferError.digitaktNotFound
        }

        let info: DigitaktInfo?
        do {
            info = try getDigitaktInfo(deviceID: resolvedID, timeout: 4.0)
        } catch TransferError.cliTimeout {
            return .cliRoutingIssue
        } catch TransferError.deviceInfoFailed {
            return .cliRoutingIssue
        }

        guard let info else {
            return .cliRoutingIssue
        }

        let typeOk = info.type?.lowercased() == "midi"
        let nameValue = info.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameOk = nameValue?.lowercased().contains("elektron digitakt") == true
        let nameMissing = nameValue == nil || nameValue?.isEmpty == true

        if typeOk && (nameOk || nameMissing) {
            return .ok(info: info)
        }

        return .routingIssue(info: info)
    }

    func listDevicesRaw(timeout: TimeInterval = 8.0) throws -> CLIResult {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }
        return try runCLI(executablePath: path, arguments: ["ld"], timeout: timeout)
    }

    func getInfoRaw(deviceID: String, timeout: TimeInterval = 8.0) throws -> CLIResult {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }
        return try runCLI(executablePath: path, arguments: ["info", deviceID], timeout: timeout)
    }

    func resolveDigitaktDeviceID(preferred: String = "1") throws -> String? {
        let devices = try listDevices()
        if let digitakt = devices.first(where: { $0.name.contains("Digitakt") }) {
            return digitakt.id
        }
        return nil
    }

    func resolveDigitaktDeviceID(fromListOutput output: String) -> String? {
        let devices = parseMIDIDevices(from: output)
        return devices.first(where: { $0.name.contains("Digitakt") })?.id
    }
    
    func findDigitakt(useCache: Bool = true) throws -> MIDIDevice? {
        // Use cache if available and not expired
        if useCache,
           let cached = cachedDigitakt,
           let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < cacheTimeout {
            return cached
        }
        
        // Refresh device list
        let devices = try listDevices()
        let digitakt = devices.first { $0.name.contains("Digitakt") }
        
        // Update cache
        cachedDigitakt = digitakt
        lastCheckTime = Date()
        
        return digitakt
    }
    
    func isDigitaktConnected() -> Bool {
        do {
            let digitakt = try findDigitakt(useCache: false)
            if let digitakt = digitakt {
                print("✅ Found Digitakt: [\(digitakt.id)] \(digitakt.name)")
                return true
            } else {
                print("⚠️ No Digitakt found in device list")
                return false
            }
        } catch {
            print("❌ Error checking Digitakt connection: \(error)")
            return false
        }
    }
    
    // MARK: - Sample Transfer
    
    func transferSample(url: URL, to deviceID: String, folder: String = "/incoming") throws {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }

        // Sandbox-safe: stage the file into our container temp directory before passing it to a child process.
        let stagedURL = try stageSampleIntoContainerTemp(url)
        defer {
            try? FileManager.default.removeItem(at: stagedURL)
        }

        // Ensure destination folder exists before upload.
        try ensureRemoteFolderExists(executablePath: path, deviceID: deviceID, folder: folder)

        let uploadTimeout: TimeInterval = 120.0
        let result = try runCLI(
            executablePath: path,
            arguments: [
                "elektron:sample:ul",
                stagedURL.path,
                "\(deviceID):\(folder)"
            ],
            timeout: uploadTimeout
        )

        if result.exitCode != 0 {
            let details = formatCLIResult(result)
            throw TransferError.systemCommandFailed(
                command: "elektroid-cli elektron:sample:ul \(stagedURL.path) \(deviceID):\(folder) (timeout \(Int(uploadTimeout))s)",
                stderr: details
            )
        }

        if !result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Non-fatal warnings are common (e.g., RtAudio). Keep as debug output.
            print("⚠️ Elektroid transfer stderr (non-fatal):\n\(result.stderr)")
        }

        // Verify transfer: list destination folder and confirm filename appears (grep -i behavior).
        let verifyTimeout: TimeInterval = 8.0
        let verifyResult = try runCLI(
            executablePath: path,
            arguments: [
                "elektron:sample:ls",
                "\(deviceID):\(folder)"
            ],
            timeout: verifyTimeout
        )

        if verifyResult.exitCode != 0 {
            let details = formatCLIResult(verifyResult)
            throw TransferError.systemCommandFailed(
                command: "elektroid-cli elektron:sample:ls \(deviceID):\(folder) (timeout \(Int(verifyTimeout))s)",
                stderr: details
            )
        }

        let targetName = stagedURL.lastPathComponent
        if !listOutputContains(verifyResult.stdout, targetName: targetName) {
            let details = formatCLIResult(verifyResult)
            throw TransferError.systemCommandFailed(
                command: "transfer verify (file not found): \(targetName)",
                stderr: details
            )
        }
    }

    func remoteFileExists(deviceID: String, folder: String, targetName: String, timeout: TimeInterval = 8.0) throws -> Bool {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }

        try ensureRemoteFolderExists(executablePath: path, deviceID: deviceID, folder: folder)
        let result = try runCLI(
            executablePath: path,
            arguments: [
                "elektron:sample:ls",
                "\(deviceID):\(folder)"
            ],
            timeout: timeout
        )

        if result.exitCode != 0 {
            let details = formatCLIResult(result)
            throw TransferError.systemCommandFailed(
                command: "elektroid-cli elektron:sample:ls \(deviceID):\(folder) (timeout \(Int(timeout))s)",
                stderr: details
            )
        }

        return listOutputContains(result.stdout, targetName: targetName)
    }
    
    // MARK: - Storage Check
    
    func checkStorage(deviceID: String) throws -> StorageInfo {
        guard let path = getCliPath() else {
            throw TransferError.elektroidNotInstalled
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["df", "\(deviceID):/"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return parseStorageInfo(from: output)
    }
    
    // MARK: - Parsing Helpers
    
    private func parseMIDIDevices(from output: String) -> [MIDIDevice] {
        var devices: [MIDIDevice] = []

        for line in output.split(separator: "\n") {
            let lineStr = String(line).trimmingCharacters(in: .whitespaces)
            guard !lineStr.isEmpty else { continue }

            print("🔍 Parsing line: \(lineStr)")

            // Try multiple parsing formats
            // Format 1: "1: id: hw:2,0,0; name: Elektron Digitakt, Elektron Digitakt MIDI 1"
            if let device = parseFormat1(lineStr) {
                devices.append(device)
                continue
            }

            // Format 2: Just check if line contains device info
            if let device = parseFormat2(lineStr) {
                devices.append(device)
                continue
            }

            print("⚠️ Could not parse line: \(lineStr)")
        }

        return devices
    }

    private func parseFormat1(_ line: String) -> MIDIDevice? {
        // Example line:
        // "1: id: Elektron Digitakt :: Elektron Digitakt; name: Elektron Digitakt :: Elektron Digitakt"
        // For Elektroid CLI commands, the device identifier is the numeric prefix ("1"), not the "id:" field.
        let idSplit = line.components(separatedBy: ": id: ")
        guard idSplit.count == 2 else { return nil }
        let deviceIndex = idSplit[0].trimmingCharacters(in: .whitespaces)

        let components = idSplit[1].components(separatedBy: "; name: ")
        guard components.count == 2 else { return nil }

        let name = components[1].trimmingCharacters(in: .whitespaces)

        print("✅ Parsed device: [\(deviceIndex)] \(name)")
        return MIDIDevice(id: deviceIndex, name: name)
    }

    private func parseFormat2(_ line: String) -> MIDIDevice? {
        // Skip non-device lines (e.g. RtAudio warnings)
        if line.hasPrefix("ERROR") || line.hasPrefix("WARNING") {
            return nil
        }

        // Simpler format: "0: Elektron Digitakt"
        // or any line containing device info
        let parts = line.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        let id = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let name = String(parts[1]).trimmingCharacters(in: .whitespaces)

        // Skip system entries
        guard !name.lowercased().contains("system") else { return nil }

        print("✅ Parsed device (format 2): [\(id)] \(name)")
        return MIDIDevice(id: id, name: name)
    }

    private func parseStorageInfo(from output: String) -> StorageInfo {
        // Parse output like:
        // +Drive    959.5MiB    285.9MiB    673.6MiB    29.80%

        // For now, return placeholder values
        // TODO: Implement proper parsing
        return StorageInfo(
            totalSpace: 1_000_000_000,
            usedSpace: 300_000_000,
            availableSpace: 700_000_000
        )
    }
}

// MARK: - Models

struct MIDIDevice {
    let id: String
    let name: String
}

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let availableSpace: Int64

    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
}

// MARK: - Errors

enum TransferError: LocalizedError {
    case elektroidNotInstalled
    case digitaktNotFound
    case transferFailed
    case deviceListFailed
    case insufficientSpace
    case deviceInfoFailed
    case digitaktRoutingIssue
    case cliRoutingIssue
    case transferVerificationFailed
    case securityScopeAccessFailed
    case systemCommandFailed(command: String, stderr: String)
    case cliTimeout

    var errorDescription: String? {
        switch self {
        case .elektroidNotInstalled:
            return "Elektroid CLI is not configured. Install/build elektroid-cli and select it in Settings."
        case .digitaktNotFound:
            return "Digitakt not found. Make sure it's connected via USB."
        case .transferFailed:
            return "Failed to transfer sample to Digitakt"
        case .deviceListFailed:
            return "Failed to list MIDI devices"
        case .insufficientSpace:
            return "Not enough space on Digitakt"
        case .deviceInfoFailed:
            return "Failed to read Digitakt info from elektroid-cli"
        case .digitaktRoutingIssue:
            return "Digitakt routing issue detected (USB mode or MIDI routing)"
        case .cliRoutingIssue:
            return "No output from elektroid-cli info 1 (CLI routing issue)"
        case .transferVerificationFailed:
            return "Transfer verification failed (file not found after upload)"
        case .securityScopeAccessFailed:
            return "Failed to access the selected file via security-scoped access"
        case .systemCommandFailed(let command, let stderr):
            return "Command failed: \(command)\n\(stderr)"
        case .cliTimeout:
            return "elektroid-cli timed out (command did not finish)"
        }
    }
}
