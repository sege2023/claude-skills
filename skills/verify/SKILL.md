---
name: verify
description: Run this repo's checks (format, lint, types, tests) and explain or fix any failure at its root. Use before committing, when a change is complete, or when the user asks whether the code passes.
argument-hint: "[test paths]"
allowed-tools: Bash(./scripts/verify.sh) Bash(./scripts/verify.sh *) Bash(git diff *) Bash(git status *)
---

# Verify

`scripts/verify.sh` is the single source of truth for "does this repo pass". You, CI and Claude all run the same script, so a green verify here means a green CI check. This skill runs it and handles failures; it never substitutes its own commands when the script exists.

Arguments: $ARGUMENTS

## 1. Run

- If `scripts/verify.sh` exists, run `./scripts/verify.sh`, passing the test directories of the modules touched by the current change for speed (e.g. `./scripts/verify.sh engine/execution/tests`). With no arguments it runs the full suite. CI always runs the full suite.
- If it does not exist, read pyproject.toml, run the equivalent checks through the repo's runner (`uv run` or `poetry run`): `ruff format --check`, `ruff check`, `pyright`, `pytest -q`. Then tell the user the script is missing and offer to create it from [verify.sh.template](verify.sh.template).

## 2. Interpret failures

For each failing step:
- Give `file:line` and the root cause in one sentence.
- Check `git diff HEAD`: say whether this change caused the failure or it was already there. Report pre-existing failures separately and do not fix them unless asked.

## 3. Fix the cause, never weaken the check

- Do not add `# type: ignore`, `# noqa` or `# pyright: ignore`, skip or delete tests, loosen assertions, or change tool config to make a failure disappear, unless the user approves.
- For a type error on an override or Protocol implementation, fix the signature: matching parameter names, parameter types wider-or-equal, return type narrower-or-equal.
- Re-run after each round of fixes: fixing one type error often unmasks others. Stop after three rounds and report what remains.

## 4. Report

One line per step: `format ok`, `lint ok`, `types FAIL (2)`, `tests ok (142 passed)`. Then the remaining failures, if any.

## Before a commit

When this runs ahead of a commit and anything still fails, do not commit. Report the failures and stop.

Security scanning is not part of verify. The repo's git pre-commit hooks run the fast security gates when the commit happens, and CI runs the full scans, so they are not run twice.
