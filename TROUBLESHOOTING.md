# FlowForge Build Troubleshooting

## ✅ Verified Working

All Swift files parse correctly:
- ✅ `AppState.swift` - No syntax errors
- ✅ `FolderManager.swift` - No syntax errors
- ✅ `SettingsView.swift` - No syntax errors
- ✅ `ContentView.swift` - No syntax errors

Files are in correct locations:
- ✅ `BLOWBORG/flowforge/Models/AppState.swift`
- ✅ `BLOWBORG/flowforge/Services/FolderManager.swift`
- ✅ `BLOWBORG/flowforge/Views/SettingsView.swift`

## 🔍 Common Build Issues & Solutions

### Issue 1: "Cannot find type 'AppState' in scope"
**Cause:** Files not added to Xcode project target

**Solution:**
1. In Xcode, select `AppState.swift` in Project Navigator
2. Open File Inspector (right sidebar, first tab)
3. Under "Target Membership", ensure `flowforge` is checked
4. Repeat for `FolderManager.swift` and `SettingsView.swift`

**Note:** Your project uses `PBXFileSystemSynchronizedRootGroup` which should auto-include all files in the `BLOWBORG/flowforge/` directory. If files aren't showing up, try:
- Close Xcode
- Delete `~/Library/Developer/Xcode/DerivedData/flowforge-*`
- Reopen Xcode

---

### Issue 2: "Module compiled with Swift X.X cannot be imported by Swift Y.Y"
**Cause:** Swift version mismatch

**Solution:**
1. Select project in Navigator
2. Select `flowforge` target
3. Go to "Build Settings"
4. Search for "Swift Language Version"
5. Set to "Swift 6" (or whatever your Xcode supports)

---

### Issue 3: Files showing in Navigator but not building
**Cause:** Xcode cache issue

**Solution:**
```bash
# Clean build folder
# In Xcode: Shift+Cmd+K

# Or manually:
rm -rf ~/Library/Developer/Xcode/DerivedData/flowforge-*

# Then rebuild: Cmd+B
```

---

### Issue 4: "Use of undeclared type 'WorkflowState'"
**Cause:** AppState.swift not being compiled

**Solution:**
1. Check that `AppState.swift` is in the project
2. Verify it's in the `flowforge` target
3. Try cleaning and rebuilding

---

### Issue 5: "Cannot find 'FolderManager' in scope"
**Cause:** FolderManager.swift not being compiled

**Solution:**
Same as Issue 4 - verify file is in target and rebuild

---

### Issue 6: Xcode shows files but they're grayed out
**Cause:** File references broken

**Solution:**
1. Right-click on grayed file
2. Select "Delete" → "Remove Reference" (don't move to trash)
3. Right-click on `flowforge` folder in Navigator
4. Select "Add Files to flowforge..."
5. Navigate to the file and add it back
6. Ensure "Copy items if needed" is UNCHECKED (files are already there)
7. Ensure "Create groups" is selected
8. Ensure `flowforge` target is checked

---

### Issue 7: "Ambiguous use of 'AudioFile'"
**Cause:** Multiple definitions or import conflicts

**Solution:**
- Check that `AudioFile` is only defined once (in `AppState.swift`)
- Make sure you're not importing any conflicting frameworks

---

### Issue 8: Build succeeds but app crashes on launch
**Cause:** Runtime error, not build error

**Solution:**
1. Run app in Xcode (Cmd+R)
2. Check Console for crash logs
3. Look for error messages
4. Common issues:
   - Missing entitlements for file access
   - UserDefaults key conflicts
   - Folder permission issues

---

## 🛠️ Debug Steps

### Step 1: Verify Project Structure
```bash
cd /Users/elij/Desktop/folders/Programming/FlowForge
find BLOWBORG/flowforge -name "*.swift" -type f
```

Should show:
```
BLOWBORG/flowforge/ContentView.swift
BLOWBORG/flowforge/Item.swift
BLOWBORG/flowforge/flowforgeApp.swift
BLOWBORG/flowforge/Models/AppState.swift
BLOWBORG/flowforge/Services/FolderManager.swift
BLOWBORG/flowforge/Views/SettingsView.swift
```

### Step 2: Check File Permissions
```bash
ls -la BLOWBORG/flowforge/Models/
ls -la BLOWBORG/flowforge/Services/
ls -la BLOWBORG/flowforge/Views/
```

All files should be readable (`-rw-r--r--`)

### Step 3: Verify Xcode Can See Files
In Xcode:
1. Open Project Navigator (Cmd+1)
2. Expand `flowforge` folder
3. You should see:
   - `flowforgeApp.swift`
   - `ContentView.swift`
   - `Item.swift`
   - `Models/` folder with `AppState.swift`
   - `Services/` folder with `FolderManager.swift`
   - `Views/` folder with `SettingsView.swift`

### Step 4: Check Build Phases
1. Select project in Navigator
2. Select `flowforge` target
3. Go to "Build Phases" tab
4. Expand "Compile Sources"
5. Should include all `.swift` files

---

## 📋 What to Share for Help

If still having issues, please provide:

1. **Exact error message** from Xcode
2. **Screenshot** of Issue Navigator (left sidebar, exclamation mark icon)
3. **Xcode version**: Xcode → About Xcode
4. **macOS version**: System Settings → General → About
5. **Build log**: Product → Show Build Log (or Cmd+9)

---

## 🎯 Quick Fixes to Try

1. **Clean Build Folder**: Shift+Cmd+K
2. **Rebuild**: Cmd+B
3. **Restart Xcode**: Quit and reopen
4. **Delete Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/flowforge-*
   ```
5. **Reset Package Caches** (if using SPM):
   File → Packages → Reset Package Caches

---

## ✅ Verification Checklist

Before asking for help, verify:
- [ ] All files exist on disk (checked with `ls`)
- [ ] All files parse correctly (checked with `swiftc -parse`)
- [ ] Files are visible in Xcode Project Navigator
- [ ] Files are in `flowforge` target (File Inspector)
- [ ] Cleaned build folder (Shift+Cmd+K)
- [ ] Tried rebuilding (Cmd+B)
- [ ] Restarted Xcode

---

**Most likely cause:** Xcode cache issue. Try cleaning and rebuilding first!
