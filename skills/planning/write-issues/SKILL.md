---
name: write-issues
description: Decompose a PRD (or sufficiently-shaped plan) into ranked, agent-ready GitHub Issues. Each issue is sized to <10 min review, has acceptance criteria as test cases, explicit out-of-scope, invariants, and topological dependencies. Use when the user invokes `/write-issues`, says "write the issues", "decompose this into issues", "create the GH issues", or naturally needs to take a PRD to a queue. Output is a markdown draft at `~/.claude/plans/<slug>-issues.md` for review, then optionally `gh issue create`. NEVER auto-creates on GitHub without explicit confirmation. Skip for trivial work (single-file changes, bug fixes the user can describe in one sentence).
tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# Write Issues

Decompose a PRD (or sufficiently-shaped plan) into ranked, agent-ready GitHub Issues. Each issue is sized for fast review and unambiguous autonomous execution.

## When to apply this skill

**Apply it for:**
- After `/write-prd` produced a PRD
- A plan that's been refined and is ready for execution
- Any feature where multiple PRs are needed and the work needs to be queued

**Skip it for:**
- Trivial single-PR work (one file, <50 lines change)
- Bug fixes the user can describe in one sentence
- Asks where the user has already decided exactly what one PR should contain

## Core constraints

- **Each issue's PR must be reviewable in <10 minutes.** Hard cap. Bigger → split.
- **Topologically ordered.** Issues you can start now first; blocked ones below their blockers.
- **Match existing repo labels — never invent new ones.** If a needed label is missing, flag it, don't auto-create.
- **Never auto-create on GitHub.** The output is a markdown draft for the user to review. After approval, offer `gh issue create` per-issue or bulk.
- **Architecture / security / ambiguity → `needs-human-decision`.** Those issues stay in the human queue, not the agent queue.

## Workflow

### 1. Locate the source

In order of preference:
1. The most recent `~/.claude/plans/<slug>-prd.md` from `/write-prd` (Glob, sort by mtime).
2. A PRD or plan file the user explicitly references.
3. The most recent grill-me plan (`~/.claude/plans/<slug>.md`) if no PRD exists.
4. Conversation context if no plan file exists.

If nothing is identifiable, ask once: *"Which PRD or plan should I decompose?"* — then stop.

### 2. Read the surrounding context

Before drafting:
- Read the source PRD/plan in full
- Read `AGENTS.md` for project conventions
- Run `gh label list` to know which labels exist
- Run `git status` to know what's in flight (don't propose issues that overlap uncommitted work or live worktrees without flagging)
- Skim referenced files so issue file paths are real

### 3. Decompose into issues

Each issue is **independently shippable** (or has explicit dependency markers). Walk the PRD's phases — each phase usually maps to 1–N issues.

For each unit of work, ask:
- **Can a reviewer skim the resulting PR in <10 min?** If no, split.
- **Is the unit independently mergeable?** If no, mark dependencies explicitly.
- **Does it touch architecture / security / ambiguous decisions?** If yes, label `needs-human-decision`.

### 4. Size each issue

- **`size/S`** — 1 file, <50 lines change. Quick PR, fast review.
- **`size/M`** — multi-file, <200 lines change. Standard agent unit of work.
- **`size/L`** — too big. Apply this label only if the issue *cannot be split further* (rare). Default action when an issue would be `size/L`: **split it into multiple `size/M`s**.

### 5. Match labels — never invent

Run `gh label list` first. Use only the labels that exist.

If a label is missing that you'd genuinely want (e.g., `migration`, `infra`, etc.), surface it:

> "I'd like to use a label `<name>` but it doesn't exist on the repo. Run `gh label create <name>` if you want it, or I can drop it from the issues."

Do not auto-create labels.

### 6. Topologically order

Order issues so that anything an executor (autonomous agent or human) could start *now* comes first; blocked issues come below their blockers, with `blocked-by:#<n>` markers in the body.

GitHub does not have a native "blocked-by" mechanism without ZenHub or similar — use a body line `**Blocked by:** #<n>` and rely on the agent (and you) to respect it.

### 7. Write the markdown draft

Output to `~/.claude/plans/<slug>-issues.md`. Format:

```markdown
# Issues for <PRD title>

Source PRD: `~/.claude/plans/<slug>-prd.md`

---

## Issue 1: <Imperative title — "Add X", not "X">

**Labels:** `agent-ready`, `size/S`, `enhancement`
**Blocked by:** *(none — ready now)*
**PRD section:** [Phase 1](path/to/prd.md#phase-1-name)

### Context
<1–2 sentences. What this issue does and why.>

### Files to touch
- `src/components/Foo.jsx` — <brief role>
- `src/data/quizEngine.js` — <brief role>

### Acceptance criteria
- [ ] Given <state>, when <action>, then <observable outcome>
- [ ] Given <state>, when <action>, then <observable outcome>
- [ ] `npm run lint && npm run build && npm run test:e2e` all green

### Out of scope
- <Explicit "do not do X" — mirrors PRD non-goals>
- <Explicit "do not refactor adjacent Y, even if it looks wrong">

### Invariants to preserve
- <e.g., XP stays client-side per ADR-003>
- <e.g., existing e2e tests still pass>

---

## Issue 2: <...>

*(same structure)*

---

## Summary

| # | Title | Size | Labels | Blocked by |
|---|-------|------|--------|------------|
| 1 | <title> | S | agent-ready, enhancement | — |
| 2 | <title> | M | agent-ready, enhancement | #1 |
| 3 | <title> | M | needs-human-decision | — |
```

### 8. Show the user, then offer to create

After writing the markdown:

1. Tell the user: *"Issues drafted at `~/.claude/plans/<slug>-issues.md`. Review the file, then tell me when you want me to create them on GitHub."*
2. Wait for explicit go-ahead. Do not auto-create.
3. When the user says go, offer two modes:
   - **Per-issue confirmation** (default): `gh issue create` one at a time, you confirm each title before it's created
   - **Bulk** (faster, riskier): create all at once after one confirmation

Use `AskUserQuestion` to pick. Default the recommendation to **per-issue confirmation** unless the user has already said "create them all."

### 9. Create on GitHub

For each issue:

```bash
gh issue create \
  --title "<title>" \
  --body "<body assembled from Context + Files + Acceptance + Out-of-scope + Invariants + Blocked-by>" \
  --label "<comma-separated existing labels>"
```

After creation:
- Capture the returned issue number
- Update the markdown draft with the GH issue URLs (so the file becomes a record of what was created)
- For issues that were `blocked-by` placeholder issue numbers in the draft, post-process: edit the created issue body to replace placeholder #N with the real GH number after dependencies are created

### 10. Final report

End with:

> "Created N issues on `<repo>`. Markdown draft at `~/.claude/plans/<slug>-issues.md` updated with GitHub URLs. Issues labeled `agent-ready` are ready for `claude-code-action` pickup once that's wired up."

## Output discipline

- **No invented labels.** If you want one and it doesn't exist, surface it; don't auto-create.
- **No auto-creation on GitHub without confirmation.** Issues are visible work; bad issues = visible bad work.
- **No oversized issues.** If you find yourself writing a `size/L`, split first. Only apply `size/L` to genuinely-indivisible units.
- **No prose in the issue body.** Bullets > paragraphs. Acceptance criteria > requirement narrative.
- **No "Definition of Done" boilerplate.** Acceptance criteria + invariants cover it.
- **Mirror PRD non-goals as per-issue out-of-scope.** Autonomous executors enforce out-of-scope at the issue level — they don't go re-read the PRD for it.
