# Livrables de stage et registre des jalons

Mise à jour du 16 septembre 2026. L'état dépend des preuves disponibles, pas des dates initiales du planning. MATLAB Online est disponible. L'exécution Gate 2 corrigée a réussi tous les contrôles numériques le 15 septembre 2026 à 23:33:46 UTC ; l'échec initial de saturation est conservé séparément. Les contrôles Python indépendants ne sont pas présentés comme des résultats MATLAB. Aucune acceptation d'encadrant n'est enregistrée.

| Jalon / livrable | Travail disponible | État / acceptation restante |
|---|---|---|
| G1 / D1 | Rapport initial et addendum de clôture LaTeX FR/EN ; référence numérique ; sémantique des défauts et dépendances D4 précisées | Décisions documentées ; revue encadrant et périmètre capteurs/voies en attente |
| G2 / D2 | Plante non linéaire à 13 états, QP intégré, bancs plante/direction, cinq manœuvres, génération de preuves FR/EN ; première exécution MATLAB conservée | 36 tests unitaires, 3 cas plante, 4 cas direction, 5 manœuvres et convergence réussis ; revue encadrant et mise en forme des figures en attente |
| G3 / D3 | Campagne de 30 pannes retardées, quatre références nominales, comparaisons et figures FR/EN ; contrôle numérique indépendant | Préliminaire ; MATLAB, enveloppe/autorité et modes non couverts restent ouverts |
| G3 / D4 | Registre AMDEC, logique d'arbre de défaillances et huit dépendances DFA | Brouillon prêt pour revue ; indépendance et cartographie matérielle non démontrées |
| G4 / D5 | Matière de rapport bilingue, plan de preuves et consignes de reproduction | Résultats finaux, discussion et soutenance à terminer |
| Extension / D6 | Candidat perte de direction et d'un circuit de frein conservé | Reporté ; répartition du circuit et manœuvre standardisée non choisies/validées |

**Lots de travail achevés**, sans clôture formelle : infrastructure temporelle des défauts, protocole nominal/dégradé, brouillon D4, glossaire bilingue et passage à MATLAB. Une réussite numérique ne devient jamais automatiquement une acceptation de jalon.

## Traçabilité actuelle exigences/preuves

| Exigence | Implémentation / preuve prévue | Limite restante |
|---|---|---|
| REQ-01 | Bornes QP ; contrôles pneu/vitesse/charge ; TestGate2Integration, TestGate3Preparation et TestAllocatorSaturation ; campagnes G2/G3 | Bornes et saturation réussies dans le G2 MATLAB corrigé ; G3 et validation de couple/charge réelle restent ouverts |
| REQ-02 masque ≤10 ms | `fault_event_masks`, historiques physiques/connus, chronologie G3 | Diagnostic injecté ; détecteur/ordonnanceur réels absents |
| REQ-02 réponse ≤50 ms + maintien 100 ms | `recovery_band_metric` ; sortie réelle face à l'oracle QP à état figé | Enveloppe non linéaire à 15 % et interprétation de l'oracle à valider ; diagnostic non assimilé à conformité |
| REQ-02 continuité | Écart de lacet apparié sur 200 ms depuis apparition physique | Seuil provisoire ; perception conducteur non validée |
| REQ-03a freinage rectiligne ≥60 % | Pannes en freinage ; `straight_braking_screening` distingue force brute et freinage à lacet nul | Autorité maximale avec compensation active de direction non établie |
| REQ-03b angle/vitesse ≥60 % | Banc crémaillère avec perte A/B et pannes intégrées | Hypothèses fonctionnelles ; absence de validation en charge |
| REQ-03c DBBS | Impulsions ±0,15 rad/s, pertes centrée/en virage ; lacet/trajectoire/décélération | Manœuvres testées uniquement ; 15 % d'autorité maximale et robustesse non établis |
| REQ-04 | AMDEC F01–F18, arbre et DFA D01–D08 | Dépendances matérielles, capteurs, calculateur partagé et revue ouverts |
| REQ-05/06 | Registre explicite du périmètre étendu | Aucune preuve d'acceptation ; aucune revendication de manœuvre ISO |

Les anciens classeurs de traçabilité sont des instantanés historiques. Le présent registre et les catalogues Gate 2/Gate 3 portent l'état actuel jusqu'à leur régénération.

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

1. Revoir les preuves Gate 2 corrigées du 15 septembre 2026 à 23:33:46 UTC. Les conserver séparément de l'échec initial. Réexporter les figures du rapport avec un thème clair homogène : le thème sombre MATLAB a affecté les axes/textes. Les contrôles numériques ont réussi ; l'acceptation de l'encadrant reste en attente.
2. Exécuter `run_gate3_validation()`. Comparer les résultats aux contrôles préliminaires et examiner les écarts, sans présumer l'équivalence des solveurs.
3. Résoudre enveloppe/autorité non linéaires, sémantique capteurs/voies et revue de sécurité. MATLAB seul ne clôt pas ces questions d'ingénierie.
4. Remplacer ou accompagner les figures préliminaires de preuves MATLAB vérifiées, soumettre D2–D4 à la revue, puis assembler rapport final et soutenance.

Documents sources, rapports, preuves générées et PDF restent locaux/ignorés. Leur génération n'autorise aucune publication ni téléversement.
