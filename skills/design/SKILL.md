---
name: design
description: Outline the implementation design for a task before any code is written — intent, assumptions to confirm, scope, module ownership, approach, risks, tests and steps — then wait for approval. Review mode sends a saved design to a fresh subagent for critique.
disable-model-invocation: true
argument-hint: "<task> | review [design file]"
---

# Design

The point is to catch a mismatch between what the user meant and what you understood before it turns into code. A design is cheap to correct; an implementation built on a wrong assumption is not. Optimize for the user spotting a wrong assumption fast, not for completeness.

Arguments: $ARGUMENTS

If the first argument is `review`, follow [review.md](review.md) instead.

If the request is a question about how existing code works rather than a change, answer it (or suggest `/trace`) instead of writing a design.

## 1. Explore first, read only

Never design from guesses. Before writing anything:
- Read CLAUDE.md (already loaded), `ARCHITECTURE.md`, and the README of every module the task touches.
- Read the code the task will change and the code that calls it. Find existing patterns to follow; prefer extending what exists over adding a new abstraction.
- Check `docs/adr/` and `docs/designs/` for decisions that constrain this task.
- Make no edits during exploration.

## 2. Pick the depth

- **Small** (one module, no interface change, under ~3 files): sections 1–3 of the template, inline, a few lines each. No file.
- **Full** (new module, interface or schema change, money or order paths, more than one module, or the user says "full"): the whole template in [template.md](template.md), saved to `docs/designs/YYYY-MM-DD-<slug>.md` with status `Proposed`.

When unsure, go full.

## 3. Write the design

Follow [template.md](template.md). Rules:
- **Intent first, in one sentence**, in the form "You want X so that Y." If you can't fill in "so that", that's the first question.
- **Assumptions are numbered yes/no questions**, most consequential first. Include the ones that feel obvious: those are where misreadings hide. If an assumption would change the design substantially depending on the answer, say how.
- **Ground every claim in the code:** cite `file:line` for existing behavior, interfaces and callers.
- **Respect module ownership:** place each piece in the module that owns that concern. If ownership is unclear, that's an assumption to ask about, not a decision to make silently.
- **One real alternative**, and why it lost. No straw men.
- **Steps are commit-sized:** each one leaves the code working and could be reviewed and committed alone.
- No code beyond signatures and short schema or interface snippets.

## 4. Stop

End with the open questions restated and: "Waiting for your go. Reply with answers, changes, or `/design review` for a second opinion." Do not edit code until the user approves.

## 5. After approval

- Fold the user's answers and changes into the design file, mark it `Approved`, and note any changed decisions in its log.
- Implement step by step, in the order given. Run `/verify` (or `./scripts/verify.sh`) after each step.
- **If implementation contradicts the design** (an assumption turns out false, an interface differs from what you read, a step needs a different module), stop. Explain the deviation, propose the design change, and wait. Don't silently adapt.
- When done, mark the design `Implemented`. If it records a decision with real alternatives that is costly to reverse, suggest `/docs adr` for it.
