<!-- Drafted from notes, not from the tree. Check the Layout and Commands sections against the repo, fix anything stale, then delete this comment. -->

# Quant stack: BTCUSDT perps research and runtime

Two kinds of code live here:
- **Research** (signal, strategy, regime, portfolio research engines): correctness matters most; hardening does not.
- **Live paths** (`engine/execution` venue adapters and order state, `engine/risk`, observability): production standard. These can send real orders on Bybit.

## Layout (bounded contexts)

- `core/` — types, frozen event dataclasses, interfaces (Protocols), event bus
- `engine/` — event-driven runtime: `backtest/`, `execution/`, `portfolio/`, `risk/`, `strategy/`
- observability — circuit breaker, event logger, alerting, heartbeat, reconciliation, `outputs/<run_id>/` writer
- `regime_engine/` — AR-HMM and hysteresis regime labels
- `signal_research_engine/` — signals, IC/HAC analysis, WFA validation
- `strategy_research_engine/` — vectorized backtester, sizing, stops
- `portfolio_management_engine/` — design-time PortfolioSpec
- `research_infra/` — multiple-testing ledger (append-only parquet), WFA adapters, shortlist selection
- `shared/data/loaders/get_data.py` — data access; reads the storage tree, never venue scripts

Each engine owns its concern. Put new code in the engine that owns it; never scatter one feature across engines. If it's unclear where something belongs, ask.

## Runtime event loop

MarketEvent → Strategy → SignalEvent → Portfolio.size() → OrderTargetEvent → RiskManager.validate() → OrderValidatedEvent → Execution → FillEvent → Portfolio.on_fill()

- Events are `@dataclass(frozen=True, slots=True)`.
- One `EventBus` per run (not a singleton), so walk-forward folds are isolated.
- Rejected and Orphaned orders are always published to the bus.
- Simulated and Bybit execution implement one `ExecutionHandler` interface. `execute()` can return None (resting or rejected order).

## Commands

- Checks: `./scripts/verify.sh` (slow tests skipped locally; CI runs `VERIFY_FULL=1`)

## Research rules

- Every backtest or parameter trial goes into the `research_infra` ledger, failures included.
- Signals are computed on raw bars. Regime labels used in signal research are stitched out-of-sample labels.
- Baseline fees for BTCUSDT backtests: 11 bps round trip.
- Join signals on the raw bar index, not on each signal's own `dropna()` output; each lookback trims a different number of leading rows.
- Full review lenses: `.claude/review/lenses.md`. Before trusting any result, use the `research-integrity` skill.

## Never

- Use data from bar t+1 or later in a decision at bar t.
- Fit scalers, thresholds, quantiles or regime models on data outside the training fold.
- Hardcode the funding interval; read it from the exchange.
- Commit API keys or point anything at Bybit mainnet without an explicit instruction.
