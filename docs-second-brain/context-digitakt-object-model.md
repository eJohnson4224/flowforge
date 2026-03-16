# ELEKTRON DIGITAKT — CODEX-OPTIMIZED MEMORY / OBJECT MODEL

## DOCUMENT_TYPE
`domain-reference`

## AUTHORITY
Canonical conceptual model for Digitakt storage, pool, browser, and sound/sample relationships used in FlowForge reasoning.
This is a product/domain reference, not a roadmap or execution queue.

## STATUS
`active-reference`

## AI_CONTEXT_PRIORITY
`5 when Digitakt transfer or object-model reasoning is in scope`

## UPDATE_TRIGGER
Update when product assumptions about Digitakt object relationships or transfer reasoning change.

## RELATED_DOCUMENTS
- [../README.md](../README.md)
- [../docs/roadmap.md](../docs/roadmap.md)
- [README.md](README.md)
- [now.md](now.md)
- [../docs/active/test-sweep.md](../docs/active/test-sweep.md)

## PURPOSE

Represent the Digitakt as a structured system:

- persistent storage
- project-scoped memory
- track state
- sound preset logic
- browser/navigation relationships

This model is conceptual, not official firmware internals.
It is intended for reasoning about:

- sample loading
- sound browsing
- pool relationships
- track assignment
- CLI or automation workflows

## 1. TOP-LEVEL SYSTEM MODEL

```text
Digitakt
├── Global Persistent Storage
│   ├── +Drive Samples
│   └── +Drive Sounds
│
├── Project
│   ├── Audio Pool
│   ├── Project Sound Pool
│   ├── Tracks[1..8]
│   ├── Patterns
│   ├── Sample Browser View
│   └── Sound Browser View
│
└── Runtime Actions
    ├── Load Sample
    ├── Load Sound
    ├── Save Track as Sound
    ├── Assign Sample to Track
    └── Reference Sample from Pool
```

## 2. STORAGE LAYERS

There are two main storage scopes:

### A. GLOBAL / PERSISTENT

- survives across projects
- stored on +Drive
- browsable from project context

### B. PROJECT / WORKING SET

- active only inside current project
- contains the samples and sounds currently available to that project
- tracks primarily work from this layer

## 3. GLOBAL PERSISTENT STORAGE

```text
GlobalPersistentStorage
├── PlusDriveSampleLibrary
│   ├── Folder*
│   │   ├── SampleFile.wav
│   │   ├── SampleFile.aif
│   │   └── ...
│   └── ...
│
└── PlusDriveSoundLibrary
    ├── FactorySoundPreset*
    ├── UserSoundPreset*
    └── ...
```

Definitions:

### SampleFile

- raw audio file
- no track settings by itself
- may exist in folder hierarchy
- source material for project use

### SoundPreset

- saved sound object
- contains parameter state
- typically includes a reference to a sample
- may point to a sample that must be available to the project

## 4. PROJECT MODEL

```text
Project
├── AudioPool
├── ProjectSoundPool
├── Tracks[1..8]
├── Sequences/Patterns
└── UI Browsers
    ├── SampleBrowser
    └── SoundBrowser
```

## 5. AUDIO POOL

```text
AudioPool
├── SampleSlot[1..N]
└── metadata for loaded project samples

SampleSlot
├── slotIndex
├── sourceFileReference
├── fileName
├── projectAvailability = true
└── audioDataReference
```

Meaning:

- the Audio Pool is the project's active sample set
- tracks do not conceptually browse the whole +Drive directly during normal assignment logic
- they reference samples that are loaded into the project pool

Practical mental model:

- +Drive Samples = disk
- Audio Pool = project RAM / working set

## 6. PROJECT SOUND POOL

```text
ProjectSoundPool
├── SoundEntry[1..128 approx conceptual]
└── sound objects saved inside current project

ProjectSoundEntry
├── name
├── linkedSampleReference
├── srcSettings
├── filterSettings
├── ampSettings
├── lfoSettings
├── fxSendSettings
└── otherTrackParameterState
```

Meaning:

- these are sounds saved into the project
- usable for recall and sound locking
- distinct from raw samples
- project-local, unlike +Drive sounds

## 7. TRACK MODEL

```text
Tracks[1..8]
├── Track1
├── Track2
├── ...
└── Track8

Track
├── assignedSampleSlot
├── trackSoundState
├── sequencerData
└── performance/playback state

TrackSoundState
├── sampleReference
├── SRC page settings
├── filter settings
├── amp settings
├── LFO settings
├── FX send settings
└── other synthesis/playback modifiers
```

Important distinction:

- `Track.assignedSampleSlot` = reference to project-loaded sample
- `Track.trackSoundState` = full playable configuration for that track

In shorthand:

- `TrackSoundState = SampleReference + ParameterState`

## 8. SAMPLE VS SOUND

### Sample

- raw audio asset
- no complete preset behavior by itself
- loaded through Sample Browser
- stored globally on +Drive, then loaded into project Audio Pool

### Sound

- preset object
- includes sample reference + playback/shaping parameters
- loaded through Sound Browser
- can exist globally (+Drive Sound Library) or locally (Project Sound Pool)

Canonical rule:

- `Sample != Sound`

More explicitly:

- `Sample = audio file`
- `Sound = audio file reference + machine parameter state`

## 9. BROWSER MODEL

```text
SampleBrowser
├── AudioPool view
└── +Drive Sample Library view

SoundBrowser
├── +Drive Sounds view
├── Project Sounds view
└── possibly current track-derived sound context
```

Interpretation:

- Sample Browser is for choosing raw source audio
- Sound Browser is for choosing presetized playable states

## 10. SAMPLE BROWSER LOGIC

SampleBrowser data sources:

```text
SampleBrowser
├── Project.AudioPool
│   └── already-loaded samples
└── GlobalPersistentStorage.PlusDriveSampleLibrary
    └── all available stored sample files
```

User intent in Sample Browser:

- browse raw sample files
- preview/select sample
- load sample into project context
- assign sample to track

Conceptual operation:

```text
function loadSampleToTrack(sampleFile, targetTrack):
    if sampleFile not in Project.AudioPool:
        create SampleSlot in Project.AudioPool
    targetTrack.assignedSampleSlot = matching SampleSlot
    targetTrack.trackSoundState.sampleReference = matching SampleSlot
```

Important:

- Loading a sample does NOT necessarily create a reusable saved Sound object.

## 11. SOUND BROWSER LOGIC

SoundBrowser data sources:

```text
SoundBrowser
├── GlobalPersistentStorage.PlusDriveSoundLibrary
└── Project.ProjectSoundPool
```

User intent in Sound Browser:

- browse saved sounds/presets
- load full track-ready sound states
- recall parameterized sounds, not just raw files

Conceptual operation:

```text
function loadSoundToTrack(soundPreset, targetTrack):
    ensure linked sample is available in Project.AudioPool
    targetTrack.trackSoundState = soundPreset.parameterState
    targetTrack.assignedSampleSlot = resolved linked sample slot
```

Important:

- Loading a sound affects more than sample choice.
- It applies a whole parameter configuration.

## 12. RESOLUTION RULES

When a Sound is loaded:

1. identify linked sample reference
2. resolve whether that sample exists in project Audio Pool
3. if absent, load/import it into Audio Pool
4. apply all saved sound parameters to target track
5. track now plays using both:
   - resolved sample slot
   - loaded parameter state

When a Sample is loaded:

1. identify raw sample file
2. load/import into Audio Pool if absent
3. assign sample slot to target track
4. preserve or partially preserve existing track parameters unless explicitly overwritten

This is the most useful conceptual difference for tooling.

## 13. FILESYSTEM ANALOGY

Use this analogy for automation tooling:

- +Drive Samples = disk folder of raw assets
- +Drive Sounds = disk folder of presets
- Audio Pool = project RAM cache / active asset table
- Project Sound Pool = project-local preset bank
- Track = playback instance / object
- Track Sound State = current instantiated preset on a track

Compact analogy:

- `Disk Asset -> Loaded Asset -> Assigned Playback Object`

Which expands to:

- `Sample File -> Audio Pool Slot -> Track Sample Reference`

and:

- `Sound Preset -> Track Sound State -> Playback Result`

## 14. OBJECT MODEL

```python
class Digitakt:
    global_storage: GlobalStorage
    current_project: Project

class GlobalStorage:
    plus_drive_samples: list[SampleFile]
    plus_drive_sounds: list[SoundPreset]

class Project:
    audio_pool: list[SampleSlot]
    sound_pool: list[ProjectSound]
    tracks: list[Track]
    patterns: list[Pattern]

class SampleFile:
    path: str
    name: str
    format: str

class SampleSlot:
    slot_id: int
    source_sample_file: SampleFile

class SoundPreset:
    name: str
    linked_sample: SampleFile | SampleSlot | None
    parameter_state: ParameterState

class ProjectSound(SoundPreset):
    project_local: bool = True

class Track:
    track_id: int
    assigned_sample_slot: SampleSlot | None
    sound_state: ParameterState
    sequencer_data: object

class ParameterState:
    src: object
    filter: object
    amp: object
    lfo: object
    fx: object
```

## 15. NAVIGATION TREE FOR PROMPTING / REASONING

```text
Digitakt
├── +Drive
│   ├── Samples
│   │   ├── folder/*
│   │   └── raw sample files
│   └── Sounds
│       ├── factory sounds
│       └── user sounds
│
└── Current Project
    ├── Audio Pool
    │   └── active sample slots used by project
    │
    ├── Project Sound Pool
    │   └── project-local saved sounds
    │
    ├── Tracks
    │   ├── Track 1
    │   │   ├── assigned sample slot
    │   │   └── track sound state
    │   ├── Track 2
    │   └── ...
    │
    ├── Sample Browser
    │   ├── Audio Pool view
    │   └── +Drive Samples view
    │
    └── Sound Browser
        ├── +Drive Sounds view
        └── Project Sounds view
```

## 16. CLI/AUTOMATION-SAFE RULES

Rule 1:
A sample transfer operation targets sample storage / project pool logic, not the Sound Browser directly.

Rule 2:
A sound browsing operation does not mean browsing raw samples; it means browsing preset objects.

Rule 3:
If a track can play a sample, that sample must be conceptually available in the project working set.

Rule 4:
Saving a track as a sound creates a reusable preset object derived from current track state.

Rule 5:
Changing sample assignment and changing sound assignment are different classes of operation:

- sample assignment changes raw source audio
- sound assignment changes preset state, usually including sample linkage

## 17. SHORTEST HIGH-VALUE SUMMARY

Digitakt mental model:

1. +Drive stores raw samples and saved sounds.
2. Project Audio Pool holds the samples currently loaded for the project.
3. Each track plays one assigned sample slot plus its own parameter state.
4. Sample Browser browses raw audio sources.
5. Sound Browser browses saved preset objects.
6. A Sound is not a Sample; a Sound is a `SampleReference + TrackParameters`.

## 18. ONE-LINE MODEL

`Digitakt = (+Drive assets) -> (project pool) -> (track assignment) -> (sound state) -> playback`
