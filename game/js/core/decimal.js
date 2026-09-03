/**
 * decimal.js — Números gigantes (mantissa/expoente) para incrementais profundos.
 *
 * Representação: valor = m * 10^e, com 1 <= |m| < 10 (ou m === 0 para zero).
 * Suporta até ~1e(1.79e308). Sem tetração (layers) — desnecessário para o escopo.
 *
 * API imutável por padrão (`add`, `mul`, ...) e variantes mutáveis `*Mut`
 * para os laços quentes do combate (evita pressão de GC).
 */

const LOG10 = Math.log(10);
const MAX_EXP = 1e308;
const MIN_EXP = -1e308;

export class D {
  constructor(m = 0, e = 0) {
    this.m = m;
    this.e = e;
  }

  /* ---------------------------------------------------------------- núcleo */

  norm() {
    const m = this.m;
    if (m === 0 || !isFinite(m)) {
      if (!isFinite(m)) { this.m = m > 0 ? Infinity : (m < 0 ? -Infinity : NaN); this.e = 0; return this; }
      this.m = 0; this.e = 0; return this;
    }
    const abs = Math.abs(m);
    if (abs >= 1 && abs < 10) {
      // já normalizado
    } else {
      const shift = Math.floor(Math.log10(abs));
      let nm = m / pow10(shift);
      let ne = this.e + shift;
      // correção de borda por erro de ponto flutuante
      const na = Math.abs(nm);
      if (na >= 10) { nm /= 10; ne += 1; }
      else if (na < 1 && na > 0) { nm *= 10; ne -= 1; }
      this.m = nm; this.e = ne;
    }
    if (this.e > MAX_EXP) { this.m = this.m < 0 ? -Infinity : Infinity; this.e = 0; }
    else if (this.e < MIN_EXP) { this.m = 0; this.e = 0; }
    return this;
  }

  clone() { return new D(this.m, this.e); }

  set(other) { this.m = other.m; this.e = other.e; return this; }

  setNumber(n) {
    if (n === 0 || !isFinite(n)) { this.m = isFinite(n) ? 0 : n; this.e = 0; return this; }
    const e = Math.floor(Math.log10(Math.abs(n)));
    this.m = n / pow10(e);
    this.e = e;
    return this.norm();
  }

  /* --------------------------------------------------------- construtores */

  static zero() { return new D(0, 0); }
  static one() { return new D(1, 0); }

  static of(v) {
    if (v instanceof D) return new D(v.m, v.e);
    if (typeof v === 'number') return new D().setNumber(v);
    if (typeof v === 'string') return D.fromString(v);
    if (v && typeof v === 'object' && 'm' in v && 'e' in v) return new D(v.m, v.e);
    return new D(0, 0);
  }

  static fromME(m, e) { return new D(m, e).norm(); }

  static fromString(s) {
    s = String(s).trim().replace(/,/g, '');
    if (s === '' || s === 'NaN') return new D(NaN, 0);
    // formato "1.23e45" / "1.23E45" / "e45"
    const idx = s.search(/[eE]/);
    if (idx >= 0) {
      const mPart = s.slice(0, idx);
      const ePart = s.slice(idx + 1);
      const m = mPart === '' || mPart === '+' ? 1 : (mPart === '-' ? -1 : parseFloat(mPart));
      const e = parseFloat(ePart);
      if (!isFinite(e)) return new D(NaN, 0);
      return new D(m, 0).norm().mulPow10Mut(e);
    }
    return new D().setNumber(parseFloat(s));
  }

  /* ------------------------------------------------------------ aritmética */

  add(other) { return this.clone().addMut(other); }
  addMut(other) {
    const o = other instanceof D ? other : D.of(other);
    if (o.m === 0) return this;
    if (this.m === 0) { this.m = o.m; this.e = o.e; return this; }
    let big = this, small = o;
    if (this.e < o.e) { big = o; small = this; }
    const de = big.e - small.e;
    if (de > 17) { this.m = big.m; this.e = big.e; return this; }
    this.m = big.m + small.m / pow10(de);
    this.e = big.e;
    return this.norm();
  }

  sub(other) { return this.clone().subMut(other); }
  subMut(other) {
    const o = other instanceof D ? other : D.of(other);
    return this.addMut(new D(-o.m, o.e));
  }

  mul(other) { return this.clone().mulMut(other); }
  mulMut(other) {
    const o = other instanceof D ? other : D.of(other);
    this.m *= o.m;
    this.e += o.e;
    return this.norm();
  }

  mulN(n) { return this.clone().mulNMut(n); }
  mulNMut(n) {
    if (n === 0) { this.m = 0; this.e = 0; return this; }
    this.m *= n;
    return this.norm();
  }

  div(other) { return this.clone().divMut(other); }
  divMut(other) {
    const o = other instanceof D ? other : D.of(other);
    if (o.m === 0) { this.m = this.m === 0 ? NaN : (this.m > 0 ? Infinity : -Infinity); this.e = 0; return this; }
    this.m /= o.m;
    this.e -= o.e;
    return this.norm();
  }

  divN(n) { return this.clone().mulNMut(1 / n); }

  neg() { return new D(-this.m, this.e); }
  abs() { return new D(Math.abs(this.m), this.e); }
  recip() { return D.one().divMut(this); }

  mulPow10(e) { return this.clone().mulPow10Mut(e); }
  mulPow10Mut(e) {
    if (this.m === 0) return this;
    this.e += e;
    return this.norm();
  }

  /* ---------------------------------------------------------- exponenciais */

  log10() {
    if (this.m === 0) return -Infinity;
    if (this.m < 0) return NaN;
    return this.e + Math.log10(this.m);
  }

  ln() { return this.log10() * LOG10; }
  logBase(b) { return this.log10() / Math.log10(b); }

  static pow10(x) {
    const e = Math.floor(x);
    return new D(pow10(x - e), e).norm();
  }

  static exp(x) { return D.pow10(x / LOG10); }

  pow(n) {
    if (n === 0) return D.one();
    if (n === 1) return this.clone();
    if (this.m === 0) return n > 0 ? D.zero() : new D(Infinity, 0);
    if (this.m < 0) {
      // apenas expoentes inteiros para bases negativas
      const r = this.abs().pow(n);
      return (Math.abs(n % 2) === 1) ? r.neg() : r;
    }
    return D.pow10(this.log10() * n);
  }

  sqrt() { return this.pow(0.5); }
  cbrt() { return this.pow(1 / 3); }

  /** Raiz enésima segura (this^(1/n)). */
  root(n) { return this.pow(1 / n); }

  /* -------------------------------------------------------- comparadores */

  cmp(other) {
    const o = other instanceof D ? other : D.of(other);
    if (this.m === 0 && o.m === 0) return 0;
    if (this.m === 0) return o.m > 0 ? -1 : 1;
    if (o.m === 0) return this.m > 0 ? 1 : -1;
    const s1 = this.m > 0 ? 1 : -1;
    const s2 = o.m > 0 ? 1 : -1;
    if (s1 !== s2) return s1 > s2 ? 1 : -1;
    if (this.e !== o.e) return (this.e > o.e ? 1 : -1) * s1;
    if (this.m === o.m) return 0;
    return this.m > o.m ? 1 : -1;
  }

  lt(o) { return this.cmp(o) < 0; }
  lte(o) { return this.cmp(o) <= 0; }
  gt(o) { return this.cmp(o) > 0; }
  gte(o) { return this.cmp(o) >= 0; }
  eq(o) { return this.cmp(o) === 0; }
  isZero() { return this.m === 0; }
  isPos() { return this.m > 0; }
  isNeg() { return this.m < 0; }
  isNaN() { return Number.isNaN(this.m); }
  isFinite() { return Number.isFinite(this.m) && Number.isFinite(this.e); }

  max(o) { return this.gte(o) ? this.clone() : D.of(o); }
  min(o) { return this.lte(o) ? this.clone() : D.of(o); }
  clamp(lo, hi) { return this.max(lo).min(hi); }

  /* ------------------------------------------------------------- conversão */

  toNumber() {
    if (this.m === 0) return 0;
    if (this.e > 308) return this.m > 0 ? Infinity : -Infinity;
    if (this.e < -324) return 0;
    return this.m * pow10(this.e);
  }

  floor() {
    if (this.e >= 17) return this.clone();
    return new D().setNumber(Math.floor(this.toNumber()));
  }
  ceil() {
    if (this.e >= 17) return this.clone();
    return new D().setNumber(Math.ceil(this.toNumber()));
  }
  round() {
    if (this.e >= 17) return this.clone();
    return new D().setNumber(Math.round(this.toNumber()));
  }

  toJSON() { return this.m === 0 ? '0' : `${this.m}e${this.e}`; }
  toString() { return this.toJSON(); }

  /* --------------------------------------------------------------- extras */

  /** Interpolação logarítmica — útil para barras de progresso com números enormes. */
  static logProgress(cur, goal) {
    const c = cur.log10(), g = goal.log10();
    if (!isFinite(c)) return 0;
    if (!isFinite(g) || g <= 0) return c >= g ? 1 : 0;
    return Math.max(0, Math.min(1, c / g));
  }

  /**
   * Quantas compras cabem no orçamento para custo geométrico:
   *   custo(i) = base * growth^(owned + i)
   * Retorna número inteiro (JS number) — limitado por `cap`.
   */
  static maxAffordableGeometric(budget, base, growth, owned, cap = 1e6) {
    if (growth <= 1) {
      const unit = D.of(base).mul(D.of(growth).pow(owned));
      if (unit.isZero()) return cap;
      return Math.min(cap, Math.floor(D.of(budget).div(unit).toNumber()) || 0);
    }
    const b = D.of(budget);
    if (b.lte(0)) return 0;
    const first = D.of(base).mul(D.of(growth).pow(owned));
    if (first.gt(b)) return 0;
    // k = log_g( 1 + budget*(g-1)/first )
    const inner = b.mul(growth - 1).div(first).add(1);
    const k = Math.floor(inner.log10() / Math.log10(growth) + 1e-9);
    return Math.max(0, Math.min(cap, k));
  }

  /** Custo total de `count` compras com custo geométrico. */
  static geometricSum(base, growth, owned, count) {
    if (count <= 0) return D.zero();
    const first = D.of(base).mul(D.of(growth).pow(owned));
    if (growth === 1) return first.mulN(count);
    return first.mul(D.of(growth).pow(count).sub(1)).div(growth - 1);
  }
}

/** 10^n rápido com cache para expoentes pequenos. */
const POW10_CACHE = new Float64Array(633);
for (let i = 0; i < 633; i++) POW10_CACHE[i] = Number(`1e${i - 316}`);
export function pow10(n) {
  if (Number.isInteger(n) && n >= -316 && n <= 316) return POW10_CACHE[n + 316];
  return Math.pow(10, n);
}

/* Atalhos de conveniência ------------------------------------------------- */
export const d = (v) => D.of(v);
export const DZERO = Object.freeze(new D(0, 0));
export const DONE = Object.freeze(new D(1, 0));

export default D;
