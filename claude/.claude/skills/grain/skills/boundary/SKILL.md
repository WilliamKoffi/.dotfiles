---
name: boundary
description: Vague 5 du pipeline refactor. Internalise l'etat de presentation, compresse la surface de props, et extrait la logique hors des vues. Ne decoupe aucun fichier.
argument-hint: [chemin]
arguments: [scope]
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Vague 5 — boundary

Mission : **l'etat metier reste dehors, l'etat de presentation rentre dedans.**

Ne s'applique qu'aux familles dont le rulebook possede une section
`## boundary` : composants ecmascript et vues Blade. Un module pur n'a ni
props ni etat de presentation — saute-le.

## Perimetre autorise

- surface de props d'un composant
- hooks ou objets de presentation internes
- cablage cote parent impacte par la compression
- extraction de logique hors des vues, vers l'entite ou un objet de
  presentation dedie

## Gele

- chemins et noms de fichiers
- definitions de types (vague 2)
- unions de litteraux extraites en vague 3
- emplacement des methodes de domaine (vague 4)
- decoupage de fichiers (vague 6)
- noms d'identifiants (vague 7)

## Regles

Section `## boundary` du rulebook de chaque famille, dans
`${CLAUDE_PLUGIN_ROOT}/shared/rules/`.

## Sequence obligatoire

Dans cet ordre, sans exception :

    detecter les primitives repetees
      -> utiliser le nom ou l'union deja extraits en vagues 2 et 3
      -> reduire le nombre de props
      -> internaliser l'etat d'interaction

Le decoupage n'appartient pas a cette vague. Un composant qui reste gros apres
compression sera traite en vague 6 — et il sera souvent devenu petit tout seul.

## Signaux

- prop `setX`, `showX`, `openX`, `toggleX`
- paire ouverture / fermeture traversant une frontiere
- plus de trois callbacks en props
- plus de deux booleens en props
- requete, regle metier ou appel reseau a l'interieur d'une vue

## Gate de sortie

- Aucune prop setter ni mecanique d'ouverture dans le scope
- Aucune requete ni regle metier residuelle dans une vue
- Rendu identique a l'octet pres
- Suite de tests verte, sans aucune modification des tests
- Findings `boundary` fermes ou justifies
