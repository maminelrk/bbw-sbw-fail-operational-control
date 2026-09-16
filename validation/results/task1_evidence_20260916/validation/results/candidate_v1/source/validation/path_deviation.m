function [lateral,covered] = path_deviation(faulted,nominal)
% Compare paths at equal travelled distance, not equal clock time.
sn=[0;cumsum(hypot(diff(nominal.X_m),diff(nominal.Y_m)))];
sf=[0;cumsum(hypot(diff(faulted.X_m),diff(faulted.Y_m)))];
[sn,uniqueIndex]=unique(sn,'stable');
assert(numel(sn)>1,'path_deviation:Reference','Reference must travel.');
covered=all(sf<=sn(end)+1e-8);
query=min(sf,sn(end));
xn=interp1(sn,nominal.X_m(uniqueIndex),query);
yn=interp1(sn,nominal.Y_m(uniqueIndex),query);
heading=interp1(sn,unwrap(nominal.Psi_rad(uniqueIndex)),query);
lateral=-(faulted.X_m-xn).*sin(heading)+(faulted.Y_m-yn).*cos(heading);
lateral(sf>sn(end)+1e-8)=NaN; % No extrapolation masquerading as evidence.
end
