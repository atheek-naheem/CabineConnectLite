# Writing your stage skills

One stage skill is provided: `requirements-elaboration`. Your team writes the other
five in two sessions:

- the `design` skill **after the requirements-elaboration stage completes and before the design stage starts**
- the other four **after the design stage completes and before development starts**

| Stage | Purpose | Your skill file |
|---|---|---|
| `design` | Decide how to build the solution, record the decisions, and break the work into small tasks linked to requirement IDs. | `.claude/skills/design/SKILL.md` |
| `development` | Implement the design feature by feature, with tests written alongside. | `.claude/skills/development/SKILL.md` |
| `review` | Review the code against the requirements and the design. | `.claude/skills/review/SKILL.md` |
| `quality` | Test the solution and produce the test report. | `.claude/skills/quality/SKILL.md` |
| `handoff` | Validate the delivery end to end, complete the README (sections marked *Completed at handoff*, Known limitations), and prepare the pull request. | `.claude/skills/handoff/SKILL.md` |

How each skill does its job is up to you. That is part of the challenge.

## Start from the examples

- Read `.claude/skills/requirements-elaboration/SKILL.md`. It is the reference
  example for structure, tone, and pulse handling.
- Copy `docs/process/SKILL-TEMPLATE.md` to `.claude/skills/<stage>/SKILL.md` and fill it in.
- Keep skills short and specific. A skill is a set of instructions the AI follows
  step by step, not an essay.

## Required structure

Every skill must have:

1. **Frontmatter** with `name` (the stage name), `description` (what it does and
   when to use it), and `version`.
2. **Purpose:** why the stage exists and what it must achieve.
3. **Inputs:** what the stage reads.
4. **Steps:** numbered and in order. The first step is the `started` pulse and the last is the `completed` pulse.
5. **Output:** what the stage produces and where it is stored.
6. **Gate checklist:** verifiable conditions the team checks before completing the stage.
7. **Pulse calls:** the exact commands used.

## The pulse contract

Every skill must follow these rules:

1. **Pulse `started` first**, before any other work in the stage.
2. **Commit the stage output before pulsing `completed`.** The pulse records the
   current commit, and the script warns if there are uncommitted changes.
3. **Report the gate honestly.** The team decides `passed` or `failed` after
   walking the gate checklist. A failed gate is a valid result.
4. **Report only real counts**, taken from the committed output or an actual run.
   Never estimate or round.
5. **Never send pulses by hand.** Pulses are sent only by the skills. If a stage
   is repeated, run the skill again. This records a new iteration.
6. **Carry on if a pulse fails.** The script always logs the attempt in
   `pulses.log` and never blocks you. Tell the team and continue.

Count names must be lowercase `snake_case`. The script adds `_count` unless the
name already ends in `_count`, `_passed`, `_failed`, `_fixed`, `_completed`, or `_traced`.

Recommended counts:

| Stage | Counts |
|---|---|
| `design` | `decisions`, `tasks` |
| `development` | `tasks_completed`, `tests` |
| `review` | `findings`, `findings_fixed` |
| `quality` | `tests`, `tests_passed`, `tests_failed` |
| `handoff` | `requirements_traced`, `known_limitations` |

Example:

```text
tools/pulse.sh quality completed --gate passed --count tests=12 --count tests_passed=12 --count tests_failed=0
```

## Keep decisions with the team

Wherever a stage involves an engineering decision, the skill must tell the AI to:

- present two or three options with their trade-offs
- wait for the team to choose, and never choose for them
- record the choice and the reason

A skill must never tell the AI to weaken, skip, or delete tests, to invent
requirements, or to claim something works without running it. The rules in
`CLAUDE.md` always take precedence over a skill.

## Test your skill before relying on it

1. Read it once as if you were the AI. Is every step unambiguous?
2. Check the pulse commands without sending anything:

   ```text
   tools/pulse.sh <stage> started --dry-run
   tools/pulse.sh <stage> completed --gate passed --count <name>=1 --dry-run
   ```

3. Run `tools/pulse.sh status` to see what has been recorded. Dry-runs are logged
   but ignored by `status` and by iteration counting.
4. Fix anything that is unclear, then commit the skill.

On Windows PowerShell, use `tools/pulse.ps1` with the same arguments.

## Log your changes

Record in `AI-LOG.md` every time you correct or reject AI output while writing a
skill, and every later change to a skill, with the reason.
