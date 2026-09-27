# fanin.nim -- module-level symbol fan-in counter.
#
# Transliteration of forge/src/fanin.py. Byte-identical output is the
# requirement, not merely equivalent output (shared/forge.md §D). Read
# fanin.py first; this file follows its structure function for function.
#
# Stdlib only: std/json, std/algorithm, std/tables, std/strutils.

import std/json
import std/algorithm
import std/tables
import std/strutils

type
  ContractError = object of ValueError
    ## Raised when stdin does not satisfy the fanin contract.

  Tag = object
    kind: string
    name: string
    path: string
    line: int

  Request = object
    files: seq[string]
    tags: seq[Tag]

  Symbol = object
    name: string
    path: string
    line: int
    internal: int
    external: int

const TagKinds = ["call", "def"] ## sorted; mirrors sorted(TAG_KINDS) in fanin.py

# --- the parse boundary --------------------------------------------------
# Everything in this section is the one place a malformed document is
# allowed to surface as a raised error rather than being coerced.

proc isValidUtf8(s: string): bool =
  ## Hand-rolled UTF-8 validator (no std/unicode — outside the allowed
  ## import list). Rejects overlong encodings, lone surrogates, and
  ## codepoints above U+10FFFF, same as CPython's strict UTF-8 codec.
  var i = 0
  let n = s.len
  while i < n:
    let b0 = byte(ord(s[i]))
    if b0 < 0x80'u8:
      inc i
    elif (b0 and 0xE0'u8) == 0xC0'u8:
      if i + 1 >= n or b0 < 0xC2'u8:
        return false
      let b1 = byte(ord(s[i + 1]))
      if (b1 and 0xC0'u8) != 0x80'u8:
        return false
      i += 2
    elif (b0 and 0xF0'u8) == 0xE0'u8:
      if i + 2 >= n:
        return false
      let b1 = byte(ord(s[i + 1]))
      let b2 = byte(ord(s[i + 2]))
      if (b1 and 0xC0'u8) != 0x80'u8 or (b2 and 0xC0'u8) != 0x80'u8:
        return false
      if b0 == 0xE0'u8 and b1 < 0xA0'u8:
        return false # overlong
      if b0 == 0xED'u8 and b1 >= 0xA0'u8:
        return false # UTF-16 surrogate range, invalid in UTF-8
      i += 3
    elif (b0 and 0xF8'u8) == 0xF0'u8:
      if i + 3 >= n:
        return false
      let b1 = byte(ord(s[i + 1]))
      let b2 = byte(ord(s[i + 2]))
      let b3 = byte(ord(s[i + 3]))
      if (b1 and 0xC0'u8) != 0x80'u8 or (b2 and 0xC0'u8) != 0x80'u8 or
          (b3 and 0xC0'u8) != 0x80'u8:
        return false
      if b0 == 0xF0'u8 and b1 < 0x90'u8:
        return false # overlong
      if b0 > 0xF4'u8 or (b0 == 0xF4'u8 and b1 >= 0x90'u8):
        return false # beyond U+10FFFF
      i += 4
    else:
      return false
  true

proc ensureUtf8(value: string, field: string) =
  if not isValidUtf8(value):
    raise newException(ContractError, field & " is not valid UTF-8")

proc requireStr(node: JsonNode, field: string): string =
  if node.isNil or node.kind != JString:
    raise newException(ContractError, field & " must be a string")
  result = node.getStr()
  ensureUtf8(result, field)

proc requireInt(node: JsonNode, field: string): int =
  if node.isNil or node.kind != JInt:
    raise newException(ContractError, field & " must be an integer")
  node.getInt()

proc getField(obj: JsonNode, key: string, context: string): JsonNode =
  if obj.isNil or obj.kind != JObject:
    raise newException(ContractError, context & " must be a JSON object")
  if not obj.hasKey(key):
    return nil
  obj[key]

proc parseRequest(raw: JsonNode): Request =
  ## Walk parsed JSON, validate every field, return plain records.
  ## Raises ContractError on anything unexpected rather than coercing it.
  if raw.isNil or raw.kind != JObject:
    raise newException(ContractError, "top level must be a JSON object")

  let filesNode = getField(raw, "files", "top level")
  if filesNode.isNil or filesNode.kind != JArray:
    raise newException(ContractError, "'files' must be a JSON array")
  var files: seq[string] = @[]
  for f in filesNode.elems:
    files.add(requireStr(f, "files[]"))

  let tagsNode = getField(raw, "tags", "top level")
  if tagsNode.isNil or tagsNode.kind != JArray:
    raise newException(ContractError, "'tags' must be a JSON array")

  var tags: seq[Tag] = @[]
  for i, entry in tagsNode.elems:
    let ctx = "tags[" & $i & "]"
    if entry.isNil or entry.kind != JObject:
      raise newException(ContractError, ctx & " must be a JSON object")
    let kind = requireStr(getField(entry, "kind", ctx), ctx & ".kind")
    if kind notin TagKinds:
      raise newException(
        ContractError, ctx & ".kind must be one of [call, def], got '" & kind & "'"
      )
    let name = requireStr(getField(entry, "name", ctx), ctx & ".name")
    let path = requireStr(getField(entry, "path", ctx), ctx & ".path")
    let line = requireInt(getField(entry, "line", ctx), ctx & ".line")
    tags.add(Tag(kind: kind, name: name, path: path, line: line))

  Request(files: files, tags: tags)

# --- computation -----------------------------------------------------------
# Pure arithmetic. tags[] is survey's already-merged view of a scope: ctags
# definitions (kind "def") and grep-derived call sites (kind "call"), keyed
# on name. A call is never disambiguated against imports — two definitions
# sharing a name in different files both receive credit for an external
# call under that name. That is a deliberate limit of a name-only heuristic
# (forge.md §E: it computes, grain concludes), not a bug.

proc computeSymbols(req: Request): seq[Symbol] =
  var scope = initTable[string, bool]()
  for f in req.files:
    scope[f] = true

  # Keys, not a table of Symbol: dedupes an exact-duplicate def without
  # losing two distinct definitions that merely share a name. defOrder
  # is first-seen order; the final sort below is what makes the output
  # deterministic, not this order.
  var seen = initTable[(string, string, int), bool]()
  var defOrder: seq[(string, string, int)] = @[]
  for tag in req.tags:
    if tag.kind == "def" and scope.hasKey(tag.path):
      let key = (tag.path, tag.name, tag.line)
      if not seen.hasKey(key):
        seen[key] = true
        defOrder.add(key)

  var callsByName = initTable[string, seq[string]]()
  for tag in req.tags:
    if tag.kind == "call":
      callsByName.mgetOrPut(tag.name, @[]).add(tag.path)

  var symbols: seq[Symbol] = @[]
  for key in defOrder:
    let (path, name, line) = key
    var internal = 0
    var external = 0
    if callsByName.hasKey(name):
      for p in callsByName[name]:
        if p == path:
          inc internal
        else:
          inc external
    symbols.add(
      Symbol(name: name, path: path, line: line, internal: internal, external: external)
    )

  # Deliberate re-sort, never a reliance on table iteration order:
  # (path, name) per the contract, with line as a deterministic tiebreak
  # for two definitions that share both. Nim's string `<` is byte order,
  # matching Python's codepoint order for valid UTF-8 (forge.md §D).
  symbols.sort proc(a, b: Symbol): int =
    if a.path != b.path:
      return cmp(a.path, b.path)
    if a.name != b.name:
      return cmp(a.name, b.name)
    cmp(a.line, b.line)

  symbols

# --- emission ----------------------------------------------------------
# Hand-written, not JsonNode's default `$`: it must match Python's
# json.dumps(sort_keys=True, separators=(",", ":"), ensure_ascii=True)
# byte for byte, which the default serializer does not (forge.md §D).

proc appendEscaped(buf: var string, s: string) =
  buf.add('"')
  var i = 0
  let n = s.len
  while i < n:
    let b0 = byte(ord(s[i]))
    if b0 < 0x80'u8:
      let c = char(b0)
      case c
      of '"':
        buf.add("\\\"")
      of '\\':
        buf.add("\\\\")
      of '\b':
        buf.add("\\b")
      of '\f':
        buf.add("\\f")
      of '\n':
        buf.add("\\n")
      of '\r':
        buf.add("\\r")
      of '\t':
        buf.add("\\t")
      else:
        if b0 < 0x20'u8 or b0 == 0x7F'u8:
          buf.add("\\u")
          buf.add(toLowerAscii(toHex(int(b0), 4)))
        else:
          buf.add(c)
      inc i
    else:
      # Multi-byte UTF-8 sequence -> decode one codepoint. Already
      # validated at the parse boundary, so the shape is trusted here.
      var cp: int
      var seqLen: int
      if (b0 and 0xE0'u8) == 0xC0'u8:
        cp = int(b0 and 0x1F'u8)
        seqLen = 2
      elif (b0 and 0xF0'u8) == 0xE0'u8:
        cp = int(b0 and 0x0F'u8)
        seqLen = 3
      else:
        cp = int(b0 and 0x07'u8)
        seqLen = 4
      for k in 1 ..< seqLen:
        let bk = byte(ord(s[i + k]))
        cp = (cp shl 6) or int(bk and 0x3F'u8)
      i += seqLen
      if cp > 0xFFFF:
        let cpp = cp - 0x10000
        let hi = 0xD800 + (cpp shr 10)
        let lo = 0xDC00 + (cpp and 0x3FF)
        buf.add("\\u")
        buf.add(toLowerAscii(toHex(hi, 4)))
        buf.add("\\u")
        buf.add(toLowerAscii(toHex(lo, 4)))
      else:
        buf.add("\\u")
        buf.add(toLowerAscii(toHex(cp, 4)))
  buf.add('"')

proc render(symbols: seq[Symbol]): string =
  var buf = newStringOfCap(64 + symbols.len * 48)
  buf.add("{\"symbols\":[")
  for idx, s in symbols:
    if idx > 0:
      buf.add(",")
    buf.add("{\"external\":")
    buf.add($s.external)
    buf.add(",\"internal\":")
    buf.add($s.internal)
    buf.add(",\"line\":")
    buf.add($s.line)
    buf.add(",\"name\":")
    appendEscaped(buf, s.name)
    buf.add(",\"path\":")
    appendEscaped(buf, s.path)
    buf.add("}")
  buf.add("]}")
  buf

# --- entry point ---------------------------------------------------------

proc main(): int =
  let rawText = stdin.readAll()
  if not isValidUtf8(rawText):
    stderr.writeLine("fanin: stdin is not valid UTF-8")
    return 1

  var parsed: JsonNode
  try:
    parsed = parseJson(rawText)
  except JsonParsingError as exc:
    stderr.writeLine("fanin: invalid JSON on stdin: " & exc.msg)
    return 1

  var request: Request
  try:
    request = parseRequest(parsed)
  except ContractError as exc:
    stderr.writeLine("fanin: " & exc.msg)
    return 1

  let symbols = computeSymbols(request)
  stdout.write(render(symbols))
  0

quit(main())
