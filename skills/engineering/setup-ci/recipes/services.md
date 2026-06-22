# Recipe: service containers (integration tests)

For tests that need a real Postgres/redis/etc. Two non-negotiables:
1. **Health-check the service** so the job waits until it accepts connections, not
   merely until the container starts (`[SERVICES]`).
2. **Keep this in a path-filtered, non-required workflow** so a PR that doesn't
   touch the data layer isn't blocked waiting on a check that never runs
   (`[REQUIRED-CHECK]`).

```yaml
name: data-ci
on:
  pull_request:
    paths: ['db/**', 'scripts/**', '.github/workflows/data-ci.yml']   # path-filtered, NOT required
  push:
    branches: [<protected>]
    paths: ['db/**', 'scripts/**', '.github/workflows/data-ci.yml']
permissions: { contents: read }               # [LEAST-PRIV]
jobs:
  validate:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env: { POSTGRES_USER: app, POSTGRES_PASSWORD: app, POSTGRES_DB: app }
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5          # [SERVICES] — wait for ready, not just started
    env:                              # what the test code reads
      PGHOST: localhost
      PGPORT: '5432'
      PGUSER: app
      PGPASSWORD: app
      PGDATABASE: app
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12', cache: 'pip' }
      - run: pip install -r db/tests/requirements.txt
      - run: pytest db/tests -v       # same command locally — [REPRO]
```

## redis variant
```yaml
      redis:
        image: redis:7
        ports: ['6379:6379']
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s --health-timeout 5s --health-retries 5
```
