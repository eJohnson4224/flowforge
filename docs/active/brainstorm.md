# 🧠 FlowForge Brainstorming & Experiments

**Living document for ideas, experiments, and design decisions**

---

## 🎯 Core Questions to Answer

### 1. How do we define a "project"?
- Is it a folder? A single file? A collection of files?
- Do we track Ableton .als files? Audio stems? Both?
- Should we support multiple file types per project?

**Current thinking:**
- Start simple: 1 project = 1 folder OR 1 file
- Phase 2: Support project bundles (folder with multiple files)

---

### 2. What makes a good "Surprise Me" algorithm?
- Pure random feels repetitive
- Least-recently-viewed might surface forgotten gems
- Could we weight by file creation date (newer = more likely)?

**Experiments to try:**
- [ ] Pure random (baseline)
- [ ] Weighted by last access time
- [ ] Weighted by file age (prefer newer)
- [ ] Exclude recently promoted items
- [ ] User feedback: "Show me more like this" / "Never show this again"

---

### 3. How do we handle the 4-5 slot limit?
- Hard limit (can't promote if slots full)?
- Soft limit (warning but allow)?
- Auto-archive oldest when promoting new?

**Current thinking:**
- Hard limit with clear UI feedback
- "Pull from Archive" button becomes prominent when slots full
- Option to temporarily expand to 6 slots (with warning)

---

### 4. File operations: Move or Reference?
- **Move:** Physically move files between folders (destructive but clear)
- **Reference:** Keep files in place, track state in database (safer but complex)

**Current thinking:**
- Phase 0-1: Reference-based (safer for testing)
- Phase 2: Add option to physically move files
- Always ask for confirmation before moving

---

## 🎨 UI/UX Experiments

### Sketches Panel Ideas

**Layout Options:**
- Grid view (like Finder icons)
- List view (like Finder list)
- Masonry layout (Pinterest-style)
- Carousel (swipe through samples)

**Interaction Ideas:**
- Hover to preview (auto-play audio)
- Click to select, double-click to promote
- Drag & drop to Active panel
- Right-click for context menu (tag, delete, reveal in Finder)

**Visual Experiments:**
- Show waveform thumbnails
- Color-code by file type (audio, MIDI, project)
- Animate on hover (subtle scale/glow)

---

### Active Projects Panel Ideas

**Layout Options:**
- Card grid (2x3 or 3x2)
- Horizontal carousel
- Vertical list with large cards
- Kanban-style columns (To Do, In Progress, Done)

**Card Content:**
- Project name (editable)
- Last modified date
- Progress bar (manual or auto-detected)
- Quick actions (Open, Archive, Notes)
- Thumbnail/waveform preview

**Interaction Ideas:**
- Click card to expand (show notes, tags, history)
- Drag to reorder priority
- Keyboard shortcuts (1-5 to select slot, Enter to open)

---

### Archive Panel Ideas

**Layout Options:**
- Timeline view (grouped by completion date)
- Grid view (like Photos app)
- List view (sortable by name, date, tags)

**Features:**
- Search bar (fuzzy search)
- Filter by tag, date range, DAW
- "Restore to Active" button (if slot available)
- "Export" button (zip project files)

---

## 🔧 Technical Experiments

### File Monitoring Approaches

**Option 1: DispatchSource (low-level)**
```swift
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: .write,
    queue: DispatchQueue.main
)
```
- Pros: Fast, efficient
- Cons: Complex, requires file descriptors

**Option 2: FileManager + Timer**
```swift
Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    // Scan folders for changes
}
```
- Pros: Simple, reliable
- Cons: Polling overhead, not real-time

**Option 3: FSEvents (macOS-specific)**
- Pros: Native, efficient, real-time
- Cons: Requires C interop

**Current thinking:** Start with Option 2 (simple), optimize to Option 3 later

---

### Audio Preview Strategies

**Option 1: AVAudioPlayer (simple)**
```swift
let player = try AVAudioPlayer(contentsOf: url)
player.play()
```
- Pros: Easy, works for most formats
- Cons: Limited control, no streaming

**Option 2: AVAudioEngine (advanced)**
- Pros: Real-time effects, waveform data
- Cons: Complex setup

**Current thinking:** Start with AVAudioPlayer, add AVAudioEngine for waveforms

---

### Data Persistence Options

**Option 1: UserDefaults (simplest)**
- Store folder paths, settings
- Not suitable for large datasets

**Option 2: JSON files**
- Store project metadata in JSON
- Easy to debug, human-readable
- No schema enforcement

**Option 3: Core Data**
- Full ORM, relationships, migrations
- Overkill for simple app?

**Option 4: SwiftData (new in macOS 14)**
- Modern, Swift-native
- Simpler than Core Data
- Requires macOS 14+

**Current thinking:** 
- Phase 0-1: UserDefaults + JSON
- Phase 2+: Migrate to SwiftData

---

## 🎵 DAW Integration Research

### Ableton Live
- File extension: `.als`
- Launch command: `open -a "Ableton Live" /path/to/project.als`
- Can we detect if Ableton is installed?
- Can we pass command-line args (e.g., open in background)?

### FRMS
- Need to research: Is this a macOS app? iOS only?
- File format?
- Launch mechanism?

### Koala Sampler
- Primarily iOS/Android
- Desktop version exists?
- File sharing via iCloud/Dropbox?

**Action items:**
- [ ] Test Ableton launch on your machine
- [ ] Research FRMS integration
- [ ] Investigate Koala desktop workflow

---

## 🧪 Feature Experiments

### "Flow State" Mode
**Concept:** Full-screen, distraction-free sample exploration

**Mockup:**
```
┌─────────────────────────────────────────┐
│                                         │
│         [Large Waveform Display]        │
│                                         │
│         "Sample_Name_Here.wav"          │
│                                         │
│    [Y] Promote  [N] Skip  [Space] Play  │
│                                         │
│         Auto-advance in 10s...          │
│                                         │
└─────────────────────────────────────────┘
```

**Questions:**
- Auto-play on load?
- Auto-advance timer (configurable)?
- Keyboard-only navigation?

---

### "Project Graveyard"
**Concept:** Special section for abandoned projects

**Features:**
- Auto-detect projects untouched for 90+ days
- Suggest archiving or deleting
- "Resurrect" button to restore to Active
- Stats: "You've abandoned 23 projects this year"

**Questions:**
- Is this motivating or depressing?
- Should it be opt-in?

---

### "Sample DNA"
**Concept:** Auto-detect audio characteristics

**Possible Metadata:**
- BPM (tempo detection)
- Key (pitch detection)
- Genre (ML classification)
- Mood (happy, sad, energetic, calm)
- Instruments detected

**Implementation:**
- Use Essentia (audio analysis library)
- Or call external API (e.g., AcousticBrainz)
- Or train custom ML model

**Questions:**
- Is this worth the complexity?
- Start with manual tagging, add auto-detection later?

---

## 🎨 Visual Design Experiments

### Color Schemes

**Option 1: Vibrant**
- Sketches: Orange (#FF6B35)
- Active: Blue (#004E89)
- Archive: Gray (#6C757D)

**Option 2: Pastel**
- Sketches: Peach (#FFB4A2)
- Active: Lavender (#B5A6D9)
- Archive: Sage (#A8DADC)

**Option 3: Dark Mode First**
- Sketches: Gold (#FFD700)
- Active: Cyan (#00CED1)
- Archive: Silver (#C0C0C0)

**Current thinking:** Support all three as themes!

---

### Typography

**System Fonts (safe):**
- SF Pro (macOS default)
- SF Mono (for code/paths)

**Custom Fonts (personality):**
- Inter (modern, clean)
- JetBrains Mono (for technical info)
- Recursive (variable font, fun)

**Current thinking:** Start with SF Pro, experiment with custom fonts later

---

### Iconography

**Icon Style:**
- SF Symbols (native macOS icons)
- Custom illustrations (hand-drawn?)
- Minimalist line art

**Key Icons Needed:**
- Sketches: Lightbulb, Shuffle, Grid
- Active: Hammer, Wrench, Play
- Archive: Box, Folder, Clock

---

## 🚀 Roadmap Ideas (Beyond Phase 4)

### Phase 5: Collaboration
- Share projects with collaborators
- Cloud sync (iCloud, Dropbox)
- Version control (Git integration?)

### Phase 6: Mobile Companion
- iOS app to browse/tag samples on the go
- Quick voice notes for project ideas
- Sync with desktop app

### Phase 7: AI Assistant
- "Find me a sample that sounds like X"
- Auto-generate project names
- Suggest next steps based on project state

### Phase 8: Community
- Share sample packs
- Discover other users' projects
- Collaborative playlists

---

## 📊 Metrics to Track

**Usage Metrics:**
- Samples explored per session
- Projects promoted per week
- Projects completed per month
- Average time in each state (Sketch → Active → Archive)

**Quality Metrics:**
- Completion rate (Active → Archive vs. abandoned)
- Revisit rate (Archive → Active)
- "Surprise Me" engagement

**Performance Metrics:**
- App launch time
- Folder scan time
- Audio preview latency

---

## 🤔 Open Questions

1. Should we support non-audio files (MIDI, images, text)?
2. How do we handle nested folders (projects within projects)?
3. Should we integrate with streaming platforms (SoundCloud, Spotify)?
4. Is there a market for this beyond personal use?
5. Should we build a plugin system for extensibility?

---

## 💡 Random Ideas (Unsorted)

- "Daily Sample" notification (like Duolingo)
- Integration with sample pack websites (Splice, Loopcloud)
- Export project as playlist (for listening outside DAW)
- "Sample Journal" - log thoughts/ideas per sample
- Gamification: Badges for milestones (100 samples explored, 10 projects completed)
- "Focus Mode" - hide Sketches/Archive, show only Active
- Pomodoro timer integration (25 min work, 5 min explore)
- "Sample Roulette" - random sample + random constraint (e.g., "make a beat in 10 minutes")

---

**Keep this document alive! Add ideas as they come.**

*Last updated: 2026-01-02*
