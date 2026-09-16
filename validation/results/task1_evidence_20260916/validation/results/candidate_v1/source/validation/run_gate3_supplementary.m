function manifest = run_gate3_supplementary(baseline,folder)
% Reproducible supplementary evidence, preserving every earlier campaign.
% Preuves complémentaires reproductibles, sans écraser les campagnes antérieures.
root=fileparts(fileparts(mfilename('fullpath')));
assert(~isfolder(folder),'Preserve existing supplementary evidence.'); mkdir(folder);
old=get(groot,'DefaultFigureCreateFcn');
cleanup=onCleanup(@() restore(old)); %#ok<NASGU>
set(groot,'DefaultFigureCreateFcn',@(f,e)set(f,'Theme','light'));
diary(fullfile(folder,'execution.log')); started=datetime('now','TimeZone','UTC');
manifest=struct('Protocol','G3-AUTH-ENV-01','StartedUTC',char(started), ...
    'MATLABVersion',version,'BaselineFolder',baseline,'SourceRoot',root, ...
    'SearchRevision','interior-contact-0.999-with-seed-retention', ...
    'Gate3Closed',false,'Completed',false,'Error','');
try
    files=[dir(fullfile(root,'*.m'));dir(fullfile(root,'validation','*.m'));dir(fullfile(root,'tests','*.m'))];
    hashes=cell(numel(files),1);
    for k=1:numel(files)
        file=fullfile(files(k).folder,files(k).name); relative=extractAfter(file,strlength(root)+1);
        target=fullfile(folder,'source',relative); parent=fileparts(target);
        if ~isfolder(parent), mkdir(parent); end
        copyfile(file,target);
        fid=fopen(file,'r'); bytes=fread(fid,Inf,'*uint8'); fclose(fid);
        md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
        hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
        hashes{k}=table(string(relative),string(hash),'VariableNames',{'File','SHA256'});
    end
    writetable(vertcat(hashes{:}),fullfile(folder,'source_hashes.csv'));
    tests=runtests(fullfile(root,'tests')); testTable=table(string({tests.Name})',[tests.Passed]', ...
        [tests.Failed]',[tests.Incomplete]','VariableNames',{'Name','Passed','Failed','Incomplete'});
    writetable(testTable,fullfile(folder,'unit_tests.csv'));
    assert(all([tests.Passed]),'All unit tests must pass before the campaign.');
    manifest.UnitTestsPassed=sum([tests.Passed]);
    convergence=fullfile(root,'validation','results','convergence');
    assert(isfile(fullfile(convergence,'convergence_summary.csv')),'Complete convergence first.');
    copyfile(convergence,fullfile(folder,'convergence'));
    run_gate3_authority_assessment(baseline,fullfile(folder,'authority'));
    run_gate3_envelope_assessment(baseline,fullfile(folder,'envelope'));
    manifest.Completed=true;
catch failure
    manifest.Error=getReport(failure,'extended','hyperlinks','off');
    disp(manifest.Error);
end
manifest.FinishedUTC=char(datetime('now','TimeZone','UTC'));
fid=fopen(fullfile(folder,'assessment_manifest.json'),'w');
fwrite(fid,jsonencode(manifest,'PrettyPrint',true),'char'); fclose(fid);
diary off;
if manifest.Completed
    archive=fullfile(root,'gate3_assessment_20260916.zip');
    assert(~isfile(archive),'Preserve existing archive.');
    [parent,name]=fileparts(folder); zip(archive,{name},parent);
    fprintf('ASSESSMENT COMPLETE: %s\n',archive);
else
    fprintf('ASSESSMENT STOPPED; preserved evidence and error in %s\n',folder);
end
end

function restore(old)
diary off; set(groot,'DefaultFigureCreateFcn',old);
end
