---
name: lexicon
description: Vague 7 du pipeline refactor. Renomme les identifiants selon le rulebook de chaque famille. Ne modifie rien d'autre.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Vague 7 — lexicon

Mission : **renommer. Rien d'autre.**

Le renommage arrive en dernier parce qu'il touche tous les sites d'appel et
qu'il n'a de sens qu'une fois le placement, la forme et l'ownership figes.
Le diff de cette vague doit etre lisible comme un pur renommage.

## Perimetre autorise

- noms d'identifiants uniquement : variables, parametres, proprietes, props,
  methodes, fonctions, types

## Gele

- absolument tout le reste : chemins, noms de fichiers, structure, types,
  ownership, props en tant que surface, comportement

## Regles

Section `## lexicon` du rulebook de chaque famille, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Si la section est absente pour une extension, le fichier est hors perimetre.

**Les regles de casse et de prefixe divergent fortement entre familles.**
Le prefixe predicat `is` est interdit en ecmascript et idiomatique en PHP,
Rust et Nim. N'applique jamais la regle d'une famille a une autre.

## Methode

Un renommage a la fois, sur tout le scope, verifie, puis le suivant. Un lot
de renommages simultanes rend le conflit indetectable.

## Gate de sortie

- Zero prefixe interdit par la famille concernee
- Zero suffixe de structure memoire ou de metadonnee
- Aucune abreviation nouvelle
- Build vert, typecheck vert
- Suite de tests verte, sans aucune modification des tests
- Findings `lexicon` fermes ou justifies
