# JavaScript / TypeScript Instructions

Covers TypeScript, JavaScript, and Node. Read the "Project kinds" section for the
kind you are working on in addition to the common rules above it.

## Package management
- Use `pnpm`: `pnpm add <pkg>` / `pnpm add -D <pkg>`, run scripts with `pnpm <script>`, one-offs with `pnpm dlx`
- Pin the version with the `packageManager` field in `package.json`
- Commit the lockfile; never edit it by hand
- Existing npm projects (most of `admin-rpa/*`) keep `package-lock.json` until migrated —
  consider migrating when you are already touching their tooling

## TypeScript
- TypeScript over JavaScript for anything with logic. Plain JS only for config files
- `"strict": true` in `tsconfig.json`. Avoid `any` — type it or use `unknown` and narrow
- ES Modules (`"type": "module"`); prefer small modules with few side effects
- Type-check separately from the bundler: `tsc --noEmit`
- Generate API clients from the backend's OpenAPI schema (`@hey-api/openapi-ts`) rather than
  hand-writing request/response types

## Lint / Format
- Biome for both lint and format. Do not use ESLint or Prettier
- Config in `biome.json` (or `biome.jsonc`) at the project root:
  - `formatter`: `indentStyle: "space"`, `indentWidth: 2`, `lineWidth: 120` (matches ruff)
  - `javascript.formatter`: `quoteStyle: "double"`, `semicolons: "asNeeded"`
  - `linter.rules`: start from `recommended`
- Check: `biome check ./src` — autofix: `biome check --write ./src`
- Wire it into pre-commit so local and CI runs agree
- `knip` is useful for finding dead exports and unused deps in long-lived projects

## Testing
- Vitest. Jest only in projects that already use it — do not add it to new ones
- Colocate tests with their target as `*.test.ts` (note: this differs from the
  `tests/` directory convention used in Python and Rust)
- Test logic first; mock DOM and platform APIs
- Add tests for new behavior — cover success, failure, and edge cases

## Code style
- Add type annotations to exported functions and module boundaries
- No JSDoc unless explicitly requested
- Minimal, focused changes — don't refactor surrounding code

## Commands
- cargo-make (`makers`) is the entrypoint in polyglot repos; it shells out to `pnpm` scripts
- Standard `package.json` scripts: `dev`, `build`, `lint`, `typecheck` (`tsc --noEmit`), `test`

## Project kinds

### Google Apps Script (clasp)
- `@types/google-apps-script` for typings; compile with `tsc` (no bundler)
- Workflow: `clasp login` → `clasp push` → `clasp deploy`; keep `.clasp.json` and `appsscript.json` in git
- GAS has no npm runtime — runtime `dependencies` must stay empty. Everything is a devDependency
- Never commit script IDs tied to personal accounts or any secret; use Script Properties

### Web frontend (Vite + React)
- Vite + React + TypeScript. Next.js only where SSR/routing genuinely needs it
- Routing/state: TanStack Router + TanStack Query, or React Router — follow whatever the project started with
- Style with Tailwind; component libraries (Chakra, Radix) are per-project, don't mix two in one app
- HTMX is the lighter alternative when the page is server-rendered — prefer it over an SPA
  for simple, mostly-static views

### Node service (Cloud Functions / CLI)
- `@google-cloud/functions-framework` for HTTP functions; keep the handler thin and testable
- Separate unit and integration tests (`vitest run --testNamePattern=unit|integration`)

### Browser extension (Manifest V3)
- Vite build; `background` is a service worker
- Request the minimum `permissions` / `host_permissions` — never broaden to `<all_urls>` for convenience
- `manifest.json` `version` is integers only (no SemVer suffixes) and must increase on every upload
- Never embed secrets — the whole bundle ships to users

### Slidev / Astro (content)
- pnpm workspaces; decks are Vue SFCs, so Biome/TS rules mostly don't apply
- Prettier with `prettier-plugin-slidev` is the exception where slides need formatting
