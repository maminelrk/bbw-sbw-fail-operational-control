# Périmètre académique final et achèvement

[English](final_scope.en.md). SC-2026-01, 16 septembre 2026.

## Décision et autorité

L'auteur confirme que le garant autorise l'adaptation des exigences du CDC au livrable académique de stage. Le périmètre final est donc un **démonstrateur simulé achevé et reproductible**, non un produit automobile garanti en toutes conditions ni une revendication de certification. Cette note consigne la confirmation de l'auteur, sans inventer de procès-verbal signé, de signature ou d'acceptation industrielle formelle.

Cette décision remplace les positions antérieures conditionnant la finalisation du rapport à la clôture de chaque critère initial du CDC. Les seuils numériques restent inchangés comme références d'ingénierie. Les résultats et indicateurs historiques ne sont pas réécrits.

## Livrables achevés

- Architecture à quatre freins, une crémaillère/deux entraînements et masques explicites de disponibilité.
- Modèle véhicule non linéaire à 13 états, provenance des paramètres et vérifications de la plante.
- Allocation QP bornée au mieux réalisable, contraintes d'actionneurs et réglages DBBS/perte avant corrigés.
- Preuves MATLAB conservées : 45 tests unitaires, cinq manœuvres nominales, diagnostics de 30 cas initiaux de défaut et quatre raffinements ciblés.
- Les huit impulsions DBBS étudiées respectent les critères retenus de trajectoire, erreur de lacet et décélération. Les manœuvres d'autorité avec perte avant conservent au moins 61,1 % de la référence supérieure de freinage nominal, avec une dérive maximale d'environ 0,0605 rad.
- Audit local, comparaison des commandes, études d'autorité, analyse qualitative conditionnelle de sûreté et dossier de reproductibilité.
- Rapports finaux LaTeX français et anglais : remerciements, entreprise, méthodes, résultats, périmètre et perspectives. Aucun nouveau support de soutenance n'appartient à ce livrable.

## Limite explicite du périmètre et perspectives

L'achèvement porte sur le modèle de référence documenté et les manœuvres étudiées. Il n'établit pas une enveloppe sûre continue. Les développements futurs couvrent la perte brusque d'actionneur pendant un freinage entièrement saturé, la coordination force/vitesse en transition, la récupération non linéaire indépendante, les variations de paramètres/route/bruit, la direction en charge, les capteurs et le diagnostic, les défaillances dépendantes et la validation véhicule.

Les mesures de transitions saturées sont conservées et quantifiées au chapitre des perspectives. Leur placement hors des critères d'acceptation académique finaux ne modifie pas les résultats observés et n'étend pas le domaine démontré.

## Remise

La tâche 3 est achevée comme consolidation locale des preuves et gel des sources. La tâche 4 comprend uniquement deux éditions du rapport final. Sources, PDF et manifeste SHA-256 figurent dans le dossier privé `reports/pfa_final_20260916/` ; les copies finales sont dans `output/pdf/`. Ces chemins sont volontairement absents du dépôt public. Les anciens dossiers de rapport/soutenance sont historiques et ne constituent pas la remise finale actuelle.

Aucune nouvelle simulation MATLAB n'a été utilisée pour cette finalisation. L'[évaluation tâche 2](task2_assessment.fr.md) reste l'audit numérique détaillé, à lire avec ce périmètre révisé. Encadrants académiques : Pr Said Ben Alla et Pr Issam Amellal. Garant : Elmehdi Chokri.
