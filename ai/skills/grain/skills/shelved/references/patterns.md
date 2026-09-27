# Shelf Patterns — Before / After

Examples for `skills/shelved`. Read the section matching the violation you are
fixing. Rules live in `shared/shelf.md`; this file only shows shapes.

| Section | Violation | Rule |
|---|---|---|
| 1 | Filtered read as a method | §S3 |
| 2 | Scope passed as an argument | §S4 |
| 3 | Ordering / limiting as arguments | §S5 |
| 4 | Builder returned to the caller | §S6 |
| 5 | Pivot lookups | §S3 + crud.md |
| 6 | Bulk writes | §S1 |
| 7 | Open-ended search | §S7 |
| 8 | The interface that grew | P-S10 |

---

## 1. Filtered read as a method (§S3)

```php
// ❌ Before — the shelf grows a method per question
final class UserRepository
{
    public function all(): Collection { return User::all(); }
    public function findActive(): Collection { return User::where('active', true)->get(); }
    public function findBanned(): Collection { return User::whereNotNull('banned_at')->get(); }
    public function findWithoutPosts(): Collection { return User::doesntHave('posts')->get(); }
}
```

```php
// ✅ After — a shelf per set, same vocabulary on each
final class ActiveUsers
{
    public function all(): Collection
    {
        return User::where('active', true)->get();
    }

    public function count(): int
    {
        return User::where('active', true)->count();
    }
}

final class BannedUsers { /* all(), count() */ }
final class PostlessUsers { /* all() */ }
```

Callers read as sentences: `(new ActiveUsers)->count()`.

---

## 2. Scope passed as an argument (§S4)

```php
// ❌ Before
$repo->membersOf($team);
$repo->all(['team_id' => $team->id]);
```

```php
// ✅ After
final class TeamMembers
{
    public function __construct(private Team $team) {}

    public function all(): Collection
    {
        return $this->team->members()->get();
    }

    public function count(): int
    {
        return $this->team->members()->count();
    }
}

// Caller
(new TeamMembers($team))->all();
```

Scoped *and* filtered is two nouns, one shelf: `ActiveTeamMembers`.

---

## 3. Ordering and limiting (§S5)

```php
// ❌ Before
$repo->all('created_at', 'desc', 10);
$repo->latest(10);
```

```php
// ✅ After
final class MostRecentPosts
{
    public function __construct(private int $limit = 10) {}

    public function all(): Collection
    {
        return Post::latest()->limit($this->limit)->get();
    }
}
```

The limit may sit in the constructor because it is part of *which shelf*.
It may never sit in `all()`, because that is *which items*.

---

## 4. Builder leak (§S6)

```php
// ❌ Before — every caller becomes its own repository
public function query(): Builder
{
    return User::query();
}

// Call site
$repo->query()->where('active', true)->orderBy('name')->get();
```

```php
// ✅ After — the builder never crosses the boundary
final class ActiveUsersByName
{
    public function all(): Collection
    {
        return User::where('active', true)->orderBy('name')->get();
    }
}
```

Fix this before anything else in the class. While a builder escapes, no other
rule in `shelf.md` can be enforced.

---

## 5. Pivot lookups (§S3)

```php
// ❌ Before
$repo->subscribersOf($podcast);
$podcast->subscribers()->attach($user);
```

```php
// ✅ After — pivot is a model (crud.md), pivot gets a shelf
final class PodcastSubscribers
{
    public function __construct(private Podcast $podcast) {}

    public function all(): Collection
    {
        return $this->podcast->subscribers()->get();
    }

    public function save(Subscription $subscription): Subscription
    {
        $subscription->save();
        return $subscription;
    }

    public function remove(Subscription $subscription): void
    {
        $subscription->delete();
    }
}
```

`attach()` / `detach()` appear nowhere else in the codebase.

---

## 6. Bulk writes (§S1)

```php
// ❌ Before
$repo->saveMany($users);
$repo->deleteWhere('active', false);
```

```php
// ✅ After — the vocabulary does not grow for cardinality
foreach ($users as $user) {
    $shelf->save($user);
}

// Deleting a set is a set: shelve it, then remove it
$inactive = (new InactiveUsers)->all();
foreach ($inactive as $user) {
    $shelf->remove($user);
}
```

If the loop is a genuine performance problem, that is a `defect` finding with a
measurement attached — not a new method. Record it, defer it, move on.

---

## 7. Open-ended search (§S7)

```php
// ✅ The only sanctioned eighth method
final class UserCriteria
{
    public function __construct(
        public readonly ?string $name = null,
        public readonly ?bool $active = null,
        public readonly ?CarbonInterface $joinedAfter = null,
    ) {}

    public function applyTo(Builder $query): Builder
    {
        return $query
            ->when($this->name, fn ($q, $n) => $q->where('name', 'like', "%{$n}%"))
            ->when(! is_null($this->active), fn ($q) => $q->where('active', $this->active))
            ->when($this->joinedAfter, fn ($q, $d) => $q->where('created_at', '>=', $d));
    }
}

final class Users
{
    private ?UserCriteria $criteria = null;

    public function matching(UserCriteria $criteria): static
    {
        $clone = clone $this;
        $clone->criteria = $criteria;
        return $clone;
    }

    public function all(): Collection
    {
        $query = User::query();
        return ($this->criteria?->applyTo($query) ?? $query)->get();
    }
}
```

Note what is *not* here: no array of conditions, no raw SQL, no `where()` on
the shelf. Adding an axis means adding a typed property.

---

## 8. The interface that grew (P-S10)

```php
// ❌ Before
interface UserRepositoryInterface
{
    public function all(): Collection;
    public function find(int $id): User;
    public function findActive(): Collection;
    public function findByEmail(string $email): ?User;
    public function save(User $user): User;
    public function remove(User $user): void;
}
```

```php
// ✅ After — the contract is the vocabulary; the questions became shelves
interface Shelf
{
    public function all(): Collection;
    public function find(int $id): Model;
    public function save(Model $entity): Model;
    public function remove(Model $entity): void;
}

final class Users implements Shelf { /* … */ }
final class ActiveUsers implements Shelf { /* … */ }
final class UsersByEmail implements Shelf
{
    public function __construct(private string $email) {}
    public function first(): ?User { return User::where('email', $this->email)->first(); }
}
```

If a shared `Shelf` interface is not already in use, do not introduce one.
Binding concretely is fine; two abstractions where one would do is not.
