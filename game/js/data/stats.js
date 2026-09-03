/**
 * stats.js — catálogo canônico de atributos da torre.
 *
 * `tipo` diz como o número é exibido; `base` é o valor da torre nua.
 * Modificadores vêm de upgrades, talentos, cartas, relíquias, prestígio,
 * buffs, eras e desafios (ver sim/statengine.js).
 */
import { COMBATE } from './balance.js';

export const STAT_DEFS = {
  /* ---- ofensivo ---- */
  dano:          { base: COMBATE.DANO_BASE,        tipo: 'grande', nome: 'Dano',                nomeEn: 'Damage',            icone: '⚔️', desc: 'Dano por projétil.' },
  cadencia:      { base: COMBATE.CADENCIA_BASE,    tipo: 'taxa',   nome: 'Cadência',            nomeEn: 'Fire Rate',         icone: '🔁', desc: 'Tiros por segundo.', unidade: '/s' },
  alcance:       { base: COMBATE.ALCANCE_BASE,     tipo: 'num',    nome: 'Alcance',             nomeEn: 'Range',             icone: '🎯', desc: 'Raio de tiro da torre.' },
  critChance:    { base: COMBATE.CRIT_BASE,        tipo: 'pct',    nome: 'Chance Crítica',      nomeEn: 'Crit Chance',       icone: '💥', desc: 'Chance de acerto crítico.', max: 1 },
  critDano:      { base: COMBATE.CRIT_MULT_BASE,   tipo: 'mult',   nome: 'Dano Crítico',        nomeEn: 'Crit Damage',       icone: '✴️', desc: 'Multiplicador do acerto crítico.' },
  projeteis:     { base: 1,                        tipo: 'num',    nome: 'Projéteis',           nomeEn: 'Projectiles',       icone: '☄️', desc: 'Projéteis disparados por vez.', inteiro: true },
  perfuracao:    { base: 0,                        tipo: 'num',    nome: 'Perfuração',          nomeEn: 'Pierce',            icone: '🏹', desc: 'Inimigos atravessados por projétil.', inteiro: true },
  ricochete:     { base: 0,                        tipo: 'num',    nome: 'Ricochete',           nomeEn: 'Bounce',            icone: '🪃', desc: 'Saltos do projétil para outros alvos.', inteiro: true },
  area:          { base: 0,                        tipo: 'num',    nome: 'Área',                nomeEn: 'Splash',            icone: '💣', desc: 'Raio de dano em área no impacto.' },
  velProjetil:   { base: COMBATE.VEL_PROJETIL,     tipo: 'num',    nome: 'Velocidade do Tiro',  nomeEn: 'Projectile Speed',  icone: '⚡', desc: 'Velocidade dos projéteis.' },
  penetracao:    { base: 0,                        tipo: 'pct',    nome: 'Penetração',          nomeEn: 'Armor Pen',         icone: '🔩', desc: 'Ignora parte da armadura inimiga.', max: 0.95 },
  execucao:      { base: 0,                        tipo: 'pct',    nome: 'Execução',            nomeEn: 'Execute',           icone: '☠️', desc: 'Abate instantâneo abaixo desta % de vida.', max: 0.5 },
  danoChefe:     { base: 1,                        tipo: 'mult',   nome: 'Dano em Chefes',      nomeEn: 'Boss Damage',       icone: '👑', desc: 'Multiplicador de dano contra chefes.' },
  multiplicador: { base: 1,                        tipo: 'mult',   nome: 'Multiplicador Global',nomeEn: 'Global Multiplier', icone: '🌟', desc: 'Multiplica todo o dano da torre.' },

  /* ---- elemental ---- */
  danoFogo:      { base: 0, tipo: 'pct', nome: 'Fogo',   nomeEn: 'Fire',      icone: '🔥', desc: 'Aplica Queimadura (dano contínuo).' },
  danoGelo:      { base: 0, tipo: 'pct', nome: 'Gelo',   nomeEn: 'Ice',       icone: '❄️', desc: 'Aplica Congelamento (lentidão).' },
  danoRaio:      { base: 0, tipo: 'pct', nome: 'Raio',   nomeEn: 'Lightning', icone: '🌩️', desc: 'Corrente que salta entre inimigos.' },
  danoVeneno:    { base: 0, tipo: 'pct', nome: 'Veneno', nomeEn: 'Poison',    icone: '🧪', desc: 'Veneno empilhável de longa duração.' },
  danoVazio:     { base: 0, tipo: 'pct', nome: 'Vazio',  nomeEn: 'Void',      icone: '🕳️', desc: 'Fissura: o alvo recebe dano ampliado.' },

  /* ---- defensivo ---- */
  vidaMax:       { base: COMBATE.VIDA_BASE,  tipo: 'num',  nome: 'Vida da Torre',   nomeEn: 'Tower HP',     icone: '❤️', desc: 'Integridade estrutural da torre.' },
  regen:         { base: COMBATE.REGEN_BASE, tipo: 'taxa', nome: 'Regeneração',     nomeEn: 'Regen',        icone: '💚', desc: 'Vida recuperada por segundo.', unidade: '/s' },
  armadura:      { base: 0,                  tipo: 'num',  nome: 'Armadura',        nomeEn: 'Armor',        icone: '🛡️', desc: 'Reduz o dano recebido.' },
  escudoMax:     { base: 0,                  tipo: 'num',  nome: 'Escudo',          nomeEn: 'Shield',       icone: '🔵', desc: 'Absorve dano antes da vida.' },
  escudoRegen:   { base: 0,                  tipo: 'taxa', nome: 'Recarga Escudo',  nomeEn: 'Shield Regen', icone: '🔷', desc: 'Escudo recuperado por segundo.', unidade: '/s' },
  espinhos:      { base: 0,                  tipo: 'pct',  nome: 'Espinhos',        nomeEn: 'Thorns',       icone: '🌵', desc: 'Devolve dano a quem encosta na torre.' },
  roubodeVida:   { base: 0,                  tipo: 'pct',  nome: 'Roubo de Vida',   nomeEn: 'Lifesteal',    icone: '🩸', desc: 'Converte parte do dano em vida.', max: 1 },

  /* ---- orbes ---- */
  orbes:         { base: 0, tipo: 'num',  nome: 'Orbes',          nomeEn: 'Orbs',        icone: '🔮', desc: 'Esferas que orbitam e atacam sozinhas.', inteiro: true },
  danoOrbe:      { base: 1, tipo: 'mult', nome: 'Dano dos Orbes', nomeEn: 'Orb Damage',  icone: '🌀', desc: 'Multiplicador do dano dos orbes.' },
  velOrbe:       { base: 1, tipo: 'mult', nome: 'Órbita',         nomeEn: 'Orbit Speed', icone: '💫', desc: 'Velocidade de rotação dos orbes.' },

  /* ---- economia ---- */
  ganhoOuro:     { base: 1, tipo: 'mult', nome: 'Ganho de Ouro',       nomeEn: 'Gold Gain',     icone: '🪙', desc: 'Multiplica o ouro dos inimigos.' },
  ganhoXP:       { base: 1, tipo: 'mult', nome: 'Ganho de XP',         nomeEn: 'XP Gain',       icone: '📘', desc: 'Multiplica a experiência ganha.' },
  ganhoFrag:     { base: 1, tipo: 'mult', nome: 'Ganho de Fragmentos', nomeEn: 'Shard Gain',    icone: '💠', desc: 'Multiplica fragmentos ao ascender.' },
  chanceDrop:    { base: 1, tipo: 'mult', nome: 'Sorte de Drop',       nomeEn: 'Drop Luck',     icone: '🍀', desc: 'Multiplica a chance de cartas caírem.' },
  sorte:         { base: 1, tipo: 'mult', nome: 'Sorte',               nomeEn: 'Luck',          icone: '🎲', desc: 'Melhora raridade e eventos favoráveis.' },
  jurosOuro:     { base: 0, tipo: 'pct',  nome: 'Juros',               nomeEn: 'Interest',      icone: '🏦', desc: 'Ouro passivo por segundo (% do banco).' },

  /* ---- utilidade ---- */
  cdr:           { base: 0, tipo: 'pct',  nome: 'Redução de Recarga', nomeEn: 'Cooldown Red.', icone: '⏱️', desc: 'Reduz a recarga das habilidades.', max: 0.8 },
  duracaoHab:    { base: 1, tipo: 'mult', nome: 'Duração de Efeitos', nomeEn: 'Effect Duration', icone: '⏳', desc: 'Aumenta a duração das habilidades.' },
  coleta:        { base: 1, tipo: 'mult', nome: 'Raio de Coleta',     nomeEn: 'Pickup Radius', icone: '🧲', desc: 'Atrai o ouro caído de mais longe.' },
  velocidade:    { base: 1, tipo: 'mult', nome: 'Velocidade do Jogo', nomeEn: 'Game Speed',    icone: '⏩', desc: 'Acelera toda a simulação.' },
};

export const STAT_KEYS = Object.keys(STAT_DEFS);

/** Ordem de exibição na aba "Atributos". */
export const STAT_GRUPOS = [
  { id: 'ofensivo', nome: 'Ofensivo', nomeEn: 'Offense', chaves: ['dano', 'cadencia', 'critChance', 'critDano', 'projeteis', 'perfuracao', 'ricochete', 'area', 'penetracao', 'execucao', 'danoChefe', 'multiplicador', 'alcance', 'velProjetil'] },
  { id: 'elemental', nome: 'Elemental', nomeEn: 'Elemental', chaves: ['danoFogo', 'danoGelo', 'danoRaio', 'danoVeneno', 'danoVazio'] },
  { id: 'defensivo', nome: 'Defensivo', nomeEn: 'Defense', chaves: ['vidaMax', 'regen', 'armadura', 'escudoMax', 'escudoRegen', 'espinhos', 'roubodeVida'] },
  { id: 'orbes', nome: 'Orbes', nomeEn: 'Orbs', chaves: ['orbes', 'danoOrbe', 'velOrbe'] },
  { id: 'economia', nome: 'Economia', nomeEn: 'Economy', chaves: ['ganhoOuro', 'ganhoXP', 'ganhoFrag', 'chanceDrop', 'sorte', 'jurosOuro', 'coleta'] },
  { id: 'utilidade', nome: 'Utilidade', nomeEn: 'Utility', chaves: ['cdr', 'duracaoHab', 'velocidade'] },
];
