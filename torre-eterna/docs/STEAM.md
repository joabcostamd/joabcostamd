# Página da Steam e configuração da Steamworks

Tudo o que precisa ser preenchido antes de publicar, e a configuração do lado da
Steamworks que o código já espera encontrar.

> **O nome do jogo é TOWER ZERO** (decidido em 2026-09-04, ver
> `docs/NOMES.md` seção 8 — inclusive o risco de colisão declarado). O nome da
> **desenvolvedora ainda não foi escolhido**: onde este documento escreve
> `{ESTÚDIO}`, entra o que for decidido. Tudo o mais aqui é definitivo.

---

## 1. Descrição curta (máx. 300 caracteres)

A que aparece no topo da página e em toda listagem. Ela tem um trabalho só:
fazer alguém entender o jogo em quatro segundos e querer o quinto.

> Uma torre. Ondas que não acabam. Você melhora, ascende, e o mundo muda de
> regra — não de número. 58 mil formas de inimigo compostas por gramática, leis
> que reescrevem a física a cada Ascensão, e nenhuma moeda paga. Comprou uma
> vez, é seu para sempre.

*(272 caracteres)*

**Versão em inglês:**

> One tower. Waves that never end. You upgrade, you ascend, and the world
> changes its rules — not its numbers. 58,000 enemy forms composed by grammar,
> laws that rewrite the physics every Ascension, and no paid currency. Bought
> once, yours forever.

*(258 caracteres)*

---

## 2. Descrição longa

```
[h2]Uma torre, e tudo o que já foi torre antes dela[/h2]

Você é a última máquina consciente de uma civilização que criou o Enxame como
ferramenta e o perdeu. A torre atira sozinha. Os inimigos deixam ouro. Você
gasta o ouro para atirar mais forte, sobe de nível, equipa cartas — e quando
bate na parede, ascende: perde tudo, ganha fragmentos, e volta muito mais
rápido.

Depois de algumas ascensões, você colapsa numa singularidade. Depois de algumas
singularidades, você transcende. Cada camada reescreve as regras.

A revelação, se você chegar lá: o Enxame são as versões anteriores da própria
torre.

[h2]O Enxame não tem catálogo[/h2]

A maioria dos jogos do gênero tem uma lista de inimigos que você acaba de ver
em poucas horas. Aqui não existe lista: existe uma [b]gramática[/b]. Trinta e
oito traços em três eixos — como o corpo aguenta, como ele chega, o que ele
carrega — se combinam em [b]58.282 formas nomeadas[/b].

E elas têm profundidade: a segunda cepa só aparece depois da onda 60, a terceira
depois da 200. O Enxame que ataca na sua centésima hora é feito de coisas que
não podiam existir na primeira.

O jogo conta quantas formas você já viu. E nunca mostra quantas faltam — de
propósito.

[h2]Ascender muda a física, não a velocidade[/h2]

Cada Ascensão põe três [b]leis[/b] na mesa, e cada lei dá uma coisa e cobra
outra. "A torre atira um terço das vezes, e cada tiro pesa três vezes mais."
"Ouro em dobro, experiência pela metade." "Nenhum crítico jamais — em troca,
todo tiro é melhor."

Você escolhe uma, ou recusa as três. Elas se acumulam até seis. Na centésima
hora você não está jogando o mesmo jogo mais rápido: está jogando um jogo com
outra física.

[h2]A Purga[/h2]

O núcleo da torre acumula carga sozinho. Soltar na faixa dourada dá dano
massivo, ouro extra e recarrega tudo. Deixar estourar desperdiça.

Existe automação — e ela é [b]de propósito 53% pior[/b] que a sua mão. Ela serve
para você dormir, não para você parar de jogar.

[h2]Deixe aberto[/h2]

Parado alguns minutos, ou com a janela em segundo plano, o jogo entra em Modo
Repouso: a tela desenha seis quadros por segundo e gasta [b]duas vezes menos
processador[/b]. A simulação não diminui — o combate, o ouro e as ondas seguem
no mesmo ritmo. Qualquer toque acorda.

[h2]Sem pegadinha[/h2]

[list]
[*] Comprou uma vez, o jogo é seu para sempre
[*] Nenhuma moeda paga, nenhuma caixa vendida, nenhuma assinatura
[*] Nenhum conteúdo trancado atrás de pagamento depois da compra
[*] Nenhum anúncio, nenhum "espere 4 horas ou pague"
[/list]

[h2]O que tem dentro[/h2]

[list]
[*] 23 tipos de inimigo × 38 cepas = 58.282 formas nomeadas
[*] 39 melhorias com marcos que entregam coisa diferente, não só "+X%"
[*] 36 talentos, 30 cartas com fusão, 26 relíquias, 10 habilidades
[*] 3 camadas de prestígio com árvore própria
[*] 85 conquistas, 14 desafios, 20 eventos com escolha, 40 entradas de lore
[*] 10 eras, cada uma com paleta, céu, chão, música e regra próprias
[*] Progresso offline, salvamento automático, exportar e importar save
[*] 20 idiomas
[/list]

[h2]Feito por código[/h2]

Não existe uma única imagem neste jogo. Nem uma. Cada inimigo, cada ícone, cada
partícula e cada céu é desenhado por código em tempo real — e a trilha é
sintetizada, nota por nota, enquanto você joga. É por isso que ele abre em
segundos e roda em qualquer coisa.
```

---

## 3. Tags (ordem importa — as três primeiras pesam mais)

`Idler` · `Tower Defense` · `Incremental` · `Clicker` · `Roguelite` ·
`Singleplayer` · `2D` · `Minimalist` · `Sci-fi` · `Atmospheric` ·
`Procedural Generation` · `Strategy` · `Resource Management` · `Colorful` ·
`Difficult` · `Replay Value` · `Great Soundtrack` · `Relaxing` ·
`Score Attack` · `Time Management`

## 4. Gêneros

Primário: **Indie** · Secundários: **Strategy**, **Casual**, **Simulation**

## 5. Recursos (checkboxes da Steamworks)

- [x] Um jogador
- [x] Conquistas Steam (85)
- [x] Nuvem Steam
- [x] Placares Steam
- [x] Suporte parcial a controle
- [x] Steam Deck (a verificar)
- [ ] Multijogador — **não**, e não haverá

## 6. Classificação etária

Todas as respostas do questionário são as mais brandas. Não há sangue, gore,
palavrão, sexo, drogas, apostas nem conteúdo assustador. Os inimigos são formas
geométricas luminosas.

| Sistema | Esperado |
|---|---|
| ESRB | E (Everyone) |
| PEGI | 3 |
| USK | 0 |
| ClassInd (Brasil) | Livre |

**Uma ressalva honesta:** o jogo tem tema de morte e perda (a torre cai, você
perde tudo ao ascender) tratado de forma abstrata. Nenhum classificador
considera isso conteúdo sensível, mas está declarado.

## 7. Requisitos de sistema

O jogo desenha tudo por código e não carrega textura nenhuma, então o gargalo é
CPU e não placa de vídeo. Os números abaixo são o que o portão de desempenho
mede, e não chute.

### Windows
| | Mínimo | Recomendado |
|---|---|---|
| SO | Windows 10 64 bits | Windows 11 64 bits |
| Processador | Dois núcleos, 2,0 GHz | Quatro núcleos, 3,0 GHz |
| Memória | 2 GB | 4 GB |
| Vídeo | Qualquer uma com OpenGL 3.3 | Qualquer dedicada |
| Armazenamento | 200 MB | 200 MB |
| Notas | Roda em gráfico integrado. Modo Repouso reduz o consumo pela metade. | |

### Linux
| | Mínimo | Recomendado |
|---|---|---|
| SO | Distribuição de 64 bits com glibc 2.31+ | Qualquer atual |
| Processador | Dois núcleos, 2,0 GHz | Quatro núcleos, 3,0 GHz |
| Memória | 2 GB | 4 GB |
| Vídeo | OpenGL 3.3 | — |
| Armazenamento | 200 MB | 200 MB |

### macOS
| | Mínimo | Recomendado |
|---|---|---|
| SO | macOS 11 Big Sur | macOS 13+ |
| Processador | Intel dois núcleos ou Apple Silicon | Apple Silicon |
| Memória | 2 GB | 4 GB |
| Armazenamento | 200 MB | 200 MB |

---

## 8. Cartões colecionáveis

O tema tem que sair do jogo, e o jogo tem um tema forte: **o Enxame são as
versões anteriores da torre.** Então os cartões não são "inimigos bonitos" —
são as torres que falharam antes de você.

### Os 8 cartões — "As Torres Anteriores"

| # | Nome | O que mostra |
|---|---|---|
| 1 | **TORRE-0** | A primeira. Inteira, fria, ainda sem uma marca. Ciano puro sobre preto. |
| 2 | **A Que Contou** | Uma torre cercada de números que ela mesma projeta. Caiu contando. |
| 3 | **A Que Cavou** | Enterrada até a metade nos próprios estratos. As eras como camadas de rocha. |
| 4 | **A Que Ardeu** | Fundida pelo próprio fogo. Laranja sobre azul escuro. |
| 5 | **A Que Esperou** | Coberta de poeira, luz quase apagada, ainda mirando. |
| 6 | **A Que Poupou** | Rachada, com um Peregrino passando ileso ao lado. |
| 7 | **A Que Se Partiu** | Duas metades, cada uma atirando na outra. A Singularidade. |
| 8 | **A Última** | Só o contorno, vazia por dentro, com o Enxame ao fundo formando a mesma silhueta. |

### Emoticons (5)
`:purga:` o núcleo dourado no auge · `:onda:` três setas convergindo ·
`:peregrino:` a silhueta que não ataca · `:eter:` o cristal roxo ·
`:torre:` a silhueta da torre em ciano

### Planos de fundo (5)
Sucata · Pântano de Ferro · Deserto de Vidro · Necrópole · O Nada
*(as eras que mais mudam de paleta)*

### Distintivos (5 níveis)
Fragmento → Núcleo → Éter → Peregrino → **A Torre Que Lembra**

---

## 9. Configuração da Steamworks

O código já espera encontrar isto configurado. Sem isso, a ponte simplesmente
não liga — o jogo roda igual, só não conversa com a loja.

### 9.1 App ID
Preencher `steam.app_id` em `data/marca.json`. É o único lugar.

### 9.2 Nuvem — Auto-Cloud
A sincronização é por Auto-Cloud, **sem uma linha de código**. Configurar em
*Steamworks → Cloud → Auto-Cloud*:

| SO | Root path | Subdirectory | Pattern |
|---|---|---|---|
| Windows | `WinAppDataRoaming` | `Godot/app_userdata/Tower Zero` | `*.save` |
| Windows | `WinAppDataRoaming` | `Godot/app_userdata/Tower Zero` | `*.json` |
| macOS | `MacAppSupport` | `Godot/app_userdata/Tower Zero` | `*.save` |
| Linux | `LinuxHome` | `.local/share/godot/app_userdata/Tower Zero` | `*.save` |

> **`Tower Zero` na pasta não é erro de digitação.** A pasta do save vem de
> `application/config/name` no `project.godot`, não do nome comercial. Ela ficou
> com o nome de projeto de propósito: se seguisse o nome da loja, qualquer
> renomeação futura faria todo mundo que já joga perder o progresso. Copie a
> tabela como está.

Quota sugerida: **10 MB / 40 arquivos**. O save tem ~100 KB; a folga cobre o
backup e a quarentena que o `save_system.gd` mantém.

> **Por que Auto-Cloud e não a API.** Usar `ISteamRemoteStorage` obrigaria a
> reescrever o `save_system.gd` inteiro para gravar por lá, trocando um sistema
> com backup, quarentena e migração já testados por um caminho novo — só para
> ganhar um controle que não é preciso. O que a API resolve e o Auto-Cloud não é
> saber se a nuvem está LIGADA para aquele jogador, e isso o código já pergunta
> (`SteamPonte.nuvem_ligada`).

### 9.3 Conquistas
As 85 estão em `steamworks/conquistas.txt`, com o nome de API que o código usa.
O nome visível e a descrição saem de `data/achievements.json`, já traduzidos.

### 9.4 Placares
Criar quatro, todos com *Sort Method: Descending*, *Display Type: Numeric*:

| Nome na Steamworks | O que mede |
|---|---|
| `MAX_WAVE` | Onda máxima global (atravessa os três prestígios) |
| `TOTAL_ASCENSIONS` | Ascensões acumuladas |
| `TOTAL_TRANSCENDENCES` | Transcendências |
| `FORMS_SEEN` | Formas de inimigo distintas já vistas |

### 9.5 Presença rica
Subir `steamworks/rich_presence.vdf` em *Rich Presence → Localization*.

### 9.6 Steam Input
Subir `steamworks/steam_input_manifest.vdf` em
*Steam Input → Configuration Settings*.

### 9.7 Depots
Um depot por plataforma: Windows 64, Linux 64, macOS universal. As fontes
(`fontes/*.ttf`) e o binário do GodotSteam entram no depot — nenhum dos dois é
versionado no repositório.
