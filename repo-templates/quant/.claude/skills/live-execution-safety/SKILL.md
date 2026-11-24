---
name: live-execution-safety
description: Safety rules for code that can place real orders on Bybit. Applies when changing the live venue adapter, order state machine, risk checks, reconciliation, circuit breaker or the live runner.
paths:
  - "**/engine/execution/venues/bybit*"
  - "**/engine/execution/order_state.py"
  - "**/engine/risk/**"
  - "**/observability/**"
---

# Live execution safety

This code can send real orders. Any path that could send an unintended order, oversize a position, or lose track of an order is a blocker.

## Keys

- Trade-only API keys: no withdrawal permission, IP-restricted to the live VPS.
- Loaded from an env or secret file at startup; never logged, never in config snapshots or run outputs.
- Testnet and mainnet keys are selected by explicit config. The default is testnet.

## Orders

- Every order gets a deterministic client order ID (Bybit `orderLinkId`) before it is sent, and the intent is written to the durable log before the network call.
- Retries reuse the same client order ID. Never retry an order without it.
- A websocket drop between send and acknowledgement leaves the order `Orphaned`. On reconnect, query by client order ID; never assume filled or canceled.
- On startup, reconcile positions and open orders with the exchange before trading.

## Pre-trade limits (in `engine/risk`, before the network call)

- Maximum order quantity, maximum position notional, maximum leverage.
- Price band against mark price, to catch fat-finger prices.
- Circuit breaker checked before every validation. Manual reset only.

## Failure handling

- Separate retryable errors (timeouts, rate limits) from final ones (insufficient margin, invalid parameters). Bounded retries with backoff.
- On a circuit-breaker trip: stop new orders, cancel open orders, alert. Whether to flatten is a configured policy, never improvised in code.
- Clock drift breaks signed requests: keep the VPS clock synced and use the exchange's receive window.
- Graceful shutdown: stop new orders, cancel resting ones, flush the log. Infra auto-shutdown must never kill the live box with open positions.

## Testing

- Changes to the order state machine need a stateful property test (see the `pbt` skill) or a replay test of recorded events.
- New live behavior runs on testnet, and in dry-run mode (orders logged, not sent), before mainnet.

## Review output

Findings in the deep-review format. Anything that could send an unintended order, exceed a limit or orphan an order without reconciliation is a `[blocker]`.
