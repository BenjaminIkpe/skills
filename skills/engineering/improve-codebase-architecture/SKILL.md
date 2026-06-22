---
name: improve-codebase-architecture
description: Scan the codebase for shallow-module clusters and architectural drift, propose deep-module refactors with simple interfaces. Propose only — execution happens collaboratively after agreement, outside the skill run. Use when the user invokes `/improve-codebase-architecture`, says "deepen modules", "find architectural drift", "find refactor opportunities", or signals the codebase is hard to change. Output is a ranked list of opportunities at `~/.claude/plans/<slug>-architecture.md`. Skip for greenfield projects, single-file projects, or codebases the user is actively rewriting.
tools: Read, Glob, Grep, Bash, Write
---

# Improve Codebase Architecture

Scan for shallow-module clusters and architectural drift. Propose deep-module refactors. **Propose only — execution is collaborative and happens after agreement, outside the skill run.**

## When to apply this skill

**Apply it for:**
- Codebases that feel hard to change ("touching X breaks Y")
- Code an autonomous agent has trouble with (long context, hard-to-reason boundaries)
- Periodic architecture audits between major features
- After a feature ships and it's clear some module shape needs to change

**Skip it for:**
- Greenfield projects (nothing to deepen)
- Codebases under active rewrite (output collides with in-flight work)
- Single-file scripts or tools

## Core principle: deep modules

Per Ousterhout's *A Philosophy of Software Design*: a **deep module** has lots of functionality behind a simple interface. A **shallow module** has little functionality and a wide interface (or many tiny modules clustered around a domain that callers must navigate).

For AI executors, deep modules matter more than for humans:
- Smaller surface area = less context to load
- Single entry point = one thing to call, not five
- Hidden complexity = the executor doesn't need to know it

But: **a deep module with a weak interface doc is worse than a shallow one with clear naming.** The interface text is now load-bearing.

## Workflow

### 1. Read the lay of the land

Before scanning:
- `AGENTS.md` — project conventions
- `Sage Vault/Architecture/App Architecture.md` (if it exists) — the documented module map
- Any recent ADRs in `Sage Vault/Architecture/`
- `git status` and active branches/worktrees — **skip clusters that overlap uncommitted work or live worktrees**

### 2. Scan for shallow signals

Use Glob + Grep + small Bash analyses to find:

**Shallow-cluster signals:**
- Files <50 lines imported by many places
- Clusters of small utility files in one folder around one domain (5+ files all about "X")
- Components passing props through 3+ levels without adding value (prop drilling)
- Functions that only call one other function (delegate-only)
- Tight import cycles between N small files

**Architectural-drift signals:**
- Two modules solving similar problems differently (e.g., two different state stores both managing user data)
- Inconsistent error-handling patterns across modules (some throw, some return errors, some silently fail)
- Inconsistent naming for the same concept (e.g., `quiz` in some files, `practice` in others, `exam` in a third — for the same data)
- Duplicate logic across files (same algorithm in 3 places)

Useful Bash patterns:
```bash
# Files <50 lines, sorted by import count (rough proxy)
find src -name '*.{js,jsx}' -size -50l

# Most-imported files (top 20)
grep -rh "from '" src --include="*.js" --include="*.jsx" \
  | sed -E "s/.*from '(.+)'.*/\1/" \
  | sort | uniq -c | sort -rn | head -20

# Functions that appear to only call one other function
# (manual review — too hard to mechanise reliably)
```

### 3. Stop-list — leave these alone

These are *legitimately* shallow and should not be deepened:
- Config files (`*.config.js`, env loaders)
- Type definitions / constants files
- Pure data files (JSON, fixtures, seed data)
- Single-purpose adapters at system boundaries (database client, HTTP wrapper)
- Files that are intentionally a thin re-export layer (barrel files — though these can be deleted if unused)

When you find one of these, skip — don't include in the proposals.

### 4. Cluster and propose deep modules

For each shallow cluster, draft a deep-module proposal:

- **Proposed module name and location** (single file or single folder with one entry point)
- **The simple interface** — what callers actually need (function names + signatures)
- **What complexity gets hidden** — what the rest of the codebase no longer needs to know
- **Where the test boundary moves to** — what gets tested at the new entry point
- **Interface doc draft** — a paragraph the executor (and human readers) can scan to understand the module's purpose without reading the inside

If the proposal would change AGENTS.md (a new mental model, a new entry-point convention), draft the AGENTS.md update inline. **Standing context must reflect the deepening.**

### 5. Rank by leverage — show axes, not unified score

For each proposal, score on:
- **Change frequency** — how often this cluster has changed in `git log` (high = high leverage)
- **Call-site count** — how many places import from this cluster (high = high leverage)
- **Current pain** — bugs, hard-to-reason areas, AI-execution failures in this cluster (qualitative)

Show all three axes per proposal. Don't unify into a single score — the user weighs them.

### 6. Write the markdown output

Output to `~/.claude/plans/<slug>-architecture.md`. Format:

```markdown
# Architecture proposals — <date>

Source: `<repo>` on branch `<branch>`, HEAD `<short-sha>`.
Scope: <e.g., "src/" or "everything but eval/ and video/">

---

## Proposal 1: <Module name>

**Current state (shallow):**
- `path/to/a.js` (12 LoC, imported by 9 places)
- `path/to/b.js` (8 LoC, imported by 4 places)
- `path/to/c.js` (15 LoC, imported by 7 places)
- (etc — list the cluster)

**Proposed deep module:** `path/to/<module>.js` (or `path/to/<module>/index.js`)

**Simple interface:**
```js
export function doX(args): Result;
export function doY(args): Result;
// hidden: helpers a/b/c, cache, retry logic, etc.
```

**Hidden complexity:**
- <what callers no longer need to know>
- <what callers no longer need to know>

**Test boundary:** Tests sit at `path/to/<module>.test.js` against the public interface. Internal helpers don't get individual tests.

**Interface doc (proposed):**
> <One paragraph explaining what the module does, when to use it, what guarantees it provides, what it does NOT do.>

**AGENTS.md update (if applicable):**
> <Diff or addition the user should make to AGENTS.md to reflect the new mental model.>

**Leverage axes:**
- Change frequency: <high/med/low — based on git log>
- Call-site count: <number>
- Current pain: <one-line qualitative note>

---

## Proposal 2: <...>

*(same structure)*

---

## Architectural drift findings (separate from shallow clusters)

### Drift 1: <Description>
- **Where:** `<paths>`
- **Symptom:** <e.g., "Two modules track user data: useUserStore (zustand) and storage.user (custom hook). They get out of sync.">
- **Proposed resolution:** <e.g., "Pick one, migrate the other's call sites.">

---

## Stop-list (skipped — legitimately shallow)

- `vite.config.js`, `eslint.config.js` — config files
- `src/data/cisdf-questions.json` — data file
- (etc.)

---

## Skipped due to in-flight work

- `eval/` — v2 question bank work-in-progress per Session Log
- (etc.)

---

## Next

The user reviews this list and picks which proposals to take on. Refactor execution happens collaboratively, outside this skill run. Each chosen proposal becomes a `/grill-me` → `/write-prd` → `/write-issues` chain or a direct implementation depending on size.
```

### 7. Hand off — do not refactor

End with:

> "Proposals saved at `~/.claude/plans/<slug>-architecture.md`. Review the list and tell me which ones you want to take on. Each chosen proposal becomes its own work item — I'll route it through `/grill-me` → `/write-prd` → `/write-issues` when you decide."

**Do not start refactoring during this skill run.** Even if a proposal seems obvious. Refactor execution is collaborative; the user picks the order, and the skill chain handles each chosen one.

## Output discipline

- **Propose only.** Never refactor inside this skill run.
- **Skip in-flight collisions.** Read `git status` first; don't propose changes to files in active worktrees or with uncommitted modifications.
- **Show axes, not scores.** Three numbers beat one weighted-average that hides trade-offs.
- **Don't propose deepening config / types / constants.** Those are legitimately shallow.
- **Interface doc is mandatory.** A deep module without a docstring is worse than the shallow cluster it replaces, for AI consumers.
- **AGENTS.md updates surface in the proposal, not as silent changes.** The user approves them when picking the proposal.
- **Don't unify "shallow modules" and "architectural drift" into one ranked list.** They're different problems with different remediation patterns. Keep separate sections.
