# 🗼 Torre Eterna

> Um idle/incremental de tower defense em **Godot 4**. Uma torre no centro, ondas
> infinitas vindo de todos os lados, e três camadas de prestígio para você
> recomeçar mais forte — de novo, e de novo, e de novo.

![Godot](https://img.shields.io/badge/Godot-4.7%2B-478CBF?logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-2.0-478CBF)
![Arte](https://img.shields.io/badge/Arte-100%25%20procedural-a855f7)
![Áudio](https://img.shields.io/badge/Áudio-sintetizado-f472b6)
![Testes](https://img.shields.io/badge/Testes-709%2F709-4ade80)
![Idiomas](https://img.shields.io/badge/Idiomas-PT--BR%20%C2%B7%20EN-38bdf8)

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
# Godot 4.7 ou superior
godot --path torre-eterna

# ou abra a pasta torre-eterna/ no editor do Godot e pressione F5
```

### Comandos de desenvolvimento

```bash
cd torre-eterna

# Verificação estrutural (todo script compila? dados presentes?)
godot --headless --path . -s res://tools/verificar.gd

# Suíte de testes da simulação — 709 testes, sem mocks
godot --headless --path . -s res://tools/testes.gd

# Convenções do projeto (emoji na interface, print solto, painel órfão, mídia)
godot --headless --path . -s res://tools/lint.gd

# Validação do conteúdo (ids, atributos, condições, cores, referências, curvas)
godot --headless --path . -s res://tools/validar_dados.gd

# Simulador de balanceamento: roda horas de jogo em segundos e reporta o ritmo
godot --headless --path . -s res://tools/sim_balance.gd -- 2

# Teste de resistência: horas de jogo com invariantes checadas o tempo todo
godot --headless --path . -s res://tools/soak.gd -- 3

# Estresse de desempenho: 500 inimigos, perfil por subsistema
godot --headless --path . -s res://tools/perf.gd -- 412

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

### As mecânicas que dão a cara do jogo

Duas ressalvas honestas antes da lista. Coleção que dá bônus e sacrifício que
compra multiplicador permanente são convenções velhas do gênero — o Álbum e o
Panteão são variações com torque próprio, não invenções. O que vale como raro
está dito em cada verbete.

**A Purga.** O núcleo da torre acumula carga sozinho. Soltar na faixa dourada
(92%+) dá dano massivo em tudo, ouro extra e recarrega as habilidades. Deixar
estourar desperdiça. Existe automação — e ela é **de propósito 40% pior** que a
sua mão. É a única coisa que o jogo pede de você, e a razão para voltar à tela.

**Marcos de melhoria.** Melhoria de idle costuma ser "+X%" repetido, e aí a
ordem de compra não importa: compra-se a mais barata, sempre. Aqui quinze delas
têm **marcos** — degraus que entregam uma coisa *diferente* do que a melhoria
vende. O Canhão de Plasma passa crítico e depois multiplicador global; a
Refrigeração passa um projétil a mais; o Fogo passa área; o Raio passa
ricochete. Como o ouro é finito a cada instante, **qual degrau perseguir
primeiro** é uma decisão de verdade, e o painel diz o quanto falta para o
próximo.

**Álbum de Ecos.** Bônus de coleção existe desde sempre; o torque aqui é
registrar ao **ver**, não ao guardar. Duplicata deixa de ser lixo e vira
micro-progresso, e o medo de descartar não existe — porque descartar não perde
nada. Imune a todos os prestígios.

**Adaptação do Enxame.** O mundo cria resistência ao elemento que você mais usa
(até 62%) e esquece o que você abandona. A build ótima muda sozinha; você nunca
chega ao "já resolvi, agora é só esperar".

**O Peregrino.** Um inimigo raro que não ataca ninguém: atravessa a arena e vai
embora. Matar rende 40× ouro. Poupar não rende nada — o jogo só conta, para
sempre, e usa a contagem no final.

**O Panteão.** Sacrifício por bônus permanente é rocha-mãe do gênero; o torque
é exigir um **conjunto completo**, o que transforma a decisão em "desmontar uma
build que funciona". Consagrar destrói aquelas cartas para sempre em troca de um
multiplicador eterno. É o único sistema em que você perde algo de verdade.

E ainda: **A Retomada** — fast-forward pós-prestígio é comum, mas correr contra
o fantasma da run anterior, ultrapassando-o ao vivo, é o que faz o reset deixar
de ser anticlímax. E a **Aglomeração**, uma curva de ouro por lotação: o teto de
entidades vira economia, e a tela cheia rende mais em vez de render menos.

### Números
- **23** tipos de inimigo · **9** modificadores de elite · **10** chefes · **2** super-chefes
- **40** entradas de lore em 8 capítulos · **30** dicas
- **6** moedas · **6** raridades · **39** atributos de torre
- **1.058** chaves de interface e **1.286** textos de conteúdo, em português e inglês
- **709** testes da simulação · **0** arquivo de som · a única imagem do repositório é `icon.svg`, o ícone do projeto

---

## Decisões técnicas

**Números gigantes em espaço logarítmico.** Ouro, dano e vida são guardados como
`log10` num `float` de 64 bits (`scripts/core/big.gd`). Multiplicar vira somar
(exato e instantâneo), o alcance passa muito de `1e308`, e **nada é alocado** —
o que importa quando 412 inimigos recalculam vida a 60 fps. Soma usa log-sum-exp.

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
