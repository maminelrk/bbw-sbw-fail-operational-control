function scenarios = gate2_maneuvers()
% Versioned nominal maneuvers. These are project tests, not ISO maneuvers.
base=struct('ID',"",'NameEN',"",'NameFR',"",'Profile',"", ...
    'Duration',6,'InitialSpeed',60/3.6,'ForceRMSELimit',250, ...
    'YawRMSELimit',0.012,'Kind',"tracking");
scenarios=repmat(base,5,1);
ids=["G2-BRK" "G2-STR" "G2-CMB" "G2-YAW" "G2-SAT"];
en=["Ramped straight braking" "Smoothed step steering" ...
    "Combined braking and steering" "Sinusoidal yaw reference" "Brake saturation and recovery"];
fr=["Freinage rectiligne progressif" "Échelon de direction lissé" ...
    "Freinage et direction combinés" "Consigne sinusoïdale de lacet" "Saturation et reprise du freinage"];
profiles=["brake" "steer" "combined" "yaw" "saturation"];
for k=1:5
    scenarios(k).ID=ids(k); scenarios(k).NameEN=en(k);
    scenarios(k).NameFR=fr(k); scenarios(k).Profile=profiles(k);
end
scenarios(5).Duration=4; scenarios(5).Kind="capacity";
end
