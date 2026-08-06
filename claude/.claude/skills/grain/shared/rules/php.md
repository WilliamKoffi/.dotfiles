# Famille php

Extensions : `.php`, `.blade.php`

Deux profils distincts. Toujours resoudre `.blade.php` avant `.php`.

---

# Profil : php

## slice

### La convention a points ne s'applique PAS

PSR-4 exige que le nom de fichier corresponde exactement au nom de la classe
qu'il contient. `payment.service.php` casse l'autoload.

    <ClassName>.php        en StudlyCase

Le role est porte par le **namespace et le repertoire**, qui sont l'equivalent
natif PHP du suffixe :

    app/Services/PaymentService.php     -> App\Services\PaymentService
    app/Models/User.php                 -> App\Models\User
    app/Http/Controllers/OrderController.php

Ne jamais introduire de point dans un nom de fichier PHP autre qu'une vue.

### Structure

- Slice verticale sous `app/Features/<Feature>/` ou modules Laravel, selon ce
  que le projet utilise deja. Ne pas imposer une des deux si l'autre est en
  place : consigner un finding et laisser le choix.
- `composer.json` : mettre a jour le mapping PSR-4 apres tout deplacement de
  namespace, puis `composer dump-autoload`.
- Un fichier = une classe. Pas de classe secondaire en fin de fichier.
- Verifier les references par chaine : `config/`, conteneur de services,
  `::class` dans les migrations. Un `git mv` seul ne suffit pas en PHP.

## domain

- Value objects plutot que primitives correlees. Trois arguments scalaires
  correles dans une signature = finding.
- Types de retour declares partout. Pas de `array` nu quand la forme est
  connue : declarer un DTO ou un objet dedie.
- `declare(strict_types=1)` en tete de chaque fichier.
- Enum PHP 8.1 pour tout ensemble ferme de valeurs actuellement en constantes
  de classe ou en chaines.

Pas de section `## literal` pour ce profil : l'extraction ci-dessus se fait
directement ici, en vague `domain`. La vague `literal` (3) n'a rien a faire
sur `.php`.

## cruddy

Seule famille ou cette vague s'applique. Les regles sont dans
`../crud.md` (§C1 a §C12) et les exemples dans
`../../skills/cruddy/references/laravel.md` — ne pas les repeter ici. Cette
section ne porte que ce qui est propre au profil php.

- Perimetre de detection : `app/Http/Controllers/**`. Un fichier hors de la
  s'analyse en `affordance`, pas ici.
- Toute methode publique routee hors des sept verbes est un finding `C1`.
  `__invoke()` compte comme conforme (§C6).
- `attach()` / `detach()` dans un corps d'action : finding `C4`, sans
  exception. Le pivot devient un modele.
- `find($id)` dans une action : finding `C9`. Route model binding partout.
- Validation en ligne dans l'action plutot qu'en FormRequest : finding `C8`.
- Logique metier dans le corps de l'action : finding `C8`, **defere a
  `affordance`**. Cette vague reshape le routage, elle n'extrait pas de
  domaine.

**Frontiere avec `affordance`.** Les deux vagues touchent les controleurs et
se marchent dessus si on n'y prend pas garde. La coupe : `cruddy` decide
*quelle action vit sur quel controleur*, `affordance` decide *ce qui ne
devrait pas etre dans un controleur du tout*. Un `*Service` injecte dans un
controleur correctement decoupe n'est pas un finding `cruddy`.

**Collision idiomatique assumee**, meme nature que celle notee en
`affordance` : Laravel tolere les controleurs a actions custom et la
documentation officielle en montre. Cette regle les rejette. Ne pas
"corriger" vers l'idiome.

## affordance

- Supprimer les agent nouns : `*Manager`, `*Service`, `*Handler`, `*Helper`,
  `*Engine`, `*Repository` sans persistance reelle.
- Deplacer la methode vers l'entite qui detient l'etat.
  `PaymentService::charge($order)` -> `$order->charge()`.
- God object : `User::createSubscription()` -> `Subscription::start($user)`.
- Sans etat -> classe finale a methodes statiques, ou fonction dans un
  fichier de namespace. Pas d'instanciation ceremonielle.
- Controleurs : si un controleur coordonne trois responsabilites sans lien,
  extraire un nom de domaine, pas un service.

**Collision idiomatique assumee.** L'ecosysteme Laravel encourage les classes
`*Service` et le pattern Action. Cette regle les rejette au profit de
l'affordance. C'est un choix delibere du projet, pas une erreur : ne pas
"corriger" vers l'idiome Laravel. Si un `*Service` est impose par un package
tiers, consigner une derogation et le laisser.

## split

- Seuil d'inspection : 150 lignes. Declencheur d'examen, pas ordre de coupe.
- Un controleur au-dela de sept methodes publiques = finding structurel, pas
  un probleme de taille.
- Traits : extraire seulement si le comportement est reellement partage par
  deux classes ou plus. Un trait a un seul consommateur est un deplacement de
  bruit, pas une decomposition.

## lexicon

- Classes : StudlyCase. Methodes : camelCase. Constantes : SCREAMING_SNAKE.
  Proprietes : camelCase.
- Le prefixe `is` est **autorise** sur les methodes predicat (`isActive()`) :
  c'est l'idiome PHP. L'interdiction porte sur les proprietes booleennes
  (`$isRemote` -> `$remote`).
- Prefixes bannis sur les methodes : `handle*` (sauf contrat de framework),
  `process*`, `execute*`, `doX*`.
- Purger les `get*`/`set*` qui n'encapsulent rien : preferer des proprietes
  typees ou des accesseurs nommes par le domaine.
- Pas d'abreviations, pas d'acronymes hors sigles etablis du domaine.

## drift

- Chaque nom de fichier correspond au nom de sa classe.
- `composer dump-autoload` sans avertissement.
- Aucun agent noun reintroduit.
- `declare(strict_types=1)` present partout.

---

# Profil : blade

Concentration sur l'architecture et l'extraction de logique hors des vues.
Aucune convention cosmetique propre a Blade.

## slice

### Le point est deja reserve

Laravel resout `view('login.dialog')` en `login/dialog.blade.php`. Un point
supplementaire dans le nom de fichier rend la vue introuvable.

    <name>.blade.php       lowercase, kebab-case, AUCUN point additionnel

Le role est porte par le repertoire seul :

    resources/views/components/cards/user.blade.php
    resources/views/components/dialogs/login.blade.php

### Structure

- Vues co-localisees avec leur feature quand le projet est en slices.
- Composants Blade sous `components/<categorie>/`.
- Apres tout deplacement : mettre a jour les appels `view()`,
  `@include`, `@extends`, `<x-...>` et les references en configuration.
  Ce sont des chaines, aucun compilateur ne les verifiera.

## boundary

C'est le coeur du profil blade. Meme mission que `boundary` cote composants :
la vue ne detient que la presentation.

Interdits dans une vue :

- requete base de donnees, appel Eloquent, `::where`, `::find`, `::all`
- regle metier, calcul de prix, decision d'autorisation
- appel HTTP, acces au conteneur, `app()`, `resolve()`
- plus de deux niveaux de conditionnelle imbriquee

Destination de la logique extraite, par ordre de preference :

1. l'entite qui detient l'etat (affordance sur le modele)
2. un view model ou un objet de presentation dedie
3. un view composer, si la donnee est requise par plusieurs vues
4. le controleur, en dernier recours

Chaque extraction preserve le rendu a l'octet pres.

## split

- Seuil d'inspection : 150 lignes.
- Decouper par region de presentation reelle, en composants Blade, pas par
  comptage de lignes.
- Une vue dont le decoupage n'est pas evident apres extraction de la logique
  est probablement deja correcte : consigner une derogation.

## lexicon

- Noms de fichiers et de repertoires : lowercase, kebab-case.
- Variables passees a la vue : nom de domaine, pas d'implementation.
  `$rows` -> `$orders`. `$data` -> le nom de ce que c'est.
- Pas de `$isX` : `$isActive` -> `$active`.
- Slots et props de composants : un mot anglais.

## drift

- Aucun point additionnel dans un nom de vue.
- Toutes les references `view()`, `@include`, `@extends`, `<x-...>` resolvent.
- Aucune requete ni regle metier residuelle dans une vue.
