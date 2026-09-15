# Préparation de la campagne de pannes Gate 3

Protocole **G3-PREP-01**, véhicule **REF-2026-02**. Implémentation et analyse préliminaire, sans clôture du jalon de validation. MATLAB reste la référence d'exécution. Cette campagne ne valide ni algorithme de détection, ni calculateur de série, ni indépendance matérielle.

## Sémantique des défauts

Le modèle distingue la santé physique `h_physical` des informations de santé transmises à la commande `h_known`. La plante perd un canal à l'instant physique `t_p` ; l'allocateur en est informé à `t_flag = t_p + detection_delay`, au premier échantillon suivant cet instant. Les deux historiques sont enregistrés. Les défauts sont permanents, sans rétablissement automatique.

- Perte d'un frein : sa force au contact devient immédiatement nulle ; son état interne décroît. Il s'agit d'une hypothèse de frein relâché après perte de fonction, et non d'un frein bloqué en serrage.
- Perte du canal de direction A/B : le moteur défaillant ne contribue plus à la vitesse de crémaillère. Avant le diagnostic, le moteur sain conserve son ancienne part de commande ; après diagnostic, la répartition est recalculée. L'angle réel et l'état du moteur sain restent continus.
- Perte complète des entraînements de direction : les deux contributions sont nulles et la crémaillère conserve l'angle réel à l'apparition du défaut. Les essais distinguent la position centrée et la perte en virage. Ce modèle ne représente ni une crémaillère libre, ni un blocage arbitraire, ni une panne de capteur.
- Une perte d'alimentation ou de communication n'est équivalente à une perte de canal que **si l'isolation locale produit le même effet physique de perte de fonction sans action intempestive**. Maintien de paquet, temporisation, corruption de bus, perte d'un bus commun et action intempestive ne sont pas couverts par un simple changement d'étiquette de cause.

Le retour d'état complet est idéal. Le délai de détection est une hypothèse injectée, pas une performance de diagnostic estimée. Les points 0, 10 et 50 ms constituent une étude de sensibilité, et non des délais matériels sourcés ou un intervalle de tolérance aux fautes approuvé.

## Catalogue

`validation/gate3_fault_cases.m` construit 30 cas :

| Cas | Manœuvre et défaut | Chronologie |
|---|---|---|
| 18 | Perte de chacun des canaux FL/FR/RL/RR/direction A/direction B en freinage-virage combiné | Apparition à 2 s ; délai 0/10/50 ms |
| 6 | Perte des deux entraînements ; impulsion DBBS positive | Apparition à 1 s (centrée) ou 3 s (en virage) ; délai 0/10/50 ms |
| 4 | Perte de chaque frein pendant un freinage rectiligne progressif | Apparition à 2 s ; diagnostic idéal |
| 2 | Impulsion DBBS négative/symétrique | Apparition à 1 ou 3 s ; délai 10 ms |

Quatre références nominales appariées sont générées : combinée, freinage, DBBS positif et négatif. La vitesse initiale est de 60 km/h. La consigne DBBS passe progressivement de zéro à ±0,15 rad/s entre 1,5 et 2,5 s, reste constante jusqu'à 4,5 s puis revient à zéro à 5,5 s ; l'enregistrement dure 6 s. Aucune propulsion ni régulation compensatrice de vitesse n'est ajoutée : le freinage DBBS réduit donc la vitesse. Cette impulsion est un essai de projet, pas une manœuvre ISO ni une couverture exhaustive de l'enveloppe de lacet.

La perte complète est un cas de secours au niveau de l'effecteur, **pas automatiquement une panne unique de moteur indépendant**. Elle peut provenir d'un chemin commun, d'une condition mécanique ou de deux pannes moteur ; l'architecture doit identifier la cause réelle. Elle est séparée des six classes de panne d'un seul canal.

## Mesures et limites d'interprétation

Les références nominales comportent une seconde supplémentaire de roue libre après les 6 s du défaut. Les véhicules dégradés légèrement plus rapides disposent ainsi d'une référence complète à distance égale, sans extrapolation ; les comparaisons temporelles restent limitées aux 6 s communes.

Précisément, l'écart est exprimé dans le repère d'orientation du véhicule nominal : `e_lat = -(X_f-X_n)*sin(psi_n) + (Y_f-Y_n)*cos(psi_n)` à distance parcourue appariée. En présence de dérive, ce n'est pas exactement la distance géométrique minimale à la trajectoire.

1. **Chronologie des masques :** enregistrer apparition, diagnostic livré et application du masque. L'objectif de 10 ms commence au diagnostic livré. Le temps physique jusqu'à la réponse inclut séparément la détection. Le simulateur applique le drapeau disponible dans le même échantillon de commande ; cela ne valide pas l'ordonnancement d'un calculateur réel.
2. **Diagnostic de rétablissement REQ-02 :** résoudre un oracle à masque réel avec les mêmes état figé, demande et commande précédente. Comparer les forces/moment non linéaires réels à sa prédiction QP affine, normalisée par ses estimations d'autorité. Mesurer la première entrée dans une bande de 10 %, maintenue pendant 100 ms complets ; comparer le retard après diagnostic à 50 ms. Un enregistrement trop court ne peut réussir. Cette mesure inclut le retard des actionneurs et l'écart de modèle ; l'oracle n'est pas un calcul indépendant d'ensemble atteignable non linéaire.
3. **Continuité :** différence maximale de vitesse de lacet nominale/dégradée pendant les 200 ms suivant *l'apparition physique*, comparée au seuil provisoire de 0,05 rad/s. Les conditions initiales et consignes sont identiques.
4. **Manœuvre DBBS :** RMSE de lacet après défaut ≤0,03 rad/s, écart latéral maximal ≤0,50 m et décélération longitudinale réelle maximale ≤0,35g. L'écart est la projection normale sur la trajectoire nominale à distance parcourue cumulée égale, et non à temps égal ; une référence insuffisante est signalée, jamais extrapolée en réussite. La perte de vitesse est séparée. Chaque critère reste évalué même en cas d'échec.
5. **Contrôles numériques/physiques :** états finis, charges brutes positives, cercles d'adhérence, vitesses de commande des actionneurs sains, limites réelles de crémaillère/moteurs, succès des solveurs, bornes, absence de dérogation de vitesse saine, vitesse supérieure au seuil bas et dérive ≤0,15 rad.

**Aucune conformité automatique REQ-02 :** la marge de 15 % de l'enveloppe post-défaut n'est pas encore établie par rapport à un ensemble atteignable non linéaire. `REQ02Status` reste donc `PENDING_ENVELOPE_AND_ORACLE_REVIEW`, même si les diagnostics réussissent. Assimiler la sortie de l'allocateur à la réponse mesurée rendrait le contrôle circulaire ; le code ne fait pas cette assimilation.

**Aucune preuve automatique d'autorité REQ-03 :** une manœuvre de suivi ne mesure pas la décélération rectiligne maximale réalisable ni l'autorité maximale de lacet. `REQ03AuthorityStatus` reste `NOT_ASSESSED`. Le banc REQ-03b conserve une portée fonctionnelle. Une réussite DBBS éventuelle ne couvre que l'impulsion et la position de crémaillère testées, pas la clause distincte de 15 % d'autorité de lacet.

## Passage à MATLAB

```matlab
gate2 = run_gate2_validation();
gate3 = run_gate3_validation();
```

Examiner Gate 2 avant d'interpréter Gate 3. La seconde commande exécute les tests unitaires, quatre références nominales et 30 cas de panne. Son manifeste conserve **toujours** `Gate3Closed=false` et `AllRequirementsPassed=false`. Les échecs comportementaux restent disponibles pour l'analyse ; ils ne sont ni supprimés ni transformés en acceptation du jalon.

Les preuves générées dans `validation/results/gate3/` comprennent `fault_summary.csv`, les séries brutes, `fault_metrics.csv`, `comparison.csv`, les fichiers MAT, les figures de réponse/comparaison FR/EN et un manifeste contenant version MATLAB, produits, paramètres et état Git. Ces sorties restent ignorées par Git.

## Décisions restantes

- Valider les définitions d'enveloppe opérationnelle non linéaire et d'autorité avant toute clôture REQ-02/03.
- Définir une stratégie dégradée bornée de lacet/trajectoire si l'allocateur initial ne satisfait pas les critères DBBS ; conserver son réglage comme référence comparative.
- Définir les pertes de capteur de demande/angle, le maintien et l'action intempestive, ainsi que les domaines réels d'alimentation/communication.
- Examiner avec l'encadrant le brouillon AMDEC/arbre/DFA conservé localement dans `reports/`, ignoré par Git. Les masques ne prouvent pas l'indépendance.
- Reporter les extensions panne double/circuit et manœuvre standardisée jusqu'à consolidation du socle.
