---
name: deep-review
description: Behavior-first code review that traces data across modules, applies this repo's lenses, and teaches the reasoning behind each finding. Use when the user asks to review a diff, branch, commit range, PR or module, or asks whether code is correct or what they missed.
argument-hint: "[learn|fast|audit] [ref-range | path | #PR] [--post]"
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git show *) Bash(gh pr view *) Bash(gh pr diff *) Bash(gh pr checks *)
---

# Deep review

Review behavior, not files. Logic lives in the paths data takes across modules, so the core of this review is tracing concrete inputs through the code, then questioning each step.

## Snapshot

!`git status --short`

!`git diff HEAD --stat`

Arguments: $ARGUMENTS

## Mode (first argument)

- **none**: standard review. Passes 0–5, findings, then exactly one closing question.
- **learn**: follow [teaching.md](teaching.md) instead of the standard output.
- **fast**: passes 1, 2 and 4 on changed lines only. No trace, no closing question. For small diffs.
- **audit**: spawn a fresh subagent with no conversation history to run the standard review, so the reviewer is not the one who wrote the code. Give it the target, the path `${CLAUDE_SKILL_DIR}/SKILL.md` to follow, the repo lens path below, and the instruction to end with "Questions for the author" instead of asking (see Unattended output). Relay its findings unchanged, then ask the closing question yourself.

## Target (remaining argument)

- **A path** (file or module directory): review its current state as a walkthrough of existing code, not a diff.
- **A ref range** (`main..HEAD`, a SHA): review `git diff <range>`.
- **A PR** (`#123` or a PR URL): read it with `gh pr view <n> --json number,title,body,baseRefName,headRefName,headRefOid,files` and review `gh pr diff <n>`, which is the diff against the PR's own base. In a stacked PR the base is the slice below, not the integration branch; review only this PR's diff.
- **Nothing**: review uncommitted changes (`git diff HEAD` plus untracked files). If the tree is clean, review the last commit (`git show HEAD`).

**Size.** Count changed lines without generated files (`linguist-generated` in `.gitattributes`, `_generated/`, regenerated clients, lockfiles, generated reports); list those as skimmed under **Checked**. If the rest exceeds about 400 lines, say so, propose splitting the review by module, and start with the riskiest module. For a PR, also suggest `/pr plan` to split it into stacked PRs.

## Load context

1. The repo's CLAUDE.md is already loaded. Respect its profile: in a repo marked prototype or mock, report correctness only and skip hardening findings.
2. Read `${CLAUDE_PROJECT_DIR}/.claude/review/lenses.md` if it exists. Those lenses are mandatory for this repo.
3. Read [lenses/core.md](lenses/core.md).
4. If the change touches CI workflows, Dockerfiles, compose files, shell scripts, deploy config or policy files, read [lenses/infra.md](lenses/infra.md).

## Passes

**0. Intent.** State in one sentence what the change is supposed to do, from the PR description, commit messages, branch name or the user. For a PR, the description is the spec: a diff that does more, less or something else than the description says is a finding. If you cannot state the intent, ask and stop (unattended: report it as the first finding and stop): an unclear intent is the first finding.

**1. Triage.** Get tool results before reading code. Spend no review attention on anything a tool already catches. Report failures as one block.
- **PR target:** read `gh pr checks <n>` first. Checks that ran and passed need not be rerun. If no checks ran (common for a stacked PR whose base is not a branch CI watches), say so and run the tools below in a temporary worktree at the PR head (`git worktree add <tmpdir> <headRefOid>`, removed afterwards), never in the user's working tree.
- **Python:** linter, type checker and tests scoped to the touched modules (`ruff check`, `pyright`, `pytest <module tests>`), through the repo's runner if pyproject.toml uses one (`uv run`, `poetry run`).
- **Infra files:** if `.pre-commit-config.yaml` exists, run its *check-only* hooks on the changed files by id (`pre-commit run <hook-id> --files <files>`), e.g. gitleaks, checkov, conftest, check-yaml. Never run formatter or fixer hooks: a review does not edit files. Otherwise run whichever of `actionlint`, `shellcheck`, `hadolint` are installed on the matching files. List missing tools under **Not checked**.

**2. Change map.** List the touched modules. For each, mark every interface change: function signatures, Protocol or ABC methods, dataclass or schema fields, events, DB migrations, config keys, public exports. For each changed interface, grep for every caller. Callers not updated to match are the most common cross-module bug.

**3. Trace.** Find the entry points the change reaches (API handler, webhook, event handler, CLI, scheduled job, backtest loop). For each, take one realistic concrete input and follow it through every function across files: the happy path first, then each failure branch. Write the trace as numbered steps, `file:function → what happens to the value`. Draw a mermaid `sequenceDiagram` when the trace crosses three or more modules.

For CI, deploy and infra changes the entry point is an event: a push to a branch, a PR into a base, a schedule, a manual dispatch with given inputs. Take one concrete event, e.g. "a PR into staging where one scanner crashes", and follow it through triggers, jobs, `needs`, conditions and gates to what gets deployed or blocked. Then the failure branches: a tool crashes, a step times out, an input is empty.

**4. Lenses.** At each trace step, apply the core and repo lenses. Report only lens hits with evidence; never paste the checklist.

**5. Tests.** For each finding, ask whether an existing test would fail if the bug were real. If none would, name the test or property that would catch it, using the property patterns in the core lenses.

## Findings format

```
[blocker] engine/execution/order_state.py:88 — what is wrong, in one sentence
  Why it matters: the concrete failure in production
  Found via: the pass and lens, e.g. "trace step 4, failure-modes lens"
  Fix: the direction of the fix, not a full rewrite unless asked
```

- **blocker**: wrong result, money or data loss, security hole
- **major**: breaks under a realistic edge case, or seriously hurts maintainability
- **nit**: naming or style, optional
- **question**: cannot tell whether it is intended

Blockers first. Show at most about 10; collapse the rest as "and N more nits". Never pad: a clean review is a valid outcome.

End every review with two lines:
- **Checked:** the passes, lenses and entry points covered.
- **Not checked:** what was skipped, e.g. integration tests not run, a path not traced.

## Closing question (standard and audit modes)

Ask exactly one question about production implications: failure, concurrency, an edge case, scaling, or a design trade-off, tied to a specific line in this change. Never syntax, trivia or definitions. Phrase it so the user must defend the choice, e.g. "This webhook arrives twice 200 ms apart. What does line 42 do on the second delivery, and why is that safe?"

If the answer shows a gap, explain it briefly and offer a fix. If it is right, confirm in one line and move on. The user can reply "skip".

## Unattended output (audit subagent, `--post`)

No one is there to answer, so do not ask and wait. Replace the closing question with a **Questions for the author** section: one to three questions of the same kind, each tied to a `file:line`. Put open `question` findings there too.

## Posting to a PR (`--post`, PR targets only)

Write the full review (findings, Checked, Not checked, Questions for the author) to a temp file and post it as one comment: `gh pr comment <n> --body-file <file>`. Typing `--post` is the user's approval for that one comment. Never approve, request changes or merge. Without `--post`, show the review and offer to post it.

## Rules

- Do not edit files during a review. Fix only after the user asks.
- Evidence or it is a question: cite `file:line`; tag anything unverified as `question`.
- Respect module boundaries: when logic belongs in another module or engine, flag that instead of suggesting it be added where it is.
- Do not flag what the formatter or linter enforces.
