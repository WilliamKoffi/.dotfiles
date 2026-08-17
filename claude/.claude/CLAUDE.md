## Code shaping

Structural work on this machine follows the `grain` doctrine.

- Rules: `~/.claude/skills/grain/shared/convention.md`
- Laravel routing additionally: `~/.claude/skills/grain/shared/crud.md`

Read the relevant file before any structural edit. Do not restate its rules
inline — reference them by section number (`§1.2`, `§C4`).

Pipeline: `/grain:survey <path>` first. It writes `trash/grain/ledger.json`,
which every later wave consumes. Never run a mutating wave without a ledger.

Commit before any `context: fork` wave — fork-applied changes fall outside
session checkpoints and cannot be rewound with `/rewind`.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
