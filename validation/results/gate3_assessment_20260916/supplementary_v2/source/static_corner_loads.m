function Fz = static_corner_loads(p)
% Static (no load-transfer) vertical load at each corner: [FL FR RL RR]
Fzf_total = p.m*p.g*p.wf;
Fzr_total = p.m*p.g*(1-p.wf);
Fz = [Fzf_total/2, Fzf_total/2, Fzr_total/2, Fzr_total/2];
end
