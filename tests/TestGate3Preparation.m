classdef TestGate3Preparation < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addValidationPath(testCase)
            root=fileparts(fileparts(mfilename('fullpath'))); oldPath=path;
            addpath(root,fullfile(root,'validation'));
            testCase.addTeardown(@() path(oldPath));
        end
    end
    methods (Test)
        function matchedGridsAllowRoundoffButRejectSampleShifts(testCase)
            faultTime=(0:.002:6)'; referenceTime=(0:.002:7)';
            testCase.verifyTrue(time_grids_match(faultTime,referenceTime(1:numel(faultTime))));
            testCase.verifyFalse(time_grids_match(faultTime,faultTime+.002));
            testCase.verifyFalse(time_grids_match(faultTime,faultTime+1e-8));
            testCase.verifyFalse(time_grids_match(faultTime,faultTime(1:end-1)));
            invalid=faultTime; invalid(end)=NaN;
            testCase.verifyFalse(time_grids_match(faultTime,invalid));
        end
        function physicalFailurePrecedesDiagnosis(testCase)
            s=struct('FaultScenario',"brake_fl_loss",'FaultTime',.003,'DetectionDelay',.010);
            [physical,known]=fault_event_masks(.002,s);
            testCase.verifyEqual(physical,ones(6,1)); testCase.verifyEqual(known,physical);
            [physical,known]=fault_event_masks(.004,s);
            testCase.verifyEqual(physical(1),0); testCase.verifyEqual(known(1),1);
            [physical,known]=fault_event_masks(.014,s); testCase.verifyEqual(known,physical);
        end
        function detectionDoesNotHideThePhysicalSteeringLoss(testCase)
            p=get_params(); failed=fault_scenario_mask('steering_a_loss');
            [rate,~,before]=steering_actuator_dynamics(0,[p.delta_rate/2;p.delta_rate/2],p.delta_max,failed,p,ones(6,1));
            [~,~,after]=steering_actuator_dynamics(0,[0;0],p.delta_max,failed,p,failed);
            testCase.verifyEqual(before.contributions(1),0);
            testCase.verifyEqual(rate,p.delta_rate/2,'AbsTol',1e-12);
            testCase.verifyEqual(before.target_rates(2),p.delta_rate/2,'AbsTol',1e-12);
            testCase.verifyEqual(after.target_rates(2),.6*p.delta_rate,'AbsTol',1e-12);
        end
        function recoveryNeedsFullDwellAndDeadline(testCase)
            t=(0:.002:.3)'; e=ones(size(t)); e(t>=.04)=.05;
            m=recovery_band_metric(t,e,0,.05,.1);
            testCase.verifyTrue(m.DiagnosticPass); testCase.verifyEqual(m.EntryDelay_s,.04,'AbsTol',1e-12);
            e(t==.10)=.2; m=recovery_band_metric(t,e,0,.05,.1);
            testCase.verifyFalse(m.DiagnosticPass);
            e(:)=1; e(end-10:end)=0; m=recovery_band_metric(t,e,0,.05,.1);
            testCase.verifyTrue(isnan(m.EntryDelay_s));
        end
        function pathComparisonDoesNotConfuseSlowingWithLateralError(testCase)
            nominal=table((0:10)',zeros(11,1),zeros(11,1),'VariableNames',{'X_m','Y_m','Psi_rad'});
            faulted=nominal; faulted.X_m=faulted.X_m/2;
            [err,covered]=path_deviation(faulted,nominal);
            testCase.verifyTrue(covered); testCase.verifyEqual(err,zeros(11,1),'AbsTol',1e-12);
            faulted.X_m=nominal.X_m*2; [err,covered]=path_deviation(faulted,nominal);
            testCase.verifyFalse(covered); testCase.verifyTrue(isnan(err(end)));
        end
        function catalogHasThirtyUniqueCases(testCase)
            cases=gate3_fault_cases(); ids=string({cases.ID});
            testCase.verifyEqual(numel(cases),30); testCase.verifyEqual(numel(unique(ids)),30);
            for k=1:numel(cases)
                s=cases(k);
                testCase.verifyLessThan(s.FaultTime+s.DetectionDelay+.15,s.Duration);
                [physical,known]=fault_event_masks(s.Duration,s);
                testCase.verifyEqual(physical,known); testCase.verifyTrue(any(physical==0));
            end
        end
        function dbbsPulseRespectsDefinedReference(testCase)
            p=get_params(); s=struct('Profile',"dbbs",'YawSign',-1);
            r=maneuver_reference(3,s,p); testCase.verifyEqual(r.yaw,-.15,'AbsTol',1e-12);
            r=maneuver_reference(1,s,p); testCase.verifyEqual(r.yaw,0);
            r=maneuver_reference(6,s,p); testCase.verifyEqual(r.yaw,0);
        end
        function rawForceIsNotStraightLineCapacity(testCase)
            s=straight_braking_screening();
            testCase.verifyLessThan(s.ZeroSteerRatio(1),.60);
            testCase.verifyGreaterThan(s.RawStaticForceRatio(1),.60);
            testCase.verifyEqual(s.ZeroSteerRatio(1),s.ZeroSteerRatio(2));
        end
    end
end
