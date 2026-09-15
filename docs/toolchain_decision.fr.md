# Choix de la chaîne d'outils

La chaîne d'outils d'exécution du projet est MATLAB, avec Simulink disponible pour les modèles en schémas-blocs. La préférence initiale pour une chaîne exclusivement open source est remplacée par ce choix pour l'implémentation du projet.

Produits requis :

- MATLAB R2021a ou une version ultérieure ;
- Optimization Toolbox (`quadprog`) ;
- MATLAB Unit Test Framework, inclus avec MATLAB.

L'implémentation de référence actuelle du Gate 2 utilise des scripts et fonctions MATLAB via `run_gate2_validation` ; elle ne nécessite pas Simulink. Simulink est requis uniquement pour ouvrir ou exécuter les modèles `.slx`. Le fichier existant `wawaw.slx` est un prototype historique à 11 états, et non l'intégration actuelle du Gate 2 à 13 états.

Le dépôt de simulation et la documentation finale du projet doivent indiquer ces dépendances afin de permettre la reproduction des résultats. L'équivalence avec une chaîne open source ne constitue pas un critère d'acceptation du projet, sauf si elle est ajoutée ultérieurement comme objectif distinct.
