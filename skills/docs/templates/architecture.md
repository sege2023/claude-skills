# Architecture

<Two or three sentences: what the system does and for whom.>

## Module map

```mermaid
graph LR
  <module_a> --> <module_b>
```

| Module | Owns | Depends on |
|---|---|---|
| `<module>/` | <one line> | <modules> |

## Key flows

<One short section per important end-to-end flow, each with a sequence diagram. Link module READMEs for detail.>

## Cross-cutting concerns

- **Configuration:** <where config lives, how it is loaded>
- **Errors and retries:** <the shared policy>
- **Logging and metrics:** <what is logged where>
- **Security boundaries:** <what is trusted, what is not>

## Decisions

| ADR | Title | Status |
|---|---|---|
| [0001](docs/adr/0001-<slug>.md) | <title> | Accepted |

## Running locally

<The few commands to get it running, or a link to the doc that has them.>
