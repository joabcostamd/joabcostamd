# Kit Puzzle — motor de puzzle de grade com gerador e solucionador

Base reaproveitável para produzir jogos de puzzle em série. O ponto não é o
Sokoban em si: é a **máquina de fabricar níveis validados**.

## Por que isso acelera a produção

O jogo tem três peças independentes, e as três rodam sem abrir janela:

| Peça | O que faz |
|---|---|
| `Tabuleiro` | A regra do jogo, em estado puro — sem nós, sem desenho |
| `Solucionador` | Busca em largura: acha a **menor** solução, ou prova que não existe |
| `Gerador` | Sorteia níveis e só entrega os que o solucionador resolveu |

Como o solucionador existe, o gerador nunca produz um nível impossível — e
já sabe de antemão em quantos movimentos ele é resolvível. Ou seja: **níveis
infinitos, todos jogáveis, com dificuldade medida em vez de chutada.**

O mesmo solucionador vira o botão de dica dentro do jogo (tecla `H`): ele
resolve o estado atual na hora, então a dica sempre funciona, inclusive num
nível gerado agora que ninguém jogou antes.

## Rodar

```bash
godot                # jogar
./testar.sh          # 16 testes, sem tela nenhuma
godot --headless --script res://tests/dump.gd   # imprime níveis em texto
```

Teclas: **setas** mover · **Z** desfazer · **R** reiniciar · **N** outro nível · **H** dica

## Estado dos testes

```
  [ok]    anda para espaço livre
  [ok]    não atravessa parede
  [ok]    empurra a caixa
  [ok]    não empurra caixa contra parede
  [ok]    não empurra duas caixas juntas
  [ok]    não declara vitória com caixa fora do alvo
  [ok]    declara vitória com tudo no lugar
  [ok]    acha a solução mais curta (2 empurrões)
  [ok]    a solução realmente resolve o nível
  [ok]    prova que nível travado não tem solução
  [ok]    detecta caixa morta no canto
  [ok]    gera um nível a partir da semente
  [ok]    o nível gerado tem solução conhecida
  [ok]    o nível gerado não nasce resolvido
  [ok]    a mesma semente gera o mesmo nível
  [ok]    lote de 12 níveis: todos jogáveis (12 validados, média de 17 passos)
TODOS OS TESTES PASSARAM (16/16)
```

O último teste é o que mais importa: ele gera um lote de níveis, resolve
cada um e confirma que a solução realmente leva à vitória. É a prova de que
a linha de produção funciona.

## Trocar de jogo mantendo a máquina

`Tabuleiro` é a única peça que conhece a regra. Reescreva o `mover()` e você
tem outro puzzle — deslizar blocos, tubos, cores — herdando de graça o
solucionador, o gerador, as dicas e os testes.
