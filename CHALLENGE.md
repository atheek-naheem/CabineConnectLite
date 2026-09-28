# The Challenge

## Goal

Build a small working application from the business requirements in
`docs/input/BUSINESS_REQUIREMENTS.md`, using Claude Code, by following a staged
engineering process. How you work counts as much as what you deliver: clear
requirements, deliberate decisions, disciplined building, honest testing, and a
delivery that runs from a fresh clone.

You choose the language and technology stack. Nothing in this repository
prescribes a solution.

## The six stages

| # | Stage | What happens | Skill | Artifact |
|---|---|---|---|---|
| 1 | `requirements-elaboration` | Elaborate and specify the requirements | Provided | `docs/requirements/REQUIREMENTS.md` |
| 2 | `design` | Design the solution and break it into tasks | You write it | `docs/design/DESIGN.md` |
| 3 | `development` | Implement feature by feature, with tests alongside | You write it | Source code and tests |
| 4 | `review` | Review the code against requirements and design | You write it | Review section in the PR or a review file |
| 5 | `quality` | Test and report | You write it | Tests and `docs/testing/TEST_REPORT.md` |
| 6 | `handoff` | Final validation, README, traceability check, PR | You write it | README and PR description |

Write your skills using `docs/process/SKILL-GUIDE.md`, in two sessions:

- between `requirements-elaboration` and `design`: the `design` skill
- between `design` and `development`: the `development`, `review`, `quality`, and `handoff` skills

## Timebox: 3 hours

Suggested plan:

| Activity | Time |
|---|---|
| Requirements elaboration | 25 min |
| Writing the design skill | 10 min |
| Design | 25 min |
| Writing four skills | 25 min |
| Development | 60 min |
| Review | 15 min |
| Quality | 20 min |
| Handoff | 10 min |

Unfinished work is not hidden. List it under **Known limitations** in the README
and the test report.

## Deliverables

- Completed `docs/requirements/REQUIREMENTS.md` and `docs/design/DESIGN.md`
- Five stage skills in `.claude/skills/` (`design`, `development`, `review`, `quality`, `handoff`)
- Working source code with automated tests
- Completed `docs/testing/TEST_REPORT.md`
- Completed `README.md`
- Completed `AI-LOG.md`
- `pulses.log`, committed
- A pull request from `solution` to `main`

## Run contract

The README must give the **exact** commands to install, run, and test the
application. The final check is a fresh clone of your repository using **only**
those commands. If it does not run that way, it does not run.

## Pulse rules

Pulses report your progress through the stages to ai-hub.

- Pulses are sent only by the stage skills, never by hand.
- `started` is the first step of a stage. `completed` comes after the stage output is committed.
- Gate results are reported honestly. A failed gate is valid information.
- Counts are real numbers from your artifacts or test runs.
- If a pulse fails, carry on. It is still logged in `pulses.log`.
- Check your progress with `tools/pulse.sh status` (or `tools/pulse.ps1 status`).

## AI log

Keep `AI-LOG.md` up to date as you go. Most important are the moments you
corrected or rejected AI output, and why. That includes changes to your skills.
See `AI-USAGE.md`.

## Submission

1. Work on the `solution` branch (see `CONTRIBUTING.md`).
2. Open a pull request from `solution` to `main` using the PR template.
3. **Do not merge it.**

## Evaluation areas

- Requirements
- Design
- Skill quality
- Build discipline
- Review and testing
- AI usage
- Validation and delivery
