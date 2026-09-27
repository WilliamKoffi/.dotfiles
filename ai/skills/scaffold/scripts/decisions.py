#!/usr/bin/env python3
"""Read the shared decision base and write the chosen decisions into a project.

  decisions.py archs                              list the architectures
  decisions.py offer <arch>                       JSON: the arch's decisions, grouped by system
  decisions.py check <arch> <ID,ID,...>           conflicts and missing requirements, exit 1 if any
  decisions.py write <arch> <ID,ID,...> <target>  write docs/decisions/ + decisions.lock in <target>
"""
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

import yaml

BASE = Path.home() / ".dotfiles/ai/decisions"


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def split(path):
    _, front, body = path.read_text().split("---", 2)
    return yaml.safe_load(front), body.strip()


def catalog():
    decisions = {}
    for path in sorted((BASE / "systems").rglob("*.md")):
        meta, body = split(path)
        decisions[meta["id"]] = {**meta, "body": body, "path": str(path.relative_to(BASE))}
    return decisions


def arch(name):
    path = BASE / "archs" / f"{name}.yaml"
    if not path.exists():
        fail(f"unknown arch: {name}")
    return yaml.safe_load(path.read_text())


def base_commit():
    run = subprocess.run(["git", "-C", str(BASE), "log", "-1", "--format=%h", "--", "."],
                         capture_output=True, text=True)
    return run.stdout.strip() or "uncommitted"


def archs():
    for path in sorted((BASE / "archs").glob("*.yaml")):
        data = yaml.safe_load(path.read_text())
        print(f"{data['id']}\t{data['title']}\tproven in: {', '.join(data.get('proven_in', []))}")


def offer(name):
    decisions, groups = catalog(), {}
    for id_, checked in arch(name)["decisions"].items():
        item = decisions[id_]
        if item["status"].startswith(("superseded", "retired")):
            continue
        groups.setdefault(item["system"], []).append({
            "id": id_, "title": item["title"], "checked": checked, "status": item["status"],
            "conflicts": item["conflicts"], "requires": item["requires"],
            "proven_in": item["proven_in"],
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


def write(name, chosen, target):
    if found := problems(chosen):
        fail("\n".join(found))
    folder = Path(target) / "docs/decisions"
    if folder.exists() and any(folder.glob("[0-9][0-9][0-9]-*.md")):
        fail(f"{folder} already holds decisions; adopt one by one instead")
    folder.mkdir(parents=True, exist_ok=True)
    decisions, commit, today = catalog(), base_commit(), date.today().isoformat()
    rows, lock = [], {"arch": name, "base": str(BASE), "commit": commit, "date": today, "decisions": []}
    for number, id_ in enumerate(chosen, start=1):
        item = decisions[id_]
        local = f"{number:03d}"
        body = item["body"].split("\n", 1)[1].strip()  # drop the shared "# ID — title" line
        (folder / f"{local}-{slug(item['path'])}.md").write_text(
            f"# {local} — {item['title']}\n\n"
            f"- **Status:** {item['status']}\n"
            f"- **Date:** {today}\n"
            f"- **Source:** ai/decisions {id_}@{commit} (proven in: {'; '.join(item['proven_in'])})\n\n"
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
- `decisions.lock` at the root records which shared decisions were taken, at which commit.

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


def main(args):
    match args:
        case ["archs"]:
            archs()
        case ["offer", name]:
            offer(name)
        case ["check", _, ids]:
            check(ids.split(","))
        case ["write", name, ids, target]:
            write(name, ids.split(","), target)
        case _:
            fail(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
