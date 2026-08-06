---
name: slice
description: Vague 1 du pipeline refactor. Place chaque fichier dans sa slice et applique la convention de nom de sa famille. Ne touche a aucune logique.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git mv *), Bash(git status *)
---

# Vague 1 — slice

Mission : **chaque fichier a la bonne place, sous le bon nom.**

## Perimetre autorise

- chemins et noms de fichiers
- creation de repertoires
- lignes d'import et d'export impactees par un deplacement
- mapping PSR-4, fichier .nimble, declarations de modules

## Gele

- toute logique, toute signature, tout identifiant de symbole
- tout fichier hors de `$scope`
- `src/legacy/`

## Regles

La convention depend de la famille. Lis la section `## slice` du rulebook
correspondant a l'extension de chaque fichier, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

**Ne generalise jamais la convention d'une famille a une autre.** Le point
separateur est une regle ecmascript ; il casse Blade, Rust et Nim.

Si un fichier a une extension sans rulebook : ne le touche pas.

## Methode

1. Une famille a la fois, un commit par famille.
2. Deplacement par `git mv` systematiquement, pour preserver l'historique.
3. Apres chaque lot, mettre a jour les references — y compris celles par
   chaine, que le compilateur ne verra pas : appels de vue, conteneur de
   services, configuration, references de classe par nom.
4. Build apres chaque lot, pas seulement a la fin.

## Gate de sortie

- Build vert, typecheck vert
- Aucune reference cassee, y compris les references par chaine
- Aucun fichier de reexport pur restant
- Zero import mort
- Findings `slice` du ledger fermes ou justifies
