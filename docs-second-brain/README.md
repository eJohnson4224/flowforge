# FlowForge Second Brain

This folder is the operating system for product decisions, development flow, and AI collaboration.

## Why this exists

- Keep `docs/roadmap.md` as strategic truth.
- Keep this folder as execution truth.
- Reduce context switching while making music and building the app.

## System map

- `inbox.md`: raw capture for ideas, friction, and bugs.
- `now.md`: active queue, current sprint focus, and WIP limits.
- `questions.md`: inquiry prompts that guide product decisions.
- `docs-second-brain/experiments.md`: flow-state hypotheses and outcomes.
- `decisions.md`: durable decisions and tradeoffs (ADR-lite).
- `docs-second-brain/navigation-map.md`: explicit user journeys and navigation debt.
- `docs-second-brain/file-management-workflow.md`: reliability control doc for scan/move/conflict/recovery.
- `context-digitakt-object-model.md`: canonical Digitakt memory/object model for Elektron tooling.

## Operating loop

1. Capture fast in `inbox.md` while producing or coding.
2. Triage daily:
   - if executable now -> move to `now.md`
   - if needs discovery -> move to `questions.md`
   - if measurable bet -> move to `docs-second-brain/experiments.md`
   - if resolved direction -> log in `decisions.md`
3. Build from `now.md` only (protect focus).
4. At PR/commit gates, update `docs/roadmap.md` if strategy changed.
5. End of week: close or roll forward items in `now.md`.

## AI cooperation protocol

Before asking AI for implementation work, pass a compact context pack:

1. `docs/roadmap.md` (strategic phase + acceptance criteria)
2. `docs-second-brain/now.md` (active priorities)
3. 1-3 relevant source files (service/view/model)
4. `docs/active/test-sweep.md` if behavior changes

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
