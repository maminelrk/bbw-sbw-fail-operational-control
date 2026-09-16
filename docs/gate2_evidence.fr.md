# Gestion des preuves Gate 2

[English](gate2_evidence.en.md)

La référence numérique est l'exécution MATLAB corrigée du **15 septembre 2026 à 23:33:46 UTC**, au statut `READY_FOR_SUPERVISOR_REVIEW`. Elle a réussi 36 tests unitaires, 3 cas plante sans allocateur, 4 bancs de direction, 5 manœuvres intégrées et la comparaison des pas. L'accord de l'encadrant et Gate 3 restent distincts.

## Dossier local achevé

L'archive corrigée originale (88 fichiers), le réexport MATLAB natif clair (94 fichiers), les sept empreintes sources numériques et les 42 fichiers bruts copiés ont été vérifiés localement. Le dossier final comprend **46 figures bilingues et deux rapports LaTeX de 17 pages** dans des répertoires ignorés. Les titres globaux MATLAB restant pâles, les rapports finaux utilisent Matplotlib uniquement pour tracer les CSV MATLAB inchangés ; les deux moteurs sont identifiés au pied de chaque figure. Aucune simulation de substitution, interpolation ou opération de lissage n'a été effectuée. Le réexport natif est conservé séparément. Une correction ultérieure des propriétés de titre a été analysée statiquement mais n'a pas été réexécutée dans MATLAB ; sa version archivée antérieure reste traçable.

L'index local est `reports/gate2_validation/README.fr.md` ; les figures finales sont dans `validation/results/gate2_presentation_20260915_233346/`. Le journal de vérification est `validation/results/gate2_local_verification.json`. Ces fichiers ne sont volontairement pas publiés.

## Trois enregistrements distincts

1. **Référence en échec :** 19:04:40 UTC, conservée pour le diagnostic ; jamais requalifiée en réussite.
2. **Preuves brutes corrigées :** `gate2_corrected_20260915_233346.zip`, comprenant résultats MAT/CSV, manifeste original, console, diagnostic solveur et instantané des sept fichiers sources testés.
3. **Dossier de présentation :** nouveau répertoire avec figures bilingues sur fond clair, preuves brutes identiques octet par octet, `presentation_manifest.json` et `rendering_source/`. Il s'agit d'un réexport, non d'une nouvelle campagne numérique.

L'exécution originale utilisait le commit de base `a775806` et sept fichiers corrigés ensuite enregistrés dans `c37a749`. Conserver les métadonnées originales de modifications non commitées ; utiliser `saturation_fix_source_manifest.json` pour identifier la correction testée. Une modification ultérieure de présentation ne change pas l'identité de cette exécution numérique.

## Réexporter sans relancer la simulation

Avec le projet et `validation` dans le chemin MATLAB :

```matlab
addpath(pwd,fullfile(pwd,'validation'));
sourceRoot = '/chemin/absolu/vers/original/validation/results';
outputRoot = '/chemin/absolu/vers/nouveau/gate2_presentation';
presentation = reexport_gate2_evidence(sourceRoot,outputRoot);
```

La source doit contenir `gate2`, `plant`, `gate2_corrected_console.txt`, `gate2_corrected_extra.mat`, `saturation_fix_source_manifest.json`, `saturation_fix_v7.zip` et `solver_diagnostic_v6`. Le manifeste source doit indiquer une réussite. La destination ne doit ni exister ni chevaucher la source.

L'utilitaire lit les MAT/CSV existants et exporte **46 PNG : 20 intégrés, 18 plante et 8 direction**, répartis à parts égales entre français et anglais. Il vérifie chaque fichier copié hors PNG avec son SHA-256 original avant d'écrire le manifeste de présentation. Les fichiers numériques originaux et les seuils d'acceptation ne sont pas modifiés. Un échec de réexport peut laisser une destination partielle : l'inspecter et réessayer dans un nouveau répertoire, sans la considérer comme un dossier achevé.

`style_report_figure` impose des fonds blancs, des étiquettes sombres et une palette lisible à l'impression. Les lanceurs de validation habituels utilisent les mêmes fonctions de tracé pour les futures campagnes. Ne pas relancer `run_gate2_validation` dans le dossier de preuves historique pour simplement corriger les figures : ce lanceur écrase ses sorties numériques.

## Liste de vérification

- Vérifier l'intégrité de l'archive et les empreintes des fichiers extraits.
- Comparer les sept empreintes sources à la correction archivée et aux sources locales.
- Contrôler tous les indicateurs CSV, pas uniquement le statut global.
- Recalculer le lacet en saturation, la force résiduelle et la vitesse minimale depuis les séries temporelles.
- Comparer les empreintes des fichiers bruts copiés au téléchargement original et au manifeste de présentation.
- Inspecter visuellement les figures et les deux versions linguistiques du rapport final.
- Conserver rapports, documents de cadrage et preuves générées dans les dossiers ignorés ; ne jamais les publier dans le dépôt public.

Le rapport de stage doit distinguer cohérence de simulation et validation physique, contrôles nominaux et validation dynamique sous défaut, préparation numérique et acceptation par l'encadrant.
