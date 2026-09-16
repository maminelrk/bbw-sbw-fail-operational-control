# Exécution MATLAB Gate 3

Archivage UTC : 2026-09-16 01:26:32. Base du code : 93db2a5c9e8cc522e93985af2bde151cfdfebf4d, complétée par les trois fichiers de source_delta.

37 tests unitaires, 4 références nominales, 30 cas de panne. Échecs des contrôles numériques : 0. Échecs de la manœuvre DBBS : 4/8.

Preuves préliminaires de simulation : ni clôture Gate 3 ni certification de sécurité. La revue enveloppe/oracle REQ-02, les autorités REQ-03 et l'indépendance architecturale restent ouvertes.

La première tentative a été arrêtée par une égalité exacte rejetant un écart temporel maximal de 8,881784197001252e-16 s entre les échantillons communs des enregistrements de 6 s et 7 s. Elle est conservée séparément dans validation/results/gate3_attempt1_timegrid. L'exécution corrigée a été entièrement relancée. Seuls le traitement de l'arrondi de comparaison et son test de régression ont changé ; commande, véhicule, échantillonnage et seuils sont inchangés.

Les figures sont natives MATLAB avec un DefaultFigureCreateFcn temporaire imposant Theme=light. Le rappel précédent a été rétabli après exécution. Les exports français/anglais accompagnent les données CSV/MAT brutes.

Reproduction : utiliser le commit de base 93db2a5c9e8cc522e93985af2bde151cfdfebf4d, appliquer source_delta/validation et source_delta/tests, puis exécuter run_gate3_validation sous MATLAB avec Optimization Toolbox. Les preuves générées sont exclues de GitHub.
