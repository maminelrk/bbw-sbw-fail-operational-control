# Allocation de commande tolérante aux défaillances pour BbW et SbW

[English](README.en.md) | [Index des langues](README.md)

## Présentation

Ce projet de stage développe et documente une simulation intégrée du freinage Brake-by-Wire (BbW) et de la direction Steer-by-Wire (SbW). Il répartit les demandes de force longitudinale et de moment de lacet entre quatre freins et une crémaillère commune entraînée par deux canaux d'actionneur masqués indépendamment.

Lorsque la demande complète est physiquement irréalisable, l'allocateur fournit la meilleure solution réalisable respectant les limites. Lorsqu'un actionneur tombe en panne, un masque binaire supprime son autorité et l'allocateur redistribue la demande entre les actionneurs sains restants.

Le concept de secours est le Differential-Braking Backup Steering (DBBS) : un freinage asymétrique produit un moment de lacet correctif lorsque la direction commandée est indisponible. Le braquage de crémaillère par rayon de pivot n'est pas modélisé. La commande corrigée respecte les critères de l'impulsion retenue dans les huit cas DBBS étudiés ; les conditions élargies relèvent des perspectives.

## État du développement

**Livrable académique achevé dans le périmètre révisé SC-2026-01.** L'auteur confirme que le garant autorise l'adaptation du CDC au livrable de stage. La [note de périmètre final](docs/final_scope.fr.md) définit les acquis et perspectives. Les rapports finaux LaTeX français/anglais et les sources testées figées restent privés ; aucune nouvelle simulation MATLAB ni aucun support de soutenance n'a été produit pendant cette finalisation.

Les preuves conservées comprennent la campagne Gate 2, 45 tests unitaires, cinq manœuvres nominales, les diagnostics de 30 cas initiaux de défaut et quatre raffinements pour `ALLOC-2026-04`. L'archive et 54 séries temporelles ont été auditées localement. La gestion des transitions saturées, les garanties continues d'enveloppe/récupération non linéaire et la validation matérielle sont hors acceptation académique finale et restent des perspectives documentées. Les mesures et indicateurs historiques sont inchangés : l'achèvement académique délimité se distingue d'une conformité universelle ou d'une certification de série. Voir l'[état actuel](docs/project_status.fr.md) et l'[audit détaillé tâche 2](docs/task2_assessment.fr.md).

Éléments implémentés :

- allocateur par programmation quadratique bornée avec solution au mieux réalisable ;
- limites physiques des forces de freinage et de l'angle de direction ;
- limites de variation des forces de freinage et de la direction ;
- masques nommés pour les défauts d'un seul actionneur ;
- traçabilité documentée des paramètres du véhicule de référence ;
- campagne de validation du modèle en boucle ouverte sans allocateur ;
- deux boucles de vitesse entraînant une crémaillère commune, avec masques A/B ;
- allocateur connecté au véhicule non linéaire à 13 états dans une boucle échantillonnée ;
- cinq manœuvres nominales variables, figures françaises/anglaises et manifeste d'exécution ;
- calcul statique de l'autorité résiduelle ;
- tests unitaires MATLAB ;
- scénarios nominaux, de saturation, de défaut de frein et de perte de direction ;
- 30 cas Gate 3 séparant la défaillance physique du diagnostic retardé ;
- comparaisons nominal/défaillant, diagnostics de récupération et figures bilingues ;
- critères numériques pour REQ-02 et REQ-03 ;
- traçabilité entre exigences et tests.

Décisions et limites restantes :

- résolution de la faisabilité transitoire en freinage saturé et évaluation indépendante de récupération ;
- documents historiques conservés pour traçabilité ; rapports privés actuels fondés sur les preuves corrigées et auditées ;
- aucune preuve d'enveloppe continue ni de maxima globaux revendiquée ;
- limites de sémantique capteurs/chemins, modes non couverts et indépendance physique ;
- relecture des livrables privés par les étudiants et préparation de soutenance.

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
min 0.5 (c + B u - y_d)' Q (c + B u - y_d) + 0.5 rho u' R u
```

sous contraintes de limites physiques, d'une réserve longitudinale nominale de 2 % (portée à 8 % à l'arrière après diagnostic de perte d'un seul frein avant avec les deux freins arrière sains), de vitesses et de six indicateurs de santé `[FL FR RL RR A B]`. Dans la boucle intégrée, `c` et `B` sont recalculés à partir de l'état ; la performance est mesurée sur les sorties non linéaires du véhicule. Voir le [guide Gate 2](docs/gate2.fr.md) et la [commande corrigée](docs/task1_control.fr.md).

## Prérequis

- Référence exécutée : MATLAB R2026a Update 5 ; anciennes versions non vérifiées pour le workflow complémentaire complet
- Simulink uniquement pour l'ancien prototype par blocs
- Optimization Toolbox (`quadprog`, et `fmincon` pour l'étude complémentaire)
- MATLAB Unit Test Framework

Exécution de référence : MATLAB Online R2026a Update 5 avec Optimization Toolbox ; version détaillée, identité des sources et configuration sont enregistrées avec les preuves.

## Exécution de la validation

Utiliser une nouvelle copie du projet pour préserver les preuves auditées : les lanceurs écrivent dans des dossiers fixes. Ouvrir MATLAB à la racine de cette copie puis lancer Gate 2. Voir la [reproduction sans écrasement](docs/handover.fr.md).

```matlab
results = run_gate2_validation();
```

Cette commande lance les tests unitaires, le modèle seul, le banc de direction, cinq manœuvres intégrées et la convergence du pas. Les CSV, MAT, figures françaises/anglaises et le manifeste sont générés dans `validation/results/`. Un échec empêche l'état d'acceptation. `run_project_validation()` ajoute les anciens tests d'allocation à demande constante. Les preuves générées sont exclues de Git.

Pour reproduire la campagne de défauts déjà exécutée dans la nouvelle copie :

```matlab
faultResults = run_gate3_validation();
```

Elle exécute les tests unitaires, quatre références nominales appariées et 30 cas de défaut avec diagnostic retardé. Son manifeste maintient toujours Gate 3 ouvert : réussir les diagnostics de manœuvre ne démontre ni l'enveloppe complète REQ-02/03 ni un dossier de sécurité. Voir le [guide Gate 3](docs/gate3.fr.md) et le [registre courant des jalons](docs/project_status.fr.md).

Pour valider uniquement le modèle, sans appeler l'allocateur :

```matlab
plantSummary = run_plant_validation();
```

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
wawaw.slx                         Prototype Simulink archivé à 11 états
steering_actuator_dynamics.m      Direction à deux canaux et crémaillère commune
plant_step.m                      Pas RK4 du modèle non linéaire intégré
run_gate2_validation.m            Point d'entrée des preuves et contrôles Gate 2
run_gate3_validation.m            Point d'entrée des preuves préliminaires Gate 3
straight_braking_screening.m      Estimation restreinte à braquage et lacet nuls
validation/                       Campagne de validation automatisée
tests/                            Tests unitaires MATLAB
docs/                             Documentation technique bilingue
run_project_validation.m          Point d'entrée de validation du dépôt
run_plant_validation.m            Point d'entrée de validation sans allocateur
```

## Documentation

- [État des jalons et livrables du stage](docs/project_status.fr.md)
- [Campagne Gate 3 avec diagnostic retardé](docs/gate3.fr.md)
- [Glossaire et notation communs](docs/glossary.fr.md)
- [Architecture, manœuvres et preuves Gate 2 courantes](docs/gate2.fr.md)
- [Preuves Gate 2 vérifiées et procédure de présentation](docs/gate2_evidence.fr.md)

- [Référence numérique des exigences](docs/requirements_baseline.fr.md)
- [Paramètres du véhicule et du modèle](docs/parameters.fr.md)
- [Validation du modèle en boucle ouverte sans allocateur](docs/plant_validation.fr.md)
- [Choix de la chaîne d'outils MATLAB/Simulink](docs/toolchain_decision.fr.md)
- Les classeurs de `docs/verification/` sont des instantanés REF-2026-01 ; le guide Gate 2 remplace leurs indications d'état d'implémentation courant.

Les brouillons AMDEC/arbre/DFA et rapports LaTeX bilingues sont conservés localement dans `reports/`, ignoré par Git ; ils ne sont pas distribués avec les sources du projet.

## Avertissement sur la sécurité et le périmètre

Les critères numériques et les simulations servent à la vérification du projet. Ils ne démontrent ni la conformité à l'ISO 26262 ni la sécurité d'un véhicule. Les exigences dépendant de la dynamique véhicule, de l'indépendance matérielle, de la détection des défauts ou de la perception humaine nécessitent des analyses et des preuves physiques supplémentaires.

Le CDC, le rapport Gate 1, le workflow de stage et leurs copies extraites ne font pas partie de ce dépôt. Ils ne doivent pas être ajoutés aux commits.

## Licence

Aucune licence open source n'a été attribuée. Il ne faut pas supposer un droit de réutilisation ou de redistribution du projet. Une licence ne devra être ajoutée qu'après confirmation des droits de propriété et de publication.
