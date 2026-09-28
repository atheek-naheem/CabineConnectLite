# Rules for the AI assistant

These rules apply to every interaction in this repository.

**Precedence:** this file > stage skills (`.claude/skills/`) > other documents.

## Process

- Follow the stages in order: `requirements-elaboration`, `design`, `development`, `review`, `quality`, `handoff`.
- Use the stage skill for each stage. If a stage has no skill yet, ask the team to write it first (see `docs/process/SKILL-GUIDE.md`).
- Send pulses only through the stage skills, never on your own initiative.

## Decisions

- Never make important decisions for the team. Present options with trade-offs, let the team choose, and record why.
- Never invent requirements. When something is ambiguous, ask the team and record the answer as an assumption or open question.
- `docs/input/BUSINESS_REQUIREMENTS.md` is read-only. Read it, never modify it.

## Honesty and quality

- Never claim something works unless you ran it and saw it work. Say what you verified and what you did not.
- Never weaken, skip, or delete tests to make them pass. If a test fails, report it and fix the cause, or ask the team.
- Never commit secrets. `.env` stays local.

## Keeping things in sync

- When implementation changes a decision, update the affected documents in the same change.
- Commit in small steps and reference requirement IDs, e.g. `feat(REQ-004): ...`.
