function scenarios = plant_open_loop_scenarios()
%PLANT_OPEN_LOOP_SCENARIOS Allocator-free plant validation cases.

p = get_params();
base = struct( ...
    'ScenarioID',"",'Name',"",'NameFR',"",'Duration_s',4.0, ...
    'InitialSpeed_mps',p.reference_speed, ...
    'SteeringStepTime_s',0.5,'Steering_rad',0, ...
    'BrakeStepTime_s',0.5,'BrakeForces_N',zeros(4,1));

scenarios = repmat(base,3,1);

scenarios(1).ScenarioID = "PLANT-BRK-01";
scenarios(1).Name = "Symmetric straight-line braking";
scenarios(1).NameFR = "Freinage rectiligne symétrique";
scenarios(1).BrakeForces_N = -1500*ones(4,1);

scenarios(2).ScenarioID = "PLANT-STR-01";
scenarios(2).Name = "Positive one-degree step steer";
scenarios(2).NameFR = "Échelon positif de direction de un degré";
scenarios(2).Steering_rad = deg2rad(1);

scenarios(3).ScenarioID = "PLANT-CMB-01";
scenarios(3).Name = "Combined braking and step steer";
scenarios(3).NameFR = "Freinage et direction combinés";
scenarios(3).Steering_rad = deg2rad(1);
scenarios(3).BrakeForces_N = -1000*ones(4,1);

end
