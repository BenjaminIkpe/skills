---
name: end-of-session
description: Update the Sage Vault at the end of a Claude Code session — refresh the Session Log, capture ADR-worthy decisions, log new bugs, and roll up roadmap status. Use PROACTIVELY when the user says "end of session", "update the vault", "wrap up", "update the session log", or signals the session is closing. Also runs on explicit invocation as `/end-of-session`. Project-specific to the cisdf-quiz repo and its Sage Vault structure.
model: opus
tools: Read, Edit, Write, Bash, Glob, Grep
---

# End of Session

Run this at the end of every Claude Code session to keep the Sage Vault current. The vault is the handoff document between sessions — if it isn't updated, the next session starts cold.

## 0. Check vault file hygiene

For every vault file created or edited this session:
- Confirm it has YAML frontmatter with at minimum `tags: [sage, <type>]`
- Confirm any cross-reference to another vault file uses `[[wiki-link]]` syntax, not plain text
- Valid types: `hub` · `adr` · `session` · `skill` · `reference` · `roadmap` · `bugs` · `feedback` · `data` · `users` · `deprecated`

If anything is missing, fix it before closing the session.

---

## 1. Update Session Log

File: `Sage Vault/Sessions/Session Log.md`

Update the Current Status section at the top with:
- What was worked on this session
- What got completed (with tick ✅)
- What is still in progress or broken
- The exact next step to start from next session
- Last commit hash if any commits were made

Keep only the last 2 sessions in the log — older ones roll to `Sage Vault/Sessions/Archive.md`.

Add a new dated entry under "Recent Sessions" using this template:

```
### YYYY-MM-DD — [Short title]
**Worked on:**
**Key decisions made:**
**Bugs fixed:**
**Commits pushed:**
**Left unfinished:**
```

## 2. Check for ADR-worthy decisions

If during this session we made a significant architectural or technical choice that wasn't obvious, create a new file at `Sage Vault/Architecture/ADR-00X Title.md`.

Template:
```
---
tags: [sage, adr]
Date:
Status: Decided
---
## Decision
## Alternatives considered
## Why we chose this
## Revisit if
## Consequences
```

Only create if a real decision was made. Don't create for routine implementation work.

## 3. Check for new bugs or gotchas

If we hit a bug that wasn't in the vault already, add it to `Sage Vault/Bugs & Gotchas/Known Issues & Fixes.md`.

Format:
```
### BUG-XXX — Bug title
- Symptom:
- Root cause:
- Fix:
- Date found:
```

## 4. Check roadmap status

Files: `Sage Vault/Roadmap/Product Overview.md` and the relevant track file(s) — Track 1 (Quiz & Learning Engine), Track 2 (AI Tutor / Sage), Track 3 (UI & Product), Track 4 (Question Bank), Track 5 (Platform & Infrastructure).

If any items were completed this session, update their checkbox from ⬜ to ✅ in the relevant track file and update the track's status in Product Overview if the overall status changed.

## 5. Nothing else

- Do not update files that didn't change this session.
- Don't invent content. If nothing ADR-worthy happened, skip step 2. If no new bugs, skip step 3.
- If a vault file referenced in this skill no longer exists, flag it instead of creating placeholder content.
