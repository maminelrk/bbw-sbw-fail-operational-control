# Implémentation et preuves Gate 2

Modèle courant : `REF-2026-02`. État : implémenté, exécution MATLAB en attente.
Le jalon du stage sera clos après revue des résultats MATLAB sauvegardés et des figures. Les PDF sources et les nouveaux rapports LaTeX de clôture sont conservés dans le dossier ignoré `reports/`.

## Exécution

Depuis la racine du projet dans MATLAB (R2021a ou plus récent, Optimization Toolbox) :

```matlab
results = run_gate2_validation();
```

Simulink n'est pas nécessaire pour cette campagne par scripts. `wawaw.slx` est un prototype archivé à 11 états et ne constitue pas le modèle Gate 2 courant. La simulation intégrée de référence utilise `validation/run_integrated_maneuver.m` et `plant_step.m`. L'ancienne campagne à demandes constantes reste un test de non-régression de l'allocateur ; elle ne constitue pas la preuve nominale au niveau véhicule.

Le lanceur exécute les tests unitaires, trois essais du modèle seul, quatre essais de direction, cinq manœuvres intégrées et une comparaison des pas de 2 ms et 1 ms. Un échec sauvegarde les métriques et déclenche une erreur. Tous les contrôles réussis donnent l'état `READY_FOR_SUPERVISOR_REVIEW`, sans valoir acceptation automatique de l'encadrant.

## Architecture de direction

Deux servos en vitesse, masqués indépendamment, entraînent une crémaillère unique. L'état est :

```text
x = [vx vy r X Y psi delta FxFL FxFR FxRL FxRR omegaA omegaB]'
u = [FxFL FxFR FxRL FxRR delta_command]'
h = [brakeFL brakeFR brakeRL brakeRR steeringA steeringB]'
```

Une crémaillère commune possède un angle unique : il ne faut pas additionner deux angles de roue indépendants. Les canaux sains se partagent la vitesse demandée selon leur vitesse disponible. Chaque canal est supposé assurer toute la plage ±35° et 240°/s ; la somme est plafonnée à 400°/s. Ce modèle fonctionnel ne représente ni couples moteurs, ni inertie de crémaillère, ni efforts routiers. Le banc vérifie ces hypothèses avec une tolérance de 0,001 sur le rapport de vitesse, pour une réponse asymptotique.

La perte de A conserve B ; la perte de B conserve A. Une perte totale maintient le dernier angle de crémaillère et retire l'autorité commandée. Une crémaillère libre, un blocage arbitraire et les défauts capteurs exigent des modèles Gate 3 distincts. La perte d'un frein supprime sa force au contact même si son état interne décroît. Les anciens masques à cinq entrées sont étendus en recopiant l'indicateur de direction vers A et B.

## Intégration

Le générateur fournit `ax_ref`, `r_ref` et sa dérivée analytique. Un servo nominal de lacet demande :

```text
Fx_d = m (ax_ref - vy*r)
Mz_d = Iz (dr_ref/dt + (r_ref-r)/0.25)
```

Le QP utilise une carte affine locale `y = c + B*u`, évaluée autour de l'état non linéaire courant. Le terme constant conserve les forces passives des pneus et les effets de la direction existante. Une dérivée centrée de direction préserve la symétrie rectiligne. Les échelles de sortie fixes valent 5000 N et 1000 N·m ; les variables d'actionneur sont adimensionnées. La région de linéarisation de la direction est ±0,5° autour de l'angle réel, lorsqu'elle est compatible avec les limites de variation.

À chaque échantillon de 2 ms, les commandes sont maintenues pendant le pas RK4. Les forces et moments mesurés dans la simulation proviennent du modèle non linéaire, **pas** de la prédiction QP ; les deux sont enregistrés. Les bornes de freinage suivent les charges de roue. Une intersection réellement vide avec une limite de variation d'actionneur sain est signalée et provoque le rejet Gate 2. Une borne mobile à l'intérieur de l'intervalle de variation ne recentre pas la commande précédente.

Le modèle conserve les charges brutes pour qu'un délestage soit détecté. Le transfert latéral satisfait `(Fz_droite-Fz_gauche)*voie/2 = m*ay_est*hcg`. Un budget d'adhérence restant nul donne une force latérale nulle. Chaque paire de forces longitudinale/latérale respecte son cercle de friction. Le transfert quasi statique utilise encore des accélérations estimées, dont `ay=vx*r`, sans solution couplée de suspension.

## Catalogue des manœuvres

Tous les scénarios débutent à 60 km/h, canaux sains, sans état latéral ou de lacet et avec des états d'actionneur nuls. Les rampes suivent `3s²-2s³` sur `s∈[0,1]`. Ce catalogue remplace la couverture Gate 2 des anciens classeurs de traçabilité, conservés comme instantanés REF-2026-01.

| ID | Profil | Durée | Critère de comportement |
|---|---|---:|---|
| G2-BRK | Rampe -0,20g, 0,5–1,5 s ; relâchement 3,5–4,25 s | 6 s | RMSE force ≤250 N ; RMSE lacet ≤0,012 rad/s |
| G2-STR | Lacet équivalent à 1° de direction du modèle bicyclette ; montée 0,5–0,8 s ; relâchement 4–4,5 s | 6 s | Mêmes limites de suivi |
| G2-CMB | Impulsion -0,12g et impulsion de lacet 0,06 rad/s | 6 s | Mêmes limites de suivi |
| G2-YAW | `0,08 sin(2πs) sin²(πs)`, `s=(t-0,5)/5` entre 0,5 et 5,5 s | 6 s | Mêmes limites de suivi |
| G2-SAT | Demande -1,2μg, montée 0,5–1,25 s ; relâchement 2–2,75 s | 4 s | ≥95% μmg à 1,5–1,9 s ; <100 N après 3,2 s ; lacet rectiligne <1e-4 rad/s |

Chaque cas doit aussi respecter les limites de force/angle/vitesse, les contributions des deux moteurs, des charges brutes positives, les cercles de friction, des états finis, la convergence QP, une vitesse >0,5 m/s et une dérive ≤0,15 rad. Un dépassement d'autorité ne justifie aucun relâchement de limite. Le cas de saturation possède un critère de capacité/reprise plutôt qu'un critère de suivi de la demande.

## Preuves et traçabilité

| Sortie | Usage |
|---|---|
| `validation/results/gate2/run_manifest.json` | Version/produits MATLAB, date, paramètres, révision Git, état du dépôt et acceptation |
| `unit_tests.csv` | Non-régressions modèle, allocation et intégration |
| `steering/steering_summary.csv` | Banc nominal, perte A, perte B et perte totale |
| `maneuver_summary.csv` | Une ligne de métriques et d'acceptation par manœuvre |
| `<ID>/timeseries.csv`, `metrics.csv`, `result.mat` | Demandes, états, commandes, forces réelles, prédictions QP et charges de roue |
| `<ID>/response_en.png`, `response_fr.png` | Figures de réponse pour les deux langues du rapport |
| `<ID>/actuators_en.png`, `actuators_fr.png` | Freins, charges et contributions individuelles de direction |
| `step_convergence.csv` | Comparaison 2 ms/1 ms du cas combiné ; écart lacet ≤0,001 rad/s, vitesse ≤0,03 m/s |
| `validation/results/plant/` | Preuves du modèle sans allocateur |

REQ-01 est couvert par les diagnostics intégrés de bornes/vitesses/adhérence. REQ-03b dispose d'un banc fonctionnel, sans validation matérielle sous charge. REQ-02, REQ-03a/c dynamiques et REQ-04 restent des travaux Gate 3. Une capacité brute résiduelle de 69,7% et un rapport statique de lacet de 37,6% ne prouvent ni le freinage rectiligne ni une autorité direction-freinage simultanément réalisable.

## Contrôles dans l'environnement de développement

MATLAB n'est pas disponible. Les fichiers MATLAB ont été analysés par MISS_HIT. Une implémentation distincte des équations avec moindres carrés bornés SciPy a réussi les cinq manœuvres avec les mêmes réglages, seuils et période. Ce contrôle porte sur les équations et le comportement attendu du QP, sans constituer une exécution MATLAB ou une preuve de compatibilité de `quadprog`.

| Manœuvre | RMSE force [N] | RMSE lacet [rad/s] |
|---|---:|---:|
| G2-BRK | 44,64 | <1e-12 |
| G2-STR | 20,62 | 0,002131 |
| G2-CMB | 28,64 | 0,001778 |
| G2-YAW | 6,27 | 0,001722 |
| G2-SAT | 1400,14 (demande irréalisable) | 0,00000185 |

Le plateau de saturation atteint environ 100% de μmg, puis la force résiduelle repasse sous 100 N. Aucun contournement de limite de variation ni échec solveur n'a été observé. Le pas de 1 ms modifie le lacet de 0,000128 rad/s et la vitesse de 0,000588 m/s. Ces résultats doivent être remplacés ou accompagnés de preuves MATLAB avant la clôture Gate 2. Ils ne valident pas un véhicule physique.

## Suite

La [campagne Gate 3](gate3.fr.md), le brouillon local d'analyse de sécurité et la matière de rapport bilingue sont désormais préparés. Les rapports restent dans `reports/`, ignoré par Git. Exécuter MATLAB et examiner les résultats ; remplacer ou accompagner les figures préliminaires de preuves MATLAB ; faire revoir seuils et hypothèses par l'encadrant. Le [registre des jalons](project_status.fr.md) recense les questions ouvertes d'enveloppe, d'autorité et de couverture des défauts. Les pannes doubles et manœuvres normalisées restent des extensions.
