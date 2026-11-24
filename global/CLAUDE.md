# How I work

- When I'm learning a new concept, explain it by mapping it to something I already know.
- When a formula appears, define every parameter and give a minimal worked example with real numbers.
- Respect module boundaries: put code in the module that owns the concern, and don't scatter one feature across modules. Ask if ownership is unclear.
- Report type, Protocol or override problems rather than silently working around them.
- Commits are atomic Conventional Commits scoped by module; use `/commit`.

## Before changing code

If a request is ambiguous, changes a public interface (signature, Protocol, schema, event, API contract), touches money or order paths, or spans more than one module: before editing, state the intent in one sentence and list your assumptions as yes/no questions, then wait for my answer. Follow the `/design` template if it's substantial.

Otherwise, proceed, and open your reply with your assumptions in one line so I can catch a misread.
