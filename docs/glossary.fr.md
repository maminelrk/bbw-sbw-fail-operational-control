# Glossaire et notation communs

Version associée : [English](glossary.en.md).

| Terme / symbole | Sens retenu dans le projet |
|---|---|
| BbW / SbW | Freinage par commande électrique / direction par commande électrique |
| DBBS | Direction de secours par freinage différentiel : correction du lacet par forces de freinage inégales ; pas de braquage de crémaillère via rayon de pivot |
| BAS | Terme historique de la littérature ; pas le nom du mécanisme actuellement implémenté |
| Fail-operational | Maintien de la fonction spécifiée après le défaut défini, dans une enveloppe donnée ; pas de performance nominale illimitée |
| Fail-safe | Passage à une condition sûre définie ; non synonyme de maintien de fonction |
| Plante | Véhicule, pneus et actionneurs recevant les commandes |
| Allocateur / QP | Optimisation contrainte transformant force/moment demandés en quatre forces de frein et une consigne d'angle |
| `h_physical`, `h_known` | Disponibilité réelle des canaux ; disponibilité connue de la commande |
| `t_p`, `t_flag` | Apparition physique du défaut ; livraison du drapeau validé |
| `Fx`, `Mz` | Force longitudinale véhicule [N], moment de lacet [N m] ; freinage négatif en `Fx` |
| `delta` | Angle commun de roue directrice [rad], pas angle du volant |
| `omegaA`, `omegaB` | Contributions moteur avant limitation physique, exprimées en vitesses angulaires équivalentes de roue [rad/s], pas vitesses rotor |
| `r`, `beta` | Vitesse de lacet [rad/s] ; dérive véhicule `atan2(vy,vx)` [rad] |
| FL/FR/RL/RR | Avant gauche/avant droit/arrière gauche/arrière droit ; axe latéral positif à gauche |
| Nominal / dégradé | Sans défaut / après le défaut défini ; état initial et consigne appariés |
| Meilleur effort / oracle | Allocation bornée minimisant le résidu ; prédiction affine à masque réel utilisée comme diagnostic |
| Autorité résiduelle | Capacité restante réalisable sous contraintes simultanées définies, pas somme de maxima incompatibles |
| AMDEC / FTA / DFA | Analyse des modes de défaillance et effets / arbre de défaillances / analyse des défaillances dépendantes |
| ASIL B(D) | Allocation candidate ASIL B contribuant à une exigence initiale ASIL D ; pas un label obtenu par simulation |
| Preuve préliminaire | Contrôle numérique indépendant explicitement identifié ; ni validation MATLAB, ni preuve matérielle, ni acceptation encadrant |
