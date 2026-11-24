---
name: research-integrity
description: Check research outputs and research code for lookahead, leakage, selection bias and cost errors before trusting a result. Use when analyzing backtest, walk-forward, signal or regime outputs (run output folders, ledger trials), reviewing research code, or when the user asks whether a result is real.
argument-hint: "[outputs <run path> | code <path>]"
---

# Research integrity

In research, a bug doesn't crash. It produces a result that looks good and isn't. Assume a strong result is wrong until it survives these checks.

Arguments: $ARGUMENTS

## Analyzing outputs

1. **Provenance.** Read `run_manifest.json` and `config_snapshot.json`: symbol, bar size, data window, fees, funding, slippage, git commit, and which regime run supplied the labels. If provenance is missing, say the result can't be trusted yet and stop.
2. **Selection bias.** Count the ledger trials that produced this candidate and its family. The best of many trials looks good by luck alone (see "Selection bias" below).
3. **Costs.** Confirm fees (baseline 11 bps round trip), funding and slippage are applied. Compare turnover × cost against gross edge.
4. **Sample size.** Count trades, not bars. With overlapping holding periods, the number of independent observations is closer to bars ÷ holding period.
5. **Stability.** Look at per-fold metrics: sign consistency, dispersion, whether failures cluster in calendar periods, whether results hold for neighboring parameters, and how PnL splits across regimes.
6. **Verdict.** One of: **credible**, **fragile**, or **invalid**, with the top reasons and the single next test that would most change your confidence.

## Reviewing research code

- **Lookahead:** `shift(-n)` outside target construction, centered rolling windows, resampling with the wrong `label`/`closed` side, forward-fill across gaps. Recommend the no-lookahead property test from the `pbt` skill for every signal, feature and label builder.
- **Fold leakage:** anything fit on data (scalers, z-score parameters, quantile thresholds, regime models) must be fit on the training fold only and applied frozen to the test fold. Thresholds from full-sample quantiles are the most common leak.
- **Alignment:** targets built with `shift(-h)` never appear as features. Joins use the raw bar index, not each signal's trimmed output.
- **Statistics:** overlapping horizons need HAC (Newey-West) standard errors. Sharpe must be annualized the same way everywhere (see below).
- **Ledger:** every trial loop writes to the ledger, including failed and discarded variants.

## Selection bias

If no strategy has real edge, each trial's Sharpe estimate is noise around zero with some standard deviation σ (the spread of Sharpe estimates across trials). The best of N such trials is expected to land at about k(N) × σ, where k(N) is the expected maximum of N standard normal draws:

| N trials | k(N) |
|---|---|
| 10 | 1.54 |
| 100 | 2.51 |
| 1,000 | 3.24 |

Example: 100 trials whose Sharpe estimates spread with σ = 0.5. The best one is expected to show about 2.51 × 0.5 ≈ 1.25 annualized Sharpe from luck alone. A winner at 1.3 is no evidence of edge; it needs to clear that bar by a wide margin and hold out of sample.

## Sharpe annualization

Annualized Sharpe = (mean per-bar return ÷ std of per-bar returns) × √B, where B is the number of bars per year.

For 5-minute bars on a 24/7 market, B = 288 bars/day × 365 = 105,120, and √B ≈ 324.2. Example: a mean per-bar return of 0.00002 with a per-bar std of 0.002 gives 0.01 × 324.2 ≈ 3.24. Mixing per-trade, per-day and per-bar scaling between functions makes trials incomparable; check every Sharpe in a comparison uses the same B.

## Output

Findings in the deep-review format (`[blocker]`, `[major]`, `[nit]`, `[question]`, with "Why it matters" and "Fix"), then the verdict when analyzing outputs.
