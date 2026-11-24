# Infra lenses

Apply these when the change touches CI workflows, Dockerfiles, compose files, shell scripts, deploy config or policy. Questions to ask, not a checklist to paste.

## Gates fail closed
- If a scanner crashes, times out or produces no output, does the gate block or pass? An empty results file read as "zero findings" is a silent pass.
- Is a step's failure actually propagated: `continue-on-error`, `|| true`, `set +e`, a missing `needs:`, or a job whose result nobody checks?
- Can an override (break-glass, allowlist, accepted-risk entry) be used without a reason, an expiry or a record? Who can trigger it?
- Does the scanner still parse the file? Some tools skip a whole file they cannot evaluate (an expression where a literal is expected) and report it as passing. Check the tool's output names the file.

## Triggers and coverage
- Which events run this workflow? A `branches:` filter on `pull_request` means PRs into other bases (stacked PRs) get no checks.
- `paths:` filters: can a relevant change land without matching them?
- `pull_request_target` or `workflow_run` with untrusted code checked out: fork code running with secrets.
- Does the deploy depend on the checks for the same commit, or could it deploy a commit the checks never saw?

## Workflow security
- `permissions:` least privilege per job; `contents: write` or `id-token: write` only where needed.
- Actions pinned by full commit SHA, not a tag.
- Script injection: `${{ github.event.* }}` or other user-controlled input interpolated directly into `run:`. Pass it through `env:` instead.
- Secrets echoed into logs, written to artifacts, or passed to third-party actions that do not need them.
- `concurrency`: can a newer run cancel a deploy or a gate mid-way?

## Containers and compose
- Runs as non-root; base image pinned; OS packages updated in the same layer they are installed.
- Secrets in build args, layers, or literal `environment:` values.
- Ports published on all interfaces (`"5432:5432"`) instead of `127.0.0.1:`; Docker bypasses host firewalls like UFW.
- `privileged`, host network, mounted Docker socket.

## Shell
- `set -euo pipefail` (or a stated reason not to); unquoted variables; word splitting on paths.
- Temp files and dirs cleaned up with `trap`, including on failure.
- Idempotent: safe to rerun after failing halfway?

## Deploy and rollback
- Migration order: does the new code need the migration before it starts, and does the old code survive the migrated schema during the rollout?
- Can the previous version be redeployed after this one? A non-reversible migration makes rollback a restore.
- New env vars or config keys: set in every environment that deploys this, with a safe failure if missing?
