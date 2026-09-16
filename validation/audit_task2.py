"""TASK2-LOCAL-01: audit saved evidence, without running a vehicle simulation.
Audit local des preuves sauvegardées, sans nouvelle simulation véhicule.
Run from project root: python validation/audit_task2.py OUTPUT_DIRECTORY
The output directory must not exist. Python standard library only.
"""
import csv
import hashlib
import json
import math
import sys
from bisect import bisect_left
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / 'validation/results'
NEW = RESULTS / 'task1_evidence_20260916/validation/results/candidate_v1'
OLD = RESULTS / 'gate3_matlab_20260916_timegrid_v1/gate3'
SUP = RESULTS / 'gate3_assessment_20260916/supplementary_v2'
INPUTS = {}


def content(path):
    data = path.read_bytes()
    INPUTS[path.relative_to(ROOT).as_posix()] = hashlib.sha256(data).hexdigest()
    return data.decode('utf-8-sig')


def rows(path):
    return list(csv.DictReader(content(path).splitlines()))


def numeric(path):
    return [{k: float(v) for k, v in r.items()} for r in rows(path)]


def yes(v):
    return str(v).lower() in ('1', 'true')


def check(a, b, label):
    assert math.isclose(float(a), float(b), rel_tol=1e-7, abs_tol=1e-9), (label, a, b)


def band_entry(time, error, flag, dwell=.1, threshold=.1):
    """Full inclusive sampled dwell; missing data and gaps cannot pass."""
    assert len(time) == len(error) and len(time) > 1
    assert all(math.isfinite(t) for t in time)
    assert all(b > a for a, b in zip(time, time[1:]))
    dt = min(b-a for a, b in zip(time, time[1:]))
    for i in range(bisect_left(time, flag-1e-12), len(time)):
        j = bisect_left(time, time[i]+dwell-1e-12)
        if j == len(time):
            break
        if any(b-a > 1.01*dt for a, b in zip(time[i:j], time[i+1:j+1])):
            continue
        if all(math.isfinite(e) and e <= threshold for e in error[i:j+1]):
            return max(0., time[i]-flag)
    return None


def refkey(case):
    if case.startswith('G3-BRK'):
        return 'brake'
    if 'DBBS' in case:
        return 'dbbs_negative' if 'NEG' in case else 'dbbs_positive'
    return 'combined'


CHANNELS = ('FL', 'FR', 'RL', 'RR', 'SA', 'SB')
STATE = ('Vx_mps', 'Vy_mps', 'YawRate_radps', 'X_m', 'Y_m', 'Psi_rad',
         'Delta_rad', 'BrakeStateFL_N', 'BrakeStateFR_N', 'BrakeStateRL_N',
         'BrakeStateRR_N', 'MotorRateA_radps', 'MotorRateB_radps')
COMMAND = ('CmdFL_N', 'CmdFR_N', 'CmdRL_N', 'CmdRR_N', 'CmdDelta_rad')


def audit():
    p = json.loads(content(NEW/'manifest.json'))['Parameters']
    old_p = json.loads(content(OLD/'run_manifest.json'))['Parameters']
    physical_fields = ('m','Iz','L','wf','lf','lr','tw','hcg','mu','g','Cf','Cr','Cshape','Eshape',
                       'delta_max','delta_rate','Fx_rate','actuator_tau_delta','actuator_tau_Fx','vx_floor')
    for field in physical_fields:
        check(p[field], old_p[field], 'unchanged physical parameter '+field)
    prior_audit = json.loads(content(NEW.parent/'task1_local_audit.json'))
    assert prior_audit['EvidenceConsistencyVerified'] and not prior_audit['Task1Passed']
    for rel, digest in prior_audit['SourceSHA256'].items():
        assert hashlib.sha256((ROOT/rel).read_bytes()).hexdigest() == digest
        content(ROOT/rel)
    # Model/plant-only witness reuse requires unchanged equations, not unchanged tuning.
    model_files = ('vehicle_dynamics_quantities.m', 'plant_step.m',
                   'vehicle_derivatives_block.m', 'steering_actuator_dynamics.m')
    for rel in model_files:
        a = content(NEW/'source'/rel).replace('\r\n', '\n')
        b = content(SUP/'source'/rel).replace('\r\n', '\n')
        assert a == b, ('physical model changed', rel)
    summaries = rows(NEW/'fault_summary.csv')
    old_summary = {r['ScenarioID']: r for r in rows(OLD/'fault_summary.csv')}
    series = {r['ScenarioID']: numeric(NEW/'faults'/r['ScenarioID']/'timeseries.csv') for r in summaries}
    references = {k: numeric(NEW/'faults'/('NOM-'+k)/'timeseries.csv')
                  for k in ('combined', 'brake', 'dbbs_positive', 'dbbs_negative')}
    g2 = RESULTS/'gate2_presentation_20260915_233346/gate2'
    old_nominal = {r['ScenarioID']:r for r in rows(g2/'maneuver_summary.csv')}
    nominal_checks = []
    for row in rows(NEW/'nominal_summary.csv'):
        prior = old_nominal[row['ScenarioID']]
        fields = ('ForceRMSE_N','YawRMSE_radps','PeakSideslip_rad','FinalSpeed_mps')
        for field in fields: check(row[field], prior[field], row['ScenarioID']+' '+field)
        nominal_checks.append(dict(ID=row['ScenarioID'], SavedMetricMatch=True, Pass=yes(row['OverallPass'])))
    steering = rows(g2/'steering/steering_summary.csv')
    recovery_rows, comparison = [], []
    for metric in summaries:
        case = metric['ScenarioID']; data = series[case]; nominal = references[refkey(case)]
        time = [r['Time_s'] for r in data]
        onset = next(i for i, r in enumerate(data) if any(r['Physical_'+c] == 0 for c in CHANNELS))
        flag = next(i for i, r in enumerate(data) if any(r['Known_'+c] == 0 for c in CHANNELS))
        applied = next(i for i in range(flag, len(data)) if all(data[i]['Known_'+c] == data[i]['Physical_'+c] for c in CHANNELS))
        isolation = all(abs(r['Cmd'+c+'_N']) <= 1e-7 for r in data for c in CHANNELS[:4] if r['Known_'+c] == 0)
        error = [max(abs(r['FxActual_N']-r['OracleFx_N'])/r['OracleScaleFx_N'],
                     abs(r['MzActual_Nm']-r['OracleMz_Nm'])/r['OracleScaleMz_Nm']) for r in data]
        delay = band_entry(time, error, time[flag])
        yaw = max(abs(r['YawRate_radps']-nominal[i]['YawRate_radps']) for i, r in enumerate(data)
                  if time[onset]-1e-12 <= time[i] <= time[onset]+.2+1e-12)
        check(metric['MaskActivation_s'], time[applied]-time[flag], case)
        check(metric['RecoveryDiagnostic_s'], delay, case)
        check(metric['YawDifference200ms_radps'], yaw, case)
        assert yes(metric['MaskPass']) == (isolation and time[applied]-time[flag] <= .01+1e-12)
        assert yes(metric['RecoveryDiagnosticPass']) == (delay is not None and delay <= .05+1e-12)
        assert yes(metric['ContinuityDiagnosticPass']) == (yaw <= .05)
        recovery_rows.append(dict(ID=case, Scope='DBBS_BACKUP' if yes(metric['IsDBBS']) else 'SINGLE_CHANNEL',
            Onset_s=time[onset], Flag_s=time[flag], MaskDelay_s=time[applied]-time[flag],
            MaskPass=isolation and time[applied]-time[flag] <= .01+1e-12,
            AffineBandEntry_s=delay, AffineDwellPass=delay is not None and delay <= .05+1e-12,
            ErrorAtFlag=error[flag], AlreadyInBandAtFlag=error[flag] <= .1,
            MaxErrorFirst150ms=max(e for t,e in zip(time,error) if time[flag] <= t <= time[flag]+.15+1e-12),
            YawDifference200ms_radps=yaw, ContinuityDiagnosticPass=yaw <= .05,
            IndependentNonlinearBestAvailable=False, FullREQ02Established=False))
        old = old_summary[case]
        comparison.append(dict(ID=case, DBBS=yes(metric['IsDBBS']),
            OldPath_m=float(old['PeakPathDeviation_m']), NewPath_m=float(metric['PeakPathDeviation_m']),
            OldYawRMSE_radps=float(old['PostFaultYawRMSE_radps']), NewYawRMSE_radps=float(metric['PostFaultYawRMSE_radps']),
            OldDecel_g=float(old['PeakDeceleration_g']), NewDecel_g=float(metric['PeakDeceleration_g']),
            OldFinalSpeedLoss_mps=float(old['FinalSpeedLoss_mps']), NewFinalSpeedLoss_mps=float(metric['FinalSpeedLoss_mps']),
            OldDBBSPass=yes(old['DBBSManeuverPass']), NewDBBSPass=yes(metric['DBBSManeuverPass'])))
    # Determine whether prior frozen-state/rollout evidence concerns the same inputs.
    probes = rows(SUP/'envelope/envelope_probes.csv')
    old_series = {}; transfer = []
    for case, sample in sorted({(r['ScenarioID'], r['SampleIndex']) for r in probes}):
        group = [r for r in probes if r['ScenarioID'] == case and r['SampleIndex'] == sample]
        if case not in old_series:
            old_series[case] = numeric(OLD/case/'timeseries.csv')
        target_time = float(group[0]['Time_s'])
        i = min(range(len(series[case])), key=lambda j: abs(series[case][j]['Time_s']-target_time))
        j = min(range(len(old_series[case])), key=lambda j: abs(old_series[case][j]['Time_s']-target_time))
        a, b = series[case][i], old_series[case][j]
        check(a['Time_s'], target_time, 'new envelope time'); check(b['Time_s'], target_time, 'old envelope time')
        state_delta = max(abs(a[k]-b[k]) for k in STATE)
        demand_delta = max(abs(a[k]-b[k]) for k in ('FxDemand_N', 'MzDemand_Nm'))
        prev_delta = max(abs(series[case][max(0,i-1)][k]-old_series[case][max(0,j-1)][k]) for k in COMMAND)
        same_mask = all(a['Physical_'+c] == b['Physical_'+c] for c in CHANNELS)
        # Roundoff-only identity test, not a permitted change in vehicle state.
        frozen_same = same_mask and state_delta <= 1e-9 and demand_delta <= 1e-6
        rollout_same = frozen_same and prev_delta <= 1e-6
        transfer.append(dict(ID=case, Sample=int(sample), Time_s=target_time,
            StateMaxDifference=state_delta, DemandMaxDifference=demand_delta, PreviousCommandMaxDifference=prev_delta,
            FrozenInputMatch=frozen_same, RolloutInputMatch=rollout_same,
            OldWitnesses=sum(yes(r['FrozenStateWitness']) for r in group),
            OldEndpointPasses=sum(yes(r['EndpointWithin10Percent']) for r in group),
            TransferableWitnesses=sum(yes(r['FrozenStateWitness']) for r in group) if frozen_same else 0,
            TransferableEndpointScreens=sum(yes(r['EndpointWithin10Percent']) for r in group) if rollout_same else 0,
            ContinuousEnvelopeEstablished=False))
    # Refinement uses only common samples; no new integration or interpolation.
    refined = []
    for row in rows(NEW/'refined_summary.csv'):
        case = row['ID']; coarse_dir = 'faults' if 'DBBS' in case else 'authority'
        coarse = numeric(NEW/coarse_dir/case/'timeseries.csv')
        fine = numeric(NEW/'refined'/case/'timeseries.csv')
        aligned = fine[::2]; assert len(aligned) == len(coarse)
        for a,b in zip(coarse,aligned): check(a['Time_s'], b['Time_s'], case)
        yaw = max(abs(a['YawRate_radps']-b['YawRate_radps']) for a,b in zip(coarse,aligned))
        speed = max(abs(a['Vx_mps']-b['Vx_mps']) for a,b in zip(coarse,aligned))
        path_delta = abs(float(row['Path_m'])-float(next(m for m in summaries if m['ScenarioID']==case)['PeakPathDeviation_m'])) if 'DBBS' in case else None
        refined.append(dict(ID=case, MaxYawDifference_radps=yaw, MaxSpeedDifference_mps=speed,
            PeakPathDifference_m=path_delta, ExistingRefinementScreenPass=(path_delta <= .001 and yaw <= .001 and speed <= .03) if path_delta is not None else None,
            RefinedAcceptancePass=yes(row['Pass'])))
    # Saturated transition analysis: empty physical-bound / healthy-rate intersection.
    transitions = []
    nominal = numeric(NEW/'authority/AUTH-nominal/timeseries.csv')
    for row in rows(NEW/'transition_summary.csv'):
        data = numeric(NEW/'transitions'/row['ID']/'timeseries.csv'); time = [r['Time_s'] for r in data]
        onset = next(i for i,r in enumerate(data) if any(r['Physical_'+c]==0 for c in CHANNELS[:4]))
        flag = next(i for i,r in enumerate(data) if any(r['Known_'+c]==0 for c in CHANNELS[:4]))
        overrides = [i for i,r in enumerate(data) if r['RateOverride'] > 0]; assert len(overrides)==1
        healthy_front = 'FR' if 'fl_loss' in row['ID'] else 'FL'
        i = onset; r = data[i]; previous = data[i-1]['Cmd'+healthy_front+'_N']
        lower = -p['mu']*r['Fz'+healthy_front+'_N']; allowed = p['Fx_rate']*(time[i]-time[i-1])
        ratio = [-(r['FxActual_N']/p['m']+r['Vy_mps']*r['YawRate_radps'])/(p['mu']*p['g']) for r in data]
        yaw_limit = float(row['YawLimit_Nm'])
        # Descriptive return to authority thresholds, NOT a replacement REQ-02 metric.
        joint_error = [0. if q >= .6 and abs(r['MzActual_Nm']) <= yaw_limit else 1. for q,r in zip(ratio,data)]
        plateau_indices = [j for j,t in enumerate(time) if t <= 1.9+1e-12]
        end = plateau_indices[-1]+1
        recovery = band_entry(time[:end], joint_error[:end], time[flag])
        yaw_diff = max(abs(r['YawRate_radps']-nominal[j]['YawRate_radps']) for j,r in enumerate(data) if time[onset] <= time[j] <= time[onset]+.2+1e-12)
        transitions.append(dict(ID=row['ID'], Flag_s=time[flag], OverrideTime_s=time[overrides[0]],
            HealthyFront=healthy_front, PreviousCommand_N=previous, PhysicalLowerAtOnset_N=lower,
            AllowedRelease_N=allowed, MinimumRequiredRelease_N=max(0.,lower-previous),
            EmptyIntersectionAtOnset=lower > previous+allowed+1e-6,
            MinimumBrakingRatio=min(ratio[j] for j in plateau_indices if time[j]>=1.5),
            DemandToGlobalBrakingBoundAtOnset=abs(r['FxDemand_N'])/(p['mu']*p['m']*p['g']),
            RequestedDemandOutsidePhysicalOuterBound=abs(r['FxDemand_N']) > p['mu']*p['m']*p['g'],
            PeakYawFirst200ms_radps=yaw_diff, ContinuityProxyWithin005=yaw_diff <= .05,
            JointAuthority100msDwellEntryAfterFlag_s=recovery,
            ThisIsREQ02Proof=False, HealthyRatePass=False))
    authority = rows(NEW/'braking_summary.csv')
    old_authority = rows(SUP/'authority/braking_dynamic.csv')
    brakes = []
    for row in authority:
        fault = row['ID'].removeprefix('AUTH-')
        old = next(r for r in old_authority if r['Fault']==fault)
        old_data = numeric(SUP/'authority'/('G3-AUTH-BRK-'+fault)/'timeseries.csv')
        old_beta = max(abs(math.atan2(r['Vy_mps'],r['Vx_mps'])) for r in old_data)
        brakes.append(dict(Fault=fault, OldRatio=float(old['RatioLowerBoundToNominalUpper']), NewRatio=float(row['BrakingRatio']),
            OldPeakBeta_rad=old_beta, NewPeakBeta_rad=float(row['PeakBeta_rad']),
            NewRatioMarginPercentagePoints=100*(float(row['BrakingRatio'])-.6), NewPass=yes(row['Pass'])))
    yaw_authority = rows(SUP/'authority/yaw_authority.csv')
    straight = rows(RESULTS/'gate3_straight_path_20260916/straight_path_braking.csv')
    old_audit = json.loads(content(RESULTS/'gate3_supplementary_audit_20260916.json'))
    straight_audit = json.loads(content(RESULTS/'gate3_straight_path_20260916/audit.json'))
    assert old_audit['EvidenceConsistencyVerified'] and straight_audit['Verified']
    summary = dict(Protocol='TASK2-LOCAL-01', GeneratedUTC=datetime.now(timezone.utc).isoformat(),
        NewSimulations=0, LocalAssessmentComplete=True, AllRequirementsEstablished=False,
        Task1Passed=False, Gate3Closed=False,
        Task3PackagingMayProceed=True, UnqualifiedFinishedFailOperationalClaim=False,
        RecoveryCases=len(recovery_rows), SingleChannelCases=sum(r['Scope']=='SINGLE_CHANNEL' for r in recovery_rows),
        MaskPasses=sum(r['MaskPass'] for r in recovery_rows),
        AffineDwellPasses=sum(r['AffineDwellPass'] for r in recovery_rows),
        AlreadyInBandAtFlag=sum(r['AlreadyInBandAtFlag'] for r in recovery_rows),
        MaximumBandEntry_s=max(r['AffineBandEntry_s'] for r in recovery_rows),
        MaximumYawDifference200ms_radps=max(r['YawDifference200ms_radps'] for r in recovery_rows),
        TransferableFrozenSamples=sum(r['FrozenInputMatch'] for r in transfer),
        TransferableWitnesses=sum(r['TransferableWitnesses'] for r in transfer),
        TransferableEndpointScreens=sum(r['TransferableEndpointScreens'] for r in transfer),
        AnalysisScopeEN='Independent saved-trace arithmetic; existing nonlinear witnesses reused only for matching inputs. No new nonlinear optimum, continuous envelope, or robustness campaign.',
        AnalysisScopeFR='Recalcul indépendant des traces ; réemploi des témoins non linéaires uniquement pour entrées identiques. Aucun nouvel optimum, enveloppe continue ou campagne de robustesse.')
    return summary, dict(recovery=recovery_rows, comparison=comparison, envelope_transfer=transfer, refinement=refined,
        transitions=transitions, braking_comparison=brakes, nominal_regression=nominal_checks), dict(yaw_authority=yaw_authority, straight_braking=straight,
        HistoricalFunctionalSteeringBench=steering,
        HistoricalEnvelopeCounts=dict(Counter(r['Status'] for r in probes)),
        HistoricalEndpointPasses=sum(yes(r['EndpointWithin10Percent']) for r in probes))


def main():
    out = Path(sys.argv[1]).resolve()
    assert not out.exists(), 'Preserve earlier audit: choose a new folder.'
    summary, tables, authority = audit()
    out.mkdir(parents=True)
    for name, values in tables.items():
        with (out/(name+'.csv')).open('w', newline='', encoding='utf-8') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(values[0]))
            writer.writeheader(); writer.writerows(values)
    summary.update(authority)
    summary['InputSHA256'] = INPUTS
    summary['AuditScriptSHA256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    (out/'audit.json').write_text(json.dumps(summary, indent=2, ensure_ascii=False, allow_nan=False)+'\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in summary.items() if k!='InputSHA256'}, indent=2, ensure_ascii=False))


if __name__ == '__main__':
    main()
