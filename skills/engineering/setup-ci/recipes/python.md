# Recipe: Python

Detect the test runner. If there's a real suite (pytest), gate it. If there isn't
yet, an import + `py_compile` smoke gate is a cheap, honest "it at least loads"
check — and label it as such, don't pretend it's a test suite.

Defaults: `actions/setup-python@v5` with `cache: pip` (`[CACHE]`), `python-version`
pinned (`[PIN]`). If `docker-compose.yml` exists, `docker compose config --quiet`
is a free validity gate.

```yaml
name: ci
on:
  pull_request: { branches: [<protected>] }   # [TRIGGERS]
  push: { branches: [<protected>] }
permissions: { contents: read }               # [LEAST-PRIV]
concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }  # [FAST-FIRST]
jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12', cache: 'pip' }   # [PIN] [CACHE]
      - run: docker compose config --quiet     # only if a compose file exists
      - run: pip install -r requirements.txt
      - name: Smoke (imports + syntax)         # if no real suite yet — be honest
        run: |
          python -c "import <entrypoint_module>"
          python -m py_compile <packages>/*.py
      # If pytest exists, prefer it (and run it the same way locally — [REPRO]):
      # - run: pytest -v
```

## Integration tests needing a DB
If tests need Postgres/redis, add a health-checked service container — see
`services.md`. Keep DB-dependent tests in a **path-filtered** workflow that is NOT
the required check (`[REQUIRED-CHECK]`), so a docs-only PR doesn't deadlock.
