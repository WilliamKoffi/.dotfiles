# grain — CRUDdy Convention (Laravel / PHP)

> Read by the `cruddy` wave only. Assumes `convention.md` is already loaded.
> Everything in `convention.md` still applies — this file adds the routing layer.

**Scope:** php only. The principle — seven actions, noun the verb, CRUD the
noun — is language-agnostic, but no other family has a `## cruddy` section in
its rulebook, so the wave does not fire on them. See `rules/families.md`.
Generalising to another language means writing that section first, not
loosening the §C0 gate.

**Worked examples:** `../skills/cruddy/references/laravel.md` carries the
before/after code for §C2 through §C6. The rules live here; the PHP lives
there. Do not restate one in the other.

---

## §C0. Applicability gate

The `cruddy` wave runs only when **both** hold:

1. `ledger.stack` contains `laravel` or `php`
2. At least one open finding has `rule` starting with `C`

Otherwise write `"cruddy": "skipped"` to the ledger and exit without reading further.

---

## §C1. Seven actions, no more

A controller may implement only:

```
index   create   store   show   edit   update   destroy
```

Any other public method is a violation. Record as `rule: C1`.

`__invoke()` is permitted — see §C6.

---

## §C2. Noun the verb

A custom action becomes a **new controller whose name makes the action CRUD**.

| Custom action | Becomes |
|---|---|
| `subscribe` | `SubscriptionController@store` |
| `unsubscribe` | `SubscriptionController@destroy` |
| `publish` | `PublishedPodcastController@store` |
| `unpublish` | `PublishedPodcastController@destroy` |
| `approve` | `ApprovedApplicationController@store` |
| `ban` | `BannedUserController@store` |

**The rule:** find the noun hiding inside the verb, then CRUD the noun.

This is §1.3 of `convention.md` applied to HTTP. `subscribe` is an *ability*;
`Subscription` is the *thing* that can be created and destroyed.

### C2.1 — Naming the resource controller
`{PastParticiple}{Resource}Controller` for state, `{Noun}Controller` for relations.

- State: `PublishedPodcastController`, `ArchivedOrderController`
- Relation: `SubscriptionController`, `EnrollmentController`, `LikeController`

Never `PodcastPublishController` — that is the verb again with extra steps,
except in the single-action case (§C6).

---

## §C3. Nested resources get their own controller

A child resource is never listed or shown from its parent's controller.

```php
// ❌ PodcastController@episodes
// ✅
Route::resource('podcasts.episodes', PodcastEpisodeController::class);
```

Controller name is `{Parent}{Child}Controller`, and the parent is a route
parameter, not a query inside the action.

---

## §C4. Pivots become models

`attach()` / `detach()` never appear in a controller action.

A many-to-many relationship that a user can create and destroy is a **real
concept** and gets:

1. An Eloquent model — `Subscription`, `Like`, `Enrollment`
2. A controller with `store()` and `destroy()`
3. A migration with its own primary key and timestamps

```php
// ❌
$user->podcasts()->attach($podcast);

// ✅ SubscriptionController@store
Subscription::create([
    'user_id' => $request->user()->id,
    'podcast_id' => $podcast->id,
]);
```

The pivot model is where the affordance lives — §1.2 of `convention.md`.

---

## §C5. State changes — two routes, one decision

For boolean or timestamp state (`published_at`, `archived_at`, `banned_at`):

| Option | Use when | Shape |
|---|---|---|
| **A — `update()`** | The form already submits the field alongside others | `PodcastController@update` |
| **B — dedicated controller** | The change has its own URL, its own button, its own permission | `PublishedPodcastController@store` / `@destroy` |

**Ruling for this suite: default to B** when the state change has a dedicated
UI affordance (a button that does only this). Default to A when it is one field
among many in an edit form.

Record the choice in the ledger note so `drift` can check it later.

---

## §C6. Single-action controllers

`__invoke()` is clean and acceptable for a genuinely one-off action with no
sibling operation.

```php
class PodcastPublishController extends Controller
{
    public function __invoke(Podcast $podcast)
    {
        $podcast->publish();

        return redirect()->route('podcasts.index');
    }
}
```

Note the body: `$podcast->publish()`, **not** `$podcast->update(['published_at' => now()])`.
The controller delegates to the model's affordance. A controller that reaches
into a model's columns is doing the model's job — §1.2.

**Constraint:** if a second action on the same concept appears later, collapse
both into a resource controller. A pair of `__invoke` controllers for
publish/unpublish is a `PublishedPodcastController` that hasn't been written yet.

---

## §C7. Decision tree

```
Is the method name one of the 7?
├── YES → check C3 (nested), C4 (pivot), C5 (state), C8 (fat action)
└── NO  → violation. Then:
          │
          ├── state change? (publish, archive, ban, approve)
          │     → C5: update() or {Participle}{Resource}Controller
          │
          ├── relationship? (subscribe, follow, like, enroll)
          │     → C4: model the pivot, then store/destroy
          │
          ├── listing/showing a child?
          │     → C3: Route::resource('parent.child', ...)
          │
          └── anything else
                → C2: noun the verb, new controller
```

---

## §C8. Action body limits

A controller action does four things at most, in this order:

1. Authorize
2. Validate (via FormRequest, not inline)
3. Delegate to a model or domain object
4. Respond

Business logic in step 3 is a violation — record `rule: C8` and hand the finding
to the `affordance` wave rather than fixing it here. **The `cruddy` wave reshapes
routing; it does not extract domain objects.**

---

## §C9. Routes

- One `Route::resource()` per controller. No `only()` gymnastics to squeeze two
  concepts into one line.
- Use `only()` / `except()` to declare which of the 7 exist — do not leave
  unimplemented actions routable.
- Route model binding always. No `find($id)` in an action.

---

## §C10. Write scope

The `cruddy` wave may edit only:

```
app/Http/Controllers/**
app/Http/Requests/**
routes/**
app/Models/**          ← only to ADD an affordance method or a new pivot model
database/migrations/** ← only to ADD a migration for a new pivot model
```

It may **not** touch views, tests, or existing migrations. Renaming a route name
that a Blade view references is `blocked:out-of-scope` unless the view is inside
the argument path — see §5 of `convention.md`.

---

## §C11. Pragmatism

These rules optimize for discoverability. A tiny internal admin tool with three
one-off endpoints does not need eleven controllers. When the convention costs
more than it returns, record `exempt:readability` with a one-line reason and
move on — but the exemption must be written down, not assumed.

---

## §C12. Output format

For each finding:

1. **🚨 Issue** — the violation, one line, with rule number
2. **Why it matters** — one sentence of maintenance cost
3. **✅ Better approach** — the refactored code
4. **Route** — the updated route definition
5. **Ledger** — the status written (`closed` / `deferred` / `blocked` / `exempt`)
