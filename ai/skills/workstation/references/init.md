# init — scaffold the protocol in a repo that has none

Only after confirming with the user: this writes a dozen files at the repo root and
changes how every later session works there. Never run it as a side effect of another verb.

## 1. Learn the repo before writing anything

```bash
ls; cat README.md 2>/dev/null | head -40
ls package.json composer.json pyproject.toml go.mod Cargo.toml Gemfile 2>/dev/null
rg -n '"scripts"' -A15 package.json 2>/dev/null       # the real test/lint/build commands
git log --oneline -15                                  # how this repo commits
ls AGENTS.md CLAUDE.md CONTRIBUTING.md docs/ 2>/dev/null
```

The roles, their scopes and their validation commands come from **this** repo: its
apps, its test runner, its scripts. A role with no code to own is not created. Two apps
in one repo (an API and a web client, say) usually means two code roles, not one.

If the repo already tracks work somewhere else (an issue tracker, a plan file, a
`todo.md`), say so and ask before adding a second system.

## 2. Write, smallest first

```text
AGENTS.md                      # entry point: read order, workflow, owner table. Short.
CLAUDE.md / GEMINI.md          # one line each: follow AGENTS.md
tasks/
  README.md                    # lifecycle, format rules, report shape
  TEMPLATE.yaml
  {backlog,ready,running,blocked,completed,failed}/.gitkeep
agents/
  README.md                    # role table + the contract every AGENT.md follows
  <role>/AGENT.md              # one per role found in §1
findings/
  README.md                    # categories, evidence rule, finding → task
  TEMPLATE.md
  <category>/.gitkeep
docs/decisions/
  README.md                    # format + the register table
  001-<slug>.md                # the decisions already visible in the repo
```

`CONVENTIONS.md` (or `conventions/`) is written only if the repo has rules worth
stating; otherwise the entry point links to what exists (a style config, a doctrine
file) and says the rules live there.

**AGENTS.md holds no rule and no fact** — only the read order, the workflow, and the
table naming the owner of each kind of fact. Everything else links to its owner.

**Each `AGENT.md`**: Identity · Mission · Knowledge · Rules · Scope · Forbidden ·
Input · Output · Validation. The Validation block holds commands that actually exist
in this repo — verify each one runs before writing it down.

**tasks/TEMPLATE.yaml**: id, title, role, status, depends_on, knowledge, scope,
forbidden, steps, done_when, source, an optional `slice`, and an empty `report`
(files_changed, commands_run, unresolved, blocker). Drop a field only if this repo truly has no use
for it; adding one is fine.

## 3. Seed it

- One decision per structural choice already made and visible in the tree (the layout,
  the stack, the auth, the id type). `Source:` says where you read it.
- One or two real tasks in `backlog/`, from what the repo obviously needs next.
  Their `done_when` must run today.
- No invented history: a decision the repo does not actually follow is worse than none.

## 4. Check before handing back

- [ ] Every path in every `AGENT.md` Scope exists.
- [ ] Every Validation command runs (run them).
- [ ] No fact appears in two files.
- [ ] A worker could complete the seeded task reading only its `knowledge`.
- [ ] The register lists every decision file, and every decision names a source.

Then tell the user what was created, in one short list, and what to do first.
