function presentation=reexport_gate2_evidence(sourceRoot,outputRoot)
%REEXPORT_GATE2_EVIDENCE Copy and restyle existing Gate 2 evidence only.
% Copie et remise en forme des preuves existantes, sans nouvelle simulation.
% Refuses an existing output directory and checks every copied raw file hash.
% Refuse un dossier de sortie existant et vérifie chaque fichier brut copié.
% Java's process directory may differ from MATLAB's current folder online.
if ~java.io.File(sourceRoot).isAbsolute(), sourceRoot=fullfile(pwd,sourceRoot); end
if ~java.io.File(outputRoot).isAbsolute(), outputRoot=fullfile(pwd,outputRoot); end
sourceRoot=char(java.io.File(sourceRoot).getCanonicalPath());
outputRoot=char(java.io.File(outputRoot).getCanonicalPath());
assert(isfolder(sourceRoot),'Gate2Evidence:Source','Source directory is missing.');
assert(~isfolder(outputRoot) && ~isfile(outputRoot), ...
    'Gate2Evidence:Exists','Output must be a new directory.');
assert(~startsWith([outputRoot filesep],[sourceRoot filesep]) && ...
    ~startsWith([sourceRoot filesep],[outputRoot filesep]), ...
    'Gate2Evidence:Overlap','Source and output directories must not overlap.');
runManifest=jsondecode(fileread(fullfile(sourceRoot,'gate2','run_manifest.json')));
assert(runManifest.AllChecksPassed && strcmp(runManifest.Status,'READY_FOR_SUPERVISOR_REVIEW'), ...
    'Gate2Evidence:Status','This presentation package requires a passing source run.');
groups={'gate2','plant','gate2_corrected_console.txt','gate2_corrected_extra.mat', ...
    'saturation_fix_source_manifest.json','saturation_fix_v7.zip','solver_diagnostic_v6'};
for k=1:numel(groups)
    assert(isfile(fullfile(sourceRoot,groups{k})) || isfolder(fullfile(sourceRoot,groups{k})), ...
        'Gate2Evidence:Missing','Missing source evidence: %s',groups{k});
end
raw=struct('Path',{},'SHA256',{});
for k=1:numel(groups)
    item=fullfile(sourceRoot,groups{k});
    if isfolder(item), entries=dir(fullfile(item,'**','*')); else, entries=dir(item); end
    for j=1:numel(entries)
        if entries(j).isdir, continue; end
        [~,~,ext]=fileparts(entries(j).name);
        if strcmpi(ext,'.png'), continue; end
        file=fullfile(entries(j).folder,entries(j).name);
        relative=file(numel(sourceRoot)+2:end);
        raw(end+1)=struct('Path',strrep(relative,filesep,'/'),'SHA256',sha256(file)); %#ok<AGROW>
    end
end
mkdir(outputRoot);
for k=1:numel(groups), copyfile(fullfile(sourceRoot,groups{k}),fullfile(outputRoot,groups{k})); end
cases=dir(fullfile(sourceRoot,'gate2','G2-*','result.mat'));
assert(numel(cases)==5,'Gate2Evidence:Cases','Expected five integrated cases.');
for k=1:numel(cases)
    saved=load(fullfile(cases(k).folder,cases(k).name),'result');
    plot_integrated_result(saved.result,fullfile(outputRoot,'gate2',saved.result.scenario.ID));
end
cases=dir(fullfile(sourceRoot,'plant','PLANT-*','result.mat'));
assert(numel(cases)==3,'Gate2Evidence:PlantCases','Expected three plant cases.');
for k=1:numel(cases)
    saved=load(fullfile(cases(k).folder,cases(k).name),'series','scenario');
    plot_plant_result(saved.series,saved.scenario,fullfile(outputRoot,'plant',saved.scenario.ScenarioID));
end
for name=["nominal","steering_a_loss","steering_b_loss","steering_loss"]
    s=readtable(fullfile(sourceRoot,'gate2','steering',name+".csv"));
    plot_steering_result(s,name,fullfile(outputRoot,'gate2','steering'));
end
for k=1:numel(raw)
    assert(strcmp(raw(k).SHA256,sha256(fullfile(sourceRoot,raw(k).Path))), ...
        'Gate2Evidence:SourceChanged','Original raw evidence changed: %s',raw(k).Path);
    assert(strcmp(raw(k).SHA256,sha256(fullfile(outputRoot,raw(k).Path))), ...
        'Gate2Evidence:CopyChanged','Copied raw evidence differs: %s',raw(k).Path);
end
figures=[dir(fullfile(outputRoot,'gate2','**','*.png')); ...
    dir(fullfile(outputRoot,'plant','**','*.png'))];
assert(numel(figures)==46,'Gate2Evidence:Figures','Expected 46 bilingual PNG figures.');
presentation=struct('Kind','PRESENTATION_ONLY_REEXPORT','SimulationRerun',false, ...
    'CreatedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z''')), ...
    'SourceRoot',sourceRoot,'OutputRoot',outputRoot,'FigureCount',numel(figures), ...
    'OriginalRunStartedUTC',runManifest.StartedUTC,'OriginalRunStatus',runManifest.Status, ...
    'RawFilesUnchanged',true,'RawFiles',raw);
helpers={'reexport_gate2_evidence','style_report_figure','plot_integrated_result', ...
    'plot_plant_result','plot_steering_result'};
presentation.RenderingSources=struct('File',{},'SHA256',{});
mkdir(fullfile(outputRoot,'rendering_source'));
for k=1:numel(helpers)
    file=which(helpers{k});
    copyfile(file,fullfile(outputRoot,'rendering_source',[helpers{k} '.m']));
    presentation.RenderingSources(k)=struct('File',[helpers{k} '.m'],'SHA256',sha256(file));
end
fid=fopen(fullfile(outputRoot,'presentation_manifest.json'),'w');
assert(fid>=0,'Gate2Evidence:Write','Cannot create presentation manifest.');
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(presentation));
disp('GATE 2: 46 figures re-exported; original and copied raw files SHA-256 verified.');
end

function hash=sha256(file)
fid=fopen(file,'rb'); assert(fid>=0,'Gate2Evidence:Read','Cannot read %s',file);
cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid), digest.update(fread(fid,1048576,'*uint8')); end
bytes=typecast(digest.digest(),'uint8');
hash=lower(reshape(dec2hex(bytes,2).',1,[]));
end
