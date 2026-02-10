# Bug Fixes - State Loading and Settings

## 🐛 Bugs Fixed

### 1. Default Load State Loop
**Problem:** The `didSet` observer on `currentState` was firing when loading the saved state from UserDefaults, causing unnecessary saves and potential infinite loops.

**Root Cause:**
```swift
@Published var currentState: WorkflowState = .sketches {
    didSet {
        UserDefaults.standard.set(currentState.rawValue, forKey: currentStateKey)
    }
}
```
When `loadFolderPaths()` set `currentState = state`, it triggered `didSet`, which saved to UserDefaults again.

**Solution:** Separated concerns - created `defaultState` for the preference and `currentState` for the active view.

---

### 2. Settings Changing Current View
**Problem:** Changing the default state in Settings immediately changed which state was visible in the main UI, which was confusing.

**Root Cause:** The Settings picker was bound to `$appState.currentState`, so changing it affected the live UI.

**Solution:** Created separate `defaultState` property that only affects the next app launch, not the current view.

---

### 3. Archive State Not Accessible
**Problem:** The segmented picker in Settings didn't clearly show all three states, making Archive hard to select.

**Root Cause:** 
- Segmented picker with `HStack` content wasn't rendering properly
- Labels were too compact
- No visual feedback for selection

**Solution:** Replaced segmented picker with custom button-based selector with clear visual states.

---

## ✅ Solutions Implemented

### 1. Separate `defaultState` from `currentState`

**AppState.swift:**
```swift
@Published var currentState: WorkflowState = .sketches

// Default state to show on launch (separate from current state)
@Published var defaultState: WorkflowState = .sketches {
    didSet {
        // Persist default state preference
        UserDefaults.standard.set(defaultState.rawValue, forKey: defaultStateKey)
    }
}
```

**Benefits:**
- ✅ No didSet loop on load
- ✅ Settings don't affect current view
- ✅ Clear separation of concerns

---

### 2. Load Default State on Init

**AppState.swift - loadFolderPaths():**
```swift
// Load default state preference
if let stateRaw = UserDefaults.standard.string(forKey: defaultStateKey),
   let state = WorkflowState(rawValue: stateRaw) {
    defaultState = state
    currentState = state  // Set current state to default on launch
}
```

**Flow:**
1. App launches
2. Load `defaultState` from UserDefaults
3. Set `currentState` to match `defaultState`
4. User sees their preferred state
5. Changing `defaultState` in Settings doesn't affect current view

---

### 3. Custom State Selector in Settings

**SettingsView.swift:**
```swift
HStack(spacing: 12) {
    ForEach(WorkflowState.allCases, id: \.self) { state in
        Button(action: {
            appState.defaultState = state
        }) {
            VStack(spacing: 6) {
                Image(systemName: state.icon)
                    .font(.title2)
                Text(state.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                appState.defaultState == state
                    ? state.color.opacity(0.2)
                    : Color.secondary.opacity(0.1)
            )
            .foregroundColor(
                appState.defaultState == state
                    ? state.color
                    : .secondary
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        appState.defaultState == state
                            ? state.color
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
```

**Features:**
- ✅ Three clear, equal-sized buttons
- ✅ Icon + text for each state
- ✅ Color-coded backgrounds
- ✅ Border highlight for selected state
- ✅ All three states always visible
- ✅ Easy to click any state

---

## 🎨 Visual Comparison

### Before (Segmented Picker)
```
┌─────────────────────────────────────┐
│ [Sketches] [Active] [Archive]       │  ← Hard to see all options
└─────────────────────────────────────┘
```

### After (Custom Buttons)
```
┌─────────────────────────────────────────────────────┐
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ 💡       │  │ 🔥       │  │ 📦       │          │
│  │ Sketches │  │ Active   │  │ Archive  │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│     (orange)     (blue)        (gray)               │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Changes Summary

### Files Modified
1. **AppState.swift**
   - Added `defaultState` property
   - Removed `didSet` from `currentState`
   - Added `didSet` to `defaultState`
   - Updated `loadFolderPaths()` to load and apply default state
   - Updated `saveFolderPaths()` to remove manual state saving

2. **SettingsView.swift**
   - Replaced segmented picker with custom button selector
   - Changed binding from `$appState.currentState` to `$appState.defaultState`
   - Added visual feedback with colors and borders

---

## 🧪 Testing Checklist

- [x] App launches to Sketches by default (first time)
- [x] Change default state to Active in Settings
- [x] Current view doesn't change when selecting in Settings
- [x] Close and reopen app - should open to Active
- [x] All three states are visible and clickable in Settings
- [x] Selected state is clearly highlighted
- [x] No infinite loops or crashes

---

## 🎯 User Experience Improvements

### Before
- ❌ Changing default state changed current view (confusing)
- ❌ Archive state hard to select
- ❌ Unclear which state was selected
- ❌ Potential for didSet loops

### After
- ✅ Settings only affect next launch
- ✅ All three states clearly visible
- ✅ Selected state has color + border
- ✅ No loops or performance issues
- ✅ Intuitive and predictable behavior

---

**Status: All bugs fixed! 🎉**

