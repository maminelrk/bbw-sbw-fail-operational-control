function cases = gate3_fault_cases()
% G3-PREP-01: 30 permanent loss cases, not a complete safety validation.
nominal=gate2_maneuvers(); base=nominal(3);
base.FaultScenario="nominal"; base.FaultTime=2; base.DetectionDelay=0;
base.YawSign=1; base.ReferenceKey="combined"; base.Coverage="single-channel";
cases=repmat(base,0,1);
faults=["brake_fl_loss" "brake_fr_loss" "brake_rl_loss" "brake_rr_loss" ...
    "steering_a_loss" "steering_b_loss"];
labels=["FL" "FR" "RL" "RR" "SA" "SB"];
for delay=[0 .010 .050]
    for k=1:numel(faults)
        s=base; s.FaultScenario=faults(k); s.DetectionDelay=delay;
        s.ID=string(sprintf('G3-%s-D%02d',labels(k),round(1000*delay)));
        s.NameEN="Combined maneuver / "+labels(k); s.NameFR="Manœuvre combinée / "+labels(k);
        cases(end+1,1)=s; %#ok<AGROW>
    end
    for onset=[1 3]
        s=base; s.Profile="dbbs"; s.ReferenceKey="dbbs_positive";
        s.FaultScenario="steering_loss"; s.FaultTime=onset; s.DetectionDelay=delay;
        s.Coverage="complete-drive-loss-held-rack";
        s.ID=string(sprintf('G3-DBBS-T%d-D%02d',onset,round(1000*delay)));
        s.NameEN="DBBS / held rack"; s.NameFR="DBBS / crémaillère maintenue";
        cases(end+1,1)=s; %#ok<AGROW>
    end
end
for k=1:4
    s=base; s.Profile="brake"; s.ReferenceKey="brake"; s.FaultScenario=faults(k);
    s.ID="G3-BRK-"+labels(k); s.NameEN="Braking / "+labels(k); s.NameFR="Freinage / "+labels(k);
    cases(end+1,1)=s; %#ok<AGROW>
end
for onset=[1 3]
    s=base; s.Profile="dbbs"; s.ReferenceKey="dbbs_negative"; s.YawSign=-1;
    s.FaultScenario="steering_loss"; s.FaultTime=onset; s.DetectionDelay=.010;
    s.Coverage="complete-drive-loss-held-rack";
    s.ID=string(sprintf('G3-DBBS-NEG-T%d-D10',onset));
    s.NameEN="DBBS / mirrored turn"; s.NameFR="DBBS / virage symétrique";
    cases(end+1,1)=s; %#ok<AGROW>
end
end
