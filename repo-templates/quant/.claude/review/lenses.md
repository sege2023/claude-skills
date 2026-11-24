# Repo lenses: quant stack

Copy to `<repo>/.claude/review/lenses.md`. deep-review treats these as mandatory.

## Lookahead and leakage
- A decision at bar t may use only data available at bar t's close. A signal computed on bar t's close fills no earlier than bar t+1's open.
- Watch for: `shift(-1)`, centered rolling windows, resampling with the wrong `label`/`closed` side, full-sample normalization (z-scores, scalers fit on all data), forward-fill across a gap that pulls a future value backward.
- Features, labels and the regime model are fit only on the training window of each walk-forward fold.

## Time and bars
- Timestamps in UTC. Be explicit whether a bar's timestamp marks its open or its close, and check every join agrees.
- Warm-up periods: indicators need N bars before they are valid. Are early NaN rows dropped consistently, without shifting the index?

## Fills, fees and funding
- Simulated and live execution implement the same `ExecutionHandler` interface. Check that the simulator's assumptions (fill price, partial fills, latency) are no more optimistic than live.
- Fees: maker vs taker, at the account's actual tier.
- Funding: payment = position notional × funding rate, charged at each funding timestamp. Notional is position size × mark price. Example: long 0.1 BTC at a mark price of 60,000 gives a notional of 6,000; at a rate of 0.01%, the long pays 6,000 × 0.0001 = 0.60 USDT for that interval. Read the instrument's funding interval from the exchange instead of hardcoding it.

## Orders and state (live paths)
- Order state transitions are explicit. A websocket drop mid-flight leaves the order `Orphaned`: reconcile by querying the order by client order ID on reconnect, never assume filled or canceled.
- Every order sent, canceled or filled is persisted to the durable log before being considered done.
- Position size and notional caps enforced before the order leaves the process.

## Research integrity
- Every backtest or parameter trial is recorded in the multiple-testing ledger, including the failures.
- Out-of-sample data is not touched during development. Repeated peeking turns it into in-sample.

## Engine boundaries
- Signal research, strategy research, portfolio, risk and execution each own their concern. Flag logic that lands in the wrong engine, e.g. sizing inside a signal, or fee modeling outside execution.
