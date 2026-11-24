# Threat model: payments infra

Status column: `verify` means not yet checked against the code. Run `/security-payments update` to fill it in, and keep it current.

## Assets

| Asset | Where it lives | Impact if lost |
|---|---|---|
| Customer funds in deposit addresses | on-chain, derived from the master seed | direct loss |
| Treasury | on-chain | direct loss |
| Master seed | signer host only | every deposit address drained |
| Relayer keys | `signer/.env`, one per chain | relayer balance drained, sweeps stall |
| Webhook, service, admin and event-push secrets | env files | forged deposits, unauthorized admin actions |
| Ledger and deposit state | Postgres | wrong credits, double credits |
| CI and registry credentials | GitHub secrets | malicious image or workflow deployed |

## Trust boundaries

1. **Internet → webhook ingress.** Anyone can send requests; only Alchemy-signed ones are genuine.
2. **API repo → infra API.** Trusted service, authenticated by service secret and network isolation.
3. **Operator → admin API.** Kill switch, sweep retry. Highest privilege after the signer.
4. **Infra → signer.** The signer trusts nothing about the destination; its own policy decides.
5. **Infra → chain RPC (Alchemy).** Data is mostly trusted but can be delayed, duplicated or reorged.
6. **Shared dev server (ldb-dev).** Other teams' stacks run on the same host.
7. **CI → registry → server.** Whoever can change a workflow can change what gets deployed.

## Threats and controls

| # | Threat | Control | Status |
|---|---|---|---|
| T1 | Forged webhook credits a fake deposit | HMAC over raw body bytes, constant-time compare, body-size and rate limits | verify |
| T2 | Replayed webhook double-credits | DB unique constraint on (chain, tx_hash, log_index) | verify |
| T3 | Fake token named "USDC" credited | Match chain ID + contract address against the registry; unknown assets quarantined | verify |
| T4 | Wrong-network or wrong-asset transfer lost or miscredited | Wrong-asset/wrong-network detection and a manual recovery path | verify |
| T5 | Reorg leaves a credited deposit that no longer exists | Confirmation depth per chain; reorg grace period; reversal path | verify |
| T6 | Compromised API redirects sweeps | Treasury destination fixed in signer policy, not passed by caller; per-sweep caps | verify |
| T7 | Sweep sent but status unknown, retried, double-sent | Unknown ≠ failed; check chain before retry; relayer nonce management | verify |
| T8 | Admin endpoint abused | Off the public route; separate `ADMIN_SECRETS`; IP allowlist; audit log | verify |
| T9 | Ports exposed publicly via Docker bypassing UFW | Bind to 127.0.0.1 or internal networks; enforced by `policy/compose.rego` | verify |
| T10 | Secrets leaked via repo, image or logs | gitleaks at commit and full history in CI; trivy image scan; no secrets in logs; env files `chmod 600` | verify |
| T11 | Malicious workflow change exfiltrates secrets | Branch protection (needs GitHub Team), workflow review, Actions pinned by SHA, zizmor in CI | verify |
| T12 | Neighbor service on ldb-dev compromised | Separate Docker networks; master seed not on this host; minimal secrets on host | verify |
| T13 | SQL or log injection via token names and symbols | Parameterized SQL; sanitize token metadata before logs and Telegram alerts | verify |
| T14 | Vulnerable dependency | Locked dependencies with hashes; pip-audit in CI | verify |

## Accepted risks

| Risk | Reason | Revisit by |
|---|---|---|
| | | |
