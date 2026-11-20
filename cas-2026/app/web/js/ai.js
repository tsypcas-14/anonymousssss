// AI tab: the live path through each tree ("why"), the tree maps, model quality and the learned policy.
import { confusion, hBars, treeSVG } from './charts.js';
import { $, api, classColor, esc, fname, fval, lbl, num, ORDER, setHTML } from './common.js';

const TREES = [
  { id: 'irrigation', n: 1, title: 'Irrigation', out: 'pump' },
  { id: 'climate', n: 2, title: 'Ventilation', out: 'fan' },
  { id: 'anomaly', n: 3, title: 'Watering check', out: 'pump lock' },
];
let card = null;

const legend = id => `<div class="pleg">${ORDER[id].map(c => `<div><span class="sw" style="background:${classColor(c)}"></span>${esc(lbl(c))}</div>`).join('')}</div>`;

function steps(path) {
  return `<ol class="path">${path.map(s => `<li><span>${esc(fname(s.f))}</span> <b>${fval(s.f, s.v)}</b>
    <em>${s.le ? '≤' : '>'} ${fval(s.f, s.t)}</em></li>`).join('')}</ol>`;
}

function liveCard(t, d, extra = '') {
  const tree = card.trees[t.id];
  const head = `<div class="row"><h3>Tree ${t.n} · ${t.title}</h3>${d ? `<span class="pill cls" style="--c:${classColor(d.label)}">${esc(lbl(d.label))}</span>` : ''}</div>`;
  if (!d) return `<div class="card">${head}<p class="sub">${t.id === 'anomaly' ? 'No watering checked yet.' : 'Waiting for a valid reading…'}</p></div>`;
  return `<div class="card">${head}${extra}
    <p class="chart-note">Path through the tree, from the root (${d.path.length} tests):</p>${steps(d.path)}
    <p class="arrow">→ <b>${esc(lbl(d.label))}</b> <small>(${esc(d.label)})</small></p>
    ${treeSVG(tree.root, d.path, classColor, fname, lbl)}${legend(t.id)}
    <p class="chart-note">${tree.metrics.leaves} leaves · depth ${tree.metrics.depth}. The thick line is the path taken now. Hover a dot to read its test.</p></div>`;
}

export function renderAILive(st) {
  if (!card) return;
  const dec = st.decision || {};
  const flame = dec.irrigation && dec.irrigation.label === 'SAFETY_FLAME';
  let html;
  if (flame) html = `<div class="card crit-card"><h3>Safety rule active: flame detected</h3><p class="why">The trees are not consulted: buzzer on, pump and fan cut. Hard-coded safety rules always sit above the AI.</p></div>`;
  else if (st.alarms.missing) html = `<div class="card warn-card"><h3>Sensor reading missing</h3><p class="why">Decisions are paused and the pump is off: the agent never waters blind.</p></div>`;
  else html = liveCard(TREES[0], dec.irrigation, st.irrigation.locked ? '<p class="why warn-text">The pump is locked by tree 3: even “Water now” will not start it.</p>' : '')
    + liveCard(TREES[1], dec.climate);
  const ld = st.last_diagnosis;
  html += liveCard(TREES[2], ld, ld ? `<p class="why">Last check ${new Date(ld.time).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}: soil change ${num(ld.inputs.soil_drop)}, water taken ${num(ld.inputs.water_drop_cm, 2)} cm, sensor spread ${num(ld.inputs.soil_std, 1)}.</p>` : '');
  setHTML($('#aiLive'), html);

  const s = st.sensors || {}, irr = dec.irrigation?.label, clim = dec.climate?.label;
  const box = (title, sub, cls = '') => `<div class="fbox ${cls}"><b>${title}</b><span>${sub}</span></div>`;
  setHTML($('#aiFlow'), `<div class="flow-row">
    ${box('Sensors', `${num(s.soil_raw)} raw · ${num(s.air_temp, 1)} °C · ${num(s.air_hum)} %`)}<i>→</i>
    ${box('Safety rules', flame ? 'FLAME: all cut' : st.alarms.missing ? 'reading missing' : st.alarms.tank_low ? 'tank empty: pump forbidden' : 'all clear', flame || st.alarms.missing ? 'crit' : st.alarms.tank_low ? 'warn' : 'ok')}<i>→</i>
    ${box('Tree 1 → pump', flame ? '–' : `${lbl(irr)} · ${st.irrigation.phase}`, st.actuators.pump ? 'on' : '')}
    ${box('Tree 2 → fan', flame ? '–' : lbl(clim), st.actuators.fan ? 'on' : '')}
    ${box('Tree 3 → check', st.irrigation.locked ? 'PUMP LOCKED' : ld ? lbl(ld.label) : 'waiting', st.irrigation.locked ? 'crit' : '')}</div>`);
}

function quality() {
  return `<div class="grid-auto">${TREES.map(t => {
    const m = card.trees[t.id].metrics;
    const short = l => lbl(l).replace('No water needed', 'No water').replace('Faulty soil sensor', 'Bad sensor').replace('Refill the tank', 'Refill');
    const imp = Object.entries(m.feature_importance).sort((a, b) => b[1] - a[1]).map(([f, v]) => ({ name: fname(f), value: v }));
    const n = m.confusion_matrix.flat().reduce((a, b) => a + b, 0);
    return `<div class="card"><div class="row"><h3>Tree ${t.n} · ${t.title}</h3><span class="pill">${num(m.test_accuracy * 100, 1)}% accuracy</span></div>
      <div class="mini-stats"><div><small>Test accuracy</small><b>${num(m.test_accuracy * 100, 1)}%</b></div>
        <div><small>5-fold CV</small><b>${num(m.cv_mean * 100, 1)}% ± ${num(m.cv_std * 100, 1)}</b></div>
        <div><small>Depth · leaves</small><b>${m.depth} · ${m.leaves}</b></div><div><small>Test samples</small><b>${num(n)}</b></div></div>
      <p class="chart-note">Which inputs the tree relies on (feature importance):</p>${hBars(imp, v => num(v * 100) + '%')}
      <p class="chart-note">Confusion matrix on the 20 % test set (rows = the agronomist's answer, columns = the tree's):</p>
      ${confusion(m.labels, m.confusion_matrix, short)}</div>`;
  }).join('')}</div>
  <div class="card note"><b>Read these numbers honestly.</b> They measure how faithfully each tree reproduces the agronomist's rules on
  <i>simulated</i> sensor data with realistic noise, not performance on the real greenhouse. Tree 3 scores 100 % because the simulated
  faults do not overlap; on real hardware it will be lower. Recalibrate on the prototype, then run <code>python edge_ai/retrain.py</code>.</div>`;
}

function policy() {
  const ir = card.policy.irrigation, cl = card.policy.climate;
  return `<div class="card"><h3>Irrigation (tomato)</h3><p class="chart-note">Soil sensor: raw ADC, higher = drier. Water when the soil is drier than:</p>
    <table class="tbl rules"><tbody>
    <tr><td>Normal day</td><td><b>raw &gt; ${ir.thr_base}</b></td></tr>
    <tr><td>Hot (&gt; ${ir.hot_temp} °C) or full sun (&gt; ${num(ir.bright_lux)} lx)</td><td><b>raw &gt; ${ir.thr_hot}</b> <small>water earlier</small></td></tr>
    <tr><td>Humid (&gt; ${ir.humid_hum} %) and cool (&lt; ${ir.cool_temp} °C)</td><td><b>raw &gt; ${ir.thr_humid}</b> <small>tolerate drier</small></td></tr>
    <tr><td>Tank empty (distance &gt; 10 cm)</td><td><b>Refill alert</b> <small>pump forbidden</small></td></tr></tbody></table></div>
    <div class="card"><h3>Ventilation</h3><p class="chart-note">The fan starts if any of these is true:</p>
    <table class="tbl rules"><tbody>
    <tr><td>Hot</td><td><b>&gt; ${cl.fan_temp} °C</b></td></tr>
    <tr><td>Warm and humid</td><td><b>&gt; ${cl.fan_temp_humid} °C and &gt; ${cl.fan_hum_high} %</b></td></tr>
    <tr><td>Mould risk</td><td><b>humidity &gt; ${cl.fan_hum_mold} %</b></td></tr>
    <tr><td>Warm in full sun</td><td><b>&gt; ${cl.fan_temp_bright} °C and &gt; ${num(cl.bright_lux)} lx</b></td></tr></tbody></table>
    <p class="chart-note">On the Pi the fan changes state at most once a minute, so it never chatters.</p></div>
    <div class="card"><h3>Watering checks (tree 3)</h3><p class="chart-note">60 s after each 5 s pulse:</p>
    <table class="tbl rules"><tbody>
    <tr><td>${lbl('NORMAL')}</td><td>soil wetter by ~120–260, ~0.3–0.8 cm of water used</td></tr>
    <tr><td>${lbl('FUITE')}</td><td>lots of water used (~0.9–2.2 cm) but the soil barely changes</td></tr>
    <tr><td>${lbl('POMPE_BLOQUEE')}</td><td>no water used, no effect on the soil</td></tr>
    <tr><td>${lbl('CAPTEUR_DEFAILLANT')}</td><td>soil readings very unstable (spread &gt; ~20)</td></tr></tbody></table>
    <p class="chart-note">2 leaks or stuck pumps in a row lock the pump until someone checks it.</p></div>`;
}

export async function loadAI(st) {
  if (!card) {
    card = await api('/api/ai');
    setHTML($('#aiQuality'), quality());
    setHTML($('#aiPolicy'), policy());
  }
  if (st) renderAILive(st);
}
