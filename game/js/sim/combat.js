/**
 * combat.js — aplicação de dano, status elementais e recompensas de abate.
 * É o coração numérico do jogo: tudo que machuca passa por aqui.
 */
import { D } from '../core/decimal.js';
import { bus, EV } from '../core/events.js';
import { COMBATE, ELEMENTOS, MULT_DOURADO } from '../data/balance.js';
import { consultarArea, escolherAlvo, coletaveis, inimigos } from './arena.js';
import { rng } from '../core/rng.js';

const _tmp = D.of(0);

/** Redução por armadura, com penetração da torre. */
export function fatorArmadura(armadura, penetracao) {
  const a = Math.max(0, armadura * (1 - Math.min(0.95, penetracao)));
  return COMBATE.ARMADURA_K / (COMBATE.ARMADURA_K + a);
}

/**
 * Aplica dano a um inimigo.
 * @returns {{morreu:boolean, dano:D, overkill:D, absorvido:boolean}}
 */
export function aplicarDano(e, dano, ctx, opts = {}) {
  if (!e.ativo || e.morrendo > 0) return { morreu: false, dano: D.of(0), overkill: D.of(0), absorvido: false };

  let dmg = dano instanceof D ? dano : D.of(dano);

  // Fissura (vazio) amplia o dano recebido
  if (e.fissura > 0) dmg = dmg.mulN(1 + e.fissuraForca);
  // Marcado por habilidade
  if (e.marcado > 0) dmg = dmg.mulN(1.5);
  // Armadura
  if (!opts.puro && e.armadura > 0) dmg = dmg.mulN(fatorArmadura(e.armadura, opts.penetracao || 0));
  // Modificador de elite "blindado"
  if (e.eliteMod === 'blindado') dmg = dmg.mulN(0.55);

  let absorvido = false;
  if (e.escudo > 0) {
    const esc = D.of(e.escudo);
    if (esc.gte(dmg)) {
      e.escudo = esc.sub(dmg).toNumber();
      absorvido = true;
      e.flash = Math.max(e.flash, 0.12);
      bus.emit(EV.ENEMY_HIT, { e, dano: dmg, crit: !!opts.crit, absorvido: true });
      return { morreu: false, dano: dmg, overkill: D.of(0), absorvido: true };
    }
    dmg = dmg.sub(esc);
    e.escudo = 0;
    absorvido = true;
  }

  // Execução: abaixo do limiar, morre na hora
  const limiar = opts.execucao || 0;
  if (limiar > 0 && !e.chefe) {
    const frac = e.hp.div(e.hpMax).toNumber();
    if (frac <= limiar) dmg = e.hp.clone();
  }

  const hpAntes = e.hp;
  e.hp = e.hp.sub(dmg);
  e.flash = Math.max(e.flash, opts.crit ? 0.2 : 0.12);
  e.hitAcc = Math.min(1, e.hitAcc + 0.35);

  const st = ctx.state.stats;
  st.danoTotal = st.danoTotal.add(dmg);
  if (dmg.gt(st.danoMaximo)) st.danoMaximo = dmg;

  // Roubo de vida
  const rv = opts.roubodeVida || 0;
  if (rv > 0 && ctx.state.torre.viva) {
    const cura = Math.min(dmg.toNumber() * rv, ctx.state.torre.vidaMax * 0.05);
    if (cura > 0) ctx.curarTorre(cura);
  }

  bus.emit(EV.ENEMY_HIT, { e, dano: dmg, crit: !!opts.crit, elemento: opts.elemento, absorvido });

  if (e.hp.lte(0)) {
    const overkill = e.hp.abs().min(hpAntes.mulN(COMBATE.OVERKILL_TETO));
    matarInimigo(e, ctx, { overkill, crit: opts.crit, fonte: opts.fonte });
    return { morreu: true, dano: dmg, overkill, absorvido };
  }
  return { morreu: false, dano: dmg, overkill: D.of(0), absorvido };
}

/** Dano em área centrado em (x,y). */
export function danoEmArea(x, y, raio, dano, ctx, opts = {}) {
  const alvos = consultarArea(x, y, raio);
  const lista = alvos.slice();     // consultarArea reusa buffer
  let mortos = 0;
  for (let i = 0; i < lista.length; i++) {
    const alvo = lista[i];
    if (opts.ignorar && opts.ignorar.has(alvo)) continue;
    const q = opts.quedaDistancia
      ? Math.max(0.35, 1 - Math.hypot(alvo.x - x, alvo.y - y) / raio)
      : 1;
    const r = aplicarDano(alvo, dano.mulN(q), ctx, opts);
    if (r.morreu) mortos++;
  }
  return { atingidos: lista.length, mortos };
}

/** Corrente de raio: salta entre alvos próximos com dano decrescente. */
export function correnteRaio(origem, dano, saltos, ctx, opts = {}) {
  const visitados = new Set([origem]);
  let atual = origem, dmg = dano;
  const pontos = [{ x: origem.x, y: origem.y }];
  for (let i = 0; i < saltos; i++) {
    const prox = escolherAlvo(atual.x, atual.y, 190, 'proximo', visitados);
    if (!prox) break;
    visitados.add(prox);
    dmg = dmg.mulN(ELEMENTOS.raio.fator + (opts.bonusCorrente || 0));
    aplicarDano(prox, dmg, ctx, { ...opts, elemento: 'raio' });
    pontos.push({ x: prox.x, y: prox.y });
    atual = prox;
  }
  if (pontos.length > 1) ctx.fx?.raio(pontos);
  return pontos.length - 1;
}

/** Aplica um status elemental de acordo com o dano do golpe. */
export function aplicarElemento(e, elemento, danoBase, ctx) {
  const def = ELEMENTOS[elemento];
  if (!def || !e.ativo) return;
  switch (elemento) {
    case 'fogo':
      e.queimadura = Math.min(def.pilhas, e.queimadura + 1);
      e.queimaduraDano = danoBase.mulN(def.dot);
      e.queimaduraT = def.duracao;
      break;
    case 'veneno':
      e.veneno = Math.min(def.pilhas, e.veneno + 1);
      e.venenoDano = danoBase.mulN(def.dot);
      e.venenoT = def.duracao;
      break;
    case 'gelo':
      e.gelo = def.duracao;
      e.geloForca = Math.min(0.75, def.lentidao * (1 + (ctx.stats.getN('danoGelo') || 0)));
      break;
    case 'vazio':
      e.fissura = def.duracao;
      e.fissuraForca = Math.min(1.2, def.ampliacao * (1 + (ctx.stats.getN('danoVazio') || 0)));
      break;
    case 'raio':
      correnteRaio(e, danoBase, def.corrente, ctx, {});
      break;
  }
}

/** Tique de status (dot, lentidão, atordoamento). */
export function atualizarStatus(dt, ctx) {
  const act = inimigos.active;
  for (let i = 0; i < act.length; i++) {
    const e = act[i];
    if (!e.ativo || e.morrendo > 0) continue;

    if (e.queimadura > 0) {
      e.queimaduraT -= dt;
      if (e.queimaduraT <= 0) e.queimadura = 0;
      else if (e.queimaduraDano) aplicarDano(e, e.queimaduraDano.mulN(e.queimadura * dt), ctx, { puro: true, fonte: 'fogo', dot: true });
    }
    if (e.veneno > 0) {
      e.venenoT -= dt;
      if (e.venenoT <= 0) e.veneno = 0;
      else if (e.venenoDano) aplicarDano(e, e.venenoDano.mulN(e.veneno * dt), ctx, { puro: true, fonte: 'veneno', dot: true });
    }
    if (e.gelo > 0) e.gelo -= dt;
    if (e.fissura > 0) e.fissura -= dt;
    if (e.atordoado > 0) e.atordoado -= dt;
    if (e.marcado > 0) e.marcado -= dt;
    if (e.flash > 0) e.flash -= dt * 4;
    if (e.hitAcc > 0) e.hitAcc -= dt * 2.5;
  }
}

/** Mata o inimigo e distribui recompensas. */
export function matarInimigo(e, ctx, info = {}) {
  if (e.morrendo > 0) return;
  e.morrendo = 0.28;
  e.hp = D.of(0);

  const s = ctx.state;
  s.stats.inimigosMortos++;
  s.stats.porInimigo[e.tipo] = (s.stats.porInimigo[e.tipo] || 0) + 1;
  s.codex.inimigos[e.tipo] = (s.codex.inimigos[e.tipo] || 0) + 1;
  if (e.chefe) { s.stats.chefesMortos++; s.codex.chefes[e.tipo] = (s.codex.chefes[e.tipo] || 0) + 1; }
  if (e.dourado) s.stats.douradosAbatidos++;

  // combo
  s.combo.atual = Math.min(COMBATE.COMBO_TETO, s.combo.atual + 1);
  s.combo.timer = COMBATE.COMBO_JANELA;
  if (s.combo.atual > s.combo.melhor) s.combo.melhor = s.combo.atual;
  if (s.combo.atual > s.stats.comboMaximo) s.stats.comboMaximo = s.combo.atual;
  bus.emit(EV.COMBO, { valor: s.combo.atual });

  // ouro (com combo e overkill)
  const bonusCombo = 1 + s.combo.atual * COMBATE.COMBO_BONUS_POR;
  let ouro = e.ouro.mulN(bonusCombo);
  if (info.overkill && !info.overkill.isZero()) {
    const frac = Math.min(COMBATE.OVERKILL_TETO, info.overkill.div(e.hpMax).toNumber());
    ouro = ouro.mulN(1 + frac);
    if (frac > 0.25) bus.emit(EV.OVERKILL, { e, frac });
  }
  ctx.soltarOuro(e, ouro);
  ctx.ganharXP(e.xp);

  s.inimigosMortosOnda++;
  bus.emit(EV.ENEMY_KILL, { e, ouro, chefe: e.chefe, dourado: e.dourado, elite: e.elite, crit: info.crit });
  if (e.chefe) bus.emit(EV.BOSS_KILL, { e });

  // divisor: gera filhotes
  if (e.def?.divide && !e.dividido) ctx.dividirInimigo(e);
}

/** Ouro que o inimigo dourado dropa é multiplicado. */
export const bonusDourado = MULT_DOURADO.ouro;

/** Rola crítico e devolve o dano final do golpe. */
export function rolarGolpe(danoBase, stats, alvo) {
  const chance = stats.getN('critChance');
  const crit = rng.next() < chance;
  let dmg = danoBase;
  if (crit) dmg = dmg.mulN(stats.getN('critDano'));
  if (alvo?.chefe) dmg = dmg.mulN(stats.getN('danoChefe'));
  return { dmg, crit };
}
