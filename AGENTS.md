# TypeScript Project

## Commands

```bash
npm run dev              # Development server
npm run build            # Production build
npm run lint             # ESLint
npm run typecheck        # TypeScript type checking
npm run test             # Unit and integration tests (Vitest)
npm run test:coverage    # Tests with coverage
npm run test:e2e         # Playwright E2E tests
npm run test:all         # REQUIRED before push (lint + typecheck + coverage + e2e)
```

**Troubleshooting:** If any `npm run` command fails, the very first thing to try is `npm install`.

## Testing

### Exit Criteria

This is a **requirement**:
- **Any changes:** `npm run test:all` must pass.
- **New features:** Several unit tests + some integration tests + 1-2 new E2E tests + manual testing sanity check.

### Show That Your Tests Are Working

Tests that have never failed even once are USELESS. You absolutely MUST confirm that the test is actually testing what you intend, either by following TDD and writing your test code before your product code, or by writing your changes, writing your test, temporarily removing your code changes, confirming that the test fails as expected, and then restoring the product code changes. Include the test failure validation in the commit message.

### Running Specific Tests (Vitest)

```bash
# Run tests in files matching a pattern
npm run test -- SomePattern

# Run specific test cases by name
npm run test -- -t "should do something"
```

### Test Organization

- **One `describe()` per file** — each test file contains exactly one top-level `describe()` block.
- **No `test.skip()` calls** — place tests in their intended directory instead.

### E2E Test Debugging

#### One second is an ETERNITY for a computer
Tests in this project are finely tuned to run very fast. Each E2E test case MUST run in 5s or less. This is PLENTY. GitHub APIs, Vercel, CI/CD machines, local dev environment, etc. are all extremely fast. This is applicable to old and new tests. The entire test suite runs in 20s. When running E2E tests, enforce a timeout in the Bash tool call of 1 minute.

#### There are no flaky tests only failing tests
Leave the tests better than how you found them. If you notice a flaky test, you are supposed to help investigate what is the issue and if possible come up with a solution for it. Don't dismiss test failures as "unrelated to my changes".

#### Don't guess - Use the Playwright test trace to understand what is happening
When a Playwright E2E test fails, NEVER assume it's a timeout/flakiness issue. You will not get your tests working by adding arbitrary waitForTimeouts. So much so that they are banned via an ESLint rule. You must analyze the test trace before blindly changing test code. The codebase uses an unreleased version of Playwright with a **new feature called playwright-cli that helps with investigations**.

1. Load the playwright-cli skill
2. Run `npx playwright show-trace --port 0 <trace.zip>` - it will start a web server with the trace information
3. Traces have everything you might need to troubleshoot: Step-by-step action timeline with links to exact DOM state before and after of each action, full error details with stack traces, browser console output, HTTP request log, etc.
3. Use Playwright skill **in headed mode** to open the desired snapshot HTML and have full debugging capabilities
4. Look for actual failures: missing elements, wrong content, API errors, auth issues

#### Proper use of `waitFor` methods
 * `waitForSelector`: Best for waiting for elements to appear, disappear, or change state.
 * `waitForFunction`: Ideal for complex conditions involving multiple elements or JavaScript state.
 * `waitForLoadState`: Good for ensuring the page has reached a certain loading stage.
 * `waitForURL`: Perfect for navigation events and redirects.
 * `waitForEvent`: Useful for downloads, dialogs, and other events.
 * `waitForTimeout`: Banned.

#### Prefer locators to selectors
Unlike traditional selectors that perform a one-time query, locators are lazy and resilient references to elements that automatically retry until elements become available, wait implicitly for elements to be actionable, and adapt to DOM changes between queries.

#### E2E tests in this project are rock solid
All E2E tests go through a stress test where they run 10x in parallel and 10x in sequence every new push to main in search of race conditions and flakiness. You may check the stress test health looking at the workflow history of the ci-cd-main workflow on GitHub.

## Manual Testing

You have access to Playwright via playwright-cli skill. Make sure to **only use it in headed mode** so the user can see your work and assist you. Use it sparingly in the following situations:
 * You are stuck trying to reproduce a bug through code analysis or test cases. `evaluate` is invaluable to capture runtime information such as computed styles or library side effects.
 * Sanity check your work as you reach a milestone in the implementation of a feature. Once you reach ~200 lines of code changes, the risk that you are compounding errors and don't have working code becomes high. A quick inspection in Playwright gives extra assurance that you are on the right track.
 * Final quality assurance. Don't ask the user to test a feature manually before you did it yourself!

## Shared Environment

There are multiple instances of Claude Code running in parallel. Each one has multiple node.exe instances (MCP, dev server, etc.) and dev servers running. Each worktree has its own designated port: 3010 for A, 3020 for B, 3030 for C, 3040 for D, 3050 for E, 3060 for F, 3070 for G. The `npm run dev` command is smart to only kill zombie servers associated with your worktree and only start a server in its designated port automatically. DO NOT kill all node.exe or kill by port number. If `npm run dev` fails STOP and ask the user for assistance.

## Code Conventions

### TypeScript

- Strict mode. No `any` unless absolutely unavoidable. Use `unknown` if unsure, but prefer defined types.
- Prefer named exports over default exports.
- File naming: `kebab-case.ts` for modules, `PascalCase.tsx` for React components.
- Use `@/` path aliases for imports instead of relative paths.

### Components

- **Icons**: Use `lucide-react` for icons. Do not import other icon libraries.

### Error Handling

- Let errors propagate naturally. Don't wrap everything in try/catch.
- Validate at system boundaries (API inputs, tool inputs). Trust internal code.
- Always handle API errors gracefully in the UI (Error Boundaries or Toast Notifications).

## Git Workflow

- **Merge strategy**: Only merge commits are allowed (`gh pr merge --merge`). Squash and rebase merge are disabled.
- **Branch must be up to date**: PRs must be up to date with `main` before merging (strict status checks).
- **Updating PR branches**: Always rebase onto `main` (`git pull --rebase origin main`), never merge `main` into your branch. This keeps history linear on the branch.
- **Do not bypass branch policies**: Branch protection rules exist for a reason. Never use `--admin` or any other mechanism to bypass required status checks, required reviews, or merge restrictions unless the user has explicitly authorized it for a specific operation.
- **Do not bypass git hooks**: Pre-commit and pre-push hooks enforce project standards. Never use `--no-verify` to skip them. If a hook fails, fix the underlying issue.

## Agent Workflow Standards

### Stop and Read Policy

- **Before Coding**: Read the relevant spec and any related source files before starting implementation.

### Error Recovery Protocol

- **Linter Errors**: If a fix triggers a linter error, DO NOT suppress it with `// eslint-disable` unless absolutely necessary. Fix the root cause.
- **Test Failures**: Analyze the failure output. If the test is wrong (e.g., outdated selector), update the test. If the code is wrong, update the code. Do not delete the test.

### Atomic Task Management

- **One Task at a Time**: Do not try to implement multiple features in a single session.
- **Update Artifacts**: Keep task tracking updated in real-time. If you finish a sub-task, mark it checked immediately.

### Context Optimization

- **Path Aliases**: Use `@/` for imports (e.g., `import { Button } from '@/components'`) instead of relative paths. This reduces cognitive load when moving files.
- **Type Definitions**: Look in `src/types/` first. Prefer feature-specific types only when a dedicated domain module exists.

### Self-Verification

- **Run the Build**: After significant changes, run `npm run build` and `npm run lint`.
- **Visual Check**: You WILL be asked to demo your code changes using Playwright, so before claiming completion you MUST perform a visual check with it.
- **CI Must Be Green**: Before claiming work is done or a PR is ready, watch CI/CD with `gh run watch <run-id>` and confirm all jobs pass. A PR with failing CI is not done.

### Test Data Standard

- **Factories**: Use `src/tests/factories/` for generating test data.
