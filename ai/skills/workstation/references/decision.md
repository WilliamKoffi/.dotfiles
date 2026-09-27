# decision — record why

A decision is written when a structural choice is made and would otherwise be
re-litigated: a layout, a boundary, a data shape, a tool, a market rule, a rule
reversal. Not for a preference inside one file, and not for what the code already
says plainly.

## 1. Check the register first

Read the decisions README. If the choice is already there, either it stands (cite the
number and stop) or this is a **reversal** — then §4.

## 2. Write it

Next number in the register, `NNN-<slug>.md`, in the register's own format. The common
shape:

```markdown
# NNN — Title

- **Status:** proposed | locked | superseded by NNN
- **Date:** YYYY-MM-DD
- **Source:** where it comes from
- **Supersedes:** NNN   (only on a reversal)

## Decision
## Why
## Consequences
```

- **Decision**: what holds, in the present tense, in one or two sentences. Not the debate.
- **Why**: the reason that would make someone re-derive the same answer.
- **Consequences**: what now has to be true elsewhere — a doc to update, a task to write,
  a constraint on future work.
- **Source** is mandatory: the user and the date, a finding id, an upstream project's
  decision number, or the note it came from.

`proposed` until the user approves it. Only the user locks a decision.

## 3. Register it

Add the row to the register table in the same commit. A decision that is not in the
register does not exist.

## 4. Reversal

Never edit a locked decision. Write a new one with `Supersedes: NNN`, and make the only
edit that is allowed to the old file: set its status to `superseded by <new>`. Update
both rows in the register.

## 5. Consequences become work

If the decision implies changes, say so and offer to write the tasks (`task.md`) with
`source: decision NNN`. Do not make the changes under the decision verb.
