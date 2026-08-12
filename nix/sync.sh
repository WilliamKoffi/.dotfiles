#!/usr/bin/env bash
# Single Responsibility: Seed/sync the Nix packages list from manifest.json to packages.txt
set -euo pipefail

MANIFEST_FILE="$HOME/.nix-profile/manifest.json"
OUT_FILE="$(dirname "$0")/packages.txt"

# Early return if manifest does not exist
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "Error: Nix profile manifest not found at $MANIFEST_FILE" >&2
    exit 1
fi

echo "Syncing active packages against $OUT_FILE (preserving domain sections)..."

python3 -c '
import json, re, sys

manifest_file, out_file = sys.argv[1], sys.argv[2]

try:
    m = json.load(open(manifest_file))
    els = m["elements"]
    items = els.values() if isinstance(els, dict) else els
    active = set()
    for el in items:
        flake = (el.get("originalUrl") or el.get("originalUri") or "").replace("flake:", "")
        attr  = re.sub(r"^(legacyPackages|packages)\.[^.]+\.", "", el.get("attrPath", ""))
        if flake and attr:
            active.add(f"{flake}#{attr}")
except Exception as e:
    print(f"Error parsing manifest: {e}", file=sys.stderr)
    sys.exit(1)

existing_lines = open(out_file).read().splitlines() if __import__("os").path.exists(out_file) else []
known = {line.strip() for line in existing_lines if line.strip() and not line.strip().startswith("#")}

stale = known - active
new = active - known

kept_lines = [
    line for line in existing_lines
    if line.strip().startswith("#") or not line.strip() or line.strip() not in stale
]

if new:
    if kept_lines and kept_lines[-1].strip():
        kept_lines.append("")
    kept_lines.append("# uncategorized (new — sort me)")
    kept_lines.extend(sorted(new))

open(out_file, "w").write("\n".join(kept_lines) + "\n")

for pkg in sorted(stale):
    print(f"  - removed (no longer installed): {pkg}", file=sys.stderr)
for pkg in sorted(new):
    print(f"  + added (uncategorized): {pkg}", file=sys.stderr)
' "$MANIFEST_FILE" "$OUT_FILE"

echo "Done. $(grep -vcE "^\s*(#|$)" "$OUT_FILE" | xargs) packages tracked."
