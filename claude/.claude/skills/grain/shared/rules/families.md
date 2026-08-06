# Table des familles

Le routeur lit ce fichier pour mapper extension -> famille -> rulebook.

| Extension    | Famille    | Rulebook                  |
| :----------- | :--------- | :------------------------ |
| `.js`        | ecmascript | `ecmascript.md`           |
| `.jsx`       | ecmascript | `ecmascript.md`           |
| `.ts`        | ecmascript | `ecmascript.md`           |
| `.tsx`       | ecmascript | `ecmascript.md`           |
| `.vue`       | ecmascript | `ecmascript.md`           |
| `.php`       | php        | `php.md`                  |
| `.blade.php` | php        | `php.md` (profil `blade`) |
| `.rs`        | rust       | `rust.md`                 |
| `.nim`       | nim        | `nim.md`                  |

`.blade.php` doit etre teste **avant** `.php` : c'est une extension composee,
un match naif sur `.php` la capturerait et appliquerait les mauvaises regles.

## Applicabilite vague x famille

|            | ecmascript | php | blade | rust | nim |
| :--------- | :--------: | :-: | :---: | :--: | :-: |
| survey     | X | X | X | X | X |
| slice      | X | X | X | X | X |
| domain     | X | X | . | X | X |
| literal    | X | . | . | . | . |
| cruddy     | . | X | . | . | . |
| affordance | X | X | . | X | X |
| boundary   | X | . | X | . | . |
| split      | X | X | X | X | X |
| lexicon    | X | X | X | X | X |
| drift      | X | X | X | X | X |

`literal` n'a de section propre que dans `ecmascript.md`. Pour php, rust et
nim, l'extraction d'ensemble ferme de valeurs se fait directement dans leur
section `## domain` respective — voir la note en fin de chacune de ces
sections. `blade` n'a pas de section `domain` du tout, donc pas de `literal`
non plus.

`cruddy` n'a de section propre que dans `php.md`. Le principe — sept actions,
nouner le verbe — n'est pas propre a PHP, mais aucun autre rulebook ne decrit
sa couche de routage. Ouvrir la vague a une famille supplementaire veut dire
ecrire son `## cruddy` d'abord. `blade` est une famille de vues : elle n'a pas
de controller, donc jamais de `cruddy`.

L'absence de section `## <vague>` dans un rulebook est la source de verite.
Cette table est un resume, pas l'autorite.

## Invariants du pipeline

Valables pour toutes les familles, toutes les vagues :

- `src/legacy/` est immuable. Ne pas lire, importer, ni modifier.
- La suite de tests est verte a chaque frontiere de vague.
- Une vague = un commit.
- Aucune vague ne modifie un fichier hors de son scope.
