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
  análise sem erro/aviso novo nos arquivos tocados.
- Código: `e690292db7dd409374df1859e5116edf346fb435` (sem skip ci).
- [Run verde 40153760344](https://github.com/CaioGuerras/heisuca/actions/runs/40153760344), `success`.
- [APK 2.0.18+19 — heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40153760344/artifacts/12584277212).
  Artifact: 51.223.785 bytes, não expirado na conferência. Digest ZIP:
  `b116c389b2c4ce50450fa8c9193190c936198d9b8dd15e10e7fa4a0dc00db96d`.
  Testes nativos, compilação ARM64 e validação do pacote/providers/assinatura passaram.
  Certificado SHA-256 confirmado: `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
- Não testado em aparelho. Não foi validado visualmente com conta real, Plex/Jellyfin
  reais ou vídeos de Caio. A2 e B–M ainda não iniciadas.

## Rodada de 25/10 — etapa A2 — 2.0.19+20 — concluída no CI
A2 foi iniciada somente após o run verde da etapa A.

- Evidência real lida; confirmado o defeito de uma fileira física (linha 88 do recorte,
  704 cores, fundo uniforme acima/abaixo). Não foi confundido com um degradê inteiro.
- **Reprodução anterior à correção:** o teste padrão passou, mas os quatro casos com
  Impeller falharam, com uma fileira colorida no mesmo limite da arte. Exemplo:
  rolagem 32,125 dp, DPR 2,97, borda 1653,82875 px; 1220 pixels divergentes.
- Controle sem parallax passou. ClipRect externo sozinho não resolveu; não foi adotado
  como correção isolada. A causa reproduzida é cobertura subpixel da composição da máscara
  com a imagem transformada no Impeller, não o gradiente dentro de Transform.
- Novo `HeisucaArtworkMask` comum à ficha e Início garante cobertura da célula física
  da borda, ampliando só a composição da máscara por um pixel físico. Imagem, quadro,
  alinhamento e coordenadas do gradiente mantêm as medidas originais.
- Primeira matriz corrigida: **4 passaram no Impeller**. Matriz final ampliada aprovada:
  dois DPRs × dois quadros × parallax ligado/desligado, 184 quadros por renderizador.
- Golden anterior verifica composição em repouso com tolerância máxima de 1/255 por
  canal; a verificação da borda é exata. Comparação das capturas, fora da borda,
  também teve diferença máxima de 1/255. Nenhuma troca de recorte ou montagem de fileiras.
- Teste com Impeller adicionado ao `checar.sh` para impedir que a regressão volte verde
  apenas porque o renderizador padrão não mostra o defeito.
- Evidências, método e capturas sintéticas de antes/depois em
  `docs/evidencias/A2_REPRODUCAO_2026-10-25.md`. Não são capturas do aparelho nem do acervo.
- Portão completo aprovado: análise sem erro/aviso novo, **379 testes aprovados e
  3 ignorados** na suíte padrão, mais **8 aprovados com Impeller**.
- Código: `ec7bc5cf5a9de2c925b4435ee291736a09e91ff8`, sem skip ci.
- [Run verde 40156049967](https://github.com/CaioGuerras/heisuca/actions/runs/40156049967), `success`.
- [APK 2.0.19+20 — heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40156049967/artifacts/12584731542).
  Artifact: 51.226.218 bytes, não expirado na conferência. Digest ZIP:
  `252f6f14b70cfb0d1abd1015461fa4f4d87024633a4530c51dd05ad3018ad9b3`.
  Portão com Impeller, testes nativos, compilação ARM64 e validador do APK aprovados.
- **Não testado em aparelho.** A reprodução equivalente no Flutter tester não confirma
  a correção física no Edge 60 Pro. B–M ainda não iniciadas.

## Rodada de 25/10 — etapa B — 2.0.20+21 — concluída no CI
Iniciada somente após o run verde de A2. A decisão atual de remover Discord inteiro
prevalece sobre o trecho histórico do handoff que sugeria manter presença sem capa.

### O que saiu e por quê
- MAL/AniList: clientes, autenticação, trackers, fontes de catálogo e modelos exclusivos;
  entradas de configurações, início de conexão/QR e vinculação de sessões no provider.
- OAuth proxy: cliente, serviço base e diálogo; retirada a constante do relay antigo.
- Discord RPC: serviço e dependência `dart_discord_presence`, inicialização, preferências,
  comandos de ajustes, efeitos de configurações e ganchos de vídeo/música. Sem integração
  substituta com Telegram e sem envio automático a outro serviço.
- Envio interativo de diagnóstico: serviço HTTP/endereço, ações e diálogos de Logs e
  da falha de abertura. O limite UTF-8 necessário ao Clipboard permanece no helper
  **local** `diagnostic_text.dart`; copiar, selecionar, limpar e recuperar logs continuam.
- Recursos sem consumidores: mixin `anime_list_tracker_base.dart` e protótipo
  `heisuca_player_screen.dart`. A varredura de referências confirmou ausência de uso;
  o HUD/player real foi preservado. Retiradas exceções TLS dos dois trackers removidos,
  em Dart e no XML Android, mantendo confiança estrita para os demais endpoints.

### O que foi preservado e como foi verificado
- Trakt: cliente e fluxo de autenticação mantidos; sessão/catálogo compartilhados com
  o tracker, isolamento por perfil, revogação, cancelamento e geração de vínculos.
- Simkl/MDBList não foram removidos. A lista de serviços disponíveis é centralizada;
  nem a opção de testes de mostrar todos recria MAL/AniList na interface.
- IDs legados do enum e campos de metadados continuam legíveis para compatibilidade
  com dados salvos. Isso não cria cliente nem consulta de rede: teste semeia sessões
  MAL/AniList antigas e verifica que não ativam fontes ou chamadas.
- `rg -n 'ice.plezy.app' apps/app/lib`: **sem resultados** (saída 1 esperada do rg).
  Guarda permanente também verifica ausência do destino, `DiscordRPCService` e
  `OAuthProxyClient` no código do app.
- A Início Jellyfin, sua montagem e os componentes de arte de A2 não foram alterados.

### Testes
- **383 aprovados**: providers (incluindo Trakt), serviços de trackers/filas/cancelamento,
  música, logs, falha de abertura, avaliações, Trakt CGFLIX e confiança TLS.
- **31 aprovados**: falha de abertura do vídeo, abertura/recarga, saída da rota e linha
  do tempo de TV ao vivo. Nenhuma transmissão/casting foi acrescentada.
- **11 aprovados**: cache, catálogo e trocas de fontes do CatalogSourcesProvider.
- Análise de `lib test` sem erro ou aviso novo nos arquivos tocados.
- Testes exclusivos das integrações retiradas foram aposentados com elas; as provas
  gerais de perfil, corrida, filas, música e seleção/cópia foram mantidas. Casos gerais
  antes baseados em MAL/AniList usam Trakt/Simkl agora. Donos OAuth: 6 → 3; avaliações:
  5 trackers → 3, mais o servidor. As duas expectativas de nome CGFLIX na cópia foram
  atualizadas para a marca vigente Heisuca, sem mudar o conteúdo/separadores copiados.
- Portão completo: **381 aprovados e 3 ignorados**, mais **8 aprovados com Impeller**.
- Commit de código: `383f59ef4a3ac36b853f79e92968d7b51e3e4b37` (sem skip ci).
- [Run verde 40159071302](https://github.com/CaioGuerras/heisuca/actions/runs/40159071302), `success`.
- [APK 2.0.20+21 — heisuca-apk](https://github.com/CaioGuerras/heisuca/actions/runs/40159071302/artifacts/12586550852).
- Artifact: 51.128.517 bytes; SHA-256 `c4686baa9e34cb0d68e19d3d91e2ac95a8fece22a6ad81d7a61b025716d1bbc9`.
- Não testado em aparelho, em conta Trakt real nem em reprodução com servidor real.
  Os testes de rede usam clientes controlados; não foram feitos login/envio ao Plezy,
  Discord, MAL ou AniList. Etapas C–M ainda não iniciadas.

## Etapa C — pausada antes da implementação; C–M pendentes

- Evidência e pergunta de contrato: [BLOQUEIO_ETAPA_C_2026-10-25.md](BLOQUEIO_ETAPA_C_2026-10-25.md).
- O desenho exige Em alta/Em breve com Plex CGSERVER ativo; o código obtém o
  calendário completo somente com sessão Jellyfin. Falta definir a origem e a
  autenticação para uma instalação que só tem Plex, ou explicitar a dependência
  de um Jellyfin CGSERVER já conectado. Não inferir URL/token a partir do Plex.
- Investigação de código e contrato, sem consulta ao servidor real; não se afirma
  que um endpoint do servidor inexiste. A busca Plex por IDs já está disponível.
- Pausa conforme “Se algo não bater, pare e documente”; sem alteração parcial da
  Home, sem mudança da Início Jellyfin, sem aumento de versão para documentação.
- Última versão/APK verde: **2.0.20+21**, etapa B, run **40159071302**, links acima.
- Assinatura B conferida no log do Actions: SHA-256
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`, a mesma de A/A2.
- A rodada completa **não foi concluída**. Retomar na C após esclarecer o contrato;
  D–M não iniciadas. Validação física de A/A2/B ainda pendente.

## Retomada de 25/10 — etapa C — 2.0.21+22 — concluída no CI

- Contrato incorporado do commit `8531b55`: o bloqueio anterior foi superado pela
  decisão explícita de usar um Jellyfin salvo no perfil e o vínculo `plex` de cada feed.
- Uma montagem visual para Jellyfin e Plex: destaque, Continuar, Em alta, bibliotecas
  na ordem do servidor e Em breve. Removidos os hubs promovidos e sua humanização de
  títulos da Home Plex. Bibliotecas de música não entram no acervo de vídeo.
- `HeisucaPlexHomeRepository` consulta somente Jellyfins on-line/visíveis no perfil;
  valida `plex` separadamente em cada feed contra o ID da fonte Plex ativa. Não contém
  identidade/endereço CGSERVER, token fixo nem uso de token Plex no Jellyfin.
- Em alta: resolve TMDB/TVDB com `PlexClient.findByExternalIds`, preserva ranking,
  pula títulos ausentes e deduplica cópias. Em breve usa mapa + calendário autenticado
  da mesma sessão Jellyfin; abre a ficha Plex quando há correspondência e mantém a
  busca real de pedidos quando não há. Pôsteres do calendário usam o cliente de origem.
- Sem conexão/vínculo/feed acessível: fileira vazia, sem mensagem ao usuário. Cache em
  memória por instância/perfil, renovado no refresh, reconexão/troca e após dez minutos.
- O Continuar Plex continua consumindo o DiscoverProvider, atualizado ao sair do player.
- A montagem Jellyfin anterior foi mantida; só ganhou o contrato comum de dados.
  As consultas e o cache Jellyfin permaneceram iguais. Capturas da versão anterior
  (`8531b55`, antes desta etapa) foram geradas para Home parada e rolada a 350 dp;
  o teste golden compara as duas imagens com a implementação nova, sem atualizá-las.
  Ambas passaram sem diferença. São fixtures de Flutter/Linux, com Sora/Inter reais;
  não são capturas de aparelho nem conteúdo/arte de servidor real.
- Testes direcionados iniciais: **30 aprovados** (Plex, paridade Jellyfin, repositório
  Jellyfin), mais **1 golden aprovado** com duas capturas antes/depois. Teste adicional
  cobre feed indisponível e revalidação do vínculo ao atualizar.
- Portão completo: **389 aprovados, 3 ignorados**, mais **8 aprovados com Impeller**.
  Inclui os sete testes Plex e o golden Jellyfin desta etapa.
- Código: `18668541dce07f1032f45331f9eff52853af7565` (sem skip ci).
- [Run verde 40188133608](https://github.com/CaioGuerras/heisuca/actions/runs/40188133608), `success`.
- [APK 2.0.21+22](https://github.com/CaioGuerras/heisuca/actions/runs/40188133608/artifacts/12597072881).
- Artifact: 51.132.478 bytes, SHA-256 `4031cab01df685f9dc17a19e5a3006667a017a025decb3f57e20fdcb9ffdcfe9`.
- Pacote/providers conferidos; assinatura SHA-256 `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c` (mesma de B).
- Não testado: aparelho, Plex/Jellyfin reais, fluidez em hardware, abertura real do
  pedido e reprodução real. O formato público dos feeds foi informado no contrato
  do Claude/Caio; os testes desta etapa usam HTTP controlado, sem login real.

## Etapa D — 2.0.22+23 — concluída no CI

- Resolvedor único `HeisucaLogoResolver` e componente `HeisucaTitleLogo`: usados pelo
  cabeçalho compartilhado (destaque/ficha) e pelo título de série/filme do player.
- Ordem: logo do próprio servidor, sem consulta adicional; senão, para Plex, lê os
  IDs externos pelo cliente existente e procura o mesmo título num Jellyfin on-line
  visível no perfil que declare o vínculo Plex nos feeds definidos em C. Confirma
  TMDB/TVDB/IMDb pelo `findByExternalIds`; nome sozinho nunca autoriza usar o logo.
  Sem vínculo, IDs, correspondência, imagem ou rede, mantém o texto.
- Cache de resultados positivos/negativos por instância autenticada da fonte,
  tipo/ID e conjunto de conexões do perfil, até dez minutos. Troca de conexões
  invalida a consulta; widget não exibe resultado da requisição anterior enquanto
  uma nova consulta está pendente. Nenhuma chave de API ou URL de mídia embutida.
- Player conserva altura natural do texto quando não há logo e continua abrindo
  o seletor de episódios pelo título; o logo confirmado usa o cliente Jellyfin
  correto para imagem/autenticação, sem trocar a fonte da reprodução.
- **15 testes direcionados aprovados**: resolvedor (prioridade, match, ausência,
  cache, retirada de conexões), episódios/player, encaixe e golden Jellyfin.
- **23 testes adicionais aprovados**: componente de logo/imagens otimizadas,
  resolvedor e episódios, incluindo título provisório durante a carga da imagem.
  `ClearLogoImage` ganhou um placeholder opcional; o padrão dos demais consumidores
  não muda. Portão completo: **393 aprovados, 3 ignorados**, mais **8 aprovados
  com Impeller**.
- Código: `ae1d90e960176853c0459628e522e912d1b7f88b` (sem skip ci).
- [Run verde 40190335242](https://github.com/CaioGuerras/heisuca/actions/runs/40190335242), `success`.
- [APK 2.0.22+23](https://github.com/CaioGuerras/heisuca/actions/runs/40190335242/artifacts/12597877876).
- Artifact: 51.134.205 bytes, SHA-256 `68838050e6826f6dcc304c53f617dc8c99b74a78d947445a5962fcf0ce18a010`.
- Pacote/providers conferidos; mesma assinatura SHA-256 `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
- Não testado em aparelho nem com servidores reais. Fixtures HTTP comprovam a
  decisão/cliente/caminho, não o download visual do logo real de Ranma nem a fluidez.

## Etapa E — 2.0.23+24 — concluída no CI

- “Adicionar a …”, “Escolha uma fonte” e a fonte atual em Você usam componentes
  Heisuca: Sora/Inter, paleta do tema, áreas de toque generosas e marca própria de
  fonte (três caminhos que chegam à origem). Retirados ListTile, ícones de hardware,
  cartões/bordas genéricos e palavras visíveis “Conectado/Offline” dessas áreas.
- Servidor e tipo aparecem na linha; status só por bolinha, com rótulo TalkBack:
  verde on-line, âmbar conectando, cinza fora do ar, vermelho erro de acesso.
  O cabeçalho de Você também mantém nome/tipo com o mesmo sinal acessível.
- Reconexão vem da tarefa real do gerenciador. Um stream de atividade separado
  atualiza os sinais sem falsear o status de saúde e sem recarregar bibliotecas
  a cada início/fim de tarefa. O tipo Plex continua conhecido quando a conexão
  salva ainda não tem cliente on-line. Bind inicial usa o estado real do perfil.
- Mantidos os fluxos de autenticação Plex/Jellyfin/Emby, vínculo ao perfil, conexão
  emprestada com PIN, espera do rebind e persistência/isolamento da seleção.
  Modo infantil continua sem acesso à troca de fonte/perfis por esse caminho.
- Busca real (`SearchScreen`, usada pela navegação): origem em cada título/pessoa,
  nome quando única, “2 fontes” (ou N) quando há servidores distintos. Versões no
  mesmo servidor contam uma vez; respeita fontes visíveis no perfil. Biblioteca
  continua na mesma linha quando relevante. Cor de texto da nova origem sem a
  redução de opacidade anterior; origem também no rótulo de acessibilidade.
- Registro da busca agora retira associação antiga de um título/pessoa que a
  consulta nova só encontrou numa fonte; evita manter “2 fontes” desatualizado.
  Busca, ranking e agrupamento continuam unificados, sem duplicar cartões.
- **58 testes direcionados aprovados**: fontes, seleção/rebind, autenticadores,
  navegação D-pad, pessoa/busca, agrupamento e progresso de conexão.
- **83 aprovados**: gerenciador e provider de servidores (incluindo ciclo de vida,
  troca de clientes, reconexão e status). O teste novo confirma que “conectando”
  não dispara snapshot de saúde falso; temas claro/escuro com texto 2× e semântica.
- Capturas sintéticas Flutter/Linux, 412×914, PNG a 2×, fontes Sora/Inter e ícones
  carregados: `docs/evidencias/e_fontes_{adicionar,escolher}_{isis,heitor}.png`.
  Conferidas visualmente. A captura de escolher mostra o componente em uma página
  de prévia, sem o scrim da rota modal; nomes/estados são fixtures, não servidores
  consultados. Não são evidência de teste em aparelho.
- Testes antigos de badges/linha de biblioteca foram ajustados ao sinal próprio e
  ao separador novo. D-pad agora verifica os três destinos efetivamente alcançados,
  em vez de contar uma classe de wrapper que saiu do desenho.
- **28 testes finais aprovados** após o ajuste de cor/origem da busca. A análise dos
  arquivos tocados terminou sem erro/aviso (13 infos de estilo já existentes).
- Portão completo: **397 aprovados, 3 ignorados**, mais **8 aprovados com Impeller**.
- Código: `5eb816e791c5b8e40f51c623224617a3fecd698e` (sem skip ci).
- [Run verde 40193402429](https://github.com/CaioGuerras/heisuca/actions/runs/40193402429), `success`.
- [APK 2.0.23+24](https://github.com/CaioGuerras/heisuca/actions/runs/40193402429/artifacts/12598649958).
- Artifact: 51.140.156 bytes, SHA-256 `e3d791297faefa8cba795498d996af0a9ceb7aae4e32bc28665d176a8bc7732b`.
- Pacote/providers conferidos; mesma assinatura SHA-256 `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
- Não testado em aparelho, TalkBack real, servidor real, teclado/controle físico,
  login real ou resposta de rede real. A Início Jellyfin não foi redesenhada.

## Etapa F — 2.0.24+25 — concluída no CI

- Retirada a implementação manual `_CgflixPredictiveBack`. O builder da marca agora
  herda `PredictiveBackPageTransitionsBuilder` e delega a ele toda a transição/gesto;
  só aplica a cor da marca e o portão de movimento reduzido. A duração normal vem
  do Flutter; no aparelho reduzido é zero. Android já tinha o opt-in no manifesto
  e `main.dart` já chama `cgflixEnableEdgeToEdge`; ambos foram conferidos.
- Ficha, abertura infantil, sessão/login, tocador de música e detalhe de TV passam
  por `MaterialPageRoute`. Não há `PageRouteBuilder` no código do app. O helper de
  sessão conserva `opaque=false`, exigido pela composição anterior, por uma subclasse
  Material que não implementa animação nem gesto próprios.
- Vídeo usa rota Material, textura ao vivo (`allowSnapshotting=false`) e tema escuro
  também em volta da transição, em vez de eliminar a animação para evitar branco.
  A **substituição de um vídeo por outro dentro do player** continua imediata:
  é transferência de dono do canal nativo, não uma nova tela; o anterior tem de
  desmontar antes do próximo. A entrada normal e a saída para o acervo usam o tema.
  Os testes que recusam dois donos simultâneos continuaram passando.
- O player não desativa mais swipe-back o tempo todo por causa da régua. No celular,
  sem folha/painel, aviso ou confirmação de convidado, aceita o gesto oficial.
  Painel/folha fecham antes; confirmações de convidado continuam necessárias. A saída
  direta do celular com os controles visíveis foi preservada; TV/desktop conservam
  a navegação de controles já existente. Nenhuma transmissão para TV foi criada.
- Pop confirmado fecha produtores sincronicamente e inicia a limpeza do dono
  capturado, sem prender o pop ao retorno nativo; cancelamento não pausa. A limpeza
  continua acompanhada pela aposentadoria existente. Botões/TV e confirmações ainda
  têm o orçamento de limpeza de 1 s, seguido da transição oficial. Repetição não
  duplica pausa/dispose. Retirada de um player não remove uma rota que o cobre.
- Régua/botões inferiores respeitam `SafeArea` com `systemGestureInsets` como mínimo,
  incluindo paisagem. Não se bloqueia a borda inteira do sistema para arrastar a régua.
- Abas: `FadeThroughTransition` do pacote oficial Flutter `animations` **2.2.0**
  (`flutter/packages`, BSD-3-Clause, incluído pelo mecanismo de licenças do build).
  A restrição 2.x mantém a API Material usada pelo app. Estados ficam montados;
  controladores estáveis por chave conservam o quadro em trocas rápidas e retornos
  durante a saída. Abas ocultas não recebem toque, semântica nem tickers do conteúdo.
- Prova antes/depois da interrupção: teste de toque rápido falhou com opacidade
  **1,0** de uma aba que ainda estava invisível (esperado 0); passou após separar
  os controladores por aba. O teste permanece. Testes por quadro conferem saída,
  passagem, entrada com escala e ausência de deslocamento horizontal.
- Tokens M3: abas/utilitários `Durations.medium2` + `Easing.standard`; folhas
  `medium4/short4` + `emphasizedDecelerate/emphasizedAccelerate`. Movimento reduzido
  (aparelho/sistema) desliga os efeitos, inclusive o indicador da pílula.
- **166 testes direcionados aprovados, 1 captura opcional ignorada**: rotas, música,
  dono nativo, folhas e controles. **23 aprovados** após ajustar as verificações de
  falha/recarga à duração oficial; não se presume descarte no mesmo frame do pop.
  Os testes verificam início da saída dentro do orçamento e depois seu término.
- **18 aprovados** no último ajuste: painel fecha sem pausar, gesto do player cancela
  sem pausar e confirma apesar de pausa nativa pendente (duas bordas), aba interrompida,
  ficha real com gesto por esquerda/direita, cancelamento/commit, aparelho reduzido e
  preferência do sistema. Eventos usam o canal `flutter/backgesture`, não drag no conteúdo.
- **252 testes de vídeo aprovados**, repetidos com o último ajuste já fixado.
- Portão completo: **408 aprovados, 3 ignorados**, mais **8 aprovados com Impeller**.
  Commit/run/APK aguardando CI.
- Não testado: aparelho, gesto físico Android/OEM, textura real mpv/Exo durante a
  transição, TV/controle físico, fluidez/FPS e comportamento visual com servidor real.
  Provas são Flutter/Linux + canais controlados. Não se afirma aprovação física.
  A composição e as duas capturas de regressão da Início Jellyfin foram preservadas.
- Repetição final do portão após congelar o código: **408 aprovados, 3 ignorados +
  8 Impeller aprovados**. G–M ainda não iniciadas; na L incluir também a retirada
  das traduções Discord que restaram em i18n, conforme a continuação pedida por Caio.

- Complemento da F antes de avançar: o portão passa a incluir também
  `player_route_exit_test.dart` e `video_player_navigation_test.dart`, para que
  cancelamento/commit e a exclusão de dois donos nativos sejam verificados no CI
  das etapas seguintes. Mesma versão da etapa; o primeiro run da F é substituído
  pelo run deste complemento, sem marcar o run cancelado como aprovado.
- Portão ampliado da F: **423 aprovados, 3 ignorados + 8 Impeller aprovados**,
  incluindo os dois arquivos do player adicionados ao CI. Primeiro commit de código:
  `96d3904797d0abd0283da61b3011fecb5813af53`; run inicial `40199848233` substituído
  pelo complemento de cobertura. Não avançar à G até o run do complemento ficar verde.
- **Fechamento (Claude, 25/10, depois do limite de uso do Codex):** run do complemento
  [40200689682](https://github.com/CaioGuerras/heisuca/actions/runs/40200689682) `success` em `0d8d76a`.
  Artifact 12601943900 (51.143.036 bytes); APK 98.605.838 bytes, SHA-256
  `196b6e97bc46892365fd0bf3018aa5c5ea5fe454a3d1732682fdc2b49eded5a8`; assinatura v2 com o mesmo certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`. Publicado em
  `https://heisuca.docaio.com.br/pacotes/heisuca-2.0.24-teste.apk` (download conferido pelo SHA-256).
- Conferência C–F (Claude): runs C `40188133608`, D `40190335242`, E `40193402429`, F `40200689682` verdes; o run
  `40199848233` (cancelado) foi substituído. Vínculo Plex↔Jellyfin lido só dos feeds do servidor (`plex` em
  `emalta/embreve.json`), sem nome de servidor fixo. G–M seguem com o Codex; depois a etapa N
  (`docs/RETORNO_CAIO_2026-10-25_TARDE.md`).

## Etapa G — modo infantil — 2.0.25+26 (em validação)

- Retomada sobre `66d45a5`, após pull dos documentos do Claude. F permanece encerrada
  no run `40200689682`; não foi refeita.
- Causa do campo invisível: a criação trocava a paleta de fundo, mas herdava o tema
  escuro do responsável, mudando apenas `primary`. Agora aplica o tema infantil
  completo, o mesmo usado quando o perfil está ativo. Teste antes: contraste do
  rótulo **1,071:1 (Ichigo)** e **1,079:1 (Sorairo)**, abaixo de 4,5:1; falhou nos dois.
  Depois: os dois testes passam, antes de tocar no campo, partindo de tema escuro.
- Foto em círculo na criação e edição, com um componente comum. A abertura recebe
  a foto já salva no perfil, tanto no primeiro acesso quanto no retorno ao modo
  infantil. Decodificação limitada ao tamanho físico exibido. Só aceita URI local;
  sem foto, com URI inválida/remota ou erro de leitura, usa a assinatura infantil.
- Abertura também respeita `DevicePerformance.isReduced`, além da preferência do
  sistema. Tema infantil escuro continua fora desta etapa.
- **13 testes infantis aprovados, 1 captura opcional ignorada**: imagem local
  efetivamente decodificada nos três destinos, recorte circular, origem do arquivo,
  semântica, rejeição de imagem remota e contraste dos dois temas.
- Portão completo e Actions: em andamento; preencher commit, run, artifact,
  SHA-256 do APK e certificado depois de conferir o resultado real.
- Não testado em aparelho: seletor de fotos do Android, persistência após reiniciar,
  troca de sessão com servidor real, TalkBack físico e aprovação visual do Caio.
  Nenhuma alteração na Início do Jellyfin.
- Portão local final: **427 aprovados, 3 ignorados + 8 Impeller aprovados**,
  `APROVADO: análise e testes concluídos.` A prova da foto inclui o `RawImage`
  decodificado, não apenas a presença do widget. Registro do CI segue após o push.
- Código da G: `cf884dd04f072680f56145d56a859c7319dd01df` (sem `[skip ci]`),
  já enviado ao ramo único. Run pendente:
  [40211659360](https://github.com/CaioGuerras/heisuca/actions/runs/40211659360).
  **Ponto de retomada:** aguardar esse run, conferir pacote/certificado e SHA-256
  do APK, registrar o resultado; só então iniciar H (próxima 2.0.26+27).
  H–O ainda não iniciadas. Na L remover Sentry inteiro e traduções Discord;
  N/O seguem o handoff atualizado pelo Claude, inclusive changelog manual.
- Primeiro run da G **verde** em `cf884dd`:
  [40211659360](https://github.com/CaioGuerras/heisuca/actions/runs/40211659360),
  [artifact 12606780964](https://github.com/CaioGuerras/heisuca/actions/runs/40211659360/artifacts/12606780964),
  ZIP 51.148.225 bytes, SHA-256 do **ZIP**
  `6cea1117047045aef84b859fc274cccc6a61eb639c8b59710acc997de2a9be3d`.
  O CI conferiu APK 98.605.838 bytes, pacote `app.heisuca.player.teste.home`,
  nome Heisuca Teste e certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
- Limite encontrado na conferência local: o proxy recusa o CONNECT do endereço
  Azure Blob para o qual o GitHub redireciona o artifact (403), apesar da política
  HTTP constar como irrestrita. CLI e API retornaram o mesmo bloqueio; não houve
  download do APK nem se confundiu hash do ZIP com hash do APK.
- Complemento da mesma G/versão: a validação do APK passa a imprimir também seu
  SHA-256 diretamente no CI, junto das conferências reais de pacote e assinatura.
  Isso permite registrar o hash em todas as etapas sem depender do download local.
  Aguardar o run do complemento antes de H. Nenhuma mudança adicional na interface.
- Documentos da O recebidos por pull em `b7f1678`: fontes agora em
  `docs/pesquisa_rodada2/`; o caminho ausente foi resolvido pelo Caio.
- Complemento: manifesto fonte e compilação sintática Python aprovados; portão
  local novamente **427 aprovados, 3 ignorados + 8 Impeller aprovados**. O hash é
  calculado por `hashlib.file_digest` sobre o mesmo APK conferido por apksigner/aapt.
- **Retomada atualizada da G:** complemento `157327c6e33cebadf5245350a460740974470cb3`,
  run [40213852821](https://github.com/CaioGuerras/heisuca/actions/runs/40213852821)
  pendente. Aguardar verde e ler no log do validador o SHA-256 do APK e certificado;
  registrar artifact/metadados desse run. G segue 2.0.25+26; H–O não iniciadas.
- **G encerrada no CI — 2.0.25+26:** complemento
  `157327c6e33cebadf5245350a460740974470cb3`, run
  [40213852821](https://github.com/CaioGuerras/heisuca/actions/runs/40213852821)
  observado como `completed/success`. APK:
  [artifact 12607098715](https://github.com/CaioGuerras/heisuca/actions/runs/40213852821/artifacts/12607098715).
  ZIP 51.148.383 bytes, SHA-256
  `53d44bcc66342f26e4d4fa2f1f1dcffc13c390b29b52084a58db921d965f360d`.
  **APK real:** 98.605.838 bytes, SHA-256
  `f8a05ceb5a2f41064d5c5e5f485ca6f15932c8dfc7466ee7333e75cfb590ec8f`.
  Pacote `app.heisuca.player.teste.home`, nome Heisuca Teste, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  Hash, pacote e assinatura conferidos no log do validador sobre o APK construído;
  o download local permanece indisponível pelo bloqueio do proxy. Limites de
  aparelho continuam os descritos acima. Próxima etapa: H, 2.0.26+27.
