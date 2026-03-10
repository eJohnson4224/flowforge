# Experiments (Flow-State Additions)

Run one experiment at a time unless dependencies are independent.

## Experiment template

- ID:
- Hypothesis:
- Slice to build:
- Success metric:
- Observation window:
- Outcome: (Pass / Fail / Mixed)
- Decision:

## Active experiment candidates

1. ID: `EXP-001-spacebar-preview`
   - Hypothesis: Keyboard play/pause reduces sample browse friction by at least 25%.
   - Slice to build: global spacebar handling in Samples list + Random Sample view.
   - Success metric: average actions-to-preview drops in manual walkthrough.
   - Observation window: 3 sessions.
2. ID: `EXP-002-flow-warm-start`
   - Hypothesis: A 10-minute guided "Flow mode" increases useful sample saves per session.
   - Slice to build: timed random sample loop with keep/skip shortcuts.
   - Success metric: count of samples marked for reuse per session.
   - Observation window: 5 sessions.
3. ID: `EXP-003-navigation-unification`
   - Hypothesis: Universal `Reveal` + `Open` actions cut navigation dead-ends.
   - Slice to build: add actions to all project/sample/archive cards.
   - Success metric: fewer context switches to Finder setup/manual browsing.
   - Observation window: 1 sprint.
4. ID: `EXP-004-resurface-cadence`
   - Hypothesis: Weekly resurfacing from Archive increases project revival rate.
   - Slice to build: "Resurface 1 project" prompt from Archive.
   - Success metric: restored-to-active count per week.
   - Observation window: 4 weeks.
