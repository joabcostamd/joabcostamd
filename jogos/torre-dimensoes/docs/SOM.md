# Torre entre Dimensões — direção sonora

Data: 2026-09-12

> O buraco histórico dos projetos: som decidido no fim vira som improvisado.
> Consulte o acervo (skill `acervo-sons`) antes de comprar ou gerar qualquer coisa.

---

## 1. Os três sons universais

Decididos na identidade mínima. Aparecem em toda tela do jogo.

| som | como soa | de onde vem |
|---|---|---|
| confirmar | <descrição> | <gerado por código / acervo / IA> |
| cancelar | <descrição> | <...> |
| erro | <descrição> | <...> |

## 2. Os momentos que pedem som

Toda ação do jogador tem retorno sonoro. Regra do `PREFERENCIAS-DE-JOAB.md`.

| evento | som | prioridade |
|---|---|---|
| <evento> | <nome> | <alta / média / baixa> |

## 3. Som que informa precisa de equivalente visual

Se um som avisa de perigo, quem não ouve precisa de um sinal na tela.

| som que informa | o sinal visual equivalente |
|---|---|
| <som> | <sinal> |

## 4. Música

Camadas: <quantas e quando cada uma entra> · faixas no lançamento: <n>
De onde vem: <sintetizada por código / autoral / acervo CC0 / gerada por IA>

## 5. Mixagem

| bus | o que passa | volume padrão |
|---|---|---|
| Mestre | tudo | <db> |
| Música | <...> | <db> |
| Efeitos | <...> | <db> |
| Interface | <...> | <db> |

## 6. Contrato de som

Formato: <ogg / wav> · taxa: <Hz> · pico máximo: <dBFS> · sem silêncio nas pontas ·
laço fechado obrigatório em som que repete.

---

## Está pronto quando

- [ ] os três sons universais existem e tocam
- [ ] toda ação do jogador da tabela 2 tem som
- [ ] todo som que informa tem equivalente visual
- [ ] o jogo é jogável de ponta a ponta sem som nenhum
