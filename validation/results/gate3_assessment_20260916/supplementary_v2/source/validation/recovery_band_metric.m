function metric = recovery_band_metric(time,errorSignal,flagTime,deadline,dwell)
% First sampled entry into <=0.10 band sustained for the ENTIRE dwell.
% Missing/nonfinite samples or insufficient end-of-record time cannot pass.
time=time(:); errorSignal=errorSignal(:);
assert(numel(time)==numel(errorSignal) && all(diff(time)>0));
entry=NaN;
for k=find(time>=flagTime-1e-12)'
    stop=find(time>=time(k)+dwell-1e-12,1);
    if isempty(stop), break; end
    band=errorSignal(k:stop);
    if all(isfinite(band) & band<=0.10)
        entry=time(k)-flagTime; break;
    end
end
metric=struct('EntryDelay_s',entry,'Deadline_s',deadline,'Dwell_s',dwell, ...
    'DiagnosticPass',isfinite(entry) && entry<=deadline+1e-12);
end
