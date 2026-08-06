# Famille ecmascript

Extensions : `.js`, `.jsx`, `.ts`, `.tsx`, `.vue`

## slice

### Convention de nom

    <entity>.<role>.<ext>

Le role technique est separe de l'entite par un **point**, jamais par un tiret.
L'entite est en kebab-case si elle compte plusieurs mots.

    hooks/user-hook.ts        ->  hooks/user.hook.ts
    services/payment-service.ts -> services/payment.service.ts
    cards/user-card.tsx       ->  cards/user.card.tsx
    dialogs/login-dialog.vue  ->  dialogs/login.dialog.vue
    steps/building-choice.tsx ->  steps/building-choice.step.tsx

Cette convention remplace la dualite Pattern A / Pattern B. Une seule regle
pour les artefacts techniques et pour les composants UI.

**Derogation assumee.** Le role apparait a la fois dans le dossier et dans le
suffixe (`cards/user.card.tsx`). C'est voulu : le dossier sert la navigation
dans l'arborescence, le suffixe sert l'onglet d'editeur, le fuzzy-find, la
stack trace et le `git log`. Ne pas "corriger" cette redondance.

### Roles reconnus

Techniques :

    service hook schema type store validator constant query repository
    guard adapter mapper factory client config util

UI :

    card dialog drawer form input list menu modal popover select sheet
    sidebar step table tab timeline toolbar tooltip widget badge avatar
    button checkbox radio layout page view

Un fichier dont le role n'est pas dans cette liste garde son nom nu
(`user.ts`). Ne pas inventer de role.

### Structure

- Slice verticale : `features/<feature>/` possede tout ce dont elle a besoin.
- `shared/` seulement a partir de **trois** consommateurs independants.
- Le dossier de categorie est le pluriel du role : `cards/`, `hooks/`.
- Les assets graphiques vont dans `assets/` (`choice/assets/papers.tsx`).
- `index.tsx` qui rend du JSX = composeur, autorise.
- `index.ts` qui ne fait que reexporter = barrel, interdit.
- Alias de chemins preserves. Imports morts supprimes.

### Cas `.vue`

Meme convention. Le SFC n'a pas de contrainte de resolution, donc
`login.dialog.vue` est sur. Si le projet utilise l'auto-import de composants
(Nuxt, `unplugin-vue-components`), verifier que le resolveur tolere les points
avant de renommer : sinon consigner un finding `slice` bloque plutot que
casser la resolution.

## domain

- Si plusieurs valeurs voyagent toujours ensemble, extraire un nom de domaine.
  Trois primitives correlees ou plus dans une signature = finding.
- Jamais de forme de retour anonyme (`{ tone: string; text: string }[]`).
  Declarer et exporter une interface nommee.
- DTO partageant un socle -> heritage d'interface (`Query extends Profile`).
- Bannir `any` et `any[]`.
- Une fonction a plus de trois arguments -> regrouper en DTO typé.

## literal

- Cles de membre en PascalCase dans l'objet `as const` (`Pending`, `Paid`).
  La valeur associee reste le litteral d'origine, inchangee.
- Nom du concept exporte : PascalCase singulier (`OrderStatus`, pas
  `OrderStatuses` ni `ORDER_STATUS`).
- Jamais de `enum` TypeScript — voir la justification dans `literal/SKILL.md`.
- Un cluster dont les valeurs traversent deja un objet `as const` existant
  n'est pas un nouveau finding : c'est `domain` qui aurait du le rattacher au
  concept existant plutot que d'en ouvrir un second.

## affordance

- Supprimer les agent nouns : `*Manager`, `*Service`, `*Handler`,
  `*Broadcaster`, `*Sender`, `*Engine`, `*Helper`, `*Util` porteur de logique.
- Deplacer la methode vers l'objet qui detient l'etat.
  `Gardener.water(plant)` -> `plant.water()`.
- God object : `user.redeemLicense()` -> `license.redeem(user)`.
- Sans etat entre appels -> `export namespace Domaine { ... }` avec fonctions
  pures. Avec etat -> entite.
- Purger les wrappers `get*` qui n'encapsulent rien.

## boundary

S'applique a `.tsx`, `.jsx`, `.vue`. Pas aux modules purs.

- Le parent detient l'etat metier. Le composant detient l'etat de presentation.
- Interdits en props : `setX`, `showX`, `openX`, `toggleX`, et toute paire
  `open`/`close` traversant une frontiere.
- L'etat d'interaction s'internalise dans un hook local (`usePicker()`).
- Sequence obligatoire, dans cet ordre :
  detecter primitives repetees -> extraire le nom -> reduire les props ->
  internaliser l'etat UI. Le decoupage vient plus tard, en vague `split`.
- Une prop = une affordance. `upload`, `submit`, `close`, `back`, `choose`.

## split

- Seuil d'inspection : 150 lignes. C'est un **declencheur d'examen**, pas un
  ordre de decoupage automatique.
- Ne decouper que sur une frontiere de responsabilite reelle. Si le fichier
  fait 180 lignes d'une seule chose coherente, le laisser et consigner une
  derogation ecrite.
- Coupes typiques d'un module mixte : `measure.ts` / `listen.ts` /
  `animate.ts` / `hook.ts`.
- Extraire les SVG inline vers `assets/`.
- Tout fichier cree ici respecte la convention de nom de la section `slice`.

## lexicon

Renommage d'identifiants uniquement.

- Props : un mot anglais. Compose `<qualifieur><nom>` tolere si le nom seul
  est ambigu (`activeTab` oui, `active` non). `<verbe><nom>` et `is<X>`
  interdits en props.
- Prefixes bannis : `handle*`, `on*`, `callback*`, `trigger*`, `execute*`,
  `process*`, `is*`.
- Suffixes bannis (fuite de structure memoire ou de metadonnee) :
  `*Set`, `*Pool`, `*Tag`, `*Flags`, `*Meta`, `*List`, `*Array`.
- Setter `useState` local : `setX` en camelCase. **Obligatoire, pas un smell.**
  L'interdiction de `setX` porte sur les props publiques, pas sur les setters
  locaux.
- Elevation du vocabulaire : `position` -> `role`, `company` -> `employer`,
  `isRemote` -> `remote`, `selectedSet` -> `chosen`, `isFr` -> `french`.
- Pas d'abreviations, pas d'acronymes.
- Nom de fichier : lowercase, kebab-case pour l'entite.

## drift

- Aucun fichier hors convention `<entity>.<role>.<ext>` pour un role reconnu.
- Aucun barrel reintroduit.
- Aucun agent noun reintroduit.
- Les fichiers crees par `domain`, `affordance`, `boundary` et `split` sont
  places et nommes selon la section `slice`.
- Build vert, typecheck vert.
