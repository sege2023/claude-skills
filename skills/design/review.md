# Design review

A second opinion from a reviewer who did not write the design and has not seen this conversation, so it judges the design on what's written, not on what was meant.

## 1. Find the design

The path given after `review`, or the most recent `Proposed` file in `docs/designs/`. If the design was only inline in the conversation, save it there first; the reviewer can only read files.

## 2. Spawn the reviewer

Start a fresh subagent (read-only; the Plan agent if available) with this brief, filled in:

> Review the design at `<path>` for this repo. Read it, then read CLAUDE.md, ARCHITECTURE.md, `.claude/review/lenses.md` if present, the README of every module it names, and the code it cites. Do not edit anything. Answer:
>
> 1. **Intent fit:** does the approach actually achieve the stated intent? Is anything in scope that the intent doesn't need, or missing that it does?
> 2. **Assumptions:** which listed assumptions does the code contradict? Which important assumptions are missing from the list?
> 3. **Ownership:** does each piece sit in the module that owns that concern? Any boundary crossed or logic duplicated?
> 4. **Interfaces:** are all affected callers listed? Grep to check.
> 5. **Production:** what breaks under failure, retries, concurrency, replays or bad input that the risks section doesn't cover? Apply the repo's lenses.
> 6. **Simpler:** is there a simpler design that meets the same intent?
> 7. **Steps and tests:** does each step leave the code working? Would the tests catch the main risks?
>
> Cite `file:line` for every claim about the code. Tag each point `[blocker]`, `[major]`, `[nit]` or `[question]`. End with a verdict: **approve**, **revise**, or **rethink**, and the one change that matters most.

## 3. Relay

Show the reviewer's points and verdict unchanged. Then, separately, give your own take on each `[blocker]` and `[major]`: agree, or disagree with a reason. Don't revise the design until the user decides which points to take.
