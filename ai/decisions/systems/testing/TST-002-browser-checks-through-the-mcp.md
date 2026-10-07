---
id: TST-002
title: "Browser checks run through the Playwright MCP, driven the way a person uses the app"
system: testing
status: locked
date: 2026-10-07
conflicts: [TST-001]
requires: []
supersedes: null
---
# TST-002 — Browser checks run through the Playwright MCP, driven the way a person uses the app

## Decision

- **The MCP, never a dependency.** Every browser check is run from the agent session through the
  Playwright MCP server. Playwright is not added to any `package.json`; the repository holds no
  Playwright config and no spec file.
- **Driven as a person.** The check opens the first page by its URL, then moves only through what
  a user can do: click, type, fill a form, select, press a key, hover, go back. It reads the screen
  through snapshots and screenshots.
- **No shortcut.** No script is evaluated in the page; no check writes a token into storage, calls
  the API from the page, or jumps to a URL no link on screen reaches, except one a person would
  type by hand.
- **Passed** means the expected text, state or error is visible, and the console shows no error,
  at 1440 px and 375 px unless the task names other viewports.

## Why

A check that only does what a person can do fails where a person would fail; a shortcut proves the
code path, not the product.

## Consequences

- Each check's report lists every action and what the screen showed after it. Screenshots go to an
  ignored folder.
- A flow a person cannot reach from the screen (a hand-built request, a foreign tenant's id) is an
  API test, not a browser check.
