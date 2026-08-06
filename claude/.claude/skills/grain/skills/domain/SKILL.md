---
name: domain
description: Vague 2 du pipeline refactor. Cree les noms de domaine manquants et rend toutes les formes explicites. Ne deplace ni ne renomme aucun fichier.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Vague 2 — domain

Mission : **les concepts que le code manipule sans les nommer recoivent un nom.**

## Perimetre autorise

- nouveaux fichiers de types, interfaces, structs, enums, value objects
- annotations de type sur signatures existantes
- hierarchies de DTO
- remplacement de primitives correlees par le nom extrait, aux sites d'appel

## Gele

- chemins et noms de fichiers (la vague 1 les a fixes)
- emplacement des methodes (vague 4)
- noms d'identifiants existants (vague 7)
- comportement a l'execution

## Regles

Section `## domain` du rulebook de chaque famille, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Tout fichier cree ici respecte la convention de nom etablie en vague 1 pour sa
famille. Tu ne redecides pas la convention, tu la consultes.

## Signaux

- trois primitives correlees ou plus dans une signature
- forme de retour anonyme
- ensemble ferme de valeurs modelise en booleens multiples ou en chaines
- typage evasif

## Litteraux repetes : findings pour la vague 3

Certaines familles ferment elles-memes l'ensemble ferme de valeurs (`enum`
PHP, `enum` Rust, `enum` Nim — voir la section `## domain` de leur rulebook).
Pour ces familles, ne rien deleguer : tu extrais deja tout ici.

Pour les familles dont le rulebook n'a pas de mecanisme d'enum natif consacre
dans `## domain` (ecmascript aujourd'hui), un cluster de litteraux repetes
n'est **pas** ta charge d'extraction — c'est un finding que tu ouvres pour la
vague `literal` :

    {
      "id": "F-014", "wave": "literal", "family": "ecmascript",
      "kind": "literal-cluster", "status": "open",
      "concept": "OrderStatus", "home": "src/orders/types.ts",
      "members": ["pending", "paid", "shipped", "cancelled"],
      "exhaustive": true,
      "sites": [
        { "path": "src/orders/api.ts", "range": [42, 51], "value": "pending" }
      ]
    }

`home` doit etre un chemin qui existe deja ou qui est le nom de domaine que
*toi* tu es en train de creer dans cette meme vague — jamais un chemin que
`literal` devra inventer. `exhaustive: false` si le jeu de valeurs n'est pas
prouvablement clos (ex : valeurs en provenance d'une API non typee). Toi seul
decides si deux chaines identiques sont un seul concept ou deux coincidences
— `literal` ne rouvre jamais ce jugement, il ne fait qu'extraire.

## Gate de sortie

- Aucune forme de retour anonyme dans le scope
- Aucun groupe de trois primitives correlees ou plus en signature
- Typecheck vert
- Suite de tests verte, sans aucune modification des tests
- Findings `domain` fermes ou justifies
- Tout cluster de litteraux repetes ecmascript a un finding `literal` ouvert
  ou une derogation ecrite
