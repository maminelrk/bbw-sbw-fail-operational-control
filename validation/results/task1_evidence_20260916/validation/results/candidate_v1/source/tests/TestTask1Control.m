classdef TestTask1Control < matlab.unittest.TestCase
    % Regression checks / vérifications de non-régression Task 1.
    methods (TestClassSetup)
        function addPaths(testCase)
            root=fileparts(fileparts(mfilename('fullpath'))); oldPath=path;
            addpath(root,fullfile(root,'validation'));
            testCase.addTeardown(@() path(oldPath));
        end
    end
    methods (Test)
        function dbbsGainUsesKnownHealthAndUnchangedReference(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed; x(3)=.05;
            ref=struct('ax',0,'yaw',.15,'yaw_dot',.02);
            [before,tau]=motion_demand(ref,x,ones(6,1),p);
            testCase.verifyEqual(tau,p.yaw_tracking_tau);
            for name=["steering_a_loss" "steering_b_loss"]
                testCase.verifyEqual(motion_demand(ref,x,fault_scenario_mask(name),p),before);
            end
            [after,tau]=motion_demand(ref,x,fault_scenario_mask('steering_loss'),p);
            testCase.verifyEqual(tau,p.dbbs_yaw_tracking_tau);
            testCase.verifyEqual(after(1),before(1));
            testCase.verifyEqual(after(2),p.Iz*(.02+.10/p.dbbs_yaw_tracking_tau),'AbsTol',1e-10);
        end
        function optionalParametersRetainDefaultBehavior(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            a=allocator([-2000;100],0,[],[],zeros(5,1),.002,x);
            b=allocator([-2000;100],0,[],[],zeros(5,1),.002,x,p);
            testCase.verifyEqual(a,b,'AbsTol',1e-10);
        end
        function reserveAppliesOnlyToFrontBrakeLoss(testCase)
            p=get_params(); p.fault_rear_friction_fraction=.92;
            x=zeros(13,1); x(1)=p.reference_speed;
            for name=["nominal" "brake_fl_loss" "brake_fr_loss" "brake_rl_loss" "steering_loss"]
                mask=fault_scenario_mask(name);
                [~,flag,info]=allocator([-10000;0],0,[],mask,[],[],x,p);
                fraction=p.allocation_friction_fraction;
                if any(name==["brake_fl_loss" "brake_fr_loss"]), fraction=.92; end
                testCase.verifyGreaterThan(flag,0);
                testCase.verifyEqual(info.allocation_lower_bounds(3:4), ...
                    fraction*info.physical_lower_bounds(3:4),'AbsTol',1e-8);
            end
        end
        function newReserveDoesNotOverrideHealthyReleaseRate(testCase)
            p=get_params(); p.fault_rear_friction_fraction=.88;
            x=zeros(13,1); x(1)=p.reference_speed;
            mask=fault_scenario_mask('brake_fl_loss');
            q=vehicle_dynamics_quantities(x,p,mask);
            previous=[-.98*p.mu*q.Fz;0]; previous(1)=0;
            [u,flag,info]=allocator([-15000;0],0,[],mask,previous,.002,x,p);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyFalse(info.rate_override);
            testCase.verifyLessThanOrEqual(abs(u(2:4)-previous(2:4)),p.Fx_rate*.002+1e-6);
            testCase.verifyGreaterThanOrEqual(u,info.physical_lower_bounds-1e-8);
            testCase.verifyEqual(u(1),0,'AbsTol',1e-10);
        end
    end
end
