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
