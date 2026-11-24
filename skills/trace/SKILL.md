---
name: trace
description: Trace how one concrete input flows through the codebase across modules, as numbered steps plus a sequence diagram. Use when the user asks how something works, where a value goes, what happens when X occurs, or wants a walkthrough of a flow.
argument-hint: "[learn] <scenario or entry point>"
---

# Trace

Follow one realistic input through the real code, step by step, across files and modules. The output should let someone who has never read the code explain the flow.

Arguments: $ARGUMENTS

## 1. Pick the entry point and the input

- Find where the scenario enters the system: an API route, webhook handler, event subscriber, CLI command, scheduled job, or a backtest loop. Grep for it; never guess from names.
- Choose one concrete, realistic input with actual values (an order of 0.01 BTC at 64,250; a USDC deposit of 25.00 on chain 8453), not a placeholder.
- If the scenario is ambiguous, ask which path the user means before tracing.

## 2. Follow it

At each step, read the function body and record:
- `file:line function` and what happens to the value (validated, transformed, stored, dropped).
- Side effects: DB writes, network calls, events published, logs, files written.
- Branch points: the condition, and which way this input goes.

Rules:
- Read the code at every step. If a step is inferred rather than read, mark it `(inferred)`.
- Async boundaries (queue, event bus, webhook, scheduled job): say what crosses the boundary, then continue on the consumer side.
- Stop at third-party library calls. Describe the contract you rely on (what it returns, what it raises), don't trace inside it.
- Follow the happy path to the end first. Then go back and follow each failure branch one level: where does it go, what state is left behind?
- More than about 25 steps: collapse sub-flows into one line each and offer to expand any of them.

## 3. Output

1. **One sentence**: what this flow does end to end.
2. **Sequence diagram** in mermaid `sequenceDiagram`. Participants are modules or services, not individual functions.
3. **Steps**, numbered: `n. file:line function → what happens to the value`.
4. **Branches not taken**: each condition you passed and where its other side goes.
5. **Invariants this flow relies on**: things that must be true for it to work (an index exists, events arrive in order, a config key is set).
6. **Surprises**: anything that looked wrong or fragile. Flag it, don't fix it, and suggest `/deep-review` if any look serious.

## Learn mode

With `learn` as the first argument, pause twice during the walkthrough and ask the user to predict the next step ("the event is published here; which module picks it up, and what does it do with the amount?") before revealing it. When a concept is new to them, explain it by mapping it to something they already know.
