# Laravel CRUDdy by Design — Code Patterns Reference

## Table of Contents
1. [Custom Action → Dedicated Controller](#1-custom-action--dedicated-controller)
2. [Nested Resource Controller](#2-nested-resource-controller)
3. [Pivot Table → Real Model + Controller](#3-pivot-table--real-model--controller)
4. [State Change via update()](#4-state-change-via-update)
5. [State Change via Dedicated Controller](#5-state-change-via-dedicated-controller)
6. [Single-Action Controller](#6-single-action-controller)
7. [Route Cheatsheet](#7-route-cheatsheet)
8. [URI Shape — Before / After](#8-uri-shape--before--after)

---

## 1. Custom Action → Dedicated Controller

**❌ Bad**
```php
class PodcastController extends Controller
{
    public function subscribe(Request $request, Podcast $podcast)
    {
        auth()->user()->podcasts()->attach($podcast->id);
        return redirect()->route('podcasts.index');
    }
}
```
> `subscribe()` is not one of the 7 CRUD verbs. It also leaks pivot logic into
> the wrong controller.

**✅ Good**
```php
class SubscriptionController extends Controller
{
    public function store(Request $request)
    {
        Subscription::create([
            'user_id'    => auth()->id(),
            'podcast_id' => $request->podcast_id,
        ]);

        return redirect()->route('podcasts.index');
    }

    public function destroy(Subscription $subscription)
    {
        $subscription->delete();
        return redirect()->route('podcasts.index');
    }
}
```
```php
// routes/web.php
Route::post('subscriptions', [SubscriptionController::class, 'store'])
    ->name('subscriptions.store');

Route::delete('subscriptions/{subscription}', [SubscriptionController::class, 'destroy'])
    ->name('subscriptions.destroy');
```

---

## 2. Nested Resource Controller

**❌ Bad**
```php
class PodcastController extends Controller
{
    public function listEpisodes(Podcast $podcast)
    {
        return view('episodes.index', [
            'episodes' => $podcast->episodes,
        ]);
    }
}
```
> Listing episodes is not the responsibility of `PodcastController`.
> It also adds an 8th method, breaking the 7-action rule.

**✅ Good**
```php
class PodcastEpisodeController extends Controller
{
    public function index(Podcast $podcast)
    {
        return view('episodes.index', [
            'podcast'  => $podcast,
            'episodes' => $podcast->episodes,
        ]);
    }

    public function show(Podcast $podcast, Episode $episode)
    {
        return view('episodes.show', compact('podcast', 'episode'));
    }
}
```
```php
// routes/web.php
Route::resource('podcasts.episodes', PodcastEpisodeController::class);
// Generates: /podcasts/{podcast}/episodes
//            /podcasts/{podcast}/episodes/{episode}
```

---

## 3. Pivot Table → Real Model + Controller

**❌ Bad**
```php
class PodcastController extends Controller
{
    public function follow(Request $request, Podcast $podcast)
    {
        auth()->user()->followedPodcasts()->attach($podcast->id);
    }

    public function unfollow(Podcast $podcast)
    {
        auth()->user()->followedPodcasts()->detach($podcast->id);
    }
}
```
> Using `attach()`/`detach()` directly couples the controller to the pivot
> table. The relationship has no model, no timestamps, no queryability.

**✅ Step 1 — Create a real model**
```php
// app/Models/Follow.php
class Follow extends Model
{
    protected $fillable = ['user_id', 'podcast_id'];
}

// Migration
Schema::create('follows', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('podcast_id')->constrained()->cascadeOnDelete();
    $table->timestamps();
    $table->unique(['user_id', 'podcast_id']);
});
```

**✅ Step 2 — Create the controller**
```php
class FollowController extends Controller
{
    public function store(Request $request)
    {
        Follow::firstOrCreate([
            'user_id'    => auth()->id(),
            'podcast_id' => $request->podcast_id,
        ]);

        return back();
    }

    public function destroy(Follow $follow)
    {
        $this->authorize('delete', $follow);
        $follow->delete();
        return back();
    }
}
```
```php
// routes/web.php
Route::post('follows', [FollowController::class, 'store'])->name('follows.store');
Route::delete('follows/{follow}', [FollowController::class, 'destroy'])->name('follows.destroy');
```

---

## 4. State Change via `update()`

Use when the state field is sent directly from a form (e.g., a toggle checkbox
or a select input).

```php
class PodcastController extends Controller
{
    public function update(Request $request, Podcast $podcast)
    {
        $validated = $request->validate([
            'title'        => 'sometimes|string|max:255',
            'published_at' => 'sometimes|nullable|date',
        ]);

        $podcast->update($validated);

        return redirect()->route('podcasts.show', $podcast);
    }
}
```
```html
<!-- In your Blade view -->
<form method="POST" action="{{ route('podcasts.update', $podcast) }}">
    @method('PATCH')
    @csrf
    <input type="hidden" name="published_at" value="{{ now() }}">
    <button type="submit">Publish</button>
</form>
```

---

## 5. State Change via Dedicated Controller

Use when the state change has a clear, distinct URL and intent that feels
separate from the main resource edit form.

```php
class PublishedPodcastController extends Controller
{
    // POST /podcasts/{podcast}/published → publish
    public function store(Podcast $podcast)
    {
        $this->authorize('publish', $podcast);

        $podcast->update(['published_at' => now()]);

        return redirect()->route('podcasts.show', $podcast)
            ->with('status', 'Podcast published.');
    }

    // DELETE /podcasts/{podcast}/published → unpublish
    public function destroy(Podcast $podcast)
    {
        $this->authorize('publish', $podcast);

        $podcast->update(['published_at' => null]);

        return redirect()->route('podcasts.show', $podcast)
            ->with('status', 'Podcast unpublished.');
    }
}
```
```php
// routes/web.php
Route::post('podcasts/{podcast}/published', [PublishedPodcastController::class, 'store'])
    ->name('podcasts.published.store');

Route::delete('podcasts/{podcast}/published', [PublishedPodcastController::class, 'destroy'])
    ->name('podcasts.published.destroy');
```

---

## 6. Single-Action Controller

Use for one-off actions with no sibling CRUD methods needed.

```php
class PodcastFeaturedController extends Controller
{
    public function __invoke(Podcast $podcast)
    {
        $podcast->update(['featured_at' => now()]);

        return redirect()->route('podcasts.index')
            ->with('status', 'Podcast featured on homepage.');
    }
}
```
```php
// routes/web.php
Route::post('podcasts/{podcast}/featured', PodcastFeaturedController::class)
    ->name('podcasts.featured');
```

---

## 7. Route Cheatsheet

| Situation | Route helper | Controller method |
|---|---|---|
| List a resource | `Route::resource('x', XController::class)` | `index()` |
| Nested resource | `Route::resource('x.y', XYController::class)` | `index(X $x)` |
| Pivot/relationship | Manual `post`/`delete` routes | `store()` / `destroy()` |
| State: form toggle | PATCH to parent resource | `update()` |
| State: distinct URL | Manual `post`/`delete` routes | `store()` / `destroy()` |
| One-off action | `Route::post('...', MyController::class)` | `__invoke()` |

---

## 8. URI Shape — Before / After

Rules: `../../../shared/crud.md` §C9. Shapes only here.

### §C9.3 — verb leads the segment

**❌ Bad**
```php
Route::get('get-invoice/{id}', [InvoiceController::class, 'show']);
Route::get('download-report', [ReportController::class, 'download']);
```

**✅ Good**
```php
Route::get('invoices/{invoice}', [InvoiceController::class, 'show'])
    ->name('invoices.show');

Route::get('reports/{report}/export', ReportExportController::class)
    ->name('reports.export');
```

### §C9.4 — method restated in the path

**❌ Bad**
```php
Route::post('orders/store', [OrderController::class, 'store']);
Route::get('orders/delete/{id}', [OrderController::class, 'destroy']);
```

**✅ Good**
```php
Route::post('orders', [OrderController::class, 'store'])
    ->name('orders.store');

Route::delete('orders/{order}', [OrderController::class, 'destroy'])
    ->name('orders.destroy');
```
> The second ❌ is also a §C9.1 defect — a `GET` reaching `destroy()`. Per
> `../../../shared/rules/php.md` `## cruddy`, that is one finding raised as
> C9.1 and left `deferred`. The ✅ above is the target shape, not a rewrite
> this wave performs: changing `GET` to `DELETE` means turning the caller's
> `<a href>` into a form, which is outside §C10.

### §C9.2 — catch-all shadowing every literal

**❌ Bad** — correct only because it is physically last
```php
Route::get('{alias}', [ProfileController::class, 'show']);
```

**✅ Good** — order-independent
```php
Route::get('{alias}', [ProfileController::class, 'show'])
    ->where('alias', '[a-z0-9-]{3,}')
    ->name('profiles.show');
```

### §C9.5 — duplicate name, second wins

**❌ Bad** — `GalleryController@index` is unreachable
```php
Route::get('{vcard}/galleries', [GalleryController::class, 'index'])
    ->name('gallery.index');

Route::get('{vcard}/galleries', [InstagramEmbedController::class, 'index'])
    ->name('gallery.index');
```
> Report both and name the winner. Deleting either is a behavior decision —
> §5. `kind: "defect"`, `status: "deferred"`.

### §C9.8 — the shape you must not apply

Payment-vendor routes collapse structurally:

```php
// current shape — one triple per provider × subject × outcome
Route::get('stripe/subscription/success', ...);
Route::get('stripe/subscription/failed', ...);
Route::get('paypal/subscription/success', ...);

// the shape it would reduce to
Route::get('payments/{provider}/{subject}/{outcome}', PaymentReturnController::class)
    ->where('provider', 'stripe|paypal')
    ->where('outcome', 'success|failed');
```
> **Do not perform this rewrite.** Every path above is externally bound under
> §C9.8 condition 3 — the URLs are registered in each provider's dashboard, so
> the condition-2 grep returns zero hits and the rewrite still takes checkout
> down on deploy. These are `deferred`, and the collapsed form is shown as the
> target of a coordinated migration, never as this wave's output.
>
> Whether `outcome` is a path segment or a query parameter depends on whether
> each provider registers distinct success and failure URLs. That is answered
> at migration time against the provider config, not here.
