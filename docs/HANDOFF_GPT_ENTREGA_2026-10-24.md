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

## Etapa H — medidor no popup — 2.0.26+27 (em validação)

- Medidor integrado ao caminho real Configurações › Aparelho reconhecido › Ver
  funções ativas. Retirados `HeisucaDeviceScreen` e a entrada "Este aparelho" do
  menu Você. O popup usa Sora/Inter, paleta do tema e três faixas discretas.
- Lê a política existente (`DevicePerformance.isReduced/isFlagshipHardware`),
  sem alterar os critérios, preferências, caches nem a reprodução. Apresenta
  **Reduzido / Padrão / Topo de linha**, como a decisão atual da N3 pede também
  para a H. O teste com 3,6 GiB mostra Padrão; o de 7,4 GiB mostra Topo de linha.
  Memória desconhecida não recebe selo de hardware de topo. "Medir fluidez" fica
  para a N; estes níveis não são resultado de uma medição de quadros.
- Texto principal simples, motivo do nível e RAM quando informada. Cache,
  processo, renderizador, frequência, preferência e decodificação ficam em
  "Detalhes técnicos", recolhidos inicialmente. HDR/DV não são prometidos pelo
  reconhecimento do aparelho. Reduzir movimento do sistema é distinguido do nível.
- Prova antes/depois: teste pelo botão real, com resposta do canal nativo
  controlada, falhou no popup anterior por não encontrar "Padrão"; passa no novo,
  abrindo detalhes, rolando até Fechar e retornando às configurações. A primeira
  tentativa sem controlar o canal só observou espera assíncrona, e **não** foi
  usada como evidência da ausência do medidor.
- **21 testes direcionados aprovados**, incluindo os três níveis, dados ausentes,
  retirada da entrada no menu, detalhes recolhidos e popup claro/escuro em tela
  320×568 com texto em dobro. Expansão não cria animação no modo reduzido; a
  transição do diálogo usa os tokens comuns e duração zero quando necessário.
- Portão completo em andamento; commit/run/artifact/hash serão registrados após
  os resultados reais. Não testado em aparelho: Tab A9/Edge, TalkBack físico,
  informações nativas reais e aprovação visual do Caio. Início Jellyfin preservada.
- Portão local completo da H: **433 aprovados, 3 ignorados + 8 Impeller
  aprovados**, `APROVADO: análise e testes concluídos.`
- **Ponto de retomada H:** código enviado em
  `ee4af889a916ea50dab4321a0bee9f2843a50ccd` (sem `[skip ci]`), run
  [40216216038](https://github.com/CaioGuerras/heisuca/actions/runs/40216216038)
  pendente. Aguardar `completed/success`, conferir no log do validador o pacote,
  certificado e SHA-256 do APK, obter os metadados do artifact e registrar.
  Só então iniciar I (próxima 2.0.27+28). I–O ainda não iniciadas.
- **H encerrada no CI — 2.0.26+27:** código
  `ee4af889a916ea50dab4321a0bee9f2843a50ccd`, run
  [40216216038](https://github.com/CaioGuerras/heisuca/actions/runs/40216216038)
  observado como `completed/success`. APK:
  [artifact 12607964347](https://github.com/CaioGuerras/heisuca/actions/runs/40216216038/artifacts/12607964347).
  ZIP 51.149.443 bytes, SHA-256
  `8f1f956c8256b72b96eb87a67404fe6d56b6ba0c8d3a70b5be7f3de266ac03f2`.
  **APK real:** 98.605.930 bytes, SHA-256
  `d33d1946fbe12cd5b03b5f84378ec6f1a272ed943ab5ef71bc5e4b00c4b7eb14`.
  Pacote `app.heisuca.player.teste.home`, nome Heisuca Teste; certificado conferido
  no validador sobre o APK:
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  Mesma assinatura da F/G. Conferência pelo CI; download local segue bloqueado
  pelo proxy. Não testado em aparelho nos termos acima. Próxima: I, 2.0.27+28.

## Etapa I — Dicas atuais — 2.0.27+28 (em validação)

- Nova orientação de navegação com Início, Biblioteca, Baixados e Você, conferidos
  nos destinos reais da pílula. Downloads agora apontam para Baixados na barra
  inferior e usam o rótulo real "Apagar baixados já assistidos".
- Conta: caminho Você › Conta › Minha conta: foto e senha. O código real oferece
  essa tela para Jellyfin; a dica deixa essa condição explícita e orienta a
  conta Plex pelo site plex.tv, sem prometer edição no app para as duas fontes.
- Uma só dica de TV: nossos apps Samsung/LG, opções compatíveis no Fire TV,
  Google TV/Android TV, Roku e Apple TV; Quick Connect pelo site do Jellyfin,
  plex.tv/link para Plex e espelhamento pelo sistema do celular/TV. Saiu a dica
  duplicada "Entrar na TV" e a expressão "TV box". Nenhuma transmissão criada.
- Ícones continuam Material Symbols. Não se alteraram telas nem rotas: as
  mudanças são de conteúdo. Qualidade deixou de prometer que qualquer vídeo
  sempre toca como original: orienta a preferência Original e uso de Wi-Fi.
- **7 testes existentes das Dicas aprovados**: texto curto sem jargão, lista,
  abrir/fechar ajuda, tema claro e dica dos gestos (toque, timer e movimento
  reduzido). Ajustada a expectativa antiga "Dicas do CGFLIX" para a marca atual
  já usada pela tela. Esse arquivo passa a integrar o portão obrigatório do CI.
- Portão completo em andamento; registrar commit/run/artifact e hashes após
  conferir. Não testado em aparelho: login real por código, apps de cada TV,
  espelhamento e leitura com TalkBack físico. Início Jellyfin preservada.
- Portão local completo da I: **440 aprovados, 3 ignorados + 8 Impeller
  aprovados**, `APROVADO: análise e testes concluídos.`
- **Ponto de retomada I:** código enviado em
  `c5861f871e8c2691e1ae6255adc2cd2e72400a07` (sem `[skip ci]`), run
  [40218628281](https://github.com/CaioGuerras/heisuca/actions/runs/40218628281)
  pendente. Aguardar `completed/success`, ler pacote/certificado/SHA-256 do APK
  no log do validador, registrar metadados do artifact. Só então iniciar J,
  próxima 2.0.28+29. J–O ainda não iniciadas.
- **I encerrada no CI — 2.0.27+28:** código
  `c5861f871e8c2691e1ae6255adc2cd2e72400a07`, run
  [40218628281](https://github.com/CaioGuerras/heisuca/actions/runs/40218628281)
  observado como `completed/success`. APK:
  [artifact 12608852577](https://github.com/CaioGuerras/heisuca/actions/runs/40218628281/artifacts/12608852577).
  ZIP 51.146.926 bytes, SHA-256
  `f278d83ee68d86e51f5371fcd74e9218cb70f5aa33458859767e6eea508c37b4`.
  **APK real:** 98.602.954 bytes, SHA-256
  `60a98e3295cb9846fedecf800ce0f348e10b7a9350e155820b39919b877cc277`.
  Pacote `app.heisuca.player.teste.home`, nome Heisuca Teste e certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`,
  conferidos no validador do APK. Mesma assinatura da F/G/H. Download local
  continua indisponível pelo proxy; limites físicos permanecem os acima.
  Próxima etapa: J, 2.0.28+29.

## Etapa J — testes antigos e ícone escolhido — 2.0.28+29 (em validação)

- Reproduzidos os 16 testes da lista antiga: 1 aprovado, 16 falhando no arquivo
  de navegação. Motivo de cada caso e substituição em
  `docs/J_TESTES_ANTIGOS_2026-10-25.md`. Testes passaram a usar o chrome real
  aprovado; o menu mantido no offline conserva testes de despachantes/retorno.
- Bug real demonstrado no chrome atual: alvo de toque da marca com **28 dp**,
  seis falhas contra mínimo de 48 dp. Apenas a área invisível passou a 48 dp;
  SVG continua com 28 dp, na mesma posição. **17 testes de navegação + 1 golden
  da Home aprovados**; as capturas parada/rolada da Início são byte a byte as
  mesmas. Nenhuma composição visual, recorte ou fileira da Home foi alterada.
- Variante **01_relevo** aplicada aos recursos de launcher Shikkoku, mantendo os
  gradientes exatos do SVG escolhido. Mesmo tratamento nos demais temas com as
  cores canônicas. Fundos adaptativos sangrados, sem assar a máscara no primeiro
  plano; selo inteiro na zona segura. Não muda applicationId nem aliases.
- Monocromático oficial preservado, sem relevo. Ícones de notificação usam a
  geometria gótica pequena, 24 dp em todas as densidades. O recurso alternativo
  `ic_stat_notification` também foi atualizado para essa marca.
- Novo gerador usa somente a variante escolhida, os SVGs `assets/heisuca/icone_*`
  e os vetores oficiais em `docs/marca/android/`. Substitui o script antigo que
  recriava notificações pelo asset do Plezy. Não usa `cgflix-brand`.
- **95 recursos gerados e conferidos por `--verify`**; `aapt2 compile` aceitou o
  conjunto de recursos. Inspecionada a prévia local `docs/evidencias/j_icones_48px.png`:
  SVG, composição do XML sob máscara circular e mono em 48 px, aviso em 24 px.
  Fonte SVG da prévia ao lado. São renderizações locais, não captura de aparelho.
- O arquivo de navegação passa a integrar o portão obrigatório. Portão completo
  em andamento; código ainda sem commit da J, sem run da J. G/H/I encerradas
  nos runs registrados acima. K–O não iniciadas.
- Não testado em aparelho: atualização/caches do launcher, ícones temáticos de
  fabricantes, TalkBack físico e instalação Android. Não se afirma aprovação
  física; pacote e assinatura do APK serão conferidos no CI após o push.
- Portão completo da J: **457 aprovados, 3 ignorados + 8 Impeller aprovados**,
  `APROVADO: análise e testes concluídos.` Capturas aprovadas da Home preservadas.
- **Ponto de retomada J:** código enviado em
  `dce6e0239c17a53de81a9fb547b24583915154d0` (sem `[skip ci]`), run
  [40221928427](https://github.com/CaioGuerras/heisuca/actions/runs/40221928427)
  pendente. Aguardar `completed/success`, conferir pacote/certificado/SHA-256 do
  APK no validador e os metadados do artifact, registrar. Só então iniciar K,
  próxima 2.0.29+30. K–O ainda não iniciadas. `aapt2 compile` repetido sobre os
  recursos finais também passou; árvore de código enviada integralmente.
- **J encerrada no CI — 2.0.28+29:** código
  `dce6e0239c17a53de81a9fb547b24583915154d0`, run
  [40221928427](https://github.com/CaioGuerras/heisuca/actions/runs/40221928427)
  observado como `completed/success`. APK:
  [artifact 12610003513](https://github.com/CaioGuerras/heisuca/actions/runs/40221928427/artifacts/12610003513).
  ZIP 51.176.149 bytes, SHA-256
  `dfc5504a120fd129ee2fbc718978438db0664950324afec78e4ef378a6787b3a`.
  **APK real:** 98.633.122 bytes, SHA-256
  `b12b7666cedcec200b6fb439a6850bd0bb176bc8fe380b6efc58b19bca9225d7`.
  Pacote `app.heisuca.player.teste.home`, nome Heisuca Teste; certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`
  conferido no APK pelo validador, mesmo da F/G/H/I. Download local segue
  bloqueado pelo proxy. Limites de aparelho permanecem os acima.
  Próxima: K, 2.0.29+30.

## Etapa K — bancada Android — 2.0.29+30 — concluída no CI

- Implementação e limites em `docs/BANCADA_ANDROID_2026-10-25.md`. Workflow
  independente do APK, emulador API 35/x86_64; autenticação/app/player reais,
  capturas nativas e quatro vídeos por fase/orientação, sem gravar credenciais.
- Prioriza conta dedicada, faz rodízio nas livres, nunca usa `-kids`. Somente
  filme sem histórico, reset oficial e comparação posterior de todos os campos
  relevantes. Perfil local anônimo; perfil do servidor não é alterado. Limpeza
  encerra só as duas sessões criadas pela bancada. Logs redigidos antes de gravar.
- **8 testes de segurança Python aprovados**, **1 teste do binding aprovado**;
  análise da integração/driver sem erros. Portão completo em andamento.
- Código ainda sem commit/run da K. Execução Android com segredos reais **ainda
  não ocorreu**. Não foi provada restauração no servidor real; a bancada só poderá
  ficar verde depois dessa conferência. Não testado em aparelho, Android 17,
  motor alternativo, fluidez física nem perda completa do runner.
- G/H/I/J encerradas nos runs acima. L–O não iniciadas. Próxima ação: concluir
  portão, commit/push da K, conferir workflow do APK e workflow da bancada.
- Portão local final K: **8 testes Python + 458 Flutter aprovados, 3 ignorados,
  mais 8 Impeller aprovados**, análise incluindo integração e driver, `APROVADO`.
  YAML carregado e inputs conferidos no action fixado por SHA de commit.
- APK da bancada é compilado antes do emulador, sem credenciais. Configuração
  chega por stdin ao armazenamento privado do app; não há defines secretos nem
  APK com dados de conta. Isso também reduz o pico de memória do job.
- **Ponto de retomada K:** código enviado em
  `407d02a26033a1f09c24a7da05c43f15dd400595` (sem `[skip ci]`). Runs pendentes:
  [APK 40227167125](https://github.com/CaioGuerras/heisuca/actions/runs/40227167125)
  e [bancada 40227167082](https://github.com/CaioGuerras/heisuca/actions/runs/40227167082).
  Aguardar e inspecionar ambos: APK verde com pacote/certificado/SHA-256/artifact;
  bancada com capturas/vídeos, quadro nativo/avanço e restauração realmente
  confirmados. Falha de infraestrutura permanece instável, sem marcar verde.
  Falha de produto/harness ou limpeza exige correção/conferência antes de encerrar.
  L–O ainda não iniciadas; próxima versão L 2.0.30+31 quando K estiver resolvida.
- **Correção da K antes de executar contas reais:** leitura do SDK Flutter
  (`integration_test/src/_callback_io.dart`) mostrou que o Android não implementa
  os argumentos de `takeScreenshot` e entrega screenshots ao driver só ao fim.
  O controle ao vivo previsto não seria válido. Run da bancada `40227167082`
  cancelado enquanto ainda estava em **Compilar APK da bancada**, antes de iniciar
  emulador/login. O run do APK `40227167125` é independente e continua sob inspeção.
  Não houve prova de percurso/restauração real nesse run, nem se o marca aprovado.
- Ajuste em andamento: marcos do teste por arquivos privados com confirmação do
  host; `adb` captura a superfície real e confirma parada do vídeo antes de
  permitir digitação privada. Sem conversão da superfície Flutter nem dependência
  de callback tardio. K segue 2.0.29+30; L–O não iniciadas. Próximo commit/run
  deve substituir a bancada cancelada e passar o portão novamente.
- Correção de protocolo implementada: marcos/ACK numerados em arquivos privados,
  publicação atômica; captura e Back por adb enquanto o teste está em execução.
  Login espera parada confirmada da gravação antes de digitar; não usa
  `takeScreenshot`, argumentos Android não suportados nem conversão de superfície.
  Driver básico só recolhe o resultado final. Motor reportado pelo método
  `runtimePlayerType`, incluindo eventual fallback efetivo.
- **13 testes Python aprovados**, incluindo parada antes do ACK, captura inválida
  sem confirmação, Back apenas quando solicitado, marcos inválidos e falha ao
  salvar vídeo sem interromper limpeza. Análise da integração/driver aprovada.
  Run antigo da bancada confirmado `cancelled`; sem autenticação executada.
- Portão após a correção: **458 testes Flutter aprovados, 3 ignorados, 8 Impeller
  aprovados**, análise aprovada e `APROVADO` no script completo. Os testes Python
  foram repetidos após a última alteração: **13 aprovados**. Em falha, o CI mostra
  o fim do log já redigido para permitir diagnóstico sem depender do download.
  Autenticação/capturas/restauração reais ainda aguardam o novo run.
- **Retomada K após corrigir sincronização:** código
  `dbd84d3aa09f60ab4dfdbc4814429c11fabdd1b6`, enviado no ramo autorizado.
  Novos runs: [APK 40228852172](https://github.com/CaioGuerras/heisuca/actions/runs/40228852172)
  e [bancada 40228852177](https://github.com/CaioGuerras/heisuca/actions/runs/40228852177).
  Ambos pendentes de resultado e inspeção; não encerrar K nem iniciar L sem
  resolver o percurso/limpeza (ou documentar instabilidade real de infraestrutura)
  e conferir pacote, assinatura, artifact e SHA-256 do APK verde desse código.
  Versão mantida **2.0.29+30**; L–O não iniciadas.
- **Fechamento da K (Claude, 25–26/10, enquanto o Codex estava sem limite).** Correções na ordem em que a própria
  bancada as revelou; cada commit traz a causa e a prova:
  - `4a797f5`, `b9b7aa7`: runner sem disco ao instalar a imagem do emulador; limpeza ampliada e tolerante.
  - `dfdc773`: `adb install` 600 s; `relatorio.json` passa a trazer `erro`, `erro_restauracao` e `status_percurso`.
  - `b109c34`: `adb exec-out … tee` com stdin nunca recebia o fim da entrada (TimeoutExpired); configuração e ACK em
    base64 no argumento; resposta não-JSON do `cat` tratada como ausente.
  - `6319f8b`, `1802f26`: caso declarado antes de qualquer `await` em `main()`; `app.main()` dentro do caso (o framework
    troca a árvore por "Test starting..."); handles de semântica do app em debug guardados e soltos no fim.
  - `cc5c6ad` **(defeito do app, etapa F)**: `_SessionMaterialRoute` herdava `MaterialPageRoute` com `opaque=false`
    (`assert(opaque)` derruba o debug); agora `PageRoute` + `MaterialRouteTransitionMixin`. Teste novo antes/depois.
  - `ab1892f`: o aviso de falha da sondagem do Jellyfin traz o motivo (endereço trocado por `[endpoint]`).
  - `479b129` **(defeito do app, herdado)**: login com um endereço só passava pela corrida de 2 s ("connect timed out"
    no emulador; também derrubaria 4G fraco); com um candidato usa `jellyfinProbe` (8 s). Teste novo antes/depois.
  - `7d1e1bf` **(defeito do app, 22–23/10)**: `cgflixUseYouTab` usava `Theme.of` no `initState` da MainScreen; agora
    `defaultTargetPlatform` (mesma fonte do tema). Teste novo antes/depois.
  - `495c21a`: Back da bancada fechava o aviso do sistema "Viewing full screen" (marcado como visto antes do teste);
    `flutter drive` desinstalava o app no fim (`--keep-app-running`); o item volta sempre, mesmo se a sessão falhar.
  - `e02fcd5`: `ErrorWidget.builder`/`FlutterError.onError` do app devolvidos no fim do caso.
- **Bancada verde:** [run 40251727025](https://github.com/CaioGuerras/heisuca/actions/runs/40251727025) `success`,
  `relatorio.json` = **aprovado**: 11 passos (01-login … 11-voce), motor **mpv**, `quadroNativo: true`, **+5,7 s** de
  avanço, restauração **confirmada** (progresso, assistido, contagem, data e preferências). 11 PNG nativos e 4 MP4 com
  imagem e duração válidas (ffprobe); capturas conferidas a olho. Conta do rodízio (liberada pelo Caio em 26/10; ele
  limpa resíduos no fim).
- **APK verde do mesmo código:** [run 40251727031](https://github.com/CaioGuerras/heisuca/actions/runs/40251727031),
  artifact 12621890613; APK 98.632.818 bytes, SHA-256
  `d4d8545c667a6c924eef0b4def047d9e475e087754ea37f6feb923d19f21231a`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`. Publicado em
  `https://heisuca.docaio.com.br/pacotes/heisuca-2.0.29-teste.apk` (download conferido). Portão local: APROVADO
  (487 Flutter + 8 Impeller + 14 Python).
- **Observações para depois (não bloqueiam):** no emulador a Início e a Biblioteca ainda não tinham pôsteres no momento
  da captura (rede/emulador lentos) e a captura 07 pegou a ficha no meio da transição; a conta dedicada
  `teste-sem-senha` não foi usada em nenhum run (conferir se existe no segredo e se tem filme livre). Resíduo de testes
  na conta Claudia (Yellow Mirror: contagem/data; 2 aparelhos `sdk_gphone64_x86_64`) fica para o Caio limpar no fim.
- **Próxima:** L (2.0.30+31).

## Etapa L — independência, parte 2 — 2.0.30+31 (em implementação)

- Base atualizada por pull até `e649f9c`; K fechada pelo Claude, sem refazer.
  Preservados cc5c6ad (rota), 479b129 (sondagem única 8 s) e 7d1e1bf
  (navegação sem Theme no initState), com os testes mantidos no portão.
- Namespace Android, referências JVM/JNI, regras R8 e canais próprios mudados
  para `app.heisuca`; `applicationId` permanece `app.heisuca.player.teste.home`
  no ramo de teste e `app.heisuca.player.teste` na outra variante. Pacote Dart
  passa a `heisuca`, com todos os imports ajustados. Assinatura não foi alterada.
- Sentry removido de dependências, inicialização, hooks, ajustes, diagnóstico
  nativo/Dart e ferramentas de upload de símbolos; locks Apple sem o SDK.
  Os diagnósticos continuam locais e compartilháveis pelo usuário. Fila de envio
  retirada; consumo local serializado com gravações, inclusive em concorrência.
- Correção do diagnóstico histórico: na base real `_enableSentry` era false por
  padrão e dependia de define; a preferência true não prova envio dos APKs
  anteriores. Retirada total mantém a independência solicitada, sem alegar envio
  anterior não demonstrado.
- Traduções do Discord e da opção de telemetria retiradas na fonte e regeneradas.
  Textos exibidos trocados para Heisuca. GPL-3.0 completa e aviso de origem ficam
  em Licenças; o crédito separado do Sobre foi retirado. Recursos da marca antiga
  deixam de entrar no bundle. Atualizador não aponta mais para releases do Plezy.
- Chaves históricas de dados locais e `DisplayPreferences.client = 'Plezy'`
  permanecem por compatibilidade dos dados; não representam destinos de rede
  nem marca exibida. Bundle IDs de plataformas Apple não foram alterados.
- Teste novo de independência falhou antes e passou depois; 89 testes direcionados
  e 7 de identidade/rota/navegação passaram. Portão completo em andamento.
  Sem commit/push da L ainda. APK, certificado, hash e bancada ainda não validados.
  M–O não iniciadas; não testado em aparelho físico nem nas plataformas Apple/PC.
- Teste adicional reproduziu concorrência entre consumo e falha nova: arquivo
  preservado, mas registro em memória antigo. Correção mantém também o registro
  mais novo em memória; teste falhou antes e passou depois. Portão repetido sobre
  a implementação final; os 14 testes Python da K permanecem incluídos.
- Validador do APK também exige a Activity no namespace novo e o arquivo da GPL
  completa com aviso do autor original. Mudanças de namespace limitadas ao Android;
  canais das outras plataformas acompanham o Dart. IDs/empacotamento desktop
  mantidos. Sem alteração funcional das três correções do fechamento da K.
- **Portão final L aprovado:** análise sem erros, **552 Flutter aprovados e 3
  ignorados + 8 Impeller + 14 Python**; `APROVADO` no script completo. Nenhum
  golden da Início foi atualizado. Pacotes, JNI e restauração reais ainda serão
  comprovados pelos dois runs deste código.
- **Ponto de retomada L:** código enviado no commit
  `8f72d6fc73a6cbc647102d485648570dc8606c62`, sem `[skip ci]`.
  [APK 40255564554](https://github.com/CaioGuerras/heisuca/actions/runs/40255564554)
  e [bancada 40255564586](https://github.com/CaioGuerras/heisuca/actions/runs/40255564586)
  estão em execução. Conferir ambos antes de iniciar M: pacote/certificado/hash,
  ausência do Sentry no APK e relatório do percurso/restauração. Versão L 2.0.30+31.
  M–O não iniciadas. K permanece fechada; a ausência de pôsteres e o uso da conta
  dedicada são observações não bloqueantes, conforme autorização de Caio em 26/10.
- Revisão adicional de **todos** os testes encontrou três referências de teste à
  telemetria retirada (duas ao pref e uma à inicialização do reporter). O teste de
  atualização de preferências usa agora o pref dinâmico do Trakt, com a mesma
  propriedade verificada; o teste de fases verifica apenas o registro local.
  Ambos entram no portão, que também analisa a pasta `test` inteira.
- **Validação final do complemento:** análise de todos os testes sem erros,
  **603 Flutter aprovados, 3 ignorados, 8 Impeller e 14 Python**. Script completo
  terminou `APROVADO` com fontes congeladas. Uma execução intermediária foi
  invalidada porque o script foi editado enquanto rodava; não conta como portão.
- Bancada `40255564586` cancelada ainda em **Compilar APK da bancada**, antes do
  emulador/login, para substituir pelo commit final que inclui os testes. Não é
  bancada verde nem falha de infraestrutura. APK anterior será substituído pelo
  run do complemento. Nenhuma mudança funcional adicional no app nem na K.
- **Retomada L (código final):** complemento de testes enviado em
  `f617c2e063a2f4068622bc8872dade3f4d70cb1f` (sem `[skip ci]`), sobre a implementação
  `8f72d6fc73a6cbc647102d485648570dc8606c62`. Aguardar e inspecionar
  [APK 40256320319](https://github.com/CaioGuerras/heisuca/actions/runs/40256320319)
  e [bancada 40256320245](https://github.com/CaioGuerras/heisuca/actions/runs/40256320245).
  Versão **2.0.30+31**, portão local aprovado (603 + 8 + 14). Não iniciar M antes
  de conferir os dois runs, pacote, certificado, hash, GPL e ausência do Sentry.
  L ainda não fechada; M–O não iniciadas. Aparelho físico/Apple/PC não testados.
- **L ainda aberta — falha real da bancada `40256320245`:** compilação passou,
  mas o percurso expirou em **voltar à ficha**, depois de reproduzir o vídeo.
  A restauração foi **confirmada** no log. Não é classificada como infraestrutura
  nem se considera bancada aprovada. Artifact 12622379862 (2.059.193 bytes), ZIP
  SHA-256 `fb2995f330c93a28407017e6cdaae612d441f1fbb1e651224bb095aef2b9d426`.
  APK `40256320319` ainda em compilação. M–O continuam não iniciadas.
- Próxima ação: inspecionar capturas/relatório e reproduzir o estado após Back,
  antes de modificar navegação. Não desfazer cc5c6ad/479b129/7d1e1bf, que permanecem
  intactos. A falha nova não demonstra qual é a causa; não será atribuída ao
  emulador, à rota ou à retirada do Sentry sem evidência.
- **APK L verde e inspecionado**, ainda sem fechar a etapa pela falha da bancada:
  [run 40256320319](https://github.com/CaioGuerras/heisuca/actions/runs/40256320319),
  commit `f617c2e063a2f4068622bc8872dade3f4d70cb1f`, artifact
  [12623397735](https://github.com/CaioGuerras/heisuca/actions/runs/40256320319/artifacts/12623397735).
  Pacote `app.heisuca.player.teste.home`, rótulo Heisuca Teste, 97.070.954 bytes.
  Certificado SHA-256 `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  **SHA-256 do APK:** `fededf324bc037e4b928ed8d45783d55f60ed5697ad146a9f6aead372c0889cb`.
  ZIP do artifact: `552259635aab165427e26394e65205a87174c02782bdfa8f1b20af1f17e534bf`.
  Validador comprovou Activity no namespace novo, GPL/aviso presentes e **zero
  plezy.app/SDK Sentry** nos conteúdos descomprimidos. Testes nativos passaram.
  Instalação sobre o APK anterior em aparelho não foi executada.
- Download do artifact da bancada bloqueado novamente pela rede do ambiente
  (403). Em diagnóstico local: timeout após Back passará a publicar uma captura
  nativa e flags de quais telas estão presentes/visíveis. Não muda a navegação
  nem adiciona espera ao caminho que passa; só registra o estado em falha após
  perfil anonimizado/reprodução, nunca os campos de login preenchidos.
- Portão do diagnóstico aprovado: **603 Flutter + 8 Impeller + 14 Python**,
  3 ignorados, análise incluindo todos os testes sem erros. A instrumentação
  apenas fotografa e registra flags no timeout, depois do mesmo Back e dos
  mesmos 90 s. Nenhum conserto do app foi aplicado sem conhecer o estado real.
- **Ponto de retomada L/diagnóstico:** commit
  `741e7a7b40810dd0f68f16efd7e15fe29e417b78` enviado sem `[skip ci]`, versão 2.0.30+31.
  Novos runs [APK 40258843798](https://github.com/CaioGuerras/heisuca/actions/runs/40258843798)
  e [bancada 40258843944](https://github.com/CaioGuerras/heisuca/actions/runs/40258843944)
  em execução. Se voltar a falhar, ler `BANCADA_RETORNO` no log (flags de telas) e
  `12-falha-retorno.png` no artifact antes de escolher uma correção. APK anterior
  verde/conferido: 40256320319, artifact 12623397735, dados acima.
  **L não fechada; M–O não iniciadas.** Não tratar a falha do retorno como infra.
- **Evidência adicional do Caio:** `06-player.png` do run `40256320245` mostra
  **ANR do Android**: “Heisuca Teste isn't responding”, botões “Close app”/“Wait”,
  sobre o vídeo. Não era menu do player nem aviso de tela cheia. A captura 06 é
  feita pelo host **antes** de injetar Back; o ANR já estava presente nesse ponto.
  Isso não permite atribuir a falha ao pop/dispose sem investigar a cronologia.
- O Caio informou que no run K `40251727025` (`e02fcd5`) a mesma captura tinha só
  vídeo. Comparação em andamento com esse commit: rotas da K preservadas; mudanças
  do player incluem canais/JNI/namespace e retirada dos breadcrumbs Sentry. No
  trecho final disponível no log do Actions há `aimagereader: Waiting for frame
  timed out`, mas **não** consta motivo do ANR. Artifact completo continua 403.
  Foi solicitado o trecho `ANR in ...`/`Reason:`/thread main do `execucao.log`.
  Não classificar como instabilidade sem motivo real do ANR. Diagnóstico em
  execução: bancada `40258843944`, APK `40258843798`; ainda sem resultado.
- Caio confirmou: o execucao.log completo não tem motivo/Reason do ANR (fica no
  system_server). Comparação e cronologia em `docs/ANR_BANCADA_L_2026-10-26.md`.
- **Reexecução verde sem correção do app:** bancada `40258843944`, commit
  `741e7a7b40810dd0f68f16efd7e15fe29e417b78`: mpv/quadro nativo, +3,448 s,
  percurso/restauração aprovados. Artifact 12624527406 (4.116.585 bytes), ZIP
  `7dacb7021c660bdb83aa0ecd932673dfdd1e185d78b2a91a579392896ad54c65`.
  APK do mesmo código verde `40258843798`, artifact
  [12624163181](https://github.com/CaioGuerras/heisuca/actions/runs/40258843798/artifacts/12624163181),
  97.070.954 bytes, pacote `app.heisuca.player.teste.home`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`,
  **SHA-256 APK `836964d54b08c8d586b09c71edca85d33959985073bfea011947be02e5dfde0b`**,
  ZIP `5eaeab94ebbb049975d49cc8fd71806211b61d3067d653bc6af3be312814c477`.
  GPL e ausência de SDK/destino Sentry novamente verificadas no pacote.
- Isso **não demonstra correção nem causa do ANR anterior**. Seguindo a indicação
  do Caio, há coleta nativa em implementação antes da próxima execução: lastanr
  e events/system_server, antes da limpeza; ANR próprio ou coleta indisponível
  impede verde. Sem mudar o app nem marcar infraestrutura sem motivo. L segue
  em validação desse complemento; M–O não iniciadas.
- Portão da coleta nativa aprovado: **603 Flutter, 3 ignorados, 8 Impeller e
  18 Python**; análise sem erros. Os testes Python foram repetidos com stdout
  das simulações oculto, para não confundir ANR de teste com ocorrência real.
  A coleta real ainda será verificada no próximo job Android. Sem correção
  especulativa no player/pop/dispose; a causa do ANR observado segue pendente.
- **Retomada L com coleta nativa:** código
  `2d4785018f04a6ccb1e3e3424108d221aa231a93`, enviado sem `[skip ci]`, versão
  **2.0.30+31**. Aguardar [APK 40261399840](https://github.com/CaioGuerras/heisuca/actions/runs/40261399840)
  e [bancada 40261399848](https://github.com/CaioGuerras/heisuca/actions/runs/40261399848).
  Conferir `Diagnóstico Android` no log: comandos disponíveis e ANR do app; se
  houver ANR, ler o motivo nativo antes de corrigir/classificar. O último par
  verde é 40258843798/40258843944, dados acima. L aguarda validação desse guard;
  **M–O não iniciadas**. ANR do run 40256320245 não tem causa demonstrada nem foi
  classificado como infraestrutura. Sem mudança especulativa no app.
- **Run 40261399848 falhou com ANR nativo confirmado:** coleta disponível
  (`dumpsysCodigo=0`, `logcatCodigo=0`), ANR do pacote detectado, restauração
  confirmada. Motivo: **Input dispatching timed out, 5009 ms esperando
  FocusEvent(hasFocus=true)**. Evento am_anr às 03:10:47; relatório às 03:10:49.
  Mesmo intervalo registra diálogo ANR de `com.google.android.apps.messaging`,
  carga `42.15 / 15.07 / 5.44` e `/proc/pressure/cpu some avg10=91.61`.
  Isso demonstra saturação sistêmica; ainda não fornece a stack main do app.
  Não se considera o app corrigido. Próxima investigação: condições da imagem
  google_apis/boot e traces nativos, sem mexer no pop/dispose por suposição.
- Artifact da falha: 12625117952, 3.007.155 bytes, ZIP SHA-256
  `cb278473763b8dcb729a74b0d2adaa900819fb3a4f786ea9030e8cc4d910d423`.
  APK do mesmo código `2d4785018f04a6ccb1e3e3424108d221aa231a93` verde e conferido
  no run `40261399840`, artifact
  [12625436053](https://github.com/CaioGuerras/heisuca/actions/runs/40261399840/artifacts/12625436053),
  97.070.954 bytes, pacote `app.heisuca.player.teste.home`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 APK `ea5ac4fe76f6c9c8763d8dacd20315ab3e4ae308d461d3d7d0b2fae8ed17c680`,
  ZIP `59c8829124d13b6e795d8eb86a0462029c264d223a704e97eed0013b97e33813`.
  GPL presente, zero SDK/destino Sentry. **L continua aberta; M–O não iniciadas.**
- Experimento da fixture, sem alterar o app: imagem **AOSP default API 35/x86_64**,
  conferida no catálogo oficial (link no diagnóstico). Retira GMS/Mensagens do
  Google da bancada; mantém dispositivo, RAM, renderizador e prazos. Motivo:
  ANRs sistêmicos e pressão CPU 91,61% observados na imagem anterior. Ainda não
  se afirma que isso resolve a ocorrência.
- Coleta de traces de /data/anr habilitada no emulador de teste: conserva só o
  processo do app, dados redigidos e stack main quando disponível. Sem alteração
  de permissão/código do APK. Testes cobrem seleção do processo, redação e falta
  de acesso a trace. **Portão aprovado: 603 Flutter (3 ignorados), 8 Impeller e
  21 Python**, YAML validado. Próximo commit/run confere a hipótese no Android.
- **Retomada L / experimento AOSP:** commit
  `23bffeff9c9e8dc3547dd1fbcac78ac107103dc6`, enviado sem `[skip ci]`, versão
  **2.0.30+31**, portão 603 + 8 + 21 aprovado. Runs em execução:
  [APK 40264419240](https://github.com/CaioGuerras/heisuca/actions/runs/40264419240)
  e [bancada AOSP 40264419251](https://github.com/CaioGuerras/heisuca/actions/runs/40264419251).
  Conferir o diagnóstico nativo, percurso, restauração e APK. Se houver ANR,
  procurar a stack main no log/trace; não supor causa nem desfazer as correções K.
  Último APK verde conferido: 40261399840 (dados acima); último percurso verde:
  40258843944. **L aguarda este experimento; M–O não iniciadas.**
- **Experimento AOSP 40264419251:** compilou e executou, adb root confirmado
  (`uid=0`). Coleta nativa disponível, **anrDoApp=false**, sem ANR registrado;
  mesmo assim expirou em **voltar à ficha**. Restauração confirmada. Portanto
  a saturação/ANR da imagem Google não explica toda a falha do percurso. Não
  classificado como instável nem como aprovado.
- Artifact AOSP 12626502433, 2.015.895 bytes, ZIP
  `7fa3c8597b5a39c001756b0ee35f100c79dc1e9443dac7e38108ea8f65e06c45`.
  APK 40264419240 está verde, ainda falta registrar hash/artifact/certificado.
  Foi solicitado ao Caio o estado `BANCADA_RETORNO`/12-falha-retorno.png, porque
  o download segue 403 e o trecho final de 60 linhas omitiu a flag impressa.
- Ajuste local ainda sem commit: encaminhar a flag do retorno diretamente ao
  log do Actions e preservá-la no resultado JSON do driver. Sem alterar navegação.
  **L continua aberta; M–O não iniciadas.**
- Caio inspecionou o AOSP: player visível, ficha montada fora de cena; captura 12
  mostra **ANR do Quickstep**, não do app. Launcher topResumedActivity, sem janela
  focada, PiP=false; nenhuma Activity do app resumed/focada no dump. A ausência
  de ANR próprio não aprova o retorno. Foco **antes** do Back ainda precisa ser
  medido; o dump posterior não demonstra sozinho quando foi perdido.
- Manifest fonte byte a byte igual a e02fcd5 (hash no diagnóstico); sem mudanças
  de launchMode/taskAffinity/configChanges/PiP. Namespace altera os nomes completos
  da Activity/aliases no APK. A próxima execução retoma **google_apis**, conforme
  solicitado pelo Caio, e registra foco/janela antes/depois de Back, ciclo nativo,
  estado das rotas Flutter e chegada de pop. Não força foco nem envia Back extra.
  Instrumentação local em validação; nenhuma correção especulativa do app.
- **Portão final da instrumentação de foco aprovado:** 603 Flutter (3 ignorados),
  8 Impeller e 27 Python; análise incluindo integração/driver/testes sem erros.
  Teste do host verifica que o estado anterior é coletado antes de injetar Back
  e o posterior depois. Não altera a decisão de navegação nem o prazo de 90 s.
- APK AOSP-código `23bffef` conferido no run verde `40264419240`, artifact
  [12626067706](https://github.com/CaioGuerras/heisuca/actions/runs/40264419240/artifacts/12626067706),
  97.070.954 bytes, pacote `app.heisuca.player.teste.home`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 APK `e0c1cf5ed0952b2718260b69384c708b3cc8ea0a517bc050b99650f88b19a4ee`,
  ZIP `0d531c1aee012da9a053a0db3e2f7308f3a3295ba8cb6a376535b18617db1533`.
  GPL e ausência de SDK/destino Sentry verificadas. Isso não fecha a L: a bancada
  correspondente falhou no retorno, sem ANR do app e com ANR do launcher.
- **Retomada L / foco antes do Back:** código enviado em
  `43ad4df8cd74fc6f611553cfb70ae6444f9b3014`, sem `[skip ci]`, versão **2.0.30+31**.
  Novos runs [APK 40269817723](https://github.com/CaioGuerras/heisuca/actions/runs/40269817723)
  e [bancada google_apis 40269817747](https://github.com/CaioGuerras/heisuca/actions/runs/40269817747).
  Ler diretamente no log `BANCADA_MARCO`, `BANCADA_FOCO_ANTES/DEPOIS/FALHA`,
  `BANCADA_ROTAS_ANTES`, eventual `BANCADA_POP_NATIVO_RECEBIDO`, ciclo de vida e
  diagnóstico Android. Flags também ficam no JSON do driver. Se o foco já for
  launcher antes do comando, investigar sua perda; não forçar foreground para
  fazer passar. **L ainda aberta; M–O não iniciadas.** K preservada.

- **L entregue / validação atual verde, 26/10 às 04:55 UTC:** código
  `43ad4df8cd74fc6f611553cfb70ae6444f9b3014`, versão **2.0.30+31**.
  [APK 40269817723](https://github.com/CaioGuerras/heisuca/actions/runs/40269817723)
  e [bancada 40269817747](https://github.com/CaioGuerras/heisuca/actions/runs/40269817747)
  inspecionados, ambos **success**. Portão: 603 Flutter (3 ignorados), 8 Impeller,
  27 Python, análise e testes nativos do pipeline aprovados.
- Bancada google_apis: percurso completo até 11-voce, mpv com quadro nativo e
  avanço de **3,22 s**; restauração confirmada. Antes/depois do Back em 06-player,
  **topResumedActivity, mFocusedApp e mCurrentFocus eram do Heisuca**. Flutter
  resumed; rota atual, não inicial, popDisposition=pop; Navigator local pode
  voltar, raiz não (pilha interna). Evento `BANCADA_POP_NATIVO_RECEBIDO` às
  04:53:29; ficha capturada às 04:53:38. Sem forçar foco ou repetir Back do player.
  Diagnóstico disponível, **anrDoApp=false**. Artifact da bancada
  [12628946907](https://github.com/CaioGuerras/heisuca/actions/runs/40269817747/artifacts/12628946907),
  ZIP 3.994.335 bytes, SHA-256
  `fc1443299726501eec0aff2eca5a878dfb69782cbc6b9af5e31746241b0013eb`.
- APK [12628567515](https://github.com/CaioGuerras/heisuca/actions/runs/40269817723/artifacts/12628567515):
  pacote `app.heisuca.player.teste.home`, Heisuca Teste, APK 97.070.954 bytes;
  certificado `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 **do APK** `28ff81a03b04926efab04b21406248f88dbde62c3e79b4d0e6f557da683ba4ad`;
  ZIP 50.362.999 bytes, SHA-256
  `876feb7f95d420da9557604582d72297a27ef5b33a309b5f81cc7980ece0a884`.
  Validador inspecionou manifesto, providers, GPL e ausência de plezy.app/SDK Sentry.
- **Limite explícito:** esta execução não reproduziu os ANRs anteriores; não houve
  correção no player nem causa demonstrada para a intermitência. Não foram
  reclassificados os runs vermelhos como infraestrutura nem apagadas evidências.
  A L tem APK e bancada verdes conforme o rito; o diagnóstico histórico continua
  aberto em `docs/ANR_BANCADA_L_2026-10-26.md`. O guard de ANR e a coleta de foco
  permanecem nas etapas seguintes. Capturas/artifacts não foram baixados neste
  ambiente (403); conclusões acima vêm dos logs do Actions, não de inspeção visual.
  **Não testado em aparelho físico**, atualização sobre instalação do Caio,
  outras plataformas ou servidores Plex. K e Início Jellyfin preservadas.
  Próxima etapa **M**, versão **2.0.31+32**; N e O ainda não iniciadas.


## Etapa M — em implementação (26/10)

- Base validada: L `43ad4df`, APK 40269817723 e bancada 40269817747 verdes, dados acima.
- Trabalho local ainda **sem commit de código/push**, versão preparada **2.0.31+32**.
  Política de áudio reproduzida em teste: antes pausava mesmo com escolha explícita;
  depois passa e mantém pausa obrigatória para TV/carro.
- Usa a MediaSession/MediaPlaybackService existentes, sem trocar mpv/Exo ou criar
  outro player. Opção desligada por padrão; só áudio exige serviço real em primeiro
  plano. Faixa de vídeo desativada/restaurada, sem reabrir URL nem perder posição.
- Android AOSP 15, `PipTaskOrganizer.removePipImmediately` e
  `ActivityTaskSupervisor.removeRootTask`: fechamento normal do PiP move a tarefa
  para trás; não equivale a remover tarefa dos Recentes. Não se acrescentou cache
  de engine nem retenção de Activity. O percurso real ainda precisa confirmar isso.
- PiP: sourceRectHint da imagem e seamlessResize=false. ASS/SRT continuam nas camadas
  existentes; aparência em aparelho físico ainda não conferida.
- Downloads: cópia local BSD-3-Clause do plugin `5d45882`, origem/licença em
  `apps/app/packages/background_downloader/HEISUCA.md`; grupo silencioso com
  pausar/continuar/cancelar, pausa não equivale a conclusão. Sem Live Updates.
- Bancada estendida para Home/PiP, som com FGS, transporte MediaSession, fechamento
  pelo botão real do SystemUI e restauração da imagem antes do Back. Sem saída
  simulada ou Back extra. Essa extensão **ainda não rodou no Android**.
- Até aqui: análise Dart sem erros, 31 testes Python aprovados. Portão completo,
  testes Kotlin, APK e bancada da M **pendentes**. N/O não iniciadas. Antes do push,
  terminar revisão/testes locais e registrar commit/runs neste documento.

- **M / portão local completo aprovado:** 615 Flutter (3 ignorados), 8 Impeller,
  32 Python; análise sem erros, manifesto fonte e diff conferidos. Nenhum golden
  da Início alterado. Teste da política falhou antes (`Expected false, Actual true`)
  e passou depois; default desligado também testado na preferência persistente.
- Envio do código da M em preparação, sem `[skip ci]`. Testes Kotlin selecionados
  no workflow: buffer existente, PiP (3), mpv áudio (3), grupo de downloads (2).
  **Não executados localmente** (sem SDK Android completo). A bancada exige cinco
  provas `foraDoApp` verdadeiras; FGS/áudio/PiP não são aprovados só pelo código.
  Continuam pendentes o par APK/bancada, hashes, certificado e validação física
  de ASS/SRT/PiP, ExoPlayer, lockscreen e download com pausar/retomar no aparelho.
- **Retomada M / código enviado:** `1ecb735d8d512414201b443e05ef83a70c74a655`,
  versão **2.0.31+32**, sem `[skip ci]`, portão 615 + 8 + 32 aprovado.
  Aguardar e inspecionar [APK 40301348854](https://github.com/CaioGuerras/heisuca/actions/runs/40301348854)
  e [bancada 40301349609](https://github.com/CaioGuerras/heisuca/actions/runs/40301349609).
  Registrar artifact, SHA-256 do APK/ZIP e certificado após a conferência.
  Ver `BANCADA_FORA_DO_APP`, foco antes/depois, cinco provas no JSON, ANR e
  restauração. Se falhar, corrigir na causa; não simular fechamento do PiP,
  repetir Back ou forçar foreground para ocultar falha. A reabertura explícita
  nos marcos 14/18/20 faz parte do teste Home/PiP/áudio; o Back original continua
  único e instrumentado. **M ainda aberta; N/O não iniciadas.** Último par verde
  é o da L, 40269817723/40269817747, versão 2.0.30+31.

- Revisão do preparo da M: teste demonstrou escolha indevida de clipe de 30 s
  (`suficiente != curto`) para o percurso ampliado. Passou após exigir >=5 min;
  paginação cobre catálogo com 200 curtas antes do primeiro filme adequado.
  Jellyfin OpenAPI conferida: filtro de duração não existe, não foi inventado.
  34 testes Python aprovados. Bancada 40301349609 cancelada **na preparação KVM**,
  antes de compilar/iniciar emulador/login, para não executar com esse preparo
  insuficiente; não houve conta a restaurar. APK 40301348854 segue em execução.
  Também preservados heartbeats da reprodução quando só o som continua; não
  suspendê-los como se a mídia estivesse pausada. Portão final do complemento
  em execução; novo commit/run será registrado após passar.
- **Complemento M aprovado localmente:** portão completo, 615 Flutter (3 ignorados),
  8 Impeller, 34 Python, análise sem erros. Preservado o wakelock das demais
  plataformas; só o modo de áudio desliga a retenção da tela. Versão continua
  2.0.31+32 (mesma etapa). Novo push precisa de APK e bancada verdes.
- **Retomada M / complemento enviado:** `05af83111ee04171163011df9378d76318cde01d`,
  versão **2.0.31+32**, portão 615 + 8 + 34 aprovado, sem `[skip ci]`.
  Runs a conferir: [APK 40303114349](https://github.com/CaioGuerras/heisuca/actions/runs/40303114349)
  e [bancada 40303114336](https://github.com/CaioGuerras/heisuca/actions/runs/40303114336).
  O APK anterior 40301348854 (`1ecb735`) ainda executava testes nativos no momento
  deste registro. Não confundir o resultado dele com a aprovação do complemento.
  Próximo passo: ler testes Kotlin e `BANCADA_FORA_DO_APP`, retorno/foco/ANR e
  restauração; conferir pacote, certificado e SHA-256/artifact do novo APK.
  **M não fechada; N/O não iniciadas.** Último APK e bancada verdes continuam
  40269817723/40269817747 da L, 2.0.30+31. Falhas intermitentes antigas continuam
  no diagnóstico da L, sem causa demonstrada e sem reclassificação de infraestrutura.
- **M / bancada 40303114336 falhou com ANR antes do primeiro Home**. Restauração
  confirmada. Diagnóstico disponível, anrDoApp=true, 1 trace do app e main coletada.
  Motivo FocusEvent(hasFocus=true), 5001 ms; foco já no diálogo ANR em 13-home-pip
  antes de injetar Home. Stack main espera em pthread_cond_wait/JNI no caminho
  DeferredSurfaceTextureListener.onSurfaceTextureAvailable → TextureView.getTextureLayer/draw.
  Sem atribuição automática ao emulador. Detalhes no diagnóstico da L.
  Artifact [12642990088](https://github.com/CaioGuerras/heisuca/actions/runs/40303114336/artifacts/12642990088),
  ZIP 1.782.596 bytes, SHA-256
  `41003062ef2e1210ff9d004cfacb01cfdba6325212e46d86af877a8744a930f0`.
- **Retomada atual:** código 05af831, docs após 3d7913d, versão 2.0.31+32.
  APK 40303114349 segue compilando release; testes Kotlin da M passaram no step 12.
  Bancada vermelha impede fechar M ou iniciar N/O. Próximo passo: identificar
  a espera JNI/superfície com a stack completa e símbolos do engine 5d531788,
  criar teste de reprodução antes da correção e repetir portão/CI. Impressão
  atual dos traces corta Java depois de 12 KB de frames nativos do interpretador;
  preservar/priorizar Java e threads raster na coleta, sem alterar a navegação.
  O run 40301348854 foi cancelado automaticamente pela concorrência do workflow
  quando entrou o complemento; 40301349609 foi cancelado antes do emulador.
- Coleta complementar, sem mudar o app: resumo de trace prioriza Java e threads
  raster/renderização, em vez de gastar 12 KB com o interpretador. Regressão
  coberta com 1.000 frames nativos antes do chamador JNI: 35 testes Python verdes.
  Workflow de leitura baixa o artifact já redigido pelo Actions (actions:read),
  sem segredos de servidor/conta e sem rodar o percurso. Resolve a falta da stack
  no log disponível neste ambiente; não considera o ANR corrigido.

- **Stack completa lida:** workflow [40306588701](https://github.com/CaioGuerras/heisuca/actions/runs/40306588701)
  verde, código `f3c624e48d0cdd28fac084b0794522dc942259fe`, evidência do mesmo
  artifact 40303114336, sem novo login. Main em FlutterJNI.nativeSurfaceCreated;
  raster presa em glGetActiveUniform_enc/qemu_pipe_read do driver do emulador;
  RenderThread Android idle. Não é stack de pop/dispose do mpv.
- Configuração conferida contra Google: Emulator 37.2.12 rodava modo
  swiftshader_indirect, descontinuado desde 36.4.9. Experimento preparado muda
  só GPU para `software`, backend suportado escolhido pelo Emulator. Imagem
  google_apis/API35/ABI x64, motor do app e prazos mantidos. Resultado ainda
  pendente, sem declarar cura nem reclassificar os ANRs antigos sem stack.
- Push do leitor também abriu APK 40306588427 e bancada 40306588412; o APK
  40303114349 anterior foi cancelado pela concorrência. A bancada do leitor
  ainda está na preparação/compilação, sem executar o percurso. M continua
  aberta; portão completo do experimento está em execução antes do novo push.
- **Experimento gráfico / portão completo aprovado:** 615 Flutter (3 ignorados),
  8 Impeller, 35 Python, análise sem erros. Bancada 40306588412 cancelada ainda
  na preparação KVM, antes do emulador/contas. Nenhum prazo ou comportamento do
  player foi alterado para este experimento. M segue aberta até a execução real.
- **Retomada M / GPU suportada enviado:** commit
  `c29ca1d3133f3d57c265afc7cd07cc004f262baa`, sem `[skip ci]`, versão **2.0.31+32**.
  Portão local **615 + 8 + 35** aprovado. Inspecionar
  [APK 40307478247](https://github.com/CaioGuerras/heisuca/actions/runs/40307478247)
  e [bancada 40307478230](https://github.com/CaioGuerras/heisuca/actions/runs/40307478230).
  Conferir no log qual backend `-gpu software` escolheu e o percurso completo,
  flags foraDoApp, foco, ANR, restauração e hashes/certificado do APK.
  A mudança só trata a configuração de emulação demonstrada pelo trace; ainda
  não há resultado do experimento, nem prova das funções da M no emulador.
  **M aberta, N/O não iniciadas.** Último par verde completo continua sendo
  L 40269817723/40269817747 (2.0.30+31). Não retomar hipóteses de pop/dispose:
  stack da reprodução M já foi lida em 40306588701 e está no diagnóstico da L.
- APK 40307478247, tentativa 1: falha **antes dos testes Kotlin**, no download
  `https://ffmpeg.org/releases/ffmpeg-8.0.1.tar.xz`, task prepareMpvFfmpegDevelopment
  (`Failed to download FFmpeg 8.0.1 headers`). Não é falha de asserção do app.
  Solicitada repetição do job com `gh run rerun --failed`, mesmo código/checksum.
  Tentativa 2 pendente. Bancada 40307478230 com GPU software ainda em execução.
  M continua aberta, N/O não iniciadas. Não há APK M conferido até este ponto.

- **Bancada software 40307478230:** escolheu Vulkan **lavapipe** / GLES **swangle**.
  **anrDoApp=false**, restauração confirmada; passou Home/PiP padrão e retorno.
  Falhou no passo seguinte: `só som fora do app`. O evento Android após o Home
  com a opção ligada ainda indica `auto-pip`; não é ANR nem instabilidade aceita.
  Artifact [12644117517](https://github.com/CaioGuerras/heisuca/actions/runs/40307478230/artifacts/12644117517),
  ZIP 12.639.624 bytes, SHA-256
  `366875e15319d6ff44cb76eae6b55a4b7153a9c88a522f78262d925364c3f9e9`.
- Reprodução local de uma corrida real no atualizador do PiP: consulta antiga
  de dimensões pode publicar true depois de uma mudança que publicou false.
  Teste falhou com **Expected [false], Actual [false, true]**. Correção local
  invalida revisões anteriores e reconfere preferência/pausa/dono depois do await;
  5 testes passaram (desligar, consulta mais nova, dono cancelado e condição atual).
  Isso ainda precisa ser confirmado no Android; não se declara toda a falha resolvida.
- Hipótese auxiliar sobre pump/segundo plano foi testada isoladamente: a espera
  completou no SDK atual; não se reproduziu bloqueio. Experimento removido, sem
  mudar binding/pump da bancada por suposição. Diagnóstico de timeout agora inclui
  PiP, ciclo Flutter, escolha de áudio, áudio ativo e serviço foreground.
- Correção ainda local, portão completo em execução; APK 40307478247 tentativa 2
  segue em andamento. M aberta; N/O não iniciadas. Próximo commit precisa de
  APK/bancada novos e registro dos respectivos runs.

- Complemento de reprodução da espera: o primeiro probe não estabilizava frames.
  Depois de `pump` inicial, pausa e 100 ms para escoar frames pendentes, **pump
  em segundo plano expirou em 250 ms**. Novo teste reproduziu isso no LiveBinding.
  O driver passa a usar relógio real (`binding.delayed`) nas esperas e política
  fullyLive para o app desenhar como em uso normal. Não força frames enquanto
  o Android os suspende. Dois testes passaram: espera em pausa e animação em
  primeiro plano sem pumps do driver. Não altera binding/código do APK de produção.
- Corrida do PiP integrada à tela, 5 testes aprovados. Portão anterior do controle
  passou 620 Flutter + 8 Impeller + 35 Python. Agora o portão final inclui também
  os dois testes de espera da bancada; em execução com fontes congelados.
  A execução real da correção ainda não ocorreu. M continua aberta.
- **Portão final do complemento PiP/espera aprovado:** 622 Flutter (3 ignorados),
  8 Impeller, 35 Python; análise sem erros. O controlador só publica a consulta
  atual e não publica pela tela desmontada; a bancada usa fullyLive e relógio
  real nas esperas, mantendo entrada/saída/Back nativos. Sem mudança de prazos.
  Código em preparação para push sem `[skip ci]`, mesma versão 2.0.31+32.
  Ainda não aprovado no Android. APK 40307478247 tentativa 2 compilava release;
  a bancada correspondente está vermelha por `só som fora do app` (não ANR).
- **Retomada M / PiP e relógio do driver enviados:**
  `bbc0a66eeba5d4bfe4023660247c661b124ab0ba`, sem `[skip ci]`, **2.0.31+32**,
  portão **622 Flutter + 8 Impeller + 35 Python** aprovado.
  Aguardar [APK 40312145112](https://github.com/CaioGuerras/heisuca/actions/runs/40312145112)
  e [bancada 40312145102](https://github.com/CaioGuerras/heisuca/actions/runs/40312145102).
  [Leitura de evidência 40312145094](https://github.com/CaioGuerras/heisuca/actions/runs/40312145094)
  só inspeciona artifact anterior: não é aprovação da bancada nem das funções.
  No novo percurso conferir cinco provas foraDoApp, foco/ANR, retorno e restauração;
  se falhar, a flag agora inclui PiP, ciclo, preferência, áudio ativo e FGS.
  Conferir pacote/certificado/SHA-256/artifact do APK novo. **M aberta; N/O não
  iniciadas.** Último par completo verde continua L 40269817723/40269817747,
  versão 2.0.30+31. Não reiniciar K/F nem desfazer correções K.
- **Bancada 40312145102 (`bbc0a66`) falhou:** passou PiP padrão, só som com FGS,
  vídeo desativado (`vid=no`) e avanço de posição, pausa e play pela MediaSession.
  Falhou ao retornar à imagem no marco 18. O ANR já estava visível no marco 16,
  portanto não começou no comando de retorno. Evento às 11:22:33: FocusEvent
  **hasFocus=false**, 5002 ms, depois de Home 15 às 11:22:25.
- Timeout: pipAtivo=false, cicloFlutter=inactive, servicoMidiaForeground=true,
  continuarOuvindo=true, audioForaDaTela=true. Janela ANR retém foco; reabrir traz
  Activity para topResumed, mas não tira o foco do diálogo. Main coletada mostra
  Java nativePollOnce e frame Dart; schedstat main: ~19,6 s executando e ~169,2 s
  esperando CPU. Essa stack é diferente da espera glGetActiveUniform anterior;
  ainda não foi classificada como infraestrutura. Não alterar pop/dispose por isso.
- Restauração confirmada. Artifact
  [12646601316](https://github.com/CaioGuerras/heisuca/actions/runs/40312145102/artifacts/12646601316),
  ZIP 12.064.676 bytes, SHA-256
  `92e92215be0b3efb0643811940131314d5c748423bf0ed04aba244af0bc5a82c`.
- **Retomada atual:** código `bbc0a66`, docs após `edc0384`, versão 2.0.31+32;
  bancada 40312145102 vermelha, APK 40312145112 compilando release (testes nativos
  passaram). Próximo passo: ler pressão/carga CPU e contexto integral do novo
  ANR antes de classificar/corrigir. Som e transporte foram exercitados; retorno
  da imagem e fechar PiP com áudio ainda não foram comprovados. M aberta, N/O
  não iniciadas. Último par completo verde continua a L, 2.0.30+31.

- **APK M verde e conferido:** código `bbc0a66eeba5d4bfe4023660247c661b124ab0ba`,
  versão **2.0.31+32**, [run 40312145112](https://github.com/CaioGuerras/heisuca/actions/runs/40312145112),
  [artifact 12645654971](https://github.com/CaioGuerras/heisuca/actions/runs/40312145112/artifacts/12645654971).
  Pacote `app.heisuca.player.teste.home`, Heisuca Teste, APK 97.072.446 bytes,
  certificado `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 APK `9127b306ee272579162d220e62c8e5e004ea5f3ce7aeff3ea9f1695bc75340a6`;
  ZIP 50.367.789 bytes, SHA-256
  `a384e683b2592f20214b5b8bda26595c192b7c75fd5db44f4202de8cf50e2a54`.
  Validador confirmou serviço privado mediaPlayback, sem Live Updates, GPL,
  zero plezy.app/SDK Sentry. Testes Kotlin aprovados (BUILD SUCCESSFUL).
  **Não fecha M:** bancada do mesmo código tem ANR. Sem teste físico de áudio,
  PiP/ASS/SRT, notificações de download, ExoPlayer ou atualização instalada no Caio.
- Leitor de artifacts ampliado para imprimir motivo/carga/pressão de recursos
  do android-anr.log já redigido. Não altera app nem transforma o run da bancada
  em verde. Próxima leitura é do ANR de perda de foco 40312145102.

### Bloqueio externo para retomar a M — 26/10, 11:35 UTC

- Código mais recente: `628f1964a794beafa4bc2db08f417c387150ee4d` (só leitor de
  evidência desde `bbc0a66`; código do app continua o do APK verde abaixo).
  Versão **2.0.31+32**; portão do app aprovado: **622 Flutter (3 ignorados),
  8 Impeller, 35 Python**. Ramo único preservado, sem PR/merge/publicação no site.
- Os três runs novos falharam **sem executar nenhum step**:
  [APK 40316060620](https://github.com/CaioGuerras/heisuca/actions/runs/40316060620),
  [bancada 40316060677](https://github.com/CaioGuerras/heisuca/actions/runs/40316060677),
  [leitor 40316060681](https://github.com/CaioGuerras/heisuca/actions/runs/40316060681).
  Annotations conferidas nos três check-runs (121548831188, 121548831059,
  121548830789), mesma mensagem exata:
  > The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings
- Não se sabe qual das duas condições ocorreu. Nenhum pagamento/limite foi
  alterado pelo Codex. Não adianta repetir os jobs enquanto o GitHub bloquear
  a conta; depende do responsável regularizar Billing & plans. Não houve login
  de teste nem dados a restaurar nesses três runs sem steps.
- **Último APK verde conferido: 40312145112 / artifact 12645654971, 2.0.31+32**,
  pacote/certificado/hashes acima. Não é aprovação da M: a bancada 40312145102
  tem ANR de perda de foco, com restauração confirmada. O bloqueio de cobrança
  não reclassifica esse ANR como infraestrutura nem resolve o retorno da imagem.
- **L entregue; M aberta; N e O não iniciadas.** Não iniciar outra etapa antes
  de cumprir o rito da M (ou documentar uma falha de infraestrutura demonstrada,
  sem inventar a causa do ANR). PiP padrão, áudio com FGS e transporte foram
  exercitados; imagem no retorno e áudio após fechar PiP ainda sem prova completa.
  Teste físico de ASS/SRT/PiP/lockscreen/download/Exo/atualização segue pendente.

Próxima ação quando Actions for liberado:
1. `git pull --ff-only` no ramo codex/heisuca-home-site e ler o fim deste registro.
2. Rodar o leitor sem novo acesso ao servidor:
   `gh workflow run heisuca-inspecionar-anr.yml --ref codex/heisuca-home-site -f run_id=40312145102`.
   Ele já inclui carga/pressão de recursos do android-anr.log, além da stack e
   do JSON do teste; essa versão do leitor ainda não executou por bloqueio de cobrança.
3. Identificar o motivo do novo ANR: começou em Home 15, antes de voltar à imagem;
   main mostra nativePollOnce/frame Dart e alta espera por CPU (~169 s acumulados),
   não a stack glGetActiveUniform anterior. Conferir métricas antes de concluir.
   Não forçar foco, repetir Back, ampliar prazos ou alterar dispose por suposição.
4. Corrigir a causa com teste antes/depois; portão completo, commit de código
   sem skip, push e APK/bancada verdes; conferir pacote/certificado/SHA-256 e
   registrar artifact. Manter M em 2.0.31+32 enquanto corrige a mesma etapa;
   depois N 2.0.32+33 e O 2.0.33+34, seguindo os handoffs e relatórios do repo.

### Retomada da M — Actions liberado em 26/10, 12:55 UTC

- Pull em `codex/heisuca-home-site` até `d2f4728`; alterações recentes do Claude
  são só CI, sem diferença líquida no app. Cobrança deixou de bloquear jobs.
- [APK 40321095197](https://github.com/CaioGuerras/heisuca/actions/runs/40321095197)
  **verde**, código do app ainda `bbc0a66`, versão **2.0.31+32**.
  [Artifact 12649218807](https://github.com/CaioGuerras/heisuca/actions/runs/40321095197/artifacts/12649218807):
  ZIP 50.367.959 bytes, digest `20879833df08925ec5fa923d50fae8b17a655b985752d9091df8ec7f69c334e5`.
  APK 97.072.446 bytes, SHA-256 `91be2793fc2e678e2e5a898426050f593587e844eabec095214c8216c36081eb`.
  Log conferido: pacote `app.heisuca.player.teste.home`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`,
  serviço privado mediaPlayback, GPL presente e nenhum Sentry/plezy.app.
- [Ler ANR 40325209236](https://github.com/CaioGuerras/heisuca/actions/runs/40325209236)
  **verde**, lendo a evidência do run vermelho 40312145102, sem acessar contas.
  Confirma `FocusEvent(hasFocus=false)` 5002 ms em Home 15; carga
  **36,78 / 27,64 / 12,79**, CPU **99%**, pressão CPU avg10 **91,04%**,
  avg60 **90,40%**. Main em estado R, ~19,6 s executando e ~169,2 s aguardando CPU;
  Java nativePollOnce, RenderThread idle. Não é a stack de GPU anterior nem
  evidência de bloqueio em pop/dispose. Não extrapolar essa causa aos ANRs antigos.
- Novo experimento só de bancada: renderizar **540x1200 / 210 dpi**, em vez de
  1080x2400 / 420 dpi, mantendo ~411x914 dp e cortando 75% dos pixels de
  renderização por software. Comprovação esperada é percurso completo sem ANR;
  nenhum timeout, foco, efeito do app ou guard de ANR relaxado.
- Bancada 40320970997 observada por mais de 35 minutos em **Preparar KVM e espaço**,
  sem sequer compilar/iniciar emulador; 40321095378 aguardava essa execução.
  Após cancelamento, log completo mostrou a causa exata: limpeza terminou em
  ~1 minuto; **apt baixava ffmpeg e recomendações**, com downloads parados
  por vários minutos (libcodec2/pocketsphinx). A suspeita inicial de limpeza
  lenta foi descartada antes do commit; limpeza original preservada. Instalação
  agora sem recomendações, timeout HTTP/HTTPS 30 s, duas tentativas, limite de
  10 min para preparação. Falha de download continua vermelha, sem acessar conta.
  Ambos os runs antigos foram cancelados antes de compilar/acessar servidor.
- M permanece **aberta**; N/O não iniciadas. Não testado em aparelho físico.
- Portão local desta retomada aprovado: **622 testes Flutter (3 ignorados),
  8 com Impeller e 35 Python**, análise sem erros. Registro em
  `/workspace/m-retomada-gate.log` (arquivo local, não distribuído no APK).
- Experimento enviado no commit **49ea96defbddc7b2760f1e4cf47cc92ea25a6654**,
  sem skip, mesmo app/versão da M. Runs em acompanhamento:
  [APK 40326294512](https://github.com/CaioGuerras/heisuca/actions/runs/40326294512) e
  [bancada 40326294796](https://github.com/CaioGuerras/heisuca/actions/runs/40326294796).
  **Não considerá-los aprovados antes de ler o resultado e artifacts.**

### Resultado do experimento 49ea96d — M ainda aberta

- [APK 40326294512](https://github.com/CaioGuerras/heisuca/actions/runs/40326294512)
  **verde**, versão 2.0.31+32; pacote/certificado/mediaPlayback/GPL/ausência de
  Sentry conferidos no run. [Artifact 12651329519](https://github.com/CaioGuerras/heisuca/actions/runs/40326294512/artifacts/12651329519),
  ZIP 50.367.807 bytes, digest `830a6235e5ccf34dacb569ba787d04b732aa12c01fc73d18eb4912db39d4da7c`.
  APK 97.072.446 bytes, SHA-256 **daf47c2221d601b10d8430115e35717a5d4441cf1b22a0a0d804dee8b4242ab5**.
  Certificado **19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c**.
  Download pela ferramenta conectada GitHub funcionou: ZIP extraído e SHA do
  APK recalculado localmente, igual ao log. O mesmo vale para o APK anterior.
- [Bancada 40326294796](https://github.com/CaioGuerras/heisuca/actions/runs/40326294796)
  **vermelha**, artifact **12653390690**, ZIP 6.547.310 bytes, digest
  `495475923eedfb83ce44fe514b5592c1c3762e398c004b06e406db7c9ba6a193`.
  Relatório/PNG/vídeo/log baixados e inspecionados. Sem ANR do app, coleta
  nativa disponível; restauração de progresso/assistido/contagem/data/preferências
  confirmada. Overrides efetivos 540x1200 / 210 dpi. Preparação passou em 48 s.
- Percurso chegou a **19-fechar-pip**: padrão desligado, Home em PiP, retorno,
  áudio com FGS/vid=no/avanço, pausa e retomada via MediaSession, retorno da
  imagem (estado/vid) e nova entrada em PiP. **Não chegou ao Back final**.
  Falha exata: `RuntimeError: Botão de fechar PiP não encontrado; nenhuma saída simulada.`
  Não é run instável/aprovado; o guard continua recusando fechamento da M.
- Captura 15 tem vídeo real; captura 19 mostra PiP preto transitório, mas o
  fim do vídeo interrompido tem imagem no PiP. Há erro MediaCodec de índice
  após mudanças de superfície; não declará-lo inofensivo nem corrigido sem prova.
  A nova captura 21 documentará a imagem após voltar do áudio, antes do PiP manual.
- Diagnóstico da automação, fontes AOSP oficiais lidas:
  `frameworks/testing/master/uiautomator/cmds/uiautomator/src/com/android/commands/uiautomator/DumpCommand.java`
  espera `waitForIdle(1000, 10000)` e só lê `getRootInActiveWindow()`;
  `frameworks/base/android15-release/libs/WindowManager/Shell/src/com/android/wm/shell/pip/phone/PipMenuView.java`
  esconde menu após **3500 ms** (depois de interação, **2000 ms**).
  O caminho antigo de dois dumps levou ~20 s e não preservava a janela PiP.
- Próximo teste usa UiAutomation nas **janelas interativas** sem espera de idle:
  helper Java compilado/dexado só na bancada, executado como shell, abre menu
  com toque real dentro do task pinned deste pacote e faz ACTION_CLICK apenas
  no botão Close/dismiss do SystemUI. Nenhum pop/PiP exit é simulado. O teste
  continua exigindo PiP inativo, FGS e avanço de áudio, retorno da imagem e Back.
  Helper e task dump são registrados no artifact, com a mesma redação de dados.
  Sem alteração de permissões/motor/pacote/versão do app. Não testado em aparelho.
- Portão local após a mudança de automação: **aprovado**, 622 Flutter
  (3 ignorados), 8 Impeller e 35 Python; análise sem erros. Java/D8 do helper
  será compilado no SDK do Actions; não se montou SDK Android neste ambiente.
- Commit enviado: **477ed64b6a0f3d104adb25e002302585e2ab3b26** (sem skip).
  Em acompanhamento: [APK 40329657365](https://github.com/CaioGuerras/heisuca/actions/runs/40329657365)
  e [bancada 40329657261](https://github.com/CaioGuerras/heisuca/actions/runs/40329657261).
  Se houver interrupção, começar inspecionando esses runs e seus artifacts;
  não refazer a L, não iniciar N/O e não considerar a M fechada automaticamente.

### Retomada seguinte — resultado de 477ed64, 26/10

- [APK 40329657365](https://github.com/CaioGuerras/heisuca/actions/runs/40329657365)
  **verde**, 2.0.31+32. Pacote `app.heisuca.player.teste.home`, 97.072.446 bytes;
  certificado `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 do APK `3cb3fa6aafd7ca71ba6ee3cb3cc5ef55c17871e52759ba226b671c04680474da`.
  Artifact **12653254525**, ZIP 50.367.759 bytes, digest
  `f480afd66ee3f8cdc2622d6b0089bf8b3fcb9287a580cbd616799bb971db31af`.
  Pacote, assinatura e hashes lidos no run; este APK ainda não foi recalculado localmente.
- [Bancada 40329657261](https://github.com/CaioGuerras/heisuca/actions/runs/40329657261)
  **instável por infraestrutura identificada**, nunca verde: compilação do
  APK de integração e do helper Java/D8 aprovadas; emulador informou boot completo,
  mas `adb root` falhou imediatamente com **`unable to connect for root: closed`**
  às 13:30:45 UTC. Script encerrou antes de instalar/executar app ou acessar servidor.
  Não é novo ANR nem prova funcional de fechar PiP. Artifact **12654862564**,
  240 bytes, digest `dc1fca9e13e71bcb7082a6026835d3e67f29f6d42b18b7de5c9ad57f56803e92`.
- Disparada apenas a bancada novamente, **mesmo código**: run
  [40339131385](https://github.com/CaioGuerras/heisuca/actions/runs/40339131385),
  head documental `b3408cd`, código `477ed64`. Em acompanhamento; **M aberta**.
  Não avançou para N/O nem declarou resolvida a falha anterior de automação.

### Correção local da coleta do helper antes da próxima execução

- Revisão encontrou defeito novo na automação de 477ed64: `capturas.adb` descarta
  stderr, logo `CompletedProcess.stderr` é None, mas `acoes.perform` concatenava
  stdout+stderr. Teste novo reproduziu **TypeError: can't concat NoneType to bytes**
  antes da correção. Agora só a chamada do helper reúne stderr em stdout; o
  restante do wrapper permanece descartando stderr. Saída nativa passa pela
  redação já existente antes de gravar no artifact. **36 testes Python verdes**.
- Run **40339131385 cancelado**, ainda em compilação do APK de integração,
  antes de emulador/conta. Cancelamento comum recebeu HTTP 502 e 500; o
  endpoint force-cancel foi aceito e o estado final `cancelled` foi conferido.
  Não houve execução do novo helper nesse run. Nenhuma alegação de teste do app.
- O portão completo está sendo repetido; código do aplicativo segue o mesmo,
  versão 2.0.31+32. M continua aberta, N/O não iniciadas.
- Portão final desta correção **aprovado**: 622 Flutter (3 ignorados),
  8 Impeller, 36 Python; análise sem erros. Log local m-pip-stderr-gate.log.
- Correção enviada em **7ec179b8982340ffd19027242ae5795bd3a0e2a5** (sem skip).
  Pendente conferir [APK 40340535441](https://github.com/CaioGuerras/heisuca/actions/runs/40340535441)
  e [bancada 40340535448](https://github.com/CaioGuerras/heisuca/actions/runs/40340535448).
  Retomar por esses runs. M aberta, versão 2.0.31+32; N/O não iniciadas.

### Resultado de 7ec179b — 26/10, M ainda aberta

- [APK 40340535441](https://github.com/CaioGuerras/heisuca/actions/runs/40340535441)
  **verde**, 2.0.31+32, pacote `app.heisuca.player.teste.home`, 97.072.446 bytes;
  certificado **19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c**.
  SHA-256 **af92f2e2341ca7cda380bd20ad370b68b7c793f53d0a1fb8f1298df7103337bb**,
  artifact **12660236296**, ZIP 50.367.948 bytes, digest
  `d28bc65d0a06256f18122edb815367f898a3dc96a9fcf996625631e92effebe7`.
  Conferidos no run; ainda não recalculado localmente.
- [Bancada 40340535448](https://github.com/CaioGuerras/heisuca/actions/runs/40340535448)
  **vermelha**, artifact **12658969782** baixado/inspecionado, ZIP 5.994.437 bytes,
  digest `454d14c5f6b76e705d35cda1f28da9d5d604fe2aaeaad279f5085f4c7fef258c`.
  **Sem ANR do app**, diagnósticos disponíveis, restauração confirmada.
  Chegou ao marco 21 e ao 19. Helper registrou só **`Killed`**, antes de registrar
  clique; erro do host `Clique nativo de fechar PiP falhou`. Não há motivo de
  kernel/Java coletado para atribuir a memória, permissões ou outra causa.
- **Captura 21 está preta**: vid selecionado e áudio/posição avançando NÃO
  comprovam imagem restaurada. O vídeo interrompido tem intervalo preto de
  ~89,5 a 103,7 s, terminando quando aparece o launcher na transição PiP.
  Não corrigir o player por suposição nem declarar retorno funcional. N/O seguem
  não iniciadas. Captura 15 anterior tinha vídeo; a falha visual requer prova.
- Próxima investigação isolada: workflow **Heisuca Diagnosticar UiAutomation**,
  sem instalar app, sem servidor/contas e **sem toque**. Só conectar/listar janelas/
  desconectar, com milestones e logs Android/kernel/memória. Helper tem --probe
  para isso; a bancada normal mantém clique real e todas as verificações.
  O workflow diagnóstico não fecha a etapa nem substitui a bancada.

### Causa do Killed isolada — 26/10, 14:59 UTC

- Diagnóstico [40344507220](https://github.com/CaioGuerras/heisuca/actions/runs/40344507220)
  **vermelho**, sem app/servidor/toque, reproduziu **exit 137** durante `connect`.
  Artifact **12659883587**, ZIP 75.374 bytes, digest
  `f21427b8e4d154c0bc10c092b6715ca2cc30371d27a99ef8a273bb51f54e0330`.
- Log Android mostra `FATAL EXCEPTION: UiAutomation`, PID 2739:
  `NullPointerException ... Looper.mQueue ... Looper null`, em
  `Handler.<init> → AccessibilityInteractionClient.<init> → getInstanceForThread
  → AccessibilityService$IAccessibilityServiceClientWrapper.init`.
  `BANCADA_PIP: início` e `conectando` foram impressos; `conectado` não.
  Isso explica o SIGKILL do helper pelo tratador fatal do runtime; não atribuir
  a OOM/SELinux nem a travamento do processo do Heisuca.
- Correção do bootstrap do processo shell: preparar o **Looper principal** antes
  de conectar. O HandlerThread passado à UiAutomation continua cuidando de seus
  callbacks; sem ActivityThread o Looper principal não era criado. Nenhuma
  alteração do app, de timeout de player, foco ou atalho de saída.
- Antes de novo percurso, repetir a sondagem isolada e exigir conexão/lista de
  janelas/desconexão com exit zero. Isso ainda não comprova fechar PiP nem a
  imagem preta observada na M. Não iniciar N/O até a M ter a prova exigida.

### Prova antes/depois do bootstrap da UiAutomation

- Correção **781a626f9683f1da188b9583f05949a3ee2d3b90**.
  Sondagem [40345431981](https://github.com/CaioGuerras/heisuca/actions/runs/40345431981)
  **verde**: exit **0**, marcos `início → conectando → conectado → janelas=1
  → encerrando conexão`. Log inspecionado. Artifact **12660334405**, 65.297 bytes,
  digest `59f9dd7212dcfc7332b7679fd9e6ae138551ae59032a1bde8ec3887e5929044f`.
  Contrasta com a mesma sonda vermelha por NPE antes da única inicialização
  do Looper principal. Não houve app instalado/toque/servidor nesse teste.
- A bancada com a correção **40345395444** ainda está em preparação; APK
  correspondente **40345395249** também em acompanhamento. Não supor aprovação.
  Bancada duplicada **40344506657** cancelada ainda na fila; **40344379555**
  cancelada antes de compilar/usar conta porque ainda continha o bootstrap com NPE.
- Diagnóstico do mirror, log de 40344379555: índices baixaram **12,6 MB em 2 s**,
  porém .deb do `azure.archive.ubuntu.com` HTTP chegaram a ~60 KB/s e libcodec2
  teve retry. Preparação levou vários minutos. Próxima bancada prioriza o
  **archive.ubuntu.com HTTPS oficial**, preservando chaves e verificação APT,
  limite de preparação de 10 min e todos os guards do percurso.
- Próxima coleta da M: `video-pts`, VO/configuração, dimensões, avsync e quedas
  de quadro antes/depois; tentativa de `screenshot-to-file ... video` do mpv
  para comparar quadro decodificado com screenshot do Android. Sem mudança
  de motor, decoder ou vídeo escolhido. Se o VO não permitir captura, registrar
  indisponibilidade; não inferir que a imagem voltou só da posição/faixa.
  PNG decodificado só pode ser lido de caminho fixo privado criado pelo teste;
  PNG inválido recusa ACK (novo teste de regressão, **37 Python verdes**).
- Resultado da bancada **40345395444**: infraestrutura **instável**, erro exato
  `Preparar KVM e espaço has timed out after 10 minutes`, ainda baixando .deb
  do mirror Azure; não compilou/iniciou app nem acessou conta. Artifact
  **12661642876**, 240 bytes, digest
  `dffd3eafdb8970a949ea34560310abb0eaebc4350edf9123567ec3ec45e565a8`.
  Não substituir por isso a falha visual anterior do retorno do áudio.
- [APK 40345395249](https://github.com/CaioGuerras/heisuca/actions/runs/40345395249)
  **verde**, 2.0.31+32; pacote/certificado conferidos, assinatura19160423…
  (valor completo já registrado), 97.072.446 bytes, SHA-256
  `41d08cc2685989ca09aa537658bb31acfca6edc6163b0285645735cf3f94c0e1`.
  Artifact **12661643360**, ZIP 50.368.118 bytes, digest
  `04007bdd33f37efa0ceff99db335944bae2448311e9b6177dd1a8f2eaf30c176`.
- Log da bancada mostrou `hw.cpu.ncore=2`. Próxima configuração registra nproc
  do host e usa os núcleos disponíveis (máximo 4) no AVD. É capacidade da bancada,
  sem comprar runner, mudar motor/efeitos do app ou alegar correção da tela preta.
- Portão local da coleta de quadros **aprovado**: **622 Flutter (3 ignorados),
  8 Impeller, 37 Python**, análise sem erros. Análise do arquivo de integração
  repetida após ajustar o log, sem erros. Sem teste físico; M aberta.
- Coleta e preparação enviadas em **707d4cb22350418248bfce462bc311479f0e7979**,
  sem skip. Runs pendentes: [APK 40348261830](https://github.com/CaioGuerras/heisuca/actions/runs/40348261830)
  e [bancada 40348262192](https://github.com/CaioGuerras/heisuca/actions/runs/40348262192).
  Retomar por eles, baixar artifact e comparar PNG decodificado/tela se disponíveis.
  M **não fechada**, N/O não iniciadas, versão **2.0.31+32**, nenhum teste físico.

### Resultado de 707d4cb e próximo diagnóstico nativo — 26/10

- [APK 40348261830](https://github.com/CaioGuerras/heisuca/actions/runs/40348261830)
  **verde**, 2.0.31+32, pacote `app.heisuca.player.teste.home`, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`,
  97.072.446 bytes. SHA-256 **429ccb44472775fc47abc903c53feccbabafe7eb31f085d53eb0a3098e09921d**.
  Artifact **12663566848**, ZIP 50.367.874 bytes, digest
  `ee45f66b7650f13b5485544767358349b7273cc39fe4b6e7bcc581e1ef2afbff`.
  Conferência pelo run; ainda não recalculado localmente.
- [Bancada 40348262192](https://github.com/CaioGuerras/heisuca/actions/runs/40348262192)
  **vermelha**, artifact **12664175500** baixado e inspecionado, 6.240.640 bytes,
  digest `9b7a36b7f86ad79f5c43260174b0d43f71eb20053e013c37f42aad4fbe75643a`.
  **Sem ANR do app**, restauração confirmada. Preparação passou em **93 s**,
  host/AVD **4 CPUs**, overrides 540x1200 / 210 dpi efetivos. Não concluir que
  a capacidade adicional corrige o problema visual.
- Helper agora **conecta e lista janelas**; não encontra a vista Close.
  Listou SystemUI, app e launcher, encerrou conexão e terminou Killed (exceção
  principal enviada ao log Android pelo runtime). Próxima versão imprime a
  própria exceção em stderr antes de retornar exit 1, preservado no artifact.
- Imagem 05 tem quadro real (Lisoca); **21 continua preta**. mpv **não permitiu
  screenshot-to-file**, sem PNG decodificado; indisponibilidade registrada,
  não tratada como prova. `video-pts` não existe nesta versão do mpv e será
  retirado da sonda. Inicial: vid=1, current-vo=gpu, vo-configured=no,
  output=1920x1080. Após áudio: vid=1, GPU, vo-configured=no, output=null.
  Não basta para determinar a causa; o quadro inicial pode ser da transição
  anterior. Logs mostram mediacodec→gpu por `reasons=[shaders]` e retorno a
  mediacodec no PiP. Próxima coleta inclui entrada/decoder/faixa e logs do VO
  em nível v **só na integração**, passando pela redação já existente.
- Fontes AOSP 15 conferidas para fechar PiP sem depender do menu efêmero:
  `libs/WindowManager/Shell/src/com/android/wm/shell/pip/phone/PipAccessibilityInteractionConnection.java`
  publica **ACTION_DISMISS**, cujo handler chama `mMotionHelper.dismissPip()`.
  `services/accessibility/java/com/android/server/accessibility/AbstractAccessibilityServiceConnection.java`
  encaminha ações não focais da janela PiP para essa conexão do sistema.
- Helper passa a usar **uma ACTION_DISMISS** oferecida pela janela que o Android
  marca como PiP, com pacote do app/SystemUI; host continua validando o task
  pinned do Heisuca antes da chamada. Não toca em outra janela nem chama
  saída/pop no aplicativo. Mantém as verificações de FGS, avanço de áudio,
  PiP encerrado, reabertura e Back único. Não é um clique visual no X; é a
  ação real de acessibilidade do sistema, com o mesmo fechamento nativo.
- M continua **aberta**, sem prova da imagem restaurada; N/O não iniciadas.
- Portão local da ação nativa de acessibilidade **aprovado**: 622 Flutter
  (3 ignorados), 8 Impeller, 37 Python; análise sem erros. Não testado em aparelho.
- Commit da ação nativa após integrar o remoto 8908741 (só publicação/SSH):
  **0cb87aa62ec477b24a9182622c45913c87d1b09d**, sem skip. Portão do código
  aprovado antes do rebase; alterações remotas não mudam o app/testes.
  Runs pendentes: [APK 40355325643](https://github.com/CaioGuerras/heisuca/actions/runs/40355325643)
  e [bancada 40355325623](https://github.com/CaioGuerras/heisuca/actions/runs/40355325623).
  Foco da investigação: imagem preta/VO GPU sem configuração após áudio, com
  logs do VO; nenhuma correção no player atribuída a isso ainda. M aberta,
  versão 2.0.31+32; N/O não iniciadas. Não multiplicar tentativas sem ler essa evidência.

### Resultado de 0cb87aa — falha anterior ao player, sem novo dado da retomada

- [APK 40355325643](https://github.com/CaioGuerras/heisuca/actions/runs/40355325643)
  **verde**, artifact **12667120951**, 50.367.747 bytes, digest
  `67d4a04f0eee8875bfcd1dda29a7a2ea680f72ae2c15a338f8559943cdfb99c5`.
- [Bancada 40355325623](https://github.com/CaioGuerras/heisuca/actions/runs/40355325623)
  **vermelha**, artifact **12665354473**, 833.330 bytes, digest
  `e8403888cb58d6e84d34285049dcbd64de997f43b6095eaf1c066283bbf8d7be`.
  Baixado/inspecionado: só marcos 01–04. Erro `Tempo esgotado na etapa: player
  nativo`. **Sem ANR**, restauração confirmada. Nem helper ACTION_DISMISS nem
  nova coleta de VO chegaram a executar: não atribuir esse resultado a eles.
- Captura **04-ficha.png** mostra **Assistir desabilitado**. Código real de
  `HeisucaTitleSheet._playButton`: enabled = `_target != null`, InkWell.onTap
  null até terminar a seleção de conteúdo. Teste esperava a ficha existir,
  tocava no texto imediatamente e aguardava um player que não fora solicitado.
  Não há prova de que o alvo permaneceu indisponível por 90 s; não chamar isso
  de falha de infraestrutura ou de reprodução. Nenhuma mudança no app indicada.
- Corrigir a pré-condição da automação: aguardar InkWell visível/hit-testable
  **com onTap não nulo**, depois **um toque**. Prazo existente de 90 s mantido.
  Sem habilitar botão, escolher cliente alternativo, chamar reprodução por fora
  ou repetir toque. Falha continua vermelha se a ficha não ficar pronta.
- A captura de falha passa a ser armada **depois do perfil anônimo (02)**,
  antes da busca/ficha; antes disso continua proibida. Registra etapa e estado
  naquele instante, para distinguir carregamento/erro real de falta de interação.
  Não expõe campos de login. M continua aberta, N/O não iniciadas.
- APK 40355325643 conferido no log: pacote `app.heisuca.player.teste.home`,
  97.072.446 bytes, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`, SHA-256
  `bd4b0f2f10d5aba0627bbe8a971c8e144151781ed44494cea0f28300c956a33b`.
- Portão local da pré-condição de Assistir **aprovado**: 622 Flutter
  (3 ignorados), 8 Impeller, 37 Python; análise sem erros. Versão 2.0.31+32.
- Pré-condição enviada em **442d3455ee25972b9684287233ede0755bdf2342** (sem skip).
  Conferir [APK 40359809836](https://github.com/CaioGuerras/heisuca/actions/runs/40359809836)
  e [bancada 40359810049](https://github.com/CaioGuerras/heisuca/actions/runs/40359810049).
  Se interromper, retomar desses runs; ainda não há dado novo da imagem após
  áudio nem teste real de ACTION_DISMISS. M aberta, 2.0.31+32, N/O não iniciadas.

### Último resultado e perda do ambiente — 26/10, após 442d345

- [APK 40359809836](https://github.com/CaioGuerras/heisuca/actions/runs/40359809836)
  **verde**, versão **2.0.31+32**, pacote `app.heisuca.player.teste.home`,
  97.072.446 bytes. Certificado conferido no job:
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 do APK **1535e239d45356fbb5a23d96adcf018215e5480e720e11f2d2a8c46dae086cbd**.
  [Artifact 12668527190](https://github.com/CaioGuerras/heisuca/actions/runs/40359809836/artifacts/12668527190),
  ZIP 50.367.790 bytes, digest
  `9970d11a604d8016b3699bd2e624719d637acac9436156a21b27c1dd8ff80219`.
  Leitura pelo conector GitHub; não foi recalculado localmente.
- [Bancada 40359810049](https://github.com/CaioGuerras/heisuca/actions/runs/40359810049)
  **vermelha**, artifact **12666949950**, 7.972.683 bytes, digest
  `a4b654d118f6afa09c2c801d5141e1e5364cb5462fc2e52a7088a2643e78ab83`.
  Job completo lido pelo conector GitHub. O percurso chegou a **11-voce**:
  flags padrão desligado/PiP padrão/áudio FGS/transporte/áudio após fechar
  PiP **todas verdadeiras**, reabertura e Back único devolveram à ficha.
  Assim, ACTION_DISMISS foi exercitada no percurso real; não é só a sonda.
  **Sem ANR**, restauração confirmada.
- Motivo ainda a detalhar: Flutter encerrou com **Multiple exceptions (6)**.
  O log público só imprime as últimas 60 linhas; não contém as seis causas
  originais. **Não ignorar exceções, não classificar como infraestrutura e não
  fechar a M.** Ler os blocos EXCEPTION CAUGHT do execucao.log já redigido.
  Também conferir imagens 21 e 06 e os logs detalhados do VO; as flags do teste
  não substituem prova da imagem restaurada.
- Caio respondeu que **ainda não testou esse cenário no aparelho**. Portanto
  não há confirmação física de que o defeito é exclusivo do emulador.
- Ambiente de execução ficou **unavailable**; exec-server transport disconnected.
  Nenhuma alteração local perdida: último código/testes **442d345**, checkpoint
  **2f9eae5** já enviados. Sem Flutter/arquivos locais acessíveis enquanto durar
  a indisponibilidade. GitHub conectado continua acessível para leitura e registro.
- **M aberta, N/O não iniciadas**, versão **2.0.31+32**. Próximo passo é ler as
  seis exceções e a evidência visual desse artifact, antes de propor correção.

### M — limite de diagnóstico autorizado e regressão do HUD (26/10, 17h26 UTC)

- Caio limitou a prova adicional no emulador a **30 minutos (até 17h54 UTC)**;
  ao vencer, registrar o resultado e seguir N → O. Ele verificará o PiP no celular.
  Isso autoriza avançar com a pendência explícita; **não torna a bancada verde**
  nem classifica defeito do app como infraestrutura. Cenário físico ainda não testado.
- Leitor [40364703064](https://github.com/CaioGuerras/heisuca/actions/runs/40364703064)
  inspecionado: as seis exceções são **RenderFlex overflow** no cabeçalho
  (149/161 px), transporte (7,2/20 px) e coluna (212 px) do HUD durante PiP,
  com janela de **240,8 × 108,2 dp**. Não são ANR.
- Causa: o pai já oculta o HUD em PiP, mas só recebia onPipChanged, posterior
  ao redimensionamento. A correção usa o aviso de entrada do Android
  (onPictureInPictureUiStateChanged/isTransitioningToPip na API 35, com
  onUserLeaveHint nas anteriores e entrada manual antecipada), preservando
  a distinção entre transição e modo ativo. Saída/cancelamento limpam o aviso.
  Não encolhe botões nem recorta/ignora erros de layout.
- Regressão de widget cobre a janela real **antes** do callback de modo ativo,
  permanência em PiP e restauração do HUD. Prova anterior: seis erros reais
  na bancada 40359810049; prova posterior **ainda pendente no CI**.
- Capturas 21 e 06 desse artifact foram lidas: **pretas**. A correção do HUD
  não é apresentada como correção do vídeo. Nenhuma alteração especulativa
  em mpv, Surface, filtros, foco, navegação ou temporização.
- Ambiente continua indisponível: portão local impossível; conforme AGENTS.md,
  validação pelo portão completo do Actions. M permanece 2.0.31+32.

### M — prova adicional encerrada dentro do limite do Caio (26/10, 17h46 UTC)

- Autorização mais recente: no máximo mais 30 minutos no emulador, depois
  registrar e seguir N → O; Caio verificará PiP no celular. Prazo combinado
  17h24–17h54 UTC; investigação adicional encerrada às 17h46, sem nova tentativa.
- Código **0e3d77320ca4d02fbfb8525f9e373ead70dcd68c** (sem skip), mesma versão
  **2.0.31+32**. Antecipar o aviso de entrada do PiP segue o ciclo do Android,
  e o teste isolado de 240,8 × 108,2 dp passou localmente e no portão do CI.
  **Isso NÃO eliminou as seis exceções na integração real.** A hipótese de que
  bastaria antecipar esse aviso foi insuficiente; não apresentar como correção
  comprovada do defeito completo. Não foram ignoradas exceções nem alterados
  mpv, filtros, navegação, foco ou prazos para obter aprovação.
- [APK 40368590970](https://github.com/CaioGuerras/heisuca/actions/runs/40368590970)
  **verde**, portão completo aprovado, pacote `app.heisuca.player.teste.home`,
  97.072.446 bytes, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 **29ac54e9e5130e5b59f6f07fe5f6825223dc4f6b04643f4fd31fcfa0a1783c6c**.
  [Artifact 12673205246](https://github.com/CaioGuerras/heisuca/actions/runs/40368590970/artifacts/12673205246),
  ZIP 50.367.662 bytes; digest
  `d615ebe5dd792012806f547a47ee1ed82e019f5d049788a2f139994568e1ecc0`.
  Conferido no job; download direto do artifact segue bloqueado por 403,
  portanto não foi recalculado localmente.
- [Bancada 40368590994](https://github.com/CaioGuerras/heisuca/actions/runs/40368590994)
  **vermelha**. Artifact **12672787527**, 8.113.970 bytes, digest
  `a2de6f56d94c9817158f5bd100b7a1cd770ea766705f0d006c5d244a06176337`.
  Percurso terminou os 20 marcos; serviço/MediaSession/áudio após fechar PiP
  confirmados, 3,202 s avançados no primeiro trecho. Back único recebido,
  ficha/busca/Início e abas acessíveis. **Sem ANR do app**; restauração
  confirmada (progresso, assistido, contagem, data e preferências).
- [Leitura 40371170100](https://github.com/CaioGuerras/heisuca/actions/runs/40371170100)
  inspecionada: persistem overflows de cabeçalho/transporte/coluna nas
  dimensões do PiP. **21-imagem-apos-audio continua preta; 06-player está
  preta com indicador de carregamento.** Miniaturas lidas visualmente;
  indicadores de faixa/posição não são prova de imagem restaurada.
- A bancada não foi classificada como infraestrutura e a M **não recebeu
  aprovação integral**. Avançamos à N exclusivamente pela autorização acima,
  conservando a pendência do layout/retorno de imagem e o teste físico do Caio.
  Não há prova de que seja defeito exclusivo do emulador.
- Ambiente local voltou; sincronizado por `git pull --ff-only` no mesmo ramo.
  Nenhum ramo/PR/merge criado. N preparada localmente; ainda não entregue.

## N — servidor real no login e fluidez do próprio Flutter — 2.0.32+33

- A M permanece com a pendência descrita acima; avanço N → O autorizado pelo
  Caio após limitar a investigação adicional no emulador. Não apagar/ignorar
  as falhas da M para dar verde à bancada.
- Login: componente `HeisucaServerStatus` consulta `/System/Info/Public` pelo
  `JellyfinEndpointDiscovery` existente. Espera 500 ms após digitação, aborta
  a requisição a cada mudança de texto/dispose e rejeita respostas antigas.
  Campo vazio não tem indicador; uma letra não anuncia servidor. Nome e versão
  vêm da resposta; não há CGSERVER nem bolinha repetida. O endereço sondado
  segue a mesma normalização https do login direto, sem alterar o prazo de 8 s
  nem a autenticação da etapa K. Movimentar o cursor não reinicia a sonda.
- “Outros servidores e pastas locais” conserva um único ícone de adicionar.
  Os dois scripts citados no retorno também perderam a afirmação falsa de
  servidor pronto; o esboço estático não finge uma resposta de rede. Scripts
  foram compilados para verificar sintaxe, **não foram executados/publicados**.
- Os três níveis reais já estavam na H (Reduzido/Padrão/Topo de linha), e suas
  regressões continuam no portão. Nenhum novo critério de RAM ou redução de
  efeitos; não medimos o Tab A9 fisicamente.
- “Medir fluidez” coleta `FrameTiming` do Flutter por 20 s, continua quando o
  popup fecha e conserva o resultado só na memória. Taxa da tela lida no toque;
  limite = 1000/Hz. Detalhes recolhidos: contagem, p50/p90/p99 de construção,
  rasterização e total, e % em que construção ou rasterização excede o limite.
  Total inclui fila e não é somado ao tempo das etapas paralelas para decidir
  atraso. Classificação descritiva: até 10% boa, até 30% pode melhorar, acima
  baixa. Não é benchmark do vídeo nem altera os efeitos automaticamente.
- **Antes/depois:** teste da tela real com uma letra falhou no código anterior
  ao encontrar “● CGSERVER · Jellyfin pronto para autenticar”; passou após
  substituir o indicador. Sonda falsa cobre resposta, erro, debounce, aborto,
  resposta antiga e dispose. Teste do botão mudou a tela de 60 para 120 Hz
  depois de abrir o popup: falhou ao usar 60 capturados no build e passou ao
  ler 120 no toque. Quadros falsos comprovam percentis, 50% de atraso a 120 Hz,
  fim da coleta, continuidade fora do popup e ausência de resultado inventado
  quando não há quadros. Os testes existentes de layout estreito/fonte grande
  continuam passando; os testes agora rolam até “Detalhes técnicos”.
- Portão local completo **APROVADO**: **628 Flutter, 3 ignorados; 8 Impeller;
  37 Python**. Análise sem erros fatais. `git diff --check` e sintaxe Python
  aprovados. Preservados Início do Jellyfin, arquivos golden e correções K.
- Commit/run/APK: serão registrados após o push e inspeção do Actions.
  **Não testado em aparelho:** sondagem em redes reais, medição no Tab A9/Edge,
  taxa variável durante a coleta e apresentação visual física. A bancada
  automática ainda exercita o percurso da M, cuja pendência não fica resolvida
  pelos testes unitários da N.
- N enviada em **c1d466ebc5c04bb063aa68472023e66b94b58b15**, sem skip.
  Aguardar e inspecionar [APK 40387651870](https://github.com/CaioGuerras/heisuca/actions/runs/40387651870)
  e [bancada 40387651901](https://github.com/CaioGuerras/heisuca/actions/runs/40387651901).
  Nenhum resultado verde presumido. Revisão da M preparada em
  `docs/DIAGNOSTICO_M_PIP_2026-10-26.md`, incluindo a ordem favorável simulada
  pelo teste isolado e a falta de prova da ordem real dos callbacks/métricas.

### N — resultado dos runs inspecionados

- Código **c1d466ebc5c04bb063aa68472023e66b94b58b15**, **2.0.32+33**.
  [APK 40387651870](https://github.com/CaioGuerras/heisuca/actions/runs/40387651870)
  **verde**, portão completo aprovado também no CI. Pacote
  `app.heisuca.player.teste.home`, 97.072.446 bytes, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 **5bcd2a1d7960a0606e525429508b325eecf3cae8ae6a1bc8015c38d404a02a22**.
  [Artifact 12680944377](https://github.com/CaioGuerras/heisuca/actions/runs/40387651870/artifacts/12680944377),
  ZIP 50.371.395 bytes, digest
  `529af72dea4dd396c146f2f809b116745ce53f4dabbf3219be36d44f42c247ab`.
  Conferido pelo verificador do job, sem recálculo local do download bloqueado.
- [Bancada 40387651901](https://github.com/CaioGuerras/heisuca/actions/runs/40387651901)
  **vermelha**, artifact **12682405588**, 8.461.342 bytes, digest
  `6f3b724d67799a7b9e83212f95c5e7aeaa53166b65ef20edc240deeabb7288ab`.
  [Leitura 40390020895](https://github.com/CaioGuerras/heisuca/actions/runs/40390020895)
  inspecionada: repetiu os erros do HUD em janela pequena, nos mesmos
  `video_controls_header.dart:59`, `mobile_video_controls.dart:387/:237` da M.
  Todos os 20 marcos terminaram; as cinco flags fora do app verdadeiras,
  3,403 s avançados no trecho inicial, Back recebido, restauração confirmada,
  diagnóstico nativo disponível e **anrDoApp=false**. Não foi encontrada falha
  nova de login; o percurso real autenticou e navegou. Medição do popup foi
  provada por widget com quadros falsos; não foi exercitada fisicamente.
- Não chamamos a bancada de verde/instável. **N implementada e com APK verde,
  conservando a pendência da M**; avanço à O pela autorização expressa do Caio
  para não manter essa prova bloqueando N/O. Nenhum novo ciclo de investigação
  da M foi aberto; a leitura acima confere o run automático obrigatório da N.

## O — análise concluída; implementação parada para revisão dos contratos

- Atendendo à instrução mais recente do Caio (“se estiver travada em alguma
  parte, pare e me dê o diagnóstico, eu envio para o Claude analisar”), parei
  no cruzamento dos contratos antes de publicar uma adaptação parcial.
- Diagnóstico concreto: `docs/DIAGNOSTICO_O_COMPATIBILIDADE_2026-10-26.md`.
  Base mais próxima **Plezy 2.22.0** (34 tags comparadas contra `612b0a6`),
  matriz em `docs/pesquisa_rodada2/BASE_PLEZY_COMPARADA_2026-10-26.json`.
  Origem registrada em AGENTS.md e apps/app/CLAUDE.md. Notas reais da 2.23/2.24
  e commits de origem conferidos, corrigindo as atribuições do Gemini.
- Pontos para revisão: esquema próprio **23** versus patch de coleções que
  pressupõe **24 → 25**; helper de prévia pressupõe `MediaSourceInfo.partTimeline`,
  ausente no nosso modelo; pacote nativo muda de TAR com headers para AAR.
  Isso não prova que todas as funções sejam incompatíveis. O diagnóstico
  distingue dependências necessárias de adaptações possíveis e não assume
  incompatibilidade de ABI. Estão descritas duas rotas para o banco.
- BIF: reproduzida a cópia adicional do arquivo por isolate com teste negativo
  (esperado 254, obtido 16); log em `docs/evidencias/o_bif_antes_2026-10-26.txt`.
  O teste negativo não ficou ativo no portão. Nenhuma correção foi proclamada.
- AAR de origem baixado e SHA-256 completo conferido; símbolos JNI relevantes
  existem e a classe de callback coincide após normalizar pacote/espaços.
  Ainda não foi integrado/compilado no Heisuca. Nenhum binário foi commitado.
- Estudo parcial do buffer HTTP foi **revertido antes da parada**. Código do
  app, testes ativos, pubspec e Android voltaram exatamente a `c1d466e` (N).
  Sem APK/versão nova da O; **continua 2.0.32+33**. Próxima O: **2.0.33+34**.
- Também documentados os recursos já existentes (identidade de faixa, regras
  keep-N, políticas/bridge DV7 e prompt por temporizador), para não recriá-los
  a partir das lacunas desatualizadas do relatório. O não foi marcada pronta.
- Pendente: revisão do Claude/retomada da O e prova física de PiP pelo Caio.
  Último APK verde continua o artifact **12680944377**, run **40387651870**.

### Confirmação física recebida de Caio — 26/10/2026

Caio informou nesta conversa: **“O PiP está funcionando, acabei de testar”**,
com o vídeo `VID-20261026-WA0023.mp4` (anexo da conversa; não publicado no
repositório). SHA-256 do anexo recebido:
`6ac9c9a524c4b98e106fb58028104c239ef0dad44def2f732bf35ba9e707c08d`.
É uma confirmação do usuário em aparelho real para PiP; não muda retroativamente
o resultado vermelho da bancada nem prova, por si só, o cenário específico de
“Continuar ouvindo ao sair” ligado → Home do Android → voltar ao vídeo. O relato
não identifica o número do APK instalado. Sem novas execuções para investigar M.

### O parcial autorizada — em implementação sobre 54d6053

Escopo decidido por Caio/Claude: Novidades próprias e manuais, motivos de conversão
informados pelo Jellyfin na reprodução ativa, pergunta por N episódios sem interação
reutilizando o prompt, e BIF como falha conhecida executável. Versão alvo 2.0.33+34.
Nenhum port de BIF/partTimeline, migração do esquema 23, pacote nativo/AAR,
estimativa/automação por temporada ou conferência física de DV7: são etapas
separadas, dependentes de aprovação. A N e as correções K permanecem.
Resultados do portão, commit e APK serão acrescentados após inspeção real.

### Retomada solicitada em 27/10 — handoff Whatbox indisponível neste ambiente

O portão local da O parcial terminou **APROVADO** (`/tmp/o-gate.log`),
incluindo os 8 testes Impeller. Alterações locais ainda sem commit/push;
HEAD permanece `54d6053`, pubspec local em 2.0.33+34. Nenhum run de APK
desta implementação foi iniciado.

Caio pediu assumir a seção 2 de
`~/cgflix/handoffs/2026-10-26_claude_para_codex_whatbox.md`. Esse arquivo
não existe no HOME deste executor (`/home/agent`) nem foi encontrado em
`/workspace`, `/home/agent` ou na árvore remota do ramo após fetch.
Sem ferramentas/conexão Whatbox disponíveis nesta sessão. Aguardando o
conteúdo ou localização acessível do handoff antes de executar instruções
que ainda não puderam ser lidas. As alterações locais foram preservadas.

### O parcial — entrega Ultron, 27/10/2026 — 2.0.33+34

O comando de handoff da Whatbox foi cancelado pelo Caio: destinava-se à Jocasta,
não a este executor. **M fechada no aparelho real por decisão explícita do Caio**,
que confirmou o PiP. A bancada histórica permanece com seus resultados originais;
nenhum run adicional foi disparado para investigar M.

Implementação própria, sem copiar código do Plezy:

- **Novidades:** tela com paleta Heisuca, Sora/Inter e selo; entrada no Sobre e
  aviso discreto uma vez por versão, restritos à fonte Jellyfin. Texto escrito
  à mão em `apps/app/assets/heisuca/CHANGELOG_USUARIO.md`, incluído no app e no
  mesmo artifact do APK. Conta a origem próxima do Plezy 2.22.0 e o fork independente.
- **Esta reprodução:** nos ajustes do player, mostra o método efetivo da sessão
  e traduz `TranscodeReasons` da URL negociada pelo próprio Jellyfin. O snapshot
  acompanha o resultado da inicialização/troca de fonte; não infere motivos dos
  codecs do arquivo nem usa o motivo de fallback como motivo de conversão.
  Ausência e código desconhecido são declarados; nenhum token/URL é exibido.
- **Ainda está assistindo?:** amplia o prompt existente. Padrão 3 episódios;
  quantidade configurável em Reprodução, 0 desliga só essa condição. EOF aceito
  conta uma vez; toque, tecla e comandos explícitos de transporte reiniciam a
  contagem. Antes de avançar, pausa e aguarda resposta. Continuar abre o próximo;
  o temporizador conserva o prazo. Parar no fim do vídeo tem prioridade.
  Watch Together conserva sua própria política (não aplica esta contagem).
- **BIF:** reprodução negativa executada no portão, marcada XFAIL, esperado 254,
  obtido 16. Não é teste ignorado: só aceita a falha conhecida; XPASS ou resultado
  diferente falham e exigem revisão. Código do BIF intacto.

**Portão local completo aprovado**, `/tmp/o-gate.log`: 843 testes Flutter,
3 ignorados já existentes, 8 Impeller e 37 Python. Análise sem erros fatais;
`git diff --check` passou. O portão inclui os testes reais de negociação Jellyfin,
reload/EOF do player e temporizador. Prova negativa com o caminho anterior do
prompt: esperado true, obtido false; com a implementação nova, pausa, EOF duplicado,
31 segundos de espera, Continuar/abertura do próximo e prioridade do temporizador
passaram. O temporizador de 20 minutos manteve o mesmo prazo. Aviso Jellyfin único,
ausência no Plex e texto ampliado em 320 px também cobertos.

**Fora desta entrega, por decisão do Caio:** port da prévia/BIF (`partTimeline`),
coleções offline (migração a partir do esquema 23), pacote nativo do mpv/AAR,
estimativa/automação por temporada e conferência física de DV7. Cada parte exige
etapa própria aprovada. Não alterados seleção semântica de faixas, executor de
sincronização, políticas DV7, fontes da N ou correções K/rota de retorno.

**Revisão independente pendente:** Jarvis, Visão e Jocasta conferem a entrega.
Testes locais do autor não representam aprovação deles nem teste físico dos novos
fluxos. Não foi publicado APK em produção ou em servidor de teste por este executor.
Commit e números dos runs são registrados abaixo após o push; a bancada deste push
é a execução automática exigida para a entrega, não uma retomada da investigação M.

#### Commit e execuções disparadas — O parcial

- Código: `b73790d8cb0a5e1f6d85d3a52e2804900f198cf9`, enviado ao ramo
  `codex/heisuca-home-site`, sem `[skip ci]`, versão **2.0.33+34**.
- APK: [40427906574](https://github.com/CaioGuerras/heisuca/actions/runs/40427906574).
- Bancada: [40427906497](https://github.com/CaioGuerras/heisuca/actions/runs/40427906497).
- Ambos consultados pela API do GitHub: **em andamento**, ainda sem conclusão.
  Artifact, certificado e SHA-256 deste APK ainda não estão disponíveis para
  conferência. Não foram presumidos verdes. Jarvis/Visão/Jocasta fazem a revisão
  independente e a publicação do pacote de teste. Nenhuma publicação realizada
  pelo Ultron. Código do BIF e lock nativo não foram alterados.

### Correção da O parcial — revisão Visão, 27/10 — 2.0.33+35

Base `3cc295c`. Cada defeito foi convertido em teste antes do patch. Provas
negativas na implementação anterior, com os novos testes e as dependências
coerentes restauradas temporariamente a partir da base (depois repostas):

- `docs/evidencias/o_correcao_news_antes_2026-10-27.txt`: toque na pílula real
  `heisuca-nav-3` com SnackBar pendente não encontra `HeisucaProfileScreen`;
  teste do asset empacotado encontra `Caio` no changelog.
- `docs/evidencias/o_correcao_sleep_antes_2026-10-27.txt`: aviso de sono visível,
  EOF e limite 1 não registram o pedido de episódio (esperado true, obtido false),
  nas variantes Continuar e Pausar. O harness carrega fonte real para não medir
  o texto do prompt com a fonte Ahem de teste. Não houve patch em overflows do HUD.

**Causa e correção:**

1. Removido o SnackBar e seu agendamento da sessão/MainScreen, não apenas mudada
   sua posição. Nenhuma camada de aviso fica sobre o conteúdo ou a navegação.
   Novidades tem somente um ponto de 6 dp no próprio item do Sobre, com rótulo
   semântico de não lido. Persiste por versão até abrir o texto; ao voltar o
   estado local do item é reconstruído. Preferência `read` separada da antiga
   `notified`: ter recebido o aviso não equivale a ter lido. É a alternativa
   mais discreta: não disputa toque, foco ou espaço com o filme e as abas.
2. Retirada toda a seção “Em avaliação”. Texto público: “base do Plezy 2.22.0”.
   Teste carrega o asset real e proíbe Caio/bancada/emulador/Em avaliação.
3. O EOF não é mais descartado só porque o prompt de sono está visível. O latch
   continua impedindo duplicatas. Ao atingir o limite, pausa e une as duas
   intenções no mesmo prompt, preservando a necessidade de rearmar o sono.
   Continuar rearma os 20 minutos e abre o próximo; Pausar não avança.

Testes direcionados após correção: 6 de Novidades/conversão/contador e 2 do canto
sono+EOF aprovados, incluindo navegação real da pílula, leitura persistida,
texto ampliado e preservação do temporizador. Portão completo em execução;
resultado, commit e números dos runs serão registrados após consulta.

Fora do escopo e intactos: código BIF/partTimeline (xfail permanece), coleções/banco,
pacote nativo/lock mpv, DV7, seleção de faixas e HUD do PiP. M continua fechada pela
prova física de Caio; seus overflows herdados são outra etapa. A bancada do push
é a execução exigida para a entrega, sem investigação adicional da M.
Nenhum APK publicado pelo Ultron. Visão confere o percurso até `11-voce` e
`testeEncerrado: true` e publica o pacote de teste; não antecipar esse resultado.

Portão completo da correção **APROVADO**, processo encerrado com código 0:
846 testes Flutter (3 ignorados preexistentes), 8 Impeller e 37 Python.
Log local `/tmp/o-correction-gate.log`. Análise sem erros fatais e
`git diff --check` limpo. Testes do BIF permanecem XFAIL conhecido e explicado.
Nenhuma afirmação de aprovação independente ou de bancada verde nesta anotação.

#### Correção O — commit e runs enviados ao Visão

- Código `9f4073b2764b6c860598249a4e13f4cb755a5c65`, versão **2.0.33+35**,
  enviado sem `[skip ci]` ao ramo `codex/heisuca-home-site`.
- APK: [40433379758](https://github.com/CaioGuerras/heisuca/actions/runs/40433379758).
- Bancada: [40433379764](https://github.com/CaioGuerras/heisuca/actions/runs/40433379764).
- Consulta real à API após push: ambos **na fila**, sem conclusão. Pacote,
  assinatura, SHA-256 e percurso até `11-voce`/`testeEncerrado: true` ainda
  aguardam os resultados e a conferência independente do Visão. Não marcados verdes.
- Não foi publicado nenhum APK. Arquivos locais limpos após commit.

### P1 em andamento — 2.0.34+36, sem aceite de release candidate

Pedido P1–P7 recebido em 27/10. P2–P7 ainda não entregues; sem ENTREGA-FINAL.
Diagnóstico concreto: `docs/DIAGNOSTICO_P1_2026-10-27.md`.

Leitura real do artifact de 40433379764 pelo run **40439214269**: percurso
chegou até `11-voce`, `testeEncerrado: true`. As capturas nativas 06/21 estão
pretas na inspeção visual. O código da coleta já usava `adb exec-out screencap -p`.
mpv muda de `vo-configured=yes`/1920×1080 inicial para `no`/dimensões nulas
após áudio, com `vid=1`/posição avançando. Anexar Surface não prova saída real.
Causa da perda de imagem ainda não demonstrada; não foi alterado o player.

Prova negativa antes do patch de coleta: PNG preto válido recebia ACK no marco
21; teste exigindo rejeição falhou com `RuntimeError not raised`. Prova em
`docs/evidencias/p1_imagem_antes_2026-10-27.txt`. Agora a coleta lê os pixels
RGB do PNG nativo com ffmpeg, registra método e imagem sim/não, e rejeita preto
total antes do ACK. PNG ilegível também é erro. 39 testes Python aprovados.
Preservado o limite: UI não preta não comprova sozinha a obra, pede inspeção.
O leitor de artifacts também passa a imprimir extremos RGB do PNG ORIGINAL,
sem JPEG, para comprovar a ausência de pixels no arquivo coletado.

**Lista de ATENÇÃO pendente de decisão:** o mesmo run traz janela 227,8×128,0 dp
com coluna 192 px, além de 240,8×108,2 e coluna 212 px. O pedido exige lista exata
e omite o primeiro conjunto. Pergunta enviada ao Caio, sem alargar a exceção
por conta própria. Classificação em três estados ainda não entregue. Imagem
preta continua defeito vermelho, jamais entra na lista de ATENÇÃO do HUD.

Nenhuma paleta, changelog público de estabilidade/segurança, migração, AAR ou
fluxo Plex/TV foi alterado. Este commit é preparação da prova da P1, não fecha
a P1 e não é autorização para publicar o pacote. Sem teste novo em aparelho.

Portão local completo desta preparação P1 **APROVADO**, exit 0:
846 Flutter (3 skips preexistentes), 8 Impeller, 39 Python.
Log `/tmp/p1-gate.log`. Não equivale a corrigir/validar a imagem do mpv.

#### Continuidade P1 — decisão da lista e prova original

Caio autorizou largura variável **<=320 dp**, apenas erros RenderFlex nos três
pontos do HUD durante entrada/ativo/saída PiP. Fora disso continua vermelho.
Implementação da regra e teste com os mesmos erros em janela cheia: antes 3
falhas, depois 3 casos aprovados (incluem negações de fase/origem/tamanho/tipo).
Relatório/summary passam a expor estado verde/ATENÇÃO/vermelho; atenção traz a
frase exata pedida. Outros erros seguem o tratador do framework, não são engolidos.
Driver mantém a lista de avisos. Preto nativo impede ACK e continua vermelho.

Leitura dos **PNGs originais** no run **40440212912** confirmou ambos os arquivos
06/21 em 1200×540 com RGB máximo **0** em cada canal: imagem **não**, preto total.
Não é só limitação da miniatura. P1 ainda não fechada por perda real de imagem.

Commit de prova inicial `58d5f09`: APK **40440203947** falhou no portão Python,
antes de compilar: `FileNotFoundError: ffmpeg`. A dependência já era instalada
na bancada, mas faltava no job de APK. Incluída preparação explícita do ffmpeg
antes do portão nesse job, mantendo assinaturas/repositórios oficiais. É correção
da causa da diferença entre executor local e runner; testes não foram ignorados.
Bancada desse commit **40440203813** ainda em execução na última consulta.

O gh CLI passou a responder HTTP 401 durante a inspeção. Os tools do conector
GitHub continuam operacionais; logs do job 121978465720 foram lidos por eles.
Não imprimir/alterar credenciais nem iniciar login interativo.

Novo teste nativo de ressincronização será conferido no CI ANTES de patch no
player. É uma hipótese documentada, não uma correção comprovada por mock.
Nenhum commit ENTREGA-FINAL, nenhuma publicação e P2–P7 continuam pendentes.

Portão local da regra PiP aprovado: 849 Flutter (3 skips), 8 Impeller,
39 Python. Log `/tmp/p1-policy-gate.log`; Python rechecado após apresentação
do estado no relatório. Teste nativo novo ainda pendente do Actions; sem SDK
Android neste executor, não alegar falha/sucesso nativo local.

#### P1 — candidato de correção do retorno do áudio

Commit anterior `b0399d0`, APK **40441219054**, job **121981762142**:
portão passou, teste nativo novo falhou em `MpvPlayerBackgroundAudioTest.kt:25`
na ordem de ressincronização. 12 testes nativos, 1 falha. Prova preservada em
`docs/evidencias/p1_ressincronizacao_antes_2026-10-27.txt`.
Bancada desse commit: **40441219089**, ainda em andamento na última consulta.

Somente depois dessa falha foi alterado `MpvPlayerCore.setBackgroundAudio`:
reativar a faixa após ouvir sem vídeo inclui seek relativo zero exato, na mesma
fila ordenada, para ressincronizar vídeo com o ponto atual do áudio. Preserva
faixa/pausa; não busca se vídeo já estava desligado; não repete no segundo
restore; erro do seek não confirma restauro. Segue o mecanismo de ressincronização
já documentado em `rebuildVideoOutput`, sem trocar codec, shaders ou AAR.
É candidato até ter pixels reais restaurados; não basta o teste mockado.

Novo teste com HUD REAL reduzido antes do callback valida a extração de origem
da política PiP: aceita só no PiP, rejeita janela cheia. Integração exige saída
configurada também nas capturas 21/06; estado da saída fica no resultado do driver.
O Actions emite annotation de aviso quando o estado é ATENÇÃO, mantendo job
com sucesso só para verde/ATENÇÃO.

Portão local completo do candidato: 850 Flutter (3 skips), 8 Impeller e
39 Python aprovados; `/tmp/p1-sync-final-gate.log`. YAML dos workflows válido.
Teste nativo e emulador após patch ainda pendentes. Não testado em aparelho.

Candidato enviado: **2f526a1dad62d6963fa46abb7433cf237ad30cdc**, 2.0.34+36.
APK **40442922526** (job 121987264613) e bancada **40442922427** (job
121987264387) em andamento. Conferir testes nativos e pixels antes de fechar P1.
Não publicar nem emitir ENTREGA-FINAL enquanto a P1 ou P2–P7 estiverem pendentes.

Bancada pré-patch **40441219089** não testou o app: terminou no comando
`adb root` com `unable to connect for root: closed`, após cold boot concluído.
Estado vermelho/instável de infraestrutura registrado, não uma aprovação nem
regressão atribuída ao player. A nova execução do candidato já foi disparada
pelo push; não houve rerun do app para mascarar esse resultado.
