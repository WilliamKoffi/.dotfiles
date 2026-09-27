# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""fanin — module-level symbol fan-in counter.

Delegable target per ``shared/forge.md`` §E: pure arithmetic over
normalised occurrence records. It never parses source syntax and never
decides what a finding means — it counts.

``tags[]`` on stdin is ``survey``'s already-merged view of a scope: ctags
definitions (``kind: "def"``) and grep-derived call sites
(``kind: "call"``), keyed on the same ``name``. This script never
disambiguates a call against imports — two definitions sharing a name in
different files both receive credit for an external call under that name.
That is a known, deliberate limit of a name-only heuristic (see
``shared/forge.md`` §E: it computes, ``grain`` concludes), not a bug.

Contract (``shared/forge.md`` §D, §G):

* stdin  -- one JSON object: ``{"files": [str], "tags": [tag]}``
* stdout -- one JSON object, nothing else, no trailing newline
* stderr -- diagnostics, nothing else
* exit   -- 0 on success, non-zero on refusal. Never partial output.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from typing import Any, Final

TAG_KINDS: Final[frozenset[str]] = frozenset({"def", "call"})


class ContractError(ValueError):
    """Raised when stdin does not satisfy the fanin contract."""


@dataclass(frozen=True, slots=True)
class Tag:
    """One normalised occurrence: a definition or a call site."""

    kind: str
    name: str
    path: str
    line: int


@dataclass(frozen=True, slots=True)
class Request:
    """A validated, parsed stdin payload."""

    files: tuple[str, ...]
    tags: tuple[Tag, ...]


@dataclass(frozen=True, slots=True)
class Symbol:
    """One module-level symbol and its fan-in split."""

    name: str
    path: str
    line: int
    internal: int
    external: int


def _ensure_utf8(value: str, field: str) -> str:
    """Reject a string that cannot round-trip through UTF-8.

    The parse boundary is the one place this check belongs (``forge.md``
    §D) — everything downstream trusts that every string it holds is
    valid UTF-8.
    """
    try:
        value.encode("utf-8", errors="strict")
    except UnicodeEncodeError as exc:
        msg = f"{field} is not valid UTF-8: {value!r}"
        raise ContractError(msg) from exc
    return value


def _require_str(obj: Any, field: str) -> str:  # noqa: ANN401 -- parse boundary
    if not isinstance(obj, str):
        msg = f"{field} must be a string, got {type(obj).__name__}"
        raise ContractError(msg)
    return _ensure_utf8(obj, field)


def _require_int(obj: Any, field: str) -> int:  # noqa: ANN401 -- parse boundary
    if not isinstance(obj, int) or isinstance(obj, bool):
        msg = f"{field} must be an integer, got {type(obj).__name__}"
        raise ContractError(msg)
    return obj


def parse_request(raw: Any) -> Request:  # noqa: ANN401 -- the one place Any may appear
    """Walk parsed JSON, validate every field, return frozen dataclasses.

    This is the only function in the module where ``Any`` may appear and
    the only place a runtime type error can originate. It raises on
    anything unexpected rather than coercing it.
    """
    if not isinstance(raw, dict):
        msg = "top level must be a JSON object"
        raise ContractError(msg)

    files_raw = raw.get("files")
    if not isinstance(files_raw, list):
        msg = "'files' must be a JSON array"
        raise ContractError(msg)
    files = tuple(_require_str(f, "files[]") for f in files_raw)

    tags_raw = raw.get("tags")
    if not isinstance(tags_raw, list):
        msg = "'tags' must be a JSON array"
        raise ContractError(msg)

    tags: list[Tag] = []
    for i, entry in enumerate(tags_raw):
        if not isinstance(entry, dict):
            msg = f"tags[{i}] must be a JSON object"
            raise ContractError(msg)
        kind = _require_str(entry.get("kind"), f"tags[{i}].kind")
        if kind not in TAG_KINDS:
            allowed = sorted(TAG_KINDS)
            msg = f"tags[{i}].kind must be one of {allowed}, got {kind!r}"
            raise ContractError(msg)
        name = _require_str(entry.get("name"), f"tags[{i}].name")
        path = _require_str(entry.get("path"), f"tags[{i}].path")
        line = _require_int(entry.get("line"), f"tags[{i}].line")
        tags.append(Tag(kind=kind, name=name, path=path, line=line))

    return Request(files=files, tags=tuple(tags))


def compute_symbols(req: Request) -> list[Symbol]:
    """Count internal and external fan-in for every in-scope definition."""
    scope = frozenset(req.files)

    # Keys, not a set of Symbol: dedupes an exact-duplicate def without
    # losing two distinct definitions that merely share a name.
    defs: dict[tuple[str, str, int], None] = {}
    for tag in req.tags:
        if tag.kind == "def" and tag.path in scope:
            defs[(tag.path, tag.name, tag.line)] = None

    calls_by_name: dict[str, list[str]] = {}
    for tag in req.tags:
        if tag.kind == "call":
            calls_by_name.setdefault(tag.name, []).append(tag.path)

    symbols: list[Symbol] = []
    for path, name, line in defs:
        call_paths = calls_by_name.get(name, [])
        internal = sum(1 for p in call_paths if p == path)
        external = sum(1 for p in call_paths if p != path)
        symbols.append(
            Symbol(
                name=name,
                path=path,
                line=line,
                internal=internal,
                external=external,
            ),
        )

    # Deliberate re-sort, never a reliance on the dict's insertion order:
    # (path, name) per the contract, with line as a deterministic
    # tiebreak for two definitions that share both.
    symbols.sort(key=lambda s: (s.path, s.name, s.line))
    return symbols


def render(symbols: list[Symbol]) -> str:
    """Serialise to the exact byte shape the Nim side must also produce."""
    payload = {
        "symbols": [
            {
                "name": s.name,
                "path": s.path,
                "line": s.line,
                "internal": s.internal,
                "external": s.external,
            }
            for s in symbols
        ],
    }
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def main() -> int:
    """Read stdin, validate, compute, emit once. Never partial output."""
    raw_bytes = sys.stdin.buffer.read()
    try:
        raw_text = raw_bytes.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        sys.stderr.write(f"fanin: stdin is not valid UTF-8: {exc}\n")
        return 1

    try:
        parsed = json.loads(raw_text)
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"fanin: invalid JSON on stdin: {exc}\n")
        return 1

    try:
        request = parse_request(parsed)
    except ContractError as exc:
        sys.stderr.write(f"fanin: {exc}\n")
        return 1

    symbols = compute_symbols(request)
    sys.stdout.write(render(symbols))
    return 0


if __name__ == "__main__":
    sys.exit(main())
