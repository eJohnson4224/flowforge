# 🎵 FlowForge

**A Creative Sample & Project Flow Management System**

> *From scattered sketches to focused projects to archived masterpieces*

---

## 📍 Current Status: Phase 1 Complete (75%)

**What's Working:**
- ✅ Full-screen workflow navigation (Sketches → Active → Archive)
- ✅ Folder-based file management (no database)
- ✅ File operations (promote, archive, restore)
- ✅ Settings panel with folder configuration
- ✅ Active slot limit enforcement (max 5)
- ✅ State persistence across launches

**What's Next (Phase 2):**
- 🎯 Audio preview (play files before moving)
- 🎯 Error handling UI (alerts for conflicts)
- 🎯 File conflict resolution (rename/replace)
- 🎯 Undo/redo for file operations
- 🎯 Sample slicing (future phase)

See [docs/roadmap.md](docs/roadmap.md) for the canonical plan. Historical gap analysis: [docs/archive/20260209-phase1-analysis.md](docs/archive/20260209-phase1-analysis.md).

---

## 🧠 Project Philosophy

FlowForge is designed around the creative principle of **constrained exploration**:
- **Sketches** = Infinite possibility (surprise & discovery)
- **Active Projects** = Focused execution (5 slots max)
- **Archive** = Cyclical inspiration (completed work feeds future creativity)

The app enforces creative discipline while maintaining serendipity.

---

## 🎯 Project Name Rationale

**FlowForge** combines:
- **Flow** = Creative flow state, workflow, audio flow
- **Forge** = Crafting, building, shaping raw materials into finished work

Alternative names considered:
- SketchFlow, SampleCycle, ProjectPulse, CreativeSlots, ForgeFlow

---

## ✨ Core Features (Phase 1 - Implemented)

### 📁 Folder-Based Workflow Management

**Three-State Navigation:**
- **Sketches** - Unlimited raw ideas and samples (orange)
- **Active** - 5 focused project slots (blue)
- **Archive** - Completed work for future inspiration (gray)
- Full-screen state switching with smooth animations
- File count badges on navigation tabs

**File Operations:**
- **Promote** - Move from Sketches → Active (with slot limit check)
- **Archive** - Move from Active → Archive
- **Restore** - Move from Archive → Active (with slot limit check)
- Real file system operations (no database)
- Async folder scanning with parallel processing

**Settings & Configuration:**
- Folder selection for each workflow state
- Default state preference (persists across launches)
- Manual rescan option
- File count display per folder
- Clear/change folder options

**Supported File Types:**
- Audio: .wav, .mp3, .aiff, .m4a, .flac, .ogg, .aif
- Projects: .als, .flp, .logic, .ptx, .rpp
- Folders: Treated as projects

---

## 🎛️ Future Features (Phase 2+)

### Audio Preview (Next Priority)
- Play files before moving them
- Waveform visualization
- Play/pause/stop controls
- Preview in all three panels

### Sample Slicing & Editing (Future)
- Visual waveform editor with draggable markers
- Millisecond-accurate time selection
- Extract slices as new files
- Non-destructive editing
- Fade in/out, normalize, reverse
- Batch slicing support

---

## 🛠️ Technology Stack & Development Environment

### Primary: Swift + SwiftUI (macOS Native)

**Why Swift/SwiftUI?**
- ✅ Native macOS performance
- ✅ Beautiful, modern UI with minimal code
- ✅ Direct file system access
- ✅ Native audio preview (AVFoundation)
- ✅ **Powerful audio processing** (AVAudioEngine, AVAudioFile)
- ✅ Easy DAW integration (NSWorkspace for launching apps)
- ✅ Built-in drag & drop support
- ✅ Sandboxing with user-granted folder access

**Development Environment:**
- **IDE:** Xcode 15+ (required for Swift/SwiftUI)
- **Language:** Swift 5.9+
- **Framework:** SwiftUI for UI, Combine for reactive programming
- **Minimum Target:** macOS 13.0 (Ventura) or later
- **Architecture:** No database - folder-based file system truth
- **Audio:** AVFoundation for preview (Phase 2), AVAudioEngine for slicing (future)
- **File Operations:** FileManager for scanning and moving files

---

## 🚀 Development Progress

### ✅ Phase 0: Rapid Prototyping (COMPLETE)
**Goal:** Get something working you can *feel* and interact with

**Completed:**
- [x] Basic 3-panel SwiftUI layout
- [x] Hardcoded sample data (mock projects)
- [x] Click to "promote" from Sketches → Active
- [x] Click to "archive" from Active → Archive
- [x] Visual feedback (animations, state changes)

**Result:** Initial prototype validated the workflow concept

---

### ✅ Phase 1: Real Data Integration (COMPLETE - 75%)
**Goal:** Connect to actual file system

**Completed:**
- [x] Folder picker (user selects Sketches, Active, Archive folders)
- [x] Scan folders and display real files
- [x] Basic metadata extraction (file name, date modified, file type)
- [x] Move files between folders (actual file operations)
- [x] Persist folder paths in UserDefaults
- [x] Full-screen state navigation (replaced 3-panel layout)
- [x] State tabs with file count badges
- [x] Settings panel with folder configuration
- [x] Default state preference (persists across launches)
- [x] Active slot limit enforcement (max 5)
- [x] Empty state views with helpful messages
- [x] Color-coded UI (orange/blue/gray)
- [x] Async folder scanning with parallel processing
- [x] File type detection (audio, project, folder)

**Missing (Phase 2 priorities):**
- [ ] Audio preview (can't listen to files)
- [ ] Error handling UI (only console logs)
- [ ] File conflict resolution (duplicate names)
- [ ] Undo/redo for file operations

**Result:** Solid foundation with working file management workflow

See [docs/roadmap.md](docs/roadmap.md). Historical implementation notes: [docs/archive/20260209-phase1-implementation.md](docs/archive/20260209-phase1-implementation.md) and [docs/archive/20260209-phase1-analysis.md](docs/archive/20260209-phase1-analysis.md).

---

### 🎯 Phase 2: Polish & Audio Preview (IN PLANNING)
**Goal:** Make Phase 1 features bulletproof + add audio preview

**Tier 1 - Critical (Must Have):**
- [ ] Audio preview (AVAudioPlayer integration)
  - [ ] Play/pause/stop controls
  - [ ] Simple waveform visualization
  - [ ] Preview in all three panels
- [ ] Error handling UI
  - [ ] Alert dialogs for errors
  - [ ] Toast notifications for success
  - [ ] Loading states with progress
- [ ] File conflict resolution
  - [ ] Detect duplicate filenames
  - [ ] Rename/replace/skip dialog
  - [ ] Auto-rename option (file_001.wav)

**Tier 2 - Important (Should Have):**
- [ ] Undo/redo for file operations
  - [ ] Move history tracking
  - [ ] Undo last move
  - [ ] Redo undone move
- [ ] Keyboard shortcuts
  - [ ] Space = preview audio
  - [ ] Cmd+1/2/3 = switch states
  - [ ] Cmd+, = settings
  - [ ] Arrow keys = navigate files
- [ ] Better file metadata
  - [ ] Audio duration display
  - [ ] File size display
  - [ ] Format/bitrate info

**Tier 3 - Nice to Have (Could Have):**
- [ ] Drag & drop file movement
- [ ] Search/filter files
- [ ] Auto-refresh on external changes
- [ ] Batch operations (multi-select)

**Strategy:** Polish first, then add complexity. See [docs/roadmap.md](docs/roadmap.md) for rationale.

---

### 🎛️ Phase 3: Sample Slicing (FUTURE)
**Goal:** Slice and edit samples without leaving the app

**Sample Slicer Tool:**
- [ ] Visual waveform editor with zoom
- [ ] Draggable start/end markers
- [ ] Millisecond-accurate selection
- [ ] Keyboard shortcuts for precision
- [ ] Play selection preview with loop
- [ ] Extract slice as new file
- [ ] Batch slicing support
- [ ] Non-destructive editing

**Audio Alterations:**
- [ ] Fade in/out with curves
- [ ] Normalize volume
- [ ] Trim silence
- [ ] Reverse audio
- [ ] Export format options

**DAW Integration:**
- [ ] "Open in Ableton" button
- [ ] "Open in FRMS" button
- [ ] "Reveal in Finder" option
- [ ] Cmd+Z = undo edit

**Philosophy:** Reduce friction between discovery and creation - slice and edit without leaving the app

**Technical Approach:**
- AVAudioPlayer for simple playback
- AVAudioEngine + AVAudioFile for waveform data and slicing
- AVAudioPCMBuffer for precise sample manipulation
- Core Graphics for waveform rendering with zoom/pan
- AVAudioConverter for format conversion
- Export sliced samples to designated "Slices" folder or user-chosen location
- Non-destructive editing: keep original files intact

---

### Phase 3: Smart Features (Week 7-8)
**Goal:** Add the "magic" that makes it indispensable

**Deliverables:**
- [ ] Random sample selector ("Surprise Me!")
- [ ] Tag system (manual tags + auto-tags from filename)
- [ ] Search/filter (by name, tag, date, BPM if detected)
- [ ] Project notes (per-project markdown notes)
- [ ] Progress tracking (manual % slider)
- [ ] Statistics dashboard (samples explored, projects completed, slices created)
- [ ] **Slice library manager** (view all slices, organize by source)
- [ ] **Auto-detect slice points** (transient detection for drums)

**Philosophy:** Enhance creativity without adding complexity

---

### Phase 4: Polish & Optimization (Week 9-10)
**Goal:** Make it beautiful and fast

**Deliverables:**
- [ ] Custom app icon
- [ ] Smooth animations (SwiftUI transitions)
- [ ] Dark mode support
- [ ] Keyboard navigation (arrow keys, tab, etc.)
- [ ] Performance optimization (lazy loading, caching, waveform caching)
- [ ] Error handling (missing files, permissions, corrupted audio)
- [ ] Onboarding flow (first-time setup)
- [ ] **Waveform rendering optimization** (background thread, caching)

**Philosophy:** Delight in the details

---

## 📁 Project Structure

```
FlowForge/
├── README.md                    # This file
├── docs/active/brainstorm.md               # Ongoing ideas and experiments
├── FlowForge.xcodeproj/        # Xcode project (created via Xcode)
├── FlowForge/                  # Main app code
│   ├── FlowForgeApp.swift      # App entry point
│   ├── Models/                 # Data models
│   │   ├── Project.swift       # Project data structure
│   │   ├── ProjectState.swift  # Enum: sketch, active, archived
│   │   ├── AudioSlice.swift    # Slice metadata
│   │   └── AppState.swift      # Global app state (ObservableObject)
│   ├── Views/                  # SwiftUI views
│   │   ├── ContentView.swift   # Main 3-panel layout
│   │   ├── SketchesView.swift  # Sketches panel
│   │   ├── ActiveView.swift    # Active projects panel
│   │   ├── ArchiveView.swift   # Archive panel
│   │   ├── SampleEditorView.swift  # Waveform editor/slicer
│   │   └── Components/         # Reusable UI components
│   │       ├── WaveformView.swift  # Waveform visualization
│   │       ├── TimelineMarker.swift # Draggable markers
│   │       └── AudioControls.swift  # Play/pause/loop controls
│   ├── Services/               # Business logic
│   │   ├── FileManager.swift   # File operations
│   │   ├── AudioPlayer.swift   # Audio preview
│   │   ├── AudioSlicer.swift   # Sample slicing engine
│   │   ├── WaveformGenerator.swift # Waveform data generation
│   │   ├── AudioProcessor.swift    # Fades, normalize, etc.
│   │   └── DAWLauncher.swift   # Launch external apps
│   └── Resources/              # Assets, sounds, etc.
└── Tests/                      # Unit tests (optional but recommended)
```

---

## 🎨 UI/UX Design Principles

### Visual Language
- **Sketches:** Chaotic, grid-based, many items visible
- **Active Projects:** Calm, card-based, spacious (max 5 cards)
- **Archive:** Organized, list/grid toggle, searchable
- **Sample Editor:** Clean, focused, waveform-centric with minimal chrome

### Interaction Patterns
- **Drag & Drop:** Drag from Sketches → Active, Active → Archive
- **Keyboard First:** Power users should never need mouse
- **Contextual Actions:** Right-click for more options (edit, slice, tag, delete, reveal in Finder)
- **Instant Feedback:** Every action has visual/audio confirmation
- **Non-Modal Editing:** Editor opens in side panel or new window, doesn't block main UI

### Color Palette (Suggested)
- **Sketches:** Warm yellows/oranges (exploration, energy)
- **Active:** Cool blues/purples (focus, calm)
- **Archive:** Neutral grays (storage, history)
- **Editor:** Dark theme with high-contrast waveform (green/blue on dark gray)

---

## 🧪 Experimental Features to Try

### "Surprise Me" Algorithm
- **V1:** Pure random selection
- **V2:** Weighted by least-recently-viewed
- **V3:** ML-based (similar to recently promoted samples)

### "Flow State" Mode
- Full-screen Sketches view
- Auto-advance every 10 seconds
- Quick keyboard shortcuts (Y = promote, N = skip, Space = preview, E = edit/slice)

### "Project Graveyard"
- Special Archive section for abandoned projects
- Periodic "resurrect a dead project" prompts

### "Sample DNA"
- Auto-detect BPM, key, genre (using ML or external APIs)
- Suggest complementary samples
- **Transient detection** for auto-slicing drums

### "Smart Slicing"
- **Auto-detect slice points** based on transients (drum hits, etc.)
- **Grid-based slicing** (divide sample into equal parts)
- **BPM-aware slicing** (slice on beat boundaries)
- **Zero-crossing detection** for clean slices (no clicks)

---

## 🚦 Getting Started

### Prerequisites
1. **macOS 13.0+** (Ventura or later)
2. **Xcode 15+** (download from Mac App Store)
3. **Basic Swift knowledge** (or willingness to learn!)

### Step 1: Create Xcode Project
```bash
# Open Xcode
# File → New → Project
# Choose: macOS → App
# Product Name: FlowForge
# Interface: SwiftUI
# Language: Swift
# Save to: /Users/elij/Desktop/folders/Programming/FlowForge/
```

### Step 2: Initial Setup
- Enable file access entitlements (for folder access)
- Set minimum deployment target to macOS 13.0
- Add AVFoundation framework (for audio)
- Add Accelerate framework (for fast waveform processing)

### Step 3: Build Phase 0 Prototype
- Start with `ContentView.swift` - create 3-column layout
- Use `@State` for mock data
- Add buttons that print to console
- Run and iterate!

---

## 🎓 Learning Resources

### Swift/SwiftUI Tutorials
- [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Hacking with Swift - 100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### Audio Programming in Swift
- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [Audio Processing with AVAudioEngine](https://developer.apple.com/documentation/avfoundation/avaudioengine)
- [Working with Audio Files](https://developer.apple.com/documentation/avfoundation/avaudiofile)
- [Waveform Visualization Tutorial](https://www.raywenderlich.com/5154-avaudioengine-tutorial-for-ios-getting-started)

### Relevant Topics
- File system access in SwiftUI
- AVFoundation audio playback
- AVAudioEngine for audio processing
- Core Graphics for waveform rendering
- NSWorkspace for launching apps
- SwiftUI animations and transitions
- Combine framework for reactive programming

---

## 💡 Development Philosophy

### Intrinsically Experimental
- **Try before you plan:** Build a feature in 30 minutes, see if it feels right
- **Fail fast:** If something doesn't spark joy, delete it
- **User (you) first:** Build for YOUR workflow, generalize later

### Optimized for Learning
- **Comment everything:** Future you will thank present you
- **Commit often:** Git is your time machine
- **Refactor ruthlessly:** Code quality improves with iteration

### Functional End Product
- **Ship early:** Get to a "usable" state ASAP
- **Iterate based on use:** Real usage reveals real needs
- **Feature freeze:** At some point, stop adding and start polishing

---

## 📝 Next Steps

1. **Read this README** ✅
2. **Open Xcode and create the project**
3. **Build Phase 0 prototype** (3-panel layout with mock data)
4. **Use it for 1 week** with mock data
5. **Iterate based on feel**
6. **Connect to real folders** (Phase 1)
7. **Build the sample slicer** (Phase 2 - the killer feature!)
8. **Use it for real** with your actual samples
9. **Add features as needed**

---

## 🤝 Contributing (Future)

This is a personal project, but if it grows:
- Open source on GitHub
- Accept PRs for new features
- Build a community of creative coders

---

## 📄 License

TBD (probably MIT or GPL)

---

**Built with ❤️ for creative flow**

*Last updated: 2026-01-04*
