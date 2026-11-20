// Every screen of the SmartFarm v2 design, rendered from the live state of the greenhouse.
// A view returns { html, tabs, tab, theme }: tabs = show the bottom bar, tab = which one is lit, theme = status-bar colour.
import { esc } from './common.js';
import { fan, flameTile, icon, landscape, logo, offline, soilSection, spark, sprout, sprouts, tank, valve } from './art.js';

// ---------------------------------------------------------------- words for numbers
const two = n => String(n).padStart(2, '0');
export const hm = iso => { if (!iso) return ''; const d = new Date(iso); return `${two(d.getHours())}:${two(d.getMinutes())}`; };
const cap = s => s ? s[0].toUpperCase() + s.slice(1) : s;
const crop = ctx => (ctx.me?.greenhouse?.crop || 'tomatoes').toLowerCase();
const house = ctx => ctx.me?.greenhouse?.name || 'My greenhouse';
const firstName = ctx => (ctx.me?.user?.name || '').split(' ')[0];

function nowOf(ctx) { return new Date(ctx.st?.sensors?.timestamp || Date.now()); }

export function dayPhrase(iso, ctx, lower = false) {
  if (!iso) return '';
  const d = new Date(iso), now = nowOf(ctx);
  const same = (a, b) => a.toDateString() === b.toDateString();
  const yest = new Date(now); yest.setDate(now.getDate() - 1);
  let s;
  if (same(d, now)) s = d.getHours() < 12 ? 'this morning' : d.getHours() < 18 ? 'this afternoon' : 'this evening';
  else if (same(d, yest)) s = 'yesterday';
  else s = 'on ' + d.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'short' });
  s += ` at ${hm(iso)}`;
  return lower ? s : cap(s);
}

function greeting(ctx) {
  const h = nowOf(ctx).getHours();
  const g = h >= 5 && h < 12 ? 'Good morning' : h >= 12 && h < 18 ? 'Good afternoon' : 'Good evening';
  return firstName(ctx) ? `${g}, ${esc(firstName(ctx))}` : g;
}

export function soilWord(raw) {
  if (raw == null) return 'No news';
  return raw <= 450 ? 'Well watered' : raw <= 600 ? 'Moist enough' : raw <= 650 ? 'A bit dry' : 'Dry';
}
function lightWord(lx) {
  if (lx == null) return 'no news of the light';
  return lx < 50 ? 'night sky' : lx < 8000 ? 'dim light' : lx < 25000 ? 'cloudy sky' : 'full sun';
}
export function tankPhrase(days, pct, low) {
  if (low) return 'Empty: the pump is stopped';
  if (days == null) return pct >= 50 ? 'Plenty of water' : 'Water level is going down';
  if (days < 1) return 'Water for less than a day';
  const whole = Math.floor(days), frac = days - whole;
  if (frac >= .25 && frac < .75) return `Water for ${whole} and a half day${whole >= 1 ? 's' : ''}`;
  const n = Math.round(days);
  return `Water for ${n} day${n > 1 ? 's' : ''}`;
}
const under = w => `<span class="u">${w}</span>`;
const stamp = (t, tilt = -4) => `<span class="stamp" style="--tilt:${tilt}deg">${t}</span>`;

function head(title, back = '#/', extra = '') {
  return `<header class="bar"><a class="back" href="${back}" aria-label="Back">${icon.back}</a><h1>${title}</h1>${extra}</header>`;
}
function row({ href, ic, title, sub, value, warn, muted, cls = '' }) {
  return `<a class="line ${muted ? 'muted' : ''} ${cls}" href="${href}">
    <span class="lic">${ic}</span><span class="ltx"><b>${title}</b><small>${warn ? `<i class="w">${icon.warn}</i>` : ''}${sub}</small></span>
    ${value != null ? `<span class="lval">${value}</span>` : ''}<span class="chev">${icon.chevron}</span></a>`;
}
function modePill(ctx, eq) {
  const m = ctx.st.modes?.[eq];
  if (!m || m.mode === 'auto') return `<a class="mode" href="#/who">${icon.wheel}<span>Auto</span></a>`;
  return `<a class="mode manual" href="#/who">${icon.user}<span>Manual · until ${hm(new Date(Date.parse(ctx.st.sensors.timestamp) + m.seconds_left * 1000).toISOString())}</span></a>`;
}

// ---------------------------------------------------------------- first launch & accounts
export function loading() {
  return { html: `<div class="center-screen">${sprouts()}<h2>Looking for the greenhouse…</h2><p class="muted">It takes a few seconds.</p>
    <div class="skel"><i></i><i></i></div></div>` };
}

export function welcome(ctx) {
  return { theme: 'forest', html: `<div class="welcome">
    <div class="brand">${logo(34)}<span>SmartFarm</span></div>
    <h1>Hello.<br>I watch over your ${under('greenhouse.')}</h1>
    <p>I tell you when everything is fine, and I warn you when there is something to do.</p>
    <div class="welcome-land">${landscape('good', 170)}</div>
    <div class="welcome-cta">
      <a class="btn wheat" href="#/connect">Connect my greenhouse</a>
      ${ctx.info?.has_accounts ? '<a class="link light" href="#/signin">I already have an account</a>' : ''}
    </div></div>` };
}

export function connect(ctx) {
  const n = ctx.info?.name || 'The greenhouse';
  return { html: `${head('Connect my greenhouse', '#/welcome')}
    <div class="pad">
      <p class="lead">Three little things, only once.</p>
      <ol class="steps done-all">
        <li class="ok"><i>${icon.check}</i><b>On the greenhouse's network</b><small>This device can reach the Raspberry Pi</small></li>
        <li class="ok"><i>${icon.check}</i><b>${esc(n)} found</b><small>It answers, everything is fine</small></li>
        <li class="now"><i></i><b>Your account</b><small>With the code written on the greenhouse</small></li>
      </ol>
      <form class="form" data-form="signup" autocomplete="on">
        <label>First name<input name="name" autocomplete="given-name" required maxlength="40"></label>
        <label>Email<input name="email" type="email" autocomplete="email" required></label>
        <label>Password<input name="password" type="password" autocomplete="new-password" minlength="8" required><small>At least 8 characters.</small></label>
        <label>Greenhouse code<input name="code" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" required placeholder="6 digits"><small>Shown on the Pi: in <code>greenhouse_code.txt</code> or in its logs.</small></label>
        <p class="form-error" hidden></p>
        <button class="btn forest" type="submit">Let's go</button>
      </form>
      <p class="center"><a class="link" href="#/signin">I already have an account</a></p>
    </div>` };
}

export function signin() {
  return { html: `${head('Sign in', '#/welcome')}
    <div class="pad">
      <p class="lead">Welcome back.</p>
      <form class="form" data-form="signin" autocomplete="on">
        <label>Email<input name="email" type="email" autocomplete="email" required></label>
        <label>Password<input name="password" type="password" autocomplete="current-password" required></label>
        <p class="form-error" hidden></p>
        <button class="btn forest" type="submit">Sign in</button>
      </form>
      <p class="center"><a class="link" href="#/connect">Create an account</a></p>
    </div>` };
}

// ---------------------------------------------------------------- home
export function home(ctx) {
  const st = ctx.st, s = st.sensors, a = st.alarms, ir = st.irrigation, th = st.thresholds;
  const watering = st.actuators.pump || ir.phase === 'checking';
  const dry = s.soil_raw != null && s.soil_raw > th.water_raw;
  let state = 'watch', title;
  if (a.missing) title = `A sensor ${under('stopped')} answering.`;
  else if (a.pump_locked) title = `The pump needs a ${under('check.')}`;
  else if (a.tank_low) title = `The tank is ${under('empty.')}`;
  else if (watering && dry) title = `The ${crop(ctx)} are ${under('thirsty.')} I'm watering.`;
  else if (watering) title = `${under('Watering')} the ${crop(ctx)}.`;
  else if (dry) title = `The ${crop(ctx)} are ${under('thirsty.')}`;
  else if (s.water_level_pct != null && s.water_level_pct < th.tank_watch_pct) title = `The tank is getting ${under('low.')}`;
  else { state = 'good'; title = `Your ${crop(ctx)} are doing ${under('well.')}`; }
  const since = watering ? ' · watering now' : ` · ${ctx.agoText}`;
  const manual = Object.entries(st.modes).filter(([, m]) => m.mode === 'manual');
  const d = nowOf(ctx).toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' });
  const alertDot = st.alerts.length ? '<i class="dot"></i>' : '';
  const soilSub = s.soil_raw == null ? 'No news from the sensor' : soilWord(s.soil_raw);
  return { tabs: true, tab: 'home', theme: state === 'good' ? 'forest' : 'wheat', html: `
    <section class="hero ${state}">
      <div class="hero-top"><span>${d}</span><span class="hero-icons"><a href="#/alerts" aria-label="Alerts">${icon.bell}${alertDot}</a><a href="#/settings" aria-label="Settings">${icon.wheel}</a></span></div>
      <p class="hello">${greeting(ctx)}</p>
      <h1>${title}</h1>
      <p class="where">${esc(house(ctx))}${since}</p>
      ${landscape(state, 150)}
    </section>
    <div class="lines">
      ${row({ href: '#/soil', ic: icon.soil, title: 'The soil', sub: soilSub, value: s.soil_pct == null ? '–' : Math.round(s.soil_pct) + ' %', warn: dry, cls: 'soil' })}
      ${row({ href: '#/water', ic: icon.tank, title: 'The tank', sub: tankPhrase(st.tank_days, s.water_level_pct, a.tank_low), value: s.water_level_pct == null ? '–' : Math.round(s.water_level_pct) + ' %', warn: a.tank_low || s.water_level_pct < th.tank_watch_pct, cls: 'tank' })}
      ${row({ href: '#/air', ic: icon.thermo, title: 'The air and the light', sub: s.air_temp == null ? 'No news from the sensor' : `It is ${Math.round(s.air_temp)} °C, ${lightWord(s.light)}`, cls: 'air' })}
      ${row({ href: '#/safety', ic: icon.flame, title: 'Safety', sub: a.fire ? 'A flame is detected!' : 'No flame', warn: a.fire, cls: 'safety' })}
      ${row({ href: '#/plants', ic: icon.leafSearch, title: 'Plant health', sub: 'Coming soon', muted: true })}
      ${row({ href: '#/3d', ic: icon.cube, title: 'The greenhouse in 3D', sub: 'Live view of every sensor', cls: 'only-mobile' })}
    </div>
    <p class="foot-note">${icon.wheel}${manual.length ? `You are in charge of the ${manual.map(([eq]) => eq === 'fan' ? 'ventilation' : 'watering').join(' and the ')} for now.` : state === 'good' ? 'The greenhouse decides on its own. Nothing to do.' : 'The greenhouse decides on its own.'}</p>` };
}

// ---------------------------------------------------------------- watering
export function water(ctx) {
  const st = ctx.st, s = st.sensors, ld = st.last_diagnosis;
  const last = ld ? `${dayPhrase(ld.time, ctx)}, <b>${ld.seconds} seconds</b>${ld.manual ? ' by hand' : ''}: the soil was at ${Math.round(ld.soil_before_pct)} %.` : 'No watering yet.';
  const busy = st.actuators.pump || st.irrigation.phase === 'checking';
  return { tabs: true, tab: 'water', html: `
    <header class="bar plain"><h1>Watering</h1>${modePill(ctx, 'irrigation')}</header>
    <div class="pad">
      <div class="tank-row">${tank(s.water_level_pct)}<div><h2 class="big-phrase">${tankPhrase(st.tank_days, s.water_level_pct, st.alarms.tank_low)}</h2>
        <p class="muted">${s.water_level_pct == null ? 'No news from the level sensor' : Math.round(s.water_level_pct) + ' % in the tank'}</p></div></div>
      <p class="note green">${last}</p>
      ${st.irrigation.locked ? `<p class="note wheat">The pump is locked after two faulty waterings. Check it, then unlock it in <a class="link" href="#/settings">Settings</a>.</p>` : ''}
      <div class="push"></div>
      ${busy ? `<a class="btn ghost" href="#/water/run">${icon.drop}Watering in progress…</a>` :
        `<button class="btn wheat" data-action="water-sheet" ${st.alarms.tank_low || st.irrigation.locked || st.alarms.fire ? 'disabled' : ''}>${icon.drop}Water now</button>`}
      <p class="center"><a class="link" href="#/log?f=irrigation">See this week's waterings</a></p>
    </div>` };
}

export function waterSheet(ctx, pick) {
  const opts = ctx.st.thresholds.manual_seconds;
  return `<div class="sheet-card"><span class="grab"></span><h2>How long?</h2>
    <div class="chips">${opts.map(o => `<button data-action="pick" data-s="${o}" class="${o === pick ? 'on' : ''}">${o} s</button>`).join('')}</div>
    <button class="btn wheat" data-action="water-go">${icon.drop}Water ${pick} seconds</button>
    <p class="muted center small">You take over. Back to auto in 1 h.</p>
    <p class="center"><button class="link" data-action="sheet-close">Cancel</button></p></div>`;
}

export function waterRun(ctx) {
  const c = ctx.st.command;
  if (!c || c.kind !== 'water') return { html: `${head('Watering', '#/water')}<div class="pad"><p class="muted">No watering in progress.</p></div>`, tabs: true, tab: 'water' };
  const S = c.steps || {};
  const list = [
    ['sent', 'Order sent', hm(S.sent)], ['received', 'The greenhouse got it', hm(S.received)],
    ['running', 'The pump starts…', S.running ? hm(S.running) : 'A few seconds'],
    ['checking', 'The water flows', S.checking ? hm(S.checking) : `For ${c.seconds} seconds`],
    ['done', 'Checking the soil', S.done ? hm(S.done) : 'One minute later, tree 3 checks it worked'],
  ];
  const firstMissing = list.findIndex(([k]) => !S[k]);
  return { tabs: true, tab: 'water', html: `${head('Watering', '#/water')}
    <div class="pad">
      <h1 class="screen-title">I'm starting the watering.</h1>
      <p class="muted">${c.seconds} seconds, by hand.</p>
      <ol class="steps">${list.map(([k, t, sub], i) => `<li class="${S[k] ? 'ok' : i === firstMissing ? 'now' : ''}"><i>${S[k] ? icon.check : ''}</i><b>${t}</b><small>${sub}</small></li>`).join('')}</ol>
      <div class="push"></div>
      ${['sent', 'received', 'running'].includes(c.status) ? '<button class="btn outline" data-action="water-stop">Stop</button>' : ''}
    </div>` };
}

export function waterDone(ctx) {
  const c = ctx.st.command;
  if (!c) return waterRun(ctx);
  if (c.status === 'success') {
    const r = c.result;
    return { theme: 'leaf', html: `<div class="result success">${sprout()}<h1>Watering done.</h1>
      <p>${r.seconds} seconds. The soil went up to ${Math.round(r.soil_after_pct)} %. The ${crop(ctx)} say thank you.</p>
      <div class="push"></div><a class="btn forest" href="#/water" data-action="ack-command">Thanks</a></div>` };
  }
  const title = c.status === 'refused' ? 'Not now.' : c.status === 'stopped' ? 'Watering stopped.' :
    c.result?.label === 'FUITE' ? 'The water went somewhere else.' : c.result?.label === 'CAPTEUR_DEFAILLANT' ? 'The soil probe is confused.' : "The water didn't flow.";
  return { html: `<div class="result error">${valve()}<h1>${title}</h1><p>${esc(c.message || '')}</p>
    <div class="push"></div>
    ${c.status === 'stopped' ? '' : `<button class="btn wheat" data-action="water-retry" data-s="${c.seconds}">Try again</button>`}
    <p class="center"><a class="link" href="#/help" data-action="ack-command">What else can I do?</a></p>
    ${c.status === 'stopped' ? '<a class="btn forest" href="#/water" data-action="ack-command">OK</a>' : ''}</div>` };
}

// ---------------------------------------------------------------- ventilation
export function fanView(ctx) {
  const st = ctx.st, on = st.actuators.fan, th = st.thresholds;
  const runs = st.fan_runs_today || [];
  const fmtRun = r => r.end ? `from <b>${hm(r.start)}</b> to <b>${hm(r.end)}</b>` : `since <b>${hm(r.start)}</b>`;
  const maxT = Math.max(...runs.map(r => r.max_temp || 0));
  const note = runs.length ? `Today it ran ${runs.slice(-2).map(fmtRun).join(', then ')}. The air reached ${maxT.toFixed(1)} °C.` : 'It has not run today.';
  return { tabs: true, tab: 'fan', html: `
    <header class="bar plain"><h1>Ventilation</h1>${modePill(ctx, 'fan')}</header>
    <div class="pad">
      <div class="tank-row">${fan(on)}<div><h2 class="big-phrase">${on ? 'Fan running' : 'Fan stopped'}</h2>
        <p class="muted">It starts above ${th.fan_temp} °C, or when the air is too damp.</p></div></div>
      <p class="note green">${note}</p>
      <div class="push"></div>
      <button class="btn wheat" data-action="fan" data-on="${on ? 0 : 1}" ${st.alarms.fire ? 'disabled' : ''}>${icon.fan}${on ? 'Stop the fan' : 'Ventilate now'}</button>
      <p class="center"><a class="link" href="#/who">Who decides: the greenhouse or me?</a></p>
    </div>` };
}

export function who(ctx) {
  const st = ctx.st;
  const block = (eq, ic, title, autoText) => {
    const m = st.modes[eq], manual = m.mode === 'manual';
    const until = manual ? hm(new Date(Date.parse(st.sensors.timestamp) + m.seconds_left * 1000).toISOString()) : '';
    return `<div class="who"><h2>${ic}${title}</h2>
      <div class="seg2"><button data-action="mode" data-eq="${eq}" data-mode="auto" class="${manual ? '' : 'on'}">The greenhouse decides</button>
      <button data-action="mode" data-eq="${eq}" data-mode="manual" class="${manual ? 'on' : ''}">I decide</button></div>
      <p class="muted">${manual ? `${esc(m.by || 'You')} took over at ${hm(m.since)}. Back to auto at ${until} if nobody touches it.` : autoText}</p></div>`;
  };
  return { tabs: true, tab: 'fan', html: `${head('Who decides?', '#/fan')}
    <div class="pad"><p class="lead">For each piece of equipment, you choose.</p>
      ${block('irrigation', icon.drop, 'Watering', 'It waters when the soil is dry.')}
      <hr class="furrow">
      ${block('fan', icon.fan, 'Ventilation', `It ventilates above ${st.thresholds.fan_temp} °C or in damp air.`)}
      <div class="push"></div>
      <p class="muted small flame-note">${icon.flame}The flame alert stays active in every case.</p></div>` };
}

// ---------------------------------------------------------------- log, alerts
const LV = { auto: 'ok', info: 'ok', user: 'user', warn: 'warn', alarm: 'alarm' };
export function log(ctx, f) {
  const filters = [['', 'All'], ['irrigation', 'Watering'], ['fan', 'Ventilation'], ['important', 'Alerts']];
  let ev = ctx.events || [];
  if (f === 'important') ev = ev.filter(e => e.level === 'warn' || e.level === 'alarm');
  else if (f) ev = ev.filter(e => e.kind === f);
  const groups = [];
  for (const e of ev.slice(0, 120)) {
    const label = dayLabel(e.time, ctx);
    if (!groups.length || groups.at(-1).label !== label) groups.push({ label, items: [] });
    groups.at(-1).items.push(e);
  }
  return { tabs: true, tab: 'log', html: `
    <header class="bar plain"><h1>The log</h1></header>
    <div class="filters">${filters.map(([k, t]) => `<a href="#/log${k ? '?f=' + k : ''}" class="${(f || '') === k ? 'on' : ''}">${t}</a>`).join('')}</div>
    <div class="pad timeline">
      ${groups.map(g => `<h3 class="caps">${g.label}</h3><ul>${g.items.map(e => `<li class="${LV[e.level] || 'ok'}">
        <time>${hm(e.time)}</time><i></i><div><b>${esc(e.title)}</b><span>${esc(e.detail)}</span>
        ${e.why ? `<details><summary>Why?</summary><p class="note green">${esc(e.why)}</p></details>` : ''}</div></li>`).join('')}</ul>`).join('')
        || '<p class="muted">Nothing yet.</p>'}
      <p class="right">${stamp('7 days kept')}</p>
    </div>` };
}
function dayLabel(iso, ctx) {
  if (!iso) return 'Earlier';
  const d = new Date(iso), now = nowOf(ctx), y = new Date(now); y.setDate(now.getDate() - 1);
  if (d.toDateString() === now.toDateString()) return 'Today';
  if (d.toDateString() === y.toDateString()) return 'Yesterday';
  return d.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'short' });
}

const ALERT_IC = { fire: 'flame', locked: 'lock', missing: 'thermo', tank: 'tank', dry: 'soil' };
const ALERT_GO = { fire: '#/safety', locked: '#/settings', missing: '#/air', tank: '#/water', dry: '#/soil' };
export function alerts(ctx) {
  const st = ctx.st, today = nowOf(ctx).toDateString();
  const handled = (ctx.events || []).filter(e => e.level === 'auto' && new Date(e.time).toDateString() === today).slice(0, 6);
  const crit = st.alerts.some(a => a.level === 'critical');
  return { tabs: true, tab: 'home', html: `${head('Alerts')}
    <div class="pad">
      <h3 class="caps">To look at</h3>
      ${st.alerts.length ? st.alerts.map(a => row({ href: ALERT_GO[a.id], ic: icon[ALERT_IC[a.id]], title: a.title, sub: `${esc(a.detail)} Since ${hm(a.since)}.`, cls: a.level })).join('')
        : '<p class="muted">Nothing to look at. Everything is fine.</p>'}
      <h3 class="caps">Already handled today</h3>
      ${handled.length ? handled.map(e => `<div class="line static"><span class="lic">${e.kind === 'fan' ? icon.fan : icon.drop}</span><span class="ltx"><b>${esc(e.title)}</b><small>${hm(e.time)} · ${esc(e.detail)}</small></span></div>`).join('')
        : '<p class="muted">Nothing yet today.</p>'}
      ${crit ? '' : `<p class="center">${stamp('nothing in red', 3)}</p>`}
    </div>` };
}

// ---------------------------------------------------------------- sensors
function mute(ctx, title, key, unit, back, advice) {
  const lv = ctx.st.last_valid?.[key];
  return { tabs: true, tab: 'home', html: `${head(title, back)}
    <div class="pad"><span class="dash"></span><h1 class="screen-title">No news from the sensor.</h1>
      <p class="muted">${lv ? `Last valid reading: <b>${(+lv.v).toFixed(key === 'air_temp' ? 0 : 0)} ${unit} at ${hm(lv.t)}</b>. I don't show it as if it were today's.` : 'No valid reading yet.'}</p>
      <p class="note wheat">${advice}</p><div class="push"></div><a class="btn wheat" href="#/help">What to check?</a></div>` };
}

export function soil(ctx) {
  const st = ctx.st, s = st.sensors;
  if (s.soil_raw == null) return mute(ctx, 'The soil', 'soil_raw', 'raw', '#/', 'Check that the soil probe is well in the soil and that the Arduino is plugged into the Pi. Watering is paused meanwhile.');
  const h = ctx.history?.points || [];
  const lastW = (st.last_diagnosis && dayPhrase(st.last_diagnosis.time, ctx, true)) || '';
  return { tabs: true, tab: 'home', html: `<div class="soil-head">${soilSection(s.soil_pct)}<a class="back over" href="#/" aria-label="Back">${icon.back}</a><span class="depth">10 cm deep</span></div>
    <div class="pad"><p class="muted">The soil is</p><h1 class="screen-title">${soilWord(s.soil_raw).toLowerCase()} <span class="earth">${Math.round(s.soil_pct)} %</span></h1>
      <h3 class="caps">Since ${h.length ? dayPhrase(h[0].t, ctx, true) : 'yesterday'}</h3>
      ${spark(h.map(p => p.soil), { min: 0, max: 100, threshold: st.thresholds.water_pct, color: '#8b4a2b' })}
      <p class="muted">The red line: below it, the greenhouse waters.${lastW ? ` It did ${lastW}.` : ''}</p>
      <p class="muted small">Raw probe value: ${Math.round(s.soil_raw)} (higher = drier).</p></div>` };
}

export function air(ctx) {
  const st = ctx.st, s = st.sensors;
  if (s.air_temp == null) return mute(ctx, 'The air and the light', 'air_temp', '°C', '#/', 'Check that the air sensor (DHT22) is plugged in. Ventilation keeps working with the other readings, watering is paused.');
  const h = ctx.history?.points || [];
  const today = nowOf(ctx).toDateString();
  const todays = h.filter(p => new Date(p.t).toDateString() === today && p.temp != null);
  const max = todays.length ? Math.max(...todays.map(p => p.temp)) : s.air_temp;
  const maxAt = todays.find(p => p.temp === max);
  const ran = (st.fan_runs_today || []).length;
  return { tabs: true, tab: 'home', html: `${head('The air and the light')}
    <div class="pad"><p class="huge">${Math.round(s.air_temp)}<small>°C</small></p>
      <p class="muted">It reached ${max.toFixed(1)} °C ${maxAt ? dayPhrase(maxAt.t, ctx, true).replace(/ at .*/, '') : 'today'}.${ran ? ' The greenhouse ventilated.' : ''} Humidity ${Math.round(s.air_hum)} %.</p>
      <h3 class="caps">Since ${h.length ? dayPhrase(h[0].t, ctx, true) : 'yesterday'}</h3>
      ${spark(h.map(p => p.temp), { band: st.thresholds.comfort, color: '#b5731c' })}
      <p class="muted">The green band: where the ${crop(ctx)} are fine, from ${st.thresholds.comfort[0]} to ${st.thresholds.comfort[1]} °C.</p>
      <div class="line static"><span class="lic sun">${icon.sun}</span><span class="ltx"><b>Light</b><small>${cap(lightWord(s.light))}, ${s.light >= 8000 ? 'enough for the day' : s.light >= 50 ? 'the plants grow slowly' : 'the plants rest'} · ${Math.round(s.light).toLocaleString('en-GB')} lx</small></span></div>
    </div>` };
}

export function safety(ctx) {
  const st = ctx.st, g = ctx.me?.greenhouse || {}, fire = st.alarms.fire;
  const lastFire = (ctx.events || []).find(e => e.kind === 'safety' && e.level === 'alarm');
  const phone = g.contact_phone ? g.contact_phone.replace(/(\d{2})\d+(\d{3})$/, '$1 ••• $2') : '';
  return { tabs: true, tab: 'home', html: `${head('Safety')}
    <div class="pad"><div class="safe-head">${flameTile(fire ? '#f6d9d4' : '#e3efd6', fire ? '#a8392b' : '#2f6b2f')}<h1 class="screen-title">${fire ? 'A flame in the greenhouse!' : 'No flame in the greenhouse.'}</h1></div>
      <p class="muted">If a flame appears, the alarm sounds on site and the pump and fan are cut at once, even if the app is closed.</p>
      ${row({ href: '#/settings', ic: icon.contact, title: g.contact_name ? `${esc(g.contact_name)}, contact of the greenhouse` : 'Contact in case of flame', sub: g.contact_name ? esc(phone) : 'Not set yet: add one in Settings' })}
      <div class="line static"><span class="lic">${icon.book}</span><span class="ltx"><b>Last alert</b><small>${lastFire ? dayPhrase(lastFire.time, ctx) : 'None in the last 7 days'}</small></span></div>
    </div>` };
}

export function plants() {
  return { tabs: true, tab: 'home', html: `${head('Plant health')}
    <div class="soon-art">${landscape('good', 120).replace('class="land"', 'class="land soft"')}</div>
    <div class="pad"><h1 class="screen-title">Soon, the greenhouse will look at your plants.</h1>
      <p class="muted">A camera will spot diseases and tell you what it sees. Not installed yet.</p>
      <p class="note kraft">When it is ready, each result will be marked "to confirm". A photo is not a diagnosis.</p></div>` };
}

// ---------------------------------------------------------------- settings
export function settings(ctx) {
  const me = ctx.me || {}, u = me.user || {}, g = me.greenhouse || {}, st = ctx.st;
  return { tabs: true, tab: 'home', html: `${head('Settings')}
    <div class="pad">
      <h3 class="caps">Notify me</h3>
      <label class="radio"><input type="radio" name="notify" value="important" data-action="notify" ${u.notify !== 'all' ? 'checked' : ''}><span><b>The important things</b><small>The rest goes into the log.</small></span></label>
      <label class="radio"><input type="radio" name="notify" value="all" data-action="notify" ${u.notify === 'all' ? 'checked' : ''}><span><b>Everything</b><small>Finished waterings too.</small></span></label>
      <p class="muted small flame-note">${icon.flame}The flame alert cannot be turned off.</p>
      ${st.irrigation.locked ? `<div class="note wheat"><b>The pump is locked.</b> Two faulty waterings in a row. Once you have checked the pump and the pipe: <button class="btn small forest" data-action="unlock">Unlock the pump</button></div>` : ''}
      <details class="line-edit"><summary class="line"><span class="lic">${icon.contact}</span><span class="ltx"><b>Contact in case of flame</b><small>${esc(g.contact_name || 'Not set')}</small></span><span class="chev">${icon.chevron}</span></summary>
        <form class="form" data-form="contact"><label>Name<input name="contact_name" value="${esc(g.contact_name || '')}" maxlength="40"></label>
        <label>Phone<input name="contact_phone" type="tel" value="${esc(g.contact_phone || '')}" maxlength="20"></label><button class="btn small forest">Save</button></form></details>
      ${row({ href: '#/thresholds', ic: icon.soil, title: 'What the greenhouse watches', sub: 'The thresholds' })}
      ${row({ href: '#/who', ic: icon.wheel, title: 'Who decides?', sub: 'Automatic or by hand, per equipment' })}
      ${row({ href: '#/help', ic: icon.help, title: 'Help', sub: 'If something goes wrong' })}
      <h3 class="caps">The dashboard</h3>
      ${row({ href: '#/3d', ic: icon.cube, title: 'The greenhouse in 3D', sub: 'Every sensor, live' })}
      ${row({ href: '#/stats', ic: icon.chart, title: 'Statistics', sub: 'Waterings, water, fan, 7 days' })}
      ${row({ href: '#/ai', ic: icon.ai, title: 'How the AI decides', sub: 'The 3 decision trees, live' })}
      ${st.simulated ? row({ href: '#/lab', ic: icon.lab, title: 'Simulation lab', sub: 'Speed up time, create a problem' }) : ''}
      <h3 class="caps">Account</h3>
      <details class="line-edit"><summary class="line"><span class="lic">${icon.user}</span><span class="ltx"><b>${esc(u.name || '')}</b><small>${esc(u.email || '')}</small></span><span class="chev">${icon.chevron}</span></summary>
        <form class="form" data-form="me"><label>First name<input name="name" value="${esc(u.name || '')}" maxlength="40" required></label><button class="btn small forest">Save</button></form></details>
      <details class="line-edit"><summary class="line"><span class="lic">${icon.greenhouse}</span><span class="ltx"><b>${esc(g.name || '')}</b><small>Growing ${esc(g.crop || '')} · code ${esc(me.code || '')}</small></span><span class="chev">${icon.chevron}</span></summary>
        <form class="form" data-form="greenhouse"><label>Name of the greenhouse<input name="name" value="${esc(g.name || '')}" maxlength="40" required></label>
        <label>What grows in it<input name="crop" value="${esc(g.crop || '')}" maxlength="30"></label>
        <p class="muted small">The greenhouse code lets a person create an account: share it only with people you trust.</p><button class="btn small forest">Save</button></form></details>
      <button class="btn outline" data-action="logout">Sign out</button>
      <p class="app-foot"><span>SmartFarm 1.0</span><span>${esc(g.name || '')}</span></p>
    </div>` };
}

export function thresholds(ctx) {
  const t = ctx.st.thresholds;
  const r = (v, txt) => `<div class="thr"><b>${v}</b><span>${txt}</span></div>`;
  return { tabs: true, tab: 'home', html: `${head('What the greenhouse watches', '#/settings')}
    <div class="pad">
      ${r(`${t.water_pct} %`, `Below about ${t.water_pct} % moisture, the greenhouse waters (earlier when it is hot).`)}
      ${r(`${t.fan_temp} °C`, `Above ${t.fan_temp} °C, it ventilates.`)}
      ${r('90 %', 'Above 90 % air humidity, it ventilates against mould.')}
      ${r(`${t.tank_watch_pct} %`, `Below ${t.tank_watch_pct} % of water in the tank, it warns you.`)}
      ${r('0 %', 'Tank empty: the pump never runs dry.')}
      <p class="note wheat">These are starting values, learned from an agronomist's rules for ${crop(ctx)}. We will adjust them with the greenhouse's experience.</p>
    </div>` };
}

export function help(ctx, open) {
  const q = [
    ['offline', "I can't see the greenhouse anymore", "Check that this phone or computer is on the greenhouse's Wi-Fi, and that the Raspberry Pi is powered (its green light blinks). The greenhouse keeps working on its own meanwhile."],
    ['valve', "The water doesn't flow", 'Look at the pipe from the tank to the pots: is it bent, or out of the water? Is the pump plugged into its relay? After two faulty waterings the pump locks itself: unlock it in Settings once it is fixed.'],
    ['flame', 'A flame is detected', 'The buzzer sounds and the pump and fan are cut at once. Go and look. If it is a false alarm (strong sunlight on the sensor), the alarm stops by itself when the sensor is clear.'],
    ['sensor', 'A sensor stopped answering', 'Check its wires. Soil probe: on the Arduino, itself plugged into the Pi by USB. Air sensor (DHT22): on the Pi. Until it answers again, the greenhouse does not water: it never waters blind.'],
  ];
  return { tabs: true, tab: 'home', html: `${head('Help', '#/settings')}
    <div class="pad faq">${q.map(([k, t, a]) => `<details ${open === k ? 'open' : ''}><summary>${t}<span class="pm"></span></summary><p>${a}</p></details>`).join('')}</div>` };
}

// ---------------------------------------------------------------- special screens
export function fire(ctx) {
  const g = ctx.me?.greenhouse || {};
  return { theme: 'fire', html: `<div class="fire-screen">${flameTile('#fff', '#a8392b')}
    <h1>A flame in the greenhouse.</h1>
    <p>The alarm is sounding on site. The pump and the fan are cut.</p>
    <div class="push"></div>
    <button class="btn white" data-action="fire-ack">I saw it, I'm checking</button>
    ${g.contact_phone ? `<p class="center"><a class="link light" href="tel:${esc(g.contact_phone.replace(/\s/g, ''))}">Call ${esc(g.contact_name || 'the contact')}</a></p>` : ''}</div>` };
}

export function offlineView(ctx) {
  const s = ctx.st?.sensors;
  return { html: `<div class="pad offline">${offline()}
    <h1 class="screen-title">I can't see the greenhouse anymore.</h1>
    <p class="muted">Last news: ${s ? hm(s.timestamp) : '–'}. Check that this device is on the greenhouse's Wi-Fi.</p>
    ${s ? `<p class="muted">At ${hm(s.timestamp)}: soil ${Math.round(s.soil_pct ?? 0)} %, tank ${Math.round(s.water_level_pct ?? 0)} %, air ${Math.round(s.air_temp ?? 0)} °C.</p>` : ''}
    <div class="push"></div><p class="muted small center">The flame alarm still sounds on site.</p>
    <button class="btn forest" data-action="retry">Try again</button></div>` };
}
