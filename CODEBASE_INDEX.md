# FlowForge Codebase Index

This is a quick navigation map for the repository.

## Top-level

- `flowforge/` — Xcode project source root
- `flowforge/flowforge.xcodeproj/` — Xcode project settings
- `Projects/` — user project assets (local workspace content)
- `misc/` — miscellaneous assets/notes
- `COMPLETED_ROADMAP/` — archived roadmap phases

## Core docs

- `README.md` — primary project overview
- `ROADMAP.md` — living product roadmap and phase planning
- `QUICKSTART.md` — setup/getting started steps
- `TROUBLESHOOTING.md` — known issues and fixes
- `XCODE_SETUP_CHECKLIST.md` — Xcode setup checklist
- `BUILD_STATUS.md` — current build notes

## Feature/implementation notes

- `IMPLEMENTATION_SUMMARY.md` — summary of current implementation state
- `UI_WALKTHROUGH.md` — UI flow walkthrough
- `NEW_UI_MOCKUP.md` — UI mockup notes
- `SKETCHES_IMPLEMENTATION.md` — Sketches state details
- `MACOS_NATIVE_IMPROVEMENTS.md` — macOS-focused enhancements
- `DIGITAKT_TRANSFER_IMPLEMENTATION.md` — Digitakt/Elektroid integration notes
- `BUGFIX_*.md`, `BUG_FIX_LOG.md`, `BUGFIX_SUMMARY.md` — bugfix notes and log

## App entry points

- `flowforge/flowforge/flowforgeApp.swift` — SwiftUI app entry
- `flowforge/flowforge/ContentView.swift` — root view + state routing

## Models

- `flowforge/flowforge/Models/AppState.swift` — global app state + persistence
- `flowforge/flowforge/Models/SampleFile.swift` — sample model
- `flowforge/flowforge/Models/ProjectMetadata.swift` — metadata model
- `flowforge/flowforge/Item.swift` — legacy/sample data model

## Services

- `flowforge/flowforge/Services/FolderManager.swift` — folder selection, scanning, moves
- `flowforge/flowforge/Services/SampleScanner.swift` — recursive WAV scan
- `flowforge/flowforge/Services/AbletonParser.swift` — Ableton `.als` parsing
- `flowforge/flowforge/Services/AudioPreviewManager.swift` — preview playback engine
- `flowforge/flowforge/Services/MetadataManager.swift` — metadata read/write
- `flowforge/flowforge/Services/ElektroidCLI.swift` — CLI wrapper for Digitakt transfer

## Views

- `flowforge/flowforge/Views/SamplesListView.swift` — Samples list UI
- `flowforge/flowforge/Views/SampleDetailView.swift` — sample detail UI
- `flowforge/flowforge/Views/RandomSampleView.swift` — random sample selector UI
- `flowforge/flowforge/Views/SettingsView.swift` — settings UI

## Assets

- `flowforge/flowforge/Assets.xcassets/` — app icons and colors

## Notes

- Source code is currently under `flowforge/flowforge/`.
- The file system is the primary data source; metadata lives under the user’s Application Support at runtime.
