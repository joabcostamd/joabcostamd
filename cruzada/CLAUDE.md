# PLACARD — como se trabalha neste repositório

## O jogo em uma frase

Cada carta pontua em **duas** mãos de pôquer: a fileira e a coluna onde você a
colocar. Grade 5×5, 12 linhas vivas (5 fileiras, 5 colunas, 2 diagonais).

## Duas palavras que se confundem

| Palavra | O que é | Muda? |
|---|---|---|
| **PLACARD** | o nome do **jogo** | é o título, em `Marca.NOME` |
| **CRUZADA** | o nome da **jogada** — colher fileira e coluna de uma vez | **fica** |

`CRUZADA DO CENTRO`, `GEO_CRUZADA_SO_DIFERENTES` e a DICA chamada CRUZADA são a
jogada, não sobra do nome antigo. Não "conserte".

## Regra antes de código

`cruzada/DESIGN.md` é **normativo**, não descritivo. As regras têm número (R01 a
R46) e o código as cita. Mudou o comportamento? Muda a regra primeiro, no
DESIGN, e só depois o `.gd`. Se código e DESIGN discordam, o DESIGN está certo e
o código tem bug.

A fórmula do evento é a que mais dói errar:

    fichas_da_linha = fichas_base_da_categoria + soma_das_fichas_das_5_cartas
                    + piso_do_padrão_parcial (só em mão fraca)
    fator = (Σ multiplicadores de TODAS as mãos colhidas no evento) × Tear
    pontos_da_linha  = piso(fichas_da_linha × fator)  × 0,60 se diagonal
    pontos_do_evento = Σ pontos_das_linhas

O fator é **um só, compartilhado por todas as linhas do evento**. Se cada linha
usasse o próprio multiplicador, colher duas juntas pagaria igual a colher
separado, e a Janela da Colheita perderia a razão de existir. Há teste para isso.

## O que não entra

- **Só GDScript.** Nada de C#, nada de plugin, nada de asset store.
- **Nenhum binário.** Toda a arte é desenhada por código e todo o som é
  sintetizado em tempo real. Não há um `.png` nem um `.wav` de conteúdo no
  repositório — as imagens em `capturas-do-jogo/` são saída de ferramenta.
- **Nenhuma cor literal fora dos tokens de `Temas`.** A exceção documentada é
  `maquete/folha.gd`, que é ferramenta e precisa de fundo neutro fixo.

## Estilo

Indentação de **4 espaços**. Tipagem estática sempre (`var x: int := 0`).
Nomes em português. Comentário de documentação com `##`, e ele explica **por
que**, não o que — o que já está no código.

## Sempre rode a suíte

    cd cruzada && ./testar.sh

522 asserções + aferição + tipografia + layout + contraste. Nada entra vermelho.
Sem Godot no PATH ela cai em modo degradado e roda só os validadores Python —
o que **não** é suficiente para commitar.

## Três armadilhas de Godot headless que já custaram horas

1. **Teste de tela tem que rodar como cena**, não como script:
   `godot --headless res://testes/fluxo.tscn`. Com `--script`, o `_ready` nunca
   dispara porque o laço principal não começou, e o teste "passa" sem testar.
2. **Renderizar exige tela de verdade**: use `xvfb-run -a godot ...` **sem**
   `--headless`. Em headless o `RenderingServer.frame_post_draw` nunca dispara e
   a ferramenta trava para sempre esperando um quadro que não vem. O TextServer
   também mede texto como zero sem tela, então a validação de tipografia mente.
3. **Toda ferramenta precisa de `get_tree().quit()`** no fim. Sem isso ela fica
   viva depois de terminar, segurando a saída no buffer.

## Onde está o quê

| Pasta | O que é |
|---|---|
| `cruzada/scripts/nucleo/` | o jogo **sem uma linha de interface**. Roda no terminal |
| `cruzada/scripts/ui/` | as telas, o som sintetizado, o juice |
| `cruzada/testes/` | 522 asserções |
| `cruzada/ferramentas/` | aferição, calibração, capturas, validadores |
| `cruzada/maquete/` | a maquete que decidiu o visual antes da primeira regra |
| `cruzada-pesquisa/` | as medições. **`DECISOES.md` é o livro-razão** |

## Antes de propor mudança de balanceamento

Leia `cruzada-pesquisa/DECISOES.md`. Ele tem uma seção inteira de **dials que são
código morto** — parâmetros já provados inertes por medição. Aumentar o prêmio da
cruzada, por exemplo, foi testado em 4×, 20× e 100× e não moveu nada. §7 lista o
que está em aberto, com número.

## O MCP Godot

`.mcp.json` aponta para o servidor de <https://github.com/joabcostamd/mcp-godot-desenvolvimento>.
Clone-o ao lado deste repositório, ou aponte `MCP_GODOT_DIR` para onde ele estiver.

---

# IA dentro do editor: o Godot AI

<https://github.com/hi-godot/godot-ai> — MIT, Godot 4.7+, compatível com o
nosso 4.7.2. É um servidor MCP que liga o Claude Code a um **editor Godot
vivo**. O que ele acrescenta a este projeto, em ordem de valor:

| Ferramenta | Por que importa aqui |
|---|---|
| `editor_screenshot(source="game")` | captura o **framebuffer do jogo rodando**. Hoje nossas capturas saem de SubViewport com estado fixo: elas mostram uma pose, não uma partida. Isto vê o jogo de verdade, com animação e juice acontecendo |
| `logs_read(source="editor")` | erros de parse do GDScript, `push_error`, avisos de recarga e as linhas vermelhas da aba Errors do Debugger. Hoje só enxergamos erro quando uma rodada headless imprime |
| `project_run` | roda e detecta o erro de parse que **congela o jogo antes de qualquer log sair** — a classe de falha que nenhum teste nosso pega |

As outras ~43 ferramentas editam nós, materiais, partículas e animação. **Para
nós elas quase não servem**: o PLACARD tem 7 cenas praticamente vazias e desenha
tudo em `_draw()`. Não force o uso delas aqui.

## Isto NÃO viola a regra "nada de plugin"

A regra de que não entra plugin vale para o **jogo**: nada de dependência que o
jogador precise ter, nada de asset store no produto. O Godot AI é **ferramenta
de desenvolvimento**, fica em `addons/` que está no `.gitignore`, e não é
carregado por nenhuma cena do jogo. Não o remova achando que é sujeira.

## Instalar

1. `uv` instalado (o servidor roda por `uvx`)
2. Baixe uma **release publicada** e ponha o add-on em `cruzada/addons/godot_ai/`,
   com o `plugin.cfg` dentro dessa pasta. **Não copie um snapshot do código-fonte
   do repositório** — a documentação deles é explícita nisso
3. No Godot: *Project → Project Settings → Plugins → Godot AI*
4. No dock do Godot AI, botão **Configure** ao lado de Claude Code

**Não escreva a entrada do `.mcp.json` na mão.** A v4 fala `godot-ai attach` por
stdio e o comando gerado pelo dock carrega versão, portas, resolvedor e domínios
de ferramenta excluídos. Uma URL crua tipo `http://127.0.0.1:8000/mcp` não
autentica — está na documentação deles.

## O limite honesto

Ele precisa de um **editor Godot vivo**. Na nuvem headless isso não existe de
graça: o valor dele é na sua máquina, com o editor aberto. Nossa suíte
(`./testar.sh`) continua sendo o que roda em qualquer lugar, sem editor e sem
rede.

## Duas lições que vieram de lá e valem aqui

1. **Espere sinal determinístico, nunca tempo.** Eles têm `game_capture_ready`,
   que vira verdadeiro só quando o jogo avisa que está pronto — em vez de dormir
   e torcer. É a mesma armadilha da seção de Godot headless acima: quem espera
   por tempo ou trava para sempre, ou mede cedo demais e mente.
2. **Teste que finge o motor não verifica o motor.** A frase deles é "mocks de
   Python não pegam bug de GDScript; um pytest verde não é uma mudança
   verificada". A nossa versão: 522 asserções verdes não provam que a tela está
   legível — por isso existem os validadores de contraste, tipografia e layout,
   e por isso as capturas são olhadas.
