---
name: requirements-elaboration
description: Elaborate the business requirements into a complete, testable requirements specification together with the team. Run at the start of the challenge, or again when requirements change.
disable-model-invocation: true
metadata:
  version: "1.1.0"
---

# Requirements Elaboration stage

## Purpose

Turn the business requirements into a specification that the team agrees with
and that design, development, and testing can trace back to. The product owner
owns every business interpretation. Your job is to surface ambiguity, not to
resolve it for them.

## Inputs

- `docs/input/*.md`: the business input, including any change requests.
  **Read-only. Never modify these files.**
- `docs/requirements/REQUIREMENTS.md`: the specification to fill in or update.
- `CLAUDE.md`: standing rules.

## Steps

1. **Pulse started.** Run this first, before any other work:
   - macOS / Linux / Git Bash: `tools/pulse.sh requirements-elaboration started`
   - Windows: `powershell -ExecutionPolicy Bypass -File tools\pulse.ps1 requirements-elaboration started`

   If the pulse prints a warning, tell the team and carry on. Pulses never block the work.

2. **Check for an existing specification.** If `REQUIREMENTS.md` already contains
   content, this is a new iteration: you will **update** it, not rewrite it. Keep
   all existing IDs and the team's manual edits. New items get new IDs. Never
   reuse an ID. Team-proposed features go under "Team-proposed extensions" with
   `EXT-` IDs, without changing existing items.

3. **Read the input.** Read every file in `docs/input/` in full. Do not edit them.

4. **Find ambiguities first. Never invent requirements.**
   Before writing anything, look for missing definitions, unclear boundaries,
   conflicting statements, undefined behaviour, unstated limits, and **role
   permissions the input does not state**. Where the input is silent, do not
   fill the gap; ask. For each ambiguity:
   - quote the unclear statement
   - present two or three plausible interpretations and what each would imply
   - ask the **product owner** to choose. Do not recommend unless asked, and then give reasons.
   - record the choice as an assumption (`A-001`, ...) with who decided and why,
     or as an open question (`Q-001`, ...) if they cannot decide yet

   Ask in small batches. Do not continue past an ambiguity that changes a
   requirement until it is answered.

5. **Elaborate.** Using the input and the product owner's decisions, draft:
   - user roles, and what each may and may not do (only what the input or an assumption states)
   - functional requirements (`REQ-001`, ...)
   - non-functional requirements (`NFR-001`, ...)
   - business rules (`BR-001`, ...)
   - validation rules, error scenarios, edge cases
   - security considerations
   - testable acceptance criteria for every requirement (observable outcome, not implementation)

   Every item must trace to a statement in the input or to an assumption. Note
   the source of each item.

6. **Write the document.** Fill in or update `REQUIREMENTS.md`, keeping the
   template headings. Remove the template's guidance text and example rows.
   Do not add solution or technology choices. Those belong to the design stage.
   On an update, show the team a short summary of what changed.

7. **Review.** Check the document yourself and report what you find:
   - every statement in the input is covered by at least one requirement or rule
   - every requirement has at least one testable acceptance criterion
   - IDs are unique and consistent across sections
   - no contradictions between requirements, rules, and assumptions
   - nothing was added that the input or the product owner did not ask for

   If the team edited the document by hand, re-read it and check it for
   consistency before continuing.

   Then walk the team through the **Gate checklist** item by item. **The team
   decides** whether the gate passed or failed. Record the result and the
   completion timestamp in the document.

8. **Remind the team** that before the design stage starts they must write
   their `design` skill using `docs/process/SKILL-GUIDE.md` and
   `docs/process/SKILL-TEMPLATE.md`, with this skill as the reference example.

9. **Commit.** Commit the document and `pulses.log`
   (e.g. `docs(requirements): elaborate requirements`).

10. **Pulse completed.** Count from the committed document, never estimate:
    - `requirements` = number of `REQ-` items
    - `assumptions` = number of `A-` items
    - `open_questions` = number of `Q-` items still open

    ```text
    tools/pulse.sh requirements-elaboration completed --gate <passed|failed> --count requirements=N --count assumptions=N --count open_questions=N
    ```

    On Windows: `powershell -ExecutionPolicy Bypass -File tools\pulse.ps1` with
    the same arguments. Report the gate honestly. A failed gate is valid
    information, not a problem to hide.

## Output

- `docs/requirements/REQUIREMENTS.md`, completed or updated, and committed.
- Two pulses in `pulses.log` (started, completed).

## Gate checklist

The team confirms each item:

- [ ] Every statement in the business input maps to at least one requirement or business rule.
- [ ] Every requirement has an ID and at least one testable acceptance criterion.
- [ ] Every ambiguity was decided by the product owner (assumption) or recorded (open question).
- [ ] No requirement or permission was invented without a product owner decision.
- [ ] Roles and their permissions are explicit.
- [ ] Error scenarios and edge cases are listed.
- [ ] The document contains no design or technology decisions.
- [ ] The product owner and the engineers have read the document and agree with it.

## Pulse calls

| When | Command |
|---|---|
| First step | `tools/pulse.sh requirements-elaboration started` |
| Last step, after commit | `tools/pulse.sh requirements-elaboration completed --gate <passed\|failed> --count requirements=N --count assumptions=N --count open_questions=N` |

Only this skill sends these pulses. If a pulse fails, tell the team and carry on.
