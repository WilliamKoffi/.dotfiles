# Family nim

Extension: `.nim`

## slice

### The dot convention does NOT apply

A module name comes from the file name. The dot is the field-access operator in
Nim; a module name must be a valid identifier. `user.card.nim` cannot be
imported.

    <module>.nim           lowercase, NO dot

The role is carried by the **directory path**:

    src/payment/service.nim     ->  import payment/service
    src/checkout/card.nim       ->  import checkout/card

### Structure

- Vertical slice = one directory per feature.
- Shared code from three independent consumers onward.
- A module that only re-exports through `export` with no public-API intent is a
  barrel: remove it. A targeted `export` that defines the package's public API
  is legitimate.
- After any move: update the `import`, `include`, `export` statements and the
  paths in the `.nimble` file. Verify with `nim check`.

### Note on style insensitivity

Nim ignores case and underscores in identifiers after the first character:
`myVar`, `my_var` and `myvar` all name the same symbol. That holds for
identifiers, **not for file names**, which remain case-sensitive on the file
systems concerned. Do not rely on this tolerance when renaming files.

## domain

- `distinct` type rather than a bare primitive when the type carries an
  invariant: `type Employer = distinct string`.
- Correlated primitives -> dedicated `object`. Three correlated scalar
  parameters in a signature = finding.
- `enum` for every closed set of values modeled as booleans or as strings.

No `## literal` section for this family: the extraction above happens directly
here, in the `domain` wave. The `literal` wave (3) has nothing to do on `.nim`.
- Declare return types explicitly. No anonymous tuple beyond two fields: name an
  `object`.

## affordance

- Remove agent noun objects: `*Manager`, `*Service`, `*Handler`, `*Engine`.
- Behavior goes on the type holding the state, as the first parameter.

**Nim specificity.** Uniform function call syntax (UFCS) makes `plant.water()`
and `water(plant)` strictly equivalent. The affordance / ability distinction
therefore disappears at the call site — but it survives where it really counts:
in the module hosting the procedure and in the first parameter. The rule becomes:
**the procedure lives in the module of the type it mutates**, and that type is
its first parameter. Do not take the call style alone as proof the wave is
satisfied.

- Stateless between calls -> free procedure in the module. The module is the
  namespace; no ceremonial object to group things.
- A `method` (dynamic dispatch) is only worth it with real polymorphism.
  Otherwise `proc` or `func`.

## split

- Inspection threshold: 150 lines.
- Split by responsibility, not by count.
- Keep a type and the procedures that make up its primary API together.
- Watch out for import cycles: Nim tolerates them poorly. If a split creates a
  cycle, the cut is in the wrong place — record it and re-examine.

## lexicon

- Procedures and variables: camelCase. Types: PascalCase. Constants: PascalCase
  or SCREAMING_SNAKE per the convention in place — stay consistent.
- The `is` prefix is **allowed** on predicates (`isEmpty`): idiomatic. The `is*`
  ban is an ecmascript rule, not a universal one.
- Banned: `*Manager`, `*Helper`, `*Util`, `do*`, `process*`, `handle*`.
- No abbreviations.
- Do not lean on style insensitivity to let `myVar` and `my_var` coexist: pick
  one form and apply it.

## drift

- `nim check` green on every module in scope.
- The test suite passes.
- No dot in a `.nim` file name.
- No import cycle introduced.
- No agent noun object reintroduced.
