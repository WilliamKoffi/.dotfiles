# todo

Daily TODO file manager. Replaces the Bash `todo()` function that used to
live in `bash/.config/bash/functions.sh`.

The compiled binary lives at `~/.local/bin/todo` and is **never committed** —
this repository is public. Only the Nim source is tracked.

## Behaviour

Working directory is `~/lab/temp/todos`, created if missing. Today's file is
`TODO.YYYYMMDD.md`.

1. If today's file exists, open it and stop.
2. Otherwise seed it from yesterday's file; failing that from the most recent
   `TODO.YYYYMMDD.md` older than today; failing that create it empty.
3. If the seed removed nothing, the source is **renamed** to today's name
   instead of copied (below).
4. Archive old TODO files and harvest completed detail work (below).
5. Open the result in `nvim`, with the todos directory as the working
   directory.

`--dry-run` reports every step without writing anything — no directory, no
seeded file, no archive — and does not open the editor.

## Extraction

Seeding and detail harvesting both run the tree extractor in
`src/todopkg/tree.nim`. The document is parsed into sections, tasks and notes,
and then:

- `- [x]`, `- [X]` and `- [-]` are removed **together with their entire
  subtree**;
- `- [ ]` is never removed, but is recursed into, so a completed child is still
  extracted from an open parent. An open parent whose children were all
  completed survives, childless;
- a note is never removed on its own;
- a section survives only if something remains inside it — a task, a note, or a
  surviving child section — evaluated bottom-up, so a parent whose children all
  collapsed collapses too.

Headers nest at any depth, and a tab indents to the next multiple of four so
tab- and four-space-nested children behave alike. `- []` (no space between the
brackets) is a note, not a task, which is how the existing files use it.
Everything that survives keeps its original text, indentation and order;
nothing is reformatted.

### Days where nothing was completed

If extraction removes nothing, today's file would be a byte-for-byte copy of
the source: that is the same list continuing, not a new day. The source is
renamed to today's name rather than copied, so a quiet week leaves one file
instead of seven identical ones and `archives/` only ever receives states that
actually differ. The date on the file therefore reads as *the day this list was
last carried forward*, and the number of days it sat untouched is not recorded.

Renaming still normalises: `extract()` trims trailing blank lines, so the
carried-forward file is rewritten when its render differs from the source even
though no task was removed.

### Legacy: `clean.nim`

`src/todopkg/clean.nim` is a byte-identical port of the original `clean_todo()`
AWK program, verified against all 125 `.md` files in the todos tree plus 400
generated adversarial cases. **It is no longer on any code path** — it is kept,
with its tests, because it encodes the contract the existing files were written
against, and it is the fallback if the tree extractor misbehaves.

It cannot replace the tree: it has no nesting (so an emptied parent section is
not computable), it recognises only `## `, it deletes a section holding only
notes, it counts a tab as one column, and its `NR<=2` rule means a completed
item on line 1 or 2 is never extracted at all.

## Archive rules

Everything lands under `~/lab/temp/todos/archives/`, preserving the path
relative to the todos root. `archives/` is never a source: TODO scanning is
non-recursive and detail scanning is rooted at `details/`, so it cannot
recurse into its own output.

### TODO files

A **TODO file** is `TODO.YYYYMMDD.md` directly in the todos root. Anything
else (`TODO.cleared.md`, `README.md`) is left alone.

The two newest by date are retained — today's file and the most recent file
older than today — and the rest move verbatim into `archives/`, flat, because
root files have no relative subpath. Retaining "the newest older file" rather
than literally yesterday is what keeps the fallback in step 2 working after a
skipped day.

Files are moved, not cleaned: an archived day is a record of that day.
An existing archive is never overwritten; a collision gets a `.1`, `.2` suffix.

### Detail files

A **detail file** is any `*.md` under `details/`, at any depth. These are the
files the TODO overview links into (`./details/...`).

Detail files are never moved and never deleted. Completed work is extracted
from the live file and **appended** to

```
archives/details/<same relative path>/<name>.<YYYYMMDD>.md
```

so `details/shop/customer.md` archives to
`archives/details/shop/customer.20260826.md`. The date is the run's date and
lives in the filename, so an archived detail is identifiable without opening
it; each day gets its own file, and two runs on the same day append to that
day's file rather than overwriting it.

The live file keeps only open work. If everything in it was completed the file
is left empty rather than deleted — including its title, since a section with
nothing left in it is removed like any other.

There is no date rule for detail files: harvesting is content-driven and runs
on every invocation. It is idempotent — a file with nothing completed is not
rewritten at all.

Lowercase kebab-case is the convention for detail paths
(`details/shop/product-stock.md`). The program mirrors whatever path exists and
never renames anything.

## First-run compilation

`todo()` in `bash/.config/bash/functions.sh` is a bootstrap, not an
implementation. It compiles and installs the binary when

- `~/.local/bin/todo` does not exist, or
- any file under `src/`, or `todo.nimble`, or `config.nims`, is newer than it
  (`find -newer -print -quit`, so a couple of stat calls in the common case).

Otherwise it hands straight over to the binary — there is no compilation on a
normal invocation.

The binary `cd`s into the todos directory before opening the editor, so `nvim`
starts with the workspace as its working directory (this is what makes `:e
details/...` and fuzzy-finding work) and `--dir` is honoured. A child process
cannot change its parent's cwd, so the function `cd`s as well afterwards, which
leaves the *shell* in the todos directory as the old implementation did.

Build artifacts go to `$XDG_CACHE_HOME/todo-build` (`config.nims` forces
`--outdir` there, so even a bare `nim c src/todo.nim` inside the repository
cannot drop an executable into it). `.gitignore` is the second line of defence,
and `scripts/.stow-local-ignore` stops stow from symlinking this directory into
`~/todo`.

## Usage

```
todo                      # the daily flow
todo --dry-run            # show what a run would do, changing nothing
todo --dir <path>         # operate on another todos directory
todo --today YYYYMMDD     # override today's date
todo --no-archive         # skip archiving and harvesting
todo --help
```

## Tests

```
nim c -r --outdir:/tmp/todo-tests tests/test_tree.nim    # extraction rules
nim c -r --outdir:/tmp/todo-tests tests/test_clean.nim   # legacy AWK contract
```
