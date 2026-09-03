/** rng.js — RNG determinístico (mulberry32) + utilidades de sorte. */

export class RNG {
  constructor(seed = 123456789) { this.seed = seed >>> 0; this.s = this.seed; }
  next() {
    this.s = (this.s + 0x6D2B79F5) >>> 0;
    let t = this.s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  float(min = 0, max = 1) { return min + this.next() * (max - min); }
  int(min, max) { return Math.floor(this.float(min, max + 1)); }
  bool(p = 0.5) { return this.next() < p; }
  sign() { return this.next() < 0.5 ? -1 : 1; }
  angle() { return this.next() * Math.PI * 2; }
  pick(arr) { return arr[Math.floor(this.next() * arr.length)]; }
  /** Gaussiana (Box-Muller) — dispersão natural de partículas. */
  gauss(mean = 0, sd = 1) {
    let u = 0, v = 0;
    while (u === 0) u = this.next();
    while (v === 0) v = this.next();
    return mean + sd * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
  }
  reset(seed = this.seed) { this.s = seed >>> 0; return this; }
  state() { return this.s; }
  restore(s) { this.s = s >>> 0; return this; }
}

/** Hash de string -> inteiro 32 bits (para seeds derivadas e determinismo). */
export function hashStr(str) {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

/** RNG global do jogo (visual/loot) — não determinístico entre sessões. */
export const rng = new RNG((Math.random() * 0xffffffff) >>> 0);

/**
 * Sorte com "pity": aumenta a chance a cada falha para evitar sequências frustrantes.
 * Retorna { hit, pity } — o chamador guarda o pity acumulado.
 */
export function pityRoll(baseChance, pity, pityStep, r = Math.random()) {
  const chance = Math.min(1, baseChance + pity * pityStep);
  if (r < chance) return { hit: true, pity: 0 };
  return { hit: false, pity: pity + 1 };
}
