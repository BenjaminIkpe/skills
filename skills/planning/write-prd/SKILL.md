---
name: write-prd
description: Turn a grill-me plan or any sufficiently-shaped idea into a high-fidelity PRD optimised for AI execution. The audience is the executor agent (interactive Claude Code session, claude-code-action overnight run, or anything else that consumes a spec), not a human stakeholder. Use when the user invokes `/write-prd`, says "write the PRD", "write a PRD for X", "turn this into a PRD", or naturally needs a durable spec after `/grill-me`. Output is `~/.claude/plans/<slug>-prd.md`. Skip for trivial work (bug fixes, renames, doc edits, exact-spec tasks where there's nothing to flesh out).
tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# Write PRD

Turn a grill-me plan or sufficiently-shaped idea into a high-fidelity PRD optimised for AI execution. **The audience is the executor agent, not a human stakeholder.** Length is not the cost; ambiguity is.

## When to apply this skill

**Apply it for:**
- After `/grill-me` produced a plan and you want a durable, executable spec
- Any sufficiently-shaped idea (clear goal, scope, decisions in hand) that's about to be implemented
- Features destined for `/write-issues` decomposition

**Skip it for:**
- Bug fixes — the bug has a defined fix, no PRD needed
- Renames, deletions, doc edits, formatting
- Exact-spec asks ("change X to Y in file Z")
- Anything where the user can describe the implementation in one sentence

## The PRD's audience and shape

The PRD is read by an executor that does not have the conversation context. It must be:
- **Self-contained for the *delta* this feature introduces** — but not for global project context (assume executor has read `AGENTS.md` and the vault)
- **Dependency-ordered** — foundations first, then layers built on top
- **Concrete** — file paths, function names, test cases, not abstract requirements
- **Adversarial** — what could break this, what an enthusiastic implementer would gold-plate

Optimise for "executor comes back correct on first try," not "human skims in 90 seconds."

## Workflow

### 1. Locate the source

In order of preference:
1. The most recent `~/.claude/plans/<slug>.md` from `/grill-me` (Glob `~/.claude/plans/*.md`, sort by mtime; if multiple recent ones exist, ask the user which).
2. A plan file the user explicitly references.
3. The conversation context if no plan file exists.

If no source is identifiable, ask once: *"What plan or topic should I write the PRD for?"* — then stop until answered.

### 2. Don't re-grill

If `/grill-me` already produced a plan, the heavy lifting is done. **Do not re-interview the user.** Read the plan, generate the PRD, surface anything genuinely missing as an "open question" in the output rather than a question to the user.

Exception: if a *critical, blocking* section is empty (e.g., no goal, no non-goals at all), ask exactly one question to fill it. Don't go beyond that — if grill-me missed something fundamental, the user should re-run grill-me, not have this skill paper over the gap.

### 3. Read the surrounding context

Before drafting, skim:
- `AGENTS.md` (project conventions and standing rules)
- Files referenced in the source plan (so file paths in the PRD are real)
- Any relevant `Sage Vault/Architecture/ADR-*.md` so existing decisions aren't re-derived
- `git status` and current branch so you know what's in flight

### 4. Generate the PRD

Write to `~/.claude/plans/<slug>-prd.md` (sibling to the grill-me plan). If the file exists, append a numeric suffix.

**Structure (skip empty sections, do not write "N/A"):**

```markdown
# <Title>

## Problem
<Concrete, 1–3 sentences. What pain does this solve? Why does it matter now?>

## Goal
<Single sentence. The state-of-the-world this PRD aims to bring about.>

## Non-goals
- <Explicit "do not do X" — verbatim from grill-me's non-goals>
- <Any additional non-goals discovered during PRD drafting>

## Decisions with rationale
- **<Decision>**: <choice>. *Why:* <one-line reason>
- **<Decision>**: <choice>. *Why:* <one-line reason>

(The executor generalises from *why* when new edge cases arrive. Outcomes alone don't transfer.)

## Phases

Phases are dependency-ordered. Each phase is independently testable.

### Phase 1: <Name>
**Deliverable:** <single sentence>

**Files to touch:**
- `path/to/file.js` — <brief role in this phase>
- `path/to/other.jsx` — <brief role>

**Acceptance criteria** (executable test cases):
- Given <state>, when <action>, then <observable outcome>
- Given <state>, when <action>, then <observable outcome>

**Phase invariants** (what must remain true after this phase):
- <e.g., existing tests still pass>
- <e.g., no public API changes>

### Phase 2: <Name>
*(same structure, depends on Phase 1)*

## Expected agent execution path

A condensed walkthrough of what the executor does, in order. Used by autonomous agents to plan their work.

1. Read the relevant files (paths above).
2. Implement Phase 1, run its acceptance criteria locally before moving on.
3. Implement Phase 2, etc.
4. Run `npm run lint && npm run build && npm run test:e2e` before opening the PR.

## Global invariants (across all phases)

- <e.g., `Sage Vault/Sessions/Session Log.md` updated at session end>
- <e.g., schema changes require an ADR>
- <e.g., XP stays client-side; do not server-ify in this PRD>

## What could break this

(Adversarial section. Forces implicit risks visible.)

- <Real risk + mitigation>
- <Real risk + mitigation>
- <"An enthusiastic implementer might add X — DO NOT, because Y">

## Open questions

(Verbatim from grill-me, plus any surfaced during PRD drafting.)

- <Unresolved branch + the dimension that's blocking>

## Next
- `/write-issues` — decompose this PRD into ranked GH issues
- (or hand to an autonomous agent / implement directly)
```

### 5. Length discipline

There is no upper limit on PRD length. **Detail proportional to load-bearing-ness.**

- Sections that constrain implementation (data model, edge cases, integration points, gotchas) get expanded fully.
- Sections that don't (generic risks, hand-wavy framing) stay short or get dropped.
- Boilerplate ("user-centric design," "follow best practices") is dead weight — never include.

If the PRD's atomic instruction count exceeds ~150–200 (LLMs degrade beyond that), split into multiple PRDs by phase. Phase 1 gets its own PRD; Phase 2 references the Phase 1 PRD as a prerequisite.

### 6. Skip the global-context boilerplate

The executor has read `AGENTS.md` and the vault. Do not re-state:
- Tech stack overview
- Branch workflow
- Commit conventions
- Testing setup
- Coding style

The PRD focuses on the **delta** this feature introduces. If a project-wide convention is *especially* load-bearing for this PRD, link to the AGENTS.md section or ADR rather than restating it.

### 7. Reference code by path, not description

Wrong: *"The quiz engine handles question selection..."*
Right: *"`src/data/quizEngine.js:buildPracticeQueue` selects the next question..."*

The executor reads the file. Don't paraphrase what's already there.

### 8. Offer the next step

End with:

> "PRD saved at `~/.claude/plans/<slug>-prd.md`. Next: `/write-issues` to decompose into GH issues, or hand the PRD to an executor directly."

## Output discipline

- **No fabrication.** If grill-me didn't resolve something, surface it as an "Open question" — don't invent the answer.
- **No "N/A" filler.** Skip empty sections entirely.
- **No prose where bullets work.** Bullets > paragraphs > prose.
- **Concrete examples over abstract requirements.** "User can edit a question" is weak; "Clicking Edit on Q1 pre-fills the form with Q1.stem and Q1.options; save calls `storage.updateQuestion()`; failure shows toast" is strong.
- **Decisions carry rationale.** "Picked Supabase over Firestore *because real-time sync isn't needed and we already have Supabase auth*" beats "Picked Supabase."
- **Don't write a how-to.** The PRD says *what* and *why*. Implementation strategy belongs to the executor.
