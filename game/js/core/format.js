/** format.js — formatação de números gigantes em várias notações. */
import { D } from './decimal.js';

/** Sufixos curtos: K, M, B, T, Qa... e depois aa, ab, ac... (padrão do gênero). */
const SHORT = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc',
  'UDc', 'DDc', 'TDc', 'QaDc', 'QiDc', 'SxDc', 'SpDc', 'ODc', 'NDc', 'Vg'];

/** Nomes por extenso em PT-BR (escala longa brasileira). */
const LONG_PT = ['', 'mil', 'milhão', 'bilhão', 'trilhão', 'quatrilhão', 'quintilhão',
  'sextilhão', 'septilhão', 'octilhão', 'nonilhão', 'decilhão', 'undecilhão', 'duodecilhão',
  'tredecilhão', 'quatuordecilhão', 'quindecilhão'];
const LONG_PT_PLURAL = ['', 'mil', 'milhões', 'bilhões', 'trilhões', 'quatrilhões', 'quintilhões',
  'sextilhões', 'septilhões', 'octilhões', 'nonilhões', 'decilhões', 'undecilhões', 'duodecilhões',
  'tredecilhões', 'quatuordecilhões', 'quindecilhões'];
const LONG_EN = ['', 'thousand', 'million', 'billion', 'trillion', 'quadrillion', 'quintillion',
  'sextillion', 'septillion', 'octillion', 'nonillion', 'decillion', 'undecillion', 'duodecillion',
  'tredecillion', 'quattuordecillion', 'quindecillion'];

/** Letras estendidas: aa, ab ... zz para expoentes altíssimos. */
function letterSuffix(tier) {
  if (tier < SHORT.length) return SHORT[tier];
  let n = tier - SHORT.length;
  let s = '';
  do { s = String.fromCharCode(97 + (n % 26)) + s; n = Math.floor(n / 26) - 1; } while (n >= 0);
  return s;
}

export const NOTATIONS = ['mista', 'letras', 'cientifica', 'engenharia', 'padrao', 'logaritmica'];
export const NOTATION_LABELS = {
  mista: { pt: 'Mista (recomendada)', en: 'Mixed (recommended)' },
  letras: { pt: 'Letras (1,23 K)', en: 'Letters (1.23 K)' },
  cientifica: { pt: 'Científica (1,23e6)', en: 'Scientific (1.23e6)' },
  engenharia: { pt: 'Engenharia (1,23e6)', en: 'Engineering (1.23e6)' },
  padrao: { pt: 'Por extenso (1,23 milhões)', en: 'Long form (1.23 million)' },
  logaritmica: { pt: 'Logarítmica (e6,09)', en: 'Logarithmic (e6.09)' },
};

const cfg = { notation: 'mista', decimals: 2, locale: 'pt' };

export function setNotation(n) { if (NOTATIONS.includes(n)) cfg.notation = n; }
export function setDecimals(n) { cfg.decimals = Math.max(0, Math.min(4, n | 0)); }
export function setFormatLocale(l) { cfg.locale = l === 'en' ? 'en' : 'pt'; }
export function getNotation() { return cfg.notation; }

const decSep = () => (cfg.locale === 'pt' ? ',' : '.');
const thoSep = () => (cfg.locale === 'pt' ? '.' : ',');

function fixed(n, dec) {
  let s = n.toFixed(dec);
  if (dec > 0) s = s.replace(/\.?0+$/, '');
  return cfg.locale === 'pt' ? s.replace('.', ',') : s;
}

function withThousands(intStr) {
  return intStr.replace(/\B(?=(\d{3})+(?!\d))/g, thoSep());
}

/**
 * Formata um número (JS number ou D).
 * @param {number|D|string} value
 * @param {{decimals?:number, notation?:string, forceSign?:boolean, small?:boolean}} [opts]
 */
export function fmt(value, opts = {}) {
  const dec = opts.decimals ?? cfg.decimals;
  const notation = opts.notation ?? cfg.notation;
  const v = value instanceof D ? value : D.of(value);

  if (v.isNaN()) return '?';
  if (!v.isFinite()) return v.isNeg() ? '-∞' : '∞';
  const sign = v.isNeg() ? '-' : (opts.forceSign && !v.isZero() ? '+' : '');
  const a = v.abs();

  if (a.isZero()) return sign + '0';

  const exp = a.log10();

  // números pequenos (< 1) — úteis para taxas e porcentagens
  if (exp < 0) {
    const n = a.toNumber();
    if (n >= 0.01 || opts.small) return sign + fixed(n, Math.max(dec, 2));
    return sign + fmtSci(a, dec);
  }

  // até 999.999 sempre por extenso com separador de milhar
  if (exp < 6) {
    const n = a.toNumber();
    if (n < 1000) return sign + fixed(n, n < 10 ? Math.min(dec, 2) : (n < 100 ? Math.min(dec, 1) : 0));
    const intPart = Math.floor(n);
    return sign + withThousands(String(intPart));
  }

  switch (notation) {
    case 'cientifica': return sign + fmtSci(a, dec);
    case 'engenharia': return sign + fmtEng(a, dec);
    case 'logaritmica': return sign + 'e' + fixed(exp, 3);
    case 'letras': return sign + fmtLetters(a, dec);
    case 'padrao': return sign + fmtLong(a, dec);
    case 'mista':
    default:
      return sign + (exp < 36 ? fmtLetters(a, dec) : fmtSci(a, dec));
  }
}

function fmtSci(a, dec) {
  const e = Math.floor(a.log10());
  const m = a.div(D.pow10(e)).toNumber();
  return `${fixed(m, dec)}e${e}`;
}

function fmtEng(a, dec) {
  const e = Math.floor(a.log10());
  const e3 = Math.floor(e / 3) * 3;
  const m = a.div(D.pow10(e3)).toNumber();
  return `${fixed(m, dec)}e${e3}`;
}

function fmtLetters(a, dec) {
  const e = Math.floor(a.log10());
  const tier = Math.floor(e / 3);
  const suffix = letterSuffix(tier);
  if (!suffix) return fixed(a.toNumber(), dec);
  const m = a.div(D.pow10(tier * 3)).toNumber();
  return `${fixed(m, dec)} ${suffix}`;
}

function fmtLong(a, dec) {
  const e = Math.floor(a.log10());
  const tier = Math.floor(e / 3);
  const table = cfg.locale === 'pt' ? LONG_PT : LONG_EN;
  if (tier >= table.length) return fmtSci(a, dec);
  const m = a.div(D.pow10(tier * 3)).toNumber();
  const isPlural = m >= 2 || (m > 1 && dec > 0);
  const name = cfg.locale === 'pt'
    ? (isPlural ? LONG_PT_PLURAL[tier] : LONG_PT[tier])
    : table[tier];
  return name ? `${fixed(m, dec)} ${name}` : fixed(m, dec);
}

/** Percentual: 0.153 -> "15,3%" */
export function fmtPct(frac, dec = 1) {
  return `${fixed((frac || 0) * 100, dec)}%`;
}

/** Multiplicador: 2.5 -> "×2,50" */
export function fmtMult(v, dec = 2) {
  const s = fmt(v, { decimals: dec });
  return `×${s}`;
}

/** Ganho por segundo. */
export function fmtRate(v, unit = '/s') {
  return fmt(v) + unit;
}

/** Números inteiros pequenos com separador (níveis, contagens). */
export function fmtInt(n) {
  return withThousands(String(Math.floor(n)));
}

/** Barra de progresso textual — usada por leitores de tela. */
export function fmtProgress(cur, max) {
  return `${fmt(cur)} / ${fmt(max)}`;
}
