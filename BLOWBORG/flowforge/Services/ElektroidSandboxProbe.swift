//
//  ElektroidSandboxProbe.swift
//  flowforge
//
//  Isolated sandbox probe for elektroid-cli access and execution.
//

import Foundation

struct ElektroidSandboxProbe {
    struct StepResult {
        let name: String
        let success: Bool
        let details: String
    }

    static func run(cliURL: URL, timeout: TimeInterval = 6.0) -> [StepResult] {
        func runCommand(_ path: String, _ args: [String], timeout: TimeInterval = 6.0) -> (exit: Int32, stdout: String, stderr: String)? {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            let semaphore = DispatchSemaphore(value: 0)
            process.terminationHandler = { _ in
                semaphore.signal()
            }

            do {
                try process.run()
            } catch {
                return nil
            }

            if semaphore.wait(timeout: .now() + timeout) == .timedOut {
                process.terminate()
                return (exit: -1, stdout: "", stderr: "timeout")
            }

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: outData, encoding: .utf8) ?? ""
            let stderr = String(data: errData, encoding: .utf8) ?? ""
            return (exit: process.terminationStatus, stdout: stdout, stderr: stderr)
        }

        var results: [StepResult] = []

        let ok = cliURL.startAccessingSecurityScopedResource()
        let bundleRoot = Bundle.main.bundleURL.path
        let inBundle = cliURL.path.hasPrefix(bundleRoot)
        results.append(StepResult(
            name: "startAccessingSecurityScopedResource",
            success: ok || inBundle,
            details: "ok=\(ok) inBundle=\(inBundle)"
        ))

        defer {
            if ok { cliURL.stopAccessingSecurityScopedResource() }
        }

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: cliURL.path, isDirectory: &isDir)
        results.append(StepResult(
            name: "fileExists",
            success: exists && !isDir.boolValue,
            details: "exists=\(exists) isDir=\(isDir.boolValue)"
        ))

        let isExec = FileManager.default.isExecutableFile(atPath: cliURL.path)
        results.append(StepResult(
            name: "isExecutableFile",
            success: isExec,
            details: "isExecutable=\(isExec)"
        ))

        if let statInfo = try? ElektroidCLI.shared.runSystemCommandForProbe("/usr/bin/stat", ["-f", "%Sp %Su:%Sg", cliURL.path]) {
            results.append(StepResult(
                name: "stat",
                success: true,
                details: statInfo
            ))
        }

        if let lsInfo = try? ElektroidCLI.shared.runSystemCommandForProbe("/bin/ls", ["-l", cliURL.path]) {
            results.append(StepResult(
                name: "ls -l",
                success: true,
                details: lsInfo
            ))
        }

        if let values = try? cliURL.resourceValues(forKeys: [.isReadableKey, .isExecutableKey, .isRegularFileKey]) {
            results.append(StepResult(
                name: "resourceValues",
                success: (values.isReadable ?? false) && (values.isRegularFile ?? false),
                details: "readable=\(values.isReadable ?? false) executable=\(values.isExecutable ?? false) regularFile=\(values.isRegularFile ?? false)"
            ))
        }

        let bundleDir = cliURL.deletingLastPathComponent()
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: bundleDir.path) {
            let listing = contents.sorted().joined(separator: ", ")
            results.append(StepResult(
                name: "bundleContents",
                success: true,
                details: "dir=\(bundleDir.path)\n\(listing)"
            ))
        } else {
            results.append(StepResult(
                name: "bundleContents",
                success: false,
                details: "dir=\(bundleDir.path)"
            ))
        }

        if let otool = runCommand("/usr/bin/otool", ["-L", cliURL.path]) {
            var missing: [String] = []
            var absolute: [String] = []
            for rawLine in otool.stdout.split(separator: "\n") {
                let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if line.isEmpty || line.hasSuffix(":") { continue }
                guard let dep = line.split(separator: " ").first else { continue }
                let depStr = String(dep)
                if depStr.hasPrefix("@executable_path/") {
                    let name = depStr.replacingOccurrences(of: "@executable_path/", with: "")
                    let local = bundleDir.appendingPathComponent(name)
                    if !FileManager.default.fileExists(atPath: local.path) {
                        missing.append(name)
                    }
                } else if depStr.hasPrefix("/opt/homebrew") || depStr.hasPrefix("/usr/local") {
                    absolute.append(depStr)
                }
            }

            var details = "exit=\(otool.exit)"
            if !otool.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                details += "\nstderr:\n\(otool.stderr)"
            }
            details += "\nmissing=@executable_path: \(missing.isEmpty ? "none" : missing.joined(separator: ", "))"
            if !absolute.isEmpty {
                details += "\nabsolute: \(absolute.joined(separator: ", "))"
            }

            results.append(StepResult(
                name: "otool -L",
                success: missing.isEmpty && absolute.isEmpty,
                details: details
            ))
        } else {
            results.append(StepResult(
                name: "otool -L",
                success: false,
                details: "otool failed to launch"
            ))
        }

        if let codesign = runCommand("/usr/bin/codesign", ["-vv", "--strict", cliURL.path]) {
            var details = "exit=\(codesign.exit)"
            if !codesign.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                details += "\nstdout:\n\(codesign.stdout)"
            }
            if !codesign.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                details += "\nstderr:\n\(codesign.stderr)"
            }
            results.append(StepResult(
                name: "codesign -vv --strict",
                success: codesign.exit == 0,
                details: details
            ))
        } else {
            results.append(StepResult(
                name: "codesign -vv --strict",
                success: false,
                details: "codesign failed to launch"
            ))
        }

        do {
            _ = try FileHandle(forReadingFrom: cliURL)
            results.append(StepResult(
                name: "fileHandleRead",
                success: true,
                details: "read ok"
            ))
        } catch {
            results.append(StepResult(
                name: "fileHandleRead",
                success: false,
                details: "\(error)"
            ))
        }

        let testExec = (try? ElektroidCLI.shared.runSystemCommandForProbe("/usr/bin/test", ["-x", cliURL.path])) != nil
        let testDetails: String
        let testSuccess: Bool
        if inBundle {
            testSuccess = true
            testDetails = "test -x \(testExec ? "ok" : "failed") (ignored for bundled CLI)"
        } else {
            testSuccess = testExec
            testDetails = "test -x \(testExec ? "ok" : "failed")"
        }
        results.append(StepResult(
            name: "test -x",
            success: testSuccess,
            details: testDetails
        ))

        // Attempt to execute elektroid-cli (ld) to validate actual run permissions.
        do {
            let result = try ElektroidCLI.shared.runCLIForProbe(executablePath: cliURL.path, arguments: ["ld"], timeout: timeout)
            results.append(StepResult(
                name: "run elektroid-cli ld",
                success: result.exitCode == 0,
                details: "reason=\(result.terminationReason) exit=\(result.exitCode)\nstdout:\n\(result.stdout)\nstderr:\n\(result.stderr)"
            ))
        } catch {
            results.append(StepResult(
                name: "run elektroid-cli ld",
                success: false,
                details: "\(error)"
            ))
        }

        return results
    }
}
