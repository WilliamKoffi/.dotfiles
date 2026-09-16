---
name: filament-split-resource
description: Split an oversized Filament resource (api/app/Modules/*/Filament/Resources/*Resource.php)
  into a role folder — Resource (composer), Form, Grid, plus a Blade view for any
  hand-built HTML column. Use when a resource passes 150 lines, builds HTML strings
  in a closure, or the user asks to refactor/split/de-god a Filament resource.
---

# filament-split-resource

Turns `Modules/<Module>/Filament/Resources/<Name>Resource.php` into a folder of roles
(grain `§3.1`, `§3.2`) without changing a single visible behavior (`§5`). Worked
example: `Modules/Catalog/Filament/Resources/Product/`.

Read before editing: `AGENTS.md` §1 (items 9–10 govern imports) and `~/.claude/skills/grain/shared/convention.md`
`§0`–`§3`, `§5`. Cite sections by number; do not restate them.

## Target shape

```
Filament/Resources/<Name>/
  Resource.php          composer — model, nav, labels, relations, pages, query
  Form.php              Form::build(Schema $schema): Schema
  Grid.php              Grid::build(Table $table): Table
  Pages/                pages used only by this resource (moved)
  RelationManagers/     relation managers used only by this resource (moved)
api/resources/views/filament/columns/<column>.blade.php   (only if an HTML column exists)
```

Namespace: `App\Modules\<Module>\Filament\Resources\<Name>` (singular, non-tautological —
`Product\Resource`, not `Product\ProductResource`).

## Pick a candidate

When no resource is named, rank them by size and propose the largest; do not start
until the user confirms which one.

```bash
cd api && find app/Modules -path "*/Filament/Resources/*.php" \
  -not -path "*/Resources/*/*" | xargs wc -l | sort -n
```

A resource already in a role folder (`Resources/<Name>/Resource.php`) is done.

## Process

1. **Start from the file on disk, never from a proposal.** Read the current resource in
   full. A user-supplied draft is a sketch of intent: columns, `toggleable()`,
   `filters()`, `created_at`/`updated_at`, labels added since the draft was written
   must all survive. Diff your output against the original, column by column.

2. **Map the blast radius.** Find every reference before moving anything:
   ```bash
   grep -rn "<Name>Resource" api/app api/tests api/routes api/config
   ```
   Expect: the module's `Providers/ModuleServiceProvider.php` (`filamentResources()`),
   its own `Pages/*`, and `api/tests/Feature/web/admin-panel-test.php`.
   Beware the HTTP API resource with the same basename
   (`Modules/<Module>/Http/Resources/<Name>Resource.php`) — do not touch it.
   Also grep for `file_get_contents(app_path(...<Name>Resource.php` — the admin panel
   test reads some resources **by path**; update the path to `<Name>/Resource.php`.

3. **Move with history.** `git mv` the resource to `<Name>/Resource.php`, and its
   exclusive `Pages/` and `RelationManagers/` into the folder. Shared folders (e.g.
   `Pages/` also holding `ManageCategories.php`) keep the other resources' files.
   Rewrite `namespace` lines and `use ...<Name>Resource;` → `use ...<Name>\Resource;`,
   `<Name>Resource::class` → `Resource::class`. Remove folders left empty.
   Keep page and relation-manager class names unchanged — renaming them is out of scope.

4. **Write the composer.** `class Resource extends Base` with
   `use Filament\Resources\Resource as Base;` — importing `Resource` unaliased into a
   class named `Resource` is a fatal name clash. `form()` returns `Form::build($schema)`,
   `table()` returns `Grid::build($table)`. Everything else stays verbatim.

5. **Pin the slug.** Filament derives the URL from the class basename; `Resource`
   yields a broken slug. Add, with the plural kebab of the old name:
   ```php
   /** Pinned: the `Resource` basename would otherwise derive a broken slug. */
   protected static ?string $slug = 'products';
   ```

6. **Extract Form and Grid.** Plain classes with one static `build()` method. Copy the
   component/column arrays **unchanged** — same labels, same chain order, same
   formatting. Keep `->filters([ // ])` and `recordActions`/`toolbarActions` in Grid.
   Only the class references change, per step 9.
   - **Exception: image columns lead.** Any `ImageColumn::make(...)` in Grid's
     `->columns([...])` moves to position 1 (or 1–2, if there are two) even if the
     source had it lower — thumbnails should be the first thing scanned in a list.
     Move the column entries only; don't touch their labels, modifiers, or the
     relative order of everything else. Reference: `Catalog/Filament/Resources/Category/`
     (`cover.path`, `banner.path` lead; `Content/Filament/Resources/Banner/` already
     led with `image.path`).

7. **Extract HTML columns to Blade.** A `TextColumn::make(x)->html()->state(fn ...)`
   that concatenates markup becomes
   `ViewColumn::make(x)->label(...)->view('filament.columns.<x>')`, carrying over
   `->toggleable()` and any other modifiers. In the view:
   - Read the record with `$getRecord()`.
   - Use `$loop->first` / `$loop->index` instead of a manual counter.
   - One-word variables (`§2.1`, `§2.4`): `$marginLeft` → inline `$loop` expression,
     `$zIndex` → inline or `$layer`, repeated style strings → one `$swatch`-style variable.
   - Drop `e()` — `{{ }}` escapes. Never use `{!! !!}` for record data.
   - **Keep inline `style="... !important"`.** Filament's compiled CSS lacks arbitrary
     Tailwind utilities (`rounded-full`, `text-[10px]`, `bg-gray-100`); swapping styles
     for classes silently breaks the rendering. Classes already present in the
     original (`ring-2 ring-white dark:ring-gray-900 shrink-0 shadow-xs`) stay.

8. **Update importers.** In the provider and tests, alias to keep call sites untouched:
   `use App\Modules\<Module>\Filament\Resources\<Name>\Resource as <Name>Resource;`

9. **Import style (`AGENTS.md` §1.10).** In every file of the folder — Form, Grid, and
   the moved Pages and RelationManagers — a Filament class used **only** as `X::make(...)`
   is called by inline FQCN and its `use` line is removed:
   `\Filament\Tables\Columns\TextColumn::make('sku')`, `\Filament\Actions\CreateAction::make()`.
   Keep the `use` import when the class is also a signature type (`Schema`, `Table`,
   `Builder`), a parent (`RelationManager`, `ManageRecords`, `Base`), a `::class` or enum
   reference (`Product`, `Heroicon`, `Products`), or not Filament (`Money`, `Storage`).
   One mixed usage keeps the import for that class. Traits follow §1.9.

## Do not

- **Rename labels.** `__('Regular Price')` is a key in `api/lang/fr.json`; shortening it
  to `Price` ships untranslated English. The one-word rule governs identifiers, not
  display strings or database columns.
- Convert inline styles to Tailwind classes (step 7).
- Let `pint` rewrite unrelated files or undo step 9. Run `vendor/bin/pint --dirty`, then
  `git diff --stat` and `git diff`; revert any file whose churn is not yours
  (`git checkout <file>` and reapply your change), and restore any inline FQCN Pint
  collapsed back into a `use` import. It has rewritten every inline FQCN in
  `admin-panel-test.php` before.
- Install tooling to do the job — `api/CLAUDE.md` asks for `laravel/boost`; this skill
  does not need it.
- Rename Page or RelationManager classes, or split a second resource without asking.
- Commit unless asked.

## Verify

Run from `api/`:

```bash
composer dump-autoload -q
php artisan route:list --name=<slug>          # same admin/<slug> URIs and route names
php artisan test --compact tests/Feature/web/admin-panel-test.php
php artisan test --compact                    # full suite
wc -l app/Modules/<Module>/Filament/Resources/<Name>/*.php   # each ≤ 150
```

For an extracted view, render it against in-memory records and compare with the old
closure's output (empty, under-limit, over-limit, null fallback, a label containing
`<`). Use a standalone script in the scratchpad — `php artisan tinker <file>` hangs
waiting on stdin:

```php
<?php
require '<abs>/api/vendor/autoload.php';
$app = require '<abs>/api/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$make = fn (array $tones) => tap(new App\Modules\Catalog\Models\Product,
    fn ($p) => $p->setRelation('tones', collect($tones)));

foreach ([[], [/* 3 items */], [/* 6 items */]] as $set) {
    echo view('filament.columns.tones', ['getRecord' => fn () => $make($set)])->render(), "\n";
}
```

### UI parity in the browser

Tests do not render the table. Check the live panel with Playwright:

1. From `api/`, start `php artisan serve --port=8000` in the background; expect `200`
   on `/admin/login`. Credentials: `database/seeders/Identity/AdminSeeder.php`.
   Confirm seeded data exists for any extracted column (e.g. `Product::has('tones')->count()`).
2. Open `/admin/<slug>` and `/admin/<slug>/1/edit`. Use `browser_snapshot` (accessibility
   tree), not `browser_take_screenshot` — screenshots land at a path the shell cannot find.
   Compare labels, column order, data and the extracted column's output.
3. `browser_console_messages` on both pages: zero errors or warnings.
4. Stop the server, and delete any artifact dropped in the repo root (`*.png`).
   Never `find /` for a lost file.

Intelephense "Undefined type/function" and CSS-lint errors on `style="{{ }}"` in the
new files are editor noise; the test suite is the authority.

## Report

State: files created/moved, importers updated, slug pinned, imports converted per
step 9, UI-parity result, and every point where the
result deliberately departs from the user's draft with the reason (clash, slug,
translations, CSS, draft bugs such as `@endphp` closing a `@foreach`).
