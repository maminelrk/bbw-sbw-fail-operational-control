# Tâche 1 — correction de la commande en mode dégradé

Protocole : `TASK1-CTRL-01`. Commande : `ALLOC-2026-04`. Véhicule : `REF-2026-02` inchangé.

État : campagne MATLAB et audit local des preuves terminés le 16 septembre 2026. Les échecs initiaux sont corrigés, mais six transitions supplémentaires en freinage saturé échouent ; `Task1Passed=false` et Gate 3 reste ouvert.

Suite : [l'évaluation locale tâche 2 terminée](task2_assessment.fr.md) apporte recalcul temporel indépendant, contrôle de transfert des preuves, matrice courante et décision conditionnelle tâche 3, sans nouvelle exécution MATLAB.

Contexte : l'auteur du projet a confirmé que le garant a approuvé les décisions en attente qui lui étaient soumises. Cette confirmation est consignée sans inventer de signature, de date d'approbation ni de procès-verbal ; elle ne transforme pas un essai en échec en réussite. Encadrants académiques supplémentaires : Pr Said Ben Alla et Pr Issam Amellal. La cible est un démonstrateur académique validé en simulation, non une certification de sûreté d'un véhicule de série.

## Diagnostic et conception

Les cas initiaux de perte d'un frein avant sous fort freinage dépassaient 0,15 rad de dérive malgré une faible vitesse de lacet. L'équilibre en lacet ne préservait pas à lui seul le soutien latéral arrière. À 98 % d'utilisation longitudinale, le budget latéral théorique du cercle d'adhérence à la limite commandée vaut seulement `sqrt(1-0.98^2) = 19,9 %` de `mu*Fz`. Les retards d'actionneur et transferts de charge distinguent encore ce budget commandé de la capacité réelle des pneus.

Le candidat limite les commandes de freinage arrière à 92 % de la capacité longitudinale courante lorsqu'un seul frein avant est diagnostiqué défaillant et que les deux freins arrière sont disponibles. Le budget latéral théorique correspondant est de 39,2 %. Les autres canaux conservent la politique de 98 %. Adhérence physique, équations pneu, limites d'actionneur et paramètres véhicule sont inchangés. Seul le masque diagnostiqué déclenche cette politique ; la commande ne consulte ni identifiants de scénario, ni défauts futurs, ni résultats de validation.

Le balayage MATLAB à six valeurs (0,98 ; 0,96 ; 0,94 ; 0,92 ; 0,90 ; 0,88) a montré le compromis freinage/stabilité. À 0,92, l'essai préliminaire de perte avant gauche conservait 61,115 % de freinage avec 0,060513 rad de dérive maximale, contre 63,679 % et 0,241615 rad à 0,98. Il s'agit d'essais de conception, non du verdict final de non-régression. Le seuil de 60 % reste inchangé ; cette marge limitée ne garantit pas la robustesse.

Une nouvelle réserve est atteinte en respectant la vitesse de relâchement autorisée des commandes. Cette réserve de commande peut être temporairement dépassée pendant la transition ; les bornes physiques restent prioritaires. Un conflit inévitable entre borne physique et vitesse reste enregistré comme dérogation, sans être masqué.

L'écart de trajectoire DBBS avec crémaillère centrée a été réduit dans les essais par un retour de lacet plus rapide. Le candidat passe la constante de temps de 0,25 s à 0,15 s seulement après diagnostic de perte des deux entraînements de direction. Le fonctionnement nominal et la perte d'un seul entraînement conservent 0,25 s. La consigne temporelle initiale et tous les seuils d'évaluation sont inchangés. Il s'agit d'un suivi de lacet, sans prétendre à une nouvelle boucle de retour de trajectoire.

Une variante adaptant la consigne de lacet à la vitesse a été testée puis rejetée : elle aggravait l'écart du cas centré. Ses résultats et son code expérimental initial sont conservés en privé. Elle ne fait pas partie de la commande livrée.

## Reproduction et acceptation

Depuis la racine du projet dans MATLAB avec Optimization Toolbox :

```matlab
results = run_task1_validation();
```

Le programme crée un nouveau dossier horodaté et archive les sources MATLAB exactes. Un dossier de sortie explicitement fourni déjà existant est refusé afin de préserver les preuves.

Couverture : suite complète de tests unitaires ; cinq manœuvres Gate 2 ; 30 cas de défaut Gate 3 avec quatre références nominales ; cinq cas de freinage dynamique ; six transitions supplémentaires de perte avant pendant un fort freinage ; contrôles à 1 ms d'échantillonnage/intégration pour les deux pertes avant et les deux directions DBBS centrées initialement en échec.

Limites principales inchangées : dérive <= 0,15 rad ; freinage conservé >= 60 % ; moment de lacet sur plateau <= 5 % d'un témoin nominal faisable ; écart DBBS <= 0,50 m, RMSE de lacet <= 0,03 rad/s et décélération additionnelle <= 0,35 g. Les contrôles de forces, adhérence, charges, vitesses, solveur et masques restent actifs. Les transitions supplémentaires sous charge sont distinguées du critère de plateau de la manœuvre d'autorité initiale.

`Task1Passed` est distinct de la fermeture de Gate 3. L'oracle de récupération existant reste diagnostique ; l'applicabilité et la récupération indépendantes REQ-02, l'enveloppe opérationnelle, la comparaison à une référence simple et la robustesse élargie relèvent de la tâche 2.

## Résultats MATLAB — candidat v1

Les 45 tests unitaires, cinq manœuvres nominales et diagnostics numériques/masques/récupération/continuité des 30 cas de défaut initiaux réussissent. Les huit évaluations de manœuvre DBBS réussissent : écart maximal 0,294527 m (limite 0,50 m), RMSE de lacet maximale 0,011461 rad/s (0,03), décélération maximale 0,277080 g (0,35). Les manœuvres initiales d'autorité après perte d'un frein avant atteignent maintenant 0,060513 rad de dérive (0,15), conservent au moins 61,1147 % de freinage (60 %) et respectent la limite de lacet sur plateau. Les deux pertes arrière réussissent. Les quatre raffinements à 1 ms réussissent ; l'écart DBBS centré reste inférieur à 0,295254 m.

Les six essais **supplémentaires** injectent la perte avant à 1,5 s pendant un freinage saturé, avec diagnostic à 0/10/50 ms. Chacun signale une dérogation à la vitesse de commande. Sur la fenêtre 1,5–1,9 s incluant l'instant du défaut, le freinage minimal vaut 49,587–50,592 % et le moment de lacet maximal environ 3919,81 Nm, au-dessus de 567,14 Nm. La dérive reste inférieure à 0,060395 rad. Ces échecs sont conservés, sans conversion en réussite ni revendication de conformité totale. Les contrôles dès l'apparition du défaut doivent être distingués du plateau d'autorité initial avec défaut préalable ; faisabilité transitoire et récupération restent à évaluer avant clôture.

### Conflit transitoire restant

Lors de la perte avant gauche sans retard de diagnostic, la commande avant droite saine vaut -5614,4 N juste avant le défaut. La charge quasi statique du modèle tombe à 5693,3 N à l'apparition du défaut, d'où une borne physique basse d'environ -5124,0 N. La contrainte de vitesse n'autorise qu'un relâchement de 80 N par 2 ms, donc une commande au plus égale à environ -5534,4 N à ce pas. Les intervalles sont disjoints : aucune allocation ne peut satisfaire simultanément ces contraintes instantanées dans cet état. Le repli donnant priorité aux bornes commande -5021,5 N et signale explicitement la dérogation. Cela ne démontre pas qu'un actionneur réel puisse effectuer ce saut.

Pour cette trace, de 1,70 s à 1,90 s, le freinage conservé vaut au moins 60,258 % et le moment absolu de lacet au plus 238,662 Nm. Il s'agit d'une description de la récupération, non d'une nouvelle fenêtre d'acceptation ni d'une réussite indépendante REQ-02. La saturation à l'apparition du défaut exige une décision explicite sur le modèle, la sémantique des commandes et l'enveloppe opérationnelle ; un réglage de gains ne supprime pas une intersection vide de contraintes. Aucune nouvelle décision de ce type n'est attribuée au garant.

Contrainte d'utilisation : l'auteur demande de réduire la consommation MATLAB et de prioriser l'achèvement le jour même. Aucune campagne MATLAB supplémentaire n'est programmée. La suite exploite localement les preuves sauvegardées ; toute nouvelle simulation indispensable doit être précisément justifiée avant exécution.

## Archive des preuves

Archive terminée : `validation/results/task1_evidence_20260916.zip`, SHA-256 `6821dcd9105ca9d5d5f961cb79b079c928c2f6e117a992fa8e89478f8b95550c`, vérifié avec MATLAB Drive. Elle contient le candidat exécuté, ses sources exactes, les essais de conception et les variantes rejetées. L'audit local a recalculé les contrôles sur 54 séries CSV et vérifié l'identité exacte des six sources MATLAB modifiées. `task1_local_audit.json` confirme la cohérence, non une réussite tâche 1. Deux ratios de freinage après perte arrière diffèrent d'environ 1,6e-7 lorsque l'arrondi CSV inclut l'échantillon à 1,9 s ; son exclusion reproduit MATLAB sans changer les verdicts. Pendant les défauts saturés avec diagnostic retardé, les commandes dépassent aussi temporairement les bornes de force de l'état réel avant diagnostic, bien que les forces effectives restent limitées par le cercle d'adhérence. Ces limites sont consignées, sans revendication de validation indépendante du modèle ni de REQ-02. Quatre figures PNG avant/après bilingues sont sauvegardées dans `validation/results/presentation` au sein des preuves extraites.

L'instantané local du code MATLAB avant modification est `tmp/task1_baseline_20260916.zip`, SHA-256 `dad44b7625503f81ec32dafe34fde3b34e3de4de1277e80d6d9f37838fa26d94`. Les preuves Gate 2, Gate 3 et complémentaires initiales sont intactes. Le travail MATLAB Online est isolé dans `task1_control_20260916` ; les sources et résultats cloud initiaux sont conservés. Archives brutes, rapports et documents sources restent exclus du GitHub public.
