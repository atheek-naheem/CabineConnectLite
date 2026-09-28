# Contributing

## Git workflow

1. Create the `solution` branch from `main` once, at the start:

   ```text
   git checkout main
   git checkout -b solution
   git push -u origin solution
   ```

2. Do each piece of work on a short-lived feature branch from `solution`:

   ```text
   git checkout solution
   git pull
   git checkout -b feat/<short-name>
   ```

3. Open a pull request from the feature branch into `solution`. **One teammate
   reviews and approves** before it is merged.
4. At the end, open the final pull request from `solution` into `main` using the
   PR template. **The team never merges this pull request.**

Commit stage documents and `pulses.log` like any other change.

## Commit messages

Use `type(scope): summary`, with a requirement ID as the scope where one applies:

```text
feat(REQ-004): <what the change does>
fix(BR-002): <what was wrong and what changed>
test(REQ-001): <what is now tested>
docs(design): <what was recorded>
chore: <tooling or housekeeping>
```

Keep commits small, one logical change each, so a reviewer can follow them.

## Coding basics (any language)

- Follow the conventions of your chosen language and use its standard formatter and linter.
- Use clear names. Keep functions small and focused.
- Avoid duplicating logic. Duplicated rules drift apart.
- Validate all input. Report errors clearly and consistently.
- Write tests alongside the code, not afterwards. A change without a test needs a reason.
- Do not leave dead code, commented-out code, or debug output behind.
- Keep documentation in sync with the code.

## Security basics

- Never commit secrets. Configuration secrets live in `.env`, which is ignored by Git.
- Enforce permissions where the action is performed, not only by hiding options from the user.
- Treat all input as untrusted. Use your stack's safe, built-in mechanisms for handling input and output.
- Do not log sensitive data.
- Use dependencies from official sources, and only the ones you need.
