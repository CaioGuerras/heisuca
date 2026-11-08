# Contrato sintético dos hubs — lógica 10

`hubs-logica10.json` é uma fixture sintética, sem consulta a PMS ou dados reais.
Preserva os campos do envelope Plex antes do mapeamento para `Item`:

- `hubIdentifier: "home.continue"`: origem Continuar, inclusive sem `viewOffset`.
- `context: "hub.home.continue"` (sem `hubIdentifier`): variante de origem Continuar; o valor é o real do PMS 1.43.4 (`plex-respostas/hubs-real-13.json`).
- `hubIdentifier: "home.ondeck"`: origem de próximos episódios; os episódios já iniciados (`viewOffset > 0`) entram em Continuar.
- Hubs anônimos ou de outra origem não entram nessas duas listas, mesmo com progresso ou título traduzido parecido.

Os identificadores `home.continue,home.ondeck` são os usados no cliente local de referência:
`~/heisuca/apps/app/lib/services/plex_client.dart`, `_getContinueWatching`, linhas 1627–1657.
Conferido com PMS real 1.43.4 (Visão, tarefa 13): os dois hubs trazem `hubIdentifier` e
`context` = `hub.home.continue` / `hub.home.ondeck`. A captura anonimizada está em `hubs-real-13.json`.

Casos de regressão: Continuar sem posição não vira Próximo; onDeck em curso é retomada;
Próximo visível sobrevive à deduplicação da Home; item/série repetido tem prioridade de retomada;
Metadata e Directory continuam aceitos. As chamadas `continuar` e `proximos` da fachada já
existem em `src/api/servidor.ts`; nenhum campo de origem foi acrescentado a `Item`.
