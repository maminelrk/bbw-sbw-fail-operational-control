function [demand,tau]=motion_demand(ref,state,known,p)
% Body acceleration and yaw tracking, scheduled by diagnosed steering health.
% Suivi accélération/lacet, réglé selon l'état diagnostiqué de la direction.
% The external reference is unchanged. No future fault or nominal-run data.
if nargin<4 || isempty(p), p=get_params(); end
channels=normalize_actuator_mask(known);
tau=p.yaw_tracking_tau;
if all(channels(5:6)==0), tau=p.dbbs_yaw_tracking_tau; end
demand=[p.m*(ref.ax-state(2)*state(3)); ...
    p.Iz*(ref.yaw_dot+(ref.yaw-state(3))/tau)];
end
