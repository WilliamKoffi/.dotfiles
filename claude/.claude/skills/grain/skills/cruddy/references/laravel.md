# Laravel CRUDdy by Design — Code Patterns Reference

## Table of Contents
1. [Custom Action → Dedicated Controller](#1-custom-action--dedicated-controller)
2. [Nested Resource Controller](#2-nested-resource-controller)
3. [Pivot Table → Real Model + Controller](#3-pivot-table--real-model--controller)
4. [State Change via update()](#4-state-change-via-update)
5. [State Change via Dedicated Controller](#5-state-change-via-dedicated-controller)
6. [Single-Action Controller](#6-single-action-controller)
7. [Route Cheatsheet](#7-route-cheatsheet)

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
