# Decisions (ADR-lite)

Record durable choices so future AI sessions do not re-open settled fundamentals.

## Template

- ID:
- Date:
- Decision:
- Context:
- Alternatives considered:
- Consequences:
- Follow-up:

## DEC-001

- Date: 2026-03-07
- Decision: File system remains source of truth; no hidden database required for core workflow.
- Context: FlowForge depends on user-owned folders and transparent file behavior.
- Alternatives considered: full DB-backed state tracking.
- Consequences: move/scan correctness and conflict handling become first-class engineering priorities.
- Follow-up: strengthen conflict resolution and scan error visibility.

## DEC-002

- Date: 2026-03-07
- Decision: Active projects remain capped at 5.
- Context: Product intent is deliberate focus with constrained active load.
- Alternatives considered: soft cap or auto-expanding slots.
- Consequences: restore/promote flows must enforce slot checks clearly.
- Follow-up: improve prompts and swap/archive ergonomics when full.

## DEC-003

- Date: 2026-03-07
- Decision: Hardware transfer remains optional and non-blocking for Sketches core UX.
- Context: Digitakt integration adds value but introduces external dependency risk.
- Alternatives considered: making hardware workflow a central requirement.
- Consequences: transfer failures should never block core browsing, preview, tagging, or moves.
- Follow-up: isolate transfer failures behind explicit UI messaging.

## DEC-004

- Date: 2026-03-07
- Decision: Current phase targets stable sample transfer to `/samples/SKETCHS`, not automatic sample-to-sound conversion.
- Context: Immediate product need is dependable transfer workflow during Sketches sessions.
- Alternatives considered: prioritize generated Sound objects and Sound Browser flow in this phase.
- Consequences: transfer UX/tests focus on reliability, recovery, and edge-case handling.
- Follow-up: keep sound-object exploration as optional future work only if it does not slow transfer hardening.
