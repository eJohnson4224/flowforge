# FlowForge Second Brain

This folder is the operating system for product decisions, development flow, and AI collaboration.

## Why this exists

- Keep `ROADMAP.md` as strategic truth.
- Keep this folder as execution truth.
- Reduce context switching while making music and building the app.

## System map

- `INBOX.md`: raw capture for ideas, friction, and bugs.
- `NOW.md`: active queue, current sprint focus, and WIP limits.
- `QUESTIONS.md`: inquiry prompts that guide product decisions.
- `EXPERIMENTS.md`: flow-state hypotheses and outcomes.
- `DECISIONS.md`: durable decisions and tradeoffs (ADR-lite).
- `NAVIGATION_MAP.md`: explicit user journeys and navigation debt.
- `FILE_MANAGEMENT_WORKFLOW.md`: reliability control doc for scan/move/conflict/recovery.
- `CONTEXT_DIGITAKT_OBJECT_MODEL.md`: canonical Digitakt memory/object model for Elektron tooling.

## Operating loop

1. Capture fast in `INBOX.md` while producing or coding.
2. Triage daily:
   - if executable now -> move to `NOW.md`
   - if needs discovery -> move to `QUESTIONS.md`
   - if measurable bet -> move to `EXPERIMENTS.md`
   - if resolved direction -> log in `DECISIONS.md`
3. Build from `NOW.md` only (protect focus).
4. At PR/commit gates, update `ROADMAP.md` if strategy changed.
5. End of week: close or roll forward items in `NOW.md`.

## AI cooperation protocol

Before asking AI for implementation work, pass a compact context pack:

1. `ROADMAP.md` (strategic phase + acceptance criteria)
2. `SECOND_BRAIN/NOW.md` (active priorities)
3. 1-3 relevant source files (service/view/model)
4. `TEST_SWEEP.md` if behavior changes

Prompt framing pattern:

- `Goal`: the user outcome in one sentence.
- `Constraint`: architecture invariant(s) to preserve.
- `Done`: concrete acceptance checks.

## File-management focus lane

Treat file-management reliability as the primary lane until stable:

1. scan reliability
2. conflict resolution
3. move correctness + refresh correctness
4. user-visible failures
5. recovery paths (missing files, permissions, iCloud placeholders)

## Flow-state focus lane

Use small measurable bets:

- one friction point per sprint
- one navigation improvement per sprint
- one experiment per sprint with a pass/fail metric
