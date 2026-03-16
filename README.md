# FlowForge

## DOCUMENT_TYPE
`router`

## AUTHORITY
Entry-point only. This file defines canonical document routing and AI load order.
It is not the source of truth for product scope, execution priorities, or verification procedure.

## STATUS
`active`

## AI_CONTEXT_PRIORITY
`0`

## UPDATE_TRIGGER
Update when canonical docs move, change authority, or the repository documentation topology changes.

## CANONICAL_DOCUMENTS

1. [docs/roadmap.md](docs/roadmap.md)
   - `type:` `strategic-roadmap`
   - `authority:` Canonical strategic truth for product direction, phase ordering, architecture invariants, and documentation topology.
2. [docs-second-brain/README.md](docs-second-brain/README.md)
   - `type:` `execution-system`
   - `authority:` Canonical execution workflow for how work is captured, triaged, and handed to AI.
3. [docs-second-brain/now.md](docs-second-brain/now.md)
   - `type:` `active-queue`
   - `authority:` Canonical day-to-day priorities, WIP limits, and current sprint focus.
4. [docs-second-brain/decisions.md](docs-second-brain/decisions.md)
   - `type:` `decision-log`
   - `authority:` Canonical durable decisions record until explicitly superseded.
5. [docs-second-brain/file-management-workflow.md](docs-second-brain/file-management-workflow.md)
   - `type:` `control-reference`
   - `authority:` Canonical file-management reliability rules for scan, move, conflict, and recovery behavior.
6. [docs-second-brain/context-digitakt-object-model.md](docs-second-brain/context-digitakt-object-model.md)
   - `type:` `domain-reference`
   - `authority:` Canonical Digitakt memory and object-model reference when hardware-transfer reasoning is in scope.
7. [docs/active/test-sweep.md](docs/active/test-sweep.md)
   - `type:` `verification-gate`
   - `authority:` Canonical manual proof sweep for behavior-changing work and commit-gate validation.

## PROJECT_SUMMARY

FlowForge is a macOS-native SwiftUI app for managing music-making work across three folder-backed states:

- `Sketches`: capture and explore raw ideas
- `Active`: focus execution with a hard cap of `5`
- `Archive`: retain completed or paused work for intentional resurfacing

The file system is the source of truth. Optional sample-preview, metadata, and Digitakt-transfer tooling sit on top of that core workflow.

## AI_CONTEXT_PACK

For implementation work, load documents in this order:

1. `README.md`
2. `docs/roadmap.md`
3. `docs-second-brain/README.md`
4. `docs-second-brain/now.md`
5. the relevant canonical reference doc
6. `docs/active/test-sweep.md` when behavior changes
7. the source files being edited

## HISTORICAL_CONTEXT

- `docs/archive/` is archive-only context.
- `docs/reference/` is durable supporting reference, not strategic or execution authority unless a canonical doc explicitly points to it.
- Do not treat archived phase docs as authority for current behavior unless a current canonical doc explicitly points back to them.
