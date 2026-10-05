# run — execute a ready task

Input: a task id, or the first task in `ready/` whose role and dependencies allow it.
Output: the change, a filled `report`, the task in `completed/`, `blocked/` or
`failed/`, and one commit.

## 1. Take it

```bash
cat tasks/ready/TASK-NNN.yaml
ls tasks/completed/ | grep -E 'TASK-(…)'      # every depends_on id, one by one
```

- A dependency is not completed → the task goes back to `backlog/`, say why, stop.
- Then read, in this order: the entry point (`AGENTS.md`), the role's `AGENT.md`,
  the task, and every file in `knowledge`. **Read nothing else.** If the task cannot be
  done from its `knowledge`, that is a defect in the task: add the missing file to
  `knowledge` and say you did, or send it back to `backlog/`.

```bash
git mv tasks/ready/TASK-NNN.yaml tasks/running/
# set status: running in the file
```

## 2. Change

The smallest change that satisfies `done_when`. Only paths in `scope`; never a path in
`forbidden`. Follow the repo's conventions by reading them, not from memory.

Something wrong outside `scope` → a finding (`finding.md`), never a fix. Say in the
report that you filed it.

## 3. Validate

Run the role's Validation block **and** every `done_when` entry. Real commands, real
output. A `done_when` that needs a browser needs the browser — do not mark it passed
from reading the code.

Failing after an honest attempt:
- an outside blocker → `blocked/`, `report.blocker` says exactly what is missing and
  starts with what it waits on, so `status` can sort the board:
  - `human:` — a step only a person can do (a credential, an install, a manual check)
  - `decision:` — a question the user owes
  - `TASK-NNN:` — another task's work, one prefix per task it waits on
- the task cannot pass as written → `failed/`, `report.blocker` says what was tried
  and why it cannot

## 4. Report

Fill every list in `report`:

- `files_changed`: path **and what changed in it**, one line each. Not a bare path.
- `commands_run`: the command and what it printed, each marked pass or fail. Include
  the ones that failed on the way — the report is the record, not a press release.
- `unresolved`: what is left, with the finding id or follow-up task it became.
- `blocker`: only in `blocked/` and `failed/`; in `blocked/`, one line per cause, each with
  its prefix (§3).

## 5. Close

```bash
git mv tasks/running/TASK-NNN.yaml tasks/completed/    # or blocked/ or failed/
# set status to match the folder
git add -A && git commit -m "TASK-NNN: <title>"        # the repo's own convention
```

One commit per task that reaches `completed/`, unless the repo says otherwise.
Attribution follows the repo's rule (`AGENTS.md`); add no trailer it forbids.

Report back in two or three lines: what changed, what passed, what is unresolved.
