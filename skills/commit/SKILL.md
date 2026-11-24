---
name: commit
description: Split the working tree into atomic Conventional Commits scoped by module, proposing the plan before committing.
disable-model-invocation: true
argument-hint: "[go]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git add *) Bash(git apply *) Bash(git commit *) Bash(git restore --staged *)
---

# Commit

## Snapshot

!`git status --short`

!`git diff HEAD --stat`

!`git log --oneline -10`

Arguments: $ARGUMENTS

## 1. Read the changes

Read the full diff (`git diff HEAD`) and every untracked file listed above. If something is already staged, include it in the plan rather than committing it blindly.

## 2. Group into atomic commits

One commit is one logical change that could be reverted on its own.

- **Scope = module.** Use the bounded context the change lives in: the directory under the package root, e.g. `engine/execution/` → `execution`, `app/sweeps/` → `sweep`. Changes in two modules are two commits, unless they are one interface change and its callers, which stay together and take the interface owner's scope.
- Code and the tests for it go in the same commit.
- Docs for a change go with the change. Docs-only edits are their own `docs` commit.
- Refactors never share a commit with behavior changes.
- Formatting-only changes are their own `style` commit.

## 3. Propose the plan

Show a table: `# | type(scope): subject | files | why it's one unit`. Wait for approval before committing, unless the argument is `go`.

## 4. Stage each commit precisely

- Stage by path: `git add <paths>`. Never `git add -A` or `git add .`.
- For part of a file, write the hunks to a patch file and apply it with `git apply --cached <patch>`. Interactive `git add -p` is not available.
- Before every commit, check staged files and diff for secrets: `.env*`, key files, seed phrases, API keys, private keys. If any appear, stop and tell the user.

## 5. Message format

```
type(scope): imperative subject, lowercase, no period, ≤ 72 chars

Why the change was made, not what the diff shows. Wrap at 72.

BREAKING CHANGE: what changed in the public interface and what callers must do
```

- Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`, `revert`.
- Mark a breaking change with `!` after the scope (`feat(execution)!:`) and a `BREAKING CHANGE:` footer. A change is breaking when a public signature, Protocol, event or DB schema, API contract or config key changes.
- Match the conventions visible in the recent log above.

## 6. Commit

- Commit with `git commit -m "<subject>" -m "<body>"`.
- Never use `--no-verify`. If a pre-commit hook fails, report the failure and fix it only if the fix is clearly in scope; otherwise stop.
- Never amend, rebase, push or force-push unless the user asks.

## 7. After

- Show `git log --oneline -<n>` for the commits just made.
- If a commit changed a module's public interface or an architectural decision, remind the user to update that module's README or write an ADR.
