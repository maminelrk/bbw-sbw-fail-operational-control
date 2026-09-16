# Choix de la chaîne d'outils

La chaîne d'exécution est MATLAB, avec Simulink disponible pour les schémas-blocs. L'utilisateur a explicitement choisi MATLAB à la place de la prescription exclusivement libre du CDC initial. Ce choix d'implémentation est autorisé, mais ne constitue pas un amendement formel enregistré du CDC ; l'acceptation de l'encadrant/garant reste non enregistrée (DEV-05 du registre local).

Produits requis :

- MATLAB R2021a ou une version ultérieure ;
- Optimization Toolbox (`quadprog`) ;
- MATLAB Unit Test Framework, inclus avec MATLAB.

L'implémentation de référence actuelle du Gate 2 utilise des scripts et fonctions MATLAB via `run_gate2_validation` ; elle ne nécessite pas Simulink. Simulink est requis uniquement pour ouvrir ou exécuter les modèles `.slx`. Le fichier existant `wawaw.slx` est un prototype historique à 11 états, et non l'intégration actuelle du Gate 2 à 13 états.

Le dépôt et la documentation finale doivent préciser ces dépendances pour permettre la reproduction. La parité open source n'appartient pas au périmètre d'implémentation choisi par l'utilisateur et n'est pas démontrée. L'acceptation de cet écart au CDC écrit pour la soumission relève de l'encadrant/garant ; cette note n'implique aucune migration.
