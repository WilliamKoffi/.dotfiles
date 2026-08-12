---
name: diag-script
description: Write a self-contained diagnostic (or gated fix) bash script to /tmp that the user runs in their own terminal — for anything needing sudo, a real TTY, or a reboot in between. Tees every step live to their terminal and archives per-step logs plus exit codes to a timestamped folder Claude reads back afterward.
argument-hint: [slug] [problem description]
disable-model-invocation: true
allowed-tools: Write, Read, Bash(chmod:*), Bash(ls:*)
---

# Diagnostic Script Writer

For tasks needing commands Claude cannot run in-session, where the user
still wants Claude to see the results — without pasting output back by hand.

## Write scope

Claude writes exactly two paths and nothing else:
- `/tmp/<slug>.sh`
- `/tmp/<slug>/` (created by the script, not by Claude)

The script itself writes only under `$OUT`, except for mutations that are
the explicit point of a `MODE=fix` run.

## Naming

Short task slug: `dmar-diag`, `network-diag`, `disk-diag`.

## Script shape

```bash
#!/usr/bin/env bash
set -uo pipefail

MODE="${MODE:-diag}"                      # diag (default) | fix
BASE=/tmp/<slug>
OUT="$BASE/$(date +%Y%m%d-%H%M%S)"

# refuse a pre-existing dir we don't own (sticky /tmp hazard)
[ -e "$BASE" ] && [ ! -O "$BASE" ] && { echo "$BASE not owned by $USER"; exit 1; }
mkdir -p "$OUT" && chmod 700 "$BASE" "$OUT"
ln -sfn "$OUT" "$BASE/latest"

sudo -v || exit 1                         # one clean prompt, before any output

run_step() {                              # run_step <name> <cmd...>
  local name=$1; shift
  echo "--- $name ---" | tee -a "$OUT/run.log"
  "$@" 2>&1 | tee "$OUT/$name.log"
  printf '%s\t%s\n' "$name" "${PIPESTATUS[0]}" >> "$OUT/status.tsv"
}

run_step env sh -c 'date; hostname; uname -a; cat /etc/os-release'
run_step <step> sudo <command>

if [ "$MODE" = fix ]; then
  echo "MUTATING: <list every change>" | tee -a "$OUT/run.log"
  cp <file> "$OUT/x.before"
  run_step apply sudo <mutating command>
  cp <file> "$OUT/x.after"
  diff -u "$OUT/x.before" "$OUT/x.after" | tee "$OUT/x.diff"
fi

echo "Logs: $OUT" | tee -a "$OUT/run.log"
```

Rules:
- Every command goes through `run_step` — live output via `tee`, plus a
  recorded exit code. Never bare `> file` for output the user needs now.
- `${PIPESTATUS[0]}` is mandatory: with `tee` in the pipe, `$?` is tee's.
- Timestamped run dir + `latest` symlink. Never truncate a previous run.
- Default `MODE=diag` is strictly read-only. All mutation lives behind
  `MODE=fix` and prints its full manifest before executing.
- Idempotent and re-runnable.
- Never log secrets: no bare `env`, no `.env`, no private keys, no
  `journalctl` greps likely to surface tokens. Redact at the source.

## Handoff

Primary — the user runs it in their own terminal (this is the only path
that survives a sudo password prompt):

```
bash /tmp/<slug>.sh
```

`bash <path>`, not `./<path>` — `/tmp` is `noexec` on hardened systems.

Secondary — `! bash /tmp/<slug>.sh` lands output directly in the
conversation, but only works if sudo is NOPASSWD or already cached.
Offer it as an option, don't assume it.

Claude never runs the script itself when it needs sudo: it hangs or fails
silently on a prompt Claude can't answer.

## Read-back

In order, stopping as soon as the answer is clear:
1. `/tmp/<slug>/latest/status.tsv` — which steps failed
2. `/tmp/<slug>/latest/run.log` — step sequence
3. Only the individual step logs that are non-zero or directly relevant.
   `tail -n 200` anything large rather than reading it whole.

Comparing runs: diff `status.tsv` across two timestamped dirs first.

## Cleanup

Scratch artifacts. `rm -rf /tmp/<slug>*` once resolved.
