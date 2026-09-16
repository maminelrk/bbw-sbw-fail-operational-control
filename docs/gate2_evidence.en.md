# Gate 2 evidence handling

[Français](gate2_evidence.fr.md)

The numerical reference is the corrected MATLAB run of **15 September 2026, 23:33:46 UTC**, status `READY_FOR_SUPERVISOR_REVIEW`. It passed 36 unit tests, 3 allocator-free plant cases, 4 steering benches, 5 integrated maneuvers and the timestep comparison. Supervisor approval and Gate 3 remain separate.

## Completed local package

The original corrected archive (88 files), native MATLAB light archive (94 files), seven numerical-source hashes and all 42 copied raw files were verified locally. The final evidence comprises **46 bilingual figures and two 17-page LaTeX reports** under ignored directories. Because native MATLAB layout titles remained pale, the final reports use Matplotlib solely to plot the unchanged MATLAB CSV samples, with both engines identified in every figure footer. No substitute simulation, resampling or smoothing was performed. The native export is retained separately. A later native title-property fix is statically checked but has not been rerun in MATLAB; its archived earlier version remains traceable.

The local report index is `reports/gate2_validation/README.en.md`; final figures are under `validation/results/gate2_presentation_20260915_233346/`. The verification record is `validation/results/gate2_local_verification.json`. These files are intentionally not published.

## Three distinct records

1. **Failed baseline:** 19:04:40 UTC, retained for diagnosis; never relabelled as passing.
2. **Corrected raw evidence:** `gate2_corrected_20260915_233346.zip`, including MAT/CSV results, original run manifest, console, solver diagnostic and seven-file tested source snapshot.
3. **Presentation package:** a new directory with light-background bilingual figures, byte-identical raw evidence, `presentation_manifest.json` and `rendering_source/`. It is a re-export, not another numerical campaign.

The original run used base commit `a775806` plus seven corrected files subsequently committed in `c37a749`. Keep the original dirty-working-tree metadata; use `saturation_fix_source_manifest.json` to identify the tested correction. A later plotting-only change does not change the identity of that numerical run.

## Re-export without rerunning

With the project and `validation` folders on the MATLAB path:

```matlab
addpath(pwd,fullfile(pwd,'validation'));
sourceRoot = '/absolute/path/to/original/validation/results';
outputRoot = '/absolute/path/to/new/gate2_presentation';
presentation = reexport_gate2_evidence(sourceRoot,outputRoot);
```

The source must contain `gate2`, `plant`, `gate2_corrected_console.txt`, `gate2_corrected_extra.mat`, `saturation_fix_source_manifest.json`, `saturation_fix_v7.zip` and `solver_diagnostic_v6`. The source manifest must record a passing run. The destination must not exist or overlap the source.

The helper reads existing MAT/CSV files and exports **46 PNGs: 20 integrated, 18 plant and 8 steering**, evenly split between French and English. It verifies every copied non-PNG file against its original SHA-256 before writing the presentation manifest. Original numerical files and acceptance thresholds are not edited. A failed export can leave a partial destination: inspect it and retry in a new directory rather than treating it as a completed package.

`style_report_figure` explicitly sets white backgrounds, dark labels and a print-safe line palette. The normal validation runners use the same plotting functions for future campaigns. Do not rerun `run_gate2_validation` in the historical evidence directory merely to repair figures: that runner overwrites its numerical outputs.

## Review checklist

- Verify archive integrity and extracted-file hashes.
- Match the seven source hashes to the archived correction and local source.
- Check all CSV pass/fail flags, not just the aggregate status.
- Recalculate saturation yaw, release force and minimum speed from its time series.
- Compare copied raw-file hashes with both the original download and presentation manifest.
- Visually inspect figures and both language versions of the final report.
- Keep reports, governing documents and generated evidence in ignored directories; never upload them to the public repository.

The internship report must distinguish simulation consistency from physical validation, nominal checks from dynamic fault validation, and numerical readiness from supervisor acceptance.
