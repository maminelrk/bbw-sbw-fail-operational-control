"""Presentation-only plots from verified MATLAB CSVs (no simulation).

Figures de présentation issues des CSV MATLAB vérifiés (sans simulation).
"""
from pathlib import Path
import csv
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/plot_deps'))
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

SOURCE = ROOT / 'validation/results/validation/results'
DEST = ROOT / 'validation/results/gate2_presentation_20260915_233346'
PALETTE = ['#00558c', '#cc400d', '#007b5e', '#884aa6', '#a66e00', '#555555']
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 11,
    'figure.facecolor': 'white', 'axes.facecolor': 'white', 'savefig.facecolor': 'white',
    'text.color': '#202020', 'axes.labelcolor': '#202020', 'axes.edgecolor': '#606060',
    'xtick.color': '#202020', 'ytick.color': '#202020', 'grid.color': '#d4d9de',
    'axes.prop_cycle': matplotlib.cycler(color=PALETTE), 'lines.linewidth': 1.6,
    'axes.spines.top': False, 'axes.spines.right': False, 'legend.framealpha': .95,
    'legend.fontsize': 9, 'axes.titlesize': 12, 'axes.titleweight': 'bold',
    'savefig.dpi': 180})

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def table(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        records = list(reader)
    return {key: np.array([float(row[key]) for row in records]) for key in reader.fieldnames}

def setup(ax, ylabel, time_label=None):
    ax.set_ylabel(ylabel)
    if time_label:
        ax.set_xlabel(time_label)
    ax.grid(True, linewidth=.6)
    ax.tick_params(labelsize=9)
    ax.margins(x=.015)

def traces(ax, t, arrays, labels=None):
    styles = ['-', '--', '-.', ':', '--', ':']
    for i, a in enumerate(arrays):
        ax.plot(t, a, linestyle=styles[i % len(styles)], label=labels[i] if labels else None)
    if labels:
        ax.legend(loc='best', ncol=min(len(labels), 4))

def save(fig, path, lang):
    footer = ('MATLAB R2026a data | REF-2026-02 / ALLOC-2026-03 | '
        '2026-09-15 23:33:46 UTC | CSV replot: Matplotlib' if lang == 'en' else
        'Données MATLAB R2026a | REF-2026-02 / ALLOC-2026-03 | '
        '15-09-2026 23:33:46 UTC | Retracé CSV : Matplotlib')
    fig.text(.5, .009, footer, ha='center', fontsize=7, color='#52647a')
    fig.tight_layout(rect=(0, .035, 1, .95))
    fig.savefig(path)
    plt.close(fig)

def integrated(folder, lang):
    s = table(folder / 'timeseries.csv')
    t = s['Time_s']
    titles = {
        'G2-BRK': ('Ramped straight braking', 'Freinage rectiligne progressif'),
        'G2-STR': ('Smoothed step steering', 'Échelon de direction lissé'),
        'G2-CMB': ('Combined braking and steering', 'Freinage et direction combinés'),
        'G2-YAW': ('Sinusoidal yaw reference', 'Consigne sinusoïdale de lacet'),
        'G2-SAT': ('Brake saturation and recovery', 'Saturation et reprise du freinage')}
    time_label = 'Time [s]' if lang == 'en' else 'Temps [s]'
    labels = ['Reference', 'Simulated actual'] if lang == 'en' else ['Consigne', 'Mesure simulée']
    fig, axes = plt.subplots(3, 2, figsize=(11, 8.5))
    fig.suptitle(folder.name + ' - ' + titles[folder.name][lang == 'fr'], color='#183f7d', weight='bold')
    for ax, keys, ylabel, pair in [
        (axes[0, 0], ['FxDemand_N', 'FxActual_N'], r'$F_x$ [N]', True),
        (axes[0, 1], ['YawReference_radps', 'YawRate_radps'], r'$r$ [rad/s]', True),
        (axes[1, 0], ['Vx_mps'], r'$v_x$ [m/s]', False),
        (axes[1, 1], ['MzDemand_Nm', 'MzActual_Nm'], r'$M_z$ [N m]', True),
    ]:
        traces(ax, t, [s[k] for k in keys], labels if pair else None)
        setup(ax, ylabel, time_label)
    ax = axes[2, 0]
    ax.plot(s['X_m'], s['Y_m'])
    setup(ax, 'Y [m]', 'X [m]')
    ax.set_aspect('equal', adjustable='datalim')
    traces(axes[2, 1], t, [np.rad2deg(s[k]) for k in ['CmdDelta_rad', 'Delta_rad']], labels)
    setup(axes[2, 1], ('Road-wheel angle [deg]' if lang == 'en' else 'Angle de roue [deg]'), time_label)
    save(fig, folder / f'response_{lang}.png', lang)
    fig, axes = plt.subplots(3, 1, figsize=(11, 8.5))
    fig.suptitle(folder.name + (' - Actuators and wheel loads' if lang == 'en' else ' - Actionneurs et charges de roue'), color='#183f7d', weight='bold')
    for ax, keys, ylabel, names, scale in [
        (axes[0], ['CmdFL_N', 'CmdFR_N', 'CmdRL_N', 'CmdRR_N'], r'$F_{x,cmd}$ [N]', ['FL','FR','RL','RR'], 1),
        (axes[1], ['FzFL_N','FzFR_N','FzRL_N','FzRR_N'], r'$F_z$ [N]', ['FL','FR','RL','RR'], 1),
        (axes[2], ['ContributionA_radps','ContributionB_radps','RackRate_radps'], ('Rack rate [deg/s]' if lang == 'en' else 'Vitesse crémaillère [deg/s]'), ['A','B','A+B'], 180/np.pi),
    ]:
        traces(ax, t, [s[k]*scale for k in keys], names)
        setup(ax, ylabel, time_label)
    save(fig, folder / f'actuators_{lang}.png', lang)

def plant(folder, lang):
    s = table(folder / 'timeseries.csv'); t = s['Time_s']
    time_label = 'Time [s]' if lang == 'en' else 'Temps [s]'
    ref_labels = ['Command','Simulated actual'] if lang == 'en' else ['Consigne','Mesure simulée']
    axles = ['Front','Rear'] if lang == 'en' else ['Avant','Arrière']
    fig, axes = plt.subplots(3, 1, figsize=(11, 8.5))
    fig.suptitle(folder.name + (' - Allocator-free plant' if lang == 'en' else ' - Plante sans allocateur'), color='#183f7d', weight='bold')
    for ax, key, ylabel in [(axes[0], 'Vx_mps', r'$v_x$ [m/s]'), (axes[1], 'YawRate_radps', r'$r$ [rad/s]')]:
        traces(ax, t, [s[key]]); setup(ax, ylabel, time_label)
    axes[2].plot(s['X_m'], s['Y_m']); setup(axes[2], 'Y [m]', 'X [m]')
    axes[2].set_aspect('equal', adjustable='datalim')
    save(fig, folder / f'vehicle_response_{lang}.png', lang)
    fig, axes = plt.subplots(3, 1, figsize=(11, 8.5))
    fig.suptitle(folder.name + (' - Actuators and loads' if lang == 'en' else ' - Actionneurs et charges'), color='#183f7d', weight='bold')
    for ax, keys, ylabel, labels, scale in [
        (axes[0], ['SteeringCommand_rad','SteeringActual_rad'], r'$\delta$ [deg]', ref_labels, 180/np.pi),
        (axes[1], ['FxFL_N','FxFR_N','FxRL_N','FxRR_N'], r'$F_x$ [N]', ['FL','FR','RL','RR'], 1),
        (axes[2], ['FzFL_N','FzFR_N','FzRL_N','FzRR_N'], r'$F_z$ [N]', ['FL','FR','RL','RR'], 1),
    ]:
        traces(ax, t, [s[k]*scale for k in keys], labels); setup(ax, ylabel, time_label)
    save(fig, folder / f'actuators_and_loads_{lang}.png', lang)
    fig, axes = plt.subplots(2, 1, figsize=(11, 7))
    fig.suptitle(folder.name + (' - Tire forces and slip' if lang == 'en' else ' - Forces pneumatiques et dérive'), color='#183f7d', weight='bold')
    for i, (force, cap) in enumerate([('FyFront_N','FyFrontCapacity_N'),('FyRear_N','FyRearCapacity_N')]):
        axes[0].plot(t, s[force], color=PALETTE[i], label=axles[i])
        axes[0].plot(t, s[cap], '--', color=PALETTE[i], alpha=.7, label=axles[i] + (' limit ±' if lang == 'en' else ' limite ±'))
        axes[0].plot(t, -s[cap], '--', color=PALETTE[i], alpha=.7)
    axes[0].legend(ncol=2); setup(axes[0], r'$F_y$ [N]', time_label)
    traces(axes[1], t, [np.rad2deg(s[k]) for k in ['AlphaFront_rad','AlphaRear_rad']], axles)
    setup(axes[1], r'$\alpha$ [deg]', time_label)
    save(fig, folder / f'tire_response_{lang}.png', lang)

def steering(folder, name, lang):
    s = table(folder / f'{name}.csv'); t = s['Time_s']
    titles = {'nominal': ('Nominal steering', 'Direction nominale'),
        'steering_a_loss': ('Steering drive A loss', "Perte de l'entraînement A"),
        'steering_b_loss': ('Steering drive B loss', "Perte de l'entraînement B"),
        'steering_loss': ('Complete steering drive loss', 'Perte totale des entraînements de direction')}
    time_label = 'Time [s]' if lang == 'en' else 'Temps [s]'
    fig, axes = plt.subplots(2, 1, figsize=(11, 7))
    fig.suptitle(titles[name][lang == 'fr'], color='#183f7d', weight='bold')
    traces(axes[0], t, [np.rad2deg(s['Delta_rad'])]); setup(axes[0], r'$\delta$ [deg]', time_label)
    traces(axes[1], t, [np.rad2deg(s[k]) for k in ['RackRate_radps','ContributionA_radps','ContributionB_radps']], ['A+B','A','B'])
    setup(axes[1], r'$d\delta/dt$ [deg/s]', time_label)
    save(fig, folder / f'{name}_{lang}.png', lang)

def main():
    assert not DEST.exists(), 'Refusing to overwrite a presentation package'
    manifest = json.loads((SOURCE / 'gate2/run_manifest.json').read_text())
    assert manifest['AllChecksPassed'] and manifest['Status'] == 'READY_FOR_SUPERVISOR_REVIEW'
    raw = [{'Path': p.relative_to(SOURCE).as_posix(), 'SHA256': digest(p)}
        for p in sorted(SOURCE.rglob('*')) if p.is_file() and p.suffix.lower() != '.png']
    shutil.copytree(SOURCE, DEST)
    for lang in ('en','fr'):
        for folder in sorted((DEST / 'gate2').glob('G2-*')):
            integrated(folder, lang)
        for folder in sorted((DEST / 'plant').glob('PLANT-*')):
            plant(folder, lang)
        for name in ('nominal','steering_a_loss','steering_b_loss','steering_loss'):
            steering(DEST / 'gate2/steering', name, lang)
    for record in raw:
        assert digest(SOURCE / record['Path']) == record['SHA256']
        assert digest(DEST / record['Path']) == record['SHA256']
    pngs = list((DEST / 'gate2').rglob('*.png')) + list((DEST / 'plant').rglob('*.png'))
    assert len(pngs) == 46
    (DEST / 'rendering_source').mkdir()
    shutil.copy2(__file__, DEST / 'rendering_source/render_gate2_csv.py')
    presentation = {'Kind': 'PRESENTATION_ONLY_CSV_REPLOT', 'SimulationRerun': False,
        'SimulationEngine': manifest['MATLABVersion'], 'PlottingEngine': 'Matplotlib '+matplotlib.__version__,
        'CreatedUTC': datetime.now(timezone.utc).isoformat(), 'OriginalRunStartedUTC': manifest['StartedUTC'],
        'OriginalRunStatus': manifest['Status'], 'RawFilesUnchanged': True, 'RawFiles': raw,
        'FigureCount': len(pngs), 'RenderingSources': [{'File':'render_gate2_csv.py', 'SHA256':digest(Path(__file__))}],
        'NoteEN': 'Only CSV plotting and radian-to-degree display conversion. No model integration, optimization, resampling or acceptance changes.',
        'NoteFR': 'Tracé des CSV et conversion radians-degrés pour affichage uniquement. Aucune intégration du modèle, optimisation, interpolation ni modification des critères.'}
    (DEST / 'presentation_manifest.json').write_text(json.dumps(presentation, indent=2), encoding='utf-8')
    print(json.dumps({k:v for k,v in presentation.items() if k != 'RawFiles'}, indent=2))

if __name__ == '__main__':
    main()
