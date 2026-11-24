<!-- Drafted from notes, not from the tree. Check the Layout and Commands sections against the repo, fix anything stale, then delete this comment. -->

# payments-infra

Production system that moves real customer funds on mainnet. Every change is held to production standard: no shortcuts, no "fix later" on money paths.

## What it does

HD-derived deposit address per payment → Alchemy Address Activity webhook → ingress (signature check) → detection → confirmation → deposit state machine → ledger entry plus queued sweep → signer → treasury. First targets: BSC USDT and Base USDC.

The API repo is separate. It talks to infra over synchronous internal HTTP with service auth, using a generated client package. Infra stays independent so API deploys don't affect it and B2C can reuse it.

## Layout

- `src/payments_infra/` — API, ingress, workers (detection, confirmation, sweeps)
- `signer/` — separate signing service with its own `.env` and policy; holds the keys
- `migrations/` — SQL migrations, applied by `migrate.py`
- `ops/` — local `docker-compose.yml` (Postgres + Redis, `payments_test` DB in the same container), `db_roles.sql`, `tools/api_smoke.sh`
- `deploy/` — `docker-compose.staging.yml`, Prometheus and Alertmanager config
- `policy/` — conftest policies for compose files

## Commands

- Checks: `./scripts/verify.sh` (format, lint, pyright, tests)
- Local infra: `docker compose -f ops/docker-compose.yml up -d`
- Workers run on the host: `uv run --env-file <env file> ...` with `.env`, `.env.ingress` and `signer/.env`
- Smoke test: `ops/tools/api_smoke.sh`
- `LOCAL_DEV.md` is outdated; trust this file and the code over it.

## Branches

`dev` → `staging` → `main`. Work on `dev`.

## Money rules

- Amounts are integer base units or Decimal, never float.
- Assets are identified by chain ID plus contract address, never by symbol.
- Idempotency is a DB unique constraint on (chain, tx_hash, log_index). Providers resend payloads.
- Full review lenses: `.claude/review/lenses.md`. Threat model: the `security-payments` skill.

## Decisions already made

- Reorgs: 5-minute grace period before marking a deposit reorged; a reorged deposit is revived in place if its tx is re-mined.
- Admin API uses its own `ADMIN_SECRETS`, separate from service auth.
- One relayer key per chain (`SIGNER_RELAYER_KEYS`, chain ID → key).
- Services bind `127.0.0.1` by default (`API_HOST`, `INGRESS_HOST`, `SIGNER_HOST`).

## Lessons from this codebase

- When a caller needs a capability (a signing account) but receives a value object (`DerivedAddress`: index + address), add a method on the class that holds the key material (`HDWallet`) returning the capability. Never widen the frozen value object to carry secrets. Derive and account resolution share one node-resolution helper so they can't drift.

## Never

- Log, print or echo secrets, keys, seeds or full webhook secrets.
- Commit env files or anything under `secrets/`.
- Change the signer's treasury destination or per-sweep caps unless explicitly asked.
- Point local or test code at mainnet keys.
