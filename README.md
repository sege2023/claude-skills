# Claude Code skills

## Layout

```
claude-skills/
├── global/CLAUDE.md                  → ~/.claude/CLAUDE.md (applies in every repo)
├── skills/                           → ~/.claude/skills/ (global methods)
│   ├── design/                       intent + assumptions + plan before code; review by a fresh subagent
│   ├── deep-review/                  behavior-first review, learn and audit modes, PR targets (+ infra lens)
│   ├── trace/                        follow one input through the code
│   ├── commit/                       atomic Conventional Commits by module
│   ├── pr/                           stacked PRs from commits, promotion PRs (+ templates)
│   ├── verify/                       runs scripts/verify.sh (+ template)
│   ├── pbt/                          Hypothesis property tests (+ examples)
│   ├── docs/                         module READMEs, ARCHITECTURE.md, ADRs (+ templates)
│   └── python-contracts/             background rules, auto-loads on .py files
└── repo-templates/                   copy into each repo's root
    ├── payments-infra/
    │   ├── CLAUDE.md
    │   ├── .pre-commit-config.yaml
    │   ├── policy/compose.rego
    │   └── .claude/
    │       ├── review/lenses.md
    │       └── skills/security-payments/  (SKILL.md, threat-model.md, predeploy.md)
    └── quant/
        ├── CLAUDE.md
        └── .claude/
            ├── review/lenses.md
            └── skills/
                ├── research-integrity/
                └── live-execution-safety/   (loads only for live-path files)
```

## Install

```bash
cd ~/path/to/claude-skills

# 1. global
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
cp -n global/CLAUDE.md ~/.claude/CLAUDE.md        # -n: won't overwrite an existing one

# 2. per repo (-n never overwrites files you already have)
cp -rn repo-templates/payments-infra/. ~/path/to/payments-infra/
cp -rn repo-templates/quant/. ~/path/to/quant-repo/

# 3. in each repo: the verify script
mkdir -p scripts && cp ~/.claude/skills/verify/verify.sh.template scripts/verify.sh && chmod +x scripts/verify.sh
```

Then in each repo:
1. Open a new Claude Code session there and run `/skills`. You should see your skills listed, separate from the ones synced from claude.ai.
2. The two CLAUDE.md files were drafted from notes, not from your trees. Ask Claude Code: "Check CLAUDE.md's Layout and Commands sections against the actual repo and fix anything wrong." Then delete the comment at the top.
3. payments-infra: run `/security-payments update` once to fill in the threat model's status column from the code.
4. Commit `.claude/`, `CLAUDE.md`, `policy/` and `.pre-commit-config.yaml` so cloud sessions and future teammates get them.

## If a skill doesn't show up

- If `~/.claude/skills/` didn't exist when the session started, Claude Code isn't watching it. Run `/reload-skills` or start a new session.
- Skills synced from your claude.ai account (like `/deep-research`) and bundled skills appear alongside yours; that's normal.
- `commit` and `pr` only run when you type them. That's deliberate (`disable-model-invocation: true`): both change shared state.
- `python-contracts` doesn't appear in the `/` menu (`user-invocable: false`). Claude loads it on its own when working on `.py` files.
- Other skills load automatically only when your request matches their description. You can always invoke them directly.

## Commands

| Command | What it does |
|---|---|
| `/design add retry for failed sweeps` | Intent, assumptions, scope, approach, steps; then waits for your go |
| `/design review` | Fresh subagent critiques the latest saved design |
| `/deep-review` | Review uncommitted changes, ending with one question |
| `/deep-review learn engine/execution/` | Teaching walkthrough of existing code |
| `/deep-review audit main..HEAD` | Review a branch by a fresh subagent |
| `/trace learn a deposit webhook arriving twice` | Step-by-step flow, with predictions |
| `/pbt` | Write property tests for the current change |
| `/docs engine/execution` | Create or update that module's README |
| `/docs sync` | Report README drift across modules |
| `/docs adr erc4337-vs-permit` | Write an ADR |
| `/verify` | Run checks and fix failures at the root |
| `/commit` | Propose an atomic split, then commit |
| `/pr plan` | Slice unpushed commits into stacked PRs; changes nothing |
| `/pr open` | Create branches at the slice tips, check each tip, push, open the PRs |
| `/pr land` | After the bottom PR merges: retarget the next one and restart its CI |
| `/pr promote dev staging` | Promotion PR: included PRs, migrations, config, rollback |
| `/deep-review audit #42 --post` | Independent review of a PR, posted as one comment |
| `/security-payments triage` | Classify pasted scanner findings |
| `/security-payments predeploy` | Walk the deploy checklist with evidence |
| `/research-integrity outputs outputs/run_042` | Credible, fragile or invalid verdict |

## design

`/design` runs only when you type it. The automatic case is covered by the "Before changing code" rule in `global/CLAUDE.md`: risky or vague requests pause for your answers, clear ones go straight through with a one-line list of assumptions. If you already have a `~/.claude/CLAUDE.md`, the install's `cp -n` won't overwrite it, so paste that section in by hand.

Full designs are saved to `docs/designs/` with a status (Proposed → Approved → Implemented), so you can hand one to a fresh session. Works well inside plan mode (Shift+Tab), which blocks edits while you read the design.

## verify

`verify` delegates to each repo's `scripts/verify.sh`. Repos customize the script, not the skill, because a personal skill beats a project skill with the same name. Because it's named `verify`, Claude Code runs it before each commit Claude makes. It replaces the bundled `/verify`; `/run` is unaffected.

Set `VERIFY_RUNNER="poetry run"` or `VERIFY_RUNNER=""` if a repo doesn't use uv. Mark slow tests (njit compilation, long backtests) with `@pytest.mark.slow`, register the marker in pyproject.toml, and have CI run `VERIFY_FULL=1 ./scripts/verify.sh`.

## Security gates (payments-infra)

```bash
pipx install pre-commit checkov     # conftest: github.com/open-policy-agent/conftest
pre-commit install && pre-commit autoupdate && pre-commit run --all-files
```

Enable ruff's bandit rules in pyproject.toml:

```toml
[tool.ruff.lint]
extend-select = ["S"]

[tool.ruff.lint.per-file-ignores]
"**/tests/**" = ["S101"]   # assert is fine in tests
```

The compose policy blocks ports published on all interfaces (Docker bypasses UFW), privileged containers, and literal secrets in `environment`. It warns on untagged or `:latest` images.

## Notes

- `deep-review`, `commit`, `pr` inject `git` output when they load. In a directory that isn't a git repo, or a repo with no commits yet, the invocation aborts.
- `research-integrity` is committed to the quant repo so cloud sessions load it. Cloud sessions only see what's in the repo or reachable from it, so push the run outputs (or put them in storage the session can read) before asking it to analyze them.
- Not written yet, on purpose: an infra-safety skill for the quant `infra/` (Terraform, VPS auto-shutdown). Write it once that code exists.
