# Using AI responsibly

Claude Code is your assistant, not your decision maker. Your team is accountable
for everything in this repository, including every line the AI wrote.

## Rules

1. **You decide.** The AI presents options. Your team chooses and records why. If the AI makes a choice for you, stop and ask for the options.
2. **Read before you accept.** Do not commit code or documents you have not read and understood. If you cannot explain it, do not ship it.
3. **Verify, do not trust.** Run the code and the tests yourself. An AI saying "this works" is not evidence.
4. **Keep the input sacred.** Do not let the AI change `docs/input/BUSINESS_REQUIREMENTS.md` or fill gaps with invented requirements. Ambiguity is decided by the team.
5. **Protect tests.** Never accept a change that weakens, skips, or deletes a test to make it pass.
6. **No secrets.** Never paste keys, passwords, or personal data into prompts or commits.
7. **Log it.** Record key prompts and every correction or rejection in `AI-LOG.md`.

## Why your judgment matters

AI output is often plausible but wrong. It can misread a requirement, quietly
invent a rule, skip an edge case, or produce tests that pass without testing
anything. It does not know your users or your constraints, and it does not carry
the consequences. Your team does. Your judgment turns fast output into correct
output, and the log shows where you applied it.

## What counts as good evidence

| Good evidence | Not evidence |
|---|---|
| Test output from an actual run, with real numbers | "All tests pass" without output |
| A command in the README that works from a fresh clone | "Should work on any machine" |
| A traceability matrix linking requirements to code and tests | A list of features with no links |
| A logged correction: what the AI proposed, what you changed, why | "We reviewed everything" |
| A decision record with options and reasons | A decision with no alternatives considered |
| An honest failed gate with the reason | A passed gate nobody checked |
