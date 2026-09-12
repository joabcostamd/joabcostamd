# Torre entre Dimensões — mapa de decisões

Data: 2026-09-12 · Régua de planejamento: v1
**Fase: planejamento. Nenhuma linha de gameplay antes deste documento fechar a fase 2.**

> Este arquivo é **o estado da entrevista**. Não existe arquivo de sessão separado: os 🔴🟡🟢
> abaixo são o ponto onde paramos, e viajam por git entre a nuvem e a máquina local.
>
> O `portao-plano.py` lê exatamente este formato. Não invente outro.

---

## Legenda

**Estado** — 🔴 ABERTA (ninguém decidiu) · 🟡 PROPOSTA (recomendação do agente, falta o martelo
do Joab) · 🟢 FECHADA (decidida, com motivo escrito)

**Origem** — 👤 o Joab decidiu · 📏 saiu de medição · 🤖 recomendação do agente que o Joab aceitou

Decisão 🟢 **precisa** de marca de origem. Sem ela o portão pergunta "quem decidiu?" e bloqueia.
Decisão 🟢 só reabre com motivo escrito.

---

## Estado geral

| Bloco | Assunto | Estado |
|---|---|---|
| B0 | Identidade | 🔴 |
| B1 | Espaço e movimento | 🔴 |
| B2 | Estrutura da partida | 🔴 |
| B3 | Ação central | 🔴 |
| B4 | Progressão na partida | 🔴 |
| B5 | Meta-progressão | 🔴 |
| B6 | Conteúdo e espaço | 🔴 |
| B7 | Oposição | 🔴 |
| B8 | Telas e fluxo | 🔴 |
| B9 | Arquitetura e dados | 🔴 |
| B10 | Apresentação | 🔴 |
| B11 | Produto | 🔴 |
| B12 | Produção de assets por IA | 🔴 |

Fase alcançada: **nenhuma** · Próximo bloco: **B0** (3 decisões fechadas, pesquisa de mercado pronta)

---

## As decisões

Uma por vez, na ordem que o grafo de `BLOCOS.md` mandar. Formato exato:

### D-001 · B0 · O defeito do gênero que este jogo ataca 🟢 👤

**Valor:** a **repetição** — cada partida precisa ser visivelmente outra.
**Motivo:** é a queixa nº 1 do gênero em várias fontes independentes (*"fica repetitivo muito
rápido, sem força narrativa"*). Atacar a passividade exigiria dar um corpo ao jogador, o que
briga com a promessa de uma torre só. Ver `PESQUISA.md` §6.
**Trava:** a ação central (B3), a progressão (B4) e o conteúdo (B6).

### D-002 · B1 · O jogador não tem corpo no mundo 🟢 👤

**Valor:** só a torre. Câmera olha a torre e o campo. O jogador **decide**, não corre.
**Motivo:** mantém a promessa do título intacta, e barateia muito animação, colisão e level
design — **não existe personagem para animar**, que é o asset 3D mais caro que há. Recusa
explícita ao caminho do Orcs Must Die.
**Trava:** a câmera (B1), a ação central (B3) e o orçamento de assets (B12).

### D-003 · B2 · Uma partida dura 10 a 15 minutos 🟢 👤

**Valor:** 10 a 15 minutos, com fim definido.
**Motivo:** faixa do *Megabonk*. Cabe em qualquer sessão, convida ao "só mais uma", e limita
quanto conteúdo precisamos produzir. Derrota custa pouco, então dificuldade alta é permitida.
**Trava:** o ritmo (B2), a progressão dentro da partida (B4) e o número de ondas (B7).

### D-005 · B0 · O modelo do jogo é o Thronefall, não o Kingdom Rush 🟢 👤

**Valor:** tower defense **3D minimalista e low-poly**, com caminho fixo. Escopo de 6 a 8 torres
com evolução e 5 a 8 mapas. **Sem personagem animado, sem herói.**

**Motivo:** três medidas sustentam isso.
1. *Thronefall*: 2 pessoas, 1 milhão de cópias, US$ 1,5 mi nos dois primeiros meses, €12,99,
   quase 19 mil análises extremamente positivas. O *Kingdom Rush* faturou mais (US$ 6,1 mi),
   mas é franquia de 15 anos com 4 sequências — e o *Bloons TD 6* já ocupa o 3D grande.
2. **Conta de asset:** um Kingdom Rush em 3D são 20-30 inimigos animados = 60 a 90 clipes.
   Personagem animado é o asset mais caro e **o pior caso para consistência de arte gerada por
   IA** — o risco nº 1 registrado na régua.
3. *"Fazer coisas pequenas é o único jeito de terminar alguma coisa com 1 a 3 pessoas."*
   — Paul Schnepf, criador do Thronefall.

**Trava:** o estilo de arte (B10), a fábrica de assets (B12), o volume de conteúdo (B6) e a
oposição (B7).

### D-004 · B0 · A leitura do tema dimensional 🔴

**Valor:** <em aberto — 5 opções apresentadas, aguardando escolha>
**Motivo:** —
**Trava:** a ação central (B3), o conteúdo (B6), a apresentação (B10) e a fábrica de assets (B12).

<!-- Copie o bloco acima para cada decisão nova. Exemplos de cabeçalho válido:
### D-014 · B1 · Câmera do jogo 🟢 👤
### D-015 · B1 · O jogador pula 🟡 🤖
### D-022 · B3 · Ganho de calor por segundo 🟢 📏
-->

---

## Está pronto quando

- [ ] todo bloco da fase alvo está 🟢 na tabela de estado geral
- [ ] toda decisão 🟢 tem **motivo escrito** e **marca de origem**
- [ ] nenhuma decisão 🟡 sobrou em bloco que trava código
- [ ] `portao-plano.py` devolve a fase esperada
