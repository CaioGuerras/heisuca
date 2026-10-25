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

## Retomada — item 3 — 2.0.16+17
Ramo efetivo: `codex/heisuca-home-site`; instrução atual de Caio prevalece sobre o histórico acima.

- Você › App › Este aparelho: medidor acessível de três faixas, RAM, arquitetura do processo,
  sinal Android de pouca RAM e pressão de memória atual; atualização manual e ao retornar ao app.
- Vermelho: pressão de memória atual OU processo de 32 bits com RAM ≤ 2 GiB,
  independente da preferência de efeitos. Âmbar: portão `DevicePerformance.isReduced` ativo.
- Ajustes listados pelos portões reais: duração de animações, rotação de fundos, limites de
  imagens/cache e requisições. O pré-carregamento da Início não é apresentado como desligado:
  `_HeisucaHero._notifyActive` não tem esse portão. Parallax ainda pertence ao item 4.
- Decodificação por hardware não inferida a partir da preferência: o mpv não está disponível
  nesta tela fora da reprodução; orienta consultar as estatísticas do vídeo.
- Teste de fronteira: 2 GiB, 2 GiB + 1 byte, 64 bits, sinais ausentes e pouca memória.
- Validação local: `bash apps/app/scripts/heisuca-checar.sh` aprovado: 363 testes passaram,
  3 ignorados; análise sem erro/aviso novo nos arquivos tocados. Primeira tentativa interrompida
  por HTTP 503 ao baixar media_controls; repetição após setup concluído passou.
- Código: `f10ddc75a2c6010e2290b1959968d0918b938cc6` (sem skip ci).
- [Run verde 40138140122](https://github.com/CaioGuerras/heisuca/actions/runs/40138140122), encerrado com `success`.
- [APK ARM64 2.0.16+17 — heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40138140122/artifacts/12578350343).
  Artifact: 51.164.291 bytes, não expirado na conferência; digest ZIP
  `bf4a91555c4fc9e6cab47fa8125f5e5b5049543ec901cf16e86198882905fc8c`.
- CI passou também nos testes nativos do buffer mpv, compilação release e conferência
  do pacote/providers/assinatura. Certificado SHA-256 confirmado nos logs:
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`, igual ao original deste ramo.
- Não testado em aparelho, nem com sessão de mídia real. Itens 4–9 ainda não iniciados.


## Item 4 — parado na conferência, sem implementação
Após o verde do item 3, conferi a base indicada no item 4 do handoff (linha 73):
`cgflix/pesquisa_apps/marca` (selo C, cor do tema). Esse caminho não existe na árvore
do ramo `codex/heisuca-home-site`. Comandos de conferência:

```
git ls-tree -d HEAD
git ls-tree -r --name-only HEAD | rg 'pesquisa_apps|marca/'
rg --files | rg 'pesquisa_apps/marca|icone|icon.*512|brand'
```

Há fontes alternativas com identidades distintas:
- `apps/app/cgflix-brand/cgflix-icone.svg`: identidade histórica CGFLIX; o gerador
  `gerar_icone_android.py` descreve explicitamente o emblema "C com play".
- `apps/app/assets/heisuca/icone_shikkoku.svg` e demais temas: selo Heisuca 炳.

O próprio pedido mistura exemplos com 炳 e a base descrita como selo C. Não escolhi
uma dessas fontes como substituta do diretório ausente. Conforme a regra de Caio
("Se o código real não bater com o desenho, pare e documente; não improvise"), parei
antes de implementar o item 4. É necessário confirmar qual arquivo versionado é a
base das três variantes, ou disponibilizar a fonte indicada. Nenhum ícone foi trocado;
nenhum refino parcial do item 4 foi enviado. Não houve acesso a VPS/servidores.

### Estado ao encerrar esta retomada
| Item | Estado atual |
| --- | --- |
| 3 | Concluído no CI, 2.0.16+17; não testado em aparelho |
| 4 | Bloqueado pela divergência de referência da marca acima |
| 5 | Pendente; MAL/AniList ainda não removidos; Trakt não alterado |
| 6 | Nenhuma transmissão criada; confirmação formal da etapa ainda pendente |
| 7 | Pendente; não foi rodada/corrigida a suíte histórica dos 16 testes |
| 8 | Pendente |
| 9 | Pendente; Início Jellyfin preservada nesta retomada |

Somente o ramo `codex/heisuca-home-site` foi alterado. Sem ramo novo, PR, merge ou release.
O commit documental posterior ao verde usa skip ci; o código do item 3 já foi
compilado e validado pelo run verde acima, em commit sem skip ci.

## Item 4 — retomada após correção da base — 2.0.17+18
O bloqueio anterior foi resolvido pelo commit `148e78f` e pela instrução de Caio:
base exclusiva no selo 炳, `docs/marca/` e `apps/app/assets/heisuca/icone_*.svg`.

- `heisuca_motion.dart`: duração única de 420 ms, curva de mola criticamente amortecida,
  sem ultrapassar os limites de opacidade; compartilhadas pela ficha, abas e sheets Heisuca.
  Movimento reduzido no sistema ou `DevicePerformance.isReduced` zeram as transições.
- Parallax de 25% na arte da Início e ficha, conservando máscara e metadados. Desligado
  pelos mesmos portões. A montagem de fileiras e os dados Jellyfin não foram alterados.
- Hero liga os pôsteres Heisuca à ficha real (`HeisucaTitleSheet`, uma rota de página,
  apesar do nome); tag individual por cartão, limpa ao fechar a ficha.
- Fade-through conserva as páginas montadas e desativa toque, semântica e tickers das
  abas ocultas. Sem trocar o destino ou recriar a navegação do upstream desktop/TV.
- Sheets de login, fontes, temporadas/episódios, pedidos e menu da Home usam a mola comum.
- `docs/icone_variantes_2026-10-24/`: três PNGs 512×512, SVGs correspondentes, renderizador
  e mockup Android lado a lado. Geometria vetorial do 炳 preservada; mockup é simulação.
  Conferência visual do PNG executada. Nenhum recurso de ícone Android/iOS foi alterado.
- Testes novos: curva monotônica/normalizada, troca de abas sem toque na saída,
  parallax real de rolagem e desligamento por desempenho.
- Portão local: `bash apps/app/scripts/heisuca-checar.sh` aprovado; 367 testes passaram,
  3 ignorados, análise sem erro/aviso novo nos arquivos tocados.
- Código: `97d9e5e9624cb8cb7ab637bf05018efe82d0684c`, commit sem skip ci.
- [Run verde 40143220353](https://github.com/CaioGuerras/heisuca/actions/runs/40143220353),
  encerrado com `success`. Testes nativos, compilação ARM64 e conferência do APK aprovados.
- [APK 2.0.17+18 — heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40143220353/artifacts/12579653876).
  Artifact: 51.165.821 bytes. Digest ZIP:
  `9f7b28a5b5c6848be2ae00c7a2da73c4d3af1ba100f26dd223b1c5fe2f1e0d42`.
  Certificado SHA-256 confirmado nos logs: `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  Não testado em aparelho; fluidez, voo do
  pôster e comportamento de gestos precisam de avaliação física de Caio.


## Item 5 — divergência encontrada na conferência após o verde do item 4
**Parado antes de implementar.** O desenho descreve a retirada de MAL/AniList e do
OAuth proxy como caminho para que nenhuma chamada do app vá para `ice.plezy.app`.
O código real tem outros consumidores desse domínio, além do proxy:

| Caminho | Evidência estática | Situação |
| --- | --- | --- |
| `lib/services/discord_rpc_service.dart:56` | `_posterUploadUrl = 'https://ice.plezy.app/posters'` | Upload das capas do Discord RPC |
| `lib/services/discord_rpc_service.dart:157` | Agenda `_uploadThumbnailAndUpdatePresence` | Fluxo de presença chama o upload |
| `lib/services/discord_rpc_service.dart:366` | `httpClient.post(_posterUploadUrl, body: imageBytes, …)` | POST real, não apenas documentação |
| `lib/services/log_upload_service.dart:6` e `:51` | `logUploadEndpoint` e POST do diagnóstico | Endpoint ainda presente |
| `lib/screens/settings/logs_screen.dart:483` | Botão condicionado a `cgflixAllowLogUpload` | Desativado por padrão; não foi observado envio |
| `lib/watch_together/services/watch_together_relay_endpoint.dart:11` | `upstreamRelayBaseUrl` | Uso pelo OAuth proxy, já previsto no item 5 |

Comando de conferência: `rg -n 'ice.plezy.app' apps/app/lib` e leitura dos métodos
`_uploadThumbnail`/`_uploadThumbnailAndUpdatePresence` do Discord. Não foi feita chamada
real a esses serviços, nem teste com Discord/contas no aparelho. Discord RPC é integração
de desktop; esta descoberta não comprova envio no Android.

Remover só MAL/AniList deixa o POST de capas no Discord. Retirar também esse POST exige
especificar como a presença Discord deve ficar (por exemplo, sem capa hospedada) e
tratar a API de envio de diagnóstico; isso não está descrito no desenho do item 5.
Não redirecionei as chamadas para a VPS nem inventei endpoint ou fluxo substituto.
Parei conforme a regra de Caio: "Se algo não bater, pare e documente". Nenhum código do
item 5 foi alterado. Trakt foi preservado; MAL/AniList ainda não foram removidos.

### Estado atual desta continuação
| Item | Estado |
| --- | --- |
| 4 | Concluído no CI, 2.0.17+18; três variantes apenas em docs; não testado em aparelho |
| 5 | Parado pela divergência dos outros consumidores do domínio descrita acima |
| 6 | Pendente na sequência; nenhuma transmissão criada |
| 7 | Pendente; os 16 testes históricos ainda não foram corrigidos |
| 8 | Pendente |
| 9 | Pendente; montagem/dados da Início Jellyfin não foram alterados nesta continuação |

Somente `codex/heisuca-home-site` foi usado. Sem ramo novo, PR, merge, release ou
alteração de servidor. O registro documental posterior ao run verde usa skip ci;
o código do item 4 está no commit validado sem skip ci acima.

## Rodada de 25/10 — etapa A: conferência interrompida por divergência do diagnóstico
Base inspecionada: `1566c46`, ramo `codex/heisuca-home-site`, versão vigente **2.0.17+18**.
Leitura realizada na ordem pedida: AGENTS/Pilares; handoff A–M; correções e Android 17
no guia; retorno de Caio; esboço 04C; handoff antigo e registro de entrega.

### Evidência encontrada na etapa A
O retorno 13 atribui a listra ao degradê que se move junto com a arte. A árvore real
já mantém o ShaderMask fora da transformação do parallax:

- `apps/app/lib/heisuca/heisuca_home_screen.dart:502–513`:
  `ShaderMask → HeisucaParallax → AnimatedSwitcher → OptimizedMediaImage`.
- `apps/app/lib/heisuca/heisuca_title_sheet.dart:414–418`:
  `ShaderMask → HeisucaParallax → OptimizedMediaImage/Hero`.
- `apps/app/lib/heisuca/heisuca_motion.dart:27–35`: o único `Transform.translate`
  envolve o filho de imagem; deslocamento positivo de 25% da rolagem, limitado a 200 dp.
  O ShaderMask não está nesse filho e não recebe essa translação.
- A imagem da Início recebe exatamente `widget.height`; o helper usa ClipRect, sem
  aumentar a área pintada. Falta sobra de arte para cobrir todo o quadro local durante
  a translação. Isso é uma constatação geométrica, **não prova da causa da listra
  inferior observada no vídeo do Caio**. O quadro do sliver continua rolando normalmente.

Conferência por leitura e linhas numeradas (`nl -ba`); não foi feita reprodução em
aparelho/emulador, nem comparação visual com os vídeos citados pelo retorno. Não
atribuo a listra a outra causa sem reproduzir. É necessário reproduzir a borda e
identificar qual camada a desenha antes de escolher a correção; apenas mover a máscara
para fora do Transform repetiria a estrutura atual. Também é necessário preservar o
recorte aprovado da Início ao definir a sobra de arte.

Conforme a instrução de Caio ("Se o código real não bater com o desenho, pare e
documente; não improvise") e os Pilares (corrigir na causa), parei a etapa A sem
alterações de código. Não apliquei correções parciais de marca/fonte/ficha no mesmo item.

### Outros fatos conferidos, sem implementação
- `assets/fonts/Sora-VF.ttf` existe; a família Sora não está declarada no pubspec e a
  licença OFL não está ao lado. A tabela de nomes da própria fonte identifica o projeto
  Sora e a licença SIL OFL 1.1. Nenhuma fonte/licença foi substituída.
- O coração de Favoritos ainda está no ActionChip da Biblioteca.
- A ficha ainda tem cabeçalho próprio; a unificação com HeisucaHomeChrome não foi feita.
- O texto da marca na abertura ainda é Text; não foi trocado pelo SVG.

### Validação e estado
Nenhuma etapa A–M concluída; B–M não iniciadas. Não foi alterada a Início Jellyfin,
o player, os servidores, Discord, os ícones ou o fluxo em segundo plano. Sem PR,
ramo novo, merge, release ou acesso à VPS.

Não rodei Flutter/análise/testes nesta rodada: houve apenas inspeção e este registro.
Sem incremento de versão e sem novo APK, pois a etapa A não foi implementada.
O último código validado continua sendo `97d9e5e9624cb8cb7ab637bf05018efe82d0684c`:
- [Run verde 40143220353](https://github.com/CaioGuerras/heisuca/actions/runs/40143220353),
  `success` reconferido via GitHub CLI em 25/10.
- [APK 2.0.17+18](https://github.com/CaioGuerras/heisuca/actions/runs/40143220353/artifacts/12579653876),
  artifact `heisuca-apk` reconferido como não expirado. É o APK anterior, não uma entrega da rodada A–M.

Este commit é exclusivamente documental e usa skip ci. Não há código de etapa nova
somente em commit skip ci. A próxima versão de código permanece **2.0.18+19**.

## Rodada de 25/10 — etapa A retomada — 2.0.18+19
Base atualizada para `a972f34`: a listra foi separada na etapa A2, com evidências reais.
O bloqueio anterior não se aplica aos demais ajustes da A. Parallax/máscara/arte não
foram alterados nesta etapa; a montagem e os dados da Início Jellyfin foram preservados.

- A abertura usa `HeisucaLogo(siteHeader: true)`: os mesmos SVGs oficiais por tema da
  Início. O texto digitado da marca e o selo separado saíram desta abertura.
- Brilho reduzido (halo e sombra), slogan em cor opaca com contraste AA nos dois temas.
  O sinal de reduzir movimento e `DevicePerformance.isReduced` encerram a animação sem
  espera animada. Não foi feita medição de desempenho em aparelho.
- Sora variável declarada no pubspec; `Sora-LICENSE.txt` ao lado, com o copyright do
  projeto Sora e SIL OFL 1.1, obtida do repositório oficial Google Fonts:
  https://raw.githubusercontent.com/google/fonts/main/ofl/sora/OFL.txt .
- Favoritos da Biblioteca sem coração, como os chips vizinhos.
- A ficha usa o mesmo `HeisucaHomeChrome` da Início: título acompanha a âncora e encaixa
  entre marca e busca, com retorno e ação de continuação disponíveis. O cabeçalho
  duplicado da ficha foi removido. Parâmetros novos conservam os padrões da Início;
  a região de toque do título tem pelo menos 48 dp de altura sem aumentar a arte.
- Testes direcionados: **12 passaram**. Incluem SVG por tema, slogan AA, redução de
  movimento, encaixe do título nos dois formatos, busca e continuidade/temporadas reais
  com fixtures. A expectativa de encaixe na ficha curta foi corrigida: a fixture tem
  só 184 dp de rolagem, insuficientes para alcançar o topo; o teste específico de encaixe
  usa conteúdo longo. Não foi afrouxada a verificação da continuação nem do topo.
- `bash apps/app/scripts/heisuca-checar.sh`: **aprovado**, 371 testes passaram, 3 ignorados;
  análise sem erro/aviso novo nos arquivos tocados. Commit/run/APK aguardando CI.
- Não testado em aparelho. Não foi validado visualmente com conta real, Plex/Jellyfin
  reais ou vídeos de Caio. A2 e B–M ainda não iniciadas.
