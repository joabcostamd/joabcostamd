/** util.js — matemática, easing, cores e helpers gerais. */

export const TAU = Math.PI * 2;
export const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
export const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);
export const lerp = (a, b, t) => a + (b - a) * t;
export const invLerp = (a, b, v) => (b === a ? 0 : (v - a) / (b - a));
export const remap = (v, a1, b1, a2, b2) => lerp(a2, b2, clamp01(invLerp(a1, b1, v)));
export const approach = (cur, target, dt, rate) => cur + (target - cur) * (1 - Math.exp(-rate * dt));
export const dist2 = (ax, ay, bx, by) => { const dx = bx - ax, dy = by - ay; return dx * dx + dy * dy; };
export const dist = (ax, ay, bx, by) => Math.sqrt(dist2(ax, ay, bx, by));
export const angleTo = (ax, ay, bx, by) => Math.atan2(by - ay, bx - ax);
export const angleLerp = (a, b, t) => {
  let diff = ((b - a + Math.PI) % TAU + TAU) % TAU - Math.PI;
  return a + diff * t;
};
export const wrapAngle = (a) => ((a + Math.PI) % TAU + TAU) % TAU - Math.PI;
export const sign = Math.sign;
export const round2 = (v) => Math.round(v * 100) / 100;

/* --------------------------------------------------------------- easing */
export const Ease = {
  linear: (t) => t,
  inQuad: (t) => t * t,
  outQuad: (t) => t * (2 - t),
  inOutQuad: (t) => (t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t),
  inCubic: (t) => t * t * t,
  outCubic: (t) => 1 - Math.pow(1 - t, 3),
  inOutCubic: (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
  outQuart: (t) => 1 - Math.pow(1 - t, 4),
  outQuint: (t) => 1 - Math.pow(1 - t, 5),
  outExpo: (t) => (t === 1 ? 1 : 1 - Math.pow(2, -10 * t)),
  inExpo: (t) => (t === 0 ? 0 : Math.pow(2, 10 * t - 10)),
  outBack: (t) => { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); },
  inBack: (t) => { const c1 = 1.70158, c3 = c1 + 1; return c3 * t * t * t - c1 * t * t; },
  outElastic: (t) => {
    const c4 = TAU / 3;
    return t === 0 ? 0 : t === 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
  },
  outBounce: (t) => {
    const n1 = 7.5625, d1 = 2.75;
    if (t < 1 / d1) return n1 * t * t;
    if (t < 2 / d1) return n1 * (t -= 1.5 / d1) * t + 0.75;
    if (t < 2.5 / d1) return n1 * (t -= 2.25 / d1) * t + 0.9375;
    return n1 * (t -= 2.625 / d1) * t + 0.984375;
  },
  inOutSine: (t) => -(Math.cos(Math.PI * t) - 1) / 2,
  pulse: (t) => Math.sin(t * Math.PI),
};

/* ----------------------------------------------------------------- cores */

export function hexToRgb(hex) {
  let h = hex.replace('#', '');
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  const n = parseInt(h, 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}
export function rgbToHex(r, g, b) {
  return '#' + [r, g, b].map((v) => clamp(Math.round(v), 0, 255).toString(16).padStart(2, '0')).join('');
}
export function mixHex(a, b, t) {
  const A = hexToRgb(a), B = hexToRgb(b);
  return rgbToHex(lerp(A.r, B.r, t), lerp(A.g, B.g, t), lerp(A.b, B.b, t));
}
export function rgba(hex, alpha) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},${alpha})`;
}
export function shade(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  return amount >= 0
    ? rgbToHex(lerp(r, 255, amount), lerp(g, 255, amount), lerp(b, 255, amount))
    : rgbToHex(lerp(r, 0, -amount), lerp(g, 0, -amount), lerp(b, 0, -amount));
}
/** HSL -> hex, usado pela arte procedural. */
export function hsl(h, s, l) {
  h = ((h % 360) + 360) % 360; s = clamp01(s); l = clamp01(l);
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c / 2;
  let r = 0, g = 0, b = 0;
  if (h < 60) [r, g, b] = [c, x, 0];
  else if (h < 120) [r, g, b] = [x, c, 0];
  else if (h < 180) [r, g, b] = [0, c, x];
  else if (h < 240) [r, g, b] = [0, x, c];
  else if (h < 300) [r, g, b] = [x, 0, c];
  else [r, g, b] = [c, 0, x];
  return rgbToHex((r + m) * 255, (g + m) * 255, (b + m) * 255);
}

/* ------------------------------------------------------------- coleções */

export const pick = (arr, rnd = Math.random) => arr[Math.floor(rnd() * arr.length)];
export function weightedPick(items, weightFn, rnd = Math.random) {
  let total = 0;
  for (const it of items) total += weightFn(it);
  if (total <= 0) return null;
  let r = rnd() * total;
  for (const it of items) { r -= weightFn(it); if (r <= 0) return it; }
  return items[items.length - 1];
}
export function shuffle(arr, rnd = Math.random) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
export const sum = (arr, f = (x) => x) => arr.reduce((s, x) => s + f(x), 0);
export const groupBy = (arr, keyFn) => arr.reduce((acc, x) => { (acc[keyFn(x)] ||= []).push(x); return acc; }, {});

/* ---------------------------------------------------------------- tempo */

/** 3661 -> "1h 01m 01s" */
export function formatTime(seconds, compact = false) {
  if (!isFinite(seconds) || seconds < 0) return '—';
  const s = Math.floor(seconds % 60);
  const m = Math.floor((seconds / 60) % 60);
  const h = Math.floor((seconds / 3600) % 24);
  const dd = Math.floor(seconds / 86400);
  if (dd > 0) return compact ? `${dd}d${h}h` : `${dd}d ${pad(h)}h ${pad(m)}m`;
  if (h > 0) return compact ? `${h}h${pad(m)}` : `${h}h ${pad(m)}m ${pad(s)}s`;
  if (m > 0) return compact ? `${m}m${pad(s)}` : `${m}m ${pad(s)}s`;
  return `${s}s`;
}
export const pad = (n) => String(n).padStart(2, '0');

/* ---------------------------------------------------------------- misc */

export function debounce(fn, ms) {
  let t = 0;
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
}
export function throttle(fn, ms) {
  let last = 0, timer = 0, lastArgs = null;
  return (...args) => {
    const now = performance.now();
    lastArgs = args;
    if (now - last >= ms) { last = now; fn(...args); }
    else if (!timer) {
      timer = setTimeout(() => { timer = 0; last = performance.now(); fn(...lastArgs); }, ms - (now - last));
    }
  };
}
export const deepClone = (o) => (typeof structuredClone === 'function' ? structuredClone(o) : JSON.parse(JSON.stringify(o)));
export function deepMerge(target, source) {
  for (const k of Object.keys(source)) {
    const sv = source[k];
    if (sv && typeof sv === 'object' && !Array.isArray(sv) && target[k] && typeof target[k] === 'object' && !Array.isArray(target[k])) {
      deepMerge(target[k], sv);
    } else if (sv !== undefined) {
      target[k] = sv;
    }
  }
  return target;
}
export const uid = (() => { let n = 0; return (prefix = 'id') => `${prefix}_${(++n).toString(36)}`; })();
