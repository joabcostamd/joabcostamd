# Estes documentos descrevem o projeto ORIGINAL, não o jogo que existe

Os cinco arquivos desta pasta foram escritos antes do jogo mudar de motor. Eles
descrevem uma implementação em **JavaScript, Canvas 2D e WebAudio**, com
arquivos `.js`/`.mjs` e APIs de navegador. O jogo que está no repositório é
feito em **Godot 4 e GDScript**, e nenhum daqueles arquivos existe.

Ler isto como se fosse o estado atual leva a erro. É por isso que eles saíram
de `docs/` e vieram para cá: continuam valendo como registro de projeto, e não
valem como referência de implementação.

## O que ainda vale

- **A intenção de design.** Por que a Purga existe, por que o Álbum registra a
  carta ao ser vista, por que a Adaptação obriga a build a mudar. Isso não
  mudou de motor.
- **O elenco de conteúdo.** Nomes, papéis e progressão de inimigos, chefes,
  eras, relíquias e cartas. `data/*.json` é quem manda, mas a intenção está aqui.
- **O formato das curvas.** A forma das funções de custo e de recompensa.

## O que NÃO vale

- **Todo caminho de arquivo, nome de módulo e assinatura de função.** São de um
  projeto que não foi construído.
- **Os números de economia.** Foram calibrados antes de o jogo rodar. O
  balanceamento de hoje sai de `scripts/data/balance.gd` e é medido por
  `tools/sim_balance.gd`; onde os dois discordam, o código está certo e este
  texto está velho.
- **A camada de áudio e de render.** WebAudio e pilha de canvases não existem
  aqui: o som é sintetizado em PCM por `scripts/audio/`, e o desenho é
  `_draw()` em `scripts/render/`.

## Onde está a verdade sobre o jogo de hoje

| Pergunta | Arquivo |
|---|---|
| Como rodar, o que é o jogo | `README.md` |
| Regras de quem mexe no código | `AGENTS.md` |
| Como a qualidade é medida, com saída crua dos portões | `docs/QUALIDADE.md` |
| Contrato da interface | `docs/CONTRATO-UI.md` |
| O que o jogo é e por quê | `docs/GDD-MESTRE.md` |
| Números de balanceamento | `scripts/data/balance.gd` |
| Conteúdo | `data/*.json`, com o contrato em `tools/validar_dados.gd` |

Dois dos arquivos desta pasta estavam com o conteúdo trocado entre si —
`SPEC-ECONOMIA.md` continha a bíblia de arte e vice-versa. Isso foi corrigido
na mudança para cá.
