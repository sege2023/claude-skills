# Repo lenses: payments-infra

Copy to `<repo>/.claude/review/lenses.md`. deep-review treats these as mandatory.

## Money
- Amounts are integer minor units (wei, token base units) or Decimal. Never float, anywhere in the path, including JSON parsing and logging.
- Conservation: total credited never exceeds total confirmed deposits; total swept never exceeds total credited.
- Every balance change is a ledger entry, never an in-place overwrite.

## Assets
- Assets are identified by chain ID plus contract address. Never by symbol or name: anyone can deploy a token called "USDC".
- Unknown or unexpected assets go to a quarantine path, never credited.
- Decimals come from the asset registry, not from the token contract at runtime.

## Deposits and webhooks
- Idempotency is a DB unique constraint on (chain, tx_hash, log_index). An in-memory check is not enough: providers resend the same payload.
- Webhook signature: HMAC computed over the raw request bytes, before JSON parsing, compared in constant time. Body-size limit and rate limit on the route.
- Confirmations: a deposit is credited only after the required confirmation depth. Check the reorg path: what happens to a credited deposit whose block is orphaned?

## State machines
- Deposit and sweep statuses change only through explicit transitions. Look for code that sets status directly.
- A sweep that was sent but has no receipt is "unknown", not "failed". Retrying it without checking the chain can double-send.

## Signing and admin
- The treasury destination is fixed in the signer's policy, not passed in by the API caller.
- Per-sweep caps and small relayer balances.
- Admin endpoints (kill switch, sweep retry) are off the public route, use a separate secret, and write an audit log entry.

## Hygiene
- Parameterized SQL only.
- Token names and symbols are untrusted input: sanitize before logs or Telegram alerts.
- No secrets, keys or seed material in code, logs, error messages or test fixtures.
