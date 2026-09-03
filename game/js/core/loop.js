/**
 * loop.js — laço principal com passo fixo, hitstop, slow-motion e aceleração.
 *
 * Simulação em 60 Hz fixos (determinismo), render em rAF (o que a tela der).
 * Quando a aba fica oculta, o rAF é estrangulado pelo navegador — o tempo
 * perdido vira "progresso offline" (ver sim/offline.js).
 */
import { bus, EV } from './events.js';

export const FIXED_DT = 1 / 60;
const MAX_STEPS = 5;          // teto anti-espiral
const MAX_FRAME_MS = 250;     // salto máximo aceito num frame

export class GameLoop {
  constructor() {
    this.running = false;
    this.accumulator = 0;
    this.lastTime = 0;
    this.rafId = 0;

    this.speed = 1;           // aceleração comprável (turbo)
    this.timeScale = 1;       // slow-mo dramático
    this.hitstop = 0;         // segundos de congelamento
    this.paused = false;

    this.updateFn = null;
    this.renderFn = null;

    // telemetria
    this.fps = 60;
    this.frameMs = 0;
    this.updateMs = 0;
    this.renderMs = 0;
    this.stepsLastFrame = 0;
    this._fpsAccum = 0;
    this._fpsFrames = 0;
    this.elapsed = 0;         // tempo simulado total (s)

    this._onVisibility = this._onVisibility.bind(this);
    this._tick = this._tick.bind(this);
    this.hiddenAt = 0;
  }

  start(updateFn, renderFn) {
    this.updateFn = updateFn;
    this.renderFn = renderFn;
    this.running = true;
    this.lastTime = now();
    if (typeof document !== 'undefined') {
      document.addEventListener('visibilitychange', this._onVisibility);
    }
    this.rafId = raf(this._tick);
  }

  stop() {
    this.running = false;
    if (this.rafId) caf(this.rafId);
    if (typeof document !== 'undefined') document.removeEventListener('visibilitychange', this._onVisibility);
  }

  pause() { if (!this.paused) { this.paused = true; bus.emit(EV.PAUSE); } }
  resume() { if (this.paused) { this.paused = false; this.lastTime = now(); this.accumulator = 0; bus.emit(EV.RESUME); } }
  togglePause() { this.paused ? this.resume() : this.pause(); }

  /** Congela a ação por `ms` — o impacto "pesa". */
  addHitstop(ms) { this.hitstop = Math.min(0.2, Math.max(this.hitstop, ms / 1000)); }
  /** Câmera lenta temporária (ex.: morte de chefe). */
  setSlowmo(scale, durationMs) {
    this.timeScale = scale;
    clearTimeout(this._slowTimer);
    this._slowTimer = setTimeout(() => { this.timeScale = 1; }, durationMs);
  }

  _onVisibility() {
    if (typeof document === 'undefined') return;
    if (document.hidden) {
      this.hiddenAt = Date.now();
    } else if (this.hiddenAt) {
      const away = (Date.now() - this.hiddenAt) / 1000;
      this.hiddenAt = 0;
      this.lastTime = now();
      this.accumulator = 0;
      if (away > 3) bus.emit(EV.OFFLINE_REPORT, { seconds: away, source: 'aba' });
    }
  }

  _tick() {
    if (!this.running) return;
    this.rafId = raf(this._tick);

    const t = now();
    let frame = (t - this.lastTime) / 1000;
    this.lastTime = t;
    if (frame > MAX_FRAME_MS / 1000) frame = MAX_FRAME_MS / 1000;
    this.frameMs = frame * 1000;

    // FPS suavizado (média por segundo)
    this._fpsAccum += frame; this._fpsFrames++;
    if (this._fpsAccum >= 0.5) {
      this.fps = this._fpsFrames / this._fpsAccum;
      this._fpsAccum = 0; this._fpsFrames = 0;
    }

    if (!this.paused) {
      // hitstop consome tempo real sem avançar a simulação
      if (this.hitstop > 0) {
        const consumed = Math.min(this.hitstop, frame);
        this.hitstop -= consumed;
        frame -= consumed;
      }
      this.accumulator += frame * this.speed * this.timeScale;

      const t0 = now();
      let steps = 0;
      while (this.accumulator >= FIXED_DT && steps < MAX_STEPS) {
        this.updateFn(FIXED_DT);
        this.elapsed += FIXED_DT;
        this.accumulator -= FIXED_DT;
        steps++;
      }
      // Se sobrou muito (aceleração alta), consome em bloco para não travar
      if (this.accumulator >= FIXED_DT) {
        const bulk = Math.min(this.accumulator, FIXED_DT * 30);
        this.updateFn(bulk);
        this.elapsed += bulk;
        this.accumulator -= bulk;
        steps++;
      }
      if (this.accumulator > FIXED_DT * 10) this.accumulator = FIXED_DT * 10;
      this.stepsLastFrame = steps;
      this.updateMs = now() - t0;
    }

    const r0 = now();
    this.renderFn(frame, this.accumulator / FIXED_DT);
    this.renderMs = now() - r0;
  }
}

const now = () => (typeof performance !== 'undefined' ? performance.now() : Date.now());
const raf = (fn) => (typeof requestAnimationFrame !== 'undefined' ? requestAnimationFrame(fn) : setTimeout(() => fn(now()), 16));
const caf = (id) => (typeof cancelAnimationFrame !== 'undefined' ? cancelAnimationFrame(id) : clearTimeout(id));

export const loop = new GameLoop();
