# Famille rust

Extension : `.rs`

## slice

### La convention a points ne s'applique PAS

Le nom de module vient du nom de fichier prive de `.rs`. `user.card.rs`
produirait le module `user.card`, qui n'est pas un identifiant Rust valide.
Il faudrait un attribut `#[path]` explicite sur chaque module : cout permanent
pour un gain cosmetique. Rejete.

    <module>.rs            snake_case, AUCUN point

Le role est porte par le **chemin de module**, equivalent natif du suffixe :

    src/payment/service.rs      ->  crate::payment::service
    src/checkout/card.rs        ->  crate::checkout::card

### Structure

- Slice verticale = un module par feature : `src/checkout/`, `src/profile/`.
- Forme moderne preferee : `src/checkout.rs` + `src/checkout/` a cote.
  Ne pas introduire de nouveaux `mod.rs`. Convertir les existants seulement si
  le projet a deja migre ; sinon consigner un finding et rester coherent.
- `pub use` cible pour definir une API publique de module : legitime, ce n'est
  pas un barrel. Un `pub use` qui reexporte tout sans intention en est un.
- Code partage : `src/shared/` ou crate dediee a partir de trois consommateurs.
- Apres tout deplacement : mettre a jour les declarations `mod`, les chemins
  `use`, et verifier `cargo build` puis `cargo test`.

## domain

- Newtype plutot que primitive nue quand le type porte une invariante :
  `struct Employer(String)` plutot que `String`.
- Primitives correlees -> struct dediee. Trois parametres scalaires correles
  dans une signature = finding.
- `enum` pour tout ensemble ferme de variantes actuellement modelise en
  booleens multiples ou en chaines.

Pas de section `## literal` pour cette famille : l'extraction ci-dessus se
fait directement ici, en vague `domain`. La vague `literal` (3) n'a rien a
faire sur `.rs`.
- Pas de tuple de retour au-dela de deux elements : declarer une struct nommee.
- Eviter `Box<dyn Any>` et le typage evasif.

## affordance

- Supprimer les structs agent noun : `*Manager`, `*Service`, `*Handler`,
  `*Engine`, `*Helper` sans etat propre.
- Le comportement va dans le `impl` du type qui detient l'etat.
  `Gardener::water(&plant)` -> `plant.water()`.
- Sans etat entre appels -> fonction libre dans le module. Rust n'a pas besoin
  d'une struct vide pour grouper : le module **est** le namespace.
- Un trait n'a d'interet qu'a partir de deux implementeurs, ou pour un point
  d'extension explicite. Un trait a un seul implementeur est de l'indirection.
- God object : deplacer la methode vers le type qu'elle mute reellement.

## split

- Seuil d'inspection : 150 lignes hors tests. Les `#[cfg(test)] mod tests`
  en fin de fichier ne comptent pas.
- Decouper par responsabilite, pas par comptage.
- Un `impl` bloc de plus de dix methodes publiques = finding structurel.
- Ne pas eclater un type et son `impl` principal dans des fichiers separes.

## lexicon

- Fonctions, methodes, variables, modules : snake_case.
- Types, traits, variantes d'enum : CamelCase.
- Constantes et statics : SCREAMING_SNAKE_CASE.
- Le prefixe `is_` est **autorise et idiomatique** sur les predicats
  (`is_empty()`, `is_active()`). L'interdiction de `is*` est une regle de la
  famille ecmascript, elle ne s'applique pas ici.
- Bannis : `*_manager`, `*_helper`, `*_util`, `do_*`, `process_*`,
  `handle_*` hors contrat de framework.
- Pas d'abreviations sauf celles etablies de l'ecosysteme (`cfg`, `impl`,
  `mut`, `ptr`, `len`).
- Elever le vocabulaire technique vers le domaine : `data` -> ce que c'est.

## drift

- `cargo build` et `cargo test` verts.
- `cargo clippy` sans avertissement nouveau par rapport a la base.
- Aucun point dans un nom de fichier `.rs`.
- Aucun `#[path]` introduit par le refactoring.
- Aucune struct agent noun reintroduite.
