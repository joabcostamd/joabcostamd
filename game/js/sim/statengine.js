/**
 * statengine.js — agregação de modificadores.
 *
 *   valor = (base + Σflat) × (1 + Σpct) × Πmult
 *
 * `dano` e derivados usam `D` (podem passar de 1e308 no fim de jogo);
 * atributos "físicos" (alcance, velocidade) usam números normais.
 */
import { D } from '../core/decimal.js';
import { STAT_DEFS, STAT_KEYS } from '../data/stats.js';

/** Atributos que precisam de precisão infinita. */
export const STATS_GRANDES = new Set(['dano', 'vidaMax', 'escudoMax', 'regen', 'escudoRegen']);

export class StatEngine {
  constructor() {
    this.flat = Object.create(null);
    this.pct = Object.create(null);
    this.mult = Object.create(null);
    this.valor = Object.create(null);
    this.fontes = Object.create(null);   // rastreio para tooltips: {stat: [{nome, texto}]}
    this.dirty = true;
    this.recomputes = 0;
    this.reset();
  }

  reset() {
    for (const k of STAT_KEYS) {
      this.flat[k] = STATS_GRANDES.has(k) ? D.of(0) : 0;
      this.pct[k] = 0;
      this.mult[k] = 1;
      this.fontes[k] = [];
    }
  }

  addFlat(key, v, fonte) {
    if (!(key in this.flat)) return;
    if (STATS_GRANDES.has(key)) this.flat[key] = this.flat[key].add(v);
    else this.flat[key] += (v instanceof D ? v.toNumber() : v);
    if (fonte) this.fontes[key].push({ fonte, tipo: 'flat', valor: v });
  }

  addPct(key, v, fonte) {
    if (!(key in this.pct)) return;
    this.pct[key] += (v instanceof D ? v.toNumber() : v);
    if (fonte) this.fontes[key].push({ fonte, tipo: 'pct', valor: v });
  }

  addMult(key, v, fonte) {
    if (!(key in this.mult)) return;
    const n = v instanceof D ? v.toNumber() : v;
    if (!isFinite(n) || n <= 0) return;
    this.mult[key] *= n;
    if (fonte) this.fontes[key].push({ fonte, tipo: 'mult', valor: v });
  }

  /** Multiplicador gigante (ex.: prestígio ×1e12) — só para stats grandes. */
  addMultBig(key, v, fonte) {
    if (!STATS_GRANDES.has(key)) return this.addMult(key, v, fonte);
    this._bigMult ||= Object.create(null);
    this._bigMult[key] = (this._bigMult[key] || D.of(1)).mul(v);
    if (fonte) this.fontes[key].push({ fonte, tipo: 'mult', valor: v });
  }

  compute() {
    this.recomputes++;
    for (const k of STAT_KEYS) {
      const def = STAT_DEFS[k];
      const pct = 1 + this.pct[k];
      if (STATS_GRANDES.has(k)) {
        let v = D.of(def.base).add(this.flat[k]).mulN(Math.max(0, pct)).mulN(this.mult[k]);
        if (this._bigMult && this._bigMult[k]) v = v.mul(this._bigMult[k]);
        if (v.isNeg()) v = D.of(0);
        this.valor[k] = v;
      } else {
        let v = (def.base + this.flat[k]) * Math.max(0, pct) * this.mult[k];
        if (def.max !== undefined) v = Math.min(v, def.max);
        if (def.inteiro) v = Math.max(0, Math.floor(v + 1e-9));
        if (!isFinite(v)) v = Number.MAX_VALUE;
        this.valor[k] = v;
      }
    }
    this.dirty = false;
    return this.valor;
  }

  get(key) {
    if (this.dirty) this.compute();
    return this.valor[key];
  }
  /** Sempre número JS (para física/render). */
  getN(key) {
    const v = this.get(key);
    return v instanceof D ? v.toNumber() : v;
  }
  /** Sempre D (para dano/vida). */
  getD(key) {
    const v = this.get(key);
    return v instanceof D ? v : D.of(v);
  }
}
