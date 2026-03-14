# 🚀 FlowForge Quick Start

**Get from zero to working prototype in 1 hour**

---

## What is FlowForge?

A macOS app to manage your music samples and projects across three states:
- **Sketches** (exploration) → **Active Projects** (4-5 slots) → **Archive** (completed)

Think: Tinder for samples + Kanban for projects + Audio preview built-in

---

## Prerequisites

1. **macOS 13.0+** (Ventura or later)
2. **Xcode 15+** (free from Mac App Store)
3. **30-60 minutes** of focused time

---

## Step-by-Step Setup

### 1. Install Xcode (if needed)
```bash
# Open Mac App Store
# Search for "Xcode"
# Click "Get" or "Install"
# Wait 10-20 minutes (it's ~12GB)
```

### 2. Create New Project
1. Open Xcode
2. **File → New → Project**
3. Choose **macOS** tab → **App** template
4. Click **Next**
5. Fill in:
   - **Product Name:** `FlowForge`
   - **Team:** (select your Apple ID or "None")
   - **Organization Identifier:** `com.yourname` (or anything)
   - **Interface:** **SwiftUI** ← IMPORTANT
   - **Language:** **Swift** ← IMPORTANT
   - **Storage:** None (uncheck Core Data)
   - **Include Tests:** Optional (check if you want)
6. Click **Next**
7. **Save to:** `/Users/elij/Desktop/folders/Programming/FlowForge/`
8. Click **Create**

### 3. Run the Default App
1. Click the **Play** button (▶️) in Xcode toolbar
2. You should see a window with "Hello, World!"
3. **Congrats!** You have a working macOS app

---

## Phase 0: Build the 3-Panel Layout

### Replace ContentView.swift

Open `ContentView.swift` and replace ALL the code with this:

```swift
import SwiftUI

struct ContentView: View {
    @State private var sketches = ["Sample_1.wav", "Sample_2.wav", "Sample_3.wav", "Sample_4.wav"]
    @State private var activeProjects = ["Project_A", "Project_B"]
    @State private var archive = ["Old_Project_1", "Old_Project_2"]
    
    var body: some View {
        HStack(spacing: 0) {
            // SKETCHES PANEL
            VStack {
                Text("SKETCHES")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    ForEach(sketches, id: \.self) { sketch in
                        HStack {
                            Text(sketch)
                            Spacer()
                            Button("→") {
                                promoteToActive(sketch)
                            }
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            
            Divider()
            
            // ACTIVE PROJECTS PANEL
            VStack {
                Text("ACTIVE (4-5 SLOTS)")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    ForEach(activeProjects, id: \.self) { project in
                        HStack {
                            Text(project)
                            Spacer()
                            Button("✓") {
                                archiveProject(project)
                            }
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                Text("\(activeProjects.count) / 5 slots used")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            
            Divider()
            
            // ARCHIVE PANEL
            VStack {
                Text("ARCHIVE")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    ForEach(archive, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button("↺") {
                                restoreToActive(item)
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // ACTIONS
    func promoteToActive(_ sketch: String) {
        guard activeProjects.count < 5 else {
            print("Active slots full!")
            return
        }
        sketches.removeAll { $0 == sketch }
        activeProjects.append(sketch)
    }
    
    func archiveProject(_ project: String) {
        activeProjects.removeAll { $0 == project }
        archive.append(project)
    }
    
    func restoreToActive(_ item: String) {
        guard activeProjects.count < 5 else {
            print("Active slots full!")
            return
        }
        archive.removeAll { $0 == item }
        activeProjects.append(item)
    }
}

#Preview {
    ContentView()
}
```

### Run It!
1. Click **Play** (▶️) again
2. You should see 3 panels: Sketches, Active, Archive
3. Click the buttons to move items between panels
4. **You just built a working prototype!** 🎉

---

## What You Just Built

- ✅ 3-panel layout (Sketches, Active, Archive)
- ✅ Mock data (hardcoded samples/projects)
- ✅ Promote button (Sketches → Active)
- ✅ Archive button (Active → Archive)
- ✅ Restore button (Archive → Active)
- ✅ Slot limit enforcement (max 5 active)
- ✅ Color-coded panels (orange, blue, gray)

---

## Next Steps

### This Week: Experiment with the UI
- [ ] Add more mock data
- [ ] Change colors (try different schemes)
- [ ] Add animations (`.animation(.easeInOut)`)
- [ ] Try different layouts (grid vs list)
- [ ] Add a "Surprise Me" button (random selection)

### Next Week: Connect to Real Files
- [ ] Add folder picker (NSOpenPanel)
- [ ] Scan folders for actual files
- [ ] Display real file names
- [ ] Move files between folders

### Week 3: Add Audio Preview
- [ ] Import AVFoundation
- [ ] Add audio player
- [ ] Preview on click
- [ ] Show waveform (optional)

---

## Learning Resources

### SwiftUI Basics
- [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Hacking with Swift - SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### File System Access
- [NSOpenPanel for folder selection](https://developer.apple.com/documentation/appkit/nsopenpanel)
- [FileManager for file operations](https://developer.apple.com/documentation/foundation/filemanager)

### Audio Playback
- [AVAudioPlayer tutorial](https://www.hackingwithswift.com/example-code/media/how-to-play-sounds-using-avaudioplayer)

---

## Troubleshooting

### "Build Failed" Error
- Make sure you selected **SwiftUI** (not UIKit) when creating project
- Check that deployment target is macOS 13.0+

### App Window Too Small
- Add `.frame(minWidth: 800, minHeight: 600)` to the main HStack

### Buttons Don't Work
- Make sure functions are inside the `ContentView` struct
- Check that `@State` variables are declared

---

## Tips for Success

1. **Run often:** Click Play after every small change
2. **Experiment:** Change colors, sizes, layouts - see what feels good
3. **Comment your code:** Future you will thank you
4. **Commit to Git:** Save your progress frequently
5. **Use it:** Even with mock data, click around and feel the UX

---

## Questions?

- Check `README.md` for full development guide
- Check `brainstorm.md` for feature ideas
- Google: "SwiftUI [thing you want to do]"
- Ask ChatGPT/Claude for SwiftUI code examples

---

**You're ready to build! Go create something amazing.** 🚀

*Last updated: 2026-01-02*
