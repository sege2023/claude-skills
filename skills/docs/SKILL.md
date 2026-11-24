---
name: docs
description: Create or update per-module READMEs, the root ARCHITECTURE.md, and ADRs for a domain-driven repo, keeping them in sync with the code. Use when the user asks for docs, a module README, an architecture overview or an ADR, or after a module's public interface or architecture changed.
argument-hint: "<module path> | arch | adr <title> | sync"
---

# Docs

Arguments: $ARGUMENTS

## Modes

- **`<module path>`**: create or update that module's `README.md` from [templates/module-readme.md](templates/module-readme.md).
- **`arch`**: create or update the root `ARCHITECTURE.md` from [templates/architecture.md](templates/architecture.md).
- **`adr <title>`**: write a new ADR from [templates/adr.md](templates/adr.md).
- **`sync`**: check every module README against the code and report drift.
- **No argument**: look at `git diff HEAD`, find modules whose public interface or structure changed, and update their READMEs.

## Rules

- **Docs describe the current state.** History belongs in commit messages and ADRs. Remove lines like "renamed X to Y".
- **Read, don't guess.** The public interface section comes from the code: `__init__.py`, `__all__`, Protocols, public classes and functions. Quote real signatures.
- **Generate file trees.** Run `tree -I '__pycache__|*.pyc|.pytest_cache' --dirsfirst -L 3 <path>` (or `find <path> -not -path '*/__pycache__*'` if `tree` is missing), then add a short comment per file from reading it.
- **Diagrams in mermaid**, only when three or more participants interact. Data flow in a module README, the module map in ARCHITECTURE.md.
- **One home per fact.** Cross-module flows go in ARCHITECTURE.md; module READMEs link to it rather than repeat it.
- **Keep what humans wrote.** When updating an existing README, edit in place and keep its TODOs and open questions. Remove one only when the code shows it resolved, and say so.
- About 200 lines per module README at most. If it needs more, the module is probably doing too much: say so.

## Sync mode

For each module with a README, compare the documented interface and file tree with the code. Report a table: module, what drifted, suggested fix. Apply fixes only after the user approves.

## ADRs

Write one when a decision had real alternatives and would be costly to reverse (a protocol choice, a storage engine, a signing scheme). Save as `docs/adr/NNNN-kebab-title.md`, numbered after the highest existing one. Status starts as `Proposed`; the user accepts it. Add it to the decisions index in ARCHITECTURE.md.
