# PFA report — LaTeX sources

This package contains both language editions of the final report.

- English main file: `final_report.en.tex`
- French main file: `final_report.fr.tex`
- Shared editable content: `report.tex`
- Required figures and logos: `assets/`

## Compile

Upload this ZIP as a project to Overleaf, choose pdfLaTeX, then select the English or French main file in the project settings. Compile each edition separately.

Alternatively, from the extracted directory with a TeX installation:

```sh
latexmk -pdf final_report.en.tex
latexmk -pdf final_report.fr.tex
```

Tectonic can also compile each entry file. The delivered reports were built with Tectonic; pagination can differ slightly with other TeX distributions.

Edit `report.tex` to change the report. In `\bi{English}{French}`, the first argument is English and the second is French. Keep both translations consistent. Do not compile `report.tex` directly: use one of the two main files, which selects the language.

The bibliography and vector architecture diagrams are embedded in `report.tex`. No separate bibliography, MATLAB installation, simulation rerun, Python builder, or private evidence archive is required to compile these sources. Keep `assets/` alongside the main files.

These final report sources are published with the authors' authorization. The CDC, reference reports and raw simulation evidence are not included.
