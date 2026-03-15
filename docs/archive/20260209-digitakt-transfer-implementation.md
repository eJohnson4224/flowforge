# 🎹 Digitakt Sample Transfer - Implementation Guide

## ✅ Current Status

**Added:** "Transfer to Digitakt" button in Random Sample Explorer  
**Status:** Placeholder with implementation guide

---

## 🎯 Implementation Options

### **Option 1: Elektroid CLI (Recommended)**

**Elektroid** is an open-source FLOSS alternative to Elektron Transfer that supports Digitakt sample transfer via MIDI.

#### **Pros:**
- ✅ Free and open-source (GPL-3.0)
- ✅ Command-line interface (easy to automate)
- ✅ Actively maintained
- ✅ Supports all Elektron devices (Digitakt, Digitone, Analog Rytm, etc.)
- ✅ Works on macOS, Linux, Windows (MSYS2)
- ✅ Can transfer samples, projects, sounds
- ✅ Can list devices, check storage, etc.

#### **Cons:**
- ❌ Requires separate installation
- ❌ Requires Digitakt to be connected via USB
- ❌ No official Homebrew formula (must compile from source or use unofficial tap)

#### **Installation:**

**Option A: Homebrew (if available)**
```bash
brew install elektroid
```

**Option B: Compile from source**
```bash
# Install dependencies
brew install automake libtool pkg-config gtk+3 libsndfile libsamplerate gettext zlib json-glib libzip rtaudio rtmidi

# Clone and build
git clone https://github.com/dagargo/elektroid.git
cd elektroid
autoreconf --install
./configure CLI_ONLY=yes  # CLI only, no GUI
make
sudo make install
```

#### **Usage from Swift:**

```swift
func transferToDigitakt(sample: SampleFile) {
    // 1. Check if elektroid-cli is installed
    let checkProcess = Process()
    checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    checkProcess.arguments = ["which", "elektroid-cli"]
    
    do {
        try checkProcess.run()
        checkProcess.waitUntilExit()
        
        if checkProcess.terminationStatus != 0 {
            showElektroidNotInstalledAlert()
            return
        }
    } catch {
        showElektroidNotInstalledAlert()
        return
    }
    
    // 2. List MIDI devices to find Digitakt
    let listProcess = Process()
    listProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/elektroid-cli")
    listProcess.arguments = ["ld"]  // list devices
    
    let pipe = Pipe()
    listProcess.standardOutput = pipe
    
    do {
        try listProcess.run()
        listProcess.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        // Parse output to find Digitakt device ID
        // Example output:
        // 0: id: SYSTEM_ID; name: computer
        // 1: id: hw:2,0,0; name: hw:2,0,0: Elektron Digitakt, Elektron Digitakt MIDI 1
        
        guard let digitaktLine = output.split(separator: "\n").first(where: { $0.contains("Digitakt") }),
              let deviceID = digitaktLine.split(separator: ":").first?.trimmingCharacters(in: .whitespaces) else {
            showDigitaktNotFoundAlert()
            return
        }
        
        // 3. Transfer sample
        transferSample(sampleURL: sample.url, deviceID: deviceID)
        
    } catch {
        print("❌ Error listing devices: \(error)")
    }
}

func transferSample(sampleURL: URL, deviceID: String) {
    let transferProcess = Process()
    transferProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/elektroid-cli")
    
    // Upload sample to Digitakt's /incoming folder
    // Format: elektroid-cli elektron:sample:ul <file> <device>:/path
    transferProcess.arguments = [
        "elektron:sample:ul",
        sampleURL.path,
        "\(deviceID):/incoming"
    ]
    
    do {
        try transferProcess.run()
        transferProcess.waitUntilExit()
        
        if transferProcess.terminationStatus == 0 {
            showTransferSuccessAlert()
        } else {
            showTransferFailedAlert()
        }
    } catch {
        print("❌ Error transferring sample: \(error)")
        showTransferFailedAlert()
    }
}
```

---

### **Option 2: Elektron Transfer App (Official)**

**Elektron Transfer** is the official Elektron app for transferring samples.

#### **Pros:**
- ✅ Official Elektron software
- ✅ GUI application
- ✅ Free download from Elektron website

#### **Cons:**
- ❌ No command-line interface (can't automate easily)
- ❌ Would require AppleScript or UI automation
- ❌ Less reliable for automation

#### **Implementation:**

You would need to use AppleScript or macOS Accessibility APIs to automate the Transfer app:

```swift
func transferViaElektronTransfer(sample: SampleFile) {
    // 1. Check if Elektron Transfer is installed
    let transferAppPath = "/Applications/Elektron Transfer.app"
    
    guard FileManager.default.fileExists(atPath: transferAppPath) else {
        showElektronTransferNotInstalledAlert()
        return
    }
    
    // 2. Use AppleScript to automate
    let script = """
    tell application "Elektron Transfer"
        activate
        -- Would need to reverse-engineer the UI automation
        -- This is NOT recommended as it's fragile
    end tell
    """
    
    // This approach is NOT recommended
}
```

---

### **Option 3: Direct MIDI SysEx (Advanced)**

Implement MIDI SysEx communication directly in Swift using CoreMIDI.

#### **Pros:**
- ✅ No external dependencies
- ✅ Full control over transfer process
- ✅ Native Swift implementation

#### **Cons:**
- ❌ Complex implementation (need to understand Elektron SysEx protocol)
- ❌ Requires reverse-engineering or documentation
- ❌ Time-consuming to implement
- ❌ Need to handle sample format conversion (48kHz, 16-bit mono/stereo)

---

## 🚀 Recommended Implementation: Elektroid CLI

**Elektroid CLI is the best option** because it's:
- Free and open-source
- Command-line (easy to automate from Swift)
- Actively maintained
- Supports all Elektron devices

### **Quick Start Guide**

#### **1. Install Elektroid**

```bash
# Option A: Homebrew (if available)
brew install elektroid

# Option B: Compile from source
brew install automake libtool pkg-config gtk+3 libsndfile libsamplerate gettext zlib json-glib libzip rtaudio rtmidi
git clone https://github.com/dagargo/elektroid.git
cd elektroid
autoreconf --install
./configure CLI_ONLY=yes
make
sudo make install
```

#### **2. Test Manually**

```bash
# List MIDI devices
elektroid-cli ld

# Example output:
# 0: id: SYSTEM_ID; name: computer
# 1: id: hw:2,0,0; name: Elektron Digitakt, Elektron Digitakt MIDI 1

# Transfer a sample (replace 1 with your device ID)
elektroid-cli elektron:sample:ul ~/sample.wav 1:/incoming

# Check storage
elektroid-cli df 1:/
```

#### **3. Implement in Swift**

See full implementation code in the sections below.

---

## 📋 Implementation Checklist

### **Phase 1: Basic Transfer (MVP)**

- [x] Add "Transfer to Digitakt" button ✅
- [ ] Check if `elektroid-cli` is installed
- [ ] Show installation guide if not installed
- [ ] Detect Digitakt via MIDI
- [ ] Transfer single sample to `/incoming`
- [ ] Show success/error alerts

### **Phase 2: Enhanced Features**

- [ ] Add progress indicator during transfer
- [ ] Add folder selection (where to put sample on Digitakt)
- [ ] Add storage space check before transfer
- [ ] Add batch transfer (multiple samples)
- [ ] Add sample format conversion (if needed)
- [ ] Add transfer history/log

---

## 🔧 Full Swift Implementation

### **Step 1: Create ElektroidCLI Service**

Create `FlowForge/Services/ElektroidCLI.swift`:

```swift
import Foundation

class ElektroidCLI {
    static let shared = ElektroidCLI()

    private let cliPath = "/usr/local/bin/elektroid-cli"

    // Check if elektroid-cli is installed
    func isInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: cliPath)
    }

    // List all MIDI devices
    func listDevices() throws -> [MIDIDevice] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["ld"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return parseMIDIDevices(from: output)
    }

    // Find Digitakt device
    func findDigitakt() throws -> MIDIDevice? {
        let devices = try listDevices()
        return devices.first { $0.name.contains("Digitakt") }
    }

    // Transfer sample to Digitakt
    func transferSample(url: URL, to deviceID: String, folder: String = "/incoming") throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = [
            "elektron:sample:ul",
            url.path,
            "\(deviceID):\(folder)"
        ]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw TransferError.transferFailed
        }
    }

    // Check storage space
    func checkStorage(deviceID: String) throws -> StorageInfo {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
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
            // Format: "1: id: hw:2,0,0; name: Elektron Digitakt, Elektron Digitakt MIDI 1"
            let parts = line.split(separator: ":")
            guard parts.count >= 3 else { continue }

            let id = parts[0].trimmingCharacters(in: .whitespaces)
            let name = parts[2...].joined(separator: ":").trimmingCharacters(in: .whitespaces)

            devices.append(MIDIDevice(id: id, name: name))
        }

        return devices
    }

    private func parseStorageInfo(from output: String) -> StorageInfo {
        // Parse output like:
        // +Drive    959.5MiB    285.9MiB    673.6MiB    29.80%

        // Simplified parsing - you'd want to make this more robust
        return StorageInfo(
            totalSpace: 1_000_000_000,  // 1GB placeholder
            usedSpace: 300_000_000,
            availableSpace: 700_000_000
        )
    }
}

struct MIDIDevice {
    let id: String
    let name: String
}

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let availableSpace: Int64

    var usagePercentage: Double {
        Double(usedSpace) / Double(totalSpace) * 100
    }
}

enum TransferError: Error {
    case elektroidNotInstalled
    case digitaktNotFound
    case transferFailed
    case insufficientSpace
}
```

### **Step 2: Update RandomSampleView**

Replace the placeholder function with the real implementation:

```swift
private func transferToDigitakt(sample: SampleFile) {
    print("🎹 Transfer to Digitakt: \(sample.name)")

    // Check if elektroid-cli is installed
    guard ElektroidCLI.shared.isInstalled() else {
        showElektroidNotInstalledAlert()
        return
    }

    // Find Digitakt
    do {
        guard let digitakt = try ElektroidCLI.shared.findDigitakt() else {
            showDigitaktNotFoundAlert()
            return
        }

        print("✅ Found Digitakt: \(digitakt.name) (ID: \(digitakt.id))")

        // Check storage
        let storage = try ElektroidCLI.shared.checkStorage(deviceID: digitakt.id)
        print("💾 Storage: \(storage.usagePercentage)% used")

        // Transfer sample
        try ElektroidCLI.shared.transferSample(
            url: sample.url,
            to: digitakt.id,
            folder: "/incoming"
        )

        showTransferSuccessAlert(sampleName: sample.name)

    } catch {
        print("❌ Transfer error: \(error)")
        showTransferFailedAlert(error: error)
    }
}

// MARK: - Alert Helpers

private func showElektroidNotInstalledAlert() {
    let alert = NSAlert()
    alert.messageText = "Elektroid Not Installed"
    alert.informativeText = """
    To transfer samples to Digitakt, you need to install Elektroid CLI.

    Installation:
    1. Open Terminal
    2. Run: brew install elektroid
       (or compile from source: github.com/dagargo/elektroid)
    3. Connect your Digitakt via USB
    4. Try again
    """
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Open GitHub")

    let response = alert.runModal()
    if response == .alertSecondButtonReturn {
        NSWorkspace.shared.open(URL(string: "https://github.com/dagargo/elektroid")!)
    }
}

private func showDigitaktNotFoundAlert() {
    let alert = NSAlert()
    alert.messageText = "Digitakt Not Found"
    alert.informativeText = """
    Could not find Digitakt connected via USB.

    Make sure:
    1. Digitakt is powered on
    2. USB cable is connected
    3. Digitakt is in Overbridge mode (if applicable)

    Try disconnecting and reconnecting the USB cable.
    """
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

private func showTransferSuccessAlert(sampleName: String) {
    let alert = NSAlert()
    alert.messageText = "Transfer Complete!"
    alert.informativeText = """
    Sample "\(sampleName)" has been transferred to your Digitakt.

    You can find it in the /incoming folder on your Digitakt.
    """
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

private func showTransferFailedAlert(error: Error) {
    let alert = NSAlert()
    alert.messageText = "Transfer Failed"
    alert.informativeText = """
    Failed to transfer sample to Digitakt.

    Error: \(error.localizedDescription)

    Check the console for more details.
    """
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
}
```

---

## 📚 Resources

- **Elektroid GitHub:** https://github.com/dagargo/elektroid
- **Elektron Transfer:** https://www.elektron.se/support-downloads/transfer
- **Digitakt Manual:** Sample transfer on pages 8-9
- **Elektronauts Forum:** https://www.elektronauts.com/

---

## 🎯 Summary

**Current Status:**
- ✅ Button added to Random Sample Explorer
- ✅ Placeholder implementation with alert
- ✅ Full implementation guide provided

**Next Steps:**
1. Install Elektroid CLI manually and test
2. Create `ElektroidCLI.swift` service
3. Update `RandomSampleView.swift` with real implementation
4. Test with real Digitakt
5. Add progress indicators and polish UI

**Elektroid CLI is the recommended approach** - it's free, open-source, and easy to integrate! 🚀

