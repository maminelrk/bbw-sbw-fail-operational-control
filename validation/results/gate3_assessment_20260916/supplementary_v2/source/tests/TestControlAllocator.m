classdef TestControlAllocator < matlab.unittest.TestCase
    % Automated unit tests for nominal and faulted allocation behavior.

    properties
        ProjectRoot
        OriginalPath
    end

    methods (TestMethodSetup)
        function addProjectToPath(testCase)
            testCase.ProjectRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.OriginalPath = path;
            addpath(testCase.ProjectRoot);
        end
    end

    methods (TestMethodTeardown)
        function removeProjectFromPath(testCase)
            path(testCase.OriginalPath);
        end
    end

    methods (Test)
        function feasibleDemandTracks(testCase)
            [u, exitflag, info] = allocator([-6000; 0], 0);
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(info.achieved, [-6000; 0], 'AbsTol', 60);
            testCase.verifyLessThanOrEqual(max(u(1:4)), 1e-8);
        end

        function overDemandReturnsBestEffort(testCase)
            p = get_params();
            maximumBraking = p.mu*sum(static_corner_loads(p));
            [u, exitflag, info] = allocator([-1e6; 0], 0);

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyLessThan(sum(u(1:4)), -0.95*maximumBraking);
            testCase.verifyLessThan(info.achieved(1), 0);
            testCase.verifyNotEqual(u, zeros(5,1));
        end

        function namedMasksRemoveCorrectEffectors(testCase)
            expected = [0 1 1 1 1;1 0 1 1 1;1 1 0 1 1;1 1 1 0 1;1 1 1 1 0;1 1 1 1 0];
            names = ["brake_fl_loss", "brake_fr_loss", "brake_rl_loss", ...
                     "brake_rr_loss", "steering_loss"];

            for index = 1:numel(names)
                actual = fault_scenario_mask(names(index));
                testCase.verifyEqual(logical(actual), logical(expected(:,index)));
            end
        end

        function failedBrakeReceivesZeroCommand(testCase)
            mask = fault_scenario_mask('brake_fl_loss');
            [u, exitflag] = allocator([-6000; 0], 0, [], mask);
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(u(1), 0, 'AbsTol', 1e-10);
            testCase.verifyLessThan(sum(u(2:4)), -1000);
        end

        function steeringLossUsesDifferentialBraking(testCase)
            mask = fault_scenario_mask('steering_loss');
            [u, exitflag, info] = allocator([-3000; 800], 0, [], mask);

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(u(5), 0, 'AbsTol', 1e-10);
            leftForce = u(1) + u(3);
            rightForce = u(2) + u(4);
            testCase.verifyGreaterThan(abs(rightForce-leftForce), 100);
            testCase.verifyEqual(info.achieved, [-3000; 800], 'AbsTol', 30);
        end

        function allocatorRateBoundsHold(testCase)
            p = get_params();
            dt = 0.002;
            u = allocator([-6000; 800], 0, [], ones(5,1), zeros(5,1), dt);

            testCase.verifyLessThanOrEqual(abs(u(1:4)), ...
                repmat(p.Fx_rate*dt+1e-6,4,1));
            testCase.verifyLessThanOrEqual(abs(u(5)), p.delta_rate*dt+1e-9);
        end

        function staticResidualAuthorityMeetsBaseline(testCase)
            authority = control_authority_report();
            testCase.verifyGreaterThanOrEqual( ...
                authority.worst_single_corner_brake_ratio, 0.60);
            testCase.verifyGreaterThanOrEqual( ...
                authority.steering_loss_yaw_ratio, 0.15);
        end
    end
end
