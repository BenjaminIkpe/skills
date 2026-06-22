# Recipe: Node / JS

Read `package.json` `scripts` and gate only the ones that exist. Typical jobs are
`lint`, `build`, and a test layer. Each job is independent so they run in parallel
and report separately (`[FAST-FIRST]`).

Defaults to apply: `actions/setup-node@v4` with `cache: npm` (`[CACHE]`),
`node-version` pinned (`[PIN]`), `npm ci` (not `npm install`) for reproducible
installs.

```yaml
name: ci
on:
  pull_request: { branches: [<protected>] }   # [TRIGGERS]
  push: { branches: [<protected>] }
permissions: { contents: read }               # [LEAST-PRIV]
concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }  # [FAST-FIRST]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }   # [PIN] [CACHE]
      - run: npm ci
      - run: npm run lint            # only if package.json defines "lint"
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm run build           # only if defined
```

## e2e layer (only if Playwright/Cypress is a dependency)
Run after install; install browsers with `--with-deps`; upload the report on
failure (`[ARTIFACTS]`). Pass any public-but-env-specific config via `secrets`
with a comment (`[SECRETS]`).

```yaml
  e2e:
    runs-on: ubuntu-latest
    env:
      # public anon value; kept under secrets so prod↔test is one toggle [SECRETS]
      VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e        # the exact local command [REPRO]
      - if: always()                 # [ARTIFACTS]
        uses: actions/upload-artifact@v4
        with: { name: playwright-report, path: playwright-report/, retention-days: 7 }
```
