# File Management Workflow (Control Doc)

This document governs how FlowForge scans, classifies, moves, and verifies files.

## Objective

Make every file transition reliable, explainable, and reversible where possible.

## Canonical transitions

1. `Sketches -> Active` (Promote)
2. `Active -> Archive` (Archive)
3. `Archive -> Active` (Restore with slot guardrail)

## Workflow stages

1. Discover
   - Read configured folder URLs.
   - Validate access and existence.
2. Classify
   - Determine project vs sample behavior.
   - Resolve supported formats and scan filters.
3. Act
   - Execute move/copy operation.
   - Resolve conflicts (Rename / Replace / Skip).
4. Verify
   - Confirm destination placement.
   - Refresh source/destination state in UI.
5. Recover
   - Surface actionable errors.
   - Offer retry/reveal/fix-permissions paths.

## Definition of reliable behavior

- No silent failures.
- No ambiguous success states.
- No hidden destructive overwrite.
- User can always see what happened and what to do next.

## Current development queue

1. Unified error presentation for scan and move operations.
2. Conflict resolution dialog + deterministic rename strategy.
3. iCloud placeholder and missing-file resilience.
4. Post-move refresh consistency across all three states.
5. Recovery action hooks (`Retry`, `Reveal`, `Open Settings`).

## Verification checklist (per change)

1. Move a normal file between all three states.
2. Move with duplicate destination filename.
3. Trigger permission/access error and verify UI guidance.
4. Trigger missing file during scan and verify non-blocking behavior.
5. Confirm state lists refresh correctly after each outcome.

## Metrics to track

- Failed move rate per session.
- Time from action to visible confirmation.
- Number of console-only errors (target: zero).
- Manual Finder detours per workflow.
