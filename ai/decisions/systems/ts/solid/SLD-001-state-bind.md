---
id: SLD-001
title: "Solid state is read and written through `State.bind`"
system: ts/solid
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# SLD-001 — Solid state is read and written through `State.bind`

## Decision

Every signal and store is wrapped once, where it is created, by one `State` namespace, and read
and written only through the wrapper:

```ts
const form = State.bind(createSignal(''));
form.set('hello');
form.get();   // or form.value
```

```ts
export namespace State {
  export function bind<T>([read, update]: Signal<T>) {
    return {
      get: () => read(),
      set: (next: T) => update(() => next),
      get value() {
        return read();
      },
    };
  }
}
```

The setter is named `update` inside the namespace; the method is `set`. `get()` and `value` both
call the accessor, never a copy of it. A store takes the same shape through `State.store`, its
`set` forwarding to the store's setter.

## Why

Every piece of state reads the same at the call site, as English (`form.set`, `form.value`),
whatever primitive holds it. Reading through the accessor keeps each read tracked in JSX, a memo
or an effect; a `value` copied at creation would be the accessor itself, or a value that never
updates.

## Consequences

- A `createSignal` or `createStore` result used without the wrapper is a finding.
- `set(next)` wraps `next` in a function, so a function stored as a value is never called as an
  updater.
- The namespace lives in one shared place and is imported, never copied into each app.
