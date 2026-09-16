function ref = maneuver_reference(t,scenario,p)
% Cubic smooth-step ramps have zero endpoint slope; derivatives are analytic.
ax=0; yaw=0; yawDot=0;
switch scenario.Profile
    case "brake"
        ax=-0.20*p.g*pulse(t,0.5,1.0,3.5,0.75);
    case "steer"
        bicycle=linear_bicycle_reference(scenario.InitialSpeed,deg2rad(1),p);
        [w,dw]=pulse(t,0.5,0.30,4.0,0.50);
        yaw=bicycle.yaw_rate*w; yawDot=bicycle.yaw_rate*dw;
    case "combined"
        ax=-0.12*p.g*pulse(t,0.5,0.75,3.5,0.75);
        [w,dw]=pulse(t,1.0,0.5,4.0,0.5);
        yaw=0.06*w; yawDot=0.06*dw;
    case "yaw"
        if t>=0.5 && t<=5.5
            s=(t-0.5)/5;
            % A sin^2 window removes the endpoint derivative discontinuity.
            yaw=0.08*sin(2*pi*s)*sin(pi*s)^2;
            yawDot=0.08/5*(2*pi*cos(2*pi*s)*sin(pi*s)^2+ ...
                2*pi*sin(2*pi*s)*sin(pi*s)*cos(pi*s));
        end
    case "saturation"
        ax=-1.2*p.mu*p.g*pulse(t,0.5,0.75,2.0,0.75);
    case "dbbs"
        direction=1; if isfield(scenario,'YawSign'), direction=scenario.YawSign; end
        [w,dw]=pulse(t,1.5,1.0,4.5,1.0);
        yaw=direction*0.15*w; yawDot=direction*0.15*dw;
    otherwise
        error('maneuver_reference:Profile','Unknown profile.');
end
ref=struct('ax',ax,'yaw',yaw,'yaw_dot',yawDot);
end

function [w,dw]=pulse(t,on,rise,off,fall)
[a,da]=ramp(t,on,rise); [b,db]=ramp(t,off,fall);
w=a-b; dw=da-db;
end
function [w,dw]=ramp(t,start,duration)
s=(t-start)/duration;
if s<=0, w=0; dw=0;
elseif s>=1, w=1; dw=0;
else, w=s*s*(3-2*s); dw=6*s*(1-s)/duration;
end
end
