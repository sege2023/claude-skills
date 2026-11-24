# Predeploy checklist

Mark each item with evidence: a command and its output, or `file:line`.

## Code and config

- [ ] `./scripts/verify.sh` passes on the commit being deployed
- [ ] CI security jobs green: semgrep, pip-audit, trivy, zizmor, gitleaks full history
- [ ] No open `[blocker]` from the last security review
- [ ] `conftest test --policy policy/ deploy/*.yml` passes
- [ ] Migrations reviewed and reversible, or a rollback plan written

## Secrets

- [ ] Env files on the server are `chmod 600` and owned by the service user
- [ ] Each secret is distinct per environment (staging never reuses production secrets)
- [ ] Secrets left by the previous deploy owner (`DOCKERHUB_*`, `DO_*_DEV`) rotated or removed
- [ ] No image contains secrets (`trivy image --scanners secret <image>`)
- [ ] Master seed is not on any public-facing host

## Network

- [ ] Only the reverse proxy is published publicly; everything else binds 127.0.0.1 or an internal network (`ss -tlnp` on the host)
- [ ] Admin routes not reachable from the public internet
- [ ] Postgres, Redis, Prometheus (9090) and Alertmanager (9093) not reachable from outside

## Funds

- [ ] Signer policy: treasury destination and per-sweep caps match the intended values
- [ ] Relayer balances topped up only to what a few days of sweeps need
- [ ] Kill switch tested: engage, confirm sweeps stop, release

## Operability

- [ ] Alerts reach Telegram (send a test alert)
- [ ] Health and readiness endpoints green
- [ ] Rollback steps written and the previous image tag known
