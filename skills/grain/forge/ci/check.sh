#!/usr/bin/env bash
# forge/ci/check.sh -- grain's own CI for the forge helper.
#
# Runs in grain's CI only. Never shipped to a user's machine
# (shared/capability.md §3, "Meta toolchain": ruff, ty, and mypy are
# deliberately absent from every probe table).
#
# Stages, in order: Python format, Python lint, Python types, Nim check,
# the three-way differential, then a determinism check. Any stage failing
# fails the whole script (set -e), and the differential/determinism
# stages below add their own explicit checks on top of that.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SRC_DIR="../src"
FIXTURE_DIR="../fixture"
PY_SRC="$SRC_DIR/fanin.py"
NIM_SRC="$SRC_DIR/fanin.nim"
INPUT="$FIXTURE_DIR/input.json"
EXPECTED="$FIXTURE_DIR/expected.json"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "== 1. ruff format --check =="
uv run --no-project --with ruff ruff format --check "$PY_SRC"

echo "== 2. ruff check =="
uv run --no-project --with ruff ruff check "$PY_SRC"

echo "== 3. ty check =="
uv run --no-project --with ty==0.0.71 ty check "$PY_SRC"

echo "== 4. nim check =="
nim check --hints:off "$NIM_SRC"

echo "== 5. differential: python == nim == expected, byte for byte =="
NIM_BIN="$WORK_DIR/fanin"
nim c -d:release --hints:off --nimcache:"$WORK_DIR/nimcache" -o:"$NIM_BIN" "$NIM_SRC" \
  > /dev/null

PY_OUT="$WORK_DIR/py.out"
NIM_OUT="$WORK_DIR/nim.out"
python3 "$PY_SRC" < "$INPUT" > "$PY_OUT"
"$NIM_BIN" < "$INPUT" > "$NIM_OUT"

cmp -s "$PY_OUT" "$EXPECTED" || {
  echo "FAIL: python output diverges from fixture/expected.json" >&2
  diff "$PY_OUT" "$EXPECTED" >&2 || true
  exit 1
}
cmp -s "$NIM_OUT" "$EXPECTED" || {
  echo "FAIL: nim output diverges from fixture/expected.json" >&2
  diff "$NIM_OUT" "$EXPECTED" >&2 || true
  exit 1
}
cmp -s "$PY_OUT" "$NIM_OUT" || {
  echo "FAIL: python and nim disagree with each other" >&2
  diff "$PY_OUT" "$NIM_OUT" >&2 || true
  exit 1
}
echo "three-way match confirmed"

# == 6. determinism ==
# This is the stage a reader will want to cut -- it looks redundant with
# stage 5, which already ran the Python side once successfully. It stays:
# a hash-order dependency in a dict/set-shaped bug is invisible on a
# single run and would surface later as a quarantine nobody can
# reproduce, on a run that happened to pick an unlucky seed. Proving three
# different seeds agree is what stage 5 alone cannot prove.
echo "== 6. determinism: three PYTHONHASHSEED values, byte-identical each time =="
for seed in 0 1 42; do
  OUT="$WORK_DIR/py.$seed.out"
  PYTHONHASHSEED="$seed" python3 "$PY_SRC" < "$INPUT" > "$OUT"
  cmp -s "$OUT" "$EXPECTED" || {
    echo "FAIL: PYTHONHASHSEED=$seed produced different output" >&2
    diff "$OUT" "$EXPECTED" >&2 || true
    exit 1
  }
done
echo "determinism confirmed across seeds 0, 1, 42"

echo
echo "ALL CHECKS PASSED"
