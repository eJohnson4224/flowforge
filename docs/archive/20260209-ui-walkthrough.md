# FlowForge Phase 1 - UI Walkthrough

## 🎨 Main Window Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                              ⚙️ Settings │
├─────────────────┬─────────────────┬─────────────────────────────────────┤
│   SKETCHES 🔆   │    ACTIVE 🔥    │         ARCHIVE 📦                  │
│   8 files       │    3/5 slots    │         12 files                    │
├─────────────────┼─────────────────┼─────────────────────────────────────┤
│                 │                 │                                     │
│  ┌───────────┐  │  ┌───────────┐  │  ┌─────────────────────────────┐   │
│  │ 🎵        │  │  │ 🎵 Track  │  │  │ 🎵 Summer EP    ↶           │   │
│  │           │  │  │    01     │  │  │    Archived                 │   │
│  │ Drum Loop │  │  │ In Prog.. │  │  └─────────────────────────────┘   │
│  │        →  │  │  │        📦 │  │                                     │
│  └───────────┘  │  └───────────┘  │  ┌─────────────────────────────┐   │
│                 │                 │  │ 📁 Beat Pack    ↶           │   │
│  ┌───────────┐  │  ┌───────────┐  │  │    Archived                 │   │
│  │ 🎵        │  │  │ 🎵 Collab │  │  └─────────────────────────────┘   │
│  │           │  │  │    Sarah  │  │                                     │
│  │ Bass Idea │  │  │ In Prog.. │  │  ┌─────────────────────────────┐   │
│  │        →  │  │  │        📦 │  │  │ 🎵 Old Track    ↶           │   │
│  └───────────┘  │  └───────────┘  │  │    Archived                 │   │
│                 │                 │  └─────────────────────────────┘   │
│  ┌───────────┐  │  ┌───────────┐  │                                     │
│  │ 🎵        │  │  │ 🎵 Beat   │  │                                     │
│  │           │  │  │    Tape   │  │                                     │
│  │ Vocal Chp │  │  │ In Prog.. │  │                                     │
│  │        →  │  │  │        📦 │  │                                     │
│  └───────────┘  │  └───────────┘  │                                     │
│                 │                 │                                     │
│  ┌───────────┐  │  ┌───────────┐  │                                     │
│  │ ...more   │  │  │ Empty Slot│  │                                     │
│  └───────────┘  │  │    ⊕      │  │                                     │
│                 │  └───────────┘  │                                     │
│                 │                 │                                     │
│                 │  ┌───────────┐  │                                     │
│                 │  │ Empty Slot│  │                                     │
│                 │  │    ⊕      │  │                                     │
│                 │  └───────────┘  │                                     │
└─────────────────┴─────────────────┴─────────────────────────────────────┘
```

---

## ⚙️ Settings Panel

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
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  🔥 Active                                      3/5         │
│  ─────────────────────────────────────────────────────────  │
│  /Users/you/Music/FlowForge/Active                         │
│                                    [Change]  [Clear]        │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  📦 Archive                                     12 files    │
│  ─────────────────────────────────────────────────────────  │
│  /Users/you/Music/FlowForge/Archive                        │
│                                    [Change]  [Clear]        │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Rescan All Folders]                          [Done]      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Empty State (No Folders Configured)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                              ⚙️ Settings │
├─────────────────┬─────────────────┬─────────────────────────────────────┤
│   SKETCHES 🔆   │    ACTIVE 🔥    │         ARCHIVE 📦                  │
│   0 files       │    0/5 slots    │         0 files                     │
├─────────────────┼─────────────────┼─────────────────────────────────────┤
│                 │                 │                                     │
│                 │                 │                                     │
│      📁❓       │      📁❓       │            📁❓                     │
│                 │                 │                                     │
│  No folder      │  No folder      │      No folder                      │
│  selected       │  selected       │      selected                       │
│                 │                 │                                     │
│  Configure      │  Configure      │      Configure                      │
│  folders in     │  folders in     │      folders in                     │
│  settings       │  settings       │      settings                       │
│                 │                 │                                     │
│                 │                 │                                     │
└─────────────────┴─────────────────┴─────────────────────────────────────┘
```

---

## 🎨 Color Scheme

### Sketches (Orange)
- Background: `Color.orange.opacity(0.15)`
- Border: `Color.orange.opacity(0.3)`
- Text: `Color.orange`
- Icon: `lightbulb.fill`

### Active (Blue)
- Background: `Color.blue.opacity(0.15)`
- Border: `Color.blue.opacity(0.3)`
- Text: `Color.blue`
- Icon: `flame.fill`

### Archive (Gray)
- Background: `Color.gray.opacity(0.1)`
- Border: `Color.gray.opacity(0.2)`
- Text: `Color.gray`
- Icon: `archivebox.fill`

---

## 🎵 File Type Icons

- **Audio files** (.wav, .mp3, etc.): `waveform`
- **Project files** (.als, .flp, etc.): `doc.fill`
- **Folders**: `folder.fill`

---

## 🔘 Interactive Elements

### Sketches Panel
- **→ Button**: Promotes file to Active
- Hover: Subtle scale animation (future)
- Click: Moves file to Active folder

### Active Panel
- **📦 Button**: Archives file
- Shows "In Progress" status
- Larger cards (more prominent)

### Archive Panel
- **↶ Button**: Restores file to Active
- Shows "Archived" status
- Compact list view

### Settings Button
- **⚙️ Icon**: Top-right corner
- Floating above main content
- Opens settings modal sheet

---

## 📱 Responsive Behavior

- **Minimum window size**: 900x600
- **Sketches panel**: Grid adapts to width (minimum 120px per card)
- **Active panel**: Fixed vertical stack
- **Archive panel**: Scrollable list

---

## ✨ Visual Feedback

### File Operations
- Optimistic UI updates (instant)
- Rescan after operation completes
- Error messages in console (future: alerts)

### Loading States
- `isScanning` flag shows activity
- Future: Spinner or progress indicator

### Empty Slots
- Dashed border
- "Empty Slot" placeholder
- `plus.circle.dashed` icon

---

**Design Philosophy:** Clean, minimal, focused. Let the files be the content, not the chrome.

