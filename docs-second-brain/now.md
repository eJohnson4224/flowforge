# Now: FlowForge Execution Queue

Last updated: 2026-03-07

## Current sprint outcomes

1. File movement feels trustworthy and predictable.
2. Sketches -> Samples workflow is faster to navigate.
3. Flow-state additions are tested with measurable criteria.
4. Elektron SKETCHS transfer is hardened and reliable in real-device use.

## WIP limits

- Max 2 active tasks total.
- Max 1 high-risk file-management task at a time.

## Priority queue

1. User-visible error system (Sketches + move operations)
   - Done when: scan/move failures are shown in UI with actionable text.
   - Test: trigger missing file + permission conflict; app stays stable and informative.
2. Conflict resolution on move (Rename / Replace / Skip)
   - Done when: duplicate filenames are handled without silent overwrite.
   - Test: same-name promote from Sketches -> Active across multiple formats.
3. Samples scan resilience (iCloud placeholders + missing refs)
   - Done when: scanner skips/flags unavailable files without blocking UI.
   - Test: mixed local/cloud project folder scan.
4. Navigation friction pass (Reveal in Finder + Open from every core card)
   - Done when: projects/samples/archive cards all expose quick-open affordances.
   - Test: keyboard + pointer path both work.
5. Waveform trim UI completion in Sample Detail + Random Sample
   - Done when: visible waveform/trim handles map to current trim export behavior.
   - Test: preview and export use same start/end points.
6. Digitakt transfer hardening sweep (`/samples/SKETCHS`)
   - Done when: duplicate, disconnect, wrong USB mode, long file, and oversized file paths are stable.
   - Test: execute transfer edge-case sweep from `docs/roadmap.md` + `docs/active/test-sweep.md`.

## Next up (not in current WIP)

- Search/filter in Samples list.
- Shortlist/starred samples.
- Archive preview association UX.

## Blockers / dependencies

- None logged yet.
