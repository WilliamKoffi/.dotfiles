---
id: LRV-001
title: "Slicing is scoped to the layer"
system: php/laravel
status: locked
date: 2026-09-27
conflicts: []
requires: []
supersedes: null
---
# LRV-001 — Slicing is scoped to the layer

## Decision

`app/` slices by module: `app/Modules/<Name>/`, with a closed folder list: `Actions/`,
`Data/`, `Enums/`, `Filament/`, `Http/` (`Controllers/`, `Requests/`, `Resources/`),
`Models/`, `Policies/`, `Providers/`, `Queries/`, `Rules/`. Never `Services/`. Code with no
module (casts, value objects, helpers) lives in `app/Shared/`.

`routes/`, `tests/`, `database/factories/` and `database/seeders/` keep Laravel's own
folders and group by module inside them. `database/migrations/` stays flat.

## Why

Each layer keeps the shape a Laravel developer expects, and the domain code still reads
one module per folder. Tests and routes inside modules need PSR-4 wildcards and scatter the
auth contract.

## Consequences

- A module folder outside the list, or a `Services/` folder, is a finding.
- An empty folder is not scaffolded ahead of the file it will hold.
- An `Actions/` class exists only for a verb that spans two aggregates where neither owns the outcome.
