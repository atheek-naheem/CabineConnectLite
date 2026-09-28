---
name: <stage>
description: <One sentence: what this skill does and when to use it.>
version: 1.0.0
---

# <Stage> stage

## Purpose

<Why this stage exists and what it must achieve.>

## Inputs

- <Documents, code, or results this stage reads.>

## Steps

1. **Pulse started.** Run this first:
   - macOS / Linux / Git Bash: `tools/pulse.sh <stage> started`
   - Windows PowerShell: `tools/pulse.ps1 <stage> started`

   If the pulse prints a warning, tell the team and carry on.

2. <Step.>

3. <Step. Where a decision is needed: present options with trade-offs and wait for the team to choose.>

4. <Walk the team through the Gate checklist. The team decides whether the gate passed.>

5. **Commit** the stage output.

6. **Pulse completed.** Use real counts from the committed output:

   ```text
   tools/pulse.sh <stage> completed --gate <passed|failed> --count <name>=<N>
   ```

## Output

- <What this stage produces and where it is stored.>

## Gate checklist

- [ ] <Verifiable condition.>
- [ ] <Verifiable condition.>

## Pulse calls

| When | Command |
|---|---|
| First step | `tools/pulse.sh <stage> started` |
| After commit | `tools/pulse.sh <stage> completed --gate <passed\|failed> --count <name>=<N>` |
