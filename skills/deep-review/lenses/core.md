# Core lenses

Apply these at each trace step. They are questions to ask, not a checklist to paste.

## Boundaries
- What happens at 0, 1, -1, empty, None, max, and exactly at each threshold (`<` vs `<=`)?
- Off-by-one in slices, ranges, windows and pagination.
- Empty collections: does `max()`, `[0]` or division by `len()` crash or silently misbehave?

## Failure modes
- Every external call (network, DB, file, chain RPC, exchange API): what happens on timeout, error, partial response?
- Swallowed exceptions: `except Exception: pass`, or a log line with no re-raise and no fallback.
- A function that returns None on failure when it should raise. Check every caller handles the None.
- Retries: bounded, with backoff, and safe to repeat (see idempotency)?

## State and concurrency
- Idempotency: if this runs twice with the same input, is the result the same as running it once?
- Ordering: does the code assume events arrive in order? What if they don't?
- Race conditions: read-modify-write without a lock, transaction or atomic DB operation.
- Temporal coupling: must `a()` be called before `b()`? Is that enforced (constructor, return value passed in) or only remembered?
- State machines: is every transition explicit? Can an invalid transition happen?

## Data integrity
- Types at boundaries: parsed and validated where external data enters, not deep inside.
- Units, decimals and money: never float for money; consistent units (wei vs ether, bps vs %).
- Time: timezone-aware, UTC internally, consistent open-vs-close timestamps.

## Contracts (Python)
- An override or Protocol implementation must accept every call shape the base accepts: same parameter names, parameter types wider-or-equal, return type narrower-or-equal.
- No `*args/**kwargs` swallowing parameters the base declares explicitly.
- One source of truth per interface: not a Protocol in one file and an ABC for the same thing in another.
- Mutable attributes declared with their full type, never inferred from a `None` default.

## Readability as a bug detector
- **Cyclomatic complexity.** M = D + 1, where D is the number of decision points (`if`, `elif`, `for`, `while`, `except`, each `and`/`or` in a condition) and M is the minimum number of tests needed to cover every branch. Example: one `if`, one `for`, and one `if x and y` gives D = 1 + 1 + 2 = 4, so M = 5. Above about 10, flag the function: it is hiding edge cases nobody can see by reading.
- **Long dot chains** (`a.b().c().d`): each dot assumes the previous call never returns None.
- **Unnamed conditions**: `if x and not y and z > 3` hides intent. Extracting it into a well-named boolean often reveals the bug.
- **Missing else**: an `if` without `else` where the else case is possible. Is it truly impossible, or forgotten?

## Architecture
- Single responsibility: does each function, class and module do one thing?
- Module boundaries: does the change put logic in the module that owns that concern, or leak it across bounded contexts?
- Over-engineering: abstractions with one implementation and no real second use.
- New dependency: justified, maintained, pinned?

## AI-generated code
- Calls to APIs, methods or parameters that don't exist in the installed library version.
- Plausible-looking parameters that are accepted and never used.
- Tests that assert on the mock rather than on behavior.
- Defensive code that hides errors (broad try/except, default values that mask a missing input).

## Tests
- Would the tests fail if the logic were wrong, or do they only assert that code ran?
- Missing property, using one of these patterns:
  - **Round-trip**: `decode(encode(x)) == x`
  - **Invariant**: a quantity that must always hold (balance never negative, sum conserved)
  - **Idempotence**: `f(f(x)) == f(x)`, or processing an event twice equals once
  - **Oracle**: fast implementation matches a slow, obviously correct one
  - **Metamorphic**: a known relation between outputs (doubling size doubles PnL before fees)
  - **Stateful**: a `RuleBasedStateMachine` driving a lifecycle (orders, deposits, sweeps)
