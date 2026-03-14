# FlowForge - Full-Screen UI Mockup

## 🎨 Sketches State (Active)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🔆 SKETCHES 8  │  🔥 ACTIVE 3/5  │  📦 ARCHIVE 12  │          ⚙️      │
│  ═══════════════                                                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ 🎵       │  │ 🎵       │  │ 🎵       │  │ 🎵       │              │
│  │          │  │          │  │          │  │          │              │
│  │ Drum     │  │ Bass     │  │ Vocal    │  │ Guitar   │              │
│  │ Loop 01  │  │ Idea     │  │ Chop     │  │ Riff     │              │
│  │       →  │  │       →  │  │       →  │  │       →  │              │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘              │
│                                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ 🎵       │  │ 📁       │  │ 🎵       │  │ 🎵       │              │
│  │          │  │          │  │          │  │          │              │
│  │ Synth    │  │ Sample   │  │ Beat     │  │ Melody   │              │
│  │ Pad      │  │ Pack     │  │ Sketch   │  │ Idea     │              │
│  │       →  │  │       →  │  │       →  │  │       →  │              │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Features:**
- Orange underline shows Sketches is active
- Grid layout with file cards
- → button to promote to Active
- File type icons (🎵 audio, 📁 folder)

---

## 🔥 Active State (Active)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🔆 SKETCHES 8  │  🔥 ACTIVE 3/5  │  📦 ARCHIVE 12  │          ⚙️      │
│                   ═══════════════                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🎵  Track 01                                              📦    │   │
│  │     In Progress                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🎵  Collab with Sarah                                     📦    │   │
│  │     In Progress                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 📁  Beat Tape 03                                          📦    │   │
│  │     In Progress                                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Empty Slot                                                 ⊕    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Empty Slot                                                 ⊕    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Features:**
- Blue underline shows Active is active
- Badge shows "3/5" (3 files, 5 max)
- Larger cards for focused work
- 📦 button to archive
- Empty slot placeholders

---

## 📦 Archive State (Active)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🔆 SKETCHES 8  │  🔥 ACTIVE 3/5  │  📦 ARCHIVE 12  │          ⚙️      │
│                                     ════════════════                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🎵  Summer EP 2024                                        ↶     │   │
│  │     Archived                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 📁  Beat Pack Vol 1                                       ↶     │   │
│  │     Archived                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🎵  Old Track 2023                                        ↶     │   │
│  │     Archived                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🎵  Remix Project                                         ↶     │   │
│  │     Archived                                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ... 8 more files ...                                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Features:**
- Gray underline shows Archive is active
- Badge shows "12" (total files)
- Compact list view
- ↶ button to restore to Active
- Scrollable for many files

---

## ⚙️ Settings Panel (Updated)

```
┌─────────────────────────────────────────────────────────────┐
│  Workflow Settings                                      ✕   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🔆 Sketches                                    8 files     │
│  ─────────────────────────────────────────────────────────  │
│  /Users/you/Music/FlowForge/Sketches                       │
│                                    [Change]  [Clear]        │
│                                                             │
│  🔥 Active                                      3/5         │
│  ─────────────────────────────────────────────────────────  │
│  /Users/you/Music/FlowForge/Active                         │
│                                    [Change]  [Clear]        │
│                                                             │
│  📦 Archive                                     12 files    │
│  ─────────────────────────────────────────────────────────  │
│  /Users/you/Music/FlowForge/Archive                        │
│                                    [Change]  [Clear]        │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  ⭐ Default State on Launch                                 │
│  ─────────────────────────────────────────────────────────  │
│  Choose which workflow state to show when you open          │
│  FlowForge                                                  │
│                                                             │
│  ┌───────────┬───────────┬───────────┐                     │
│  │ 🔆 Sketches│ 🔥 Active │ 📦 Archive│  ← Segmented Picker │
│  └───────────┴───────────┴───────────┘                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Rescan All Folders]                          [Done]      │
└─────────────────────────────────────────────────────────────┘
```

**New Feature:**
- "Default State on Launch" section
- Segmented picker with icons
- Persists across app restarts

---

## 🎨 Color Scheme

### Sketches (Orange)
- Tab: `#F5A623` (orange)
- Underline: 3px solid orange
- Cards: Orange tint

### Active (Blue)
- Tab: `#4A90E2` (blue)
- Underline: 3px solid blue
- Cards: Blue tint

### Archive (Gray)
- Tab: `#9B9B9B` (gray)
- Underline: 3px solid gray
- Cards: Gray tint

---

## 🎯 Interaction Flow

1. **Launch App** → Opens to default state (Sketches or user preference)
2. **Click Tab** → Smooth 0.2s transition to that state
3. **View Files** → Full-screen content for that state
4. **Perform Action** → Promote/Archive/Restore as before
5. **Switch State** → Click another tab to see different files

---

**The UI is now focused, clean, and gives each workflow state the attention it deserves!**

