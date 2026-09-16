# Évaluation complémentaire Gate 3 — G3-AUTH/ENV-01

Ce protocole complète la campagne conservée `93db2a5 + timegrid_v1`. Il ne modifie ni le contrôleur, ni les paramètres véhicule, ni les seuils, ni les échecs existants. Les preuves générées restent dans `validation/results/` ignoré par Git ; les rapports privés restent dans `reports/`.

## Raffinement numérique

Rejouer le DBBS centré positif/négatif (`T1-D10`) et leurs références nominales. Séparer le raffinement RK4 (intégration 1 ms, commande inchangée 2 ms) du raffinement de commande (les deux à 1 ms). Comparer à la référence sauvegardée à 2 ms. Critères de cohérence déclarés : écart de déviation maximale <= 1 mm, écart maximal de vitesse de lacet <= 0,001 rad/s, écart maximal de vitesse longitudinale <= 0,03 m/s. Le seuil de trajectoire reste **0,500 m**. Ces essais évaluent la sensibilité à la discrétisation ; ils ne constituent ni un réglage du contrôleur ni une preuve de convergence exacte.

## Capacités de freinage et de lacet

Utiliser directement `vehicle_dynamics_quantities`, indépendamment de la prédiction affine de l'allocateur. Une recherche SQP multi-départ déterministe fournit des témoins non linéaires faisables avec charges positives, forces de freinage cohérentes au contact, adhérence, masques de panne et plage de direction. `fmincon` est un optimiseur local ; plusieurs départs ne prouvent pas un maximum global ([MathWorks](https://www.mathworks.com/help/optim/ug/fmincon.html)). Conserver tous les indicateurs de sortie et objectifs. La violation normalisée des contraintes doit rester <= 1e-7 ; un témoin faisable n'exige pas une convergence d'optimalité locale réussie.

Avec des charges positives, l'inégalité triangulaire appliquée aux cercles d'adhérence fournit des majorants nominaux conservatifs :

La révision 2 impose un intérieur strict au contact de freinage (`abs(Fx_i) <= 0,999*mu*Fz_i`) pour éviter la singularité de racine carrée lorsque la capacité latérale devient nulle. Cela restreint la recherche sans relâcher les contraintes physiques ni les seuils d'acceptation. Les points initiaux faisables sont conservés si l'optimisation stagne. La première recherche jusqu'à la frontière s'est arrêtée sans équilibre optimisé faisable après perte d'un frein avant ; ses sources/journaux restent séparément conservés. Une recherche diagnostique intérieure a retrouvé un équilibre faisable. Utiliser les empreintes de révision 2 pour la campagne achevée.

- Force de freinage dans le repère caisse : `F_upper = mu*m*g`.
- Moment de lacet absolu : `M_upper = F_upper*max(hypot(lf,tw/2),hypot(lr,tw/2))`.

Un témoin post-panne divisé par un **majorant** nominal fournit un minorant de la capacité conservée. Atteindre ainsi 60% en freinage ou 15% en lacet suffit pour la condition statique/figée étudiée ; ne pas les atteindre ne prouve **pas** une capacité physique insuffisante.

Freinage : cas nominal et perte de chacun des quatre freins ; optimiser la force longitudinale sous `r=0`, `Fy=0`, `Mz=0`, avec dérive dans +/-0,15 rad et direction dans sa plage. Il s'agit d'un équilibre instantané de trajectoire rectiligne, pas d'une preuve que le contrôleur l'atteint ou le maintient pendant la décélération. Rejouer séparément le profil G2 de saturation avec l'allocateur inchangé, panne avant la consigne, et évaluer le plateau 1,5–1,9 s. Exiger une décélération minimale >= 0,6*mu*g, les contrôles numériques/de vitesse, et un moment de lacet <= 5% d'un témoin nominal faisable (limite conservative). Relever aussi la vitesse de lacet. Ces simulations évaluent la performance délivrée, pas son maximum atteignable.

Lacet : deux signes à 60 km/h, lacet/dérive initialement nuls, direction nominale ou deux moteurs désactivés avec crémaillère centrée. Étudier aussi le DBBS plafonné à 0,35g. Ces témoins physiques instantanés ne remplacent pas les essais de suivi de manœuvre ou de transitoire des actionneurs.

### Addendum d'interprétation rectiligne — G3-BRK-ALIGN-01

Avec dérive non nulle, l'équilibre à `Fy` nul de l'archive n'est qu'un point de force caisse ; il ne prouve pas seul le freinage rectiligne. Exécuter séparément `run_gate3_straight_path_check(folder)`. Il impose `r=0`, `Mz=0` et `Fy*cos(beta)-Fx*sin(beta)=0` : force alignée avec la vitesse, dérivée instantanée de dérive nulle. Conserver la marge de contact 0,999, la dérive +/-0,15 rad et `Vx=60 km/h`. Optimiser la décélération caisse ; sa division par `mu*g` minore conservativement la capacité selon le déplacement. Exporter quatre forces de frein, direction, dérive, résidus d'alignement et de lacet pour recalcul indépendant. Cela reste un témoin faisable par état, pas une performance transitoire maintenue ni un maximum global.

## Enveloppe opérationnelle échantillonnée

Pour chaque cas de panne sauvegardé, étudier les états réels à `t_flag+50 ms` et `max(3 s,t_flag+150 ms)`. Tester la demande originale `[Fx,Mz]` et quatre coins d'une boîte de demi-largeur `(0,15/0,85)*abs(demand)` par axe. Cette construction représente une réserve extérieure de 15% mesurée par rapport à la frontière. Une demande nulle donne une largeur nulle sur cet axe. Huit départs déterministes par point cherchent une correspondance force/moment non linéaire ; la tolérance déclarée est un résidu <= 0,001 des échelles globales conservatives force/moment.

Distinguer :

- Témoin faisable à état figé trouvé.
- Aucun témoin trouvé : résultat indéterminé, **pas** une preuve d'infaisabilité.
- Dépassement d'un majorant physique conservatif : point prouvé hors de cette borne.

Même des témoins réussis aux coins ne prouvent ni la faisabilité de l'intérieur d'une image non linéaire, ni une réserve de 15% sur toute une trajectoire. Il s'agit de **contrôles échantillonnés des coins**, pas d'une enveloppe opérationnelle certifiée. La perte des deux moteurs DBBS est distinguée du périmètre REQ-02 à panne d'effecteur unique.

Pour chaque correspondance, appliquer aussi une rampe de commande limitée en vitesse vers le témoin dans le modèle complet véhicule/actionneurs pendant 50 ms, à partir de l'état sauvegardé et de la commande précédente. Cette construction en boucle ouverte sans allocateur est un candidat atteignable, pas un ensemble accessible optimal. Contrôler commandes, adhérence, charges, vitesse et dérive. Normaliser l'erreur finale par `max(abs(target),0,05*[F_upper;M_upper])` ; <=10% est uniquement un contrôle au point final, **pas** le maintien de 100 ms de REQ-02 ni la mesure de récupération par oracle affine. L'échec d'un candidat n'exclut pas un meilleur transitoire.

En DBBS centré sans dérive, `abs(Mz) <= (tw/2)*(-Fx)` exactement : le lacet exige du freinage. Les maxima indépendants de force/lacet ne définissent donc pas une région rectangulaire faisable. Ne pas étendre cette formule aux états en virage/dérive avec forces latérales passives.

## Règles de clôture

Conserver les résultats négatifs et indéterminés. Ces études seules ne ferment pas Gate 3. Un échec de manœuvre exige une correction explicite de conception et une campagne complète de non-régression. Les exigences numériques provisoires et le domaine opérationnel visé nécessitent l'accord de l'encadrant ; il s'agit de preuves de simulation, pas d'une certification de sécurité véhicule.
