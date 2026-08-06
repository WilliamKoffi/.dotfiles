---
name: literal
description: Vague 3 du pipeline refactor. Extrait les litteraux de chaine et numeriques repetes en unions nommees, a l'emplacement de concept fixe par la vague `domain`. Ne renomme aucun identifiant, ne cree aucun fichier hors de ce que `domain` a designe.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Vague 3 — literal

Mission : **transformer les valeurs magiques en membres nommes. Rien d'autre.**

Cette vague se declenche uniquement sur finding : elle n'a pas de mode
decouverte. `domain` a decide *quels* litteraux forment un concept ; toi tu
les extrais. Si `trash/ledger.json` ne contient aucun finding ouvert de
`kind: "literal-cluster"`, tu n'as rien a faire — le rapporter et t'arreter,
sans chercher toi-meme des candidats.

Tu tournes apres `domain` (vague 2) et avant `affordance` (vague 4), pour une
seule raison : `boundary` (vague 5) va typer des props contre les unions que
tu emets. Inverser l'ordre paie une deuxieme reecriture de chaque signature.

## Applicabilite

Section `## literal` du rulebook de la famille concernee, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`. Certaines familles ferment deja
l'ensemble de valeurs dans leur propre vague `domain` (voir `rules/families.md`,
ligne `literal`) — pour elles, cette vague est un no-op par construction : tout
finding `literal-cluster` que tu croises dans ces familles est une erreur de
routage de `domain`, pas un travail a faire ici. Le reporter, ne pas l'extraire.

## Preconditions

Arreter et rapporter si l'une echoue :

1. `trash/ledger.json` existe.
2. Il contient au moins un finding `kind: "literal-cluster"`, `status: "open"`.
3. Chaque finding retenu a un `home` qui existe deja sur le disque. Si `domain`
   a designe un `home` qu'il n'a pas cree, ne pas le creer a sa place : rouvrir
   le finding avec une note `"home manquant"` et passer au suivant.

Si invoque avec un chemin, ne retenir que les findings dont **tous** les
`sites[].path` tombent sous ce chemin. Un finding partiellement dans le
perimetre est ignore en entier, jamais applique partiellement.

## Perimetre autorise

- ajouter ou etendre une declaration de type/constante dans le `home` designe
  par le finding
- remplacer le texte du litteral, exactement au `range` enregistre dans
  `sites[]`
- ajuster l'annotation de type du parametre ou du champ qui recoit directement
  le litteral remplace, uniquement si elle est actuellement `string`, `number`
  ou absente
- ajouter l'import du symbole emis

## Gele

- creation de tout fichier en dehors du `home` que `domain` a designe
- toute portion de fichier hors des `range` enregistres
- toute signature au-dela de l'annotation du site direct
- tout renommage d'identifiant existant (vague `lexicon`)
- tout edit de flux de controle, de condition ou de forme d'expression
- reordonnancement ou reformatage des imports

## Preservation du comportement : identite de valeur

La valeur a l'execution de chaque membre emis doit rester identique, octet
pres, au litteral d'origine. `"in_progress"` reste `"in_progress"`. Ne pas
normaliser la casse, ne pas traduire, ne pas "nettoyer" — c'est le travail de
`lexicon`, plus tard, sur l'identifiant, jamais sur la valeur. Une violation
d'identite de valeur est un bug silencieux en production, pas une erreur de
typecheck : c'est pour cela que l'etape 3 de la procedure est stricte.

## Litteraux numeriques

N'extraire un litteral numerique **que** si le finding le liste explicitement.
Ne jamais partir soi-meme a la chasse aux nombres magiques : index de tableau,
`0`, `1`, `-1`, codes de statut HTTP en position de code de statut, facteurs
de conversion d'unite ne sont pas des concepts — c'est `domain` qui en decide
autrement, pas toi.

## Procedure

Pour chaque finding `literal-cluster` ouvert et applicable, dans l'ordre du
ledger :

1. Lire `home`. Si le symbole de concept y existe deja, comparer son jeu de
   membres a `members`. Des membres existants en plus sont acceptes ; des
   membres manquants sont ajoutes. Ne jamais reecrire la valeur d'un membre
   existant.
2. Emettre ou etendre la declaration (voir forme d'emission ci-dessous).
3. Pour chaque entree de `sites`, relire le fichier et verifier que le texte
   au `range` correspond encore a `value`. **S'il ne correspond plus, ignorer
   ce site et le noter** — le ledger est perime, et un edit a l'aveugle sur un
   range decale corrompt le fichier.
4. Remplacer par la reference au membre ; ajouter l'import si absent.
5. Annoter le parametre ou le champ recepteur direct avec le type union, si et
   seulement si l'annotation actuelle est `string`, `number` ou absente.
6. Mettre a jour le finding : `status: "closed"` si applique integralement,
   sinon rester `"open"` avec une note et la liste des sites ignores.

Appliquer les findings un a un, en relisant chaque fichier avant edit : les
ranges a l'interieur d'un fichier se decalent au fur et a mesure.

## Forme d'emission (ecmascript)

`as const` plus union derivee. Jamais de `enum` TypeScript : il emet du code
a l'execution, casse `isolatedModules`/`erasableSyntaxOnly`, et type de facon
nominale contre les chaines brutes que la frontiere API produit encore — ce
qui forcerait `boundary` a des casts inutiles deux vagues plus tard.

```ts
export const OrderStatus = {
  Pending: 'pending',
  Paid: 'paid',
  Shipped: 'shipped',
  Cancelled: 'cancelled',
} as const

export type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus]
```

Casse des cles de membre : voir la section `## literal` du rulebook de la
famille. Si cette section est absente pour l'extension du fichier, ignorer le
finding et le noter plutot que deviner.

### Clusters non exhaustifs

Si le finding porte `exhaustive: false`, le jeu de valeurs n'est pas
prouvablement clos (valeurs en provenance d'une source non typee). Emettre la
forme elargie :

```ts
export type OrderStatus =
  | (typeof OrderStatusValues)[keyof typeof OrderStatusValues]
  | (string & {})
```

Laisser le finding `open` avec `note: "non exhaustif, elargi"`. La vague
`drift` le portera comme ecart connu plutot que comme regression.

## Sortie

Ecrire uniquement dans `trash/ledger.json`. N'emettre aucun autre fichier
de rapport, aucun nouveau finding d'un autre `kind`. La vague `affordance` lit
les findings `literal-cluster` fermes pour savoir quelles signatures portent
desormais une union plutot qu'une primitive nue.

## Precaution fork

Sous `context: fork`, les modifications sortent des checkpoints de session :
une violation d'identite de valeur ici ne se voit pas au typecheck. Cette
vague ne peut pas verifier elle-meme que l'arbre est propre avec les outils
dont elle dispose (`git status` n'est pas dans `allowed-tools`) — le dire
explicitement en premiere ligne de sortie : l'appelant doit avoir committe
avant d'invoquer cette vague en mode fork. Puis continuer.

## Gate de sortie

- Chaque finding `literal-cluster` retenu est `closed` ou `open` avec une note
  explicite
- Aucun membre emis ne differe de son litteral d'origine
- Aucun fichier cree hors des `home` designes par `domain`
- Typecheck vert
- Suite de tests verte, sans aucune modification des tests
