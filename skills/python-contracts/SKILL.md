---
name: python-contracts
description: Rules for Python type contracts — overrides, Protocol conformance, variance, typed attributes and pyright error triage. Applies whenever writing or changing Python classes, Protocols, ABCs, overrides, test fakes, or fixing pyright errors.
user-invocable: false
paths: "**/*.py"
---

# Python contracts

## Overrides and Protocol implementations

An implementation must accept every call the base or Protocol accepts.

- **Parameter names match exactly** for positional-or-keyword parameters. A renamed parameter breaks keyword calls:
  ```python
  class ExecutionHandler(Protocol):
      def execute(self, order: OrderValidatedEvent) -> FillEvent | None: ...

  class Simulated:
      def execute(self, o: OrderValidatedEvent) -> FillEvent | None: ...  # breaks handler.execute(order=...)
  ```
- **Parameters may widen, never narrow** (contravariant): accepting `OrderEvent` where the base takes `OrderValidatedEvent` is fine; the reverse is not.
- **Return types may narrow, never widen** (covariant): returning `FillEvent` where the base returns `FillEvent | None` is fine; the reverse is not.
- No `*args/**kwargs` absorbing parameters the base declares explicitly.
- Keyword-only and optional parameters must stay keyword-only and optional.

After writing or touching any class passed as a Protocol, diff its methods against the Protocol: names, parameters, parameter names, types, optionality, return type.

## One source of truth per interface

Define an interface once: either a `Protocol` (structural, no inheritance needed) or an ABC (nominal, shared implementation). Not both for the same concept in different files. If both exist, flag it.

## Typed attributes

- Declare every mutable attribute's full type (class-body annotation or `self.x: T = ...`). Never rely on inference from `None` or a default.
- If an attribute is ever assigned a different type later, the declaration must include it: `self.last_fill: FillEvent | None = None`.
- Test fakes and mocks follow the same rule.

## Pyright triage

`reportAttributeAccessIssue` has two different causes; read the second line of the message.

- **"Attribute 'x' is unknown"**: the attribute does not exist on that class. Add it to the class, import the right class, or call the method that actually exists. Don't annotate an attribute on some other class; annotations are class-scoped.
- **"Expression of type Y cannot be assigned to attribute 'x' of type Z"**: the attribute exists but is declared too narrowly. Widen the declaration on the class the error names.

After fixing a Protocol conformance error, re-run pyright: the root error often masks downstream ones.

## Value objects vs capabilities

When a caller needs a capability (something that can sign, send, or write) but receives a value object (plain data), the missing piece is a method on the class that already holds the resource, returning the capability. Don't widen a frozen value object to carry secrets or handles to satisfy the caller. If two entry points must resolve the same underlying resource, share one resolution helper so they cannot drift.

## Report, don't guess

If a fix would change a public signature or a Protocol, say so and ask before doing it.
