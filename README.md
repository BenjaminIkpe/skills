# ProfSage Skills

The shared [Claude Code](https://claude.com/claude-code) **skills** the ProfSage team uses to plan,
build, and ship. Clone this repo and install them once, and your Claude works the way ours does:
same planning rituals, same issue shape, same CI standards, same handoff format.

> A *skill* is a folder with a `SKILL.md` that Claude Code loads on demand and runs as a slash
> command (e.g. `/write-issues`). It teaches Claude a repeatable procedure. See the
> [Claude Code skills docs](https://docs.claude.com/en/docs/claude-code/skills).

Most of these are **portable** skills — useful in any repo. The one exception is `end-of-session`,
which is specific to the ProfSage app repo (it drives that repo's Sage Vault). It lives here so the
whole team installs it the same way, but it only does anything inside the app repo — elsewhere it's
a no-op.

---

## Install

```bash
git clone https://github.com/BenjaminIkpe/skills.git
cd skills
./install.sh
```

`install.sh` **symlinks** each skill into `~/.claude/skills/`, so a later `git pull` updates every
skill you've installed — no re-install. It will not clobber a skill you already have with the same
name; it tells you and skips it.

To update later:

```bash
cd skills && git pull
```

Verify inside Claude Code by typing `/` — the skills below should appear.

---

## What's in here

### `skills/planning/` — think before you build
| Skill | What it does |
|-------|--------------|
| `grill-me` | Interviews you relentlessly about a plan until every branch of the decision is resolved. Use before committing to a non-trivial design. |
| `refine-plan` | Researches how established companies implement the same thing, then translates the dominant patterns into a concrete refinement for our stack. |
| `write-prd` | Turns a shaped idea (often the output of `grill-me`) into a high-fidelity PRD optimised for an AI executor, not a human stakeholder. |
| `write-issues` | Decomposes a PRD into ranked, agent-ready GitHub issues — each sized for a <10-min review, with acceptance criteria as test cases and explicit out-of-scope. This is our default issue shaper (see the app repo's `WAYS-OF-WORKING.md`). |

### `skills/engineering/` — build to our standards
| Skill | What it does |
|-------|--------------|
| `setup-ci` | Generates a CI workflow tailored to a project's stack, applying the security/quality defaults the base model skips (least-privilege tokens, pinned actions, secrets hygiene, artifacts-on-failure). Carries `principles.md` + per-stack `recipes/`. |
| `improve-codebase-architecture` | Scans for shallow-module clusters and architectural drift and proposes deep-module refactors. Proposes only — execution stays collaborative. |

### `skills/process/` — hand off cleanly
| Skill | What it does |
|-------|--------------|
| `handoff` | Compacts the current conversation into a handoff document another agent (or person) can pick up cold. |
| `end-of-session` | Updates the app's Sage Vault at the end of a session — refreshes the Session Log, captures ADR-worthy decisions, logs new bugs, rolls up roadmap status. **App-repo-specific**: it drives the Sage Vault and is a no-op in any other repo. |

---

## How these fit our way of working

The planning skills feed the pipeline described in the app repo's `WAYS-OF-WORKING.md`:

```
/grill-me  →  /refine-plan  →  /write-prd  →  /write-issues  →  GitHub issue  →  PR  →  review gate
```

`/setup-ci` encodes the CI bar every repo is held to; `/handoff` is how a long session passes the
baton without losing context. Read `HOW-WE-USE-AI.md` in the app repo for the principles underneath
all of this.

---

## Adding or changing a skill

1. Edit (or add) the `SKILL.md` under the right category folder.
2. Keep the frontmatter `description` sharp — it's what Claude uses to decide when to fire the skill.
3. Open a PR. A skill change affects how *both* of us work, so it gets a review like any other change.
