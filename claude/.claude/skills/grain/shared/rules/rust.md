# Family rust

Extension: `.rs`

## slice

### The dot convention does NOT apply

A module name comes from the file name minus `.rs`. `user.card.rs` would
produce the module `user.card`, which is not a valid Rust identifier. It would
require an explicit `#[path]` attribute on every module: a permanent cost for a
cosmetic gain. Rejected.

    <module>.rs            snake_case, NO dot

The role is carried by the **module path**, the native equivalent of the suffix:

    src/payment/service.rs      ->  crate::payment::service
    src/checkout/card.rs        ->  crate::checkout::card

### Structure

- Vertical slice = one module per feature: `src/checkout/`, `src/profile/`.
- Preferred modern form: `src/checkout.rs` alongside `src/checkout/`.
  Do not introduce new `mod.rs`. Convert existing ones only if the project has
  already migrated; otherwise record a finding and stay consistent.
- A targeted `pub use` defining a module's public API is legitimate — that is
  not a barrel. A `pub use` that re-exports everything with no intent is one.
- Shared code: `src/shared/` or a dedicated crate from three consumers onward.
- After any move: update the `mod` declarations and the `use` paths, then check
  `cargo build` and `cargo test`.

## domain

- Newtype rather than a bare primitive when the type carries an invariant:
  `struct Employer(String)` rather than `String`.
- Correlated primitives -> dedicated struct. Three correlated scalar parameters
  in a signature = finding.
- `enum` for every closed set of variants currently modeled as multiple booleans
  or as strings.

No `## literal` section for this family: the extraction above happens directly
here, in the `domain` wave. The `literal` wave (3) has nothing to do on `.rs`.
- No return tuple beyond two elements: declare a named struct.
- Avoid `Box<dyn Any>` and evasive typing.

## affordance

- Remove agent noun structs: `*Manager`, `*Service`, `*Handler`, `*Engine`,
  `*Helper` with no state of their own.
- Behavior goes into the `impl` of the type holding the state.
  `Gardener::water(&plant)` -> `plant.water()`.
- Stateless between calls -> free function in the module. Rust does not need an
  empty struct to group things: the module **is** the namespace.
- A trait is only worth it from two implementors onward, or for an explicit
  extension point. A trait with a single implementor is indirection.
- God object: move the method to the type it actually mutates.

## split

- Inspection threshold: 150 lines excluding tests. `#[cfg(test)] mod tests` at
  the end of a file does not count.
- Split by responsibility, not by count.
- An `impl` block with more than ten public methods = structural finding.
- Do not scatter a type and its main `impl` across separate files.

## lexicon

- Functions, methods, variables, modules: snake_case.
- Types, traits, enum variants: CamelCase.
- Constants and statics: SCREAMING_SNAKE_CASE.
- The `is_` prefix is **allowed and idiomatic** on predicates (`is_empty()`,
  `is_active()`). The `is*` ban is an ecmascript family rule; it does not apply
  here.
- Banned: `*_manager`, `*_helper`, `*_util`, `do_*`, `process_*`, `handle_*`
  outside a framework contract.
- No abbreviations except the ecosystem's established ones (`cfg`, `impl`,
  `mut`, `ptr`, `len`).
- Raise technical vocabulary toward the domain: `data` -> what it actually is.

## drift

- `cargo build` and `cargo test` green.
- `cargo clippy` with no new warning relative to the baseline.
- No dot in a `.rs` file name.
- No `#[path]` introduced by the refactor.
- No agent noun struct reintroduced.
