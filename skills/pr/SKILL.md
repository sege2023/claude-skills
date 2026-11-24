---
name: pr
description: Slice unpushed commits into small stacked PRs, open them with concise descriptions, land a stack, and write promotion PRs between long-lived branches.
disable-model-invocation: true
argument-hint: "plan [base] | open [go] | land | describe | promote <from> <to>"
allowed-tools: Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git rev-list *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git for-each-ref *) Bash(gh pr list *) Bash(gh pr view *) Bash(gh pr checks *) Bash(gh repo view *)
---

# PR

A feature is a unit of work; a PR is a unit of review. One feature can be several PRs. Feature PRs into the integration branch are small and reviewed line by line. Promotion PRs between long-lived branches (dev → staging → main) are large by design and reviewed as a batch: did every change in it get reviewed, and is the batch safe to deploy?

## Snapshot

!`git status -sb`

!`git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads`

Arguments: $ARGUMENTS

Templates for every description are in [templates.md](templates.md).

## Mode `plan [base]`: slice commits into PRs

Read-only. Produces a plan; changes nothing.

1. **Base.** The integration branch the PRs merge into: the argument, else `origin/dev` if it exists, else the default branch. Fetch nothing without asking; say if the remote ref may be stale.
2. **Range.** `git log --reverse --format='%h %s%n%b' --name-only <base>..HEAD`. If the range contains merge commits, stop and explain: slicing needs a linear history.
3. **Features.** Group commits by intent: commit scopes, design docs and handoff docs that mark where a body of work ends, and what the user says they worked on. Commit messages can name a feature that is not what the code actually builds (for example, a bot's design doc plus the API the bot will call, but no bot). Name the feature by what was built, and say so. If grouping is unclear, ask.
4. **Cut into slices.** A slice is a *contiguous* run of commits, so each branch is just a ref to an existing commit and nothing is rewritten. Cut where:
   - a step of the work ends (a doc commit "record step N", a handoff, a decision record),
   - the theme or module changes,
   - the slice reaches about 400–1000 reviewable lines.

   Count reviewable lines without generated files (`linguist-generated` in `.gitattributes`, `_generated/`, regenerated clients, lockfiles, generated reports). Report them separately, never as review load.
5. **Interleaving.** If two features' commits alternate, slicing in order still works but mixes themes. Propose reordering with cherry-pick only if the user asks; first check for file overlap between the moved commits (`git show --name-only`), which predicts conflicts.
6. **Dependencies.** A slice depends on an earlier one when it edits files the earlier one created, or calls code it added. In a linear stack this is automatic; say which cross-feature dependencies exist, because they fix the merge order.
7. **Shippable or not.** Everything merged into the integration branch reaches production on the next promotion. Ask, per feature: is every slice safe to ship alone (complete, or inert: unwired, flagged off, docs only)?
   - **Yes:** slices stack directly on the integration branch.
   - **No:** create an umbrella branch `feature/<name>` from the base. Slices target it, and the final `feature/<name>` → integration PR is a promotion PR (template in templates.md). Warn that a long-lived umbrella drifts; prefer making the unfinished part inert.
8. **CI coverage.** Read `on.pull_request.branches` in `.github/workflows/*`. If PR checks only run for PRs into named branches, PRs whose base is another slice's branch get no CI until retargeted. Say which PRs will be unchecked when opened.
9. **Show the plan:**

   | # | branch | commits (first..last) | n | reviewable +/− | generated +/− | intent | base |

   Branch names: `<feature>/<NN>-<slug>`, e.g. `security/02-deploy-gate`. Then wait.

## Mode `open [go]`: create the branches and PRs

Runs the approved plan. Without `go`, show each command group and wait before running it. Pushing and opening PRs are visible to others.

1. **Branches.** `git branch <name> <last-sha>` per slice. This creates refs without checking anything out, so a dirty working tree is untouched. If a name exists and points elsewhere, stop.
2. **Check each slice tip.** For each branch: `git worktree add <tmpdir> <name>`, run the repo's checks there (`scripts/verify.sh` if present, else what the repo's CLAUDE.md names), then `git worktree remove <tmpdir>`. A failing tip means the cut is wrong (a later commit fixed it, e.g. a format commit) or the slice is not self-contained. Report it and propose moving the boundary; do not open a PR on a failing tip without the user's say.
3. **Push.** `git push -u origin <name>` per branch. Never push to the integration or long-lived branches. Never force-push.
4. **Open, bottom up.** Slice 1's base is the integration (or umbrella) branch; slice N's base is slice N−1's branch. Write each body from the feature PR template to a temp file, then `gh pr create --base <base> --head <name> --title "<type(scope): subject>" --body-file <file>`. Open slices whose base is another slice as `--draft` only if the user wants reviews in order.
5. **Link the stack.** Once all numbers exist, add the stack line to every body (`gh pr edit <n> --body-file <file>`), marking the current PR.
6. **Report:** the PR list with URLs, which have CI now, and how to land them (mode `land`).

## Mode `land`: after the bottom PR merges

1. Find the stack from the open PRs' bases (`gh pr list --json number,headRefName,baseRefName,state`).
2. **Merge method.** The bottom PR must be merged with a **merge commit**. Squash or rebase merges rewrite the commits, so the next PR would show them again. If that happened, explain and propose `git rebase --onto <integration> <old-base-branch> <next-branch>` plus `git push --force-with-lease`, and run it only after an explicit yes.
3. Retarget the next PR: `gh pr edit <n> --base <integration>`. Changing the base does not fire `pull_request` workflows (`edited` is not a default trigger type), so if CI filters on base, close and reopen the PR (`gh pr close <n> && gh pr reopen <n>`) to start the checks. Say that you did.
4. Update the stack line in the remaining bodies. Delete the merged branch only if the user asks.

Never merge a PR yourself unless the user asks for that PR.

## Mode `describe`: write or refresh one PR's description

For the current branch's PR (`gh pr view`), or the branch about to be opened. Use the feature PR template. Show the text, then update with `gh pr edit --body-file` after the user agrees.

## Mode `promote <from> <to>`: promotion PR

Example: `promote dev staging`.

1. Range `origin/<to>..origin/<from>`. If empty, say so and stop.
2. **Included PRs:** merge commits on the first-parent line (`git log --first-parent --merges --format='%h %s' <range>`) matched to `gh pr list --base <from> --state merged --json number,title,mergeCommit`.
3. **Unreviewed commits:** non-merge commits on the first-parent line came in by direct push, without a PR. List them under a warning; they are what a batch review must actually read.
4. **Deploy-relevant changes**, each from the diff, not memory:
   - migrations added (`migrations/`, `alembic/`),
   - config and env (`.env.example`, compose files, `deploy/`, settings keys),
   - CI and deploy workflows changed,
   - API contracts (`openapi.yaml`, schemas) and breaking changes (`!` in a subject or a `BREAKING CHANGE:` footer),
   - new dependencies (lockfile diff),
   - alerts and dashboards.
5. **Rollback.** Say what a rollback means for this batch: a migration that is not backward compatible makes "redeploy the previous image" unsafe. Say so if present.
6. **Size note.** If the range holds more than about 15 PRs, add one line suggesting more frequent promotions. Do not lecture.
7. Show the title and body (promotion template), then `gh pr create --base <to> --head <from> --title "release: <from> → <to> (<date>)" --body-file <file>` after the user agrees.

## Writing descriptions

- The reader is a reviewer, human or AI, who has the diff but not your context. Explain what the diff does and why, not line by line.
- Build from commit bodies, which already hold the why. Do not re-derive intent from the diff when commits state it.
- The intent is one sentence. Review tools use it as the spec to check the diff against (`deep-review` pass 0).
- Concise: a feature PR body fits on one screen (about 30 lines). Cut adjectives and anything the diff shows plainly.
- Say "None" in a section rather than deleting it, so a reviewer knows it was considered.
- Never paste secrets, tokens, internal hostnames or customer data into a description.

## After opening

Suggest one review per PR: `/deep-review audit #<n>` for an independent, behavior-first review, or `/code-review <n>` for a bug pass with inline comments. Review logic belongs to those skills, not this one.
