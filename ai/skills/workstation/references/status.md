# status — read the board

Cheap, read-only. Answers: what can be worked on, what is stuck, what is owed.

```bash
for d in tasks/*/; do printf '%s %s\n' "${d#tasks/}" "$(ls "$d" | wc -l)"; done
rg -il 'status:.*\bopen\b' findings/ | grep -v TEMPLATE      # the template's own status syntax
rg -n 'blocker:' tasks/blocked/ 2>/dev/null
```

The status line's syntax differs per repo (`status: open` in YAML, `- **Status:** open`
in markdown) — read the template once and match it, rather than assuming either.

Then report, in this order and no longer than a short table plus a few lines:

1. **Ready** — id, role, title, for each task in `ready/`. These are what can start now.
2. **Running** — anything left in `running/` is an interrupted session: name it, say
   whether its work is in the tree (`git status`), and offer to finish or return it to `ready/`.
3. **Blocked** — id and its `blocker`, verbatim, grouped by prefix: `human:` and
   `decision:` first (they wait on the user), then `TASK-NNN:` (they wait on work). A
   `TASK-NNN:` whose task is now in `completed/` means the blocked task can move.
4. **Failed** — id and why, plus whether a replacement task exists.
5. **Backlog that could move** — tasks whose every `depends_on` is now in `completed/`;
   offer to move them to `ready/`.
6. **Open findings** with no task, worst severity first.
7. **Unresolved** — `report.unresolved` entries in recently completed tasks that never
   became a finding or a task. This is where work quietly disappears; surface it.

End with the one thing you would do next, and why.
