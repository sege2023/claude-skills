---
name: pbt
description: Write property-based tests with Hypothesis alongside example-based pytest tests. Use when adding tests for logic with invariants, parsers or serializers, state machines, money or numeric code, signals or backtests, or when the user asks for property tests.
---

# Property-based testing

Example tests check the cases you thought of. Property tests state a rule that must hold for every input, and Hypothesis searches for an input that breaks it, then shrinks it to the smallest failing case.

## 1. State the property in one sentence first

"Processing the same deposit twice credits it once." If you can't say the property in a sentence, write example tests instead. Then pick the pattern it matches.

## 2. Patterns

| Pattern | Rule | Typical use |
|---|---|---|
| Round-trip | `decode(encode(x)) == x` | serialization, address encoding, config parsing |
| Invariant | a quantity always holds | balance never negative, money conserved |
| Idempotence | doing it twice equals doing it once | webhook replay, retries, upserts |
| Oracle | fast version equals a slow, obviously correct one | njit kernels vs plain Python |
| Metamorphic | a known relation between two runs | doubling size doubles PnL before fees |
| No lookahead | changing the future never changes the past | signals, features, labels |
| Stateful | invariants hold through any sequence of operations | order, deposit and sweep lifecycles |

Worked examples for each repo are in [examples.md](examples.md).

## 3. Strategies

- Build domain strategies once per module in `<module>/tests/strategies.py` (`deposit_events()`, `orders()`), not inline in each test.
- Constrain to valid inputs with strategy bounds, not `assume()`. Heavy `assume()` makes Hypothesis discard most examples.
- Money: integers in base units (`st.integers(min_value=0, max_value=10**24)` for wei) or `st.decimals(places=6, allow_nan=False, allow_infinity=False)`. Never floats.
- Large numeric arrays (price series): draw a seed and generate with numpy (`rng = np.random.default_rng(seed)`). You lose value shrinking, but avoid Hypothesis's size limits and keep runs fast.
- `st.builds(Cls, ...)` for dataclasses; `@st.composite` when fields depend on each other.

## 4. Settings

- In the root `conftest.py`, register profiles and pick one by env var:
  ```python
  import os
  from hypothesis import settings
  settings.register_profile("dev", max_examples=50)
  settings.register_profile("ci", max_examples=500)
  settings.load_profile(os.getenv("HYPOTHESIS_PROFILE", "dev"))
  ```
  CI sets `HYPOTHESIS_PROFILE=ci`.
- `@settings(deadline=None)` for anything that hits njit compilation or a DB.
- When Hypothesis finds a failure, keep it: add `@example(...)` with the shrunk input so it runs every time, forever.

## 5. Check the property bites

A property that can't fail is worthless. After writing one, break the code on purpose (flip a comparison, drop the idempotency check), confirm the test fails, then revert. Tell the user which deliberate bug you used.

## Where tests live

In the module's own `tests/` directory, next to its example tests, so each module stays self-contained. Mark slow property tests `@pytest.mark.slow`.

## When not to use it

Thin glue code, simple delegation, UI, or logic whose correct output you can't state without reimplementing it.
