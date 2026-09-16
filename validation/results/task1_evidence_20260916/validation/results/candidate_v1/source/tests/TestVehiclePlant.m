classdef TestVehiclePlant < matlab.unittest.TestCase
    % Allocator-free unit tests for vehicle plant equations.

    methods (Test)
        function parameterSetIsInternallyConsistent(testCase)
            p = get_params();
            testCase.verifyEqual(p.L,p.lf+p.lr,'AbsTol',1e-12);
            testCase.verifyEqual(p.wf,p.lr/p.L,'AbsTol',1e-12);
            testCase.verifyEqual(p.Cf,66000,'AbsTol',1e-9);
            testCase.verifyEqual(p.Cr,66000,'AbsTol',1e-9);
            testCase.verifyEqual(p.reference_speed,60/3.6,'AbsTol',1e-12);
        end

        function straightCoastIsAnEquilibrium(testCase)
            p = get_params();
            x = zeros(11,1);
            x(1) = p.reference_speed;
            dx = vehicle_derivatives_block(x,0,zeros(4,1));
            testCase.verifyEqual(dx(1:3),zeros(3,1),'AbsTol',1e-12);
            testCase.verifyEqual(dx(4),p.reference_speed,'AbsTol',1e-12);
            testCase.verifyEqual(dx(5:11),zeros(7,1),'AbsTol',1e-12);
        end

        function symmetricBrakingCreatesNoYaw(testCase)
            p = get_params();
            x = zeros(11,1);
            x(1) = p.reference_speed;
            x(8:11) = -1000;
            q = vehicle_dynamics_quantities(x,p);
            dx = vehicle_derivatives_block(x,0,-1000*ones(4,1));
            testCase.verifyLessThan(dx(1),0);
            testCase.verifyEqual(q.Mz_differential_brake,0,'AbsTol',1e-12);
            testCase.verifyEqual(dx(3),0,'AbsTol',1e-12);
        end

        function brakingTransfersLoadForward(testCase)
            p = get_params();
            x = zeros(11,1);
            x(1) = p.reference_speed;
            x(8:11) = -1000;
            q = vehicle_dynamics_quantities(x,p);
            staticLoads = static_corner_loads(p);
            testCase.verifyGreaterThan(q.front_normal_load,sum(staticLoads(1:2)));
            testCase.verifyLessThan(q.rear_normal_load,sum(staticLoads(3:4)));
            testCase.verifyEqual(sum(q.Fz),p.m*p.g,'RelTol',1e-12);
        end

        function steeringSignsMirror(testCase)
            p = get_params();
            xPositive = zeros(11,1);
            xPositive(1) = p.reference_speed;
            xPositive(7) = deg2rad(1);
            xNegative = xPositive;
            xNegative(7) = -xPositive(7);
            dxPositive = vehicle_derivatives_block(xPositive,xPositive(7),zeros(4,1));
            dxNegative = vehicle_derivatives_block(xNegative,xNegative(7),zeros(4,1));
            testCase.verifyGreaterThan(dxPositive(2),0);
            testCase.verifyGreaterThan(dxPositive(3),0);
            testCase.verifyEqual(dxPositive(2),-dxNegative(2),'RelTol',1e-12);
            testCase.verifyEqual(dxPositive(3),-dxNegative(3),'RelTol',1e-12);
        end

        function frictionEllipseBoundsLateralForce(testCase)
            p = get_params();
            xFree = zeros(11,1);
            xFree(1) = p.reference_speed;
            xFree(7) = deg2rad(3);
            xBraking = xFree;
            xBraking(8:11) = -1000;
            qFree = vehicle_dynamics_quantities(xFree,p);
            qBraking = vehicle_dynamics_quantities(xBraking,p);
            testCase.verifyLessThanOrEqual(abs(qBraking.Fyf), ...
                qBraking.front_lateral_capacity+1e-9);
            testCase.verifyLessThanOrEqual(abs(qBraking.Fyr), ...
                qBraking.rear_lateral_capacity+1e-9);
            testCase.verifyLessThan(qBraking.front_lateral_capacity, ...
                p.mu*qBraking.front_normal_load);
            testCase.verifyLessThan(qBraking.rear_lateral_capacity, ...
                p.mu*qBraking.rear_normal_load);
            testCase.verifyLessThan(qBraking.front_lateral_capacity, ...
                p.mu*qFree.front_normal_load*1.20);
        end
    end
end
