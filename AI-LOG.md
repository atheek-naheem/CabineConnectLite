# AI Log

Keep this log up to date during the challenge, not at the end.

The most important section is **Corrections and rejections**: every time the
team changed, corrected, or rejected AI output, and why. Changes to your skills
go there too.

## Key prompts

*Prompts that shaped the work: the start of each stage, important questions, significant requests.*

| # | Time (UTC) | Stage | Who | Prompt (short) | Outcome |
|---|---|---|---|---|---|
| P-01 | 2026-09-28T04:41 | requirements-elaboration | Atheek | `/requirements-elaboration` (iteration 1) | 18 ambiguities raised in 4 batches, all decided by the product owner. `REQUIREMENTS.md` written with REQ-001..REQ-014, A-001..A-018, Q-001 and Q-002 opened. Gate passed. Commit `e0a8d2b`. |
| P-02 | 2026-09-28T05:25 | requirements-elaboration | Atheek | `/requirements-elaboration` (iteration 2) | No change to the business input, so the product owner resolved the two open questions instead. Added A-019..A-021, REQ-015, REQ-016 and the audit trail rules. Gate passed. Commit `a1e88b6`. |
| P-03 | 2026-09-28T05:34 | requirements-elaboration | Atheek | `/requirements-elaboration` (iteration 3) | Nothing had changed again, so the AI ran a fresh ambiguity pass and found six gaps. Added A-022..A-027, REQ-017 (pending queue), BR-020, BR-021. Gate passed. Commit `7077c65`. |
| P-04 | 2026-09-28T05:47 | requirements-elaboration | Atheek | "send a pulse to requirement stage again" | Completed pulse sent as-is by team choice; refused for incomplete setup and logged locally only. No document change. |
| P-05 | 2026-09-28T05:54 | design (skill authoring) | Atheek | "help me write a generic skill for the design stage, refer to the previous requirements-elaboration stage file" | `.claude/skills/design/SKILL.md` v1.0.0 written after the team chose scope, artifact layout, ID scheme and open-question handling. Pulse commands verified with `--dry-run`. Commit `5888a6c`. |

## Corrections and rejections

*What the AI proposed, what the team did instead, and why.*

| # | Time (UTC) | Stage | What the AI proposed | What we did (corrected / rejected) | Why | Commit |
|---|---|---|---|---|---|---|
| C-01 | 2026-09-28T05:20 | requirements-elaboration | `ERR-013` (simultaneous overlapping requests) cited `EC-010`, which is about freeing dates, not concurrency. | Re-pointed it at `BR-001` and `VAL-006`. | Wrong cross-reference would have sent a reader to an unrelated rule. Caught by the AI's own review pass before the first commit. | `e0a8d2b` |
| C-02 | 2026-09-28T05:21 | requirements-elaboration | `SEC-004` said input is validated "on the trusted side". | Reworded to "validated by the application before it is acted on". | The phrase leans on an architecture split that the design stage owns; requirements must carry no design decisions. | `e0a8d2b` |
| C-03 | 2026-09-28T05:39 | requirements-elaboration | The AI asked the product owner to choose a list ordering, offering three options. | The product owner declined to choose: "dont over complicate this, choose something simple", and delegated it. | Ordering was judged a presentation detail not worth the product owner's time. Recorded as `A-026` with the delegation stated explicitly, so the document does not imply a business decision that was never made. | `7077c65` |
| C-04 | 2026-09-28T05:40 | requirements-elaboration | For the pending queue the AI had offered "oldest first" and the product owner accepted that option. | The AI flagged that this conflicted with the single ordering rule just agreed, proposed check-in soonest first for every list, and asked before writing it. | One ordering rule everywhere is simpler and matches the request in C-03. The deviation from the accepted option was raised rather than applied silently; the team confirmed at the gate. | `7077c65` |
| C-05 | 2026-09-28T05:41 | requirements-elaboration | `BR-021` first read "The only limits on booking are the 2 unfinished bookings, the 7-night maximum and the 90-day horizon." | Narrowed it to quotas only. | As written it contradicted `BR-003` (minimum one night) and `BR-004` (no past dates), which are also limits. Caught by the AI's own review before the commit. | `7077c65` |
| C-06 | 2026-09-28T05:20, 05:41 | requirements-elaboration | While inserting new rows the AI placed `ERR-017`/`ERR-018` and `A-022`..`A-027` out of numeric order in their tables. | Repaired the row order and added a scripted check that every section's IDs ascend. | Out-of-order IDs make a specification hard to scan and hint at sloppier errors. Both were the AI's own mistakes, found by its verification step. | `e0a8d2b`, `7077c65` |
| C-07 | 2026-09-28T05:47 | requirements-elaboration | The AI offered to restore `REQUIREMENTS_ELABORATION_COMPLETED=na_UhlpriSZpf` so the completed pulse would reach ai-hub. | The team rejected that and sent the pulse without the key, accepting that it is refused and logged locally only. | Started and completed would have shared one ai-hub activity named "Requiremenets", so the hub could not tell the two events apart. A local-only record is more honest than a misleading one. The organizer must supply a distinct stage-completed ID. | `4969f0e` |
| C-08 | 2026-09-28T05:54 | design (skill authoring) | `SKILL-TEMPLATE.md` specifies a top-level `version` field in the frontmatter. | The design skill uses `metadata.version` and adds `disable-model-invocation: true`, matching the provided `requirements-elaboration` skill instead. | That frontmatter form is known to load in this environment, and disabling model invocation stops the skill firing pulses on the AI's own initiative, which `CLAUDE.md` forbids. Deviation flagged to the team rather than made silently. | `5888a6c` |

## Skill changes

*Every change to a skill after its first version, including the four your team writes.*

| # | Time (UTC) | Skill | Change | Why | Commit |
|---|---|---|---|---|---|
| S-01 | | | | | |

## Reflection

*Fill in at handoff: two or three sentences each.*

- Where did AI help most?
- Where did it mislead you, and how did you notice?
- What would you do differently?
