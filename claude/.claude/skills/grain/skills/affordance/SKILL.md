---
name: affordance
description: Vague 4 du pipeline refactor. Deplace le comportement vers l'objet qui detient l'etat et supprime les agent nouns. Ne renomme aucun fichier.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Vague 4 — affordance

Mission : **le comportement vit sur l'objet qui detient l'etat.**

## Perimetre autorise

- emplacement des methodes et fonctions
- appartenance a une classe, un impl, un module, un namespace
- suppression des classes agent noun
- sites d'appel impactes

## Gele

- chemins et noms de fichiers
- definitions de types creees en vague 2
- unions de litteraux extraites en vague 3
- props et etat de presentation (vague 5)
- noms d'identifiants (vague 7)
- comportement a l'execution

## Regles

Section `## affordance` du rulebook de chaque famille, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

Principe commun : deplacer la methode vers l'objet qui detient l'etat, pas
vers celui qui execute l'action.

## Entite ou namespace

La vague 2 a decide **qu'un nom manquait**. Tu decides **de quelle nature il
est** :

- il conserve de l'etat entre deux appels -> entite
- il n'en conserve pas -> namespace, module, ou fonction libre

Ne cree jamais un objet vide pour grouper des fonctions sans etat. Chaque
langage cible a deja un mecanisme de regroupement : utilise le sien.

## Gate de sortie

- Zero classe ou struct agent noun dans le scope
- Aucune methode dont le corps mute principalement un autre objet
- Suite de tests verte, sans aucune modification des tests
- Findings `affordance` fermes ou justifies
