---
id: RCT-001
title: "React state is read and written through `State.bind`"
system: ts/react
status: locked
date: 2026-10-07
conflicts: []
requires: []
supersedes: null
---
# RCT-001 — React state is read and written through `State.bind`

## Decision

Every `useState` result is wrapped once, where it is created, by one `State` namespace, and read
and written only through the wrapper:

```ts
const form = State.bind(useState(''));
form.set('hello');
form.get();   // or form.value
```

```ts
export namespace State {
  export function bind<T>([value, update]: [T, Dispatch<SetStateAction<T>>]) {
    return {
      get: () => value,
      set: (next: T) => update(() => next),
      value,
    };
  }
}
```

The setter is named `update` inside the namespace; the method is `set`.

## Why

Every piece of state reads the same at the call site, as English (`form.set`, `form.value`). The
wrapper is rebuilt on each render, so `value` is the value of that render, as `useState` gives it.

## Consequences

- A `useState` result used without the wrapper is a finding.
- `set(next)` wraps `next` in a function, so a function stored as a value is never called as an
  updater.
- The namespace lives in one shared place and is imported, never copied into each app.
