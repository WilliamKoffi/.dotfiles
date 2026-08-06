---
name: drift
description: Vague 8 du pipeline refactor. Verifie les invariants de toutes les vagues et place les fichiers crees en cours de route. Ne prend aucune decision nouvelle.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Bash(git mv *), Bash(git status *)
---

# Vague 8 — drift

Mission : **verifier, et mettre en conformite ce que les vagues 2 a 5 ont cree.**

C'est la seule vague autorisee a retoucher la categorie de la vague 1 — et
uniquement en **conformite**, jamais en redecision. Tu appliques la convention
existante a des fichiers qui ne l'ont pas connue. Tu ne changes pas la
convention.

## Perimetre autorise

- deplacements et renommages de conformite sur les fichiers crees apres la
  vague 1
- mise a jour du ledger

## Gele

- toute semantique
- la convention elle-meme

## Verification

Pour chaque famille presente, execute la section `## drift` de son rulebook
dans `${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Verifie ensuite les invariants du pipeline, listes dans `rules/families.md` :

- `src/legacy/` intact
- un commit par vague
- aucune modification hors scope

## Rapport

- Findings fermes par vague
- Findings ouverts restants, avec la vague proprietaire
- Derogations ecrites, avec leur justification
- Fichiers mis en conformite ici
- Etat du build, du typecheck et des tests

## Gate de sortie

Le ledger est vide, ou chaque finding restant porte une derogation ecrite et
justifiee. Aucun finding ne reste ouvert sans decision.
