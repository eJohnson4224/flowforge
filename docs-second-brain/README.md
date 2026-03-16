# FlowForge Second Brain

## DOCUMENT_TYPE
`execution-system`

## AUTHORITY
Canonical execution workflow for active development.
This file defines how work is captured, triaged, and handed to AI once strategy is set in `docs/roadmap.md`.

## STATUS
`active`

## AI_CONTEXT_PRIORITY
`2`

## UPDATE_TRIGGER
Update when execution workflow, second-brain structure, or AI handoff rules change.

## RELATED_DOCUMENTS
- [../README.md](../README.md)
- [../docs/roadmap.md](../docs/roadmap.md)
- [now.md](now.md)
- [decisions.md](decisions.md)
- [file-management-workflow.md](file-management-workflow.md)
- [context-digitakt-object-model.md](context-digitakt-object-model.md)
- [../docs/active/test-sweep.md](../docs/active/test-sweep.md)

This folder is the operating system for product decisions, development flow, and AI collaboration.

## Why this exists

- Keep `docs/roadmap.md` as strategic truth.
- Keep this folder as execution truth.
- Reduce context switching while making music and building the app.

## System map

- `inbox.md`: raw capture for ideas, friction, and bugs.
- `now.md`: active queue, current sprint focus, and WIP limits.
- `questions.md`: inquiry prompts that guide product decisions.
- `experiments.md`: flow-state hypotheses and outcomes.
- `decisions.md`: durable decisions and tradeoffs (ADR-lite).
- `navigation-map.md`: explicit user journeys and navigation debt.
- `file-management-workflow.md`: reliability control doc for scan/move/conflict/recovery.
- `context-digitakt-object-model.md`: canonical Digitakt memory/object model for Elektron tooling.

## Operating loop

1. Capture fast in `inbox.md` while producing or coding.
2. Triage daily:
   - if executable now -> move to `now.md`
   - if needs discovery -> move to `questions.md`
   - if measurable bet -> move to `experiments.md`
   - if resolved direction -> log in `decisions.md`
3. Build from `now.md` only (protect focus).
4. At PR/commit gates, update `docs/roadmap.md` if strategy changed.
5. End of week: close or roll forward items in `now.md`.

## AI cooperation protocol

Before asking AI for implementation work, pass a compact context pack:

1. `README.md` (canonical router + load order)
2. `docs/roadmap.md` (strategic phase + acceptance criteria)
3. `docs-second-brain/now.md` (active priorities)
4. the relevant canonical reference doc if the task touches a specialized domain
5. 1-3 relevant source files (service/view/model)
6. `docs/active/test-sweep.md` if behavior changes

Prompt framing pattern:

- `Goal`: the user outcome in one sentence.
- `Constraint`: architecture invariant(s) to preserve.
- `Canonical docs`: which sources of truth govern this change.
- `Environment`: the environment assumptions to preserve.
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
