# Implémentation et preuves Gate 2

Modèle courant : `REF-2026-02` ; commande : `ALLOC-2026-03`. L'exécution MATLAB corrigée a réussi tous les contrôles Gate 2 le 15 septembre 2026 à 23:33:46 UTC. État : `READY_FOR_SUPERVISOR_REVIEW`. La première exécution en échec reste conservée.
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

Les colonnes de freinage utilisent désormais la géométrie directe des forces au contact, avec charges mesurées et forces latérales figées pour le QP local. Pour l'angle réel `delta`, la ligne longitudinale vaut `[cos(delta), cos(delta), 1, 1]` ; la ligne de lacet vaut `[lf*sin(delta)-tw*cos(delta)/2, lf*sin(delta)+tw*cos(delta)/2, -tw/2, tw/2]`. Les colonnes des canaux défaillants sont nulles. Il s'agit d'une approximation locale d'efficacité de commande, et non de la dérivée complète du modèle couplé de transfert de charge/adhérence combinée. Le terme constant est recalculé à chaque échantillon pour retrouver exactement les forces généralisées réelles au point d'ancrage. La direction conserve une sécante non linéaire centrée de lacet ; sa colonne longitudinale locale est nulle, comme précisé ci-dessous. Le modèle non linéaire indépendant est inchangé.

Les anciennes différences finies de freinage perturbaient les états d'actionneur à travers l'écrêtage, le transfert de charge et la frontière en racine carrée de capacité latérale. La première exécution MATLAB a révélé des gains longitudinaux de relâchement négatifs et de très forts gains croisés de lacet près de la saturation. La géométrie directe évite d'interpréter ces effets algébriques non lisses comme l'efficacité du frein. `TestAllocatorSaturation` vérifie la géométrie, l'ancrage, les masques de défaut et la saturation/relâchement avec de petites asymétries initiales en miroir. Aucun seuil d'acceptation des manœuvres n'a été assoupli.

À chaque échantillon de 2 ms, les commandes sont maintenues pendant le pas RK4. Les forces et moments mesurés dans la simulation proviennent du modèle non linéaire, **pas** de la prédiction QP ; les deux sont enregistrés. Les bornes de freinage suivent les charges de roue. Une intersection réellement vide avec une limite de variation d'actionneur sain est signalée et provoque le rejet Gate 2. Une borne mobile à l'intérieur de l'intervalle de variation ne recentre pas la commande précédente.

Le modèle conserve les charges brutes pour qu'un délestage soit détecté. Le transfert latéral satisfait `(Fz_droite-Fz_gauche)*voie/2 = m*ay_est*hcg`. Un budget d'adhérence restant nul donne une force latérale nulle. Chaque paire de forces longitudinale/latérale respecte son cercle de friction. Le transfert quasi statique utilise encore des accélérations estimées, dont `ay=vx*r`, sans solution couplée de suspension.

## Catalogue des manœuvres

### Configuration de commande corrigée

`ALLOC-2026-03` attribue uniquement une autorité de lacet à la direction dans le QP local (`B(1,5)=0`). Le terme constant échantillonné conserve les effets longitudinaux réels du braquage ; la plante indépendante reste inchangée. L'objectif longitudinal ne peut ainsi plus utiliser volontairement du braquage et un freinage différentiel opposé pour poursuivre une demande de freinage irréalisable.

Les commandes intégrées conservent une réserve longitudinale provisoire de 2 % (`0.98*mu*Fz`), distincte des bornes physiques (`mu*Fz`). À la limite commandée, cela laisse théoriquement 19,9 % du budget latéral du cercle d'adhérence. Le retard des actionneurs et les charges variables empêchent d'en faire une garantie transitoire. L'analyse d'autorité statique utilise toujours la capacité théorique complète. La sensibilité et le fonctionnement dégradé de cette hypothèse restent à étudier ; le seuil initial d'acceptation de freinage ≥95 % est inchangé.

`allocator_options` conserve `interior-point-convex`, avec une tolérance d'optimalité de `1e-12` et de contrainte de `1e-9`. Une comparaison MATLAB contrôlée, ne faisant varier que la tolérance d'optimalité (`1e-9`, `1e-10`, `1e-12`, `1e-14`), a donné des pics de lacet d'environ `2.3923e-4`, `1.1887e-5`, `4.3859e-7`, `3.6051e-10` rad/s, sans échec du solveur. L'ancienne précision numérique était donc insuffisante pour cette non-régression en boucle fermée. Un essai active-set a été rejeté après des limites d'itérations atteintes. Les définitions suivent la [référence MathWorks de quadprog](https://www.mathworks.com/help/optim/ug/quadprog.html).

`run_allocator_solver_diagnostic()` reproduit cette comparaison et conserve chaque résultat dans `validation/results/solver_diagnostic_v6/` ; il refuse d'écraser un dossier de diagnostic existant. Le quatrième argument facultatif de `run_integrated_maneuver` fournit les options explicites du solveur, sauvegardées avec le résultat. Ce diagnostic ne change aucun seuil de manœuvre.

### Cas nominaux

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

## Première exécution MATLAB et état de la correction

Le 15 septembre 2026 à 19:04:40 UTC, MATLAB Online R2026a Update 5 a exécuté le commit `a775806` avec Optimization Toolbox. Les 31 tests unitaires initiaux, trois scénarios du modèle seul, quatre essais du banc de direction, quatre manœuvres normales et la convergence du pas ont réussi. G2-SAT a échoué : lacet absolu maximal de 0,079208 rad/s, force atteignant 9172,17 N dans la fenêtre de relâchement et vitesse sous le plancher de modèle de 0,5 m/s. Le succès du solveur et les bornes physiques ne démontraient pas un comportement correct en boucle fermée. L'exécution en échec est conservée séparément dans MATLAB Drive et ne peut pas être remplacée par une déclaration d'acceptation. L'exécution corrigée décrite ci-dessous remplace cet échec pour l'état numérique courant ; Gate 3 n'a pas été exécuté.

## Exécution MATLAB corrigée

La campagne corrigée a commencé le **15 septembre 2026 à 23:33:46 UTC** et s'est terminée en **196,2076 s** sous MATLAB Online R2026a Update 5. Les **36 tests unitaires, 3 cas du modèle seul, 4 cas de direction, 5 manœuvres et la convergence temporelle ont réussi**. État : `READY_FOR_SUPERVISOR_REVIEW`.

| Cas | RMSE force [N] | RMSE lacet [rad/s] | Résultat |
|---|---:|---:|---|
| G2-BRK | 44,6455 | 3,90575e-9 | Réussi |
| G2-STR | 20,6210 | 0,00213073 | Réussi |
| G2-CMB | 28,5375 | 0,00178501 | Réussi |
| G2-YAW | 6,27437 | 0,00172186 | Réussi |
| G2-SAT | 1541,32 (demande irréalisable) | 5,03305e-8 | Capacité/récupération réussies |

G2-SAT a fourni **98,0 % de μmg**, avec un pic de lacet de **4,38590e-7 rad/s**, une force maximale de relâchement de **0,00457908 N** et une vitesse minimale/finale de **2,75553 m/s**. Tous les contrôles physiques/opérationnels ont réussi, sans dérogation de variation. Les écarts temporels valent **0,000128328 rad/s** en lacet et **0,000587633 m/s** en vitesse, sous les limites inchangées de 0,001 rad/s et 0,03 m/s.

Les sources testées sont le commit `a775806` complété par sept fichiers corrigés non commités, identifiés dans `saturation_fix_source_manifest.json` ; chaque SHA-256 a été vérifié dans MATLAB avant exécution. Le manifeste du calcul enregistre ces modifications. L'archive corrigée dans MATLAB Drive est `gate2_corrected_20260915_233346.zip`, séparée de l'échec initial. Aucun téléchargement local vérifié n'est encore enregistré. Rapports et preuves générées restent exclus de GitHub. La courbe inspectée a révélé un style sombre des axes/textes ; une réexportation en thème clair reste une tâche de présentation. Acceptation de l'encadrant, sensibilité de la réserve et Gate 3 restent ouverts.

## Contrôles indépendants historiques (hors MATLAB)

Avant l'accès à MATLAB, les fichiers ont été analysés par MISS_HIT. Une implémentation distincte des équations avec moindres carrés bornés SciPy a réussi les cinq manœuvres avec les mêmes réglages, seuils et période. Ces valeurs historiques n'ont pas prédit l'échec de saturation dans MATLAB et ne doivent pas servir de preuve d'acceptation MATLAB.

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
