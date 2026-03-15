# Xcode Setup Checklist - Phase 1

## 📋 Steps to Add New Files to Xcode

### 1. Open Xcode Project
```bash
cd /Users/elij/Desktop/folders/Programming/FlowForge
open FlowForge.xcodeproj
```

### 2. Create Folder Structure in Xcode
Right-click on the `flowforge` folder in Project Navigator (under `FlowForge`):

**Create these groups (folders):**
- `Models` (if not exists)
- `Services` (if not exists)
- `Views` (if not exists)

### 3. Add New Files to Project

**Drag and drop these files into Xcode:**

#### Into `Models/` group:
- `FlowForge/Models/AppState.swift`

#### Into `Services/` group:
- `FlowForge/Services/FolderManager.swift`

#### Into `Views/` group:
- `FlowForge/Views/SettingsView.swift`

**Important:** When dragging files:
- ✅ Check "Copy items if needed"
- ✅ Check "Create groups"
- ✅ Select target: `flowforge`

### 4. Verify File References
In Project Navigator, you should see:
```
FlowForge/
├── FlowForgeApp.swift
├── ContentView.swift
├── Item.swift
├── Models/
│   └── AppState.swift
├── Services/
│   └── FolderManager.swift
├── Views/
│   └── SettingsView.swift
└── Assets.xcassets/
```

### 5. Build the Project
- Press `Cmd + B` to build
- Fix any compilation errors (there shouldn't be any)

---

## 🧪 Testing Checklist

### Test 1: Launch App
- [ ] App launches without crashing
- [ ] Three empty panels visible
- [ ] Gear icon visible in top-right corner
- [ ] Empty state messages show: "No folder selected"

### Test 2: Open Settings
- [ ] Click gear icon
- [ ] Settings panel opens as modal sheet
- [ ] Three folder configuration rows visible
- [ ] Each shows "Select Folder" button

### Test 3: Configure Sketches Folder
- [ ] Click "Select Folder" for Sketches
- [ ] Folder picker opens with prompt: "Select your Sketches folder..."
- [ ] Navigate to a folder with audio files
- [ ] Select folder
- [ ] Folder path appears in settings
- [ ] File count updates (e.g., "8 files")

### Test 4: Configure Active Folder
- [ ] Click "Select Folder" for Active
- [ ] Select a different folder
- [ ] Folder path appears
- [ ] File count shows "X/5"

### Test 5: Configure Archive Folder
- [ ] Click "Select Folder" for Archive
- [ ] Select a third folder
- [ ] Folder path appears
- [ ] File count updates

### Test 6: View Files in Panels
- [ ] Click "Done" to close settings
- [ ] Sketches panel shows files from Sketches folder
- [ ] Active panel shows files from Active folder
- [ ] Archive panel shows files from Archive folder
- [ ] File names display correctly
- [ ] File type icons show (🎵 for audio, 📁 for folders)

### Test 7: Promote File (Sketches → Active)
- [ ] Click → button on a sketch
- [ ] File disappears from Sketches panel
- [ ] File appears in Active panel
- [ ] File actually moved in Finder (verify manually)
- [ ] Active count increments (e.g., "3/5" → "4/5")

### Test 8: Archive File (Active → Archive)
- [ ] Click 📦 button on an active file
- [ ] File disappears from Active panel
- [ ] File appears in Archive panel
- [ ] File actually moved in Finder
- [ ] Active count decrements

### Test 9: Restore File (Archive → Active)
- [ ] Click ↶ button on an archived file
- [ ] File disappears from Archive panel
- [ ] File appears in Active panel
- [ ] File actually moved in Finder

### Test 10: Active Slot Limit
- [ ] Promote files until Active has 5 files
- [ ] Try to promote another file
- [ ] Check console for: "⚠️ Active slots full!"
- [ ] File should NOT move

### Test 11: Rescan Folders
- [ ] Add a file to Sketches folder in Finder
- [ ] Open settings
- [ ] Click "Rescan All Folders"
- [ ] New file appears in Sketches panel

### Test 12: Change Folder
- [ ] Open settings
- [ ] Click "Change" for Sketches
- [ ] Select a different folder
- [ ] Files update to show new folder contents

### Test 13: Clear Folder
- [ ] Open settings
- [ ] Click "Clear" for Archive
- [ ] Archive panel shows empty state
- [ ] Settings shows "Select Folder" button again

### Test 14: Persistence
- [ ] Configure all three folders
- [ ] Quit app (Cmd + Q)
- [ ] Relaunch app
- [ ] Folders should still be configured
- [ ] Files should load automatically

---

## 🐛 Common Issues & Fixes

### Issue: Files not showing in Xcode
**Fix:** Make sure files are in the correct physical location:
```bash
ls -la FlowForge/Models/
ls -la FlowForge/Services/
ls -la FlowForge/Views/
```

### Issue: Build errors about missing files
**Fix:** Check target membership:
1. Select file in Project Navigator
2. Open File Inspector (right panel)
3. Ensure `flowforge` target is checked

### Issue: "No such module" errors
**Fix:** Clean build folder:
- `Cmd + Shift + K` (Clean Build Folder)
- `Cmd + B` (Build again)

### Issue: Folder picker doesn't open
**Fix:** Check app sandbox entitlements:
1. Select project in Navigator
2. Select `flowforge` target
3. Go to "Signing & Capabilities"
4. Ensure "User Selected File" is set to "Read/Write"

### Issue: Files don't move
**Fix:** Check file permissions and folder access:
- Make sure folders are writable
- Check Console for error messages
- Verify folders are different (can't be the same)

---

## 🎯 Success Criteria

Phase 1 is complete when:
- ✅ All files compile without errors
- ✅ App launches and shows three panels
- ✅ Settings panel opens and allows folder selection
- ✅ Files from folders display in panels
- ✅ Promote/Archive/Restore buttons move actual files
- ✅ Active slot limit (5) is enforced
- ✅ Folder paths persist across app restarts

---

## 📝 Next Steps After Testing

Once Phase 1 is working:
1. Commit changes to git
2. Document any bugs or issues
3. Plan Phase 2 (audio preview & playback)
4. Consider adding:
   - Error alerts (instead of console logs)
   - Loading spinners during scan
   - Keyboard shortcuts
   - Right-click context menus

---

**Ready to build! 🚀**
