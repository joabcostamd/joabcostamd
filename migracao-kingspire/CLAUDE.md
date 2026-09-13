# Como trabalhar neste repositório

Este repositório é **um jogo só**: o **Kingspire**. Tower defense 3D entre dimensões,
em Godot 4.7.2.

## ⚠️ Leia primeiro: `PREFERENCIAS-DE-JOAB.md`

**Antes de qualquer coisa, leia [`PREFERENCIAS-DE-JOAB.md`](PREFERENCIAS-DE-JOAB.md).**
Ele manda em como falar, como trabalhar, como testar e como entregar — e vale em toda sessão,
sem ninguém pedir. Em caso de conflito, ele ganha deste arquivo.

O resumo: português simples, direto ao ponto, construir > explicar. Teste rápido e automático.
Travou em loop, para e reporta. **Toda fatia sai polida na mesma passada.** Toda resposta
termina com 3 opções clicáveis.

---

## 1. Em que pé o jogo está

Na fase de **plano**. Nenhuma linha de GDScript ainda, e isso é de propósito.

```bash
./testar.sh
```

Esse comando é a única prova que conta. Ele roda três coisas:

1. **os testes do próprio portão** — um portão que ninguém testa mente
2. **o portão do plano** sobre os documentos deste jogo
3. **o validador do gerador de mapa** do protótipo

O portão do plano imprime um bloco delimitado. **Esse bloco é a fonte de verdade**, não o
exit code:

```
===PLANO-VERIFY===
{ "fase_alcancada": 1, "decisoes": { "abertas": 1, "propostas": 0, "fechadas": 17 }, ... }
===FIM-PLANO-VERIFY===
```

**Nunca diga "está pronto" sem ler esse bloco na tela.**

---

## 2. As decisões

Tudo o que já foi decidido mora em [`docs/PLANO.md`](docs/PLANO.md), uma decisão por bloco,
com três estados e uma marca de origem:

| Estado | Significa |
|---|---|
| 🔴 ABERTA | ninguém decidiu ainda |
| 🟡 PROPOSTA | o agente sugeriu, o Joab **não confirmou** |
| 🟢 FECHADA | decidido, com motivo escrito |

| Marca | Quem decidiu |
|---|---|
| 👤 | o Joab decidiu |
| 📏 | saiu de uma medição |
| 🤖 | recomendação do agente, aceita pelo Joab |

**As duas regras que impedem alucinação:**

- 🟡 em bloco que trava código = **código bloqueado**. Palpite não vira implementação.
- 🟢 **sem marca de origem** = bloqueado com "quem decidiu?". Decisão sem dono não existe.

Mudou de ideia sobre algo já fechado? Não apague: **emende**, em
[`docs/DECISOES.md`](docs/DECISOES.md), dizendo o que mudou e por quê. O histórico de
decisão revertida vale mais que a decisão.

---

## 3. Os documentos

| Arquivo | O que guarda |
|---|---|
| `CONCEITO.md` | o jogo em uma página — incluindo **o que NÃO tem** |
| `docs/PLANO.md` | todas as decisões, com estado e origem |
| `docs/DECISOES.md` | o histórico: o que mudou de ideia e por quê |
| `docs/PESQUISA.md` | a pesquisa de mercado — o que funcionou e o que falhou nos concorrentes |
| `docs/DESIGN.md` | mecânica, economia, curva de dificuldade |
| `docs/TELAS.md` | quantas telas, o que cada uma faz |
| `docs/ARTE.md` | direção de arte, paleta, contrato de asset |
| `docs/SOM.md` | música, SFX, de onde vem cada som |
| `docs/ARQUITETURA.md` | como o código vai ser organizado |
| `docs/PRODUCAO.md` | ordem das fatias, o que sai primeiro |
| `docs/GLOSSARIO.md` | o vocabulário do projeto — um nome para cada coisa |

---

## 4. O protótipo

`prototipo/` é **código descartável**. Existe para decidir com a imagem na mão, antes de
existir engine. Não entra no jogo final.

```bash
python3 prototipo/gerador_mapa.py          # gera mapas e valida cada um
python3 prototipo/maquete3d.py arranjos    # os 4 lugares do castelo, em 3D
python3 prototipo/maquete3d.py dimensoes   # o mesmo mapa em 5 biomas
```

As imagens saem em `prototipo/saida/`.

**A arquitetura de duas camadas (decisão D-015)** vale para o jogo inteiro:

- **o que o mapa é** — dado puro (nível, água, rampa, ponte). Testável sem editor, na nuvem.
- **como o mapa aparece** — o 3D. Trocar o visual inteiro não toca uma linha do layout.

---

## 5. Regras que não se negociam

1. **Conceito antes de código.** O portão do plano existe para isso.
2. **A lógica mora em `scripts/regras/`**, como `static func` pura — sem nó, sem sinal, sem
   estado global. É o que a suíte mede. Se não dá para testar, está no lugar errado.
3. **`.uid` e `.import` vão para o git.** Nunca no `.gitignore`.
4. **`.godot/` e `.verify/` nunca vão para o git.**
5. **`.gitattributes` antes do primeiro asset.** LFS depois que o binário entrou no histórico
   custa reescrever tudo. O bloco LFS já está lá, comentado — descomente antes de trazer
   png/glb/ogg grande.
6. **Bug vira teste antes da correção.** O teste falha, aí você conserta.
7. **Número de balanceamento sai de simulação**, não de palpite.
8. **Caminho de asset sai do catálogo**, não de memória. Nome inventado não dá erro nenhum:
   o jogo abre, o portão passa, e a textura só não aparece.
9. **Antes de escrever qualquer método do Godot que você não leu nesta sessão**, confira:
   `python3 planejamento/api.py --tem CharacterBody2D move_and_slide`. Sai com código 1 quando
   não existe. API inventada é o erro número 1 de IA em Godot.

---

## 6. Nuvem × máquina local

| | Nuvem | Máquina local do Joab |
|---|---|---|
| Editor Godot | **não existe** | aberto |
| **Godot AI** (46 tools) | **indisponível** | é o caminho principal |
| Como mexer em `.tscn` | escrever o texto e **provar pelo portão** | tools do Godot AI |
| Screenshot / playtest visual | headless, com `xvfb-run` | direto, com o editor |

Skill que exige o editor aberto (`godot-visual-check`, `godot-playtest-loop`, `godot-visuais`,
`godot-particles`…) **não roda na nuvem**. Não finja que rodou. Diga que é local.

**Nunca minimize a janela do Godot** na máquina local: `editor_screenshot(source="game")`
devolve `stale_frame: true` com a janela minimizada. Mande para a segunda tela ou para fora
da área visível — nunca minimizada.

---

## 7. Git

- Trabalhe no branch que a tarefa indicar, nunca direto na `main`.
- Commit em português, no imperativo, dizendo **o que mudou para o jogador ou para quem
  desenvolve** — não o nome do arquivo.
- Antes de commitar: `./testar.sh` verde.
- `git commit --no-verify` é proibido.
