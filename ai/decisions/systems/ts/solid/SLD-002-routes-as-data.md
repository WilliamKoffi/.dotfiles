---
id: SLD-002
title: "A slice declares its routes as data; the shell collects them"
system: ts/solid
status: locked
date: 2026-10-07
conflicts: []
requires: [STK-004]
supersedes: null
---
# SLD-002 — A slice declares its routes as data; the shell collects them

## Decision

Each feature slice exports its routes from `features/<slice>/routes.ts`, as a plain array of
`{ path, component, permission }` entries:

```ts
export const routes = [
  { path: '/sales', component: Sales, permission: 'sales.view' },
];
```

The shell collects every slice's file with `import.meta.glob('./features/*/routes.ts')`, guards
each entry on its permission, and renders it inside the app layout. No route is declared in the
shell itself.

## Why

Adding or porting a slice then touches that slice only: the shell never learns a slice's name,
and a slice never imports the shell.

## Consequences

- A slice without screens has no `routes.ts`.
- A route without a `permission` is a finding unless the page is public (login, error pages).
