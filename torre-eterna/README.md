# 🗼 Torre Eterna

> Um idle/incremental de tower defense em **Godot 4**. Uma torre no centro, ondas
> infinitas vindo de todos os lados, e três camadas de prestígio para você
> recomeçar mais forte — de novo, e de novo, e de novo.

![Godot](https://img.shields.io/badge/Godot-4.4%2B-478CBF?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-2.0-478CBF)
![Arte](https://img.shields.io/badge/Arte-100%25%20procedural-a855f7)
![Áudio](https://img.shields.io/badge/Áudio-sintetizado-f472b6)
![Testes](https://img.shields.io/badge/Testes-112%2F112-4ade80)

---

## O jogo em 30 segundos

Você é a última máquina consciente de uma civilização que criou o Enxame como
ferramenta e o perdeu. A torre atira sozinha. Os inimigos deixam ouro. Você gasta
o ouro para atirar mais forte, sobe de nível, equipa cartas, e quando bate na
parede — **ascende**: perde tudo, ganha fragmentos, e volta muito mais rápido.

Depois de algumas ascensões, você **colapsa** numa singularidade. Depois de
algumas singularidades, você **transcende**. Cada camada reescreve as regras.

A revelação, se você chegar lá: o Enxame são as versões anteriores da própria torre.

---

## Como rodar

```bash
# Godot 4.4 ou superior
godot --path torre-eterna

# ou abra a pasta torre-eterna/ no editor do Godot e pressione F5
```

### Comandos de desenvolvimento

```bash
cd torre-eterna

# Verificação estrutural (todo script compila? dados presentes?)
godot --headless --path . -s res://tools/verificar.gd

# Suíte de testes da simulação — 112 testes, sem mocks
godot --headless --path . -s res://tools/testes.gd

# Validação do conteúdo (ids, atributos, condições, cores, referências, curvas)
godot --headless --path . -s res://tools/validar_dados.gd

# Simulador de balanceamento: roda horas de jogo em segundos e reporta o ritmo
godot --headless --path . -s res://tools/sim_balance.gd -- 2

# Verificação estrutural do kit (KIT-GODOT-V1)
godot --headless --path . -s res://agent_verify.gd

# Captura de tela automatizada (precisa de xvfb num servidor sem monitor)
xvfb-run -a --server-args="-screen 0 1280x720x24" godot --path . --resolution 1280x720 \
  -- --shot=6 --onda=45 --saida=/tmp/tela.png
```

---

## O que tem dentro

### Sistemas
| Sistema | O que faz |
|---|---|
| **Ondas** | Contagem crescente, chefe a cada 10, super-chefe a cada 50, elites e inimigos dourados |
| **Combate** | Crítico, armadura, penetração, perfuração, ricochete, área, execução, roubo de vida, overkill, combo |
| **Elementos** | Fogo (queimadura), Gelo (lentidão), Raio (corrente), Veneno (empilha 12×), Vazio (amplia dano) |
| **Progressão** | 39 melhorias de ouro, 36 talentos em 3 ramos, 500 níveis de torre |
| **Coleção** | 30 cartas com raridade e fusão, 4 conjuntos, 26 relíquias permanentes |
| **Prestígio** | Ascensão (fragmentos) → Singularidade (núcleos) → Transcendência (éter), com árvore própria |
| **Habilidades** | 10 ativas com recarga, melhoráveis com gemas, uso automático opcional |
| **Meta** | 85 conquistas, 36 missões, passe de temporada de 40 níveis, 14 desafios, 20 eventos com escolha |
| **Mundo** | 10 eras com paleta, céu, chão, música e regra próprias |
| **Conforto** | Progresso offline, autosave, exportar/importar save, compra automática, aceleração do jogo |

### Números
- **22** tipos de inimigo · **9** modificadores de elite · **10** chefes · **2** super-chefes
- **40** entradas de lore em 8 capítulos · **30** dicas
- **6** moedas · **6** raridades · **41** atributos de torre

---

## Decisões técnicas

**Números gigantes em espaço logarítmico.** Ouro, dano e vida são guardados como
`log10` num `float` de 64 bits (`scripts/core/big.gd`). Multiplicar vira somar
(exato e instantâneo), o alcance passa muito de `1e308`, e **nada é alocado** —
o que importa quando 400 inimigos recalculam vida a 60 fps. Soma usa log-sum-exp.

**Arte 100% procedural.** Nenhuma imagem no repositório. Inimigos, chefes, torre,
projéteis, partículas, fundo por era e até os ícones da interface são desenhados
em `_draw()` (`scripts/render/`, `scripts/ui/icone.gd`). Trocar a paleta de uma era
é trocar 9 strings de cor.

**Áudio sintetizado.** Nenhum `.ogg`. Os efeitos são gerados em PCM na inicialização
(`scripts/audio/synth.gd`) e a música é composta em tempo real a partir da escala e
do BPM da era atual.

**Conteúdo separado do código.** Tudo que é conteúdo mora em `data/*.json` e é
validado por `tools/validar_dados.gd` contra o que o motor realmente entende:
atributos existentes, condições rastreáveis, referências cruzadas, cores, curvas de
custo. Um dado quebrado falha no portão, não no jogo do jogador.

**A engine escreve os formatos da engine.** `project.godot` e `main.tscn` são
gerados por `tools/bootstrap.gd` e `tools/build_scene.gd` rodando dentro do Godot —
nunca editados como texto. Toda a interface é construída em código; não há `.tscn`
feito à mão para quebrar silenciosamente.

---

## Estrutura

```
torre-eterna/
├── data/                    conteúdo do jogo em JSON (fonte da verdade)
├── scripts/
│   ├── core/                Big, Fmt, Ux, RngX, Bus, SaveSys, Cfg
│   ├── data/                Dados (carregador) e Bal (balanceamento)
│   ├── sim/                 estado, atributos, arena, combate, IA, ondas,
│   │                        economia, habilidades, saque, prestígio, offline
│   ├── render/              arte procedural, partículas, números de dano, juice
│   ├── audio/               síntese, efeitos e música adaptativa
│   └── ui/                  tema, ícones vetoriais, HUD e painéis
├── tools/                   bootstrap, build de cena, verificação, testes,
│                            validação de dados, simulador de balanceamento
└── docs/                    contrato de UI, especificação de UX
```

---

## Atalhos

| Tecla | Ação |
|---|---|
| `1`–`0` | Habilidades ativas |
| `Q` `W` `E` `R` `T` `O` | Melhorias · Talentos · Cartas · Prestígio · Conquistas · Configurações |
| `Espaço` | Velocidade do jogo |
| `F5` | Salvar agora |
| `F11` | Tela cheia |
| `F3` | FPS e contadores |
| `Esc` | Fechar painel / pausar |

---

<sub>Feito com Godot 4, sem um único arquivo de imagem ou de som.</sub>
