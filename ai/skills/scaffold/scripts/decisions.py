#!/usr/bin/env python3
"""Read the shared decision base and write the chosen decisions into a project.

  decisions.py stacks                                 list the languages and frameworks to choose from
  decisions.py offer <stack>                          JSON: the decisions offered, grouped by system
  decisions.py check <ID,ID,...>                      conflicts and missing requirements, exit 1 if any
  decisions.py write <stack> <ID,ID,...> <target>     write docs/decisions/ + decisions.lock in <target>

<stack> is a comma-separated list of language and framework systems (`php,php/tempest,ts/solid`).
Generic systems (agents, money, …) are always offered; a framework brings its language along.
"""
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

import yaml

BASE = Path.home() / ".dotfiles/ai/decisions"
SYSTEMS = BASE / "systems"


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def split(path):
    _, front, body = path.read_text().split("---", 2)
    return yaml.safe_load(front), body.strip()


def catalog():
    decisions = {}
    for path in sorted(SYSTEMS.rglob("*.md")):
        meta, body = split(path)
        decisions[meta["id"]] = {**meta, "body": body, "path": str(path.relative_to(BASE))}
    return decisions


def languages():
    """A language is a top-level system folder that holds framework folders."""
    return sorted(p.name for p in SYSTEMS.iterdir() if p.is_dir() and any(c.is_dir() for c in p.iterdir()))


def choosable():
    found = []
    for language in languages():
        found.append(language)
        found += sorted(f"{language}/{p.name}" for p in (SYSTEMS / language).iterdir() if p.is_dir())
    return found


def resolve(stack):
    known, chosen = choosable(), set()
    for system in stack:
        if system not in known:
            fail(f"unknown language or framework: {system} (see `decisions.py stacks`)")
        chosen.add(system)
        chosen.add(system.split("/")[0])
    return chosen


def live(item):
    return not item["status"].startswith(("superseded", "retired"))


def ordered(stack):
    """Generic systems first, then the chosen languages and frameworks; ids in order within each."""
    chosen, langs = resolve(stack), languages()
    items = [item for item in catalog().values()
             if live(item) and (item["system"].split("/")[0] not in langs or item["system"] in chosen)]
    return sorted(items, key=lambda i: (i["system"].split("/")[0] in langs, i["system"],
                                        int(i["id"].rsplit("-", 1)[1])))


def base_commit():
    run = subprocess.run(["git", "-C", str(BASE), "log", "-1", "--format=%h", "--", "."],
                         capture_output=True, text=True)
    return run.stdout.strip() or "uncommitted"


def stacks():
    counts = {}
    for item in filter(live, catalog().values()):
        counts[item["system"]] = counts.get(item["system"], 0) + 1
    for system in choosable():
        print(f"{system}\t{counts.get(system, 0)} decisions")


def offer(stack):
    groups = {}
    for item in ordered(stack):
        groups.setdefault(item["system"], []).append({
            "id": item["id"], "title": item["title"], "status": item["status"],
            "conflicts": item["conflicts"], "requires": item["requires"],
        })
    print(json.dumps(groups, indent=2, ensure_ascii=False))


def problems(chosen):
    decisions, found = catalog(), []
    for id_ in chosen:
        if id_ not in decisions:
            found.append(f"{id_}: unknown")
            continue
        found += [f"{id_} conflicts with {c}" for c in decisions[id_]["conflicts"] if c in chosen]
        found += [f"{id_} requires {r}" for r in decisions[id_]["requires"] if r not in chosen]
    return found


def check(chosen):
    found = problems(chosen)
    print("\n".join(found) or "ok")
    sys.exit(1 if found else 0)


def slug(path):
    return path.split("/")[-1].removesuffix(".md").split("-", 2)[2]


def write(stack, chosen, target):
    if found := problems(chosen):
        fail("\n".join(found))
    order = [item["id"] for item in ordered(stack)]
    if outside := [id_ for id_ in chosen if id_ not in order]:
        fail(f"not offered for this stack: {', '.join(outside)}")
    folder = Path(target) / "docs/decisions"
    if folder.exists() and any(folder.glob("[0-9][0-9][0-9]-*.md")):
        fail(f"{folder} already holds decisions; adopt one by one instead")
    folder.mkdir(parents=True, exist_ok=True)
    decisions, commit, today = catalog(), base_commit(), date.today().isoformat()
    lock = {"stack": sorted(resolve(stack)), "base": str(BASE), "commit": commit, "date": today, "decisions": []}
    rows = []
    for number, id_ in enumerate(sorted(chosen, key=order.index), start=1):
        item = decisions[id_]
        local = f"{number:03d}"
        body = item["body"].split("\n", 1)[1].strip()  # drop the shared "# ID — title" line
        (folder / f"{local}-{slug(item['path'])}.md").write_text(
            f"# {local} — {item['title']}\n\n"
            f"- **Status:** {item['status']}\n"
            f"- **Date:** {today}\n"
            f"- **Source:** ai/decisions {id_}@{commit}\n\n"
            f"{body}\n")
        rows.append(f"| {local} | [{item['title']}]({local}-{slug(item['path'])}.md) | {item['status']} | {id_}@{commit} |")
        lock["decisions"].append({"local": local, "id": id_})
    (folder / "README.md").write_text(REGISTER.format(rows="\n".join(rows)))
    (Path(target) / "decisions.lock").write_text(yaml.safe_dump(lock, sort_keys=False))
    print(f"wrote {len(chosen)} decisions to {folder}")


REGISTER = """# Decisions

Why this project is the way it is. One file per decision: `NNN-<slug>.md`.

## Rules

- A locked decision is never edited. To change it, write a new decision with `Supersedes: NNN` and set the old
  one's status to `superseded by NNN` (the only edit allowed).
- Every decision names its `Source`: a shared decision (`ai/decisions <ID>@<commit>`), a file and line, a commit,
  or the user and a date.
- Check this register before any structural choice.
- `decisions.lock` at the root records the stack chosen and which shared decisions were taken, at which commit.

## Format

```markdown
# NNN — Title

- **Status:** proposed | locked | superseded by NNN
- **Date:** YYYY-MM-DD
- **Source:** ...
- **Supersedes:** NNN (optional)

## Decision
## Why
## Consequences
```

## Register

| # | Decision | Status | Source |
|---|---|---|---|
{rows}
"""


def stack_arg(value):
    return [s for s in value.split(",") if s]


def main(args):
    match args:
        case ["stacks"]:
            stacks()
        case ["offer", stack]:
            offer(stack_arg(stack))
        case ["check", ids]:
            check(ids.split(","))
        case ["write", stack, ids, target]:
            write(stack_arg(stack), ids.split(","), target)
        case _:
            fail(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
