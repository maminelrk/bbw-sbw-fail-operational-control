function package_gate3_run(root)
% Archive a completed MATLAB run without changing its results or gate status.
% Archive une exécution MATLAB terminée sans modifier les résultats/le jalon.
folder=fullfile(root,'validation','results','gate3');
metadata=jsondecode(fileread(fullfile(folder,'run_manifest.json')));
assert(strcmp(metadata.Status,'PRELIMINARY_EVIDENCE_REVIEW_REQUIRED'));
assert(~metadata.Gate3Closed && ~metadata.AllRequirementsPassed);
summary=readtable(fullfile(folder,'fault_summary.csv'),'TextType','string');
units=readtable(fullfile(folder,'unit_tests.csv'));
assert(height(summary)==30 && height(units)==37 && all(units.Passed & ~units.Incomplete));
cases=gate3_fault_cases();
ids=[string({cases.ID}) "G3-NOM-combined" "G3-NOM-brake" ...
    "G3-NOM-dbbs_positive" "G3-NOM-dbbs_negative"];
for id=ids
    caseFolder=fullfile(folder,id);
    required=["timeseries.csv" "metrics.csv" "result.mat" "response_en.png" ...
        "response_fr.png" "actuators_en.png" "actuators_fr.png"];
    if ~startsWith(id,"G3-NOM")
        required=[required "fault_metrics.csv" "comparison.csv" ...
            "fault_comparison_en.png" "fault_comparison_fr.png"]; %#ok<AGROW>
    end
    for name=required
        item=dir(fullfile(caseFolder,name));
        assert(isscalar(item) && item.bytes>0,'Incomplete evidence: %s / %s',id,name);
    end
end
delta=fullfile(folder,'source_delta');
assert(~isfolder(delta),'Archive packaging already exists; preserve the earlier package.');
mkdir(fullfile(delta,'validation')); mkdir(fullfile(delta,'tests'));
files={'validation/evaluate_fault_result.m','validation/time_grids_match.m', ...
    'tests/TestGate3Preparation.m'};
for k=1:numel(files)
    copyfile(fullfile(root,files{k}),fullfile(delta,files{k}));
end
[status,diffText]=system(sprintf('git -C "%s" diff -- tests/TestGate3Preparation.m validation/evaluate_fault_result.m',root));
assert(status==0); write_text(fullfile(delta,'tracked_changes.patch'),diffText);
[status,hashes]=system(sprintf('cd "%s" && sha256sum validation/evaluate_fault_result.m validation/time_grids_match.m tests/TestGate3Preparation.m',delta));
assert(status==0); write_text(fullfile(delta,'SHA256SUMS.txt'),hashes);
copyfile(mfilename('fullpath')+".m",fullfile(folder,'package_gate3_run.m'));
attempt=fullfile(root,'validation','results','gate3_attempt1_timegrid');
if isfolder(attempt)
    previous=fullfile(attempt,'run_manifest.json');
    backup=fullfile(attempt,'run_manifest.started.json');
    assert(~isfile(backup),'Interrupted-attempt manifest already preserved.');
    interrupted=jsondecode(fileread(previous));
    assert(strcmp(interrupted.Status,'RUNNING'));
    copyfile(previous,backup);
    interrupted.Status='ABORTED_TIME_GRID_ASSERTION';
    interrupted.GitCommit=metadata.GitCommit;
    interrupted.ReasonEN='Exact time-grid equality rejected 8.881784197001252e-16 s roundoff. Not a completed campaign.';
    interrupted.ReasonFR='Une égalité temporelle exacte a rejeté un arrondi de 8,881784197001252e-16 s. Campagne inachevée.';
    interrupted.CorrectedRun='../gate3';
    write_text(previous,jsonencode(interrupted,'PrettyPrint',true));
end
finished=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss'));
noteEN=sprintf(['# Gate 3 MATLAB execution\n\n' ...
    'Packaged UTC: %s. Source base: %s, plus the three files in source_delta.\n\n' ...
    '37 unit tests, 4 nominal references, 30 fault cases. Numerical-check failures: %d. DBBS maneuver failures: %d/8.\n\n' ...
    'This is preliminary simulation evidence, not Gate 3 closure or safety certification. REQ-02 operational-envelope/oracle review, REQ-03 authority and architecture independence remain open.\n\n' ...
    'The initial attempt stopped because exact equality rejected a maximum time-grid difference of 8.881784197001252e-16 s between common samples of 6 s and 7 s records. It is preserved separately as validation/results/gate3_attempt1_timegrid. The corrected run was restarted in full. Only comparison roundoff handling and its regression test changed; controller, plant, sampling and acceptance thresholds did not.\n\n' ...
    'Figures were generated natively in MATLAB using a temporary DefaultFigureCreateFcn that sets Theme=light. The previous callback was restored after execution. French and English exports accompany the raw CSV/MAT data.\n\n' ...
    'To reproduce: use base commit %s, overlay source_delta/validation and source_delta/tests, then run run_gate3_validation in MATLAB with Optimization Toolbox. Generated evidence is excluded from GitHub.\n'], ...
    finished,metadata.GitCommit,metadata.NumericalFailureCount,metadata.DBBSManeuverFailureCount,metadata.GitCommit);
noteFR=sprintf(['# Exécution MATLAB Gate 3\n\n' ...
    'Archivage UTC : %s. Base du code : %s, complétée par les trois fichiers de source_delta.\n\n' ...
    '37 tests unitaires, 4 références nominales, 30 cas de panne. Échecs des contrôles numériques : %d. Échecs de la manœuvre DBBS : %d/8.\n\n' ...
    'Preuves préliminaires de simulation : ni clôture Gate 3 ni certification de sécurité. La revue enveloppe/oracle REQ-02, les autorités REQ-03 et l''indépendance architecturale restent ouvertes.\n\n' ...
    'La première tentative a été arrêtée par une égalité exacte rejetant un écart temporel maximal de 8,881784197001252e-16 s entre les échantillons communs des enregistrements de 6 s et 7 s. Elle est conservée séparément dans validation/results/gate3_attempt1_timegrid. L''exécution corrigée a été entièrement relancée. Seuls le traitement de l''arrondi de comparaison et son test de régression ont changé ; commande, véhicule, échantillonnage et seuils sont inchangés.\n\n' ...
    'Les figures sont natives MATLAB avec un DefaultFigureCreateFcn temporaire imposant Theme=light. Le rappel précédent a été rétabli après exécution. Les exports français/anglais accompagnent les données CSV/MAT brutes.\n\n' ...
    'Reproduction : utiliser le commit de base %s, appliquer source_delta/validation et source_delta/tests, puis exécuter run_gate3_validation sous MATLAB avec Optimization Toolbox. Les preuves générées sont exclues de GitHub.\n'], ...
    finished,metadata.GitCommit,metadata.NumericalFailureCount,metadata.DBBSManeuverFailureCount,metadata.GitCommit);
write_text(fullfile(folder,'README.en.md'),noteEN);
write_text(fullfile(folder,'README.fr.md'),noteFR);
archive='/MATLAB Drive/gate3_matlab_20260916_timegrid_v1.zip';
assert(~isfile(archive),'Archive already exists; do not overwrite evidence.');
zip(archive,{'gate3'},fullfile(root,'validation','results'));
[status,archiveHash]=system(sprintf('sha256sum "%s"',archive)); assert(status==0);
disp(summary(:,{'ScenarioID','NumericalChecksPass','MaskPass','RecoveryDiagnosticPass', ...
    'ContinuityDiagnosticPass','IsDBBS','DBBSManeuverPass'}));
disp(summary(summary.IsDBBS,{'ScenarioID','PostFaultYawRMSE_radps', ...
    'PeakPathDeviation_m','PeakDeceleration_g','HeldAngle_deg'}));
disp(hashes); disp(archiveHash); disp(archive);
end

function write_text(filename,text)
fid=fopen(filename,'w','n','UTF-8'); assert(fid>=0);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',text);
end
