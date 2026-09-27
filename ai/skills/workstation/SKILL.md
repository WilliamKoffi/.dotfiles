---
name: workstation
description: Run a repository's file-based agent protocol — YAML tasks with a folder lifecycle, a decision register, findings with evidence, and role contracts under agents/. Use when writing a task, running a ready task, recording a decision, filing a finding, reading the board, or explaining a task, decision, finding, role or the protocol itself in plain words (optionally in another language with --lang=fr). The layout is discovered from the working tree, never assumed; `init` scaffolds it where it is missing.
argument-hint: task|run|decision|finding|status|explain|init [subject] [--lang=<code>]
---

# workstation

A workstation is a repository where work is files: one YAML task per unit of work,
one markdown file per decision, one per finding, one contract per role. The folder
is the status. This skill operates that protocol without inventing one — it reads
the repo's own templates and contracts first, and obeys them.

Nothing here is specific to one project. Every path below is *discovered*, and the
repo's own files win over anything this skill assumes.

## 1. Discover the layout (once per session, before any verb)

```bash
ls AGENTS.md CLAUDE.md CONVENTIONS.md 2>/dev/null
ls -d tasks docs/decisions decisions findings agents conventions 2>/dev/null
ls tasks/ 2>/dev/null                      # lifecycle folders = the statuses
cat tasks/TEMPLATE.yaml 2>/dev/null        # the task shape, field for field
ls agents/*/AGENT.md 2>/dev/null           # the roles
git log --oneline -5                       # the commit convention in use
```

Record what exists:

| Element | Typical path | Gives |
|---|---|---|
| Entry point | `AGENTS.md`, else `CLAUDE.md` | read order, workflow, owner table |
| Task system | `tasks/TEMPLATE.yaml` + lifecycle folders | the fields, the statuses |
| Roles | `agents/<role>/AGENT.md` | Scope, Forbidden, Knowledge, Validation |
| Decisions | `docs/decisions/` or `decisions/` | format + register table in its README |
| Findings | `findings/<category>/` + `TEMPLATE.md` | categories, evidence rule |
| Rules | `CONVENTIONS.md`, `conventions/*.md` | what a finding cites |

**Read `tasks/TEMPLATE.yaml` and the role's `AGENT.md` before writing a task — the
fields and section names below are the common case, not a schema to impose.** A repo
whose template has other fields gets those fields.

Nothing found → §5.

## 2. Verbs

| `/workstation …` | Does | Procedure |
|---|---|---|
| `task <what>` | Turns a request, a finding or a plan step into one task per role, in the backlog (or ready when its dependencies are met) | [references/task.md](references/task.md) |
| `run [TASK-NNN]` | Takes a ready task through its role contract: move, change, validate, report, move, commit | [references/run.md](references/run.md) |
| `decision <what>` | Records a decision in the register, with its source and consequences | [references/decision.md](references/decision.md) |
| `finding <what>` | Files a problem seen outside the current scope, with `file:line` evidence | [references/finding.md](references/finding.md) |
| `status` | Reads the board: what is ready, running, blocked, failed; open findings; unresolved reports | [references/status.md](references/status.md) |
| `explain [subject] [--lang=<code>]` | Explains a task, finding, decision, role — or the whole workstation — in plain words, read-only; `--lang` sets the language (default: the user's) | [references/explain.md](references/explain.md) |
| `init` | Scaffolds the protocol in a repo that has none, from what that repo actually is | [references/init.md](references/init.md) |

No verb given → infer it from the request (a problem seen = `finding`, "why do we…" settled = `decision`,
work to do = `task`, "do TASK-NNN" = `run`, "what is TASK-NNN" = `explain`); say which you picked in one line.

## 3. Invariants (every verb)

1. **The folder is the status.** Move with `git mv` and keep the `status` field equal
   to the folder name. Never write a task into a folder its status contradicts.
2. **Ids are global and never reused.** The next id is one past the highest that
   exists in *any* folder, including `failed/` and `completed/`:
   `ls tasks/*/ | grep -o 'TASK-[0-9]*' | sort -u | tail -1`.
3. **A task narrows its role's contract, never widens it.** Every path in `scope`
   is inside the role's Scope; nothing in `knowledge` is outside what the role reads.
   Needing two roles means two tasks linked by `depends_on`.
4. **`done_when` is checkable.** A command with its expected result, or a file fact.
   Never an opinion ("looks right", "is clean").
5. **Every task names its `source`**: a decision, a finding id, a plan step, or the user.
6. **One owner per fact.** Before writing a fact, find who owns it (the entry point's
   owner table) and write it there; everywhere else links. A fact found in two files
   is a finding, not something to fix in passing.
7. **Evidence or nothing.** A finding without `file:line` plus an excerpt or command
   output is not a finding. A report's `commands_run` holds what was actually run and
   what it printed — never what should pass.
8. **Out of scope stays out of scope.** Something wrong outside the task's `scope` is
   a finding; the task does not touch it.
9. **A decision is never edited.** It is superseded by a new one that names it.
10. **Commit as the repo commits.** Read `git log` for the convention (often one commit
    per completed task, `TASK-NNN: <title>`). Follow the repo's attribution rule; if
    `AGENTS.md` or the user forbids a co-author trailer, do not add one.

## 4. Style of the files you write

Match the repo's existing files — read one sibling before writing a new one.
Tasks and findings are terse; they are read by a worker who has no other context.
Write what is verified. "not verified" is a legitimate value; a guess is not.

## 5. The repo has no protocol

Say so in one line, name what is missing, and offer `init`. Never half-apply the
protocol by creating a lone `tasks/` folder mid-task, and never invent ids or
statuses for a repo that tracks work elsewhere (an issue tracker, a plan file):
in that repo, do the work the way that repo does it.
