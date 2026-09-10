# OVERCLOCK — direção de arte

Data: 2026-09-07

> Este documento existe porque a arte deste jogo é **decidida, não improvisada**. Nenhuma cor,
> forma ou brilho entra sem estar nesta página. Caminho de asset sai de `assets/CATALOGO.md`,
> nunca de memória.

---

## 1. A tese: neon é luz, não textura

Cyberpunk neon é o único estilo caro que **não depende de saber desenhar**. Ele depende de saber
configurar luz, material emissivo e pós-processamento — que é trabalho de engenharia, e é o que
esta dupla domina de verdade.

O raciocínio que decide tudo aqui:

| | resultado |
|---|---|
| forma **simples** + emissão + bloom + fundo escuro | parece caro |
| forma **complexa** mal texturizada | parece barato |

Por isso a regra número um: **nada neste jogo tem textura de superfície.** Cor sólida, emissão e
contorno. Uma esfera lisa que brilha vence uma esfera detalhada que não brilha, e a esfera lisa é
a que sai boa sem artista.

Isso não é uma limitação disfarçada de estilo. É o mesmo caminho que *Rez*, *Tron*, *Geometry
Wars* e a própria referência do projeto (*Shape Shifter: Formations*) escolheram de propósito.

## 2. A paleta — cinco cores, cada uma com uma função

Cor aqui **informa**, não decora. Toda cor da tela tem um trabalho, e nenhuma cor faz dois.

| papel | cor | hex | onde aparece |
|---|---|---|---|
| vazio | quase-preto azulado | `#05060E` | fundo, chão, tudo que não importa |
| **você** | ciano | `#22E9FF` | o núcleo do jogador, e só ele |
| seu dano | branco-ciano | `#B8FBFF` | seus projéteis e efeitos |
| **inimigo** | magenta | `#FF2D95` | corpo de todo inimigo |
| **o que te mata** | âmbar | `#FFB020` | projétil inimigo — e nada mais |
| calor | vermelho | `#FF3B30` | só a interface de calor e o estouro |

### A regra que salva o gênero

> **Âmbar é a única cor quente na tela, e ela significa exatamente uma coisa: isto encosta em
> você e dói.**

O defeito mais comum de bullet heaven é o jogador não conseguir ver o que o matou no meio de
mil partículas. Reservar uma faixa inteira do espectro para "perigo" resolve isso por
construção, não por polimento.

Consequência dura, que vale para todo o projeto: **nenhum efeito decorativo pode ser âmbar.**
Nem explosão, nem coleta, nem brilho de chão, nem partícula de vitória. Se um dia algo âmbar
aparecer sem machucar, a regra morreu e o jogador perde a confiança na tela inteira.

Verificação obrigatória antes de qualquer build: a paleta passa por simulação de dicromacia
(skill `acessibilidade`) — magenta contra ciano e âmbar contra ciano precisam sobreviver a
protanopia e deuteranopia. Cor que informa se prova por simulação, não por opinião.

## 3. Geometria — sólidos que se quebram

Inimigos são **sólidos geométricos** construídos por código, não modelos importados:

- classe leve: tetraedro
- média: cubo
- pesada: octaedro
- chefe: icosaedro que **se subdivide** ao perder vida, virando vários menores

A subdivisão dá duas coisas de graça: a morte fica satisfatória sem animação nenhuma, e o
jogador lê a vida do chefe pela forma dele, sem barra na tela.

O corpo é sólido na cor do time, com **contorno emissivo** e faces levemente transparentes —
o jogador vê a horda através da horda, que é obrigatório quando há trezentos inimigos.

## 4. Onde o acervo entra

O acervo de 6.160 modelos não some — muda de papel. Ele não faz personagem, faz **cidade ao
fundo**.

| camada | fonte | tratamento |
|---|---|---|
| jogador, inimigo, projétil | gerado por código | emissivo, nunca do acervo |
| props de arena (antena, torre, duto, container) | `Space Kit`, `City Kit`, `Factory Kit` (Kenney, CC0) | material original **descartado**, trocado por emissivo da paleta |
| silhueta de horizonte | `City Kit` | preto puro, sem luz, só recorte contra o céu |

Trocar o material de todo prop por um material da paleta é o passo que impede o jogo de parecer
asset flip: as peças perdem a origem e viram vocabulário do mesmo mundo. É também o que faz
pacotes diferentes casarem sem ajuste.

Som segue o mesmo caminho — acervo Kenney (`Sci-Fi Sounds`, `Digital Audio`, `Interface Sounds`,
CC0) como base, consultado pela skill `acervo-sons` antes de comprar qualquer coisa.

## 5. O chão

Plano contínuo, sem emenda e sem repetição visível — a skill `nivel-3d` mede que repetição de
textura de chão é o pior negócio de um cenário: custa peça, custa quadro e piora a leitura.

Aqui o chão é uma grade emissiva desenhada por shader, que **pulsa junto com o Clock**. É o
segundo canal de informação do calor: o jogador sente a aceleração pelo chão sem tirar o olho da
horda. Chão não projeta sombra (`cast_shadow = 0`) — ganho de quadro de graça.

Composição, pela regra medida: **chão liso, obstáculo raro.** Borda densa (moldura que diz "o
mundo acaba aqui" sem parede invisível), miolo esparso (é onde o jogo acontece), horizonte só
como silhueta. Cenário detalhado demais compete com o inimigo pela atenção, e o inimigo tem que
ganhar sempre.

## 6. O pós-processamento é metade da arte

Um único `WorldEnvironment` carrega o estilo inteiro:

- **glow/bloom** forte, com limiar alto — só o que é emissivo floresce
- **fog volumétrico** leve, azulado, para dar profundidade ao vazio
- **aberração cromática** sutil, que **cresce com o calor**
- **vinheta** que fecha conforme o núcleo aquece

Os três últimos são a mesma ideia: a tela inteira é o medidor de calor. Aos 90% de temperatura o
jogador não precisa olhar número nenhum — a imagem está gritando.

## 7. Acessibilidade não é etapa final

Vai junto desde a primeira arena, não depois:

- **modo alto contraste**: fundo puro, glow reduzido, contorno reforçado
- **redução de movimento**: desliga tremor de tela e pulso do chão (o pulso vira só variação de brilho)
- **forma além de cor**: projétil inimigo é âmbar **e** losango; nenhum outro projétil é losango.
  Quem não distingue a cor distingue a forma.
- **escala de interface** independente da resolução

## 8. Como eu provo que a arte ficou boa

Na nuvem não existe editor nem screenshot — então aqui a arte é **descrita e verificada por
portão**; o julgamento visual acontece na máquina local, com `godot-visual-check` e
`godot-playtest-loop`. Nada de afirmar que ficou bonito sem ter olhado.

Três provas obrigatórias antes de chamar qualquer arena de pronta:

1. **Quadro parado, silhuetas distinguíveis.** Legibilidade morre antes do desempenho, e nenhuma
   medida de milissegundo avisa.
2. **ms por quadro com a arena montada e a horda cheia** — nunca com a cena parada.
3. **Simulação de daltonismo** na paleta, com o resultado gravado em `AUDITORIA.md`.
