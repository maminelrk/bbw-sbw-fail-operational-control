# Validation du modèle en boucle ouverte sans allocateur

## Objectif

Valider les signes, le bilan des forces, la dynamique des actionneurs, la saturation des pneumatiques, le transfert de charge et la réponse du véhicule aux faibles angles avant de connecter l'allocateur de commande.

Le point d'entrée MATLAB est :

```matlab
plantSummary = run_plant_validation();
```

Les preuves générées sont enregistrées dans `validation/results/plant/`.

## Scénarios et critères d'acceptation

| ID | Entrée appliquée après 0,5 s | Contrôles principaux |
|---|---|---|
| `PLANT-BRK-01` | Quatre forces de freinage identiques de -1500 N | Accélération longitudinale négative, lacet nul, trajectoire rectiligne, transfert de charge vers l'avant |
| `PLANT-STR-01` | Direction de +1° à la roue, sans freinage | Réponse positive en lacet, dérive bornée, respect de l'adhérence, vitesse de lacet finale à moins de 20 % de la référence analytique du modèle bicyclette linéaire |
| `PLANT-CMB-01` | Direction de +1° et quatre forces de freinage de -1000 N | Lacet positif avec décélération, couplage visible de l'ellipse de friction, charges de roue positives, dérive bornée |

Tous les scénarios exigent également :

- des états et des forces finis ;
- une charge normale minimale de 49,9 N sur chaque roue ;
- une force latérale ne dépassant pas la capacité calculée en adhérence combinée ;
- des vitesses d'état de la direction et des freins respectant les limites configurées.

## Vérification numérique indépendante des équations

MATLAB n'est pas installé dans l'environnement de développement utilisé ici. Les mêmes équations ont donc été reproduites indépendamment en Python et intégrées avec le même pas de 2 ms par une méthode de Runge-Kutta d'ordre 4. Cette vérification permet de détecter les erreurs d'équation, de signe et de seuil, mais elle ne constitue pas le résultat officiel de validation MATLAB.

| Scénario | Vitesse finale | Lacet absolu maximal | Lacet final | Dérive absolue maximale | Charge de roue minimale | Résultat |
|---|---:|---:|---:|---:|---:|---|
| `PLANT-BRK-01` | 3,549 m/s | 0 rad/s | 0 rad/s | 0 rad | 2359 N | Contrôles de cohérence réussis |
| `PLANT-STR-01` | 16,608 m/s | 0,0749 rad/s | 0,07124 rad/s | 0,00453 rad | 2914 N | Contrôles de cohérence réussis |
| `PLANT-CMB-01` | 7,885 m/s | 0,0706 rad/s | 0,04544 rad/s | 0,00567 rad | 2453 N | Contrôles de cohérence réussis |

Pour `PLANT-STR-01`, la référence analytique du modèle bicyclette linéaire en régime permanent vaut 0,07149 rad/s. Le résultat du modèle non linéaire présente un écart d'environ 0,35 %, ce qui soutient l'implémentation aux faibles angles.

Aucun scénario n'a dépassé la capacité latérale de l'ellipse de friction lors de la vérification indépendante.

## Interprétation

Les résultats au niveau des équations soutiennent uniquement les affirmations suivantes :

- les conventions de signe sont cohérentes ;
- un freinage symétrique ne génère pas de lacet pour un état véhicule symétrique ;
- le freinage longitudinal transfère la charge normale vers l'essieu avant ;
- une direction positive génère une réponse latérale et un lacet positifs ;
- le modèle de Pacejka simplifié est proche du modèle bicyclette linéaire pour une entrée de un degré ;
- le freinage combiné réduit le budget de force latérale.

Ces résultats ne valident pas un véhicule physique particulier. Les coefficients de forme des pneus, la hauteur du centre de gravité, la voie et les limites des actionneurs contiennent encore des hypothèses documentées. Les preuves finales Gate 2 devront être produites en exécutant l'implémentation MATLAB versionnée et en vérifiant ses figures.

## Limites du modèle

- transfert de charge quasi statique sans états de roulis ou de tangage ;
- un modèle latéral global de pneumatique par essieu ;
- absence de dynamique de rotation des roues et d'état de taux de glissement ;
- absence de traînée aérodynamique et de résistance au roulement ;
- un actionneur de direction équivalent au lieu de deux canaux indépendants ;
- absence d'identification des paramètres à partir de mesures véhicule.
