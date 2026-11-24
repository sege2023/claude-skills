# <module_name>/

<One paragraph: what this module owns. Then one line on what it explicitly does NOT do, and which module does.>

## Public interface

<The names other modules may import, with real signatures. Everything else is internal.>

```python
class ExecutionHandler(Protocol):
    def execute(self, order: OrderValidatedEvent) -> FillEvent | None: ...
```

## File tree

```
<generated with tree, one comment per file>
```

## Data flow

<mermaid diagram, only if three or more participants>

## State and invariants

<State machines with every transition, and the rules that must always hold.>

## Inputs / outputs

- **Inputs:** <events, data, config this module consumes>
- **Outputs:** <events, data, files it produces>

## Dependencies

- **Depends on:** <modules>
- **Used by:** <modules>

## Testing

<How to run this module's tests, and what the property tests cover.>

## TODOs

- [ ] <open work>

## Open questions

- <decisions not yet made>
