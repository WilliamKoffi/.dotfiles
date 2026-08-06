# Famille nim

Extension : `.nim`

## slice

### La convention a points ne s'applique PAS

Le nom de module vient du nom de fichier. Le point est l'operateur d'acces de
champ en Nim ; un nom de module doit etre un identifiant valide.
`user.card.nim` est inimportable.

    <module>.nim           lowercase, AUCUN point

Le role est porte par le **chemin de repertoire** :

    src/payment/service.nim     ->  import payment/service
    src/checkout/card.nim       ->  import checkout/card

### Structure

- Slice verticale = un repertoire par feature.
- Code partage a partir de trois consommateurs independants.
- Un module qui ne fait que reexporter par `export` sans intention d'API
  publique est un barrel : supprimer. Un `export` cible qui definit l'API
  publique du paquet est legitime.
- Apres tout deplacement : mettre a jour les `import`, `include`, `export`,
  et les chemins du fichier `.nimble`. Verifier avec `nim check`.

### Note sur l'insensibilite au style

Nim ignore la casse et les underscores dans les identifiants apres le premier
caractere : `myVar`, `my_var` et `myvar` designent le meme symbole. Cela vaut
pour les identifiants, **pas pour les noms de fichiers**, qui restent
sensibles a la casse sur les systemes de fichiers concernes. Ne pas se fier a
cette tolerance lors des renommages de fichiers.

## domain

- `distinct` type plutot que primitive nue quand le type porte une invariante :
  `type Employer = distinct string`.
- Primitives correlees -> `object` dedie. Trois parametres scalaires correles
  dans une signature = finding.
- `enum` pour tout ensemble ferme de valeurs modelise en booleens ou en
  chaines.

Pas de section `## literal` pour cette famille : l'extraction ci-dessus se
fait directement ici, en vague `domain`. La vague `literal` (3) n'a rien a
faire sur `.nim`.
- Declarer les types de retour explicitement. Pas de tuple anonyme au-dela de
  deux champs : nommer un `object`.

## affordance

- Supprimer les objets agent noun : `*Manager`, `*Service`, `*Handler`,
  `*Engine`.
- Le comportement va sur le type qui detient l'etat, en premier parametre.

**Particularite Nim.** L'appel de fonction uniforme (UFCS) rend `plant.water()`
et `water(plant)` strictement equivalents. La distinction affordance / ability
disparait donc au site d'appel — mais elle persiste la ou elle compte
vraiment : dans le module qui heberge la procedure et dans le premier
parametre. La regle devient : **la procedure vit dans le module du type
qu'elle mute**, et ce type est son premier parametre. Ne pas se contenter du
style d'appel pour declarer la vague satisfaite.

- Sans etat entre appels -> procedure libre dans le module. Le module est le
  namespace ; pas d'objet ceremoniel pour grouper.
- Un `method` (dispatch dynamique) n'a d'interet qu'avec polymorphisme reel.
  Sinon `proc` ou `func`.

## split

- Seuil d'inspection : 150 lignes.
- Decouper par responsabilite, pas par comptage.
- Garder ensemble un type et les procedures qui constituent son API primaire.
- Attention aux cycles d'import : Nim les tolere mal. Si un decoupage cree un
  cycle, la coupe est au mauvais endroit — consigner et reexaminer.

## lexicon

- Procedures et variables : camelCase. Types : PascalCase. Constantes :
  PascalCase ou SCREAMING_SNAKE selon la convention en place, rester coherent.
- Le prefixe `is` est **autorise** sur les predicats (`isEmpty`) : idiomatique.
  L'interdiction de `is*` est une regle ecmascript, pas universelle.
- Bannis : `*Manager`, `*Helper`, `*Util`, `do*`, `process*`, `handle*`.
- Pas d'abreviations.
- Ne pas s'appuyer sur l'insensibilite au style pour laisser coexister
  `myVar` et `my_var` : choisir une forme et l'appliquer.

## drift

- `nim check` vert sur tous les modules du scope.
- La suite de tests passe.
- Aucun point dans un nom de fichier `.nim`.
- Aucun cycle d'import introduit.
- Aucun objet agent noun reintroduit.
