# Proof Test Sweep (P0)

## When to run

- After significant code changes that would justify a git commit
- Required before marking Phase S complete or entering Phase R

## Required setup

- Digitakt connected via USB, USB config set to Audio/MIDI
- FlowForge built with bundled `elektroid-cli`

## Tests

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
   - Set trim endpoints to <= 30s, then transfer.
   - Expect: transfer completes and file appears in `/samples/SKETCHS`.
4. Device disconnected
   - Unplug Digitakt and attempt a transfer.
   - Expect: clean "not connected" / routing error message and no crash.

## Pass criteria

- All four tests pass in one run
- No crashes or UI hangs
- RtAudio warnings in stderr are acceptable if exit code is 0

## Run log

| Date | Build/Commit | Result | Notes |
| ---- | ------------ | ------ | ----- |
| YYYY-MM-DD | (hash or branch) | Pass/Fail | |
