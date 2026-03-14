# Settings UI - Fixed Default State Selector

## 🎨 New Settings Panel Design

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
│  ┌─────────────┬─────────────┬─────────────┐               │
│  │             │             │             │               │
│  │     💡      │     🔥      │     📦      │               │
│  │             │             │             │               │
│  │  Sketches   │   Active    │   Archive   │               │
│  │             │             │             │               │
│  └─────────────┴─────────────┴─────────────┘               │
│   (selected)     (normal)      (normal)                    │
│   Orange bg      Gray bg       Gray bg                     │
│   Orange border  No border     No border                   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Rescan All Folders]                          [Done]      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 State Selector Features

### Visual States

**Unselected Button:**
```
┌─────────────┐
│             │
│     🔥      │  ← Icon (gray)
│             │
│   Active    │  ← Text (gray)
│             │
└─────────────┘
  Gray background (10% opacity)
  No border
```

**Selected Button:**
```
┌═════════════┐  ← Colored border (2px)
║             ║
║     🔥      ║  ← Icon (blue)
║             ║
║   Active    ║  ← Text (blue)
║             ║
└═════════════┘
  Blue background (20% opacity)
  Blue border
```

---

## 🎨 Color Coding

### Sketches (Selected)
- Background: Orange 20% opacity
- Border: Orange 2px
- Icon: Orange
- Text: Orange

### Active (Selected)
- Background: Blue 20% opacity
- Border: Blue 2px
- Icon: Blue
- Text: Blue

### Archive (Selected)
- Background: Gray 20% opacity
- Border: Gray 2px
- Icon: Gray
- Text: Gray

---

## 🔄 Interaction Flow

### Scenario 1: First Time User
1. Open Settings
2. See "Default State on Launch" section
3. Sketches is selected by default (orange)
4. Click "Active" button
5. Active button highlights (blue background + border)
6. Sketches button returns to gray
7. Close Settings
8. **Current view doesn't change** (still showing whatever was active)
9. Restart app
10. App opens to Active state ✅

---

### Scenario 2: Changing Preference
1. App is currently showing Archive
2. Open Settings
3. See that Active is selected (from previous choice)
4. Click "Sketches" button
5. Sketches highlights orange
6. Active returns to gray
7. Close Settings
8. **Still viewing Archive** (current view unchanged)
9. Restart app
10. App opens to Sketches ✅

---

## 💡 Key Improvements

### 1. Clear Visual Hierarchy
- **Three equal-sized buttons** - No confusion about options
- **Icons + text** - Easy to identify each state
- **Color coding** - Matches state colors from main UI
- **Border highlight** - Clear selection indicator

### 2. Predictable Behavior
- **Settings don't affect current view** - No jarring state changes
- **Only affects next launch** - Clear mental model
- **Immediate visual feedback** - See selection change instantly

### 3. Accessibility
- **Large click targets** - Easy to hit
- **High contrast** - Selected state is obvious
- **Consistent spacing** - Clean, organized layout

---

## 🧩 Implementation Details

### Button Structure
```swift
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
    .background(...)
    .foregroundColor(...)
    .cornerRadius(8)
    .overlay(...)
}
.buttonStyle(.plain)
```

### Dynamic Styling
- Background color changes based on selection
- Border appears only when selected
- Text and icon color match state color when selected
- Smooth transitions (implicit animations)

---

## 📐 Layout Specifications

### Button Dimensions
- **Width:** Equal thirds of container (with 12pt spacing)
- **Height:** Auto (based on content + 12pt vertical padding)
- **Corner Radius:** 8pt
- **Border Width:** 2pt (when selected)

### Spacing
- **Between buttons:** 12pt
- **Icon to text:** 6pt
- **Vertical padding:** 12pt
- **Section padding:** 16pt

### Typography
- **Icon:** .title2 (system font)
- **Text:** .caption (system font)

---

## 🎭 State Transitions

### On Click
1. User clicks button
2. `appState.defaultState = state` executes
3. `didSet` saves to UserDefaults
4. SwiftUI re-renders buttons
5. New button shows selected style
6. Old button returns to normal style
7. **Main UI remains unchanged**

### On App Launch
1. App initializes AppState
2. `loadFolderPaths()` called
3. Loads `defaultState` from UserDefaults
4. Sets `currentState = defaultState`
5. Main UI shows default state
6. Settings shows correct selection

---

## ✅ Testing Results

- ✅ All three states visible and clickable
- ✅ Selection highlights correctly
- ✅ Only one state selected at a time
- ✅ Changing selection doesn't affect main UI
- ✅ Preference persists across app restarts
- ✅ App launches to selected default state
- ✅ No performance issues or loops

---

**The Settings UI now provides a clear, intuitive way to set the default state without affecting the current view!**

