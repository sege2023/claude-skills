# PBT examples

Names like `Ledger`, `deposit_events()` and `compute_signal()` stand in for your real modules. The shapes are what matter.

## Payments: webhook replay never double-credits (idempotence)

```python
from hypothesis import given
from .strategies import deposit_events


@given(event=deposit_events())
def test_replay_never_double_credits(event):
    ledger = make_ledger()
    ledger.process(event)
    once = ledger.balance(event.address)
    ledger.process(event)  # provider resends the same payload
    assert ledger.balance(event.address) == once
```

## Payments: money is conserved through any sequence (stateful)

Hypothesis generates random sequences of deliveries and replays, and checks the invariant after every step against a simple model.

```python
from hypothesis import strategies as st
from hypothesis.stateful import Bundle, RuleBasedStateMachine, invariant, rule

from .strategies import deposit_events


class LedgerMachine(RuleBasedStateMachine):
    delivered = Bundle("delivered")

    def __init__(self):
        super().__init__()
        self.ledger = make_ledger()
        self.seen: set[tuple[int, str, int]] = set()
        self.expected_total = 0  # the model: sum of unique deposits

    @rule(target=delivered, event=deposit_events())
    def deliver(self, event):
        self.ledger.process(event)
        key = (event.chain_id, event.tx_hash, event.log_index)
        if key not in self.seen:
            self.seen.add(key)
            self.expected_total += event.amount
        return event

    @rule(event=delivered)
    def replay(self, event):
        self.ledger.process(event)

    @invariant()
    def credited_matches_model(self):
        assert self.ledger.total_credited() == self.expected_total

    @invariant()
    def never_negative(self):
        assert all(b >= 0 for b in self.ledger.balances().values())


TestLedger = LedgerMachine.TestCase
```

## Quant: a signal never uses future bars (no lookahead)

Change only the bars after `cut`. Every signal value up to and including `cut` must be unchanged.

```python
import numpy as np
import pandas as pd
from hypothesis import given, settings, strategies as st


@settings(deadline=None)
@given(
    seed=st.integers(min_value=0, max_value=2**32 - 1),
    n=st.integers(min_value=300, max_value=800),
    cut_frac=st.floats(min_value=0.4, max_value=0.9),
)
def test_signal_has_no_lookahead(seed, n, cut_frac):
    rng = np.random.default_rng(seed)
    close = pd.Series(100 * np.exp(np.cumsum(rng.normal(0, 0.002, n))))
    cut = int(n * cut_frac)

    perturbed = close.copy()
    perturbed.iloc[cut + 1:] *= np.exp(rng.normal(0, 0.05, n - cut - 1))

    pd.testing.assert_series_equal(
        compute_signal(close).iloc[: cut + 1],
        compute_signal(perturbed).iloc[: cut + 1],
    )
```

This catches `shift(-1)`, centered windows, and full-sample normalization. Run it on every signal, feature and label builder.

## Quant: njit kernel matches a plain reference (oracle)

```python
@settings(deadline=None)
@given(seed=st.integers(0, 2**32 - 1), window=st.integers(min_value=5, max_value=200))
def test_rolling_ar1_matches_reference(seed, window):
    x = np.random.default_rng(seed).normal(size=window * 3)
    np.testing.assert_allclose(rolling_ar1_njit(x, window), rolling_ar1_slow(x, window), rtol=1e-9, equal_nan=True)
```

## Quant: PnL scales with size before fees (metamorphic)

```python
@given(fills=fill_sequences(), k=st.integers(min_value=2, max_value=10))
def test_gross_pnl_scales_linearly(fills, k):
    scaled = [f.with_qty(f.qty * k) for f in fills]
    assert gross_pnl(scaled) == pytest.approx(k * gross_pnl(fills))
```
