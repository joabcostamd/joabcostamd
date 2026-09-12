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

Fase alcançada: **nenhuma** · Próximo bloco: **B0**

---

## As decisões

Uma por vez, na ordem que o grafo de `BLOCOS.md` mandar. Formato exato:

### D-001 · B0 · <título curto da decisão> 🔴

**Valor:** <o que foi decidido>
**Motivo:** <por que, em uma linha — obrigatório para fechar em 🟢>
**Trava:** <o que esta decisão destrava quando fechar>

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
