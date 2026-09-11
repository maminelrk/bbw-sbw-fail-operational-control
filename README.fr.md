# Allocation de commande tolérante aux défaillances pour BbW et SbW

[English](README.en.md) | [Index des langues](README.md)

## Présentation

Ce projet développe un allocateur de commande sensible aux défauts pour une architecture véhicule intégrant le freinage Brake-by-Wire (BbW) et la direction Steer-by-Wire (SbW). Il répartit une force longitudinale et un moment de lacet demandés entre quatre actionneurs de freinage indépendants et un actionneur de direction.

Lorsque la demande complète est physiquement irréalisable, l'allocateur fournit la meilleure solution réalisable respectant les limites. Lorsqu'un actionneur tombe en panne, un masque binaire supprime son autorité et l'allocateur redistribue la demande entre les actionneurs sains restants.

Le projet utilise le Brake-Actuated Steering (BAS), ou braquage produit par freinage, comme principe physique de contrôle latéral dégradé. La fonction de secours implémentée est appelée Differential-Braking Backup Steering (DBBS) : un freinage asymétrique génère un moment de lacet correctif lorsque la direction commandée est indisponible.

## État du développement

Ce dépôt constitue une référence de développement et de validation Gate 2. Il ne constitue pas un dossier de sécurité achevé.

Éléments implémentés :

- allocateur par programmation quadratique bornée avec solution au mieux réalisable ;
- limites physiques des forces de freinage et de l'angle de direction ;
- limites de variation des forces de freinage et de la direction ;
- masques nommés pour les défauts d'un seul actionneur ;
- calcul statique de l'autorité résiduelle ;
- tests unitaires MATLAB ;
- scénarios nominaux, de saturation, de défaut de frein et de perte de direction ;
- critères numériques pour REQ-02 et REQ-03 ;
- traçabilité entre exigences et tests.

Éléments restant à réaliser :

- exécution de la campagne de validation dans une installation MATLAB ;
- intégration du wrapper à trois entrées avec masque de défaut dans `wawaw.slx` ;
- comparaison véhicule nominal/défaillant pour la continuité du lacet ;
- modélisation indépendante des deux canaux de l'actionneur de direction ;
- commande en boucle fermée du lacet et de la trajectoire pour la validation dynamique DBBS ;
- AMDEC, analyse des défaillances dépendantes et preuves d'architecture pour les objectifs de sécurité.

## Formulation de l'allocation

La demande généralisée est

```text
y_d = [Fx_d; Mz_d]
```

et la commande calculée par l'allocateur est

```text
u = [Fx_FL; Fx_FR; Fx_RL; Fx_RR; delta]
```

L'allocateur minimise l'erreur de suivi normalisée et une faible pénalisation de l'effort des actionneurs :

```text
min 0.5 (B u - y_d)' Q (B u - y_d) + 0.5 rho u' R u
```

sous contraintes de limites physiques, de vitesses de commande et du masque de défaut actif. Une demande irréalisable produit donc une solution bornée au mieux réalisable, et non une commande nulle.

## Prérequis

- MATLAB
- Simulink
- Optimization Toolbox (`quadprog`)
- MATLAB Unit Test Framework

La version exacte de MATLAB utilisée devra être enregistrée lors de la première exécution de référence.

## Exécution de la validation

Ouvrir MATLAB à la racine du dépôt puis exécuter :

```matlab
summary = run_project_validation();
```

Cette commande lance les tests unitaires et tous les scénarios configurés. Les preuves CSV, MAT et PNG sont générées dans `validation/results/`. Ce dossier est volontairement exclu de Git, car son contenu peut être régénéré.

Les contrôles statiques peuvent être lancés séparément :

```matlab
authority = control_authority_report();
run("test_allocator_basic.m");
```

## Organisation du dépôt

```text
allocator.m                       Allocateur avec solution au mieux réalisable
fault_scenario_mask.m             Masques nommés de santé et de défaut
get_params.m                      Paramètres véhicule et allocateur
control_authority_report.m        Calcul statique de l'autorité résiduelle
simulink_allocator_wrapper.m      Wrapper Simulink sensible aux défauts
wawaw.slx                         Modèle de simulation véhicule actuel
validation/                       Campagne de validation automatisée
tests/                            Tests unitaires MATLAB
docs/                             Documentation technique bilingue
run_project_validation.m          Point d'entrée de validation du dépôt
```

## Documentation

- [Référence numérique des exigences](docs/requirements_baseline.fr.md)
- [Choix de la chaîne d'outils MATLAB/Simulink](docs/toolchain_decision.fr.md)
- Les matrices de traçabilité anglaise et française se trouvent dans `docs/verification/`.

## Avertissement sur la sécurité et le périmètre

Les critères numériques et les simulations servent à la vérification du projet. Ils ne démontrent ni la conformité à l'ISO 26262 ni la sécurité d'un véhicule. Les exigences dépendant de la dynamique véhicule, de l'indépendance matérielle, de la détection des défauts ou de la perception humaine nécessitent des analyses et des preuves physiques supplémentaires.

Le CDC, le rapport Gate 1, le workflow de stage et leurs copies extraites ne font pas partie de ce dépôt. Ils ne doivent pas être ajoutés aux commits.

## Licence

Aucune licence open source n'a été attribuée. Il ne faut pas supposer un droit de réutilisation ou de redistribution du projet. Une licence ne devra être ajoutée qu'après confirmation des droits de propriété et de publication.
