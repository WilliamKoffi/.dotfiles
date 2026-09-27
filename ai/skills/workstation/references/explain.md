# explain — say what something is, in plain words

Read-only. For a reader who was not there: a newcomer, the user coming back after a
week, a stakeholder. Answers "what is this, why does it exist, where does it stand".

## 1. Resolve the subject

| Subject | Read |
|---|---|
| `TASK-NNN` | the task file (any folder), its `source`, its role's `AGENT.md`, the tasks in `depends_on` |
| `FIND-NNN` | the finding, the rule it cites, the task that references it (`rg -l 'FIND-NNN' tasks/`) |
| a decision (number or title) | the decision, the one it supersedes, and what supersedes it, if anything |
| a role (`agents/<role>`) | its `AGENT.md`: Scope, Forbidden, Knowledge, Validation |
| nothing, or `protocol` | the entry point and the layout from SKILL.md §1 — explain the workstation itself |

Ambiguous subject → pick the likeliest match and say which in one line. Not found →
say so; never explain a file you have not read.

## 2. Language

`--lang=<code>` (`fr`, `en`, `es`, …) sets the language of the explanation. Absent →
the language the user is writing in.

Only the prose is translated. Ids, paths, field names, statuses, role names, commands
and quoted excerpts stay verbatim — they are what the reader will search for.
`status: blocked` stays `status: blocked`; the sentence around it is in the target language.

## 3. Say it

In this order, short paragraphs, no more than a screen:

1. **What it is** — one sentence, no jargon from the protocol unless defined.
2. **Why it exists** — its `source` chain, followed back to the user, a decision or a finding.
3. **Where it stands** — status (from the folder), what it waits on or what it unblocked.
4. **What it touches** — scope, role, the files or rules involved, as links.
5. **What happens next** — the next step under the protocol, and who takes it.

Only what the files say. Unknown is written as unknown (in the target language), never
guessed. Explain changes nothing — no moves, no edits, no commits.
