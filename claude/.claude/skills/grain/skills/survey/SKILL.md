---
name: survey
description: Vague 0 du pipeline refactor. Inventorie le scope en lecture seule et produit le ledger des findings. Ne modifie aucun code.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(git status *)
---

# Vague 0 — survey

Lecture seule. **Tu ne modifies aucun fichier de code.** Seule sortie
autorisee : `trash/ledger.json`.

## Entree

Rulebooks charges par le routeur. Pour chaque famille presente, lis les
sections de toutes les vagues afin de savoir quoi chercher.

## Travail sur `$scope`

1. Arbre des fichiers, par extension et par famille.
2. Graphe de dependances entre repertoires. Signale les cycles.
3. Candidats de slices : quels fichiers changent ensemble
   (`git log --name-only` sur les 200 derniers commits).
4. Utilitaires, hooks, schemas, types dupliques.
5. Code mort : exports sans consommateur.
6. Zones intouchables (`src/legacy/`, vendored, genere).

Pour chaque probleme detecte, emets un finding **adresse a la vague qui le
possede**. Ne propose aucune correction.

## Sortie

Cree ou met a jour `trash/ledger.json` a la racine du projet :

    {
      "scope": "<scope>",
      "families": ["ecmascript", "php"],
      "findings": [
        { "id": "F-001", "wave": "slice", "family": "ecmascript",
          "kind": "naming", "path": "src/hooks/user-hook.ts",
          "note": "tiret au lieu du point", "status": "open" }
      ]
    }

Un finding peut porter des champs additionnels propres a sa vague
proprietaire — par exemple `kind: "literal-cluster"`, ouvert par `domain` pour
la vague `literal` (voir `domain/SKILL.md`). `survey` ne genere jamais ce
`kind` lui-meme : il n'a pas la vision du concept qu'un cluster de litteraux
represente, seule `domain` l'a.

Identifiants sequentiels et stables. Ne jamais reutiliser un id retire.

## Gate de sortie

- Aucun fichier de code modifie
- Chaque finding porte une vague proprietaire et une famille
- Les extensions non couvertes par un rulebook sont listees explicitement
