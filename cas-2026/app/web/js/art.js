// Icons (2px line, rounded, one colour) and the illustrations of the SmartFarm v2 design, as inline SVG.
const I = (d, extra = '') => `<svg class="ic" viewBox="0 0 24 24" aria-hidden="true" ${extra}>${d}</svg>`;

export const icon = {
  greenhouse: I('<path d="M3.5 10.5 12 4l8.5 6.5V20h-17z"/><path d="M12 17v-4.5"/><path d="M12 14c0-2 1.4-3.2 3.3-3.2 0 2-1.4 3.2-3.3 3.2zM12 13.2c0-1.6-1.1-2.6-2.7-2.6 0 1.6 1.1 2.6 2.7 2.6z"/>'),
  drop: I('<path d="M12 3.5c3.2 4.1 5.5 7.2 5.5 10.2a5.5 5.5 0 0 1-11 0c0-3 2.3-6.1 5.5-10.2z"/><path d="M9.6 14.2a2.6 2.6 0 0 0 2.4 2.5"/>'),
  fan: I('<circle cx="12" cy="12" r="1.6"/><path d="M12 10.4c-.6-3.2.4-6 2.6-6.2 2.3-.2 2.6 3.3-2.6 6.2zM13.4 12.8c2.5 2.1 3.6 4.9 2.1 6.4-1.6 1.6-4.1-.9-2.1-6.4zM10.6 12.4c-3.1 1.1-6 .5-6.5-1.6-.5-2.2 3-3 6.5 1.6z"/>'),
  book: I('<rect x="5" y="3.5" width="14" height="17" rx="2"/><path d="M9 3.5v17M12 8h4M12 11.5h4"/>'),
  bell: I('<path d="M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 1.5H5z"/><path d="M10 20.5h4"/>'),
  wheel: I('<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="2.2"/><path d="M12 3.5v6.3M12 14.2v6.3M3.5 12h6.3M14.2 12h6.3"/>'),
  soil: I('<rect x="3.5" y="5" width="17" height="14" rx="3"/><path d="M3.5 10h17"/><circle cx="8" cy="14" r=".6"/><circle cx="12" cy="15.5" r=".6"/><circle cx="16" cy="13.5" r=".6"/>'),
  tank: I('<ellipse cx="12" cy="5.5" rx="6.5" ry="2.2"/><path d="M5.5 5.5v13c0 1.2 2.9 2.2 6.5 2.2s6.5-1 6.5-2.2v-13M5.5 12c0 1.2 2.9 2.2 6.5 2.2s6.5-1 6.5-2.2"/>'),
  thermo: I('<path d="M10 14.2V5a2 2 0 0 1 4 0v9.2a3.8 3.8 0 1 1-4 0z"/><path d="M12 9v7"/>'),
  flame: I('<path d="M12 3.5c.8 3 4.8 5 4.8 9.7a4.8 4.8 0 0 1-9.6 0c0-2.4 1.3-3.8 2.3-5 .3 1.6 1 2.4 1.9 2.8C11.2 9 11 6.3 12 3.5z"/><path d="M12 18.2a1.8 1.8 0 0 1-1.8-1.8c0-1.2 1.1-1.8 1.8-3 .7 1.2 1.8 1.8 1.8 3a1.8 1.8 0 0 1-1.8 1.8z"/>'),
  leafSearch: I('<path d="M4 15c0-6 4-10 11-10 0 7-4 11-9.5 11"/><path d="M4 20c2-4 5-7 8-8.5"/><circle cx="17" cy="16.5" r="2.8"/><path d="m19 18.5 2 2"/>'),
  chevron: I('<path d="m9.5 6 6 6-6 6"/>'),
  back: I('<path d="M15 5.5 8.5 12l6.5 6.5"/>'),
  check: I('<path d="m5.5 12.5 4 4 9-9"/>'),
  warn: I('<path d="M12 4.5 21 19.5H3z"/><path d="M12 10v4.2M12 16.8v.2"/>'),
  sun: I('<circle cx="12" cy="12" r="3.8"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/>'),
  contact: I('<path d="M6 21V4M6 5h11.5l-2 3 2 3H6"/><path d="M4 21h5"/>'),
  cube: I('<path d="M12 3.5 20 8v8l-8 4.5L4 16V8z"/><path d="M12 12.5 20 8M12 12.5 4 8M12 12.5v8"/>'),
  chart: I('<path d="M4 19.5h16"/><path d="M7 16V11M11 16V6.5M15 16v-6M19 16V9"/>'),
  ai: I('<circle cx="12" cy="5" r="2"/><circle cx="6" cy="13" r="2"/><circle cx="18" cy="13" r="2"/><circle cx="12" cy="20" r="1.6"/><path d="M11 6.7 7 11.3M13 6.7l4 4.6M7.2 14.7l3.7 4"/>'),
  help: I('<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.5a2.5 2.5 0 1 1 3.4 2.3c-.6.3-1 .8-1 1.5v.6"/><path d="M12 16.8v.2"/>'),
  user: I('<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5"/>'),
  lock: I('<rect x="5.5" y="10.5" width="13" height="10" rx="2"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>'),
  lab: I('<path d="M9.5 3.5h5M10.5 3.5v6L5 19a1.3 1.3 0 0 0 1.1 2h11.8A1.3 1.3 0 0 0 19 19l-5.5-9.5v-6"/><path d="M7.5 15h9"/>'),
  plus: I('<path d="M12 5.5v13M5.5 12h13"/>'),
  minus: I('<path d="M5.5 12h13"/>'),
  phone: I('<path d="M6.5 3.5h3l1.5 4.5-2 1.3a10 10 0 0 0 5.7 5.7l1.3-2 4.5 1.5v3a2 2 0 0 1-2 2A15.5 15.5 0 0 1 4.5 5.5a2 2 0 0 1 2-2z"/>'),
};

// SmartFarm mark: greenhouse with a sprout, in a leaf-cornered tile
export const logo = (size = 28) => `<svg width="${size}" height="${size}" viewBox="0 0 32 32" aria-hidden="true">
  <path d="M4 14 16 5l12 9v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="#1f4a2c"/>
  <path d="M16 25v-7" stroke="#f4eee0" stroke-width="2" stroke-linecap="round"/>
  <path d="M16 19.5c0-3 2-4.8 5-4.8 0 3-2 4.8-5 4.8z" fill="#a6d65a"/><path d="M16 18.5c0-2.4-1.6-3.8-4-3.8 0 2.4 1.6 3.8 4 3.8z" fill="#a6d65a"/>
  <path d="M9 26h14" stroke="#e8b746" stroke-width="2" stroke-linecap="round"/></svg>`;

// The landscape of the home screen: tunnel greenhouse, olive tree, rows. state: good | watch
export function landscape(state = 'good', h = 150) {
  const c = state === 'watch'
    ? { sky: '#e8b746', hill: '#d3a03a', field: '#8b4a2b', far: '#a5612f', row: '#e7b44a', sun: '#fff3c9', tree: '#3f6b34' }
    : { sky: '#1f4a2c', hill: '#2b6a35', field: '#4c9a2f', far: '#3d8030', row: '#b9e06a', sun: '#e8b746', tree: '#6aa84f' };
  return `<svg class="land" viewBox="0 0 360 ${h}" preserveAspectRatio="none" aria-hidden="true">
    <rect width="360" height="${h}" fill="${c.sky}"/>
    <circle cx="322" cy="${h * 0.12}" r="11" fill="${c.sun}"/>
    <path d="M0 ${h * .42} C70 ${h * .3} 140 ${h * .36} 210 ${h * .4} S330 ${h * .3} 360 ${h * .36} V${h} H0z" fill="${c.hill}"/>
    <g transform="translate(36 ${h * .3})"><path d="M0 18 C0 4 30 4 30 18z" fill="#f6f1e4"/><path d="M8 18V8M15 18V5M22 18V8" stroke="${c.hill}" stroke-width="1.6"/></g>
    <g transform="translate(296 ${h * .2})"><rect x="-1.5" y="10" width="3" height="14" fill="#6b4a2b"/><ellipse cx="0" cy="8" rx="14" ry="10" fill="${c.tree}"/></g>
    <path d="M0 ${h * .62} C90 ${h * .5} 270 ${h * .5} 360 ${h * .62} V${h} H0z" fill="${c.field}"/>
    <g fill="none" stroke="${c.row}" stroke-width="2" stroke-linecap="round">
      <path d="M180 ${h * .55} C130 ${h * .7} 80 ${h * .85} 30 ${h}"/><path d="M180 ${h * .55} C160 ${h * .72} 140 ${h * .86} 120 ${h}"/>
      <path d="M180 ${h * .55} C200 ${h * .72} 220 ${h * .86} 240 ${h}"/><path d="M180 ${h * .55} C230 ${h * .7} 280 ${h * .85} 330 ${h}"/>
      <path d="M180 ${h * .55} C110 ${h * .62} 40 ${h * .72} 0 ${h * .8}"/><path d="M180 ${h * .55} C250 ${h * .62} 320 ${h * .72} 360 ${h * .8}"/></g></svg>`;
}

// The tank, drawn big: water level, wave, ticks, red dashed reserve line
export function tank(pct = 50) {
  const p = Math.max(0, Math.min(100, pct ?? 0)), top = 22, bot = 150, y = bot - (bot - top) * p / 100;
  return `<svg class="tankart" viewBox="0 0 120 170" aria-hidden="true">
    <defs><clipPath id="tk"><path d="M16 20 V148 a44 12 0 0 0 88 0 V20z"/></clipPath></defs>
    <g clip-path="url(#tk)">
      <rect x="0" y="${y}" width="120" height="170" fill="#7fb6d5"/>
      <path d="M0 ${y} q15 -6 30 0 t30 0 t30 0 t30 0 V${y + 8} H0z" fill="#5a9cc4"/>
      <rect x="0" y="${y + 6}" width="120" height="170" fill="#5a9cc4"/>
    </g>
    <path d="M16 20 V148 a44 12 0 0 0 88 0 V20" fill="none" stroke="#24648f" stroke-width="4"/>
    <ellipse cx="60" cy="20" rx="44" ry="10" fill="#fbf8f1" stroke="#24648f" stroke-width="4"/>
    <path d="M18 141 H102" stroke="#c0392b" stroke-width="2.5" stroke-dasharray="5 4"/>
    <path d="M108 60h8M108 90h8M108 120h8" stroke="#24648f" stroke-width="3" stroke-linecap="round"/></svg>`;
}

export function fan(on = false) {
  return `<svg class="fanart ${on ? 'spin' : ''}" viewBox="0 0 120 130" aria-hidden="true">
    <path d="M60 70 V112 M44 114 H76" stroke="#55705a" stroke-width="5" stroke-linecap="round"/>
    <g class="blades" style="transform-origin:60px 56px">
      <path d="M60 56 C52 36 56 14 70 14 C82 16 78 38 60 56z" fill="none" stroke="#55705a" stroke-width="5" stroke-linejoin="round"/>
      <path d="M60 56 C80 50 100 58 98 72 C94 84 74 74 60 56z" fill="none" stroke="#55705a" stroke-width="5" stroke-linejoin="round"/>
      <path d="M60 56 C46 72 26 80 20 68 C16 56 38 50 60 56z" fill="none" stroke="#55705a" stroke-width="5" stroke-linejoin="round"/>
      <circle cx="60" cy="56" r="6" fill="#55705a"/></g></svg>`;
}

// Soil cross-section with the probe planted, moisture dots follow the soil %
export function soilSection(pct = 40) {
  const n = Math.round(3 + (pct ?? 0) / 100 * 9);
  const dots = Array.from({ length: n }, (_, i) => {
    const x = 20 + ((i * 53) % 330), y = 70 + ((i * 37) % 80);
    return `<circle cx="${x}" cy="${y}" r="3.2" fill="#4f9fd0"/>`;
  }).join('');
  return `<svg class="soilart" viewBox="0 0 360 170" preserveAspectRatio="none" aria-hidden="true">
    <rect width="360" height="170" fill="#efe3c8"/>
    <path d="M0 52 C60 46 120 58 180 52 S300 46 360 52 V170 H0z" fill="#b98a5e"/>
    <path d="M0 82 C80 76 160 90 240 82 S330 76 360 82 V170 H0z" fill="#8d5a36"/>
    <path d="M0 122 C80 116 170 128 250 120 S330 118 360 122 V170 H0z" fill="#6b3f24"/>
    <path d="M0 50 C60 44 120 56 180 50 S300 44 360 50" stroke="#3f8f33" stroke-width="5" fill="none"/>
    <path d="M40 50 c-6-12 0-22 8-26M320 50 c6-12 0-22-8-26" stroke="#3f8f33" stroke-width="3" fill="none" stroke-linecap="round"/>
    ${dots}
    <rect x="172" y="22" width="16" height="118" rx="3" fill="#f6f1e4"/>
    <rect x="166" y="10" width="28" height="22" rx="6" fill="#1f4a2c"/>
    <circle cx="180" cy="140" r="5" fill="#e8b746"/></svg>`;
}

export const sprout = () => `<svg class="hero-art" viewBox="0 0 320 220" aria-hidden="true">
  <circle cx="262" cy="34" r="16" fill="#e8b746"/>
  <path d="M0 170 C90 140 230 140 320 168 V220 H0z" fill="#cfe3b4"/><path d="M0 190 C110 165 220 168 320 186 V220 H0z" fill="#a6d65a"/>
  <path d="M160 175 V110" stroke="#1f4a2c" stroke-width="6" stroke-linecap="round"/>
  <path d="M160 118 c-6-26-30-34-48-28 6 22 26 32 48 28z" fill="#6fae3f"/><path d="M160 112 c8-26 34-34 52-26-6 22-28 32-52 26z" fill="#8cc94f"/>
  <g fill="#4f9fd0"><path d="M84 54c5 7 8 11 8 15a8 8 0 0 1-16 0c0-4 3-8 8-15z"/><path d="M238 72c4 6 7 9 7 12a7 7 0 0 1-14 0c0-3 3-6 7-12z"/>
  <path d="M60 104c3 5 5 7 5 9a5 5 0 0 1-10 0c0-2 2-4 5-9z"/><path d="M214 128c3 5 5 7 5 9a5 5 0 0 1-10 0c0-2 2-4 5-9z"/></g></svg>`;

export const valve = () => `<svg class="hero-art small" viewBox="0 0 120 120" aria-hidden="true" fill="none" stroke="#8b4a2b" stroke-width="6" stroke-linecap="round" stroke-linejoin="round">
  <rect x="44" y="10" width="32" height="20" rx="8"/><path d="M60 30v22"/><path d="M14 72h22M84 72h22"/><path d="M36 54 60 72 36 90zM84 54 60 72 84 90z"/>
  <path d="M46 106l2 2M60 102v3M72 106l-2 2" stroke="#9db7c9" stroke-width="4"/></svg>`;

export const offline = () => `<svg class="hero-art" viewBox="0 0 320 120" aria-hidden="true">
  <path d="M0 70 C80 50 200 54 320 64 V120 H0z" fill="#ddd4bf"/>
  <rect x="14" y="56" width="20" height="34" rx="5" fill="none" stroke="#4a4537" stroke-width="5"/>
  <path d="M42 54 C80 20 120 14 156 16" stroke="#6d6757" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round" fill="none"/>
  <path d="M190 22 h40" stroke="#6d6757" stroke-width="3" stroke-dasharray="2 7" stroke-linecap="round"/>
  <path d="M250 64 c0-16 32-16 32 0z" fill="#c9bfa8"/><path d="M258 64v-9M266 64v-12M274 64v-9" stroke="#ddd4bf" stroke-width="2"/></svg>`;

export const sprouts = () => `<div class="sprouts" aria-hidden="true">
  <svg viewBox="0 0 40 40"><path d="M20 38V24" stroke="#1f4a2c" stroke-width="3"/><path d="M20 26c0-6 4-9 9-9 0 6-4 9-9 9z" fill="#8cc94f"/><path d="M20 27c0-5-3-7-7-7 0 5 3 7 7 7z" fill="#6fae3f"/></svg>
  <svg viewBox="0 0 40 40"><path d="M20 38V18" stroke="#1f4a2c" stroke-width="3"/><path d="M20 20c0-7 5-11 11-11 0 7-5 11-11 11z" fill="#8cc94f"/><path d="M20 22c0-6-4-9-9-9 0 6 4 9 9 9z" fill="#6fae3f"/></svg>
  <svg viewBox="0 0 40 40"><path d="M20 38V12" stroke="#1f4a2c" stroke-width="3"/><path d="M20 14c0-8 6-12 13-12 0 8-6 12-13 12z" fill="#8cc94f"/><path d="M20 16c0-7-5-10-11-10 0 7 5 10 11 10z" fill="#6fae3f"/></svg>
  <i></i></div>`;

export const flameTile = (bg = '#fff', fg = '#a8392b') => `<div class="leaf-tile" style="background:${bg};color:${fg}">${icon.flame}</div>`;

// A small line chart (one series), with an optional dashed threshold or a comfort band
export function spark(values, { min, max, threshold, band, color = '#8b4a2b', h = 70 } = {}) {
  const v = values.filter(x => x != null);
  if (v.length < 2) return '<p class="muted small">Not enough readings yet.</p>';
  let lo = min ?? Math.min(...v), hi = max ?? Math.max(...v);
  if (threshold != null) { lo = Math.min(lo, threshold); hi = Math.max(hi, threshold); }
  if (band) { lo = Math.min(lo, band[0]); hi = Math.max(hi, band[1]); }
  const pad = (hi - lo) * .12 || 1; lo -= pad; hi += pad;
  const W = 320, X = i => i / (values.length - 1) * W, Y = x => h - 4 - (x - lo) / (hi - lo) * (h - 8);
  let d = '', pen = false;
  values.forEach((x, i) => { if (x == null) { pen = false; return; } d += (pen ? 'L' : 'M') + X(i).toFixed(1) + ' ' + Y(x).toFixed(1) + ' '; pen = true; });
  let lx = values.length - 1; while (values[lx] == null) lx--;
  return `<svg class="spark" viewBox="0 0 ${W} ${h}" preserveAspectRatio="none" aria-hidden="true">
    ${band ? `<rect x="0" y="${Y(band[1])}" width="${W}" height="${Y(band[0]) - Y(band[1])}" fill="#e3efd6"/>` : ''}
    ${threshold != null ? `<path d="M0 ${Y(threshold)} H${W}" stroke="#c0392b" stroke-width="1.6" stroke-dasharray="6 5"/>` : ''}
    <path d="${d}" fill="none" stroke="${color}" stroke-width="2.6" stroke-linejoin="round" stroke-linecap="round" vector-effect="non-scaling-stroke"/>
    <circle cx="${X(lx)}" cy="${Y(values[lx])}" r="4.5" fill="${color}"/></svg>`;
}
