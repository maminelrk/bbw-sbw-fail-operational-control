function matches = time_grids_match(first,second)
% Allow only floating-point roundoff, never a shifted/resampled time grid.
% Tolère uniquement l'arrondi flottant, jamais un décalage/rééchantillonnage.
first=first(:); second=second(:);
matches=false;
if isempty(first) || numel(first)~=numel(second) || ...
        any(~isfinite([first;second])) || any(diff(first)<=0) || any(diff(second)<=0)
    return;
end
tolerance=64*eps(max(1,max(abs([first;second]))));
matches=all(abs(first-second)<=tolerance);
end
