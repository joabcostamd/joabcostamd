# Picross 3D e Voxelgram — o que copiar, o que consertar

Pesquisa feita em 2026-09-05. Fontes no fim.

## Os dois jogos que importam

| | **Picross 3D** (DS, 2009) | **Picross 3D: Round 2** (3DS, 2015) | **Voxelgram** (Switch/PC, 2020) |
|---|---|---|---|
| Fases | ~370 | ~300 | 170 + procedurais |
| Cores | não | **sim — azul e laranja** | não |
| Coleção | **dioramas temáticos** | só a lista | só a lista |
| Erros | 5 | 5 | sem punição |
| Recepção | 84 Metacritic | 82 Metacritic | 98% positivo no Steam |

## A regra, exata

**O número na ponta da fileira** diz quantos cubos daquela fileira fazem parte
da figura. O símbolo diz como estão distribuídos:

| Marca | Significa |
|---|---|
| `7` | os cubos estão todos **juntos** |
| `④` círculo | estão em **dois** grupos |
| `⑤` quadrado | estão em **três ou mais** grupos |

É exatamente o que a nossa maquete já faz.

### A adição do Round 2: duas cores

O Round 2 acrescentou **dois tipos de bloco pintáveis**:

- **azul** — vira cubo reto
- **laranja** — vira bloco **curvo ou chanfrado**

Isso permite forma arredondada sem gastar mais voxel. Fileiras com os dois tipos
mostram **número duplo**. Errar a cor é punido igual a quebrar errado.

**Veredito honesto:** é engenhoso, mas **dobra a carga de regra** — o jogador
passa a decidir "fica ou sai" E "de que cor". Ganho de detalhe visual, custo de
clareza. Recomendo deixar para uma segunda leva de fases, não para o começo.

---

## O que copiar sem pensar duas vezes

**1. Três estrelas medidas, não sentidas.**
1 estrela = terminou. 2 = sem errar. 3 = sem errar dentro do tempo verde.
Estrela destrava fase bônus. Simples, e o tempo-alvo sai de medição — igual ao
que o Picross 2D já faz aqui.

**2. A bomba do zero.**
No primeiro jogo, apagar fileiras com pista `0` à mão era tedioso — a crítica
apareceu nas resenhas. O Round 2 pôs um botão que **limpa todos os zeros de uma
vez**. Custa nada implementar e remove o único trecho chato do gênero.

**3. Fases especiais entre os capítulos.**
O primeiro jogo tinha três tipos, e eles quebram a monotonia:
- **Uma Chance** — um erro e acabou
- **Contra o Relógio** — quebrar rápido estende o tempo
- **Construção** — várias fases montam **uma figura gigante**

A terceira é a melhor ideia dos dois jogos e quase ninguém copiou.

**4. A ferramenta de destaque (marcar sem punir).**
O Round 2 deixa "pintar sem compromisso" quando você não tem certeza. É o
equivalente do `X` no picross 2D e é indispensável.

---

## O que consertar — as brechas reais

**1. A punição é dura demais para um controle impreciso.**
A crítica mais repetida do Round 2: *"o jogo é mesquinho com erros, e cutucar o
cubo errado por acidente estraga uma partida inteira"*. O problema não é a
regra, é a mira. Em 3D, o cubo que você quer está atrás de outro.

→ **Nossa correção:** confirmação por gesto (arrastar para quebrar, tocar para
marcar), e **desfazer que custa estrela, não vida**. O erro vira preço, não
castigo.

**2. O Round 2 tirou os dioramas e as resenhas sentiram falta.**
Textual: *"não há nada para quebrar o ritmo, como os dioramas faziam no primeiro
jogo"*. O primeiro jogo dava uma **animação curta** ao terminar e guardava a
figura numa **coleção temática**, incentivando fechar a coleção.

→ **Isso valida a sua ideia dos ambientes.** Não é enfeite: é a peça de retenção
que o próprio Nintendo tirou e foi cobrado por isso.

**3. Nenhum dos três explica a dificuldade.**
Você não sabe por que a fase 40 é mais difícil que a 39. É opaco.

→ **Nossa correção:** a dificuldade sai do solucionador (abaixo), então dá para
mostrar ao jogador **qual técnica** a fase exige.

**4. Voxelgram é bonito e sem alma.**
98% positivo no Steam, mas as resenhas dizem "escultura satisfatória" e param
aí. Sem coleção, sem ambiente, sem recompensa além do modelo. É a prova de que
**o puzzle sozinho segura a nota, mas não segura o jogador**.

---

## O gerador de figuras: como fazer certo

### A regra de legibilidade (pesquisada, não chutada)

O que a literatura de voxel/pixel art de baixa resolução diz:

- **A silhueta é tudo.** Se não dá para reconhecer só pelo contorno, simplifique.
- **Apêndice fino some.** Nada com menos de 1 cubo de espessura; 2 é mais seguro.
- **3 a 4 cores no máximo** por figura. Cor limpa e viva, sem degradê.
- **Um objeto só.** Par só quando o par É o conceito (xícara + pires).
- **Uma característica definidora.** O que faz a coisa ser ela.

Nossa própria medição confirmou: o gato falhou porque corpo e cabeça tinham
larguras parecidas e fundiram. O cogumelo funcionou porque chapéu largo sobre pé
fino **é** a silhueta.

### O pipeline, ao contrário do que parece

O erro seria gerar figura e torcer para ser resolvível. A ordem certa:

```
1. figura  ->  2. calcula as pistas  ->  3. SOLUCIONADOR DE LINHA
                                              |
                     resolve sem chutar? ------+------ não resolve?
                             |                              |
                    4. mede o esforço                 descarta, ou
                       = a dificuldade                 abre 1 cubo de dica
                             |
                    5. entra no jogo, no nível medido
```

**Por que solucionador de linha e não força bruta:** decidir se um nonograma tem
solução única é **NP-difícil** — provado. Mas isso não importa, porque a pergunta
certa não é "é único?", e sim **"um humano resolve isso por dedução pura?"**.

Um solucionador que só propaga restrição linha a linha, **sem chutar nunca**,
responde exatamente essa pergunta. Se ele resolve, o jogador resolve. Se ele
empaca, a fase exigiria chute — e fase que exige chute é fase quebrada.

É o mesmo princípio do solucionador do Picross 2D que já está neste repositório,
com um eixo a mais.

### A dificuldade vira número

Enquanto o solucionador roda, ele conta:

| Medida | O que significa |
|---|---|
| passadas de propagação | quantas voltas até fechar |
| **dedução mais difícil usada** | a técnica exigida (fileira cheia, fileira vazia, cruzamento, sobreposição) |
| voxels resolvidos por passada | quanto o jogador avança de cada vez |
| momento do gargalo | onde a fase trava |

Ordenar as fases por isso **é** a curva de dificuldade — medida, não sentida.
Regra 4 do repositório.

### Como as figuras nascem

Três fontes, na ordem de custo:

1. **Sólidos paramétricos** — cogumelo, xícara, cacto, chave, peixe: cada um é
   uma função com 3 a 6 parâmetros. Uma família inteira sai de números.
2. **Voxelização de forma 2D extrudada** — pega a silhueta 2D (que você já sabe
   desenhar, tem 400 no Picross) e dá volume.
3. **Curadoria manual** para as figuras-assinatura de cada ambiente.

O portão é sempre o mesmo: **silhueta legível + resolvível sem chute**, senão
não entra.

---

## Os ambientes — a sua ideia, refinada

O primeiro Picross 3D provou que funciona e o segundo provou, pela ausência, que
faz falta. Como fazer melhor que os dois:

**1. O ambiente nasce vazio e visível.**
Você vê a doca deserta desde o começo, com **silhuetas fantasmas** nos lugares
onde as peças que faltam vão entrar. Isso é o gancho: você sabe o que falta e
onde vai.

**2. A peça sabe onde mora.**
Cada figura tem uma posição no seu ambiente. Terminar não é ganhar um item na
lista — é **ver a cena ganhar aquilo**.

**3. O ambiente ganha vida em camadas.**
Nada de "cena completa/incompleta". A cada peça, o ambiente muda de estado:
o porto ganha um barco, depois a gaivota, depois a neblina, depois o farol
acende. É recompensa contínua, não binária.

**4. A última peça é grande.**
Fase de Construção (a ideia órfã do primeiro jogo): três ou quatro puzzles que
montam **uma peça gigante** — o navio, a árvore central, o farol. É o clímax de
cada ambiente.

**5. O pó não some.**
Ideia nossa: os cubos que você quebra viram **material**. Material compra dica,
ou desbloqueia decoração livre no ambiente. Assim o ato de destruir alimenta o
ato de construir — e os dois lados do jogo se conversam.

Ambientes que se desenham bem por código, na ordem: **doca**, **estufa**,
**cozinha**, **observatório**, **oficina**, **jardim de inverno**.

---

## O que fazer agora, em ordem

1. **Solucionador 3D de linha** — sem ele, tudo o mais é chute. Mede resolubilidade
   e dificuldade de uma vez.
2. **Gerador paramétrico de figuras** + portão de legibilidade e de dedução.
3. **Medir**: gerar 200 figuras, ver quantas passam, e como a dificuldade se
   distribui. Esse número decide se o jogo é viável.
4. Só então: Godot.

O passo 3 é o que responde "esse jogo existe?" antes de qualquer linha de engine.

---

## Fontes

- [Picross 3D — Wikipedia](https://en.wikipedia.org/wiki/Picross_3D)
- [Picross 3D: Round 2 — Wikipedia](https://en.wikipedia.org/wiki/Picross_3D:_Round_2)
- [Picross 3D — Picross Wiki](https://picross.fandom.com/wiki/Picross_3D)
- [Picross 3D Round 2 — Nintendo Life](https://www.nintendolife.com/reviews/3ds/picross_3d_round_2)
- [Picross 3D Round 2 — Shacknews](https://www.shacknews.com/article/96924/picross-3d-round-2-review-chip-off-the-old-block)
- [Picross 3D Round 2 — Destructoid](https://www.destructoid.com/reviews/review-picross-3d-round-2/)
- [Picross 3D Round 2 — OpenCritic](https://opencritic.com/game/3257/picross-3d-round-2/reviews)
- [Voxelgram — Nintendo World Report](http://www.nintendoworldreport.com/review/53009/voxelgram-switch-review)
- [Voxelgram — Switch Player](https://switchplayer.net/2020/04/12/voxelgram-review/)
- [Complexity and solvability of Nonogram puzzles (tese, Groningen)](https://fse.studenttheses.ub.rug.nl/15287/1/Master_Educatie_2017_RAOosterman.pdf)
- [Nonny — solucionador que verifica resolubilidade linha a linha](https://github.com/gkikola/nonny)
- [voxel-icon — diretrizes de legibilidade em voxel](https://github.com/BIAsia/voxel-icon/blob/main/skill/voxel-icon/SKILL.md)
