# Proof Test Sweep (P0 + Edge Cases)

## When to run

- After significant code changes that would justify a git commit
- Required before marking Phase S complete or entering Phase R

## Required setup

- Digitakt connected via USB, USB config set to Audio/MIDI
- FlowForge built with bundled `elektroid-cli`

## P0 tests (commit gate)

1. Transfer short sample (<10s)
   - Use Sample Detail or Random Sample transfer.
   - Expect: "Transfer Complete" and the file appears in `/samples/SKETCHS`.
   - Optional CLI confirm: `elektroid-cli elektron:sample:ls 1:/samples/SKETCHS`
2. Duplicate file handling
   - Transfer the same file again.
   - Expect: "File Already Exists" prompt.
   - Choose Overwrite: app skips upload, keeps existing file, and shows the confirmation.
3. Long sample handling (>30s)
   - Select a sample longer than 30s and observe the preflight warning.
   - Attempt transfer: expect a "Sample Too Long" alert and no upload.
   - Set trim endpoints to <= 30s, then transfer.
   - Expect: transfer completes and file appears in `/samples/SKETCHS`.
4. Device disconnected
   - Unplug Digitakt and attempt a transfer.
   - Expect: clean "not connected" / routing error message and no crash.

## Edge-case sweep (run before big commits)

5. Oversized file (>64MB)
   - Use a large WAV over 64MB.
   - Expect: warning shown; transfer fails gracefully or is canceled intentionally.
6. Wrong USB mode
   - Set Digitakt USB mode to Overbridge (or non Audio/MIDI).
   - Expect: routing issue message; no crash.
7. Folder recreation
   - Delete `/samples/SKETCHS` on the Digitakt.
   - Transfer a sample and confirm the folder is recreated automatically.
8. Filename edge case
   - Transfer a WAV with spaces and uppercase in the name.
   - Expect: upload succeeds and verify finds it in `/samples/SKETCHS`.
9. Reconnect flow
   - Unplug, then replug the Digitakt (no app restart).
   - Transfer succeeds after reconnect.

## Pass criteria

- P0 tests pass in one run
- Edge-case sweep passes before large commits
- No crashes or UI hangs
- RtAudio warnings in stderr are acceptable if exit code is 0

## Run log

| Date | Build/Commit | Result | Notes |
| ---- | ------------ | ------ | ----- |
| YYYY-MM-DD | (hash or branch) | Pass/Fail | |
