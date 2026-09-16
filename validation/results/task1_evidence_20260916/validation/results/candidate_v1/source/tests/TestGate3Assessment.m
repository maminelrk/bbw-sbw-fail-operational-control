classdef TestGate3Assessment < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addPaths(testCase)
            root=fileparts(fileparts(mfilename('fullpath'))); oldPath=path;
            addpath(root,fullfile(root,'validation'));
            testCase.addTeardown(@() path(oldPath));
        end
    end
    methods (Test)
        function defaultSubstepsRetainOriginalSampling(testCase)
            catalog=gate2_maneuvers(); s=catalog(1); s.Duration=.02;
            a=run_integrated_maneuver(s,[],.002);
            b=run_integrated_maneuver(s,[],.002,[],1);
            testCase.verifyEqual(a.series,b.series);
            c=run_integrated_maneuver(s,[],.002,[],2);
            testCase.verifyEqual(c.series.Time_s,a.series.Time_s);
            testCase.verifyEqual(c.integration_substeps,2);
            testCase.verifyEqual(c.dt,.002);
        end
        function centeredDBBSWitnessObeysCoupledBound(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            mask=[1;1;1;1;0;0];
            a=nonlinear_authority_point(x,mask,struct('Mode',"yaw",'Starts',4),p);
            testCase.verifyTrue(a.Feasible);
            testCase.verifyEqual(a.State(7),0,'AbsTol',1e-12);
            testCase.verifyLessThanOrEqual(abs(a.Output(2)),p.tw/2*(-a.Output(1))+1e-4);
            testCase.verifyLessThanOrEqual(-a.Output(1),p.mu*p.m*p.g+1e-4);
            testCase.verifyFalse(a.GlobalOptimalityProven);
        end
        function failedBrakeHasZeroWitnessForce(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            a=nonlinear_authority_point(x,[0;1;1;1;1;1], ...
                struct('Mode',"match",'Target',[-1000;0],'Starts',4),p);
            testCase.verifyTrue(a.Feasible);
            testCase.verifyEqual(a.State(8),0,'AbsTol',1e-8);
            testCase.verifyLessThanOrEqual(a.Violation,1e-7);
        end
        function zeroWitnessRolloutRemainsAtRestInActuators(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            a=struct('State',x);
            r=authority_rollout(x,zeros(5,1),a,ones(6,1),zeros(2,1),p);
            testCase.verifyTrue(r.PhysicalAndCommandChecksPass);
            testCase.verifyEqual(r.Outputs,zeros(26,2),'AbsTol',1e-12);
            testCase.verifyEqual(r.EndpointNormalizedError,0,'AbsTol',1e-12);
        end
    end
end
