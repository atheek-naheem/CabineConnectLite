---
name: design
description: Turn the agreed requirements into a technical design and a task breakdown the team chose, with every decision and task traced to requirement IDs. Run after the requirements-elaboration gate passes, or again when the design changes.
disable-model-invocation: true
metadata:
  version: "1.0.0"
---

# Design stage

## Purpose

Decide how to build the solution and break the work into small tasks that trace
back to requirement IDs. The engineers own every technology decision and the
product owner owns every business interpretation. Your job is to lay out options
with their trade-offs and record what the team chose, not to choose for them.

This stage designs the solution. It never changes what the solution must do.

## Inputs

- `docs/requirements/REQUIREMENTS.md`: the agreed specification. The source of truth for behaviour.
- `docs/input/*.md`: the business input, for context. **Read-only. Never modify these files.**
- `docs/design/DESIGN.md`: the design to write or update.
- `CLAUDE.md`: standing rules. They take precedence over this skill.

## Steps

1. **Pulse started.** Run this first, before any other work:
   - macOS / Linux / Git Bash: `tools/pulse.sh design started`
   - Windows: `powershell -ExecutionPolicy Bypass -File tools\pulse.ps1 design started`

   If the pulse prints a warning, tell the team and carry on. Pulses never block the work.

2. **Check for an existing design.** If `DESIGN.md` already contains content, this
   is a new iteration: **update** it, do not rewrite it. Keep all existing IDs and
   the team's manual edits. New items get new IDs. Never reuse an ID. On an update,
   show the team a short summary of what changed and why.

3. **Read the requirements in full.** List every `REQ-`, `NFR-` and `BR-` ID you
   must satisfy. Check the Assumptions and Open questions sections:
   - Record every `Q-` item still open as a design risk (`R-001`, ...) naming the
     interim assumption the design relies on and what would change if the answer differs.
   - Never answer a business question yourself. If the design needs one answered,
     stop and ask the **product owner**. Their answer belongs in `REQUIREMENTS.md`
     via the `requirements-elaboration` skill, not in the design document.
   - If a requirement turns out to be impossible or contradictory, say so and ask
     the team. Do not quietly design something different.

4. **Take the technology decisions with the engineers.** For each one — language
   and runtime, persistence, interface, test framework, and anything else the
   design needs — present **two or three options with their trade-offs** against
   the requirements and the 3-hour timebox, then wait. The **engineers choose**.
   Record each as `D-001`, ... with the options considered, the choice, who decided,
   and why.

   If a choice changes observable behaviour rather than construction — what a user
   sees or what a rule means — it is a business decision. Ask the **product owner**
   and record it in `REQUIREMENTS.md`, not here.

5. **Design the solution.** Keep it lean and specific. Cite the requirement IDs
   each part serves:
   - **Architecture:** the components, what each is responsible for, how they fit together.
   - **Data model:** entities, their fields and relationships, including booking state and the state-change history.
   - **Booking state machine:** every state, every transition, who may trigger it, and which dates it frees.
   - **Role enforcement:** how each action is authorised by role and ownership in the application's own logic, not only in the interface.
   - **Persistence and seed data:** how data survives a restart and how the seeded users exist on first start.
   - **Test strategy:** what is covered by automated tests, at which level, and how the acceptance criteria will be verified.

   Design only what the requirements ask for. If you find yourself designing a
   feature with no requirement ID, stop and ask the team.

6. **Break the work into tasks.** Each task (`T-001`, ...) is small enough to
   finish and verify on its own, names the requirement IDs it serves and the
   acceptance criteria it satisfies, and has a clear done condition. Order them so
   something runs end to end early. Every `REQ-` and `NFR-` must be covered by at
   least one task; include a traceability table showing where each is covered.

7. **Write the document.** Fill in or update `docs/design/DESIGN.md` with these headings:
   Decisions (`D-`), Architecture, Data model, Booking state machine, Role
   enforcement, Persistence and seed data, Test strategy, Tasks (`T-`),
   Requirement traceability, Design risks (`R-`), Gate checklist.

   Do not restate the requirements. Reference them by ID.

8. **Review.** Check the document yourself and report what you find:
   - every `REQ-`, `NFR-` and `BR-` is covered by a design element and by at least one task
   - every decision records its options, the choice, who decided, and why
   - no requirement was invented, changed, or silently dropped
   - no open business question was answered in this stage
   - IDs are unique and consistent, and no existing ID was reused
   - tasks are small, ordered, and independently verifiable

   If the team edited the document by hand, re-read it and check it for consistency
   before continuing.

   Then walk the team through the **Gate checklist** item by item. **The team
   decides** whether the gate passed or failed. Record the result, who confirmed it,
   and the completion timestamp in the document.

9. **Remind the team** that before development starts they must write their
   `development`, `review`, `quality`, and `handoff` skills using
   `docs/process/SKILL-GUIDE.md` and `docs/process/SKILL-TEMPLATE.md`, with
   `requirements-elaboration` and this skill as the reference examples.

10. **Commit.** Commit the document and `pulses.log`, referencing requirement IDs
    where the commit serves them (e.g. `docs(design): design REQ-001..REQ-017`).

11. **Pulse completed.** Count from the committed document, never estimate:
    - `decisions` = number of `D-` items
    - `tasks` = number of `T-` items

    ```text
    tools/pulse.sh design completed --gate <passed|failed> --count decisions=N --count tasks=N
    ```

    On Windows: `powershell -ExecutionPolicy Bypass -File tools\pulse.ps1` with the
    same arguments. Report the gate honestly. A failed gate is valid information,
    not a problem to hide.

## Output

- `docs/design/DESIGN.md`, written or updated, and committed.
- Two pulses in `pulses.log` (started, completed).

## Gate checklist

The team confirms each item:

- [ ] Every `REQ-` and `NFR-` in the specification is covered by a design element and by at least one task.
- [ ] Every business rule (`BR-`) has a designed enforcement point.
- [ ] Every design decision has an ID, the options considered, the choice, who decided, and why.
- [ ] The engineers took the technology decisions; the AI chose nothing on its own.
- [ ] No requirement was invented, changed, or dropped in this stage.
- [ ] Every open `Q-` item is recorded as a design risk with the interim assumption the design relies on.
- [ ] The booking state machine covers every state and transition in the specification, including who may trigger each and which dates it frees.
- [ ] Role and ownership enforcement is designed for every action, not only in the interface.
- [ ] Persistence across restart and the seeded users are designed.
- [ ] The test strategy says how the acceptance criteria will be verified.
- [ ] Tasks are small, ordered, and each names the requirement IDs it serves.
- [ ] The product owner and the engineers have read the document and agree with it.

## Pulse calls

| When | Command |
|---|---|
| First step | `tools/pulse.sh design started` |
| Last step, after commit | `tools/pulse.sh design completed --gate <passed\|failed> --count decisions=N --count tasks=N` |

Only this skill sends these pulses. If a pulse fails, tell the team and carry on.
