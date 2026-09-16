# Guide de remise et de reproduction du stage

**Guide historique ci-dessous.** Le livrable académique actuel achevé est défini par [SC-2026-01](final_scope.fr.md), après confirmation par l'auteur que le garant autorise l'adaptation du CDC. Utiliser les rapports français/anglais et les sources testées figées du dossier privé `reports/pfa_final_20260916/`. Les anciens rapports, soutenances et classeurs sont historiques. Le dossier final ne contient aucun nouveau diaporama ni texte de soutenance ; les traces numériques originales sont inchangées.

[English](handover.en.md). Révision HANDOVER-01, 16 septembre 2026.

## État

L'étude de simulation et le lot de rédaction sont préparés pour revue de l'encadrant. Les contrôles numériques Gate 2 ont réussi. Gate 3 reste partiellement validé, avec conservation des échecs de trajectoire DBBS centrée et du domaine en freinage intense après perte avant. L'argumentaire de sûreté est conditionnel. Aucune acceptation d'encadrant ni conformité complète au CDC n'est affirmée. Voir [l'état actuel](project_status.fr.md).

MATLAB n'est **pas nécessaire pour lire, relire ou soumettre les preuves et le rapport sauvegardés**. MATLAB avec Optimization Toolbox (`quadprog` et `fmincon`) est nécessaire pour rejouer ou modifier les simulations de référence. L'environnement enregistré est MATLAB Online R2026a Update 5. Ne pas prétendre que toutes les anciennes versions ont été testées ; les figures complémentaires utilisent la propriété de thème de la version enregistrée. Simulink ne sert qu'au prototype historique `.slx`, pas aux campagnes scriptées de référence.

## Livrables privés

Le dossier local `reports/final_report/` contient le rapport technique final FR/EN en PDF/LaTeX, les soutenances éditables FR/EN et son README bilingue. `reports/final_preparation/` contient la matrice d'exigences actuelle, les écarts et la revue finale de sûreté. Ces dossiers sont volontairement absents d'une copie publique. Le manifeste privé identifie sources et preuves locales par SHA-256. Les manifestes historiques d'exécution priment sur l'instantané de remise ultérieur pour identifier ce qui a réellement été exécuté.

Rapports, CDC/workflow, preuves générées et manifestes privés restent hors Git public. Les préparer n'autorise pas leur publication. Une archive privée sert seulement au transfert local à l'encadrant, sous réserve du choix de destinataire par l'utilisateur.

## Reproduction MATLAB facultative

**Utiliser une nouvelle copie du projet dans un nouveau dossier.** Les entrées Gate 2/Gate 3 écrivent dans des dossiers relatifs fixes et peuvent écraser les anciens résultats. Ne pas les exécuter sur les preuves auditées. Le nombre de tests peut augmenter avec la révision ; conserver le nouveau manifeste sans réécrire les nombres historiques.

Depuis la nouvelle racine du projet :

```matlab
addpath(pwd, fullfile(pwd,'validation'));
gate2 = run_gate2_validation();
gate3 = run_gate3_validation();
baseline = fullfile(pwd,'validation','results','gate3');
run_gate3_convergence(baseline, ...
    fullfile(pwd,'validation','results','convergence'));
run_gate3_supplementary(baseline, ...
    fullfile(pwd,'validation','results','supplementary'));
run_gate3_straight_path_check( ...
    fullfile(pwd,'validation','results','straight_path'));
```

Le dossier de convergence est volontairement voisin de `supplementary` ; le lanceur complémentaire copie ces preuves de raffinement existantes. Les trois dossiers de destination des évaluations ne doivent pas déjà exister. Le résultat attendu inclut des échecs, pas un Gate 3 entièrement vert. Comparer aux preuves sauvegardées et conserver les différences de sources/versions.

Plante seule : `run_plant_validation()`. Tests unitaires : `runtests('tests','IncludeSubfolders',true)`. Conserver les contrôles échoués et erreurs solveur. Ne pas modifier les seuils pour obtenir une réussite.

## Reconstruction du rapport

Le maître privé est `reports/final_report/report.tex`, avec wrappers `final_report.en.tex` et `final_report.fr.tex`. Compiler depuis leur dossier avec Tectonic ou une installation LaTeX compatible. Le maître réutilise les logos Gate 1 privés et les figures Gate 2/Gate 3 vérifiées par chemins relatifs ; préserver l'arborescence. L'archive privée de transfert inclut ces dépendances.

Les entrées techniques restent `allocator.m`, `vehicle_derivatives_block.m`, `vehicle_dynamics_quantities.m`, `steering_actuator_dynamics.m`, `get_params.m` et les lanceurs de validation. Aucun modèle/contrôleur n'a changé pendant la finalisation documentaire.

## Vérifications humaines avant remise

1. Les étudiants relisent rapport et slides, vérifient identités et forme institutionnelle, et confirment leur capacité à expliquer l'implémentation et ses limites.
2. L'encadrant décide sur la référence numérique, l'écart MATLAB, le périmètre de panne et l'acceptabilité des échecs comme résultats d'étude.
3. Répéter la soutenance de 13 slides et relire ses notes orateur.
4. Conserver le dossier privé figé et les archives originales. Le MAT/journal complet du témoin final de trajectoire droite reste dans MATLAB Drive ; le CSV exact haché et l'audit indépendant sont locaux. Télécharger le MAT/journal restant pour compléter l'archivage à long terme quand possible ; aucune nouvelle simulation nécessaire.

Une nouvelle itération technique et campagne MATLAB ne s'imposent que si l'encadrant demande une meilleure performance ou un périmètre élargi. Accepter une limite ne transforme jamais un résultat historique FAIL en PASS.
