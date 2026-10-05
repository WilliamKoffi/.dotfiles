# task — turn a request into work

Input: a user request, a finding, a plan step, or a `todo.md` line.
Output: one task file per role, in `backlog/` (or `ready/` when every dependency is
already completed), and one line back to the user naming the ids.

## 1. Split by role

Read `agents/README.md` (or the roles you discovered) and match the work to **one**
role. Work that crosses roles is several tasks:

- a column plus the code that reads it → database task, then backend task `depends_on` it
- an API field plus the page that shows it → backend task, then frontend task
- anything that must be seen in a browser afterwards → the same role if its Validation
  covers it, else a tester task

Order them so each one is verifiable alone. A task that cannot be validated without
its successor is split at the wrong line.

Verifiable is a command; visible is a person seeing the behaviour work. The role split
leaves only the last task of a behaviour visible, so the tasks of one behaviour share a
`slice:` value (a short kebab-case name), and the last of them carries a `done_when` that
shows it end to end: the instrument and what a person sees (§3, the observation form).
Never merge two roles into one task to make it visible.

## 2. Fill every field of the template

Read `tasks/TEMPLATE.yaml` and fill **all** of its fields — an empty field that the
template declares is an unfinished task.

| Field | How to fill it |
|---|---|
| `id` | next free id across every folder (SKILL §3.2) |
| `title` | the outcome in one line, from the reader's side: what is true when it is done |
| `role` | exactly one, from `agents/` |
| `status` | the folder you will put it in |
| `depends_on` | ids that must be in `completed/` first; check them, don't assume |
| `knowledge` | the entry point, the owner doc of each fact touched, the rule file, and the exact source files — nothing else. This is all the worker will read |
| `scope` | the paths it may change, inside the role's Scope. Include `tasks/` and `findings/` so it can write its own report and any finding |
| `forbidden` | the paths it must not touch — the neighbours it could be tempted by (the other app, a vendored or legacy tree, generated assets) |
| `steps` | the smallest change that satisfies `done_when`, one line per file or per move. Name the file and what changes in it |
| `done_when` | see §3 |
| `slice` | the behaviour this task is part of, shared by every task of it (§1); omit for a task that stands alone |
| `source` | `FIND-NNN`, a decision number, a plan step, or `<file> (user, YYYY-MM-DD)` |
| `report` | the empty shape from the template; the worker fills it |

Verify before writing: every path in `knowledge` and `scope` exists (`ls`), every id
in `depends_on` is real, and the role's `AGENT.md` allows every path.

## 3. `done_when`

Each entry is one of:

- **a command** with its expected outcome — start from the role's Validation block, then
  add what is specific to this task
  (`cd web && pnpm build && pnpm lint && pnpm test:unit`)
- **a file fact** a command can check
  (`rg -n payment_method docs/architecture/database.md: one row in the orders table`)
- **an observation with its instrument**, when the change is visual — the tool, the
  viewports, and what must be true
  (`Playwright at 1440 and 375 px: the tab shows only femme products, 0 console errors`)

Never: "works", "matches the design", "is consistent".

## 4. Place and report

- Every `depends_on` already in `completed/` → `ready/`, else `backlog/`.
- Write the file, then say in one line: the ids, each one's role, and what blocks the
  ones in the backlog.
- Do not start the work. `run` is a separate verb, and the user decides when.

## Wide refactors

A change too wide for one task (a rename across a tree, a new layer, a port to another
language) is planned as expand–contract, so every task leaves the role's Validation green:

1. **Expand** — the new form beside the old one; nothing that works breaks.
2. **Migrate** — one task per batch, each moving callers from the old form to the new.
3. **Contract** — delete the old form once nothing uses it.

Write the contract task at planning time, in `backlog/`, `depends_on` every migrate task,
so the old form cannot be forgotten. The phase is in each title; no extra field.

## Rewriting a failed task

A task in `failed/` is not edited back to life. Read its `report.blocker`, then write
new tasks (a `source` naming the failed id) that are small enough to pass, and leave
the failed one where it is as the record of what was tried.
