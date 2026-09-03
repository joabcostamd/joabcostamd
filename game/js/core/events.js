/** events.js — barramento de eventos global, tipado por convenção. */

class EventBus {
  constructor() { this.map = new Map(); this.anyHandlers = []; this.depth = 0; }

  on(type, fn) {
    if (!this.map.has(type)) this.map.set(type, []);
    this.map.get(type).push(fn);
    return () => this.off(type, fn);
  }
  once(type, fn) {
    const off = this.on(type, (payload) => { off(); fn(payload); });
    return off;
  }
  off(type, fn) {
    const arr = this.map.get(type);
    if (!arr) return;
    const i = arr.indexOf(fn);
    if (i >= 0) arr.splice(i, 1);
  }
  onAny(fn) { this.anyHandlers.push(fn); return () => { const i = this.anyHandlers.indexOf(fn); if (i >= 0) this.anyHandlers.splice(i, 1); }; }

  emit(type, payload) {
    const arr = this.map.get(type);
    if (arr) {
      // cópia defensiva: handlers podem se remover durante o disparo
      const snapshot = arr.length > 1 ? arr.slice() : arr;
      for (let i = 0; i < snapshot.length; i++) {
        try { snapshot[i](payload); }
        catch (err) { console.error(`[bus] erro em "${type}":`, err); }
      }
    }
    for (let i = 0; i < this.anyHandlers.length; i++) {
      try { this.anyHandlers[i](type, payload); } catch (err) { console.error('[bus] onAny:', err); }
    }
  }
  clear() { this.map.clear(); this.anyHandlers.length = 0; }
}

export const bus = new EventBus();

/** Catálogo canônico de eventos — usar sempre estas constantes. */
export const EV = {
  // ciclo
  READY: 'ready',
  TICK: 'tick',
  RENDER: 'render',
  PAUSE: 'pause',
  RESUME: 'resume',
  // combate
  ENEMY_SPAWN: 'enemy:spawn',
  ENEMY_HIT: 'enemy:hit',
  ENEMY_KILL: 'enemy:kill',
  ENEMY_REACH: 'enemy:reach',
  BOSS_SPAWN: 'boss:spawn',
  BOSS_PHASE: 'boss:phase',
  BOSS_KILL: 'boss:kill',
  TOWER_HIT: 'tower:hit',
  TOWER_SHOOT: 'tower:shoot',
  TOWER_DEATH: 'tower:death',
  CRIT: 'crit',
  COMBO: 'combo',
  COMBO_BREAK: 'combo:break',
  OVERKILL: 'overkill',
  // economia
  GOLD_GAIN: 'gold:gain',
  CURRENCY_GAIN: 'currency:gain',
  UPGRADE_BUY: 'upgrade:buy',
  UPGRADE_MAX: 'upgrade:max',
  TALENT_BUY: 'talent:buy',
  CARD_EQUIP: 'card:equip',
  RELIC_DROP: 'relic:drop',
  LOOT_DROP: 'loot:drop',
  // progressão
  WAVE_START: 'wave:start',
  WAVE_CLEAR: 'wave:clear',
  WAVE_FAIL: 'wave:fail',
  LEVEL_UP: 'level:up',
  UNLOCK: 'unlock',
  ACHIEVEMENT: 'achievement',
  MISSION_DONE: 'mission:done',
  PRESTIGE: 'prestige',
  ERA_CHANGE: 'era:change',
  CHALLENGE_START: 'challenge:start',
  CHALLENGE_DONE: 'challenge:done',
  RANDOM_EVENT: 'event:random',
  // habilidades
  ABILITY_USE: 'ability:use',
  ABILITY_READY: 'ability:ready',
  // ui
  SCREEN_CHANGE: 'screen:change',
  PANEL_OPEN: 'panel:open',
  TOAST: 'toast',
  NOTIFY: 'notify',
  SETTINGS_CHANGE: 'settings:change',
  SAVE: 'save',
  LOAD: 'load',
  OFFLINE_REPORT: 'offline:report',
  UI_REFRESH: 'ui:refresh',
  // juice
  SHAKE: 'fx:shake',
  HITSTOP: 'fx:hitstop',
  FLASH: 'fx:flash',
  ZOOM_PUNCH: 'fx:zoom',
  SLOWMO: 'fx:slowmo',
  CELEBRATE: 'fx:celebrate',
};
