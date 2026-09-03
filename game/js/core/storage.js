/**
 * storage.js — persistência: serialização com Decimal, versionamento,
 * migrações, backup automático, export/import em Base64 e slots.
 */
import { D } from './decimal.js';
import { bus, EV } from './events.js';

export const SAVE_VERSION = 1;
const KEY_MAIN = 'torre_eterna:save';
const KEY_BACKUP = 'torre_eterna:backup';
const KEY_SETTINGS = 'torre_eterna:settings';
const MAGIC = 'TORRE1|';

/* ------------------------------------------------------- serialização */

/** Converte D -> string marcada; preserva Set/Map como arrays. */
export function replacer(key, value) {
  if (value instanceof D) return { __D: value.toJSON() };
  if (value instanceof Set) return { __S: Array.from(value) };
  if (value instanceof Map) return { __M: Array.from(value.entries()) };
  if (typeof value === 'number' && !Number.isFinite(value)) return { __N: value > 0 ? 'inf' : (value < 0 ? '-inf' : 'nan') };
  return value;
}

export function reviver(key, value) {
  if (value && typeof value === 'object') {
    if (typeof value.__D === 'string') return D.fromString(value.__D);
    if (Array.isArray(value.__S)) return new Set(value.__S);
    if (Array.isArray(value.__M)) return new Map(value.__M);
    if (typeof value.__N === 'string') return value.__N === 'inf' ? Infinity : value.__N === '-inf' ? -Infinity : NaN;
  }
  return value;
}

export const serialize = (obj) => JSON.stringify(obj, replacer);
export const deserialize = (str) => JSON.parse(str, reviver);

/* ------------------------------------------------------------ base64 */

function toB64(str) {
  const bytes = new TextEncoder().encode(str);
  let bin = '';
  const CH = 0x8000;
  for (let i = 0; i < bytes.length; i += CH) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
  return btoa(bin);
}
function fromB64(b64) {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new TextDecoder().decode(bytes);
}
function checksum(str) {
  let h = 5381;
  for (let i = 0; i < str.length; i++) h = ((h << 5) + h + str.charCodeAt(i)) >>> 0;
  return h.toString(36);
}

/* ------------------------------------------------------------ storage */

function safeLocal() {
  try {
    if (typeof localStorage === 'undefined') return null;
    localStorage.setItem('__probe', '1');
    localStorage.removeItem('__probe');
    return localStorage;
  } catch { return null; }
}
const memoryStore = new Map();
const store = {
  get(k) { const ls = safeLocal(); return ls ? ls.getItem(k) : (memoryStore.get(k) ?? null); },
  set(k, v) { const ls = safeLocal(); if (ls) { try { ls.setItem(k, v); return true; } catch (e) { console.warn('[save] quota', e); return false; } } memoryStore.set(k, v); return true; },
  remove(k) { const ls = safeLocal(); if (ls) ls.removeItem(k); else memoryStore.delete(k); },
  available() { return safeLocal() !== null; },
};

/* ---------------------------------------------------------- migrações */

/**
 * Cada migração transforma o save da versão N para N+1.
 * Manter para sempre — jogadores voltam com saves antigos.
 */
export const MIGRATIONS = {
  // 0: (s) => { ...; return s; },
};

export function migrate(save) {
  let v = save.version ?? 0;
  while (v < SAVE_VERSION) {
    const fn = MIGRATIONS[v];
    if (fn) { try { save = fn(save); } catch (e) { console.error('[save] migração', v, e); } }
    v++;
    save.version = v;
  }
  return save;
}

/* --------------------------------------------------------------- API */

export const Storage = {
  available: store.available(),

  save(state, { backup = true } = {}) {
    try {
      const payload = serialize(state);
      if (backup) {
        const prev = store.get(KEY_MAIN);
        if (prev) store.set(KEY_BACKUP, prev);
      }
      const ok = store.set(KEY_MAIN, payload);
      if (ok) bus.emit(EV.SAVE, { bytes: payload.length });
      return ok;
    } catch (e) {
      console.error('[save] falha ao salvar', e);
      return false;
    }
  },

  load() {
    const raw = store.get(KEY_MAIN);
    if (!raw) return null;
    try {
      return migrate(deserialize(raw));
    } catch (e) {
      console.error('[save] save corrompido, tentando backup', e);
      const bak = store.get(KEY_BACKUP);
      if (bak) {
        try { return migrate(deserialize(bak)); } catch (e2) { console.error('[save] backup também corrompido', e2); }
      }
      return null;
    }
  },

  hasSave() { return !!store.get(KEY_MAIN); },
  wipe() { store.remove(KEY_MAIN); store.remove(KEY_BACKUP); },

  /** Configurações ficam fora do save do jogo (sobrevivem a reset). */
  saveSettings(settings) { store.set(KEY_SETTINGS, JSON.stringify(settings)); },
  loadSettings() {
    const raw = store.get(KEY_SETTINGS);
    if (!raw) return null;
    try { return JSON.parse(raw); } catch { return null; }
  },

  /** Texto exportável: MAGIC + checksum + base64. */
  exportString(state) {
    const json = serialize(state);
    const b64 = toB64(json);
    return MAGIC + checksum(b64) + '|' + b64;
  },

  importString(text) {
    text = String(text).trim().replace(/\s/g, '');
    if (!text.startsWith(MAGIC)) throw new Error('Código de save inválido (assinatura não reconhecida).');
    const rest = text.slice(MAGIC.length);
    const sep = rest.indexOf('|');
    if (sep < 0) throw new Error('Código de save incompleto.');
    const sum = rest.slice(0, sep);
    const b64 = rest.slice(sep + 1);
    if (checksum(b64) !== sum) throw new Error('Código de save corrompido (checksum não confere).');
    const json = fromB64(b64);
    return migrate(deserialize(json));
  },

  /** Tamanho aproximado do save em KB. */
  sizeKB() {
    const raw = store.get(KEY_MAIN);
    return raw ? Math.round((raw.length / 1024) * 10) / 10 : 0;
  },
};
