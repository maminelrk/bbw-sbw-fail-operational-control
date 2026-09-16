classdef TestAllocatorSaturation < matlab.unittest.TestCase
    % Regression for the MATLAB Online failure at commit a775806.
    methods (TestClassSetup)
        function projectPath(testCase)
            root=fileparts(fileparts(mfilename('fullpath'))); previous=path;
            addpath(root,fullfile(root,'validation'));
            testCase.addTeardown(@() path(previous));
        end
    end
    methods (Test)
        function saturatedSymmetricRequestKeepsSymmetricCommands(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            [u,flag,info]=allocator([-1.2*p.mu*p.m*p.g;0],0,[],ones(6,1),[],[],x);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyEqual(u([1 3]),u([2 4]),'AbsTol',1e-6);
            testCase.verifyEqual(u(5),0,'AbsTol',1e-9);
            testCase.verifyEqual(info.allocation_lower_bounds(1:4), ...
                p.allocation_friction_fraction*info.physical_lower_bounds(1:4),'AbsTol',1e-10);
            testCase.verifyGreaterThanOrEqual(u(1:4),info.allocation_lower_bounds(1:4)-1e-8);
        end
        function saturatedBrakeColumnsKeepContactForceGeometry(testCase)
            p=get_params(); x=zeros(13,1); x(1)=10;
            x(2)=0.02; x(3)=0.01; x(7)=-0.13;
            % Deliberately clipped actuator states reproduce the problematic
            % boundary; contact-force effectiveness must not be differentiated
            % through these states and their algebraic load transfer.
            x(8:11)=[-6000;-6000;-1300;-1300];
            [~,flag,info]=allocator([0;0],x(7),[],ones(6,1),[],[],x);
            c=cos(x(7)); s=sin(x(7));
            expected=[c c 1 1; p.lf*s-p.tw*c/2 p.lf*s+p.tw*c/2 -p.tw/2 p.tw/2];
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyEqual(info.B(:,1:4),expected,'AbsTol',1e-12);
            testCase.verifyEqual(info.B(1,5),0,'AbsTol',1e-12);
            q=vehicle_dynamics_quantities(x,p);
            testCase.verifyEqual(info.offset+info.B*[q.Fx_actual;x(7)], ...
                [q.Fx_total;q.Mz_total],'AbsTol',1e-8);
        end
        function failedBrakeStillHasNoEffectiveness(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            [u,flag,info]=allocator([-2000;200],0,[],fault_scenario_mask('brake_fl_loss'),[],[],x);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyEqual(info.B(:,1),zeros(2,1));
            testCase.verifyEqual(u(1),0,'AbsTol',1e-10);
        end
        function smallAsymmetryDoesNotPreventSaturationRelease(testCase)
            cases=gate2_maneuvers(); scenario=cases(5);
            for direction=[-1 1]
                state=zeros(13,1); state(1)=scenario.InitialSpeed;
                state(2)=direction*1e-5; state(3)=direction*1e-6;
                state(7)=direction*1e-7;
                corner=1; if direction<0, corner=2; end
                state(7+corner)=-0.1;
                scenario.InitialState=state;
                out=run_integrated_maneuver(scenario,[]);
                % The original unmodified capacity, release, yaw and physical
                % acceptance criteria apply to both perturbed initial states.
                testCase.verifyTrue(out.metrics.OverallPass);
                testCase.verifyLessThan(max(abs(out.series.YawRate_radps)),1e-4);
                testCase.verifyLessThan(max(abs(out.series.FxActual_N(out.series.Time_s>=3.2))),100);
            end
        end
        function invalidInitialStateIsRejected(testCase)
            cases=gate2_maneuvers(); scenario=cases(5); scenario.InitialState=zeros(12,1);
            testCase.verifyError(@() run_integrated_maneuver(scenario,[]), ...
                'run_integrated_maneuver:InitialState');
        end
    end
end
