# Tâche 2 — évaluation locale et décision pour la tâche 3

Mise à jour du périmètre final : [SC-2026-01](final_scope.fr.md) définit désormais l'achèvement académique après confirmation de l'accord du garant par l'auteur. Cet audit reste une trace numérique conservée ; sa décision antérieure de préparation conditionnelle du rapport est historique. Les conditions élargies sont des perspectives, non de nouvelles capacités démontrées.

[English](task2_assessment.en.md). Révision **TASK2-LOCAL-01**, 16 septembre 2026.

**Évaluation locale terminée ; validation technique encore partielle. Passage à la préparation du dossier tâche 3, sans clôture technique inconditionnelle.** Aucune session MATLAB Online, nouvelle simulation véhicule, modification de commande ou modification de seuil n'a été utilisée.

## 1. Objet et preuves

La finalité reste une allocation BbW/SbW intégrée, adaptée aux défauts, conservant du freinage et de la direction/du lacet, démontrée sur une simulation véhicule non linéaire. Elle n'a pas été réduite à la détection de panne ou à l'arrêt du véhicule. Préserver cette finalité ne signifie toutefois pas que chaque exigence est satisfaite.

L'auteur confirme l'approbation du garant concernant les questions précédemment soumises. Cette confirmation est conservée, sans extension au nouveau conflit transitoire en saturation ni dispense des critères numériques. Encadrants académiques supplémentaires : Pr Said Ben Alla et Pr Issam Amellal. Aucune signature ni date d'acceptation formelle n'est inventée.

Entrées : références Gate 2/Gate 3 conservées ; témoins audités d'autorité/enveloppe non linéaires ; candidat tâche 1 `ALLOC-2026-04`, véhicule `REF-2026-02` ; ses 54 séries temporelles auditées. Résultats actuels : dossier privé `validation/results/task2_local_20260916_v2/`. Le dossier `task2_local_20260916/` conserve l'audit préliminaire, non la sortie courante. `audit.json` contient les empreintes de chaque entrée lue et du script. Sources et paramètres physiques sont comparés avant réemploi des anciennes preuves. Aucun contenu brut du rapport/CDC n'est publié.

## 2. Recalcul indépendant des temps — sans nouvel oracle non linéaire

L'implémentation locale recalcule apparition physique, diagnostic livré, concordance des masques, isolement des freins défaillants, entrée dans la bande de 10 % avec maintien complet de 100 ms et différence de lacet nominal/défaillant pendant les 200 premières ms. Huit tests Python couvrent bornes temporelles, maintien interrompu, données insuffisantes, échantillons manquants, erreurs non finies et grilles invalides.

- Les **30** cas de défaut initiaux réussissent les diagnostics sauvegardés de masque, récupération affine et continuité ; **22** concernent un canal unique, **8** le secours après perte complète des entraînements de direction.
- Le masque est appliqué **0 ms** après diagnostic dans cette implémentation échantillonnée. Le retard de détection injecté reste séparé ; l'ordonnancement ECU n'est pas mesuré.
- Les 30 cas sont **déjà dans la bande de l'oracle affine à l'échantillon du diagnostic** et y restent 100 ms. Leur **délai d'entrée de 0 ms n'est pas un temps d'établissement physique mesuré**.
- La différence maximale de lacet sur 200 ms vaut **0,013688 rad/s**, sous 0,05 rad/s.
- La sortie évaluée provient de la plante non linéaire, mais cible et normalisation restent celles de l'oracle affine archivé. Un recalcul indépendant ne produit pas une trajectoire optimale réalisable non linéaire indépendante. La récupération 90 %/50 ms et REQ-02 complète restent donc **non établies** au-delà du diagnostic indiqué.

Preuves par cas : `recovery.csv`. Aucun maintien incomplet ou manquant n'est transformé en réussite.

## 3. Enveloppe opérationnelle et transfert des preuves

L'étude initiale comprenait **300 sondes sur 60 états échantillonnés**, avec 240 témoins faisables à état figé et 236 contrôles de point final à 50 ms réussis. Les 60 autres recherches n'ont trouvé aucun témoin ; cela ne prouve pas l'infaisabilité.

L'audit compare les 13 composantes d'état, la demande, le masque physique et la commande précédente aux instants initiaux. Seules des différences de l'ordre de l'arrondi sont admises pour le réemploi ; une manœuvre approximativement similaire ne suffit pas.

| Preuve | Transfert à la commande corrigée |
|---|---|
| 44 états échantillonnés des 22 cas à canal unique | Entrées identiques ; 220 témoins à état figé réutilisables |
| Contrôles correspondants à 50 ms en boucle ouverte | 216/220 réussissent ; quatre trajectoires candidates restent en échec |
| 16 états DBBS échantillonnés | Entrées différentes ; aucun transfert automatique des 80 résultats antérieurs |
| Réserve continue de 15 % le long d'une trajectoire | Non établie par les campagnes |
| Maintien 100 ms face à une référence optimale réalisable non linéaire indépendante | Non établi par les contrôles de point final à 50 ms |

Les quatre constructions transférées en échec concernent une sonde pour chacun des cas `G3-FR-D50` échantillon 1, `G3-RL-D50` échantillon 1, `G3-BRK-RL` échantillon 2 et `G3-BRK-RR` échantillon 2. Ce ne sont pas quatre échecs démontrés de récupération en boucle fermée : chaque construction est une rampe vers un témoin faisable, non un calcul de l'ensemble atteignable optimal. Réciproquement, des coins faisables ne prouvent pas la faisabilité de tout l'intérieur d'une image non linéaire. Un axe à demande nulle a une largeur de boîte nulle et n'apporte aucune couverture de réserve dans cette direction.

Le domaine justifié correspond aux **manœuvres testées énumérées**, non à une enveloppe rectangulaire certifiée : vitesse initiale 60 km/h, adhérence 0,90, véhicule fixe, retour d'état idéal, pertes silencieuses de canaux et retards de diagnostic injectés. L'évolution des états d'une simulation ne constitue pas un balayage de conditions indépendamment choisies.

Preuves par échantillon : `envelope_transfer.csv`. Les témoins physiques historiques restent utiles car la plante est inchangée, sans prouver que la commande corrigée atteint chacun d'eux.

## 4. Comparaison et robustesse disponible

| Métrique | Commande initiale | Commande corrigée | Interprétation |
|---|---:|---:|---|
| Pire écart DBBS centré | 0,508632 m | 0,294527 m | Échec initial corrigé ; limite 0,50 m |
| Pire RMSE de lacet DBBS | 0,017640 rad/s | 0,011461 rad/s | Sous 0,03 rad/s |
| Pire décélération maximale DBBS | 0,257737 g | 0,277080 g | Meilleur suivi au prix de plus de freinage ; sous 0,35 g |
| Dérive maximale après perte avant | 0,241615 rad | 0,060513 rad | Sortie de domaine corrigée ; limite 0,15 rad |
| Freinage conservé après perte avant | 63,6789 % | 61,1147 % | Gain de stabilité au prix de 2,5642 points ; marge de seulement 1,1147 point sur 60 % |
| Métriques des cinq manœuvres nominales | Référence | Identiques à la tolérance d'audit | Pas de régression détectée sur les métriques sauvegardées sélectionnées |

Les huit évaluations DBBS corrigées réussissent. La comparaison avant/après porte sur **deux révisions de commande d'une même architecture**, non sur un contrôleur indépendant à pseudo-inverse ou à règles. Aucun résultat de ce dernier type n'existe ; aucun n'est inventé ni requis uniquement pour renommer l'étude en démonstrateur.

Les deux raffinements DBBS centrés à 1 ms réussissent le contrôle préexistant : variation maximale du pic de trajectoire **0,731 mm**, du lacet **0,000157 rad/s**, de la vitesse **0,002193 m/s**. Les pertes avant raffinées conservent leur réussite ; écarts maximaux échantillonnés lacet/vitesse **0,000589 rad/s / 0,002861 m/s**. Cela étaye la cohérence numérique, non la robustesse aux paramètres inconnus.

Sensibilités disponibles : diagnostic 0/10/50 ms, deux directions DBBS (direction négative à 10 ms seulement), perte de crémaillère centrée/en virage, cas de freins symétriques et raffinement ciblé. **Aucun balayage de robustesse démontré** sur adhérence, masse, CG, rigidité pneu, retard d'actionneur, bruit capteur, biais d'estimation ou autres vitesses initiales. La faible marge de freinage rend cette limite importante. Le balayage de réglage à six valeurs n'est pas une étude indépendante de robustesse.

Preuves : `comparison.csv`, `braking_comparison.csv`, `nominal_regression.csv`, `refinement.csv`.

## 5. Transitions saturées — décision sans changement de critères

Les six transitions ajoutées échouent toujours sur la vitesse de commande saine/l'absence de dérogation. À l'apparition du défaut, la commande avant saine vaut environ -5614,37 N, la nouvelle borne physique basse -5123,93 N et le relâchement autorisé seulement 80 N par pas. Au moins **490,44 N** sont nécessaires : les intervalles instantanés sont disjoints. Cela démontre l'infaisabilité **dans cet état enregistré**, non l'impossibilité de toute autre conception anticipative.

L'essai demande **120 % de la borne globale de freinage nominale** à l'apparition du défaut. Sa force demandée dépasse donc même la borne physique nominale et ne peut conserver 15 % de réserve après défaut. La clause de continuité applicable dans l'enveloppe ne peut être considérée applicable du seul fait de cet essai. Toutefois, **l'infaisabilité de la demande ne dispense pas de REQ-01 sur les limites des actionneurs sains**. La dérogation reste une non-conformité technique sous l'interprétation actuelle commande-force de contact. Le repli donne priorité aux bornes physiques ; ce n'est pas une solution respectant la vitesse de l'actionneur.

Résultats descriptifs supplémentaires :

| Retard de diagnostic | Écart maximal de lacet nominal/défaillant sur 200 ms | Premier maintien complet de 100 ms avec freinage >=60 % et limite de lacet, après diagnostic |
|---|---:|---:|
| 0 ms | 0,050622 rad/s | 148 ms |
| 10 ms | 0,060137 rad/s | 182 ms |
| 50 ms | 0,105002 rad/s | Aucun maintien complet admissible avant 1,9 s |

Ces valeurs sont symétriques FL/FR et **ne remplacent pas la définition de récupération REQ-02 fondée sur l'oracle**. Toutes dépassent numériquement le proxy de 0,05 rad/s, hors de son applicabilité démontrée. La dernière ligne signifie des preuves de plateau insuffisantes, non « ne récupère jamais ». Aucune ne permet de revendiquer une transition universellement sans à-coup. Tous les cas restent dans le domaine de dérive de 0,15 rad.

Deux voies défendables, non implémentées ici :

1. Séparer demande/état d'actionneur limités en vitesse et saturation instantanée des forces pneu-sol ; justifier toute dynamique de transfert de charge nécessaire. Valider modèle et allocateur révisés par une non-régression ciblée, sans simplement exempter l'échantillon gênant.
2. Définir un périmètre opérationnel explicitement accepté et une politique transitoire hors enveloppe, en conservant l'essai en échec. L'exclusion seule ne montre pas que le système impose ce périmètre, ni que l'exigence initiale de vitesse en permanence est satisfaite.

La première voie correspond le mieux à l'objectif d'éliminer les échecs. La seconde permet un livrable académique explicitement limité, sous réserve d'une décision d'acceptation. Les approbations antérieures ne sont pas présentées comme une approbation de ces nouvelles voies.

## 6. Matrice actuelle exigences–preuves

Cette révision remplace les anciennes synthèses de verdict et les classeurs historiques antérieurs à la correction pour l'état actuel ; les preuves initiales restent immuables.

| Clause / affirmation | Preuve et verdict |
|---|---|
| REQ-01, nominal et défauts initiaux | Contrôles testés réussis : cinq cas nominaux et diagnostics des 30 cas de défaut initiaux |
| REQ-01, transitions saturées ajoutées | **ÉCHEC** : six conflits de vitesse saine ; conformité universelle/permanente non atteinte |
| REQ-02 activation du masque <=10 ms | **RÉUSSITE TESTÉE** sur les cas initiaux ; sans validation du diagnostic ni de la latence ECU |
| REQ-02 récupération physique indépendante <=50 ms +100 ms de maintien | **PARTIEL / NON ÉTABLI** : diagnostic affine réussi, référence non linéaire indépendante absente |
| REQ-02 continuité et applicabilité réserve 15 % | **PARTIEL** : lacet initial réussi, 44 états identiques, sans enveloppe continue |
| REQ-03a freinage >=60 % avec condition de lacet | **RÉUSSITE TESTÉE / exigence mère PARTIELLE** : plateau dynamique avant minimal 61,1147 % ; témoin statique à force alignée >=61,2636 % ; sans garantie transitoire pour tout état |
| REQ-03b canal de direction unique | **RÉUSSITE DU MODÈLE FONCTIONNEL** : plage complète et 60 % de vitesse au banc ; couple sous charge et indépendance d'alimentation restent supposés |
| REQ-03c impulsion DBBS testée | **RÉUSSITE TESTÉE** : 8/8 ; les deux directions centrées conservent leur réussite à 1 ms |
| REQ-03c autorité de lacet >=15 % | **TÉMOIN À CONDITION FIGÉE** : borne inférieure conservatrice 16,6900 % avec plafond 0,35 g ; sans autorité atteignable universelle |
| REQ-04 argumentaire d'architecture | AMDEC/FTA/DFA sur dossier réutilisable après mise à jour ; indépendance physique et certification ASIL non établies |
| Robustesse paramétrique élargie / comparaison avec commande simple | **NON DÉMONTRÉ** ; distinguer enrichissement utile et résultats vérifiés disponibles |
| Extension double défaut / manœuvre standardisée | **EXTENSIONS DIFFÉRÉES**, non renommées en essais cœur achevés |

Les ratios statiques utilisent des **bornes supérieures nominales**, rendant les fractions conservatrices aux conditions étudiées. L'ancien pourcentage de freinage brut sans contrainte n'est pas utilisé comme preuve de freinage rectiligne.

## 7. Décision pour la tâche 3

**GO pour dossier reproductible et préparation du rapport ; NO-GO pour déclarer sans réserve un « système fail-opérationnel terminé et entièrement conforme ».** Le projet possède une commande simulée fonctionnelle et une tolérance aux défauts démontrée dans plusieurs cas, pas seulement une étude sur papier. Sa finalité est préservée. La conformité complète ne découle pas encore des preuves.

La tâche 3 peut figer code et preuves exacts, proposer une lecture locale des figures sauvegardées, harmoniser documentation et analyse de sûreté bilingues, distinguer clauses réussies/échouées/non vérifiées et préparer la remise. Elle doit conserver `Task1Passed=false`, Gate 3 ouvert et le conflit transitoire visible. Une lecture de résultats doit être présentée comme une relecture, non comme une simulation en direct. Les anciens rapports/soutenances ne doivent pas être remis sans révision.

Pour une **fin académique avec limites déclarées**, préparation locale et rédaction peuvent avancer aujourd'hui sans MATLAB. Pour l'objectif plus fort de **supprimer tous les échecs identifiés**, une correction technique et sa validation ciblée restent nécessaires. Aucun changement de formulation ne satisfait cet objectif. Si une exécution future devient indispensable, proposer d'abord la modification exacte et les plus petits cas discriminants ; cette note n'autorise ni ne programme une grande campagne.

## 8. Reproduire l'évaluation locale

Bibliothèque standard Python 3.10+, testée avec Python 3.12 local. Aucune licence MATLAB, connexion réseau ni bibliothèque scientifique requise :

```text
python validation/test_audit_task2.py
python validation/audit_task2.py validation/results/task2_local_new
```

Les dossiers privés de preuves de la section 1 doivent être présents. Un dossier de destination existant est refusé. Le script lit CSV/JSON/sources sauvegardés et écrit uniquement de nouveaux produits d'audit ; il ne simule pas la plante, ne change aucun seuil, n'appelle pas MATLAB et ne modifie pas les preuves historiques. Son JSON distingue travail local terminé et conformité aux exigences.
