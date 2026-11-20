import { C } from './charts.js';

export const $ = s => document.querySelector(s);
export const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
export const setHTML = (el, html) => { if (el._h !== html) { el.innerHTML = html; el._h = html; } };

// Session token (kept in this browser only). Every API call carries it; a 401 sends the user back to sign in.
export const session = {
  get token() { try { return localStorage.getItem('sf_token'); } catch { return null; } },
  set token(v) { try { v ? localStorage.setItem('sf_token', v) : localStorage.removeItem('sf_token'); } catch { /* private mode */ } },
};

export async function api(path, body, method) {
  const headers = { 'Content-Type': 'application/json' };
  if (session.token) headers.Authorization = 'Bearer ' + session.token;
  const r = await fetch(path, { method: method || (body ? 'POST' : 'GET'), headers, body: body ? JSON.stringify(body) : undefined });
  if (r.status === 401 && !path.startsWith('/api/auth/')) { window.dispatchEvent(new Event('sf:unauth')); throw new Error('Please sign in.'); }
  if (!r.ok) {
    const d = (await r.json().catch(() => ({}))).detail;
    throw new Error(typeof d === 'string' ? d : Array.isArray(d) ? 'Please fill every field.' : 'Request failed');
  }
  return r.json();
}

export function toast(msg) {
  const t = $('#toast'); t.textContent = msg; t.classList.add('show');
  clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove('show'), 2600);
}

// Features of the trees: readable name + unit
export const FEAT = {
  soil_raw: ['Soil (raw ADC)', ''], air_temp: ['Air temperature', ' °C'], air_hum: ['Air humidity', ' %'],
  light: ['Light', ' lx'], water_dist: ['Water distance', ' cm'],
  soil_before: ['Soil before watering', ''], soil_drop: ['Soil change after watering', ''],
  water_drop_cm: ['Water taken from tank', ' cm'], soil_std: ['Soil sensor spread', ''],
};
export const fname = f => (FEAT[f] || [f])[0];
export const fval = (f, v) => {
  const u = (FEAT[f] || ['', ''])[1];
  if (v == null) return '–';
  return (f === 'light' ? Math.round(v).toLocaleString('en-GB') : Math.abs(v) >= 100 ? Math.round(v) : (+v).toFixed(2).replace(/\.?0+$/, '')) + u;
};

// Decision labels (the trees speak French: the labels come from the original edge code)
export const LABEL = {
  IRRIGATE: 'Water now', OFF: 'No water needed', REFILL_ALERT: 'Refill the tank',
  FAN_ON: 'Fan on', FAN_OFF: 'Fan off',
  NORMAL: 'Normal', FUITE: 'Leak', POMPE_BLOQUEE: 'Pump stuck', CAPTEUR_DEFAILLANT: 'Faulty soil sensor',
  SAFETY_FLAME: 'Safety: flame',
};
export const lbl = k => LABEL[k] || k;

// Each class keeps its own color everywhere (color follows the entity, never its rank)
const CLASS = {
  IRRIGATE: C.s1, OFF: C.s3, REFILL_ALERT: C.s2,
  FAN_ON: C.s1, FAN_OFF: C.s3,
  NORMAL: C.s3, FUITE: C.s2, POMPE_BLOQUEE: C.s4, CAPTEUR_DEFAILLANT: C.s1,
};
export const classColor = k => CLASS[k] || C.muted;
export const ORDER = {
  irrigation: ['IRRIGATE', 'OFF', 'REFILL_ALERT'], climate: ['FAN_ON', 'FAN_OFF'],
  anomaly: ['NORMAL', 'FUITE', 'POMPE_BLOQUEE', 'CAPTEUR_DEFAILLANT'],
};

export const num = (v, d = 0) => v == null ? '–' : (+v).toLocaleString('en-GB', { minimumFractionDigits: d, maximumFractionDigits: d });
export const lux = v => v == null ? '–' : v >= 1000 ? (v / 1000).toFixed(v >= 10000 ? 0 : 1) + 'k lx' : Math.round(v) + ' lx';
export const when = iso => iso ? new Date(iso).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit', hour12: false }) : '';
