/** i18n.js — internacionalização leve (pt-BR padrão, en como alternativa). */
import { bus, EV } from './events.js';
import { setFormatLocale } from './format.js';

export const LOCALES = ['pt', 'en'];
let current = 'pt';
const dicts = { pt: {}, en: {} };

/** Registra/mescla um bloco de strings. */
export function register(locale, table) {
  Object.assign(dicts[locale] ||= {}, table);
}

export function setLocale(l) {
  if (!LOCALES.includes(l)) return;
  current = l;
  setFormatLocale(l);
  if (typeof document !== 'undefined') document.documentElement.lang = l === 'pt' ? 'pt-BR' : 'en';
  bus.emit(EV.SETTINGS_CHANGE, { key: 'locale', value: l });
  bus.emit(EV.UI_REFRESH, { full: true });
}
export function getLocale() { return current; }

/** t('hud.ouro') -> 'Ouro'; suporta {params}. */
export function t(key, params) {
  let s = dicts[current]?.[key];
  if (s === undefined) s = dicts.pt?.[key];
  if (s === undefined) return key;
  if (params) {
    for (const k of Object.keys(params)) s = s.replaceAll(`{${k}}`, params[k]);
  }
  return s;
}

/** Campo bilíngue vindo de arquivos de dados: {nome, nomeEn}. */
export function tf(obj, field = 'nome') {
  if (!obj) return '';
  if (current === 'en') {
    const en = obj[field + 'En'];
    if (en) return en;
  }
  return obj[field] ?? '';
}

export function detectLocale() {
  if (typeof navigator === 'undefined') return 'pt';
  const l = (navigator.language || 'pt-BR').toLowerCase();
  return l.startsWith('pt') ? 'pt' : 'en';
}
