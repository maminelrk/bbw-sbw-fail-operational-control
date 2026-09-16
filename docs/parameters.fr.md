# Paramètres de référence du véhicule et du modèle

Jeu de paramètres : `REF-2026-02` (données véhicule inchangées ; architecture de direction et réglages d'intégration révisés).

Il s'agit d'un véhicule de référence construit à partir de la littérature pour le développement de la simulation. Ces valeurs ne résultent pas de l'identification d'un véhicule cible physique. Chaque entrée est classée comme **sourcée**, **calculée**, **dérivée d'une exigence** ou **supposée**. Les valeurs de substitution et les hypothèses devront être remplacées ou calibrées lorsque les données du véhicule cible seront disponibles.

## Véhicule et environnement

| Symbole / champ | Valeur | Unité | Classification | Justification |
|---|---:|---|---|---|
| `m` | 1590 | kg | Sourcée | Véhicule de simulation 4WID-EV de référence, tableau 1 [S1] |
| `Iz` | 2059,2 | kg·m² | Sourcée | Véhicule de simulation 4WID-EV de référence, tableau 1 [S1] |
| `lf` | 1,05 | m | Sourcée | Distance du centre de gravité à l'essieu avant, tableau 1 [S1] |
| `lr` | 1,61 | m | Sourcée | Distance du centre de gravité à l'essieu arrière, tableau 1 [S1] |
| `L` | 2,66 | m | Calculée | `lf + lr` |
| `wf` | 0,6053 | fraction | Calculée | Fraction statique sur l'essieu avant `lr/L` |
| `tw` | 1,53 | m | Voie de substitution supposée | Le tableau 6 [S2] donne une largeur véhicule ; son emploi comme voie est une hypothèse explicite |
| `hcg` | 0,637 | m | Substitution sourcée | Hauteur du centre de gravité d'un véhicule de référence, tableau 6 [S2] |
| `g` | 9,80665 | m/s² | Sourcée | Pesanteur normale [S3] |
| `mu` | 0,90 | - | Condition supposée | Condition de forte adhérence utilisée dans [S1] ; ce n'est pas une mesure pneu-chaussée du véhicule |
| `reference_speed` | 16,6667 | m/s | Dérivée d'une exigence | Condition DBBS à 60 km/h |
| `vx_floor` | 0,5 | m/s | Protection numérique supposée | Évite une division par une très faible vitesse ; le modèle n'est pas validé sous cette limite |

## Modèle de pneumatique

| Symbole / champ | Valeur | Unité | Classification | Justification |
|---|---:|---|---|---|
| Raideur de dérive source | 33000 | N/rad par pneu | Sourcée | Raideurs avant et arrière du tableau 1 [S1] |
| `Cf` | 66000 | N/rad par essieu | Calculée | Deux pneus avant × 33000 N/rad |
| `Cr` | 66000 | N/rad par essieu | Calculée | Deux pneus arrière × 33000 N/rad |
| Facteur de pic `D` | `mu*Fz` | N | Calculé | Pic d'essieu limité par l'adhérence |
| Facteur de raideur `B` | `Cessieu/(Cshape*D)` | - | Calculé | Conserve la raideur de dérive publiée aux faibles angles |
| `Cshape` | 1,9 | - | Supposée | Valeur générique d'une formule magique simplifiée ; nécessite une calibration sur données pneu |
| `Eshape` | 0,97 | - | Supposée | Valeur générique de courbure ; nécessite une calibration sur données pneu |

Le modèle d'adhérence combinée réduit la capacité latérale selon une ellipse de friction. Il ne représente pas la dynamique de rotation des roues, la dynamique du taux de glissement, le carrossage, la température ni la sensibilité du pneu à la charge.

## Actionneurs et réglages numériques

| Symbole / champ | Valeur | Unité | Classification | Justification |
|---|---:|---|---|---|
| `delta_max` | 35 | deg à la roue | Supposée | Limite de simulation conservatrice en attente des données de crémaillère |
| `delta_rate` | 400 | deg/s | Hypothèse dérivée de l'exigence | Limite de variation actuelle des actionneurs de REQ-01 |
| `Fx_rate` | 40000 | N/s par frein | Hypothèse dérivée de l'exigence | Limite de variation actuelle des actionneurs de REQ-01 |
| `actuator_tau_delta` | 0,020 | s | Hypothèse de conception calculée | Une réponse du premier ordre atteint 91,8 % en 50 ms |
| `actuator_tau_Fx` | 0,020 | s | Hypothèse de conception calculée | Une réponse du premier ordre atteint 91,8 % en 50 ms |
| `validation_dt` | 0,002 | s | Dérivée de l'exigence | Période d'allocation et de validation |
| `allocation_effort_weight` | 1e-6 | - | Réglage numérique supposé | Rend le QP strictement convexe tout en gardant le suivi dominant |
| `allocation_friction_fraction` | 0,98 | - | Hypothèse de commande provisoire | Les commandes intégrées conservent 2 % de réserve longitudinale, soit 19,9 % de budget latéral du cercle d'adhérence à la limite commandée ; marge non calibrée sur un véhicule |
| `steering_channel_rate` | 240 par canal | deg/s | Capacité de conception supposée | Chaque entraînement fournit 60 % de la limite crémaillère de 400 deg/s |
| `steering_motor_tau` | 0,010 | s | Supposée | Retard indépendant de chaque boucle interne de vitesse |
| `yaw_tracking_tau` | 0,25 | s | Réglage supposé | Servo nominal de consigne de lacet |
| `dbbs_yaw_tracking_tau` | 0,15 | s | Réglage de conception en simulation | Servo de lacet après diagnostic de perte des deux entraînements ; non-régression tâche 1 requise |
| `fault_rear_friction_fraction` | 0,92 | - | Réglage de conception en simulation | Utilisation longitudinale arrière après perte d'un frein avant avec les deux freins arrière disponibles ; adhérence physique inchangée |
| `allocation_output_scale` | [5000; 1000] | [N; N m] | Priorités supposées | Normalisation fixe de l'objectif, distincte des diagnostics d'autorité |
| `steering_trust_angle` | 0,5 | deg | Réglage numérique supposé | Intervalle local de linéarisation non linéaire |

Les bornes physiques utilisent les charges courantes `mu*Fz`. La configuration de commande `ALLOC-2026-03` limite en plus les commandes intégrées à `0.98*mu*Fz` ; l'analyse d'autorité statique conserve la capacité théorique complète et les charges statiques. La réserve évite la frontière non lisse de budget latéral nul, mais ne garantit pas la capacité latérale transitoire : retard des actionneurs et variations des charges nécessitent toujours des contrôles indépendants de la plante. Sensibilité et fonctionnement dégradé restent à étudier. Chaque entraînement est supposé couvrir toute la plage de la crémaillère commune. Ces hypothèses fonctionnelles ne représentent ni inertie de crémaillère, ni couple moteur, ni capacité sous charge routière. L'argument des 20 ms ne vaut que pour un retard unique non saturé ; il ne prouve pas l'objectif de 50 ms de la direction en cascade. Voir [Gate 2](gate2.fr.md) pour les interfaces, manœuvres et preuves.

La révision de commande `ALLOC-2026-04` conserve les paramètres physiques ci-dessus et remplace le réglage dégradé `ALLOC-2026-03` : réserve arrière et gain DBBS sont adaptés au défaut selon la [tâche 1](task1_control.fr.md). L'utilisation arrière de 92 % correspond à un budget latéral théorique de 39,2 % du cercle d'adhérence, sans garantir la capacité transitoire réelle. Le réglage nominal est inchangé.

## Sources

- **S1 :** C. Wang, R. He et Q. Xia, « Path following control for 4WID-EV based on extended state observer and sliding mode control considering yaw stability », 2023. https://doi.org/10.1177/16878132221148271
- **S2 :** « Estimation of Vehicle Dynamic Parameters Based on the Two-Stage Estimation Method », *Sensors*, 2021, tableau 6. https://doi.org/10.3390/s21113711
- **S3 :** National Bureau of Standards, « Gravity Measurements and the Standards Laboratory », définition de la pesanteur normale. https://nvlpubs.nist.gov/nistpubs/Legacy/TN/nbstechnicalnote491.pdf

## Suite nécessaire

Avant de présenter les résultats comme représentatifs d'un véhicule particulier, il faudra remplacer les valeurs de substitution et les hypothèses d'actionneur par des mesures ou des données constructeur. Il faudra au minimum réaliser des analyses de sensibilité sur `Iz`, `hcg`, `mu`, `Cf` et `Cr`.
