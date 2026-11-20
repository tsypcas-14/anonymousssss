// Stats tab: KPI tiles, time series, daily summary, patterns, decision mix, sensor ranges.
import { BarChart, LineChart, proportionBar } from './charts.js';
import { $, api, classColor, esc, lbl, lux, num, ORDER, setHTML } from './common.js';

const LINES = [
  { key: 'soil', title: 'Soil moisture', unit: '%', min: 0, max: 100, note: 'Blue ticks on the baseline are waterings (5 s pulses).', marks: true },
  { key: 'temp', title: 'Air temperature', unit: ' °C', fmt: v => v.toFixed(1) },
  { key: 'hum', title: 'Air humidity', unit: ' %', max: 100 },
  { key: 'light', title: 'Light', unit: '', min: 0, fmt: v => v >= 1000 ? (v / 1000).toFixed(0) + 'k' : Math.round(v) + '' },
  { key: 'tank', title: 'Reservoir level', unit: ' %', min: 0, max: 100, threshold: 0, thresholdLabel: 'empty: pump forbidden' },
  { key: 'fanPct', title: 'Fan running', unit: ' %', min: 0, max: 100, note: 'Share of each 5-minute slot with the fan on.' },
];

let charts = null, hours = 24, last = null;

function build() {
  const mk = (box, Cls, def) => { const el = document.createElement('div'); $(box).appendChild(el); return new Cls(el, def); };
  charts = {
    lines: LINES.map(def => [def, mk('#lineCharts', LineChart, def)]),
    pulses: mk('#dailyCharts', BarChart, { title: 'Waterings per day', key: 'pulses', labelEvery: 1 }),
    water: mk('#dailyCharts', BarChart, { title: 'Water used per day', key: 'water_ml', unit: ' mL', labelEvery: 1, note: 'Measured: tank level before vs 60 s after each pulse.' }),
    fan: mk('#dailyCharts', BarChart, { title: 'Fan running time per day', key: 'fan_h', unit: ' h', fmt: v => v.toFixed(1), labelEvery: 1 }),
    trange: mk('#dailyCharts', BarChart, { title: 'Daily temperature range', key: 'temp_max', loKey: 'temp_min', markKey: 'temp_mean', unit: ' °C', fmt: v => v.toFixed(1), labelEvery: 1, note: 'Bar = min to max · white line = mean.' }),
    byHour: mk('#patternCharts', BarChart, { title: 'Waterings by hour of day', key: 'v', labelEvery: 3, note: 'When does the agent water? Mostly after the sunny hours dry the soil.' }),
    tHour: mk('#patternCharts', BarChart, { title: 'Temperature by hour of day', key: 'max', loKey: 'min', markKey: 'mean', unit: ' °C', fmt: v => v.toFixed(1), labelEvery: 3, note: 'Bar = coldest to warmest reading at that hour · white line = mean.' }),
    soilHist: mk('#patternCharts', BarChart, { title: 'Soil moisture distribution', key: 'v', unit: ' samples', labelEvery: 2, note: 'How often the soil sat at each moisture level (5-minute samples).' }),
    tempHist: mk('#patternCharts', BarChart, { title: 'Temperature distribution', key: 'v', unit: ' samples', labelEvery: 3 }),
  };
}

function tile(label, value, sub, cls = '') {
  return `<div class="tile ${cls}"><small>${esc(label)}</small><b>${value}</b>${sub ? `<span>${sub}</span>` : ''}</div>`;
}

export async function loadStats() {
  if (!charts) build();
  const [st, h] = await Promise.all([api(`/api/stats?hours=${hours}`), api(`/api/history?hours=${hours}`)]);
  last = st;
  const k = st.kpi;
  $('#statsSub').textContent = st.points
    ? `${st.points} samples (one every 5 minutes) since ${new Date(st.since).toLocaleString('en-GB', { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}.`
    : 'Collecting the first samples…';
  setHTML($('#kpis'),
    tile('Waterings', num(k.pulses), '5 s pulses decided by tree 1') +
    tile('Water used', num(k.water_l * 1000) + ' mL', 'measured on the tank') +
    tile('Watering efficiency', k.efficiency_pct == null ? '–' : num(k.efficiency_pct) + '%', 'checks judged NORMAL by tree 3', k.efficiency_pct != null && k.efficiency_pct < 80 ? 'warn' : '') +
    tile('Soil in good range', num(k.soil_ok_pct) + '%', `of the time (raw ≤ ${st.thresholds.stress_raw})`, k.soil_ok_pct < 80 ? 'warn' : '') +
    tile('Comfortable air', num(k.temp_ok_pct) + '%', `of the time ${st.thresholds.temp_ok[0]}–${st.thresholds.temp_ok[1]} °C`) +
    tile('Fan running', num(k.fan_h, 1) + ' h', `${num(k.fan_pct)}% of the time`) +
    tile('Mean air', k.temp ? num(k.temp.mean, 1) + ' °C' : '–', k.hum ? `humidity ${num(k.hum.mean)}%` : '') +
    tile('Reservoir now', k.tank_now == null ? '–' : num(k.tank_now) + '%', '', k.tank_now != null && k.tank_now < 15 ? 'warn' : ''));

  const pts = h.points.map(p => ({ ...p, fanPct: p.fan == null ? null : p.fan * 100 }));
  for (const [def, ch] of charts.lines) ch.set(pts, def.marks ? h.watered : []);

  const daily = st.daily.map(d => ({ ...d, label: d.label.slice(0, 6) + (d.complete ? '' : '*'), water_ml: Math.round(d.water_l * 1000) }));
  charts.pulses.o.total = `${num(k.pulses)} total`; charts.pulses.set(daily);
  charts.water.o.total = `${num(k.water_l * 1000)} mL total`; charts.water.set(daily);
  charts.fan.o.total = `${num(k.fan_h, 1)} h total`; charts.fan.set(daily);
  charts.trange.set(daily);
  const hrs = [...Array(24).keys()];
  charts.byHour.o.total = `${num(k.pulses)} waterings`;
  charts.byHour.set(hrs.map(i => ({ label: String(i).padStart(2, '0') + 'h', v: st.by_hour.pulses[i] })));
  charts.tHour.set(hrs.map(i => ({ label: String(i).padStart(2, '0') + 'h', ...(st.by_hour.temp[i] || { max: null }) })));
  const hist = (H, unit) => H.counts.map((v, i) => ({ label: `${H.edges[i]}${unit}`, v }));
  charts.soilHist.set(hist(st.hist.soil, '%'));
  charts.tempHist.set(hist(st.hist.temp, '°'));

  setHTML($('#dailyTable'), `<table class="tbl"><thead><tr><th>Day</th><th>Waterings</th><th>Water</th><th>Fan</th><th>Temp min / mean / max</th><th>Soil mean</th><th>Humidity mean</th><th>Max light</th></tr></thead><tbody>
    ${st.daily.slice().reverse().map(d => `<tr><td>${esc(d.label)}${d.complete ? '' : ' <small>(partial)</small>'}</td><td>${d.pulses}</td><td>${num(d.water_l * 1000)} mL</td><td>${num(d.fan_h, 1)} h</td>
    <td>${num(d.temp_min, 1)} / ${num(d.temp_mean, 1)} / ${num(d.temp_max, 1)} °C</td><td>${num(d.soil_mean)}%</td><td>${num(d.hum_mean)}%</td><td>${lux(d.light_max)}</td></tr>`).join('')}</tbody></table>
    <p class="chart-note">* partial day (the period starts or ends during that day).</p>`);

  const mix = (tree, counts) => proportionBar(ORDER[tree].map(c => ({ name: lbl(c), value: counts[c] || 0, color: classColor(c) })));
  setHTML($('#mixIrr'), mix('irrigation', st.decisions.irrigation) + `<p class="chart-note">“Water now” lasts only until the 5 s pulse wets the soil, so it is a thin slice: ${num(k.pulses)} pulses in the period.</p>`);
  setHTML($('#mixClim'), mix('climate', st.decisions.climate));
  const nd = Object.values(st.anomalies).reduce((a, b) => a + b, 0);
  setHTML($('#mixDiag'), nd ? mix('anomaly', st.anomalies) + `<p class="chart-note">${nd} checks in the period.</p>` : '<p class="sub">No watering checked in this period yet.</p>');

  const r = (name, s, unit, d = 0) => `<tr><td>${name}</td><td>${s ? num(s.min, d) : '–'}${unit}</td><td>${s ? num(s.mean, d) : '–'}${unit}</td><td>${s ? num(s.max, d) : '–'}${unit}</td></tr>`;
  setHTML($('#rangeTable'), `<table class="tbl"><thead><tr><th>Sensor</th><th>Min</th><th>Mean</th><th>Max</th></tr></thead><tbody>
    ${r('Soil moisture', k.soil, ' %')}${r('Soil (raw ADC, higher = drier)', k.soil_raw, '')}${r('Air temperature', k.temp, ' °C', 1)}${r('Air humidity', k.hum, ' %')}
    <tr><td>Light (BH1750)</td><td>–</td><td>–</td><td>${lux(k.light_max)}</td></tr></tbody></table>`);
}

export function initStats() {
  $('#rangeSeg').addEventListener('click', e => {
    const b = e.target.closest('button'); if (!b) return;
    hours = +b.dataset.h;
    document.querySelectorAll('#rangeSeg button').forEach(x => x.classList.toggle('on', x === b));
    document.querySelector('#p-stats .wrap').classList.add('loading');
    loadStats().finally(() => document.querySelector('#p-stats .wrap').classList.remove('loading'));
  });
}
