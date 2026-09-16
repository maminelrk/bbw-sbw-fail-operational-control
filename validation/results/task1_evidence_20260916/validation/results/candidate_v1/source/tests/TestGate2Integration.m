classdef TestGate2Integration < matlab.unittest.TestCase
    methods (Test)
        function steeringChannelsActOnCommonRack(testCase)
            p=get_params(); command=deg2rad(35);
            [~,~,both]=steering_actuator_dynamics(0,[0;0],command,ones(6,1),p);
            testCase.verifyEqual(sum(both.target_rates),p.delta_rate,'AbsTol',1e-12);
            for name=["steering_a_loss","steering_b_loss"]
                mask=fault_scenario_mask(name);
                [~,~,one]=steering_actuator_dynamics(0,[0;0],command,mask,p);
                testCase.verifyEqual(sum(one.target_rates),0.6*p.delta_rate,'AbsTol',1e-12);
                testCase.verifyEqual(one.target_rates(mask(5:6)==0),0,'AbsTol',1e-12);
            end
        end
        function totalSteeringLossHoldsRack(testCase)
            p=get_params(); mask=fault_scenario_mask('steering_loss');
            [rate,~,d]=steering_actuator_dynamics(0.1,[2;2],0,mask,p);
            testCase.verifyEqual(rate,0); testCase.verifyEqual(d.available_rate,0);
        end
        function loadTransferBalancesRollMoment(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed; x(3)=0.1;
            q=vehicle_dynamics_quantities(x,p);
            right=q.Fz_raw(2)+q.Fz_raw(4); left=q.Fz_raw(1)+q.Fz_raw(3);
            testCase.verifyEqual((right-left)*p.tw/2,p.m*p.hcg*x(1)*x(3),'RelTol',1e-12);
            testCase.verifyEqual(sum(q.Fz_raw),p.m*p.g,'RelTol',1e-12);
        end
        function zeroFrictionBudgetGivesZeroLateralForce(testCase)
            p=get_params(); load=5000;
            testCase.verifyEqual(pacejka_axle(0.1,load,p.Cf,p,-p.mu*load),0);
        end
        function yawMomentEqualsSumOfWheelMoments(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            x(3)=0.1; x(7)=0.02; x(8:11)=[-500;-1000;-200;-300];
            q=vehicle_dynamics_quantities(x,p); fx=q.Fx_actual; fy=q.Fy_wheels;
            bx=fx; by=fy;
            bx(1:2)=fx(1:2)*cos(x(7))-fy(1:2)*sin(x(7));
            by(1:2)=fx(1:2)*sin(x(7))+fy(1:2)*cos(x(7));
            px=[p.lf;p.lf;-p.lr;-p.lr]; py=[1;-1;1;-1]*p.tw/2;
            testCase.verifyEqual(q.Mz_total,sum(px.*by-py.*bx),'AbsTol',1e-8);
        end
        function wheelLiftIsVisibleInDiagnostics(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed; x(3)=2;
            q=vehicle_dynamics_quantities(x,p);
            testCase.verifyLessThan(min(q.Fz_raw),0);
            testCase.verifyGreaterThanOrEqual(min(q.Fz),0);
        end
        function affineMapIncludesExistingTireForces(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            x(2)=0.1; x(3)=0.05; x(7)=0.01; x(8:11)=-500;
            q=vehicle_dynamics_quantities(x,p);
            anchor=[q.Fx_actual;x(7)];
            [~,flag,info]=allocator([-2000;0],x(7),[],ones(6,1),anchor,p.validation_dt,x);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyEqual(info.offset+info.B*anchor,[q.Fx_total;q.Mz_total],'AbsTol',1e-8);
            testCase.verifyGreaterThan(norm(info.offset),1);
        end
        function failedBrakeIsRemovedFromPlant(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed; x(8)=-1000;
            q=vehicle_dynamics_quantities(x,p,fault_scenario_mask('brake_fl_loss'));
            testCase.verifyEqual(q.Fx_actual(1),0);
        end
        function shrinkingForceBoundsPreserveRateIntersection(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            % The integrated controller now retains an explicit grip reserve.
            previous=[-p.allocation_friction_fraction*p.mu*static_corner_loads(p)'-10;0];
            [u,flag,info]=allocator([-1e6;0],0,[],ones(6,1),previous,p.validation_dt,x);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyFalse(info.rate_override);
            testCase.verifyLessThanOrEqual(abs(u(1:4)-previous(1:4)),p.Fx_rate*p.validation_dt+1e-8);
        end
        function centeredSteeringDerivativePreservesSymmetry(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed; x(8:11)=-1000;
            [~,~,info]=allocator([-4000;0],0,[],ones(6,1),[],[],x);
            testCase.verifyEqual(info.B(1,5),0,'AbsTol',1e-9);
        end
        function nonlinearCommandProducesBoundedPlantResponse(testCase)
            p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
            [u,flag,info]=allocator([-2000;200],0,[],ones(6,1),zeros(5,1),p.validation_dt,x);
            next=plant_step(x,u,ones(6,1),p.validation_dt,p);
            testCase.verifyGreaterThan(flag,0);
            testCase.verifyTrue(all(isfinite(next)));
            testCase.verifyLessThan(next(1),x(1));
            testCase.verifyGreaterThan(next(7),0);
            testCase.verifyGreaterThanOrEqual(u,info.physical_lower_bounds-1e-9);
            testCase.verifyLessThanOrEqual(u,info.physical_upper_bounds+1e-9);
        end
    end
end
