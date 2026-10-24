# Heisuca — entrega da rodada de 24/10/2026

Branch: `codex/heisuca-rodada-2410`, criada de `381295b5e1e7951fa02cbb58a0c29c04772b93d0`
da `codex/heisuca-home-site`. A branch original foi preservada. Sem merge, release ou alteração de servidor.

## Validação autorizada por Caio
Commit/push de cada item e validação pelo workflow `.github/workflows/heisuca-android.yml`.
Run verde é obrigatório antes de avançar. Não preparar Flutter local.
A documentação não significa importação no ai-memory.

## Item 1 — ficha da pessoa — concluído no CI, não testado em aparelho
Versão **2.0.14+15**.
Código validado: `5c9b951fe88cb42bf3a15e1defc188c8582d9dc8`.
Commit inicial: `47536ccdd5fd2d417d28d4fb8d395559a289568e`; ajustes:
`961934e`, `c0a2156`, `b6799cd`, `5c9b951`.

- [Run verde 40103763989](https://github.com/CaioGuerras/heisuca/actions/runs/40103763989)
- [APK ARM64 — artifact heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40103763989/artifacts/12564630665)
- Artifact publicado: 51.141.094 bytes; expira em 07/11/2026.
- Digest ZIP: `6388124f77d29dbfe79ddef75f69fac0768aa43608f2f0c4ef1e605d5ad2490e`.

### Arquivos e comportamento
- `lib/cgflix/search/cgflix_sources.dart`: consulta as fontes autorizadas online do adulto,
  preserva escopo kids, pagina toda a filmografia, agrupa duplicatas e escolhe a melhor
  fonte pelas regras existentes da busca.
- `lib/cgflix/search/cgflix_person_plex.dart` e um gancho em `lib/services/plex_client.dart`:
  identidade de pessoa em `/library/people/{id}`, namespace oficial PMS, sem confundir tag id
  com ratingKey de filme. Referência: https://developer.plex.tv/pms/ — Get person details.
- `lib/heisuca/heisuca_person_credits.dart`: consulta identidade separadamente ao abrir.
  Jellyfin: `/Items/{personId}`, ProviderIds.Tmdb; Plex: GUID externo da pessoa.
  Sem TMDB confirmado, apenas No acervo. Não adivinha TMDB por nome/tagKey.
- `lib/cgflix/requests/cgflix_seerr.dart`: contrato separado de créditos pessoais,
  `/person/{tmdbId}/combined_credits`, somente cast e formatos camelCase/snake_case.
- `lib/cgflix/requests/cgflix_requests_ui.dart`: reaproveita tile, botão Pedir,
  escolha de temporadas e estados de pedido; permite créditos e exclusão do acervo.
- `lib/screens/actor_media_screen.dart`: ganchos mínimos para No acervo e Também atuou em.
- `test/heisuca/heisuca_person_credits_test.dart`: identidade, parser, exclusão por IDs/tipo,
  paginação, combinação Jellyfin + Plex e contrato HTTP de pessoa Plex.
- `test/heisuca/heisuca_neutral_server_test.dart`: exceção EXATA para o relay autorizado
  da versão 2.0.12, sem permitir URL de mídia/login embutida.
- `pubspec.yaml`: incremento de versão.

### Testes e evidências
Comando do portão: `bash scripts/heisuca-checar.sh`.
Executa `flutter analyze --no-fatal-infos --no-fatal-warnings lib` e a lista
`flutter test` do script, incluindo `test/heisuca`, controles do player, bootstrap,
Home, cartões, Seerr, filmografia, detalhes Plex e isolamento de favoritos Jellyfin.
Resultado: **358 aprovados, 3 ignorados**. Análise sem erro novo; avisos preexistentes
não foram apresentados como corrigidos.

Também passaram:
- `./gradlew :app:testDebugUnitTest --tests com.edde746.plezy.mpv.HeisucaBufferBudgetTest -PtargetAbi=arm64-v8a -PheisucaPreview=true`.
- Compilação Flutter Release ARM64 e `scripts/heisuca-validar-apk.py` no APK efetivo.
- Conferência de pacote, providers e assinatura; upload do artifact; run encerrado verde.

### Assinatura — limitação real da nova branch
Certificado desta build: `c417c8649715f3a38716fa7a5d9eace6b6bdecde36848b2fcf7eabac6d51f92b`.
Certificado da build verde anterior da branch original (run 40079091086):
`19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
O pacote de teste é o mesmo, mas a assinatura difere: **não é atualização direta**
sobre a instalação assinada com a chave anterior. Não apagar dados/perfis para contornar
isso. Para atualizar aquela instalação preservando dados, o responsável com acesso à
chave anterior deve reassinar/compilar com ela. Nenhuma chave foi copiada para código
ou logs. O cache de chave de teste desta nova branch foi salvo pelo workflow.

### O que não foi testado
Não testado em aparelho. Não foi feito teste ao vivo com a conta de Caio, Sadie Sink
ou Stranger Things. O cenário correspondente foi validado com fixtures Jellyfin + Plex.
Plex sem GUID externo TMDB da pessoa exibe só No acervo. Sem Seerr autenticável,
não há catálogo para pedir. Kids não consulta catálogo externo nem oferece Pedir.
Não houve alteração de VPS, Sonarr ou configuração Jellyfin.

### Histórico de falhas corrigidas neste item
- Run 40102809456: 351 aprovados, 2 falhas, 3 ignorados. Fakes novos usavam int em
  vez de int? para start/size. A outra falha já estava na base e fora da lista dos 16:
  guarda neutra rejeitando relay próprio autorizado. Correção exata com motivo no teste.
- Run 40103320121: 357 aprovados, 1 falha, 3 ignorados. Fixture HTTP Plex precisava de
  PlexApiCache com banco em memória. Corrigido com teardown, sem afrouxar assertivas.
- Runs iniciais 40102367785/40102571153 foram cancelados pela inclusão dos testes e
  correção da rota oficial Plex antes da execução final.

## Itens seguintes
| Item | Estado |
| --- | --- |
| 2 — player | Próximo item; ainda não implementado nesta rodada |
| 3 — medidor | Pendente |
| 4 — refinos/variantes do ícone | Pendente; ícone instalado preservado |
| 5 — remover MAL/AniList e manter Trakt | Pendente |
| 6 — não implementar transmissão | Nenhuma transmissão acrescentada |
| 7 — 16 testes anteriores | Lista lida; ainda não corrigidos nesta rodada |

O run verde acima valida o portão do workflow, não a suíte completa dos 16 testes
fora dele. Não declarar os sete itens entregues enquanto a tabela indicar pendências.

## Item 2 — player — 2.0.15+16 — enviado para validação
Ainda não aprovado; não testado em aparelho.
- Novo `lib/heisuca/player/heisuca_series_episodes.dart`: logo de série/filme com reserva
  em texto, código e nome próprio do episódio, seletor com abas de temporada, miniaturas,
  duração, progresso, ocultação de spoilers e rolagem no episódio atual.
- `lib/heisuca/player/heisuca_player_hud.dart`: remove Próximo do HUD e agrupa áudio,
  legendas, velocidade e ajustes à direita; proporção/PiP/rotação/trava continuam no topo.
- Ganchos mínimos em `mobile_video_controls.dart`, `video_controls.dart` e
  `widgets/video_controls_header.dart`: reaproveitam callback real de navegação e
  permissões; não alteram avanço automático nem cartão de próximo episódio.
- Testes `heisuca_player_hud_test.dart` atualizados com motivo da decisão de Caio;
  novo `heisuca_series_episodes_test.dart` cobre título, seleção entre temporadas,
  rolagem atual e verifica referências ao protótipo antigo no código do ramo.
- Protótipo antigo ainda preservado até o teste de referências confirmar a remoção.
  Se confirmado, limpeza será feita em commit próprio conforme o handoff.
- Commit/run verde/APK: pendentes. Não declarar os próximos itens entregues.

## Conferência do Claude (24/10, tarde)
- O GPT parou no item 2 (a conversa dele atingiu o limite). Itens 3 a 7 **não foram iniciados**; nada ficou pela metade
  além do que está descrito acima.
- **Item 2 validado localmente** em `b62ee7a`: `flutter analyze` sem erro nem aviso novo (só 7 infos de estilo) e a lista
  de testes do `scripts/heisuca-checar.sh` com **362 aprovados, 3 ignorados, 0 falhas**. Código conferido: sai o Próximo e a
  aba Episódios da barra de baixo, os episódios abrem pelo logo/título, velocidade entra no grupo da direita.
- **Assinatura:** o cache do GitHub Actions é separado por ramo, então `codex/heisuca-rodada-2410` não achou a chave de
  teste do `codex/heisuca-home-site` e gerou outra. Correção: `codex/heisuca-home-site` avançou (fast-forward, sem merge)
  até estes commits; o CI desse ramo usa a chave original e o APK volta a instalar por cima. Próximas rodadas trabalham
  direto em `codex/heisuca-home-site`.
