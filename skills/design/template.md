# Design: <title>

- **Status:** Proposed | Approved | Implemented | Abandoned
- **Date:** <YYYY-MM-DD>
- **Request:** <the user's words, quoted>

## 1. Intent

You want <X> so that <Y>.

## 2. Assumptions to confirm

1. <Assumption, phrased as a yes/no question>? <If no: how the design changes.>
2. ...

## 3. Scope

- **Changes:** <what will be built or changed>
- **Does not change:** <what is explicitly left alone, including tempting adjacent work>

## 4. Where it lives

| Piece | Module (owner) | New or changed |
|---|---|---|
| <piece> | `<module>/` | <new file / changed function> |

**Interface changes:** <signatures, Protocols, schema, events, config keys, API contracts; each with the callers affected, `file:line`. "None" if none.>

## 5. Approach

<How it works, in a short paragraph or numbered flow. A mermaid sequence diagram if three or more modules interact.>

**Alternative considered:** <option>. Not chosen because <reason>.

## 6. Risks

- <What could go wrong in production, and how the design handles it.>

## 7. Tests

- **Example tests:** <cases>
- **Properties:** <invariants for `/pbt`, e.g. "replaying a webhook never changes balances">

## 8. Steps

1. <Commit-sized step> — `<type(scope): subject>`
2. ...

## Open questions

<The assumptions above that still need an answer, restated briefly.>

## Log

- <YYYY-MM-DD>: Proposed.
