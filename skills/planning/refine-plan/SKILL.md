---
name: refine-plan
description: Refine a proposed plan, idea, or feature by researching how comparable established companies implement the same thing, then translate the dominant patterns and non-obvious nuances into a concrete refinement for the user's stack. Use PROACTIVELY whenever the user proposes a non-trivial implementation plan, feature design, architectural decision, or UX pattern (notification systems, auth flows, gamification, search, billing UIs, animations, data models, sync, etc.). Also runs on explicit invocation — `/refine-plan`, "refine the plan", "refine this idea", "what's the best way to do this". Skip for trivial work (bug fixes, renames, doc edits, exact-spec tasks with no design space).
tools: WebSearch, WebFetch, Read, Grep, Glob, Bash
---

# Refine Plan

Take a proposed plan or idea and harden it by checking how established teams solve the same problem at scale. Surface the non-obvious choices, translate them to the user's specific stack, and return a tight refined plan for confirmation before any code is written.

## When to apply this skill

**Apply it for:**
- New features with real design space (notification systems, auth flows, gamification, search ranking, onboarding, billing UIs, modals, animations).
- Architectural decisions (data model shape, sync strategy, caching layer, API surface, state management).
- UX patterns where conventions matter (tabs, infinite scroll, empty states, error recovery, keyboard nav, persistence).

**Skip it for:**
- Bug fixes — the bug has a defined fix.
- Renames, deletions, doc edits, formatting, dependency bumps.
- Exact-spec asks: "change X to Y", "add this exact endpoint", "remove this UI".
- Trivial UI tweaks (colour, padding, copy).
- Anything where the user has already explicitly chosen an approach and just wants execution.

If unsure, run the categorisation step (1) — it takes a moment, and aborting is cheap.

## Workflow

### 1. Categorise the problem

In one sentence: what category is this? Examples:
- "in-app notification system"
- "OAuth callback handling"
- "infinite-scroll list with prefetch"
- "tab navigation with deep links"
- "spaced-repetition review queue"

The category determines which products and engineering blogs to look at.

### 2. Identify 2–3 closest analogues

Pick products that ship this same pattern at scale. Quick map:

| Category | Closest analogues |
|----------|-------------------|
| Notifications / toasts | Duolingo, Linear, Slack, Discord, GitHub |
| Gamification (XP, streaks, badges) | Duolingo, Strava, Khan Academy, Stack Overflow |
| Auth flows | Auth0, Clerk, Supabase Auth, Firebase Auth |
| Search / ranking | Algolia, Elasticsearch, Stripe API search |
| Tabs / hash routing | Stripe Dashboard, Linear, GitHub, Notion |
| Onboarding | Notion, Linear, Figma, Stripe |
| Billing UIs | Stripe, Anthropic Console, OpenAI Platform |
| Sync / offline-first | Linear, Notion, Figma, Apple Notes |
| Empty states / loading | Linear, Notion, Stripe |
| Animations / micro-interactions | Stripe, Linear, Apple HIG, Material Design |

If the category is unfamiliar, spend a web search on "who handles \<category\> well" before diving in.

### 3. Web-search for current best practice — REQUIRED, every time

Patterns evolve. Training-data knowledge is stale on anything time-sensitive. **Always run WebSearch** for at least one query, even on familiar territory. Useful queries:

- `<feature> implementation best practices <current year>`
- `<company> engineering blog <feature>`
- `<feature> accessibility <current year>` — almost always surfaces non-obvious nuances
- `<feature> mistakes anti-patterns`
- `<framework> <feature> patterns <current year>` (e.g., "react notification toast patterns 2026")

Read 2–4 sources. Prioritise:
1. **Engineering blogs** of the analogue companies (Duolingo Engineering, Linear blog, Stripe blog).
2. **Accessibility / WCAG guides** — they catch nuances most articles miss.
3. **Framework-specific patterns** (React docs, MDN, web.dev).
4. **Recent (≤2 years old)** content — flag if you have to fall back to older sources.

Skip generic listicles, low-effort SEO content, and anything older than 3 years for stack-specific advice.

If WebFetch is needed for a specific high-value page, use it. Don't WebFetch speculatively — only when WebSearch surfaces something worth reading in full.

### 4. Surface the non-obvious nuances

These are the points a naive implementation misses. The high-value items recur across categories:

- **Batching simultaneous events** — does the UI collapse N events into one surface, or stack N toasts? (Multi-badge unlock, bulk import, batch mutation.)
- **Retroactive triggers** — when state syncs from another device or restores from cache, does it accidentally re-fire celebration UI? Need a "this event was already acknowledged" flag.
- **Accessibility** — `prefers-reduced-motion`, focus management, ARIA live regions, keyboard navigation, screen-reader announcements, sufficient colour contrast (WCAG AA: 4.5:1 normal, 3:1 large text).
- **Browser policy realities** — autoplay-with-sound blocked until user interaction; third-party cookies dying; storage quotas; popup blockers; Safari's ITP; iOS Safari viewport quirks.
- **Persistence** — tab state, scroll position, draft text, filter state. Hash routing or query params, not in-memory only. Refresh and deep-links must work.
- **Empty / error / loading states** — explicitly designed, not afterthoughts. What does the page look like at 0 items, 1 item, 1000 items, while loading, on error?
- **Mobile vs desktop divergence** — 44pt touch targets, viewport-based sizing, swipe gestures, virtual keyboard handling.
- **Sync conflict resolution** — last-write-wins is rarely right. Think CRDT, vector clocks, or explicit merge UI.
- **Off-by-default for surprising behaviour** — sound, push notifications, auto-share. Browser policies will block them anyway; respect that.

### 5. Translate to the user's stack

Generic best practice → concrete code in the user's stack. Spend a few `Read`/`Grep` calls to ground the recommendation:

- **Match existing conventions** — if the codebase uses inline styles, don't propose CSS modules. If it uses a custom hook pattern, fit into it.
- **Reuse existing primitives** — already-defined CSS tokens, components, utility functions. Don't reinvent.
- **Be cautious with new dependencies** — call them out explicitly if proposed. "This needs `<library>`" is information, not a hidden cost.
- **Consider deployment constraints** — serverless function timeouts, bundle size, cold-start cost.

### 6. Present the refined plan + confirm

Format: a tight diff against the user's original plan. Lead with **what changed and why in one line each**. Don't write a report — write a punch list. Then ask to proceed.

Example output shape:

> Refined plan, four real changes:
>
> 1. **\<Change\>** — one-line why.
> 2. **\<Change\>** — one-line why.
> 3. **\<Change\>** — one-line why.
> 4. **\<Change\>** — one-line why.
>
> Same scope, better implementation choices inside each step. Proceed?

If the original plan already covers all of this, say so explicitly:
> "Already solid — the only marginal improvement I'd add is X. Proceed as-is, or include X?"

## Output discipline

- **Be terse.** The user reads diffs, not essays. Bullet > paragraph.
- **Cite sources only when they add information beyond the recommendation** — "Stripe does X because Y" is useful; "according to a blog post" is not.
- **If web search returns nothing useful, say so.** Don't pad with platitudes.
- **Don't recommend tools / libraries the user already has working alternatives for.** Match the existing stack.
- **Don't lecture.** If a point is obvious from the original plan, drop it. Only surface what genuinely changes the design.
- **Cap the changes at 5–7 max.** More than that means the original plan was wrong, and you should say that directly rather than burying the user in a list.
