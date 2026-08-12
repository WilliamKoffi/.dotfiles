# Family table

The router reads this file to map extension -> family -> rulebook.

| Extension    | Family     | Rulebook                  |
| :----------- | :--------- | :------------------------ |
| `.js`        | ecmascript | `ecmascript.md`           |
| `.jsx`       | ecmascript | `ecmascript.md`           |
| `.ts`        | ecmascript | `ecmascript.md`           |
| `.tsx`       | ecmascript | `ecmascript.md`           |
| `.vue`       | ecmascript | `ecmascript.md`           |
| `.php`       | php        | `php.md`                  |
| `.blade.php` | php        | `php.md` (`blade` profile) |
| `.rs`        | rust       | `rust.md`                 |
| `.nim`       | nim        | `nim.md`                  |

`.blade.php` must be tested **before** `.php`: it is a compound extension, and
a naive match on `.php` would capture it and apply the wrong rules.

## Wave x family applicability

|            | ecmascript | php | blade | rust | nim |
| :--------- | :--------: | :-: | :---: | :--: | :-: |
| survey     | X | X | X | X | X |
| slice      | X | X | X | X | X |
| domain     | X | X | . | X | X |
| literal    | X | . | . | . | . |
| cruddy     | . | X | . | . | . |
| shelved    | . | X | . | . | . |
| affordance | X | X | . | X | X |
| boundary   | X | . | X | . | . |
| split      | X | X | X | X | X |
| lexicon    | X | X | X | X | X |
| drift      | X | X | X | X | X |

`literal` has a section of its own in `ecmascript.md` only. For php, rust and
nim, extracting a closed set of values happens directly in their respective
`## domain` section — see the note at the end of each of those sections.
`blade` has no `domain` section at all, so no `literal` either.

`cruddy` has a section of its own in `php.md` only. The principle — seven
actions, noun the verb — is not specific to PHP, but no other rulebook
describes its routing layer. Opening the wave to another family means writing
its `## cruddy` first. `blade` is a view family: it has no controller, so never
any `cruddy`.

`shelved` follows exactly the same rule as `cruddy`: a `## shelves` section in
`php.md` only. The principle — seven methods, noun the filter — is general, but
no other rulebook describes its data-access layer. `blade` is a view family: it
has no repository, so never any `shelved`.

The absence of a `## <wave>` section in a rulebook is the source of truth.
This table is a summary, not the authority.

## Pipeline invariants

Valid for every family, every wave:

- `src/legacy/` is immutable. Do not read from it, import from it, or modify it.
- The test suite is green at every wave boundary.
- One wave = one commit.
- No wave modifies a file outside its scope.
