// Charts on canvas + small HTML/SVG figures. Palette validated with the dataviz validator against the card
// surface #fffdf7 (slots 1-3 pass all-pairs; aqua is under 3:1, so every segment also carries a text label).
// One measure per chart (never two y-scales); a single series needs no legend (the title names it).
export const C = {
  ink: '#16241b', ink2: '#55635a', muted: '#898781', grid: '#e6e1d3', axis: '#c3c2b7', surface: '#fffdf7',
  s1: '#2a78d6', s2: '#eb6834', s3: '#1baf7a', s4: '#eda100',
  seq: ['#cde2fb', '#9ec5f4', '#6da7ec', '#3987e5', '#256abf', '#184f95', '#0d366b'],
};
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function setupCanvas(c) {
  const dpr = window.devicePixelRatio || 1, W = c.clientWidth, H = c.clientHeight;
  if (!W || !H) return null;
  c.width = W * dpr; c.height = H * dpr;
  const g = c.getContext('2d'); g.scale(dpr, dpr);
  g.fillStyle = C.surface; g.fillRect(0, 0, W, H);
  g.font = '11px system-ui, sans-serif';
  return { g, W, H };
}

function card(el, o) {
  el.className = 'card chart-card';
  el.innerHTML = `<div class="chart-head"><h3>${esc(o.title)}</h3><span></span></div>` +
    (o.note ? `<p class="chart-note">${esc(o.note)}</p>` : '') + `<canvas style="height:${o.height || 150}px"></canvas>`;
  return { readout: el.querySelector('.chart-head span'), canvas: el.querySelector('canvas') };
}

function niceRange(vals, o) {
  let lo = o.min ?? Math.min(...vals), hi = o.max ?? Math.max(...vals);
  if (o.threshold != null) { lo = Math.min(lo, o.threshold); hi = Math.max(hi, o.threshold); }
  if (hi - lo < 1e-6) hi = lo + 1;
  if (o.min == null) lo -= (hi - lo) * 0.08;
  if (o.max == null) hi += (hi - lo) * 0.08;
  return [lo, hi];
}

function yGrid(g, lo, hi, y, L, W, R, fmt) {
  g.strokeStyle = C.grid; g.fillStyle = C.muted; g.lineWidth = 1; g.textAlign = 'right'; g.textBaseline = 'middle';
  for (let k = 0; k <= 2; k++) {
    const v = lo + (hi - lo) * k / 2, yy = Math.round(y(v)) + 0.5;
    g.beginPath(); g.moveTo(L, yy); g.lineTo(W - R, yy); g.stroke();
    g.fillText(fmt(v), L - 5, yy);
  }
  g.textBaseline = 'alphabetic';
}

function pointer(canvas, self) {
  const move = e => { const r = canvas.getBoundingClientRect(); self.hover = (e.clientX - r.left) / r.width; self.draw(); };
  canvas.addEventListener('pointerdown', move);
  canvas.addEventListener('pointermove', move);
  canvas.addEventListener('pointerleave', () => { self.hover = null; self.draw(); });
  new ResizeObserver(() => self.draw()).observe(canvas);
}

// ------------------------------------------------------------------ line (time series)
export class LineChart {
  constructor(el, opts) {
    this.o = opts; this.points = []; this.marks = []; this.hover = null;
    Object.assign(this, card(el, opts));
    pointer(this.canvas, this);
  }
  set(points, marks = []) { this.points = points; this.marks = marks; this.draw(); }
  draw() {
    const cv = setupCanvas(this.canvas); if (!cv) return;
    const { g, W, H } = cv, o = this.o, pts = this.points;
    const L = 38, R = 10, T = 8, B = 20;
    const vals = pts.map(p => p[o.key]).filter(v => v != null);
    if (vals.length < 2) { g.fillStyle = C.ink2; g.fillText('Collecting data…', L, H / 2); this.readout.textContent = ''; return; }
    const [lo, hi] = niceRange(vals, o);
    const x = i => L + (W - L - R) * i / (pts.length - 1);
    const y = v => T + (H - T - B) * (1 - (v - lo) / (hi - lo));
    const f = o.fmt || (v => Math.round(v));
    yGrid(g, lo, hi, y, L, W, R, f);
    g.fillStyle = C.muted;
    [[0, 'left'], [pts.length >> 1, 'center'], [pts.length - 1, 'right']].forEach(([i, al]) => {
      g.textAlign = al; g.fillText(timeLabel(pts[i].t, pts.length > 150), x(i), H - 5);
    });
    if (this.marks.length) {                                   // watering ticks on the baseline
      const idx = new Map(pts.map((p, i) => [p.t, i]));
      g.strokeStyle = C.s1; g.lineWidth = 2;
      for (const m of this.marks) {
        let i = idx.get(m); if (i == null) { i = pts.findIndex(p => p.t >= m); if (i < 0) continue; }
        g.beginPath(); g.moveTo(x(i), H - B); g.lineTo(x(i), H - B - 9); g.stroke();
      }
    }
    if (o.threshold != null) {                                 // a threshold is the one dashed rule
      const yy = Math.round(y(o.threshold)) + 0.5;
      g.setLineDash([4, 4]); g.strokeStyle = C.ink2; g.lineWidth = 1;
      g.beginPath(); g.moveTo(L, yy); g.lineTo(W - R, yy); g.stroke(); g.setLineDash([]);
      g.textAlign = 'left'; g.fillStyle = C.ink2; g.fillText(o.thresholdLabel || '', L + 4, yy - 4);
    }
    g.strokeStyle = o.color || C.s1; g.lineWidth = 2; g.lineJoin = 'round'; g.beginPath();
    let pen = false;
    pts.forEach((p, i) => {
      const v = p[o.key];
      if (v == null) { pen = false; return; }                   // a missing reading leaves a gap
      pen ? g.lineTo(x(i), y(v)) : g.moveTo(x(i), y(v)); pen = true;
    });
    g.stroke();
    let i = pts.length - 1;
    while (i > 0 && pts[i][o.key] == null) i--;
    if (this.hover != null) {
      i = Math.max(0, Math.min(pts.length - 1, Math.round((this.hover * W - L) / (W - L - R) * (pts.length - 1))));
      g.strokeStyle = C.ink2; g.lineWidth = 1;
      g.beginPath(); g.moveTo(x(i) + 0.5, T); g.lineTo(x(i) + 0.5, H - B); g.stroke();
    }
    const v = pts[i][o.key];
    if (v != null) {
      g.fillStyle = o.color || C.s1; g.strokeStyle = C.surface; g.lineWidth = 2;
      g.beginPath(); g.arc(x(i), y(v), 4.5, 0, 7); g.fill(); g.stroke();
    }
    this.readout.textContent = (this.hover != null ? timeLabel(pts[i].t, true) + ' · ' : 'now ') + (v == null ? 'no reading' : f(v) + (o.unit || ''));
  }
}

// ------------------------------------------------------------------ bars (categories; optional floating range)
export class BarChart {
  // o: { title, unit, fmt, labelEvery, loKey (floating bars lo..key), markKey (dot inside the range) }
  constructor(el, opts) {
    this.o = opts; this.rows = []; this.hover = null;
    Object.assign(this, card(el, opts));
    pointer(this.canvas, this);
  }
  set(rows) { this.rows = rows; this.draw(); }
  draw() {
    const cv = setupCanvas(this.canvas); if (!cv) return;
    const { g, W, H } = cv, o = this.o, rows = this.rows;
    const L = 38, R = 8, T = 10, B = 20;
    const ok = rows.filter(r => r[o.key] != null);
    if (!ok.length) { g.fillStyle = C.ink2; g.fillText('No data in this period yet.', L, H / 2); this.readout.textContent = ''; return; }
    const vals = ok.flatMap(r => o.loKey ? [r[o.loKey], r[o.key]] : [r[o.key]]);
    let lo = o.loKey ? Math.min(...vals) : 0, hi = Math.max(...vals, o.minMax ?? 1);
    if (o.loKey) { const pad = (hi - lo) * 0.1 || 1; lo -= pad; hi += pad; }
    else if (!o.fmt) hi = Math.max(2, Math.ceil(hi * 1.1 / 2) * 2);  // counts: even top, so the mid tick is a whole number
    else hi *= 1.1;
    const n = rows.length, slot = (W - L - R) / n, bw = Math.max(2, Math.min(38, slot - 2));
    const x = i => L + slot * i + (slot - bw) / 2;
    const y = v => T + (H - T - B) * (1 - (v - lo) / (hi - lo));
    const f = o.fmt || (v => Math.round(v));
    yGrid(g, lo, hi, y, L, W, R, f);
    g.strokeStyle = C.axis; g.beginPath(); g.moveTo(L, Math.round(y(o.loKey ? lo : 0)) + 0.5); g.lineTo(W - R, Math.round(y(o.loKey ? lo : 0)) + 0.5); g.stroke();
    const hi_i = this.hover == null ? -1 : Math.max(0, Math.min(n - 1, Math.floor((this.hover * W - L) / slot)));
    rows.forEach((r, i) => {
      const v = r[o.key]; if (v == null) return;
      const top = y(v), base = o.loKey ? y(r[o.loKey]) : y(0), h = Math.max(1, base - top);
      g.fillStyle = (hi_i >= 0 && hi_i !== i) ? '#9ec5f4' : (o.color || C.s1);
      roundRect(g, x(i), top, bw, h, Math.min(4, bw / 2), !o.loKey);
      if (o.markKey && r[o.markKey] != null) {
        g.fillStyle = C.surface; g.fillRect(x(i), y(r[o.markKey]) - 1, bw, 2);
      }
    });
    g.fillStyle = C.muted; g.textAlign = 'center';
    const every = o.labelEvery || Math.ceil(n / 8);
    rows.forEach((r, i) => { if (i % every === 0) g.fillText(r.label, x(i) + bw / 2, H - 5); });
    if (hi_i >= 0) {
      const r = rows[hi_i];
      this.readout.textContent = `${r.label} · ` + (r[o.key] == null ? 'no data' : o.loKey
        ? `${f(r[o.loKey])}–${f(r[o.key])}${o.unit || ''}` + (o.markKey ? ` (mean ${f(r[o.markKey])})` : '')
        : f(r[o.key]) + (o.unit || ''));
    } else this.readout.textContent = o.total != null ? o.total : '';
  }
}

function roundRect(g, x, y, w, h, r, flatBottom) {
  g.beginPath();
  g.moveTo(x, y + h); g.lineTo(x, y + r); g.quadraticCurveTo(x, y, x + r, y);
  g.lineTo(x + w - r, y); g.quadraticCurveTo(x + w, y, x + w, y + r);
  if (flatBottom) g.lineTo(x + w, y + h);
  else { g.lineTo(x + w, y + h - r); g.quadraticCurveTo(x + w, y + h, x + w - r, y + h); g.lineTo(x + r, y + h); g.quadraticCurveTo(x, y + h, x, y + h - r); }
  g.closePath(); g.fill();
}

export function timeLabel(iso, withDay) {
  const d = new Date(iso);
  const hm = d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false });
  return withDay ? d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }) + ' ' + hm : hm;
}

// ------------------------------------------------------------------ HTML figures
// Part-to-whole: one segmented bar (2px gaps) + a legend with name, value and share (never color alone).
export function proportionBar(items) {
  const total = items.reduce((s, it) => s + it.value, 0);
  if (!total) return '<p class="sub">No data in this period yet.</p>';
  const seg = items.filter(it => it.value > 0).map(it =>
    `<i style="flex:${it.value};background:${it.color}" title="${esc(it.name)}: ${Math.round(100 * it.value / total)}%"></i>`).join('');
  const leg = items.map(it => `<div><span class="sw" style="background:${it.color}"></span>${esc(it.name)}
    <b>${(100 * it.value / total).toFixed(it.value / total < 0.01 && it.value ? 1 : 0)}%</b>${it.note ? `<small>${esc(it.note)}</small>` : ''}</div>`).join('');
  return `<div class="pbar">${seg}</div><div class="pleg">${leg}</div>`;
}

// Horizontal bars with direct value labels (one series -> one color).
export function hBars(items, fmt = v => v) {
  const max = Math.max(...items.map(i => i.value), 1e-9);
  return `<div class="hbars">${items.map(it => `<div class="hb"><span>${esc(it.name)}</span>
    <div><i style="width:${Math.max(1, 100 * it.value / max)}%"></i></div><b>${fmt(it.value)}</b></div>`).join('')}</div>`;
}

// Confusion matrix: rows = truth, columns = prediction; sequential blue by share of the row, numbers in cells.
export function confusion(labels, cm, short) {
  const head = labels.map(l => `<th>${esc(short(l))}</th>`).join('');
  const rows = cm.map((row, i) => {
    const tot = row.reduce((a, b) => a + b, 0) || 1;
    return `<tr><th>${esc(short(labels[i]))}</th>${row.map((v, j) => {
      const s = v / tot, k = Math.min(6, Math.round(s * 6)), dark = k >= 4;
      return `<td style="background:${v ? C.seq[k] : C.surface};color:${dark ? '#fff' : C.ink}" title="truth ${esc(labels[i])} → predicted ${esc(labels[j])}: ${v} (${(s * 100).toFixed(1)}% of the row)"${i === j ? ' class="diag"' : ''}>${v}</td>`;
    }).join('')}</tr>`;
  }).join('');
  return `<div class="cm-wrap"><table class="cm"><thead><tr><th class="corner">truth ↓ · predicted →</th>${head}</tr></thead><tbody>${rows}</tbody></table></div>`;
}

// Decision-tree map: every node, the live path drawn thick. Leaves are colored by class, with a legend.
export function treeSVG(root, path, classColor, fname, leafName = l => l) {
  let leaves = 0, depth = 0;
  const nodes = [], edges = [];
  const walk = (n, d, trail) => {
    depth = Math.max(depth, d);
    if ('leaf' in n) { const p = { x: leaves++, d, n, trail }; nodes.push(p); return p; }
    const a = walk(n.l, d + 1, trail + 'L'), b = walk(n.r, d + 1, trail + 'R');
    const p = { x: (a.x + b.x) / 2, d, n, trail };
    nodes.push(p); edges.push([p, a], [p, b]);
    return p;
  };
  walk(root, 0, '');
  const live = path.map(s => s.le ? 'L' : 'R').join('');
  const onPath = t => live.startsWith(t);
  const named = leaves <= 8;                                   // small tree: name every leaf (identity never by color alone)
  const W = Math.max(320, leaves * 14 + 20), H = depth * 46 + (named ? 50 : 34);
  const X = p => (named ? 50 : 10) + p.x * ((W - (named ? 100 : 20)) / Math.max(1, leaves - 1)), Y = p => 14 + p.d * 46;
  const e = edges.map(([a, b]) => {
    const hot = onPath(b.trail);
    return `<path d="M${X(a)},${Y(a)} C${X(a)},${Y(a) + 23} ${X(b)},${Y(b) - 23} ${X(b)},${Y(b)}" class="${hot ? 'hot' : ''}"/>`;
  }).join('');
  const nd = nodes.map(p => {
    const hot = onPath(p.trail) && p.trail.length <= live.length;
    if ('leaf' in p.n) return `<circle cx="${X(p)}" cy="${Y(p)}" r="${hot ? 7 : 4.5}" fill="${classColor(p.n.leaf)}" class="${hot ? 'hot' : ''}"><title>${esc(leafName(p.n.leaf))}</title></circle>`
      + (named ? `<text x="${X(p)}" y="${Y(p) + 20}" text-anchor="middle" class="${hot ? 'hot' : ''}">${esc(leafName(p.n.leaf))}</text>` : '');
    return `<circle cx="${X(p)}" cy="${Y(p)}" r="${hot ? 5 : 3}" class="split ${hot ? 'hot' : ''}"><title>${esc(fname(p.n.f))} ≤ ${+p.n.t.toFixed(2)} ?</title></circle>`;
  }).join('');
  return `<div class="tree-wrap"><svg viewBox="0 0 ${W} ${H}" style="width:100%;min-width:${Math.min(W, 520)}px;height:auto" role="img" aria-label="Decision tree with the live path highlighted"><g class="edges">${e}</g>${nd}</svg></div>`;
}
