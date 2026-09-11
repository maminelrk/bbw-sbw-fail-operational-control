# Référence numérique pour REQ-02 et REQ-03

Statut : référence d'ingénierie proposée pour la validation Gate 2/3. Ces valeurs doivent être validées avec l'encadrant du projet avant d'être considérées comme des exigences de sécurité approuvées. Il s'agit de critères d'acceptation en simulation et non de preuves de conformité à l'ISO 26262.

## Périmètre et définitions

- Période d'allocation : `Ts = 2 ms`, conformément à la configuration Simulink actuelle.
- Instant du défaut `t_f` : instant auquel un indicateur de défaut validé est présenté à l'allocateur. La latence de détection est mesurée séparément et n'est pas incluse dans le temps de reconfiguration.
- Sortie de l'allocation : `y = [Fx, Mz]'`.
- `y_best(t)` : sortie la plus proche réalisable avec le masque après défaut, les limites physiques et de variation actives, et la même demande. Pour une demande irréalisable, il s'agit de la solution QP au mieux réalisable et non de la demande initiale.
- Erreur de suivi normalisée : `e_y = norm((y - y_best) ./ y_scale, Inf)`, où `y_scale` représente l'autorité de force et de lacet après défaut rapportée par l'allocateur.
- Une demande appartient à l'enveloppe opérationnelle après défaut lorsqu'elle est réalisable avec au moins 15 % d'autorité inutilisée dans chaque direction de sortie active. Les critères transitoires ci-dessous s'appliquent à cette enveloppe. En dehors de l'enveloppe, l'allocateur doit toujours fournir une solution bornée au mieux réalisable et ne doit jamais inverser le signe d'une force de freinage demandée.

## REQ-02 — temps de reconfiguration et continuité

Après la présentation d'un indicateur validé de défaut d'un seul actionneur :

1. Le nouveau masque d'actionneurs doit être actif en **10 ms** au maximum, soit cinq périodes d'allocation.
2. La réponse allocateur/actionneur doit atteindre **90 % de la sortie au mieux réalisable après défaut en 50 ms** et rester dans une **bande d'erreur normalisée de 10 % pendant au moins 100 ms**.
3. Toute commande d'un frein sain doit respecter `|dFx/dt| <= 40 kN/s`, et la commande de direction saine doit respecter `|d(delta)/dt| <= 400 deg/s`.
4. Comme indicateur provisoire de discontinuité ressentie par le conducteur, la trajectoire en défaut doit rester à moins de **0,05 rad/s de la vitesse de lacet nominale pendant les 200 premières millisecondes** après le défaut, pour les demandes appartenant à l'enveloppe opérationnelle après défaut.

La cible de 50 ms est conservée comme objectif du projet. Avec les constantes de temps actuelles de 20 ms pour les actionneurs du premier ordre, 50 ms correspond à environ 92 % d'une réponse indicielle. Le seuil d'acceptation est donc fixé à 90 % plutôt qu'à 95 %. Le critère de vitesse de lacet est un indicateur de simulation et ne doit pas être présenté comme un seuil de perception humaine démontré sans essais véhicule.

## REQ-03 — capacité résiduelle minimale

REQ-03 est divisée par fonction de sécurité, car la compensation du lacet par freinage ne peut pas reproduire physiquement toute l'autorité en force et en angle de la direction normale.

### REQ-03a — capacité de freinage

Après la perte d'un frein de roue, ou d'un chemin d'alimentation ou de communication supprimant ce frein, la décélération rectiligne maximale réalisable doit rester au moins égale à **60 % de la valeur nominale**, tout en respectant :

- `|Mz| <= 5 %` de l'autorité maximale nominale en lacet ;
- les limites de force et de variation de tous les actionneurs sains.

Avec les paramètres actuels de charge statique, le pire cas prévu est la perte d'un frein avant, laissant environ **70 %** de la force de freinage nominale brute.

### REQ-03b — perte d'un canal de direction

Lorsque le modèle de direction à deux moteurs sera disponible, la perte de l'un des canaux devra laisser au moins :

- **60 % de la plage nominale d'angle aux roues** ;
- **60 % de la vitesse nominale de direction**.

Le modèle actuel à un seul angle de direction ne permet pas de vérifier cette sous-exigence.

### REQ-03c — perte complète de la direction commandée / DBBS

Lorsque l'actionneur de direction commandée est indisponible et que le Differential-Braking Backup Steering est activé, les freins restants doivent fournir :

- au moins **15 % de l'autorité maximale nominale en moment de lacet** ;
- un suivi de vitesse de lacet pour `|r_ref| <= 0,15 rad/s` à 60 km/h avec `RMSE(r) <= 0,03 rad/s` sur la manœuvre ;
- un écart latéral maximal par rapport à la trajectoire nominale `<= 0,50 m` ;
- une décélération induite par le freinage `<= 0,35 g` pendant cet essai.

Avec le jeu de paramètres `REF-2026-01`, l'autorité statique de lacet produite uniquement par les freins est d'environ 5,37 kN·m, soit environ 37,6 % de l'autorité nominale combinée direction-freinage limitée par l'adhérence. L'autorité de direction est plafonnée par `mu*Fz` au lieu d'extrapoler la raideur de dérive linéaire jusqu'à l'angle de direction maximal. Une exigence uniforme visant à reproduire 60 % de la capacité nominale de direction reste inadaptée, car le freinage différentiel ne peut pas reproduire indépendamment l'angle de direction ou la force latérale sans provoquer de décélération longitudinale.

## Preuves requises pour Gate 3

Chaque essai de défaut simple doit enregistrer la demande, la transition du masque, la commande de l'allocateur, les valeurs `[Fx, Mz]` obtenues, les meilleures valeurs `[Fx, Mz]` réalisables, les vitesses des actionneurs, la vitesse de lacet, l'écart latéral et le résultat réussite/échec de chaque clause applicable.
