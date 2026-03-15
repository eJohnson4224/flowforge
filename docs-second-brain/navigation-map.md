# Navigation Map (Workflow Clarity)

This file tracks the intended click/keyboard paths through FlowForge.

## Core state transitions

1. `Sketches -> Active` (Promote)
2. `Active -> Archive` (Archive)
3. `Archive -> Active` (Restore, slot-checked)

Each transition must show:

- current state
- target state
- success confirmation
- visible failure message with next action

## Primary user journeys

1. Sample discovery loop
   - Open Sketches
   - Toggle to Samples
   - Preview
   - Keep/shortlist or skip
   - Optional transfer/export
2. Project focus loop
   - Open Active
   - Choose one project
   - Open/reveal files
   - Add session note/next action
   - Archive when stalled
3. Resurface loop
   - Open Archive
   - Preview attached output
   - Restore if momentum exists

## Navigation quality checklist

- Core actions are visible without deep menus.
- The same action is placed consistently across states.
- Empty states explain what to do next.
- Keyboard path exists for preview and selection.
- "Reveal in Finder" and "Open" are easy to find everywhere.

## Known navigation debt

1. Inconsistent quick actions across cards.
2. Samples and projects have different affordance patterns.
3. Error-to-recovery path is not consistently shown in UI.
4. Flow mode path is not yet defined as a first-class journey.
