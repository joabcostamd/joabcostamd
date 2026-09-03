/**
 * exportar_dados.mjs — converte os módulos de dados JS (projeto de design)
 * em JSON puro consumido pelo autoload DB do Godot.
 *   node torre-eterna/tools/exportar_dados.mjs
 */
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const saida = resolve(raiz, 'torre-eterna/data');
mkdirSync(saida, { recursive: true });

/** Infinity -> -1 (ilimitado); funções e undefined são descartados. */
function limpar(v) {
  if (v === Infinity) return -1;
  if (v === -Infinity) return -1;
  if (typeof v === 'number' && !Number.isFinite(v)) return 0;
  if (typeof v === 'function' || v === undefined) return undefined;
  if (Array.isArray(v)) return v.map(limpar).filter((x) => x !== undefined);
  if (v && typeof v === 'object') {
    const o = {};
    for (const k of Object.keys(v)) {
      const c = limpar(v[k]);
      if (c !== undefined) o[k] = c;
    }
    return o;
  }
  return v;
}

const alvos = [
  ['enemies', 'game/js/data/enemies.js', (m) => ({ inimigos: m.INIMIGOS, elites: m.ELITES, chefes: m.CHEFES, superChefes: m.SUPER_CHEFES })],
  ['upgrades', 'game/js/data/upgrades.js', (m) => ({ categorias: m.CATEGORIAS, upgrades: m.UPGRADES })],
  ['talents', 'game/js/data/talents.js', (m) => ({ ramos: m.RAMOS, talentos: m.TALENTOS })],
  ['prestige', 'game/js/data/prestige.js', (m) => ({ camadas: m.CAMADAS, fragmentos: m.ARVORE_FRAGMENTOS, nucleos: m.ARVORE_NUCLEOS, eter: m.ARVORE_ETER })],
  ['abilities', 'game/js/data/abilities.js', (m) => ({ habilidades: m.HABILIDADES, nivelMax: m.NIVEL_MAX_HABILIDADE })],
  ['stats', 'game/js/data/stats.js', (m) => ({ defs: m.STAT_DEFS, grupos: m.STAT_GRUPOS })],
  ['rarities', 'game/js/data/balance.js', (m) => ({ raridades: m.RARIDADES, elementos: m.ELEMENTOS })],
  ['cards', 'game/js/data/cards.js', (m) => ({ cartas: m.CARTAS, conjuntos: m.CONJUNTOS ?? [], nivelMax: m.NIVEL_MAX_CARTA ?? 10 })],
  ['relics', 'game/js/data/relics.js', (m) => ({ reliquias: m.RELIQUIAS, passivas: m.PASSIVAS_RELIQUIA ?? {} })],
  ['achievements', 'game/js/data/achievements.js', (m) => ({ categorias: m.CATEGORIAS_CONQUISTA, conquistas: m.CONQUISTAS, pontosTotais: m.PONTOS_TOTAIS ?? 0 })],
  ['missions', 'game/js/data/missions.js', (m) => ({ diarias: m.MISSOES_DIARIAS, semanais: m.MISSOES_SEMANAIS, temporada: m.RECOMPENSAS_TEMPORADA ?? [], sequencia: m.SEQUENCIA_DIARIA ?? [] })],
  ['events', 'game/js/data/events.js', (m) => ({ eventos: m.EVENTOS })],
  ['challenges', 'game/js/data/challenges.js', (m) => ({ desafios: m.DESAFIOS, modsPadrao: m.MODS_PADRAO ?? {} })],
  ['eras', 'game/js/data/eras.js', (m) => ({ eras: m.ERAS })],
  ['lore', 'game/js/data/lore.js', (m) => ({ capitulos: m.CAPITULOS, entradas: m.ENTRADAS, dicas: m.DICAS ?? [] })],
];

let ok = 0, faltando = [];
for (const [nome, caminho, extrair] of alvos) {
  const abs = resolve(raiz, caminho);
  if (!existsSync(abs)) { faltando.push(nome); continue; }
  try {
    const mod = await import(abs);
    const dados = limpar(extrair(mod));
    writeFileSync(resolve(saida, nome + '.json'), JSON.stringify(dados, null, 1));
    const n = Object.values(dados).filter(Array.isArray).reduce((s, a) => s + a.length, 0);
    console.log(`  ${nome}.json  (${n} itens)`);
    ok++;
  } catch (e) {
    faltando.push(`${nome}: ${e.message}`);
  }
}
console.log(`\n${ok}/${alvos.length} arquivos exportados`);
if (faltando.length) console.log('pendentes:', faltando.join(' | '));
