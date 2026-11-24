---
name: security-payments
description: Security review, scanner triage and predeploy checks for the payments infra. Use when changing webhook ingress, deposit detection, sweeps, the signer, admin endpoints, auth, Docker or compose files, CI workflows or secrets handling; when triaging gitleaks, ruff S, checkov, conftest, semgrep, trivy or pip-audit findings; or before deploying to staging or production.
argument-hint: "[review | triage | predeploy | update]"
---

# Security: payments infra

Scanners enforce known patterns at commit and in CI. This skill is the judgment layer: does a change open a path to funds, is a scanner finding real, and is a deploy safe.

The threat model is in [threat-model.md](threat-model.md). The predeploy checklist is in [predeploy.md](predeploy.md).

Arguments: $ARGUMENTS

## review (default)

1. Identify which assets and trust boundaries in the threat model the change touches.
2. For each threat that applies, check the control in the code and cite `file:line`. Mark it present, partial or missing.
3. Name any new attack surface the change adds: a new route, input, secret, port, dependency or permission.
4. Report findings in the deep-review format (`[blocker]`, `[major]`, `[nit]`, `[question]`, with "Why it matters" and "Fix").
5. If a control's status changed, propose the edit to the threat model's status column and apply it once the user agrees.

## triage

Input: scanner output pasted by the user, or a file path.

For each finding:
1. Is it reachable? Trace whether untrusted input can reach that line.
2. Classify it:
   - **True positive:** propose the minimal fix.
   - **False positive:** propose a suppression on that exact line with the reason in the comment (`# noqa: S608  # columns come from an allowlist`). Apply only with the user's approval. Never disable a rule repo-wide.
   - **Accepted risk:** add it to the threat model's accepted-risks table with a reason and a revisit date, after the user agrees.
3. Summarize: counts per class, then the true positives by severity.

## predeploy

Walk [predeploy.md](predeploy.md). Mark each item with evidence: the command you ran or the file and line you checked. Items that need server access you don't have: list them with the exact command for the user to run.

## update

Re-check every row of the threat model against the code and refresh the status column. Report what changed.

## Rules

- Never print a secret value, even one a scanner found. Show its location and a redacted prefix only.
- Never run anything against mainnet.
- Never change the signer policy, treasury destination or caps unless the user explicitly asks.
