/**
 * waves.js — diretor de ondas: ritmo de spawn, chefes, limpeza e avanço.
 */
import { bus, EV } from '../core/events.js';
import { rng } from '../core/rng.js';
import { ONDA } from '../data/balance.js';
import { inimigos } from './arena.js';
import { spawnDaOnda, spawnChefe } from './enemies.js';

export class DiretorDeOndas {
  constructor(ctx) {
    this.ctx = ctx;
    this.cdSpawn = 0;
    this.spawnados = 0;
    this.estado = 'preparando';   // 'preparando' | 'ativa' | 'chefe' | 'limpando' | 'intervalo'
    this.timer = 0;
    this.chefeAtual = null;
    this.intervaloEntreOndas = 0.9;
  }

  get onda() { return this.ctx.state.onda; }

  iniciarOnda(n) {
    const s = this.ctx.state;
    s.onda = n;
    s.inimigosMortosOnda = 0;
    s.tempoNaOnda = 0;
    s.emChefe = ONDA.ehChefe(n);
    s.inimigosNecessarios = s.emChefe ? 1 : ONDA.contagem(n);
    this.spawnados = 0;
    this.cdSpawn = 0.25;
    this.chefeAtual = null;
    this.estado = s.emChefe ? 'chefe' : 'ativa';
    if (n > s.ondaMaxima) s.ondaMaxima = n;
    if (n > s.ondaMaximaGlobal) s.ondaMaximaGlobal = n;
    bus.emit(EV.WAVE_START, { onda: n, chefe: s.emChefe, super: ONDA.ehSuperChefe(n) });
  }

  atualizar(dt) {
    const ctx = this.ctx, s = ctx.state;
    s.tempoNaOnda += dt;

    switch (this.estado) {
      case 'preparando':
        this.timer -= dt;
        if (this.timer <= 0) this.iniciarOnda(s.onda);
        break;

      case 'ativa': {
        this.cdSpawn -= dt;
        const restamParaSpawnar = s.inimigosNecessarios - this.spawnados;
        if (this.cdSpawn <= 0 && restamParaSpawnar > 0) {
          this.cdSpawn = ONDA.intervaloSpawn(s.onda);
          spawnDaOnda(s.onda, ctx);
          this.spawnados++;
        }
        if (s.inimigosMortosOnda >= s.inimigosNecessarios) this.concluirOnda();
        break;
      }

      case 'chefe': {
        if (!this.chefeAtual) {
          this.chefeAtual = spawnChefe(s.onda, ctx);
          this.cdSpawn = 3.5;
        }
        // adds durante a luta
        this.cdSpawn -= dt;
        if (this.cdSpawn <= 0) {
          this.cdSpawn = 4.5;
          const invoca = this.chefeAtual?.def?.invoca;
          if (invoca && inimigos.count < 90) spawnDaOnda(s.onda, ctx);
        }
        if (!this.chefeAtual.ativo || this.chefeAtual.morrendo > 0 || this.chefeAtual.hp.lte(0)) {
          this.concluirOnda();
        }
        break;
      }

      case 'intervalo':
        this.timer -= dt;
        if (this.timer <= 0) {
          const s2 = this.ctx.state;
          const proxima = s2.modoFarm ? s2.ondaFarm : s2.onda + 1;
          this.iniciarOnda(proxima);
        }
        break;
    }
  }

  concluirOnda() {
    const ctx = this.ctx, s = ctx.state;
    s.stats.ondasCompletas++;
    ctx.recompensaDeOnda(s.onda);
    bus.emit(EV.WAVE_CLEAR, { onda: s.onda, chefe: s.emChefe, tempo: s.tempoNaOnda });
    this.estado = 'intervalo';
    this.timer = s.emChefe ? 1.6 : this.intervaloEntreOndas;
    this.chefeAtual = null;
  }

  /** A torre caiu: recomeça a onda (com penalidade). */
  reiniciarOnda(penalidade = 1) {
    const s = this.ctx.state;
    const nova = Math.max(1, s.onda - penalidade);
    s.onda = s.modoFarm ? s.ondaFarm : nova;
    this.estado = 'preparando';
    this.timer = 1.2;
    this.chefeAtual = null;
    bus.emit(EV.WAVE_FAIL, { onda: s.onda });
  }

  /** Pula direto para uma onda (viagem rápida / farm). */
  irPara(n) {
    const s = this.ctx.state;
    inimigos.releaseAll();
    s.onda = Math.max(1, Math.min(n, s.ondaMaxima));
    this.estado = 'preparando';
    this.timer = 0.4;
  }
}
