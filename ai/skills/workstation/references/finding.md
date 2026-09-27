# finding — describe a problem, never fix it

Written by an analyzer, or by any worker who sees something outside its `scope`.
A finding describes. The fix is a task, decided by whoever owns the backlog.

## 1. Qualify it

A finding needs all three:

1. **Evidence** — `file:line` plus the excerpt or the command output. No evidence, no finding.
2. **A broken rule** — a conventions file and section, a doctrine section, a decision
   number, or a stated contract. "I would have done it differently" is not a finding.
3. **An impact** — what goes wrong if it stays.

Many occurrences of one rule are **one** finding with a list, not one per file.

Check the existing findings before writing: an open finding for the same rule gets the
new occurrences appended, not a duplicate.

## 2. Write it

`findings/<category>/FIND-NNN.md` from the repo's `TEMPLATE.md`. Ids are global and
never reused — take one past the highest across every category. Pick the category from
the findings README (typically static-analysis, security, architecture, ui).

Keep it short. Evidence, impact, and a proposed task in one or two lines: role, scope,
and what its `done_when` would be.

Severity is about consequence, not effort: data loss, money, auth and exposure are high;
a naming break that nothing depends on is low.

## 3. Its life

`open` → the backlog owner writes a task (`source: FIND-NNN`) and sets it to
`task (TASK-NNN)` → `closed` when that task completes. Or `wontfix`, with the reason
written in the file.

Filing a finding during a task: mention it in that task's `report.unresolved` with its id.
