# Phase 2: Metadata & Preview System Architecture

## 🎯 Requirements Summary

### State-Specific Behaviors

| State | Preview Type | Metadata Depth | Workflow |
|-------|-------------|----------------|----------|
| **Sketches** | Audio playback | Minimal | Simple play/pause |
| **Active** | Session previews | Medium | Prompt after sessions, inherit from Archive |
| **Archive** | Project exports | Rich | Multi-step initiation with prompts |

---

## 📊 Data Model Design

### Core Models

#### 1. **AudioFile** (Enhanced)
```swift
struct AudioFile: Identifiable, Codable {
    let id: UUID
    let url: URL
    let name: String
    let dateModified: Date
    let fileType: FileType
    
    // NEW: Metadata reference
    var metadataID: UUID?  // Links to ProjectMetadata
    
    enum FileType {
        case audio
        case project
        case folder
    }
}
```

#### 2. **ProjectMetadata** (New)
```swift
struct ProjectMetadata: Identifiable, Codable {
    let id: UUID
    let projectName: String
    let createdDate: Date
    var lastModified: Date
    
    // Preview files
    var previewFileURL: URL?  // External preview audio
    var previewHistory: [PreviewSnapshot] = []  // Session previews
    
    // Rich metadata
    var notes: String = ""
    var tags: [String] = []
    var rating: Int? = nil  // 1-5 stars
    
    // Archive-specific prompts
    var archivePrompts: ArchivePrompts?
    
    // Active-specific tracking
    var sessionCount: Int = 0
    var lastSessionDate: Date?
    var needsPreviewUpdate: Bool = false
}
```

#### 3. **ArchivePrompts** (New)
```swift
struct ArchivePrompts: Codable {
    var completionNotes: String = ""  // "What did you accomplish?"
    var challenges: String = ""  // "What challenges did you face?"
    var learnings: String = ""  // "What did you learn?"
    var nextSteps: String = ""  // "What would you do differently?"
    var mood: String = ""  // "How do you feel about this project?"
    var genre: String = ""  // "Genre/style?"
    var bpm: Int? = nil
    var key: String = ""
}
```

#### 4. **PreviewSnapshot** (New)
```swift
struct PreviewSnapshot: Identifiable, Codable {
    let id: UUID
    let date: Date
    let previewURL: URL
    let sessionNotes: String
    let duration: TimeInterval?
}
```

---

## 🗂️ Storage Strategy

### Option A: JSON Files (Recommended for Phase 2)
**Structure:**
```
~/FlowForge/
  metadata/
    {project-uuid}.json  // One file per project
  previews/
    {project-uuid}/
      archive_preview.wav
      session_001.wav
      session_002.wav
```

**Pros:**
- Simple to implement
- Easy to debug
- Human-readable
- No database complexity

**Cons:**
- Manual file management
- No built-in querying

### Option B: SwiftData (Future)
- More robust for complex queries
- Better for large datasets
- Can migrate later

**Recommendation:** Start with JSON, migrate to SwiftData in Phase 3 if needed.

---

## 🎨 UI Components Design

### 1. **Sketches Panel** - Simple Audio Preview

```
┌─────────────────────────────────────┐
│  kick_001.wav                    ⓘ │  ← Info button (metadata)
│  ┌─────────────────────────────┐   │
│  │ ▶️ Play                      │   │  ← Play/pause button
│  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━ │   │  ← Waveform (simple)
│  │ 0:00 / 0:03                 │   │
│  └─────────────────────────────┘   │
│  Modified: 2 hours ago              │
└─────────────────────────────────────┘
```

### 2. **Archive Panel** - Project Initiation Workflow

**Step 1: Trigger Archive**
```
┌─────────────────────────────────────┐
│  Active Project: "Beat 001"         │
│                                     │
│  [Archive This Project]             │
└─────────────────────────────────────┘
```

**Step 2: Multi-Step Sheet**
```
┌─────────────────────────────────────┐
│  Archive Project                    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  Step 1 of 4: Name Your Project    │
│  ┌─────────────────────────────┐   │
│  │ Summer Vibes Beat           │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Cancel]              [Next →]    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Archive Project                    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  Step 2 of 4: Upload Preview        │
│  ┌─────────────────────────────┐   │
│  │  Drop preview file here     │   │
│  │  or click to browse         │   │
│  └─────────────────────────────┘   │
│  Recommended: Final mixdown/bounce  │
│                                     │
│  [← Back]              [Next →]    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Archive Project                    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  Step 3 of 4: Project Reflection    │
│                                     │
│  What did you accomplish?           │
│  ┌─────────────────────────────┐   │
│  │ Finished the main groove... │   │
│  └─────────────────────────────┘   │
│                                     │
│  What challenges did you face?      │
│  ┌─────────────────────────────┐   │
│  │ Struggled with the bass...  │   │
│  └─────────────────────────────┘   │
│                                     │
│  [← Back]              [Next →]    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Archive Project                    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  Step 4 of 4: Additional Details    │
│                                     │
│  Genre: ┌──────────────┐            │
│         │ Lo-fi Hip Hop│            │
│         └──────────────┘            │
│                                     │
│  BPM: ┌────┐  Key: ┌────┐          │
│       │ 85 │       │ Am │          │
│       └────┘       └────┘          │
│                                     │
│  Rating: ⭐⭐⭐⭐☆                   │
│                                     │
│  [← Back]         [Archive ✓]      │
└─────────────────────────────────────┘
```

### 3. **Active Panel** - Session Preview Prompt

```
┌─────────────────────────────────────┐
│  Summer Vibes Beat              ⓘ  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Session 3 • Last updated: 2h ago   │
│                                     │
│  [▶️ Play Latest Preview]           │
│  [📤 Upload New Preview]            │
│                                     │
│  ⚠️ Preview is 2 days old           │
│     Consider uploading a new one    │
└─────────────────────────────────────┘
```

### 4. **Universal Info/Metadata Button**

**Info Sheet (All States):**
```
┌─────────────────────────────────────┐
│  Project Info: Summer Vibes Beat    │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                     │
│  📝 Notes                           │
│  ┌─────────────────────────────┐   │
│  │ Working on the bassline...  │   │
│  └─────────────────────────────┘   │
│                                     │
│  🏷️ Tags                            │
│  [lo-fi] [chill] [hip-hop]         │
│  + Add tag                          │
│                                     │
│  ⭐ Rating: ⭐⭐⭐⭐☆               │
│                                     │
│  📊 Details                         │
│  Genre: Lo-fi Hip Hop               │
│  BPM: 85  Key: Am                   │
│  Created: Jan 1, 2026               │
│  Sessions: 3                        │
│                                     │
│  [Save]                   [Cancel]  │
└─────────────────────────────────────┘
```

---

## 🔧 Implementation Plan

### Phase 2A: Foundation (Week 1)
1. Create data models (ProjectMetadata, ArchivePrompts, PreviewSnapshot)
2. Build MetadataManager service (save/load JSON)
3. Update AudioFile to include metadataID
4. Create preview file storage structure

### Phase 2B: Sketches Audio Preview (Week 1-2)
1. Integrate AVAudioPlayer in AppState
2. Add play/pause controls to FileCard
3. Simple waveform visualization (optional)
4. Info button → metadata sheet

### Phase 2C: Archive Initiation Workflow (Week 2)
1. Multi-step sheet UI (4 steps)
2. Preview file upload/selection
3. Archive prompts form
4. Save metadata + move file + copy preview

### Phase 2D: Active Session Tracking (Week 3)
1. Session counter
2. Preview upload prompt
3. Inherit metadata from Archive
4. "Needs update" indicator

### Phase 2E: Universal Metadata Editor (Week 3)
1. Info button on all file cards
2. Metadata edit sheet
3. Save/load metadata
4. Display metadata in cards

---

## 📁 File Structure Changes

```
BLOWBORG/
  flowforge/
    Models/
      AppState.swift (existing)
      AudioFile.swift (new - extract from AppState)
      ProjectMetadata.swift (new)
      ArchivePrompts.swift (new)
      PreviewSnapshot.swift (new)
    Services/
      FolderManager.swift (existing)
      MetadataManager.swift (new)
      AudioPreviewManager.swift (new)
    Views/
      ContentView.swift (existing)
      SettingsView.swift (existing)
      Sketches/
        SketchesPanel.swift (existing - enhance)
        AudioPreviewCard.swift (new)
      Active/
        ActivePanel.swift (existing - enhance)
        SessionPreviewPrompt.swift (new)
      Archive/
        ArchivePanel.swift (existing - enhance)
        ArchiveInitiationSheet.swift (new)
      Shared/
        MetadataSheet.swift (new)
        FileCard.swift (existing - enhance)
```

---

**Next Step:** Should I start implementing the data models and MetadataManager?
