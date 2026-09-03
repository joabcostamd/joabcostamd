/**
 * upgrades.js — melhorias compradas com OURO (resetam na Ascensão).
 *
 * custo(n)  = base * cresc^n           (n = níveis já comprados)
 * efeito(n) = flat/pct: valor*n  |  mult: valor^n
 */
import { D } from '../core/decimal.js';

export const CATEGORIAS = [
  { id: 'ataque',    nome: 'Ataque',    nomeEn: 'Attack',  icone: '⚔️', cor: '#f87171' },
  { id: 'elemental', nome: 'Elemental', nomeEn: 'Element', icone: '🔥', cor: '#fb923c', requer: { onda: 20 } },
  { id: 'defesa',    nome: 'Defesa',    nomeEn: 'Defense', icone: '🛡️', cor: '#60a5fa' },
  { id: 'orbes',     nome: 'Orbes',     nomeEn: 'Orbs',    icone: '🔮', cor: '#a78bfa', requer: { onda: 15 } },
  { id: 'economia',  nome: 'Economia',  nomeEn: 'Economy', icone: '🪙', cor: '#fbbf24' },
  { id: 'utilidade', nome: 'Utilidade', nomeEn: 'Utility', icone: '⚙️', cor: '#34d399' },
  { id: 'forja',     nome: 'Forja',     nomeEn: 'Forge',   icone: '🌋', cor: '#f43f5e', requer: { onda: 45 } },
];

export const UPGRADES = [
  /* ---------------------------------------------------------- ATAQUE */
  { id: 'dano', cat: 'ataque', nome: 'Canhão de Plasma', nomeEn: 'Plasma Cannon', icone: '⚔️',
    desc: 'Aumenta o dano base de cada projétil.', descEn: 'Increases base projectile damage.',
    base: 12, cresc: 1.085, max: Infinity, efeito: [{ stat: 'dano', tipo: 'flat', valor: 2.4 }], destaque: true },

  { id: 'cadencia', cat: 'ataque', nome: 'Refrigeração', nomeEn: 'Coolant System', icone: '🔁',
    desc: 'Dispara mais rápido.', descEn: 'Fire faster.',
    base: 35, cresc: 1.125, max: 150, efeito: [{ stat: 'cadencia', tipo: 'pct', valor: 0.03 }], destaque: true },

  { id: 'critico', cat: 'ataque', nome: 'Mira Precisa', nomeEn: 'Precision Optics', icone: '💥',
    desc: 'Aumenta a chance de acerto crítico.', descEn: 'Increases crit chance.',
    base: 110, cresc: 1.155, max: 70, efeito: [{ stat: 'critChance', tipo: 'flat', valor: 0.0065 }] },

  { id: 'dano_critico', cat: 'ataque', nome: 'Ogiva Perfurante', nomeEn: 'Piercing Warhead', icone: '✴️',
    desc: 'Críticos causam muito mais dano.', descEn: 'Crits hit much harder.',
    base: 220, cresc: 1.145, max: 90, efeito: [{ stat: 'critDano', tipo: 'flat', valor: 0.11 }] },

  { id: 'alcance', cat: 'ataque', nome: 'Radar Estendido', nomeEn: 'Extended Radar', icone: '🎯',
    desc: 'Aumenta o alcance da torre.', descEn: 'Increases tower range.',
    base: 70, cresc: 1.135, max: 45, efeito: [{ stat: 'alcance', tipo: 'flat', valor: 11 }] },

  { id: 'vel_projetil', cat: 'ataque', nome: 'Acelerador Magnético', nomeEn: 'Magnetic Accelerator', icone: '⚡',
    desc: 'Projéteis viajam mais rápido.', descEn: 'Projectiles travel faster.',
    base: 55, cresc: 1.12, max: 35, efeito: [{ stat: 'velProjetil', tipo: 'flat', valor: 26 }] },

  { id: 'multishot', cat: 'ataque', nome: 'Bateria Múltipla', nomeEn: 'Multi Battery', icone: '☄️',
    desc: 'Dispara um projétil adicional por vez.', descEn: 'Fires an extra projectile.',
    base: 2400, cresc: 3.1, max: 14, efeito: [{ stat: 'projeteis', tipo: 'flat', valor: 1 }],
    requer: { onda: 10 }, destaque: true },

  { id: 'perfuracao', cat: 'ataque', nome: 'Núcleo Perfurante', nomeEn: 'Piercing Core', icone: '🏹',
    desc: 'Projéteis atravessam mais um inimigo.', descEn: 'Projectiles pierce one more enemy.',
    base: 1700, cresc: 2.5, max: 12, efeito: [{ stat: 'perfuracao', tipo: 'flat', valor: 1 }], requer: { onda: 12 } },

  { id: 'ricochete', cat: 'ataque', nome: 'Ricochete Balístico', nomeEn: 'Ballistic Ricochet', icone: '🪃',
    desc: 'Projéteis saltam para outro alvo.', descEn: 'Projectiles bounce to another target.',
    base: 2900, cresc: 2.8, max: 10, efeito: [{ stat: 'ricochete', tipo: 'flat', valor: 1 }], requer: { onda: 18 } },

  { id: 'area', cat: 'ataque', nome: 'Carga Explosiva', nomeEn: 'Explosive Charge', icone: '💣',
    desc: 'Impactos causam dano em área.', descEn: 'Impacts deal splash damage.',
    base: 1100, cresc: 1.26, max: 45, efeito: [{ stat: 'area', tipo: 'flat', valor: 3.2 }], requer: { onda: 14 } },

  { id: 'penetracao', cat: 'ataque', nome: 'Broca de Armadura', nomeEn: 'Armor Drill', icone: '🔩',
    desc: 'Ignora parte da armadura inimiga.', descEn: 'Ignores part of enemy armor.',
    base: 850, cresc: 1.19, max: 45, efeito: [{ stat: 'penetracao', tipo: 'flat', valor: 0.02 }], requer: { onda: 22 } },

  { id: 'execucao', cat: 'ataque', nome: 'Protocolo Execução', nomeEn: 'Execute Protocol', icone: '☠️',
    desc: 'Elimina instantaneamente inimigos muito feridos.', descEn: 'Instantly kills badly wounded enemies.',
    base: 4800, cresc: 1.3, max: 25, efeito: [{ stat: 'execucao', tipo: 'flat', valor: 0.005 }], requer: { onda: 30 } },

  { id: 'dano_chefe', cat: 'ataque', nome: 'Caça-Chefes', nomeEn: 'Boss Hunter', icone: '👑',
    desc: 'Multiplica o dano contra chefes.', descEn: 'Multiplies damage against bosses.',
    base: 3800, cresc: 1.34, max: 50, efeito: [{ stat: 'danoChefe', tipo: 'mult', valor: 1.07 }], requer: { onda: 20 } },

  /* ------------------------------------------------------- ELEMENTAL */
  { id: 'fogo', cat: 'elemental', nome: 'Combustão', nomeEn: 'Combustion', icone: '🔥',
    desc: 'Chance de aplicar Queimadura (dano contínuo).', descEn: 'Chance to apply Burn.',
    base: 5200, cresc: 1.24, max: 30, efeito: [{ stat: 'danoFogo', tipo: 'flat', valor: 0.035 }], requer: { onda: 20 } },

  { id: 'gelo', cat: 'elemental', nome: 'Criogenia', nomeEn: 'Cryogenics', icone: '❄️',
    desc: 'Chance de congelar: inimigos ficam mais lentos.', descEn: 'Chance to chill enemies.',
    base: 5200, cresc: 1.24, max: 30, efeito: [{ stat: 'danoGelo', tipo: 'flat', valor: 0.035 }], requer: { onda: 24 } },

  { id: 'raio', cat: 'elemental', nome: 'Arco Voltaico', nomeEn: 'Voltaic Arc', icone: '🌩️',
    desc: 'Chance de gerar uma corrente que salta entre inimigos.', descEn: 'Chance to chain lightning.',
    base: 6400, cresc: 1.26, max: 30, efeito: [{ stat: 'danoRaio', tipo: 'flat', valor: 0.03 }], requer: { onda: 28 } },

  { id: 'veneno', cat: 'elemental', nome: 'Toxina Corrosiva', nomeEn: 'Corrosive Toxin', icone: '🧪',
    desc: 'Chance de envenenar — empilha até 12 vezes.', descEn: 'Chance to poison; stacks to 12.',
    base: 6400, cresc: 1.26, max: 30, efeito: [{ stat: 'danoVeneno', tipo: 'flat', valor: 0.03 }], requer: { onda: 32 } },

  { id: 'vazio', cat: 'elemental', nome: 'Fissura do Vazio', nomeEn: 'Void Rift', icone: '🕳️',
    desc: 'Chance de abrir uma fissura: o alvo recebe dano ampliado.', descEn: 'Chance to open a rift.',
    base: 12000, cresc: 1.3, max: 30, efeito: [{ stat: 'danoVazio', tipo: 'flat', valor: 0.028 }], requer: { onda: 40 } },

  /* ---------------------------------------------------------- DEFESA */
  { id: 'vida', cat: 'defesa', nome: 'Blindagem Estrutural', nomeEn: 'Structural Plating', icone: '❤️',
    desc: 'Aumenta a vida máxima da torre.', descEn: 'Increases max tower HP.',
    base: 45, cresc: 1.105, max: Infinity, efeito: [{ stat: 'vidaMax', tipo: 'flat', valor: 26 }], destaque: true },

  { id: 'regen', cat: 'defesa', nome: 'Nanorreparo', nomeEn: 'Nanorepair', icone: '💚',
    desc: 'Recupera vida continuamente.', descEn: 'Continuously restores HP.',
    base: 140, cresc: 1.15, max: 70, efeito: [{ stat: 'regen', tipo: 'flat', valor: 0.65 }] },

  { id: 'armadura', cat: 'defesa', nome: 'Placas Reativas', nomeEn: 'Reactive Plates', icone: '🛡️',
    desc: 'Reduz todo o dano recebido.', descEn: 'Reduces all incoming damage.',
    base: 280, cresc: 1.165, max: 60, efeito: [{ stat: 'armadura', tipo: 'flat', valor: 4.5 }] },

  { id: 'escudo', cat: 'defesa', nome: 'Campo de Força', nomeEn: 'Force Field', icone: '🔵',
    desc: 'Escudo que absorve dano antes da vida.', descEn: 'Shield absorbs damage before HP.',
    base: 750, cresc: 1.185, max: 45, efeito: [{ stat: 'escudoMax', tipo: 'flat', valor: 45 }], requer: { onda: 16 } },

  { id: 'escudo_regen', cat: 'defesa', nome: 'Recarga do Campo', nomeEn: 'Field Recharge', icone: '🔷',
    desc: 'O escudo se recompõe mais rápido.', descEn: 'Shield recharges faster.',
    base: 1400, cresc: 1.2, max: 35, efeito: [{ stat: 'escudoRegen', tipo: 'flat', valor: 2.2 }], requer: { upgrade: 'escudo' } },

  { id: 'espinhos', cat: 'defesa', nome: 'Barreira de Espinhos', nomeEn: 'Thorn Barrier', icone: '🌵',
    desc: 'Quem encosta na torre leva dano.', descEn: 'Contact damages the attacker.',
    base: 2000, cresc: 1.22, max: 30, efeito: [{ stat: 'espinhos', tipo: 'flat', valor: 0.03 }], requer: { onda: 26 } },

  { id: 'roubo_vida', cat: 'defesa', nome: 'Conversor Vital', nomeEn: 'Vital Converter', icone: '🩸',
    desc: 'Converte parte do dano causado em vida.', descEn: 'Converts damage dealt into HP.',
    base: 3600, cresc: 1.27, max: 25, efeito: [{ stat: 'roubodeVida', tipo: 'flat', valor: 0.004 }], requer: { onda: 35 } },

  /* ----------------------------------------------------------- ORBES */
  { id: 'orbe', cat: 'orbes', nome: 'Orbe Sentinela', nomeEn: 'Sentinel Orb', icone: '🔮',
    desc: 'Adiciona um orbe que orbita e ataca sozinho.', descEn: 'Adds an auto-attacking orbiting orb.',
    base: 6500, cresc: 3.6, max: 10, efeito: [{ stat: 'orbes', tipo: 'flat', valor: 1 }], requer: { onda: 15 }, destaque: true },

  { id: 'dano_orbe', cat: 'orbes', nome: 'Foco dos Orbes', nomeEn: 'Orb Focus', icone: '🌀',
    desc: 'Aumenta o dano dos orbes.', descEn: 'Increases orb damage.',
    base: 4200, cresc: 1.28, max: 50, efeito: [{ stat: 'danoOrbe', tipo: 'mult', valor: 1.11 }], requer: { upgrade: 'orbe' } },

  { id: 'vel_orbe', cat: 'orbes', nome: 'Órbita Acelerada', nomeEn: 'Fast Orbit', icone: '💫',
    desc: 'Orbes giram (e atacam) mais rápido.', descEn: 'Orbs spin and attack faster.',
    base: 2600, cresc: 1.2, max: 30, efeito: [{ stat: 'velOrbe', tipo: 'pct', valor: 0.08 }], requer: { upgrade: 'orbe' } },

  /* -------------------------------------------------------- ECONOMIA */
  { id: 'ouro', cat: 'economia', nome: 'Refinaria', nomeEn: 'Refinery', icone: '🪙',
    desc: 'Multiplica todo o ouro obtido.', descEn: 'Multiplies all gold gained.',
    base: 90, cresc: 1.175, max: Infinity, efeito: [{ stat: 'ganhoOuro', tipo: 'mult', valor: 1.075 }], destaque: true },

  { id: 'xp', cat: 'economia', nome: 'Analisador de Combate', nomeEn: 'Combat Analyzer', icone: '📘',
    desc: 'Multiplica a experiência ganha.', descEn: 'Multiplies XP gained.',
    base: 230, cresc: 1.19, max: 70, efeito: [{ stat: 'ganhoXP', tipo: 'mult', valor: 1.07 }] },

  { id: 'ima', cat: 'economia', nome: 'Bobina Magnética', nomeEn: 'Magnetic Coil', icone: '🧲',
    desc: 'Atrai o ouro caído de mais longe.', descEn: 'Pulls dropped gold from farther.',
    base: 180, cresc: 1.16, max: 30, efeito: [{ stat: 'coleta', tipo: 'pct', valor: 0.16 }] },

  { id: 'sorte_drop', cat: 'economia', nome: 'Amuleto do Saque', nomeEn: 'Loot Charm', icone: '🍀',
    desc: 'Aumenta a chance de cartas caírem.', descEn: 'Increases card drop chance.',
    base: 1400, cresc: 1.29, max: 45, efeito: [{ stat: 'chanceDrop', tipo: 'mult', valor: 1.05 }], requer: { onda: 25 } },

  { id: 'sorte', cat: 'economia', nome: 'Dado Viciado', nomeEn: 'Loaded Dice', icone: '🎲',
    desc: 'Melhora raridades, dourados e eventos favoráveis.', descEn: 'Improves rarities and lucky events.',
    base: 8500, cresc: 1.33, max: 35, efeito: [{ stat: 'sorte', tipo: 'mult', valor: 1.045 }], requer: { onda: 38 } },

  { id: 'juros', cat: 'economia', nome: 'Cofre Rendente', nomeEn: 'Interest Vault', icone: '🏦',
    desc: 'Seu ouro guardado rende por segundo.', descEn: 'Stored gold earns interest per second.',
    base: 18000, cresc: 1.42, max: 35, efeito: [{ stat: 'jurosOuro', tipo: 'flat', valor: 0.0006 }], requer: { onda: 42 } },

  /* ------------------------------------------------------- UTILIDADE */
  { id: 'cdr', cat: 'utilidade', nome: 'Capacitor Rápido', nomeEn: 'Fast Capacitor', icone: '⏱️',
    desc: 'Reduz a recarga das habilidades.', descEn: 'Reduces ability cooldowns.',
    base: 3200, cresc: 1.23, max: 35, efeito: [{ stat: 'cdr', tipo: 'flat', valor: 0.018 }], requer: { onda: 12 } },

  { id: 'duracao', cat: 'utilidade', nome: 'Estabilizador', nomeEn: 'Stabilizer', icone: '⏳',
    desc: 'Habilidades duram mais.', descEn: 'Abilities last longer.',
    base: 4100, cresc: 1.25, max: 30, efeito: [{ stat: 'duracaoHab', tipo: 'mult', valor: 1.05 }], requer: { onda: 18 } },

  /* ------------------------------------------------------------ FORJA
     Sumidouros exponenciais do fim de jogo: caros, poderosos, infinitos. */
  { id: 'forja_dano', cat: 'forja', nome: 'Forja de Guerra', nomeEn: 'Warforge', icone: '🌋',
    desc: 'Multiplica TODO o dano da torre.', descEn: 'Multiplies ALL tower damage.',
    base: 750000, cresc: 4.6, max: Infinity, efeito: [{ stat: 'multiplicador', tipo: 'mult', valor: 1.55 }],
    requer: { onda: 45 }, destaque: true },

  { id: 'forja_ouro', cat: 'forja', nome: 'Forja de Ouro', nomeEn: 'Goldforge', icone: '💰',
    desc: 'Multiplica todo o ouro obtido.', descEn: 'Multiplies all gold gained.',
    base: 3200000, cresc: 5.4, max: Infinity, efeito: [{ stat: 'ganhoOuro', tipo: 'mult', valor: 1.45 }], requer: { onda: 50 } },

  { id: 'forja_vida', cat: 'forja', nome: 'Forja de Ferro', nomeEn: 'Ironforge', icone: '🏗️',
    desc: 'Multiplica a vida máxima e a armadura.', descEn: 'Multiplies max HP and armor.',
    base: 1600000, cresc: 5.0, max: Infinity,
    efeito: [{ stat: 'vidaMax', tipo: 'mult', valor: 1.4 }, { stat: 'armadura', tipo: 'pct', valor: 0.12 }], requer: { onda: 48 } },
];

export const UPGRADE_POR_ID = Object.fromEntries(UPGRADES.map((u) => [u.id, u]));

/** Custo do próximo nível. */
export function custoUpgrade(def, nivel) {
  return D.of(def.base).mul(D.of(def.cresc).pow(nivel));
}

/** Custo total de comprar `qtd` níveis a partir de `nivel`. */
export function custoLote(def, nivel, qtd) {
  return D.geometricSum(def.base, def.cresc, nivel, qtd);
}

/** Quantos níveis cabem no orçamento (respeita o teto). */
export function maxCompravel(def, nivel, ouro) {
  const teto = def.max === Infinity ? 1e6 : def.max - nivel;
  if (teto <= 0) return 0;
  return Math.min(teto, D.maxAffordableGeometric(ouro, def.base, def.cresc, nivel));
}

/** Requisito atendido? */
export function upgradeDisponivel(def, state) {
  const r = def.requer;
  if (!r) return true;
  if (r.onda && state.ondaMaximaGlobal < r.onda) return false;
  if (r.upgrade && !(state.upgrades[r.upgrade] > 0)) return false;
  if (r.nivel && state.nivel < r.nivel) return false;
  return true;
}

export function categoriaDisponivel(cat, state) {
  if (!cat.requer) return true;
  if (cat.requer.onda && state.ondaMaximaGlobal < cat.requer.onda) return false;
  return true;
}
