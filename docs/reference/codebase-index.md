# FlowForge Codebase Index

This is a quick navigation map for the repository.

## Top-level

- `FlowForge/` — Xcode project source root
- `FlowForge.xcodeproj/` — Xcode project settings
- `Projects/` — user project assets (local workspace content)
- `docs-second-brain/` — development operating system + AI context resources
- `misc/` — miscellaneous assets/notes
- `docs/archive/` — archived roadmap phases

## Core docs

- `README.md` — primary project overview
- `docs/roadmap.md` — living product roadmap and phase planning
- `docs-second-brain/README.md` — second-brain operating framework
- `docs-second-brain/context-digitakt-object-model.md` — Digitakt conceptual memory/object model
- `quickstart.md` — setup/getting started steps
- `troubleshooting.md` — known issues and fixes
- `xcode-setup-checklist.md` — Xcode setup checklist
- `build-status.md` — current build notes

## Feature/implementation notes

- `implementation-summary.md` — summary of current implementation state
- `ui-walkthrough.md` — UI flow walkthrough
- `new-ui-mockup.md` — UI mockup notes
- `sketches-implementation.md` — Sketches state details
- `macos-native-improvements.md` — macOS-focused enhancements
- `digitakt-transfer-implementation.md` — Digitakt/Elektroid integration notes
- `bugfix-*.md`, `bug-fix-log.md` — bugfix notes and log

## App entry points

- `FlowForge/FlowForgeApp.swift` — SwiftUI app entry
- `FlowForge/ContentView.swift` — root view + state routing

## Models

- `FlowForge/Models/AppState.swift` — global app state + persistence
- `FlowForge/Models/SampleFile.swift` — sample model
- `FlowForge/Models/ProjectMetadata.swift` — metadata model

## Services

- `FlowForge/Services/FolderManager.swift` — folder selection, scanning, moves
- `FlowForge/Services/SampleScanner.swift` — recursive WAV scan
- `FlowForge/Services/AbletonParser.swift` — Ableton `.als` parsing
- `FlowForge/Services/AudioPreviewManager.swift` — preview playback engine
- `FlowForge/Services/MetadataManager.swift` — metadata read/write
- `FlowForge/Services/ElektroidCLI.swift` — CLI wrapper for Digitakt transfer

## Views

- `FlowForge/Views/SamplesListView.swift` — Samples list UI
- `FlowForge/Views/SampleDetailView.swift` — sample detail UI
- `FlowForge/Views/RandomSampleView.swift` — random sample selector UI
- `FlowForge/Views/SettingsView.swift` — settings UI

## Assets

- `FlowForge/Assets.xcassets/` — app icons and colors

## Notes

- Source code is currently under `FlowForge/`.
- The file system is the primary data source; metadata lives under the user’s Application Support at runtime.
