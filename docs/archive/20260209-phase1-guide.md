# Phase 1: Folder Integration - User Guide

## 🎯 What Changed

FlowForge now connects to **real folders** on your file system instead of using mock data. The workflow is simple:

**Folder = State**
- Files in your Sketches folder → appear in Sketches panel
- Files in your Active folder → appear in Active panel  
- Files in your Archive folder → appear in Archive panel

Moving a file between panels = Moving the actual file between folders.

---

## 🚀 Getting Started

### 1. Launch the App
When you first launch FlowForge, you'll see three empty panels with a **gear icon** in the top-right corner.

### 2. Open Settings
Click the **gear icon** (⚙️) to open the Workflow Settings panel.

### 3. Configure Your Folders
For each workflow state, click **"Select Folder"** and choose a folder:

- **Sketches**: Where you keep raw ideas, samples, loops (unlimited)
- **Active**: Where you work on focused projects (max 5 files)
- **Archive**: Where completed work lives (unlimited)

**Important:** Each folder must be different. You can't use the same folder for multiple states.

### 4. Start Working
Once folders are configured:
- The app automatically scans and displays your files
- Click the **→** button on a sketch to promote it to Active
- Click the **archive** button on an active project to move it to Archive
- Click the **restore** button on an archived project to bring it back to Active

---

## 🎵 Musical Workflow Principles

### Simplicity Through Constraints
- **Active folder limited to 5 files** - Forces focus, prevents overwhelm
- **Flat scanning only** - No nested folders, keeps it simple
- **File system is truth** - No databases, no sync issues

### Nuance in the Details
- **Supported file types**: .wav, .mp3, .aiff, .m4a, .flac, .als, .flp, and more
- **Folders treated as projects** - Organize however you want
- **Sorted by date modified** - Most recent work appears first

### Frequency Separation
Like how different instruments occupy different frequency ranges, each workflow state has its own "space":
- **Sketches** (Orange) = High-frequency exploration, rapid iteration
- **Active** (Blue) = Mid-range focus, sustained attention
- **Archive** (Gray) = Low-frequency foundation, completed work

---

## 🔧 Settings Panel Features

### Folder Configuration
Each workflow state shows:
- Current folder path (or "Select Folder" if not set)
- File count (with limit for Active)
- **Change** button - Select a different folder
- **Clear** button - Remove folder configuration

### Rescan Button
Click **"Rescan All Folders"** to refresh the file list if you:
- Added files outside the app
- Renamed files in Finder
- Want to see the latest changes

---

## 📁 Recommended Folder Structure

### Option 1: Dedicated FlowForge Folders
```
~/Music/FlowForge/
├── Sketches/
│   ├── drum_loop_01.wav
│   ├── bass_idea.wav
│   └── vocal_sample.mp3
├── Active/
│   ├── track_01.als
│   ├── beat_tape_03/
│   └── collab_project.flp
└── Archive/
    ├── summer_ep_2024/
    └── finished_beat.wav
```

### Option 2: Integrate with Existing Workflow
```
~/Music/Production/
├── Ideas/          → Set as Sketches
├── Current/        → Set as Active
└── Completed/      → Set as Archive
```

---

## 🎹 Usage Tips

### 1. Keep Sketches Messy
Don't overthink organization in Sketches. It's meant for exploration. Dump everything here.

### 2. Active is Sacred
Only promote files you're **actively working on**. The 5-slot limit is intentional - it forces you to finish or archive.

### 3. Archive is Inspiration
Completed work isn't dead - it's a library. Browse your archive when you need inspiration or want to revisit old ideas.

### 4. Use Folders as Projects
If you have a project with multiple files (stems, MIDI, samples), keep them in a folder. FlowForge treats folders as single items.

---

## 🐛 Troubleshooting

### "No files found" but I have files in the folder
- Make sure files are **top-level** (not in subfolders)
- Check file extensions are supported (.wav, .mp3, .aiff, etc.)
- Click "Rescan All Folders" in settings

### "Active slots full" when trying to promote
- You have 5 files in Active already
- Archive or delete a project first
- This is intentional - focus on finishing before starting new work

### Files not moving when I click buttons
- Check folder permissions (macOS may need access approval)
- Make sure destination folder is configured
- Check Console for error messages

---

## 🔮 What's Next (Phase 2)

Coming soon:
- **Audio preview** - Click to hear samples
- **Waveform visualization** - See what you're working with
- **Sample slicing** - Edit audio without leaving the app
- **DAW integration** - Open projects directly in Ableton, FL Studio, etc.

---

## 💡 Philosophy Reminder

> "Simplicity in respect to nuance and unique frequencies"

The folder system is **simple** (just three folders), but the **nuance** comes from:
- How you organize within each folder
- Which files you choose to promote
- When you decide to archive
- The creative constraints that emerge from the 5-slot limit

Like a well-mixed track, each element has its place. The system doesn't do the work for you - it creates the **space** for your creativity to flow.

---

**Happy creating! 🎵**

