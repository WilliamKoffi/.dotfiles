---
id: AGT-007
title: "A port runs beside a frozen legacy copy, slice by slice, then switches at once"
system: agents
status: locked
date: 2026-10-07
conflicts: []
requires: [STK-004]
supersedes: null
---
# AGT-007 — A port runs beside a frozen legacy copy, slice by slice, then switches at once

## Decision

Moving an app to another framework or language:

- **A legacy copy.** The current code is copied, unchanged, into `<app>/legacy/` and runs on its
  own as the reference. It changes only by that copy and by its deletion.
- **Slice by slice.** The new code is written one slice at a time. A slice is ported when it does
  and shows the same thing as the legacy copy (same screens, or the same tests passing against
  both).
- **One switch.** When every slice is ported, traffic moves to the new code at once and the legacy
  copy is deleted. There are no islands of one framework inside the other and no bridge between
  them.

```
<app>/legacy/   ← frozen old code, the oracle
<app>/src/      ← new code, filled slice by slice
```

## Why

A frozen reference answers every "what did it do before" question by running it. One switch keeps
the codebase free of a bridge layer that would have to be built, tested and then removed.

## Consequences

- The app cannot be released from the new code between the first slice and the switch; releases
  build from the legacy copy until then.
- Code with no framework dependency is moved, not ported.
