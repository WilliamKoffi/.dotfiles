# shelf.md — Repository Doctrine (§S0–§S10)

Language-general. Stack-specific enforcement lives in `rules/<stack>.md`.
Consumed by: `skills/shelved`. Cited by: `shared/convention.md` §8.

**Scope:** php only today. The doctrine below is stack-agnostic, but the wave
fires only on families whose rulebook carries a `## shelves` section. See
`rules/families.md`. Opening it to another family means writing that section
first, not loosening the gate.

---

## §S0 — Scope

This doctrine governs any class whose job is to *retrieve or persist a set of
entities*: repository, DAO, query object, gateway, store, finder, mapper.

It does not govern entities themselves (`shared/convention.md`, domain wave),
HTTP controllers (`shared/crud.md`), or presentation.

A class is in scope if removing it would leave callers writing raw queries.

---

## §S1 — The Fixed Vocabulary

Every shelf may implement only these seven:

| Method | Kind | Contract |
|---|---|---|
| `all()` | read | everything on the shelf |
| `paginate($perPage)` | read | the shelf, paged |
| `find($id)` | read | one by identity, **throws** if absent |
| `first()` | read | the first item, or null |
| `count()` | read | how many are on the shelf |
| `save($entity)` | write | insert or update |
| `remove($entity)` | write | delete |

A method name outside these seven is a violation. The name of the *method*
never varies; the name of the *shelf* carries all the meaning.

Four of the seven are load-bearing (`all`, `find`, `save`, `remove`). The other
three are conveniences that earn their place by being universal. The number is
fixed so that reading one shelf teaches you every shelf.

---

## §S2 — Subset Yes, Superset Never

A shelf may implement fewer than seven. A read-only projection may expose only
`all()`. A write-only sink may expose only `save()`.

A shelf may never implement an eighth. Adding a method is always the wrong fix
— it is §S3 wearing a disguise.

---

## §S3 — Custom Query → New Shelf

If a query does not fit the vocabulary, create a shelf whose **name is the
result set**. Noun the filter, then shelve it.

```
findActiveUsers()             → ActiveUsers::all()
getExpiringSubscriptions()    → ExpiringSubscriptions::all()
fetchTopSellers(10)           → TopSellers::all()
findUnpaidInvoicesFor($client) → UnpaidInvoices::for($client)->all()
```

Name it as a **plural noun phrase describing the set**. Never an action, never
an agent suffix. `ActiveUsers` — not `UserFinder`, `UserFetcher`, `UserQuery`,
or `UserSearchService`. The agent-noun ban is stated once in
`convention.md`; this section is its persistence-layer instance, not a
second rule.

---

## §S4 — Scope Belongs to Construction

Parameters that narrow **which shelf** belong in the constructor. Parameters
that narrow **which items** are a smell — those are a different shelf.

```
new TeamMembers($team)              ✅ scope binding — the parent is identity
$members->all()                     ✅ vocabulary unchanged
$members->all(['active' => true])   ❌ filter argument → ActiveTeamMembers
```

This is the repository equivalent of a nested resource controller.

---

## §S5 — Ordering and Limiting Are Identity

Sort order and result limits are never arguments. `MostRecentPosts` and
`PopularPosts` are two shelves, not one shelf with `$orderBy`.

If the caller can reorder the result, the vocabulary has leaked and every
caller will invent its own.

`paginate($perPage)` is the single exception: page size is a transport concern,
not a query concern.

---

## §S6 — Never Return a Query Builder

The moment a shelf returns a builder, a queryset, an `IQueryable`, or anything
else with a fluent `where`, the seven-method limit is gone. Every caller becomes
its own repository, and the shelf is decoration.

Return: an entity, a collection of entities, a scalar, or null. Nothing else.

This is the one violation that invalidates the whole class rather than one
method. Flag it first and fix it first.

---

## §S7 — The Criteria Escape Hatch

Genuinely open-ended, user-driven search — a filter panel where the user picks
the axes at runtime — cannot be enumerated as shelves. For that, and only that:

```
$shelf->matching(new Criteria($input))->all()
```

Bounds on the hatch:

- `matching()` is the **only** sanctioned eighth method, and only on shelves
  that document why enumeration is impossible.
- `Criteria` is a value object with named, typed axes. It is not a key/value
  bag and never carries raw SQL or builder fragments.
- Fixed, known filters do not qualify. "Active users" is §S3, not §S7.

If more than one shelf in the codebase needs `matching()`, the design is wrong
somewhere else.

---

## §S8 — One Shelf, One File

A shelf class lives in its own file, named for the class. Shelves related by
scope may share a directory; they never share a file.

File and directory naming defers entirely to `convention.md`. This wave does
not rename existing files — creating is in scope, `git mv` is not.

---

## §S9 — Write Scope

`skills/shelved` may create and edit files in the data-access tree, and may
edit call sites **only** where the call site is itself a shelf.

Any required change to a controller, an entity, a view, or a test is out of
scope: open a finding of kind `boundary` and defer. A wave that reaches outside
its tree is the collision the ledger exists to prevent.

---

## §S10 — Behavior Preservation

A shelf rewrite must return the same rows, in the same order, with the same
laziness and the same absence semantics (`null` vs throw). Query count may
change; results may not.

Where the legacy behavior is itself wrong, do not fix it here. Record it as a
`defect` finding. Correctness changes and structural changes never ship in the
same commit — see the legacy red line in `convention.md`.
