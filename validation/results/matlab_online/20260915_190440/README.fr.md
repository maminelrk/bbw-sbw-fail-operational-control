# Première exécution MATLAB Online de Gate 2

[English](README.en.md)

## Identification des preuves

- Début : 15 septembre 2026 à 19:04:40 UTC ; durée : 297,134 s.
- Moteur : MATLAB Online Basic, R2026a Update 5, version 26.1.0.3346908 ; Optimization Toolbox 26.1 ; Linux.
- Sources : commit `a775806a5b877f8aad7e70e7baa1cc81a3e4e0ab`, branche `main`, répertoire de travail propre enregistré dans le manifeste.
- Point d'entrée : `run_gate2_validation()` ; aucune modification des sources ou des seuils pendant cette exécution.
- État final enregistré : **CHECKS_FAILED**. Il s'agit d'une campagne réellement exécutée dans MATLAB, et non d'une vérification indépendante Python. Gate 2 n'est pas clôturé. Gate 3 n'a pas été exécuté.

## Résultats

| Groupe de contrôles | Résultat |
|---|---|
| Tests unitaires | 31/31 réussis |
| Scénarios du modèle sans allocateur | 3/3 réussis |
| Banc de direction à crémaillère commune | 4/4 réussis |
| Manœuvres de suivi normales | G2-BRK, G2-STR, G2-CMB et G2-YAW réussies |
| Saturation et relâchement | G2-SAT échoue aux contrôles de comportement et de domaine de fonctionnement |
| Convergence du pas | Réussie : écart maximal de lacet 0,0002676114 rad/s, écart de vitesse 0,0005565032 m/s |

Les cinq cas intégrés respectent les contrôles enregistrés d'états finis, de charges, d'adhérence, de vitesses des actionneurs, de bornes de commande et de succès du solveur ; aucune dérogation de vitesse n'a eu lieu. Ces contrôles ne démontrent ni un comportement réussi ni une validité physique hors du domaine de fonctionnement.

| Manœuvre | RMSE force [N] | RMSE lacet [rad/s] | Bilan |
|---|---:|---:|---|
| G2-BRK | 44,645091 | 0,000000041319 | Réussite |
| G2-STR | 20,619945 | 0,002130510 | Réussite |
| G2-CMB | 28,631067 | 0,001793353 | Réussite |
| G2-YAW | 6,276130 | 0,001721762 | Réussite |
| G2-SAT | 5635,112433 | 0,023060951 | Échec |

La RMSE de force est un diagnostic, et non le critère d'acceptation de la demande de saturation volontairement irréalisable.

## Échec du cas de saturation

- Plateau de capacité : 0,9968786273 de la capacité nominale de freinage limitée par l'adhérence, au-dessus de la cible 0,95.
- Vitesse de lacet absolue maximale : 0,0792079558 rad/s, au-dessus du critère rectiligne de 0,0001 rad/s.
- Force longitudinale absolue maximale à partir de 3,2 s : 9172,1682 N, au-dessus du critère de relâchement de 100 N.
- Vitesse minimale : 0,4971831695 m/s, sous la limite stricte du domaine de fonctionnement de 0,5 m/s.
- Angle de direction absolu maximal : 35 degrés (limite mécanique).

Les historiques montrent un freinage asymétrique et un braquage non souhaité pendant une saturation nominalement rectiligne, puis un freinage avant persistant après le relâchement. Cela diffère sensiblement de la vérification numérique indépendante antérieure. Les indicateurs de sortie du solveur restent positifs ; le succès du solveur ne vaut pas validation en boucle fermée. La cause racine n'est pas encore établie. Les résultats après franchissement de la limite de faible vitesse ne doivent pas être interprétés comme un comportement véhicule validé à basse vitesse.

Suite : diagnostiquer l'allocation en saturation/adhérence combinée et le relâchement, ajouter un test de non-régression couvrant l'écart, puis réexécuter Gate 2 sans assouplir les seuils d'acceptation. Revoir Gate 2 avant de lancer Gate 3.

## Conservation des preuves brutes

Dossier du projet dans MATLAB Drive : `/MATLAB Drive/bbw-sbw-fail-operational-control`.

- `validation/results/gate2/` : manifeste, tests unitaires, banc de direction, historiques/métriques/fichiers MAT et figures françaises/anglaises des cinq manœuvres, convergence, `gate2_results.mat`.
- `validation/results/plant/` : trois cas sans allocateur, résumés et figures.
- `validation/results/gate2_console_20260915_190440.txt` : journal d'exécution enregistré.
- `validation/results/gate2_execution_summary.json`, `gate2_saturation_diagnostic.json`, `gate2_saturation_samples.csv` : résumés des diagnostics extraits.
- Archive complète : `/MATLAB Drive/gate2_matlab_20260915_190440.zip`.

L'archive a été créée dans MATLAB Drive et son téléchargement a été demandé au navigateur, mais aucune copie téléchargée localement n'a été vérifiée. Cette note locale consigne les métriques lues dans l'interface MATLAB ; elle ne remplace pas l'archive des preuves brutes. Aucun rapport ni résultat généré n'a été envoyé sur GitHub.
