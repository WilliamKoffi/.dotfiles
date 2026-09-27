---
name: scaffold
description: Start a new project's decision register from the shared decision base in ~/.dotfiles/ai/decisions — pick an architecture, take or skip each decision it offers, then write docs/decisions/ and decisions.lock into the project. Use when starting or bootstrapping a project, or when the user asks which shared decisions a project should take.
argument-hint: [arch] [target-dir]
disable-model-invocation: true
---

# scaffold

Writes a new project's `docs/decisions/` from the shared base. The base owns the text
(`~/.dotfiles/ai/decisions/README.md` holds its rules and format); this skill only picks and
copies. All reads and writes go through `scripts/decisions.py`, never by hand.

```bash
D=~/.claude/skills/scaffold/scripts/decisions.py
```

## 1. Target

- Target = second argument, else the current directory. State it; don't ask.
- `ls <target>/docs/decisions` holds `NNN-*.md` files → stop. This skill starts a register;
  it does not merge into one. Say so and offer to adopt decisions one at a time instead.

## 2. Architecture

- First argument given and in `python3 $D archs` → use it.
- Otherwise ask one AskUserQuestion with each arch as an option (title + `proven in`), and let
  "Other" through: the user names a new arch → go to §6 before continuing.

## 3. Decisions

1. `python3 $D offer <arch>` → decisions grouped by system, each with `checked`.
2. Ask with AskUserQuestion, `multiSelect: true`, **one question per system**, header = the
   system name, at most 4 questions per call and 4 options per question (split a system in
   two questions if it offers more). Option label = `<ID> <short title>`; description = the
   title, `proven in`, and `(pre-checked)` when `checked: true`. List pre-checked options first.
3. Conflicting decisions (`conflicts`) in one system: ask them as a single-select question
   instead (e.g. package manager: STK-001 pnpm / STK-002 bun).
4. Show the final list as one table (id, title, taken/skipped) before writing.

## 4. Check, then write

```bash
python3 $D check <arch> <ID,ID,...>     # conflicts, missing requires; fix with the user, re-run
python3 $D write <arch> <ID,ID,...> <target>
```

`write` numbers the files `001…` in the order of the arch, writes the register
`docs/decisions/README.md`, and `decisions.lock` (arch, base commit, local number → id).
Each file's `Source:` is `ai/decisions <ID>@<commit>`.

Base commit reads `uncommitted` → tell the user the base has uncommitted changes and the lock
cannot be traced back until they commit `~/.dotfiles`.

## 5. After

- AGT-003 taken and no `tasks/` in the target → offer `/workstation init` for the rest of the
  protocol (it finds this register and keeps it).
- Don't commit in the target. Say which files were written.

## 6. Growing the base

Only on the user's say-so, and in `~/.dotfiles/ai/decisions/`:

- **New decision**: next id in its system, format and rules from the base README, `proven_in`
  names a real project and local id. Add it to the register table and to each arch that
  should offer it.
- **New arch**: `archs/<id>.yaml` listing the decisions it offers, `true` = pre-checked.
- **Change**: never edit a locked decision; write a new one with `supersedes`.

Don't commit `~/.dotfiles` on the user's behalf.
