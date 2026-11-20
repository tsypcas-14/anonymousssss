// SmartFarm web app: the v2 design (phone column) + the dashboard panel (3D, statistics, AI, simulation lab).
import { $, api, session, setHTML, toast } from './common.js';
import * as V from './views.js';
import { FarmScene } from './scene.js';
import { initStats, loadStats } from './stats.js';
import { loadAI, renderAILive } from './ai.js';

const PANEL = ['3d', 'stats', 'ai', 'lab'];
const PUBLIC = ['welcome', 'connect', 'signin'];
const ctx = { st: null, me: null, info: null, events: [], history: null, agoText: 'just now' };
let ws = null, lastMsg = 0, lastPhone = '#/', pick = 5, fireAck = false, seenCmd = 0, farm = null, panelView = '3d';
const wide = matchMedia('(min-width: 1100px)');

// ---------------------------------------------------------------- routing
function route() {
  const h = location.hash || '#/';
  const [path, q] = h.slice(2).split('?');
  return { name: path || 'home', params: new URLSearchParams(q || '') };
}

function render() {
  const r = route();
  if (PANEL.includes(r.name)) { openPanel(r.name); if (wide.matches) return paintPhone(routeFrom(lastPhone)); return; }
  closePanelOnMobile();
  lastPhone = location.hash || '#/';
  paintPhone(r);
}
const routeFrom = h => { const [p, q] = h.slice(2).split('?'); return { name: p || 'home', params: new URLSearchParams(q || '') }; };

function viewFor(r) {
  if (!ctx.me) {
    if (!ctx.info) return V.loading();
    return r.name === 'connect' ? V.connect(ctx) : r.name === 'signin' ? V.signin(ctx) : V.welcome(ctx);
  }
  if (!ctx.st) return V.loading();
  if (ws && ws.readyState !== 1 && Date.now() - lastMsg > 6000) return V.offlineView(ctx);
  if (ctx.st.alarms.fire && !fireAck) return V.fire(ctx);
  const views = {
    home: V.home, water: V.water, 'water/run': V.waterRun, 'water/done': V.waterDone, fan: V.fanView, who: V.who,
    log: c => V.log(c, r.params.get('f')), alerts: V.alerts, soil: V.soil, air: V.air, safety: V.safety, plants: V.plants,
    settings: V.settings, thresholds: V.thresholds, help: c => V.help(c, r.params.get('q')),
  };
  return (views[r.name] || V.home)(ctx);
}

function paintPhone(r) {
  const v = viewFor(r);
  const screen = $('#screen');
  // keep what the user typed: never repaint a form that is being edited
  if (screen.contains(document.activeElement) && document.activeElement.matches('input, textarea')) return;
  const openDetails = [...screen.querySelectorAll('details[open]')].map(d => d.querySelector('summary')?.textContent);
  setHTML(screen, v.html);
  screen.querySelectorAll('details').forEach(d => { if (openDetails.includes(d.querySelector('summary')?.textContent)) d.open = true; });
  $('#tabs').hidden = !v.tabs;
  document.querySelectorAll('#tabs a').forEach(a => a.classList.toggle('on', a.dataset.tab === v.tab));
  document.body.dataset.theme = v.theme || 'kraft';
  document.querySelector('meta[name=theme-color]').content = { forest: '#1f4a2c', wheat: '#e8b746', fire: '#a8392b', leaf: '#e3efd6' }[v.theme] || '#f4eee0';
  const r2 = route();
  if (screen.dataset.route !== r2.name) { screen.scrollTop = 0; screen.dataset.route = r2.name; }
}

// ---------------------------------------------------------------- dashboard panel
function openPanel(name) {
  if (name === 'lab' && !ctx.st?.simulated) name = '3d';
  panelView = name;
  const p = $('#panel');
  p.hidden = !ctx.me;
  document.body.classList.toggle('panel-open', !wide.matches);
  document.querySelectorAll('.ptabs a').forEach(a => a.classList.toggle('on', a.dataset.p === name));
  document.querySelectorAll('.pview').forEach(s => s.classList.toggle('on', s.id === 'p-' + name));
  $('#panel .back-link').href = lastPhone;
  if (name === '3d') { if (!farm) farm = new FarmScene($('#scene'), $('#labels')); farm.active = true; farm.resize(); if (ctx.st) farm.update(ctx.st); }
  else if (farm) farm.active = false;
  if (name === 'stats') loadStats().catch(e => toast(e.message));
  if (name === 'ai') loadAI(ctx.st).catch(e => toast(e.message));
  if (name === 'lab') renderLab();
}
function closePanelOnMobile() {
  if (wide.matches) { if (ctx.me) { $('#panel').hidden = false; if (!document.querySelector('.pview.on')) openPanel(panelView); } return; }
  document.body.classList.remove('panel-open');
  $('#panel').hidden = true;
  if (farm) farm.active = false;
}
wide.addEventListener('change', () => { if (ctx.me) { $('#panel').hidden = false; openPanel(panelView); } render(); });

function renderLab() {
  const st = ctx.st; if (!st?.simulated) return;
  const names = { 0: 'Pause', 1: 'Real time', 60: '1 min/s', 600: '10 min/s', 3600: '1 h/s', 14400: '4 h/s' };
  setHTML($('#speedSeg'), st.sim.speeds.map(v => `<button data-speed="${v}" class="${v === st.sim.speed ? 'on' : ''}">${names[v]}</button>`).join(''));
  setHTML($('#simEnv'), `<button data-ev="dry">Dry the soil</button><button data-ev="refill">Fill the tank</button>
    <button data-ev="flame" class="${st.sim.flame ? 'on' : 'danger'}">${st.sim.flame ? 'Put the flame out' : 'Light a flame'}</button>
    <button data-ev="reset">Restart the simulation</button>`);
  const f = st.sim.fault;
  setHTML($('#simFaults'), `<button data-ev="leak" class="${f === 'leak' ? 'on' : ''}">Leak in the pipe</button>
    <button data-ev="blocked" class="${f === 'blocked' ? 'on' : ''}">Pump stuck</button>
    <button data-ev="sensor" class="${f === 'sensor' ? 'on' : ''}">Faulty soil probe</button>
    <button data-ev="fix" ${f ? '' : 'disabled'}>Repair everything</button>`);
}

// ---------------------------------------------------------------- live data
function connect() {
  if (!session.token) return;
  try { ws?.close(); } catch { /* already closed */ }
  ws = new WebSocket(`${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/ws?token=${encodeURIComponent(session.token)}`);
  ws.onmessage = e => { lastMsg = Date.now(); onState(JSON.parse(e.data)); };
  ws.onclose = e => {
    if (e.code === 4401) return signedOut();
    setTimeout(() => { if (session.token) connect(); }, 2500);
    setTimeout(render, 6500);
  };
}

function onState(st) {
  const prev = ctx.st;
  ctx.st = st;
  if (!prev) seenCmd = st.command?.id || 0;          // a result from before this page was opened is old news
  if (!st.alarms.fire) fireAck = false;
  $('#labTab').hidden = !st.simulated;
  // the command we sent has finished: show its result
  const c = st.command;
  if (c && c.id !== seenCmd && ['success', 'error', 'refused', 'stopped'].includes(c.status) && c.kind === 'water') {
    seenCmd = c.id;
    if (route().name.startsWith('water')) location.hash = '#/water/done';
    else toast(c.status === 'success' ? 'Watering done.' : 'The watering did not work: open Watering.');
  }
  if (c && c.kind === 'fan' && c.id !== seenCmd && c.status !== 'sent' && c.status !== 'received') {
    seenCmd = c.id; toast(c.status === 'success' ? c.message : c.message || 'The fan did not change.');
  }
  if (!prev || prev.sensors.timestamp.slice(0, 15) !== st.sensors.timestamp.slice(0, 15)) refreshSide();
  if (farm?.active) farm.update(st);
  if (panelView === 'ai' && !$('#panel').hidden) renderAILive(st);
  if (panelView === 'lab' && !$('#panel').hidden) renderLab();
  render();
}

async function refreshSide() {
  try {
    const [ev, h] = await Promise.all([api('/api/events?limit=300'), api('/api/history?hours=24')]);
    ctx.events = ev; ctx.history = h; render();
  } catch { /* offline: keep the last ones */ }
}
setInterval(() => {
  if (!ctx.me) return;
  const s = Math.round((Date.now() - lastMsg) / 1000);
  ctx.agoText = s < 20 ? 'just now' : s < 90 ? `${s} s ago` : `${Math.round(s / 60)} min ago`;
  if (route().name === 'log' || route().name === 'alerts') refreshSide();
  if (panelView === 'stats' && !$('#panel').hidden && !document.hidden) loadStats().catch(() => {});
}, 8000);

// ---------------------------------------------------------------- session
async function start() {
  // Opened by the Flutter app: it passes its session and asks for the dashboard only (3D, statistics, AI, lab)
  const qp = new URLSearchParams(location.search);
  if (qp.get('token')) session.token = qp.get('token');
  if (qp.get('embed')) document.body.classList.add('embed');
  if (qp.has('token')) history.replaceState(null, '', location.pathname + location.hash);   // keep the token out of the address bar
  render();
  try { ctx.info = await api('/api/info'); } catch { ctx.info = { name: 'The greenhouse' }; }
  if (session.token) {
    try { ctx.me = await api('/api/me'); } catch { session.token = null; }
  }
  if (ctx.me) { $('#panel').hidden = !wide.matches; connect(); refreshSide(); if (wide.matches) openPanel(panelView); }
  if (!ctx.me && !PUBLIC.includes(route().name)) location.hash = '#/welcome';
  else if (ctx.me && PUBLIC.includes(route().name)) location.hash = '#/';
  render();
}
function signedIn(res) {
  session.token = res.token;
  ctx.me = { user: res.user };
  api('/api/me').then(m => { ctx.me = m; render(); });
  connect(); refreshSide();
  if (wide.matches) { $('#panel').hidden = false; openPanel(panelView); }
  location.hash = '#/';
}
function signedOut() {
  session.token = null; ctx.me = null; ctx.st = null; ctx.events = [];
  try { ws?.close(); } catch { /* closed */ }
  $('#panel').hidden = true; document.body.classList.remove('panel-open');
  location.hash = '#/welcome'; render();
}
window.addEventListener('sf:unauth', signedOut);

// ---------------------------------------------------------------- actions
async function act(fn, okMsg) {
  try { const r = await fn(); if (okMsg) toast(okMsg); return r; } catch (e) { toast(e.message); }
}
function openSheet() { const s = $('#sheet'); s.hidden = false; setHTML(s, V.waterSheet(ctx, pick)); }
function closeSheet() { $('#sheet').hidden = true; }

document.addEventListener('click', async e => {
  const b = e.target.closest('[data-action]');
  if (b) {
    const a = b.dataset.action;
    if (a === 'water-sheet') return openSheet();
    if (a === 'sheet-close') return closeSheet();
    if (a === 'pick') { pick = +b.dataset.s; return openSheet(); }
    if (a === 'water-go') { closeSheet(); if (await act(() => api('/api/water', { seconds: pick }))) location.hash = '#/water/run'; return; }
    if (a === 'water-retry') { if (await act(() => api('/api/water', { seconds: +b.dataset.s }))) location.hash = '#/water/run'; return; }
    if (a === 'water-stop') return act(() => api('/api/water/stop', {}), 'Watering stopped.');
    if (a === 'ack-command') return;
    if (a === 'fan') return act(() => api('/api/fan', { on: b.dataset.on === '1' }));
    if (a === 'mode') return act(() => api('/api/mode', { equipment: b.dataset.eq, mode: b.dataset.mode }),
      b.dataset.mode === 'auto' ? 'The greenhouse decides again.' : 'You decide for the next hour.');
    if (a === 'fire-ack') { fireAck = true; location.hash = '#/safety'; return render(); }
    if (a === 'retry') { connect(); return toast('Looking for the greenhouse…'); }
    if (a === 'unlock') return act(() => api('/api/pump/unlock', {}), 'Pump unlocked.');
    if (a === 'logout') { await api('/api/auth/logout', {}).catch(() => {}); return signedOut(); }
    return;
  }
  const lab = e.target.closest('#p-lab button');
  if (lab && !lab.disabled) {
    if (lab.dataset.speed) return act(() => api('/api/sim', { speed: +lab.dataset.speed }));
    if (lab.dataset.ev === 'reset' && !confirm('Restart the simulation from the beginning?')) return;
    return act(() => api('/api/sim', { event: lab.dataset.ev }), {
      dry: 'Soil dried: tree 1 should water.', refill: 'Tank filled.', flame: 'Flame sensor switched.', reset: 'Simulation restarted.',
      leak: 'Leak injected: water by hand to see tree 3 find it.', blocked: 'Pump stuck: water by hand to see tree 3 find it.',
      sensor: 'Soil probe now noisy.', fix: 'Hardware repaired.' }[lab.dataset.ev]);
  }
  if (e.target === $('#sheet')) closeSheet();
});

document.addEventListener('change', e => {
  if (e.target.dataset.action === 'notify') act(() => api('/api/me', { notify: e.target.value }, 'PATCH').then(r => { ctx.me.user = r.user; }), 'Saved.');
});

document.addEventListener('submit', async e => {
  const f = e.target.closest('form[data-form]'); if (!f) return;
  e.preventDefault();
  const data = Object.fromEntries(new FormData(f));
  const err = f.querySelector('.form-error');
  const btn = f.querySelector('button[type=submit], button:not([type])');
  btn && (btn.disabled = true);
  try {
    const k = f.dataset.form;
    if (k === 'signup') signedIn(await api('/api/auth/signup', data));
    else if (k === 'signin') signedIn(await api('/api/auth/login', data));
    else if (k === 'contact' || k === 'greenhouse') { ctx.me.greenhouse = await api('/api/settings', data, 'PATCH'); toast('Saved.'); f.closest('details').open = false; }
    else if (k === 'me') { ctx.me.user = (await api('/api/me', data, 'PATCH')).user; toast('Saved.'); f.closest('details').open = false; }
    document.activeElement?.blur(); render();
  } catch (x) {
    if (err) { err.hidden = false; err.textContent = x.message; } else toast(x.message);
  } finally { btn && (btn.disabled = false); }
});

window.addEventListener('hashchange', render);
$('#viewReset').addEventListener('click', () => farm?.resetView());
initStats();
if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
start();
