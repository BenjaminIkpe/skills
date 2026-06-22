# CI principles — apply ALL of these to every generated workflow

Each is something the base model omits unless told. If a generated CI doesn't
satisfy one, it's wrong. Format: rule — why (the non-obvious part) — how.

## [LEAST-PRIV] Least-privilege GITHUB_TOKEN
Why: the default token is read/write to the whole repo; a compromised or
malicious action gets that entire blast radius. How: `permissions: { contents: read }`
at the top level; widen per-job only when a job genuinely needs it (e.g.
`pull-requests: write` to post a comment, `id-token: write` for OIDC deploys).

## [REQUIRED-CHECK] The required check must be path-agnostic
Why: a path-filtered workflow marked "required" in branch protection NEVER runs
on a PR that doesn't touch those paths — so it never reports success — so the PR
hangs forever, unmergeable. The single most common self-inflicted CI deadlock.
How: one always-runs gate (no `paths:` filter) is the required check; path-scoped
jobs (db, docs, infra) live in separate workflows that are NOT required — or, if
you must require them, add a "no relevant changes → no-op pass" job so a status is
always reported.

## [PIN] Pin actions and language versions
Why: a floating tag (`@main`, or even a moving `@v4` from an untrusted author)
can pull a breaking or compromised action mid-PR; unpinned language versions make
CI non-reproducible. How: `@v4` minimum for first-party actions; SHA-pin
security-sensitive third-party actions; set `python-version` / `node-version`
explicitly, never "latest".

## [CACHE] Cache dependencies
Why: re-downloading deps on every run is the cheapest win there is. How: use the
setup action's built-in cache (`setup-node` `cache: npm`, `setup-python`
`cache: pip`) keyed on the lockfile.

## [REPRO] CI commands mirror local
Why: a green CI you cannot reproduce locally is undebuggable, and a red one wastes
a round-trip per guess. How: the CI test step should be the exact command a dev
runs (`pytest db/tests`, `npm run test:e2e`). State that command in a comment.

## [FAST-FIRST] Cheap checks fail fast + cancel superseded runs
Why: don't make someone wait 5 minutes for e2e to discover lint failed; and don't
burn minutes on a run for a commit that's already been pushed over. How: separate
parallel jobs (lint | build | e2e) so each reports independently; add
`concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`.

## [SECRETS] Secrets hygiene
Why: secrets leak via logs and, dangerously, via fork PRs. How: never `echo` a
secret or interpolate it into a shell string that gets logged; use `pull_request`
(NOT `pull_request_target`) for untrusted forks so secrets aren't exposed to fork
code; if a value is public-but-environment-specific (e.g. a public Supabase URL or
anon key gated by RLS), keep it under `secrets` with a comment explaining why, so
prod↔test is a one-toggle swap and the workflow stays env-clean.

## [ARTIFACTS] Upload diagnostics on failure
Why: post-mortem a failure without re-running the whole job. How: `if: always()`
upload of the report (playwright-report, coverage, logs) with a short
`retention-days`.

## [SERVICES] Health-checked service containers for integration tests
Why: real DB/redis-backed tests without external infra — but the job must wait
until the service is actually accepting connections, not merely started. How: a
`services:` block with `--health-cmd` (e.g. `pg_isready`) + interval/timeout/retries,
and pass the connection env the tests read.

## [TRIGGERS] Deliberate triggers
Why: you want the merged copy on the protected branch to gate all *future* PRs,
not just the PR that introduces the workflow. How: `pull_request: { branches: [<protected>] }`
plus `push: { branches: [<protected>] }`. Be explicit about `pull_request` vs the
more dangerous `pull_request_target` (see `[SECRETS]`).

## [WIRING] The YAML gates nothing by itself
Why: a workflow file only *runs*; branch protection is what *blocks a merge*. A
file in `.github/workflows/` with no protection rule is decorative. How: after the
file lands, set the required status check via `gh api` (or the repo settings UI);
the required-check *name* must exactly match the workflow job's `name:`. Tell the
user the exact name they'll see on the PR.
