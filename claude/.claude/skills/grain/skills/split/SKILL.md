---
name: split
description: Vague 6 du pipeline refactor. Decoupe ce qui est encore trop gros, aux frontieres qui ont survecu a la compression. Ne renomme aucun identifiant.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git mv *), Bash(git status *)
---

# Vague 6 — split

Mission : **decouper ce qui est reste gros, la ou la responsabilite change.**

Cette vague arrive tard **par construction**. Les vagues 2 a 4 ont supprime la
plomberie ; beaucoup de fichiers qui depassaient le seuil sont deja rentres
dans les clous. Decouper avant aurait produit de mauvaises coupes.

## Perimetre autorise

- decoupage d'un fichier en plusieurs
- creation de composeurs
- extraction d'assets graphiques
- imports impactes par un decoupage

## Gele

- surface de props et ownership (vague 5)
- definitions de types (vague 2)
- unions de litteraux extraites en vague 3
- emplacement des methodes de domaine (vague 4)
- noms d'identifiants (vague 7)
- comportement a l'execution

## Regles

Section `## split` du rulebook de chaque famille, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

**Le seuil de 150 lignes est un declencheur d'examen, jamais un ordre de
coupe.** Un fichier de 180 lignes qui fait une seule chose coherente reste
entier : consigne une derogation ecrite dans le ledger et passe au suivant.

Ne decoupe que sur une frontiere de responsabilite reelle.

## Contrainte de placement

Tout fichier cree ici respecte la convention de nom de la vague 1 pour sa
famille. Consulte la section `## slice` du rulebook — tu ne redecides rien.

## Gate de sortie

- Aucun fichier au-dessus du seuil sans derogation ecrite
- Tout fichier cree conforme a la convention de sa famille
- Aucun cycle d'import introduit
- Suite de tests verte, sans aucune modification des tests
- Findings `split` fermes ou justifies
