# PR description templates

## Feature PR

Title: the Conventional Commit form of the slice, `type(scope): subject` (≤ 72 chars). Use the dominant type; a slice of `feat` plus its tests and docs is `feat`.

```markdown
**Intent:** <one sentence: what this PR makes true that was not true before>

Part <k> of <m> of <feature>. Stack: #a → **#b** → #c

## Changes
- `<module>`: <what changed and why, one line>
- `<module>`: ...

## Interfaces, migrations, config
<new or changed endpoints, Protocols, events, DB migrations, env vars, config keys; "None">

## Testing
<tests added, checks run at this branch's tip, what was not tested>

## Review guide
- Focus: <files or the one decision a reviewer should challenge>
- Skim: <generated files, docs, formatting-only commits>
```

### Example (filled)

```markdown
**Intent:** Let an operator ask the sweeper to requeue a sweep that reverted on chain, and record the gas the revert burned.

Part 5 of 5 of operator admin actions. Stack: #31 → #32 → #33 → #34 → **#35**

## Changes
- `ledger`: post a gas-burn entry for a reverted sweep; settlement Protocols accept frozen dataclasses
- `sweeping`: requeue request type, handled by the sweeper, never by the API
- `api`: `POST /v1/admin/sweeps/{id}/requeue`
- `observability`: alert when the sweeper leaves an operator request unanswered

## Interfaces, migrations, config
- Migration `013_sweep_requeue_request.sql` (additive)
- New admin route, added to `contracts/openapi.yaml`; client regenerated

## Testing
Unit and end-to-end tests for requeue and the revert entry, mutation-checked. `verify.sh` passes at this tip.

## Review guide
- Focus: `sweeping/cycle.py` — can a requeue race the sweeper's own retry?
- Skim: `client/**/_generated/**` (≈1.9k lines, regenerated)
```

## Promotion PR

Title: `release: <from> → <to> (<YYYY-MM-DD>)`

```markdown
Promotes <n> PRs from `<from>` to `<to>`. Every change below was reviewed in its own PR; this review is about whether the batch is safe to deploy.

## Included
- #<n> <title>
- ...

## Not reviewed in a PR
<commits pushed directly to <from>; "None">

## Deploy notes
- Migrations: <list, and whether each is backward compatible>
- Config and env: <new or changed keys; who sets them where>
- Workflows: <CI or deploy changes that alter how this deploy runs>
- API and breaking changes: <"None">
- Dependencies: <added or bumped>
- Alerts: <new or changed>

## Rollback
<redeploy previous image, or why that is unsafe for this batch>
```
