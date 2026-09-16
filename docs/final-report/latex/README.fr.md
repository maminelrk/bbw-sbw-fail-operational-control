# Rapport PFA — Sources LaTeX

Ce paquet contient les deux éditions linguistiques du rapport final.

- Fichier principal anglais : `final_report.en.tex`
- Fichier principal français : `final_report.fr.tex`
- Contenu modifiable commun : `report.tex`
- Figures et logos nécessaires : `assets/`

## Compilation

Importez ce ZIP comme projet dans Overleaf, choisissez pdfLaTeX, puis sélectionnez le fichier principal anglais ou français dans les paramètres du projet. Compilez chaque édition séparément.

Vous pouvez également exécuter les commandes suivantes depuis le dossier extrait, avec une distribution TeX installée :

```sh
latexmk -pdf final_report.en.tex
latexmk -pdf final_report.fr.tex
```

Tectonic permet également de compiler chaque fichier principal. Les rapports livrés ont été compilés avec Tectonic ; la pagination peut légèrement varier avec une autre distribution TeX.

Modifiez `report.tex` pour enrichir le rapport. Dans `\bi{English}{French}`, le premier argument correspond à l'anglais et le second au français. Maintenez la cohérence des deux traductions. Ne compilez pas directement `report.tex` : utilisez l'un des deux fichiers principaux, qui sélectionne la langue.

La bibliographie et les schémas vectoriels de l'architecture sont intégrés dans `report.tex`. Aucune bibliographie séparée, installation MATLAB, nouvelle simulation, génération Python ou archive privée de résultats n'est nécessaire pour compiler ces sources. Conservez le dossier `assets/` à côté des fichiers principaux.

Ces sources du rapport final sont publiées avec l'autorisation des auteurs. Le CDC, les rapports de référence et les résultats bruts de simulation ne sont pas inclus.
