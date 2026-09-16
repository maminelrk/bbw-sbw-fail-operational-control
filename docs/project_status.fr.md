# Livrables de stage et registre des jalons

## Décision actuelle - périmètre académique achevé SC-2026-01

L'auteur confirme que le garant autorise l'adaptation du CDC au livrable de stage. Le **démonstrateur simulé et les rapports finaux bilingues sont achevés dans ce périmètre académique révisé**. Voir le [périmètre final et la note d'achèvement](final_scope.fr.md) pour les acquis et perspectives. Le dossier privé actuel est `reports/pfa_final_20260916/` ; aucune nouvelle simulation MATLAB ni aucun support de soutenance n'a été produit. Il ne s'agit pas d'une conformité technique universelle ou d'une garantie de sûreté industrielle. Les notes ci-dessous sont historiques : leurs mesures restent valables, mais leurs décisions antérieures de préparation du rapport sont remplacées.

## Décision historique — évaluation locale tâche 2

[TASK2-LOCAL-01](task2_assessment.fr.md) est terminé avec **zéro nouvelle exécution MATLAB**. Les diagnostics temporels/de continuité des 30 cas initiaux ont été recalculés ; 220 témoins à état figé et 216 contrôles de point final sont transférables à 44 états inchangés à canal unique. Aucune enveloppe continue ni garantie de récupération non linéaire indépendante n'est établie. Six transitions saturées échouent toujours sur l'interprétation de vitesse saine REQ-01. La matrice courante et la décision tâche 3 figurent dans cette évaluation ; les anciennes matrices ci-dessous sont historiques.

**La préparation du dossier/rapport tâche 3 peut avancer ; pas la clôture technique sans réserve.** Le démonstrateur simulé fonctionnel préserve la finalité du projet, mais supprimer tous les échecs exige encore une correction transitoire justifiée et une validation ciblée. Aucune nouvelle simulation n'est programmée. L'approbation du garant n'est pas étendue aux nouveaux problèmes. Les anciens rapports/soutenances doivent être révisés avant utilisation.

## Reprise historique — tâche 1

L'auteur du projet confirme l'approbation par le garant des décisions en attente qui lui étaient soumises. Les mentions ci-dessous de décisions du garant encore attendues décrivent la remise historique, non une nouvelle demande d'approbation. Cette confirmation ne dispense pas des critères numériques et n'établit pas l'indépendance physique de sûreté. Encadrants académiques supplémentaires : Pr Said Ben Alla et Pr Issam Amellal.

La commande `ALLOC-2026-04` a terminé la [campagne corrective tâche 1](task1_control.fr.md) : les échecs initiaux de dérive après perte avant et de trajectoire DBBS centrée sont corrigés. Les 45 tests unitaires, cinq manœuvres nominales, diagnostics des 30 cas de défaut initiaux et quatre raffinements réussissent. Six transitions ajoutées en freinage saturé exposent un conflit borne physique/vitesse ; `Task1Passed=false` et Gate 3 reste ouvert. L'archive et 54 séries temporelles ont été auditées localement. La suite privilégie l'analyse locale et la rédaction bilingue, sans nouvelle campagne MATLAB programmée compte tenu de la limite d'utilisation de l'auteur. Les preuves historiques sont conservées. L'ancien dossier privé de rapport final doit être révisé ; ce n'est pas le rapport final du démonstrateur amélioré.

## Référence historique de remise

Mise à jour du 16 septembre 2026. L'état dépend des preuves disponibles, pas des dates initiales du planning. MATLAB Online est disponible. L'exécution Gate 2 corrigée a réussi tous les contrôles numériques le 15 septembre 2026 à 23:33:46 UTC ; l'échec initial de saturation est conservé séparément. Les contrôles Python indépendants ne sont pas présentés comme des résultats MATLAB. Aucune acceptation d'encadrant n'est enregistrée.

| Jalon / livrable | Travail disponible | État / acceptation restante |
|---|---|---|
| G1 / D1 | Rapport initial et addendum de clôture LaTeX FR/EN ; référence numérique ; sémantique des défauts et dépendances D4 précisées | Décisions documentées ; revue encadrant et périmètre capteurs/voies en attente |
| G2 / D2 | Plante non linéaire à 13 états, QP intégré, bancs plante/direction, cinq manœuvres, génération de preuves FR/EN ; première exécution MATLAB conservée | 36 tests unitaires, 3 cas plante, 4 cas direction, 5 manœuvres et convergence réussis ; archives locales vérifiées, 46 figures bilingues prêtes pour le rapport et deux rapports LaTeX de 17 pages disponibles ; revue encadrant en attente |
| G3 / D3 | Référence et compléments MATLAB audités localement ; 41 tests unitaires complémentaires ; raffinement, autorité non linéaire, freinage aligné et 300 points d'enveloppe étudiés | Ouvert : trajectoire DBBS centré, dérive excessive en freinage intense après perte avant, enveloppe continue et modes non couverts |
| G3 / D4 | AMDEC détaillée, coupes qualitatives vérifiées et revue finale des huit dépendances, D4-FINAL-01 | Revue sur dossier terminée ; argumentaire conditionnel, indépendance et acceptation non démontrées |
| G4 / D5 | Rapports techniques finaux bilingues de 21 pages, soutenances éditables de 13 slides, manifeste sources/preuves et guide de remise | Dossier préparé en privé ; relecture étudiants, répétition et acceptation de l'encadrant en attente |
| Extension / D6 | Candidat perte de direction et d'un circuit de frein conservé | Reporté ; répartition du circuit et manœuvre standardisée non choisies/validées |

**Lots de travail achevés**, sans clôture formelle : infrastructure temporelle des défauts, protocole nominal/dégradé, brouillon D4, glossaire bilingue et passage à MATLAB. Une réussite numérique ne devient jamais automatiquement une acceptation de jalon.

## Traçabilité historique exigences/preuves (remplacée par TASK2-LOCAL-01)

Les tâches de préparation 1 et 2 sont achevées sur le plan documentaire : [matrice détaillée exigences/preuves](../reports/final_preparation/requirements_evidence.fr.md) et [registre des écarts](../reports/final_preparation/deviations.fr.md), avec versions anglaises. Ces liens visent des rapports locaux privés ignorés par Git et ne fonctionneront pas dans une copie publique du dépôt. Ils précisent la synthèse ci-dessous sans fermer Gate 3, accepter les échecs ni enregistrer d'approbation de l'encadrant. Aucun rejeu MATLAB nécessaire. Les anciens classeurs XLSX restent historiques. La [revue finale de sûreté](../reports/final_preparation/safety_review.fr.md) termine maintenant la tâche 3 au niveau de l'étude sur dossier. Voir le [guide de remise](handover.fr.md).

| Exigence | Implémentation / preuve prévue | Limite restante |
|---|---|---|
| REQ-01 | Bornes QP ; contrôles pneu/vitesse/charge ; TestGate2Integration, TestGate3Preparation et TestAllocatorSaturation ; campagnes G2/G3 | G2 corrigé et contrôles numériques des 30 cas G3 de référence réussis ; cas supplémentaires à forte sollicitation et validation réelle de couple/charge à traiter séparément |
| REQ-02 masque ≤10 ms | `fault_event_masks`, historiques physiques/connus, chronologie G3 | Diagnostic injecté ; détecteur/ordonnanceur réels absents |
| REQ-02 réponse ≤50 ms + maintien 100 ms | `recovery_band_metric` ; sortie réelle face à l'oracle QP à état figé | Enveloppe non linéaire à 15 % et interprétation de l'oracle à valider ; diagnostic non assimilé à conformité |
| REQ-02 continuité | Écart de lacet apparié sur 200 ms depuis apparition physique | Seuil provisoire ; perception conducteur non validée |
| REQ-03a freinage rectiligne ≥60 % | Témoins non linéaires alignés : minorant conservé minimal 61,264% ; essais d'allocateur sous freinage intense achevés | Les cas avant sortent du domaine de dérive (0,2416 contre 0,15 rad) ; la capacité statique ne clôt pas la conformité transitoire |
| REQ-03b angle/vitesse ≥60 % | Banc crémaillère avec perte A/B et pannes intégrées | Hypothèses fonctionnelles ; absence de validation en charge |
| REQ-03c DBBS | Témoin figé plafonné à 0,35g : au moins 16,690% du majorant nominal conservatif ; échecs centrés confirmés après raffinement | Seuil de trajectoire toujours échoué ; autorité instantanée distincte de conformité transitoire/de manœuvre |
| REQ-04 | AMDEC F01–F18, arbre et DFA D01–D08 | Dépendances matérielles, capteurs, calculateur partagé et revue ouverts |
| REQ-05/06 | Registre explicite du périmètre étendu | Aucune preuve d'acceptation ; aucune revendication de manœuvre ISO |

Les anciens classeurs de traçabilité sont des instantanés historiques. Le présent registre et les catalogues Gate 2/Gate 3 portent l'état actuel jusqu'à leur régénération.

Audit d'enveloppe échantillonnée : 240/300 correspondances figées, 236/300 contrôles finaux réussis. Les 220 points mono-voie correspondent statiquement ; quatre échouent au candidat final de 50 ms. Vingt autres correspondances DBBS ont une demande pratiquement nulle ; 60 points DBBS actifs restent indéterminés. Aucune enveloppe continue à 15% de réserve ni conformité REQ-02 n'est revendiquée. Protocole : [français](gate3_assessment.fr.md) / [anglais](gate3_assessment.en.md). Rapports détaillés bilingues conservés localement dans `reports/gate3_assessment/`.

## Plan d'assemblage du rapport

1. Contexte, objectifs du stage, périmètre CDC et dérogation MATLAB décidée.
2. Bibliographie et architecture corrigée : quatre freins, deux moteurs, une crémaillère, sens de DBBS.
3. Modèle mathématique, provenance des paramètres et hypothèses explicites.
4. Formulation QP, contraintes, demande irréalisable et implémentation numérique.
5. Essais sans allocateur et nominaux : protocole, courbes, mesures, pas de calcul.
6. Injection de pannes : apparition/diagnostic, références appariées, résultats dégradés et limites.
7. AMDEC/arbre/DFA et argument conditionnel de décomposition ASIL.
8. Discussion : portée réelle des simulations, limites, sensibilité et risques restants.
9. Conclusion et perspectives ; extensions en annexe séparée si elles sont réalisées.

Chaque chapitre possède des sources FR/EN. Chaque légende doit préciser moteur d'exécution, révision paramètres/protocole, conditions initiales et caractère préliminaire. Une figure Python indépendante ne doit pas porter une légende MATLAB.

## Suite des travaux MATLAB

1. Revoir le dossier Gate 2 achevé du 15 septembre 2026 à 23:33:46 UTC. Les deux archives téléchargées, les empreintes sources et les données brutes sont vérifiées. Les 46 figures finales bilingues affichent les CSV MATLAB authentiques via Matplotlib, sans nouvelle simulation ; le réexport MATLAB natif est conservé séparément. Deux rapports LaTeX de 17 pages sont prêts localement. L'acceptation de l'encadrant reste en attente.
2. La campagne MATLAB Gate 3 de référence et son audit CSV indépendant local sont terminés. Conserver ses quatre échecs DBBS centré ; suivre [le protocole complémentaire](gate3_assessment.fr.md) pour le raffinement, l'autorité et l'enveloppe échantillonnée.
3. Utiliser la matrice et le registre achevés pour déclarer la validation partielle et le périmètre retenu. La revue de sûreté sur dossier est terminée ; demander les décisions de l'encadrant sur les écarts. Corrections de commande/essais supplémentaires dépendent de cette décision.
4. Rapport final et soutenances bilingues utilisent maintenant les preuves sauvegardées vérifiées. Relire le dossier privé et le soumettre à l'encadrant. Aucun nouvel essai MATLAB nécessaire pour cette étape documentaire.

Documents sources, rapports, preuves générées et PDF restent locaux/ignorés. Leur génération n'autorise aucune publication ni téléversement.
