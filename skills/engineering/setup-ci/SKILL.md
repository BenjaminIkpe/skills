---
name: setup-ci
description: Generate a CI workflow tailored to a project's stack, applying opinionated, non-default best practices the base model skips (least-privilege tokens, path-agnostic required checks, action pinning, dependency caching, secrets hygiene, artifacts-on-failure, concurrency control), then wire the required status check via branch protection. Use when the user says "set up CI", "add CI", "add a GitHub Actions workflow", bootstraps checks for a new repo, or wants to audit/harden existing CI. Skip if the repo already has comprehensive, well-secured CI and the user hasn't asked to review it.
tools: Read, Glob, Grep, Bash, Write, Edit
---

# setup-ci

Generate CI that matches THIS project and applies every rule in `principles.md`.
The stack detection is the easy part; the principles are why this skill exists —
ask Claude cold and you get the lint/build/test skeleton but almost never the
least-privilege token, the path-agnostic required check, concurrency control, or
the branch-protection wiring. Those are the payload.

**Before generating, read `principles.md` in full.** A generated workflow that
violates any principle is wrong, not just suboptimal.

## Workflow

### 1. Detect the stack (don't ask what you can read)
- `package.json` → Node. Read `scripts` and use the **real** `lint`/`build`/`test`/`test:e2e` names — never invent script names that don't exist.
- `requirements.txt` / `pyproject.toml` / `setup.py` → Python. Find the test runner (pytest?) and a cheap import/syntax smoke target.
- `docker-compose.yml` / `compose.yaml` → multi-service; `docker compose config --quiet` is a free validity gate.
- Test deps present (`playwright`, `pytest`, a `db/tests` dir, `vitest`, `jest`) → which test layers actually exist. Only gate layers that exist.
- Existing `.github/workflows/*.yml` → **audit against `principles.md` and propose edits**, do not blindly overwrite.
- Pull concrete step snippets + the caching/pinning defaults from `recipes/<stack>.md`.

### 2. Clarify only what you cannot infer (max 3 questions)
- Which branches are protected? (drives triggers + which check is *required*)
- Which single check should be the *required* status check?
- Checks-only, or is there a deploy step?

If the answers are obvious from the repo (single `main`, one test command), state your assumption and proceed instead of asking.

### 3. Generate
Assemble the workflow(s) from `recipes/<stack>.md` and apply **every** principle in `principles.md`. Where a principle is non-obvious, leave a one-line `# why` YAML comment citing it — the explanatory comments are the house style, and they make the file teach the next reader.

### 4. Split path-scoped jobs correctly
If some jobs only matter for certain paths (db/data, docs), keep **one path-agnostic always-runs gate** as the *required* check, and make path-filtered jobs separate and non-required — see principle `[REQUIRED-CHECK]`. This is the single most important structural decision; get it wrong and PRs deadlock.

### 5. Wire branch protection (the YAML gates nothing by itself)
A workflow file only *runs*; branch protection is what *blocks a merge*. After the file lands, set the required status check via `gh api`, ensuring the name exactly matches the generated job's `name:`. **Confirm with the user before changing protection** — it is an outward-facing repo setting.

### 6. Verify and hand off
Run `actionlint` if available, else parse the YAML. Tell the user (a) the exact check name they will see on a PR, (b) what it gates, and (c) the one local command that reproduces each CI step (`[REPRO]`).

## Hard rules
- Never invent npm/make/script names — use only what the manifest defines.
- Never widen `permissions` beyond what a specific job needs.
- Never mark a path-filtered workflow as a required check (`[REQUIRED-CHECK]`).
- Generate fresh against current action versions — do not paste a frozen template.
- Changing branch protection requires explicit user confirmation.

## Composes with
This skill does CI only. For commit-time checks use `setup-pre-commit`; for repo
guardrails use `git-guardrails`. Don't absorb them — keep this small.
