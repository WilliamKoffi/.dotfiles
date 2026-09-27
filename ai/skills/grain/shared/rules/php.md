# Family php

Extensions: `.php`, `.blade.php`

Two distinct profiles. Always resolve `.blade.php` before `.php`.

---

# Profile: php

## slice

### The dot convention does NOT apply

PSR-4 requires the file name to match exactly the name of the class it
contains. `payment.service.php` breaks autoloading.

    <ClassName>.php        in StudlyCase

The role is carried by the **namespace and the directory**, which are PHP's
native equivalent of the suffix:

    app/Services/PaymentService.php     -> App\Services\PaymentService
    app/Models/User.php                 -> App\Models\User
    app/Http/Controllers/OrderController.php

Never introduce a dot into a PHP file name other than a view.

### Structure

- Vertical slice under `app/Features/<Feature>/` or Laravel modules, depending
  on what the project already uses. Do not impose one when the other is in
  place: record a finding and leave the choice open.
- `composer.json`: update the PSR-4 mapping after any namespace move, then
  `composer dump-autoload`.
- One file = one class. No secondary class at the end of a file.
- Check string references: `config/`, the service container, `::class` in
  migrations. A bare `git mv` is not enough in PHP.

## domain

- Value objects rather than correlated primitives. Three correlated scalar
  arguments in a signature = finding.
- Return types declared everywhere. No bare `array` when the shape is known:
  declare a DTO or a dedicated object.
- `declare(strict_types=1)` at the top of every file.
- PHP 8.1 enum for every closed set of values currently held in class constants
  or strings.

No `## literal` section for this profile: the extraction above happens directly
here, in the `domain` wave. The `literal` wave (3) has nothing to do on `.php`.

## cruddy

The only family where this wave applies. The rules live in `../crud.md`
(§C1 to §C12) and the examples in
`../../skills/cruddy/references/laravel.md` — do not repeat them here. This
section carries only what is specific to the php profile.

- Detection perimeter: `app/Http/Controllers/**` for action shape, `routes/**`
  for path shape. A file outside both is analyzed in `affordance`, not here.
- Any routed public method outside the seven verbs is a `C1` finding.
  `__invoke()` counts as conforming (§C6).
- `attach()` / `detach()` inside an action body: `C4` finding, no exception. The
  pivot becomes a model.
- `find($id)` in an action: `C9.0` finding. Route model binding everywhere.
- Inline validation in the action rather than a FormRequest: `C8` finding.
- Business logic in the action body: `C8` finding, **deferred to
  `affordance`**. This wave reshapes routing; it does not extract domain.

### Route path detection

Signatures for `../crud.md` §C9.1–§C9.8. The rules are there; only the greps
are here.

| Rule | Signature |
|---|---|
| C9.1 | `Route::get(` / `Route::any(` whose handler matches `store\|update\|destroy\|delete\|save\|send\|cancel\|process\|confirm\|toggle`, or whose action body contains `->save()`, `->delete()`, `->update(`, `::create(` |
| C9.2 | `Route::(get\|any)\('\{[a-z_]+\}'` with no `->where(` on the chain |
| C9.3 | a segment matching `^(get\|set\|update\|delete\|remove\|add\|create\|check\|download\|upload\|send\|fetch\|list\|show\|do)-` |
| C9.4 | path ending `/store`, `/update`, `/destroy`, `/create`, `/edit`, or containing `/delete/{` |
| C9.5 | duplicates after sort/uniq over extracted `(method, path)` pairs, and over `->name('...')` values |
| C9.6 | path literal containing `[A-Z]` or `_` outside `{...}` |
| C9.7 | first segments colliding after naive de-pluralisation — candidates only |

C9.3's prefix list is the rule's closed set. Extend it here, never in
`crud.md`.

Two census patterns are **not mechanically detectable** and are therefore not
rules: a vendor or brand name used as a URI segment, and a qualifier placed
before its owner (`archived/orders` where the shape is `orders/archived`). Both
require knowing what the words mean. They surface, if at all, in human review.
An undetectable rule is doctrine that never runs; writing one down only makes
this section look more complete than it is.

**C9.8 condition 2 command**, run once per candidate path:

    rg -n --fixed-strings '<old-path-literal>' \
       resources/ public/ config/ tests/ app/Mail/ app/Notifications/ \
       app/Http/Middleware/ app/Providers/ bootstrap/ database/seeders/ \
       -g '!vendor' -g '!node_modules'

`routes/` is absent deliberately — it is already this wave's perimeter, so a
cross-referencing redirect is visible without a second sweep. The other trees
each hide a literal that no test would catch: `tests/` holds path assertions
this wave may not repair (§C9.8 condition 2), `app/Http/Middleware/` holds the
CSRF `$except` array, where a rewritten webhook path silently starts returning
419, and `app/Providers/` plus `bootstrap/` hold route-adjacent config and
redirect targets.

Zero hits is necessary and never sufficient — conditions 1 and 3 still apply.

**Precedence — C1 against C9.1.** `Route::get('subscription/cancel', ...)`
bound to `cancel()` violates both: a method outside the seven (C1), and a safe
method reaching a writer (C9.1). It is **one finding, raised as C9.1**, with
the C1 violation recorded in the same note. C1's disposition is a rewrite this
wave performs; C9.1's is a defect it must not touch. The stricter disposition
wins, per `../convention.md` §0 — moving `cancel()` onto a resource controller
while it is still reachable by `GET` preserves the defect and hides it behind a
conforming name.

**Closures in `routes/`.** A closure route is a route with no controller. If
nothing references its name, it is dead code and belongs to `survey` item 5,
not to §C9. Do not raise a shape finding against a path that should not exist
at all.

**Boundary with `affordance`.** Both waves touch controllers and will step on
each other if you are not careful. The cut: `cruddy` decides *which action lives
on which controller*, `affordance` decides *what should not be in a controller
at all*. A `*Service` injected into a properly split controller is not a
`cruddy` finding.

**Deliberate collision with the idiom**, of the same nature as the one noted in
`affordance`: Laravel tolerates controllers with custom actions and the official
documentation shows them. This rule rejects them. Do not "fix" toward the idiom.

## shelves

Implements `../shelf.md` §S0–§S10 for Eloquent. Consumed by
`../../skills/shelved` when `ledger.stack` is `laravel` or `php`.
Before/after examples: `../../skills/shelved/references/patterns.md`.
Do not restate here what `shelf.md` already says — this section carries only
what is specific to Eloquent.

**Boundary with `cruddy`**: `cruddy` owns `app/Http/**`, `shelved` owns the
data-access tree. Both rename classes, never the same ones. A rewrite here that
would require touching a controller is abandoned and opens a `boundary`
finding.

### P-S1 — What counts as a shelf

In scope: `App\Repositories\*`, any class ending `Repository`, `Dao`, `Query`,
`Finder`, `Gateway`, or `Store`, and any class whose methods return
`Collection`/`Model`/`LengthAwarePaginator` built from a query.

Out of scope: Eloquent models themselves, form requests, resources, policies.
An Active Record model is not a shelf — do not wrap models in shelves that
exist only to call `Model::all()`.

### P-S2 — Local scopes are not an exemption

```php
User::active()->get();           // ❌ builder leak at the call site (§S6)
(new ActiveUsers)->all();        // ✅
```

A local scope may live on the model and be used *inside* a shelf. It may never
be chained by a caller. Chaining is how the vocabulary escapes.

### P-S3 — Builder leaks, concretely (§S6)

Any return type of `Builder`, `EloquentBuilder`, `Relation`, `HasMany`,
`BelongsToMany`, or `QueryBuilder` is a violation, including implicit returns
of `$this->model->where(...)`. Terminate every query inside the shelf with
`get()`, `first()`, `firstOrFail()`, `count()`, `paginate()`, `save()`, or
`delete()`.

### P-S4 — Scope binding via constructor (§S4)

```php
final class TeamMembers
{
    public function __construct(private Team $team) {}

    public function all(): Collection
    {
        return $this->team->members()->get();
    }
}
```

Bind the parent model, not its id. Route-model binding already resolved it.

### P-S5 — Pivot shelves

A pivot promoted to a real model by `shared/crud.md` gets its own shelf:
`Subscriptions`, `Enrollments`, `Likes`. `attach()` / `detach()` never appear
outside a pivot shelf's `save()` / `remove()`.

### P-S6 — `find()` throws

`find($id)` maps to `findOrFail($id)` and returns `Model`, never `?Model`. Use
`first()` when absence is expected and returns null. Two different questions,
two different methods — do not collapse them into a nullable `find()`.

### P-S7 — Laziness

Return `Collection` from `all()`. Use `LazyCollection` only where the legacy
code already used `cursor()`; introducing or removing laziness changes memory
behavior and violates §S10.

### P-S8 — Eloquent Criteria (§S7)

```php
$shelf->matching(new UserCriteria($request->validated()))->all();
```

`UserCriteria` is a readonly class with typed nullable properties, one per
search axis. It exposes `applyTo(Builder $q): Builder` and is the only place a
builder is legally passed around — inside the shelf, never across its boundary.

### P-S9 — Naming and location

`app/Repositories/{Set}.php`, class `final class {Set}`. Plural noun phrase,
no `Repository` suffix on new shelves — `ActiveUsers`, not
`ActiveUsersRepository`. Existing `*Repository` classes keep their filename
until `grain:drift` runs; record them in `findings[].rename_pending[]`.

### P-S10 — Container binding

If an interface exists (`UserRepositoryInterface`), do not create a second
abstraction. Either the interface is the shelf's contract — in which case it
holds exactly the seven methods — or it is dead weight, and the shelf is bound
concretely. Never leave both an eight-method interface and a seven-method
implementation.

---

## affordance

- Remove agent nouns: `*Manager`, `*Service`, `*Handler`, `*Helper`,
  `*Engine`, `*Repository` with no real persistence.
- Move the method to the entity holding the state.
  `PaymentService::charge($order)` -> `$order->charge()`.
- God object: `User::createSubscription()` -> `Subscription::start($user)`.
- Stateless -> final class with static methods, or a function in a namespace
  file. No ceremonial instantiation.
- Controllers: if a controller coordinates three unrelated responsibilities,
  extract a domain name, not a service.

**Deliberate collision with the idiom.** The Laravel ecosystem encourages
`*Service` classes and the Action pattern. This rule rejects them in favor of
the affordance. It is a deliberate project choice, not a mistake: do not "fix"
toward the Laravel idiom. If a `*Service` is imposed by a third-party package,
record an exemption and leave it.

## split

- Inspection threshold: 150 lines. A trigger for review, not an order to cut.
- A controller beyond seven public methods = structural finding, not a size
  problem.
- Traits: extract only if the behavior is genuinely shared by two or more
  classes. A trait with a single consumer moves noise around, it does not
  decompose anything.

### `routes/` decomposition

Raised by `survey` as `kind: "route-file"`, `wave: "split"`. A root routes file
past the inspection threshold becomes a folder of leaf files `require`d from
it. Two constraints, both blocking.

**Middleware stays in the root file.** A leaf carries route declarations only,
and is `require`d from inside the group whose contract it inherits:

    routes/
      web.php              ← middleware groups, prefixes, and the require calls
      web/
        billing.php        ← Route::… declarations only
        vcard.php
        admin.php

Re-declaring `->middleware([...])` inside a leaf duplicates the auth contract.
A merge that drops one such line silently removes `auth` or `subscription` from
every route in that file — no test fails, and the diff does not read as a
security change. A leaf containing a middleware declaration is a blocking
finding, never an exemption candidate.

**Load order must not be load-bearing.** Do not decompose while a `C9.2`
finding is open (`../crud.md` §C9.2). Before the split, precedence is enforced
by physical position in one file; after it, by `require` order across several,
and nothing tests that. Constraining the parameter first makes the split
order-independent.

**Naming carve-out.** The `## slice` convention above is a PSR-4 class-file
rule and does not reach `routes/`, which autoloads nothing. Leaf files are
lowercase kebab-case, named for the resource group they carry —
`routes/web/billing.php`. `split` invents no other scheme here.

**Boundary with `cruddy`.** Both waves write `routes/`. The cut: `cruddy`
rewrites *declarations* — path, method, name, constraint — and creates no file
under `routes/`. `split` decides *which file a declaration lives in* and alters
no declaration. Same shape as the `cruddy`/`affordance` boundary above: one
wave owns content, the other placement.

## lexicon

- Classes: StudlyCase. Methods: camelCase. Constants: SCREAMING_SNAKE.
  Properties: camelCase.
- The `is` prefix is **allowed** on predicate methods (`isActive()`): that is
  the PHP idiom. The ban covers boolean properties (`$isRemote` -> `$remote`).
- Banned prefixes on methods: `handle*` (except a framework contract),
  `process*`, `execute*`, `doX*`.
- Purge `get*`/`set*` that encapsulate nothing: prefer typed properties or
  accessors named by the domain.
- No abbreviations, no acronyms beyond established domain initialisms.

## drift

- Every file name matches the name of its class.
- `composer dump-autoload` with no warning.
- No agent noun reintroduced.
- `declare(strict_types=1)` present everywhere.

---

# Profile: blade

Focus on architecture and on extracting logic out of views. No cosmetic
convention specific to Blade.

## slice

### The dot is already taken

Laravel resolves `view('login.dialog')` to `login/dialog.blade.php`. An extra
dot in the file name makes the view unreachable.

    <name>.blade.php       lowercase, kebab-case, NO additional dot

The role is carried by the directory alone:

    resources/views/components/cards/user.blade.php
    resources/views/components/dialogs/login.blade.php

### Structure

- Views co-located with their feature when the project is sliced.
- Blade components under `components/<category>/`.
- After any move: update the `view()`, `@include`, `@extends`, `<x-...>` calls
  and the references in configuration. Those are strings; no compiler will
  check them.

## boundary

This is the heart of the blade profile. Same mission as `boundary` on the
component side: the view holds presentation only.

Forbidden in a view:

- database query, Eloquent call, `::where`, `::find`, `::all`
- business rule, price computation, authorization decision
- HTTP call, container access, `app()`, `resolve()`
- more than two levels of nested conditional

Destination of extracted logic, in order of preference:

1. the entity holding the state (affordance on the model)
2. a view model or a dedicated presentation object
3. a view composer, if the data is required by several views
4. the controller, as a last resort

Every extraction preserves the rendered output byte for byte.

## split

- Inspection threshold: 150 lines.
- Split by real presentation region, into Blade components, not by line count.
- A view whose split is not obvious once the logic is extracted is probably
  already correct: record an exemption.

## lexicon

- File and directory names: lowercase, kebab-case.
- Variables passed to the view: a domain name, not an implementation one.
  `$rows` -> `$orders`. `$data` -> the name of what it is.
- No `$isX`: `$isActive` -> `$active`.
- Component slots and props: one English word.

## drift

- No additional dot in a view name.
- Every `view()`, `@include`, `@extends`, `<x-...>` reference resolves.
- No residual query or business rule in a view.
