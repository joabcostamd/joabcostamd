/**
 * tower.js — a torre: mira, disparo, projéteis, orbes e defesa.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { rng } from '../core/rng.js';
import { TAU, angleTo, clamp } from '../core/util.js';
import { ARENA, projeteis, escolherAlvo, inimigos } from './arena.js';
import { aplicarDano, danoEmArea, rolarGolpe, aplicarElemento, correnteRaio } from './combat.js';
import { RAIO_TORRE } from './enemies.js';
import { COMBATE, ELEMENTOS } from '../data/balance.js';

export const MODOS_MIRA = [
  { id: 'proximo',  nome: 'Mais próximo',  nomeEn: 'Closest',   icone: '🎯' },
  { id: 'avancado', nome: 'Mais avançado', nomeEn: 'Progressed',icone: '➡️' },
  { id: 'forte',    nome: 'Mais forte',    nomeEn: 'Strongest', icone: '💪' },
  { id: 'fraco',    nome: 'Mais fraco',    nomeEn: 'Weakest',   icone: '🍃' },
  { id: 'chefe',    nome: 'Prioriza chefe',nomeEn: 'Boss first',icone: '👑' },
  { id: 'longe',    nome: 'Mais distante', nomeEn: 'Farthest',  icone: '🔭' },
];

export class Torre {
  constructor(ctx) {
    this.ctx = ctx;
    this.cdTiro = 0;
    this.anguloCanhao = -Math.PI / 2;
    this.recuo = 0;
    this.pulso = 0;
    this.orbes = [];
    this.modoMira = 'proximo';
    this.iframes = 0;
    this.cargaEspecial = 0;
    this.tempoSemDano = 0;
  }

  /* ------------------------------------------------------------ disparo */
  atualizar(dt) {
    const ctx = this.ctx, s = ctx.state, stats = ctx.stats;
    if (!s.torre.viva) {
      s.torre.tempoMorta -= dt;
      if (s.torre.tempoMorta <= 0) ctx.reviverTorre();
      return;
    }

    if (this.iframes > 0) this.iframes -= dt;
    if (this.recuo > 0) this.recuo = Math.max(0, this.recuo - dt * 7);
    this.pulso += dt;
    this.tempoSemDano += dt;

    // regeneração
    const regen = stats.getN('regen') * (ctx.parasitas > 0 ? 0 : 1);
    if (regen > 0 && s.torre.vida < s.torre.vidaMax) {
      s.torre.vida = Math.min(s.torre.vidaMax, s.torre.vida + regen * dt);
    }
    const escRegen = stats.getN('escudoRegen');
    if (escRegen > 0 && s.torre.escudo < s.torre.escudoMax && this.tempoSemDano > 2) {
      s.torre.escudo = Math.min(s.torre.escudoMax, s.torre.escudo + escRegen * dt);
    }
    // juros sobre o ouro guardado
    const juros = stats.getN('jurosOuro');
    if (juros > 0) ctx.ganharOuro(s.moedas.ouro.mulN(juros * dt), { silencioso: true, fonte: 'juros' });

    // mira
    const alcance = stats.getN('alcance');
    const alvo = escolherAlvo(ARENA.cx, ARENA.cy, alcance, this.modoMira);
    if (alvo) {
      const ang = angleTo(ARENA.cx, ARENA.cy, alvo.x, alvo.y);
      const dif = ((ang - this.anguloCanhao + Math.PI * 3) % TAU) - Math.PI;
      this.anguloCanhao += dif * Math.min(1, dt * 16);
    }

    // cadência
    const cadencia = Math.max(0.05, stats.getN('cadencia'));
    this.cdTiro -= dt;
    let tiros = 0;
    while (this.cdTiro <= 0 && tiros < 12) {
      this.cdTiro += 1 / cadencia;
      if (alvo) { this.disparar(alvo); tiros++; }
      else break;
    }
    if (this.cdTiro < 0) this.cdTiro = 0;

    this.atualizarOrbes(dt);
  }

  disparar(alvo) {
    const ctx = this.ctx, stats = ctx.stats, s = ctx.state;
    const n = Math.max(1, stats.getN('projeteis'));
    const espalhamento = n > 1 ? Math.min(0.6, 0.06 * n) : 0;
    const base = angleTo(ARENA.cx, ARENA.cy, alvo.x, alvo.y);

    for (let i = 0; i < n; i++) {
      const t = n === 1 ? 0 : (i / (n - 1) - 0.5) * 2;
      const ang = base + t * espalhamento;
      const alvoP = i === 0 ? alvo : (escolherAlvo(ARENA.cx, ARENA.cy, stats.getN('alcance'), 'proximo') || alvo);
      this._criarProjetil(ang, alvoP);
    }
    this.recuo = 1;
    s.stats.tiros++;
    bus.emit(EV.TOWER_SHOOT, { ang: this.anguloCanhao, n });
  }

  _criarProjetil(ang, alvo) {
    const ctx = this.ctx, stats = ctx.stats;
    const p = projeteis.get();
    const danoBase = stats.getD('dano').mul(stats.getN('multiplicador'));
    const { dmg, crit } = rolarGolpe(danoBase, stats, alvo);

    p.ativo = true;
    p.x = ARENA.cx + Math.cos(ang) * (RAIO_TORRE - 4);
    p.y = ARENA.cy + Math.sin(ang) * (RAIO_TORRE - 4);
    p.vel = stats.getN('velProjetil');
    p.vx = Math.cos(ang) * p.vel;
    p.vy = Math.sin(ang) * p.vel;
    p.ang = ang;
    p.dano = dmg;
    p.crit = crit;
    p.alvo = alvo;
    p.perfuracao = stats.getN('perfuracao');
    p.ricochete = stats.getN('ricochete');
    p.area = stats.getN('area');
    p.r = crit ? 6 : 4;
    p.vida = 3.5;
    p.t = 0;
    p.origem = 'torre';
    p.elemento = this._sortearElemento();
    p.cor = p.elemento ? ELEMENTOS[p.elemento].cor : (crit ? '#fde047' : '#7dd3fc');
    p.tipo = p.area > 0 ? 'morteiro' : 'bala';
    p.atingidos = (p.perfuracao > 0 || p.ricochete > 0) ? new Set() : null;
    if (crit) ctx.stats2?.criticos?.();
    return p;
  }

  _sortearElemento() {
    const stats = this.ctx.stats;
    const pesos = [
      ['fogo', stats.getN('danoFogo')],
      ['gelo', stats.getN('danoGelo')],
      ['raio', stats.getN('danoRaio')],
      ['veneno', stats.getN('danoVeneno')],
      ['vazio', stats.getN('danoVazio')],
    ].filter(([, v]) => v > 0);
    if (!pesos.length) return null;
    let total = 0;
    for (const [, v] of pesos) total += v;
    const chance = Math.min(0.95, total);
    if (rng.next() > chance) return null;
    let r = rng.next() * total;
    for (const [k, v] of pesos) { r -= v; if (r <= 0) return k; }
    return pesos[0][0];
  }

  /* ---------------------------------------------------------- projéteis */
  atualizarProjeteis(dt) {
    const ctx = this.ctx;
    const act = projeteis.active;
    for (let i = act.length - 1; i >= 0; i--) {
      const p = act[i];
      if (!p.ativo) { projeteis.releaseAt(i); continue; }
      p.t += dt;
      p.vida -= dt;
      if (p.vida <= 0) { projeteis.releaseAt(i); continue; }

      if (p.origem === 'inimigo') {
        p.x += p.vx * dt; p.y += p.vy * dt;
        const d = Math.hypot(ARENA.cx - p.x, ARENA.cy - p.y);
        if (d < RAIO_TORRE) {
          ctx.danoNaTorre(p.danoTorre || ctx.state.torre.vidaMax * 0.02, null, { projetil: true });
          projeteis.releaseAt(i);
        } else if (this._foraDaArena(p)) projeteis.releaseAt(i);
        continue;
      }

      // guiado suave em direção ao alvo
      const alvo = p.alvo;
      if (alvo && alvo.ativo && alvo.morrendo <= 0 && !(alvo.intangivel > 0)) {
        const ang = angleTo(p.x, p.y, alvo.x, alvo.y);
        const dif = ((ang - p.ang + Math.PI * 3) % TAU) - Math.PI;
        p.ang += dif * Math.min(1, dt * 12);
        p.vx = Math.cos(p.ang) * p.vel;
        p.vy = Math.sin(p.ang) * p.vel;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      if (this._foraDaArena(p)) { projeteis.releaseAt(i); continue; }

      // colisão
      const acertou = this._checarColisao(p);
      if (acertou) {
        const remover = this._impacto(p, acertou);
        if (remover) projeteis.releaseAt(i);
      }
    }
  }

  _foraDaArena(p) {
    const m = 120;
    return p.x < -m || p.y < -m || p.x > ARENA.w + m || p.y > ARENA.h + m;
  }

  _checarColisao(p) {
    const act = inimigos.active;
    for (let i = 0; i < act.length; i++) {
      const e = act[i];
      if (!e.ativo || e.morrendo > 0 || e.intangivel > 0) continue;
      if (p.atingidos && p.atingidos.has(e)) continue;
      const dx = e.x - p.x, dy = e.y - p.y;
      const rr = e.r + p.r;
      if (dx * dx + dy * dy <= rr * rr) return e;
    }
    return null;
  }

  _impacto(p, alvo) {
    const ctx = this.ctx, stats = ctx.stats;
    const opts = {
      crit: p.crit,
      penetracao: stats.getN('penetracao'),
      execucao: stats.getN('execucao'),
      roubodeVida: stats.getN('roubodeVida'),
      elemento: p.elemento,
      fonte: 'torre',
    };

    // refletor devolve dano
    if (alvo.def?.hab === 'refletir' && !p.crit) {
      ctx.danoNaTorre(p.dano.toNumber() * 0.02, alvo, { reflexo: true });
    }
    // sombra revela
    if (alvo.def?.invisivel) alvo.revelado = true;

    aplicarDano(alvo, p.dano, ctx, opts);
    if (p.elemento) aplicarElemento(alvo, p.elemento, p.dano, ctx);

    if (p.area > 0) {
      danoEmArea(p.x, p.y, p.area, p.dano.mulN(0.6), ctx, { ...opts, quedaDistancia: true, ignorar: new Set([alvo]) });
      ctx.fx?.explosao(p.x, p.y, p.area, p.cor);
    } else {
      ctx.fx?.impacto(p.x, p.y, p.ang, p.cor, p.crit);
    }

    if (p.atingidos) p.atingidos.add(alvo);

    // perfuração: segue em frente
    if (p.perfuracao > 0) {
      p.perfuracao--;
      p.dano = p.dano.mulN(0.82);
      p.alvo = escolherAlvo(p.x, p.y, 400, 'proximo', p.atingidos);
      return false;
    }
    // ricochete: procura novo alvo
    if (p.ricochete > 0) {
      const prox = escolherAlvo(p.x, p.y, 240, 'proximo', p.atingidos);
      if (prox) {
        p.ricochete--;
        p.dano = p.dano.mulN(0.75);
        p.alvo = prox;
        p.ang = angleTo(p.x, p.y, prox.x, prox.y);
        p.vx = Math.cos(p.ang) * p.vel;
        p.vy = Math.sin(p.ang) * p.vel;
        p.vida = Math.max(p.vida, 1.2);
        return false;
      }
    }
    return true;
  }

  /* --------------------------------------------------------------- orbes */
  atualizarOrbes(dt) {
    const ctx = this.ctx, stats = ctx.stats;
    const n = stats.getN('orbes');
    if (this.orbes.length !== n) {
      this.orbes.length = 0;
      for (let i = 0; i < n; i++) this.orbes.push({ ang: (i / n) * TAU, cd: rng.float(0, 0.6), raio: 78 + (i % 3) * 22 });
    }
    if (!n) return;
    const velOrb = 1.6 * stats.getN('velOrbe');
    const danoOrb = stats.getD('dano').mulN(0.45 * stats.getN('danoOrbe') * stats.getN('multiplicador'));

    for (const o of this.orbes) {
      o.ang += velOrb * dt;
      o.x = ARENA.cx + Math.cos(o.ang) * o.raio;
      o.y = ARENA.cy + Math.sin(o.ang) * o.raio;
      o.cd -= dt;
      if (o.cd <= 0) {
        const alvo = escolherAlvo(o.x, o.y, 150, 'proximo');
        if (alvo) {
          o.cd = 0.75;
          const { dmg, crit } = rolarGolpe(danoOrb, stats, alvo);
          aplicarDano(alvo, dmg, ctx, { crit, fonte: 'orbe', penetracao: stats.getN('penetracao') });
          ctx.fx?.feixe(o.x, o.y, alvo.x, alvo.y, '#a78bfa');
        }
      }
    }
  }

  /* ------------------------------------------------------------- defesa */
  levarDano(quantidade, fonte, opts = {}) {
    const ctx = this.ctx, s = ctx.state;
    if (!s.torre.viva) return 0;
    if (this.iframes > 0 && !opts.ignoraIframes) return 0;

    const armadura = ctx.stats.getN('armadura');
    let dano = quantidade * (COMBATE.ARMADURA_K / (COMBATE.ARMADURA_K + armadura));
    dano *= (ctx.modificadores?.danoTorre ?? 1);

    if (s.torre.escudo > 0) {
      const absorvido = Math.min(s.torre.escudo, dano);
      s.torre.escudo -= absorvido;
      dano -= absorvido;
    }
    if (dano > 0) {
      s.torre.vida -= dano;
      this.iframes = opts.drenar ? 0 : COMBATE.IFRAMES;
      this.tempoSemDano = 0;
    }
    bus.emit(EV.TOWER_HIT, { dano, fonte, vida: s.torre.vida, max: s.torre.vidaMax });

    if (s.torre.vida <= 0) {
      s.torre.vida = 0;
      s.torre.viva = false;
      s.torre.tempoMorta = COMBATE.RESPAWN;
      s.stats.mortes++;
      bus.emit(EV.TOWER_DEATH, {});
    }
    return dano;
  }
}
