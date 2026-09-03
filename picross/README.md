# Revelar — um jogo de picross

Jogo completo em Godot 4.6. Você resolve o quebra-cabeça de lógica e a imagem
escondida se revela colorida, entrando na sua galeria.

![menu](capturas/menu.png)

## Abrir

```bash
godot                 # abre o editor / joga
./testar.sh           # roda a suíte inteira, sem janela
```

## O que tem dentro

- **400 fases** em 5 capítulos: 40 de 5×5, 80 de 10×10, 100 de 15×15, 100 de 20×20 e 80 de 25×25
- **14 telas e estados**: abertura, menu, capítulos, seleção de fases, jogo,
  pausa, derrota, revelação, galeria, imagem ampliada, conquistas,
  estatísticas, opções e créditos
- **21 idiomas**, com fonte que cobre todos eles
- **Tema claro e escuro**, mais duas paletas de alto contraste
- **16 conquistas** com aviso na tela, e estatísticas
- **Retoma a partida** de onde você parou, mesmo fechando o jogo
- **Mescla de salvamentos** entre aparelhos, sem perder progresso
- **Progresso salvo** em `user://progresso.save`, com estrelas e melhor tempo
- **Áudio sintetizado por código** — nenhum arquivo de som no repositório
- **Resposta em tudo**: botões que reagem ao toque, células que estalam ao
  serem pintadas, faíscas quando uma linha fecha, confete na revelação e um
  fundo com brilho e poeira em movimento

## A regra que sustenta o jogo

Todo puzzle tem **solução única alcançável por lógica pura**. Isso não é
promessa: um solucionador em Python resolve cada desenho usando só dedução,
e um desenho que ele não resolve não entra no jogo.

A mesma medição define a ordem das fases e o tempo-alvo das 3 estrelas — o
balanceamento é medido, não estimado. O relatório está em [AUDITORIA.md](AUDITORIA.md).

Sete desenhos foram corrigidos durante a produção porque o solucionador
apontou ambiguidade. O padrão era sempre o mesmo: duas células em diagonal
com as mesmas pistas, que aceitam duas leituras.

## Como jogar

| Ação | Comando |
|---|---|
| Pintar | botão esquerdo (arraste preenche em linha reta) |
| Marcar vazia | botão direito |
| Desfazer | `Z` |
| Dica | `H` — revela uma célula, abre mão das 3 estrelas |
| Pausa | `Esc` |

Errar custa uma vida; três erros encerram a partida. Quem preferir sem
pressão liga o **modo relaxado** nas opções.

## Idiomas

Interface em 21 idiomas: português, inglês, espanhol, francês, alemão,
italiano, holandês, polonês, sueco, dinamarquês, norueguês, finlandês, tcheco,
húngaro, romeno, turco, russo, ucraniano, japonês, coreano e chinês.

O texto vem de `traducoes/textos.csv`. Para acrescentar um idioma, edite
`ferramentas/idiomas.py` e rode `python3 ferramentas/gerar_traducoes.py`.

Tipografia: Nunito para alfabeto latino, cirílico e grego, com Noto Sans JP,
KR e SC como reserva. O Godot troca de fonte por glifo, então frases mistas
saem corretas. As fontes CJK foram subsetadas para os glifos que o jogo usa:
21 MB viraram 188 KB.

## Salvamento

O jogo grava em `user://progresso.save`, que é a pasta sincronizada
automaticamente por Steam Cloud e equivalentes quando o jogo é publicado com
essa opção ligada.

A parte que costuma dar errado — dois aparelhos com progressos diferentes —
está resolvida: a mescla nunca escolhe um lado inteiro, fica com o melhor
resultado **de cada fase** (mais estrelas; em empate, menor tempo). A tela de
salvamento também gera um código para levar o progresso à mão.

## Estrutura

```
ferramentas/       Python: autoria e validação dos puzzles (não entra no jogo)
dados/             puzzles.json — o conteúdo final, gerado e validado
scripts/nucleo/    regra do jogo, sem interface: Puzzle e Partida
scripts/autoload/  Catalogo, Progresso, Audio, Navegacao
scripts/ui/        Estilo, GradeJogo, ImagemPuzzle
scripts/telas/     uma classe por tela
testes/            suíte headless
```

O núcleo não conhece nós nem desenho, e por isso a suíte consegue jogar as 50
fases inteiras sem abrir janela.

## Testes

```
── auditoria dos puzzles ──
SOLUCIONADOR OK              12 testes
400 desenhos, 0 com problema
── núcleo do jogo ──
NÚCLEO OK — 82/82 testes
── fluxo das telas ──
FLUXO OK — 29/29 verificações
```

## Gravar o jogo em vídeo

O jogo sabe se jogar sozinho, do início à revelação, e o Godot grava isso:

```bash
xvfb-run -a godot --resolution 1280x720 \
  --write-movie demo.avi --fixed-fps 30 -- --demonstracao
ffmpeg -i demo.avi -c:v libx264 -crf 24 -pix_fmt yuv420p demonstracao.mp4
```

O resultado está em `capturas/demonstracao.mp4`. Com `--fixed-fps` o tempo do
jogo não depende da velocidade da gravação, então o vídeo sai no ritmo certo
mesmo levando mais tempo para ser escrito.

## Ver as telas sem monitor

```bash
CAPTURA_DESTINO=/tmp/menu.png xvfb-run -a godot --resolution 1280x720 -- --capturar menu --demo
```

As capturas de todas as telas estão em `capturas/`, e as folhas com os 200
desenhos em `capturas/arte_cap1..5.png` — geradas por
`python3 ferramentas/folha_contato.py`, que é como a arte é auditada de uma vez.

## Acrescentar uma fase

1. Desenhe em `ferramentas/arte_capN.py`, usando a prancheta:
   `t = Tela(15); t.elipse(7, 9, 5, 4); t.circulo(11, 5, 2.5)`
2. `python3 ferramentas/validar_bloco.py` — reprova se exigir chute
3. `python3 ferramentas/construir.py` — regera os dados e o relatório

A fase entra no capítulo do seu tamanho, na posição que a dificuldade medida
mandar.
