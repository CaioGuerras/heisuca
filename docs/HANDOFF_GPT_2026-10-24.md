# Handoff para o GPT: rodada Heisuca de 24/10/2026

Autor: Claude (sessão de 24/10). Dono e decisor: Caio. Responder e documentar em **PT-BR**.
Repo: `CaioGuerras/heisuca`, ramo **`codex/heisuca-home-site`** (o push nele dispara o APK em `.github/workflows/heisuca-android.yml`).
App: `apps/app` (Flutter 3.47.1, fork do Plezy). Leia antes: `AGENTS.md`, `apps/app/CLAUDE.md` (regras do fork),
`docs/PLANO_RODADA_2026-10-24.md` (desenho de cada item) e `docs/HANDOFF_CORRECOES_2026-10-24.md` (rodada anterior).

## Estado em que você recebe
- Versão **2.0.13+14** (commit `7c520ae`): pílula só com ícones (Início, Biblioteca, **Baixados**, Você; no modo infantil o 3º
  continua Favoritos); botão **Favoritos** na Biblioteca depois das bibliotecas; menu Você por assunto (Conta · Família ·
  Privacidade e segurança · App · Sair). **Nada foi testado em aparelho.**
- 2.0.12 (`de4f781`): Assistir juntos usa o relay próprio `https://heisuca.docaio.com.br/junto` (constante
  `cgflixWatchTogetherRelay` em `lib/cgflix/cgflix_defaults.dart`). O login de trackers ainda usa
  `WatchTogetherRelayEndpoint.upstreamRelayBaseUrl` (Plezy); isso sai no item 5.
- **16 testes já falhavam antes** desta rodada: lista em `docs/TESTES_FALHANDO_2026-10-24.txt`.

## Regras (sem exceção)
1. Diferença mínima do upstream: mudanças da marca em arquivos próprios (`lib/heisuca/`, `lib/cgflix/`); nos arquivos do
   upstream, só o necessário, com comentário `// CGFLIX:` ou `// Caio, 24/10:`.
2. Um commit por item, mensagem em PT-BR, terminando com a linha de coautoria que você usar. Suba a versão no `pubspec.yaml`
   (2.0.14+15, 2.0.15+16, …) a cada item que gera APK. Não abra PR para o upstream; não faça merge no `main`.
3. Antes de cada commit: `flutter analyze` sem erro/aviso novo nos arquivos tocados e `flutter test` dos testes ligados.
   Compare com `docs/TESTES_FALHANDO_2026-10-24.txt`: **nenhuma falha nova**. Teste que muda por decisão do Caio é atualizado
   com comentário dizendo por quê.
4. Não afirme "funciona" sem prova. Diga "não testado em aparelho" quando for o caso.
5. Sem segredos, tokens ou telemetria no código, nos logs ou nos workflows.
6. Se algo do desenho não fechar com o código real, **pare e documente** a divergência em vez de improvisar.

## Itens (nesta ordem)

### 1. Ficha da pessoa: filmografia de todas as fontes + "Também atuou em"
- **Fato novo (print do Caio, 24/10):** Stranger Things aparece na busca, mas **não está no CGSERVER** (nem no Jellyfin, nem
  no Sonarr). Os cartões têm selos de Kometa ("4K UHD", "ENCERRADA", "DD+ATMOS", nota IMDb) e sinopse em inglês. Ou seja,
  vem de **outro servidor Plex da conta do Caio**. A ficha da Sadie Sink consulta só a fonte do item aberto
  (`fetchPersonMedia` em `lib/services/jellyfin_client/parts/browse.dart`, tipos `Movie,Series`), por isso mostrou só o filme.
- **Fazer:**
  - **"No acervo":** juntar o que a pessoa fez em **todas as fontes conectadas** (Jellyfin e Plex), casando a pessoa por nome
    e, se houver, pelo id TMDB. Remover duplicatas como a busca unificada já faz (`cgflixUnifiedSearch`); o título fica com
    a melhor fonte.
  - **"Também atuou em":** filmografia do TMDB pelo Seerr (`GET /api/v1/person/{tmdbId}/combined_credits`; o cliente do Seerr
    já existe em `lib/models/seerr/` e `lib/cgflix/requests/`), só com o que não está em "No acervo", com o botão **Pedir**
    igual ao da busca. No modo infantil (`heisucaKidsActive`), só "No acervo" e nada de pedir.
- Arquivos: `lib/screens/actor_media_screen.dart` e o cliente Plex equivalente. Teste com a Sadie Sink: devem aparecer o filme
  e Stranger Things.

### 2. Player: episódios no título, sem botão Próximo, ajustes à direita
- HUD real: `lib/heisuca/player/heisuca_player_hud.dart` (+ `lib/widgets/video_controls/mobile_video_controls.dart`).
  `lib/heisuca/heisuca_player_screen.dart` parece **sem uso**: confirme com grep e, se for o caso, apague-o em commit próprio.
- **Topo esquerdo:** **logo** da série (imagem `Logo` do Jellyfin ou `clearLogo` do Plex), com o título em texto como reserva.
  Embaixo, pequeno: "T5 · E16 · nome do episódio". **Tocar no logo abre o seletor de episódios da SÉRIE**: abas de
  temporada, lista com miniatura, progresso e duração, rolando já até o episódio atual. Tocar num episódio troca o play.
- **Remover o botão Próximo.** Mantenha o cartão "Próximo episódio" perto do fim e a chave "Próximo episódio sozinho".
- **Ajustes num grupo alinhado à direita** (legendas/áudio, velocidade, ajustes), com espaçamento uniforme.
- Filme: sem seletor; o logo só mostra o título.

### 3. Medidor do aparelho
- Base: `lib/services/device_performance.dart` (níveis completo/reduzido).
- Nova tela **Você › App › "Este aparelho"**, com medidor de 3 faixas e texto simples:
  - **Verde "No máximo":** tudo ligado.
  - **Âmbar "Com ajustes":** lista o que foi cortado e o motivo (desfoque, parallax, pré-carregamento etc.; use os portões
    reais que o `isReduced` desliga).
  - **Vermelho "No limite":** "Este aparelho roda melhor o Heisuca Lite (em breve)". Regra inicial: processo 32 bits **e**
    RAM ≤ 2 GiB, ou sinal de pouca memória do sistema. Documente a regra no código.
- Mostre também os fatos: RAM, 32/64 bits, decodificação por hardware disponível (se o mpv informar).

### 4. Refinos visuais
- **Parallax** no destaque da Início e na capa da ficha (fundo mais lento que o conteúdo). Desligado quando
  `DevicePerformance.isReduced`.
- **Transições:** pôster → ficha com Hero (a capa voa para a ficha); entre abas, fade-through; sheets com mola. **Uma curva e
  uma duração** definidas num lugar só (`lib/heisuca/heisuca_theme.dart` ou `heisuca_design_system.dart`), usadas em tudo.
- **Ícone do app:** **não troque.** Faça 3 variantes, renderize PNGs de 512 px e um mockup lado a lado numa tela inicial
  Android, em `docs/icone_variantes_2026-10-24/`. O Caio escolhe depois.
  **Base (corrigida em 24/10, noite): o selo 炳 do Heisuca**, que é o "esboço C, selo hanko" escolhido pelo Caio em 18/10.
  Arquivos: os ícones atuais por tema em `apps/app/assets/heisuca/icone_*.svg` (ponto de partida: `icone_shikkoku.svg`),
  o selo oficial em `docs/marca/C_selo.svg`, a versão pequena em `docs/marca/C_icone_pequeno.svg`, a folha por tema em
  `docs/marca/FOLHA_C_TEMAS.png` e as regras em `docs/marca/LOGO.md` e `docs/marca/ICONES.md` (cor do selo segue o tema;
  ≤ 32 px usa a versão pequena). **Não use** `apps/app/cgflix-brand/` ("C com play"): é a marca antiga do CGFLIX.
  Ideias para as 3 variantes: selo com relevo/gradiente sutil; fundo com textura de laca; variante temática monocromática
  do Android 13. O caminho `cgflix/pesquisa_apps/marca` citado antes fica fora deste repositório.

### 5. Remover MAL/AniList (decisão do Caio, 24/10)
- Tirar da interface tudo de MyAnimeList e AniList (configurações, telas de login por QR, chamadas).
- O cliente `lib/services/trackers/oauth_proxy_client.dart` deixa de ser usado; remova também
  `WatchTogetherRelayEndpoint.upstreamRelayBaseUrl` se ficar sem uso. **Trakt continua.**
- Depois disso, nenhuma chamada do app vai para `ice.plezy.app` (confirme com grep e cite o resultado no handoff).

**Decisão para a divergência do item 5 (Claude, 25/10; objetivo do Caio: nenhuma chamada ao servidor do Plezy):**
- Remover MAL/AniList e o `oauth_proxy_client.dart`; apagar `WatchTogetherRelayEndpoint.upstreamRelayBaseUrl`.
- **Discord RPC:** a presença continua (título, episódio, tempo), mas **sem upload de capa**: retirar `_posterUploadUrl` e o
  POST em `discord_rpc_service.dart`; a imagem grande passa a ser o ícone do app (chave de asset da aplicação Discord,
  ou nenhuma imagem). Nenhum endpoint substituto.
- **Envio de diagnóstico:** já desligado (`cgflixAllowLogUpload = false`); retirar o endereço `ice.plezy.app` de
  `log_upload_service.dart` (o botão "Copiar logs" continua). Os testes do upstream que exercitam o envio passam a usar
  um endereço de teste injetado, não o do Plezy.
- Critério de pronto: `rg -n 'ice.plezy.app' apps/app/lib` sem resultado; Trakt intacto.

### 6. Transmitir para TV: NÃO fazer (decisão do Caio, 24/10)
- O Android já tem transmissão nativa. Não crie botão nem tela de transmissão.

### 7. Testes que já falhavam
- Corrija ou atualize os 16 de `docs/TESTES_FALHANDO_2026-10-24.txt`, cada um com o motivo (código mudou de propósito ou
  bug real). Bug real é corrigido no código, não no teste.

### 8. Logo do título quando o servidor não tem (decisão do Caio, 24/10)
- Hoje: player, destaque e ficha usam `clearLogoPath`; o Plex do CGSERVER não tem logo de vários títulos (ex.: Ranma ½,
  ratingKey 11406, só `coverPoster`/`background`), então aparece o nome escrito. Análise em `docs/PLANO_RODADA_2026-10-24.md`.
- **Fazer:** um resolvedor único de logo, usado por player (`heisuca_series_episodes.dart`), destaque e ficha:
  (1) logo do próprio servidor; (2) se faltar, o mesmo título no **Jellyfin do CGSERVER** conectado no app, casado por
  TMDB/TVDB/IMDb (`ProviderIds`; no Plex vêm dos `Guid` `tmdb://`, `tvdb://`, `imdb://`), usando a imagem `Logo` de lá;
  (3) senão, o texto. Guardar o resultado em cache por título. Nunca chave de API no app. Sem Jellyfin do CGSERVER
  conectado, só (1) e (3).
- Teste: fixture Plex sem logo + Jellyfin com logo para o mesmo TMDB → usa o do Jellyfin; sem correspondência → texto.

### 9. Início igual nas duas fontes (decisão do Claude, autorizada pelo Caio, 24/10)
- Hoje `heisuca_home_screen.dart` tem `_buildJellyfinSlivers` (padrão do site, aprovado no 2.0.2) e `_buildDiscoverSlivers`
  (Plex, hubs herdados do Plezy). **Fazer:** a mesma montagem para Plex: destaque, Continuar, fileira por biblioteca na
  ordem do servidor (sem os hubs genéricos do Plex, como "Oh, The Horror!").
- **Em alta e Em breve:** vêm do CGSERVER (`/cgflix/emalta.json`, `/cgflix/embreve.json` e calendário Sonarr/Radarr).
  Mostrar quando a fonte ativa é o CGSERVER: o Jellyfin dele **ou o Plex do CGSERVER** (servidor Plex chamado "CGFLIX",
  `machineIdentifier` 056b61fd61d67e9656ec915d38e21294a99dbbba). No Plex, casar cada entrada pelo TMDB/TVDB com o item da
  biblioteca Plex; o que não tiver item segue o fluxo atual (busca de pedidos). Em servidores Plex de outras pessoas, não
  mostrar essas duas fileiras.
- Manter o resultado aprovado do Jellyfin idêntico (testes de regressão da Início do Jellyfin).

### 10. Ícone escolhido: variante 1 (Caio, 25/10)
- O Caio escolheu `docs/icone_variantes_2026-10-24/01_relevo` (relevo e gradiente sutis). **Aplicar** no ícone instalado
  do tema padrão (Shikkoku): ícone adaptativo do Android (fundo + primeiro plano), versão monocromática do Android 13
  (a partir do selo, sem o relevo) e ícones de notificação/pequenos conforme `docs/marca/ICONES.md` (≤ 32 px usa a versão
  pequena). Repetir o mesmo tratamento nos ícones dos outros temas (`icone_hisui`, `icone_ichigo`, `icone_sorairo`,
  `icone_shinju`) se o app usa ícones alternativos por tema. Conferir em 48 px que o 炳 continua legível.

## Fora do seu escopo (servidor; ficam com o Claude)
- Conferir que o Sonarr não baixou o DanMachi de novo (correção dos formatos de 24/10).
- Vigia de leitura sem play e de reimportação repetida; Attack on Titan reimportado 3×; análise MediaInfo dos episódios antigos.
- Relay `heisuca-relay` na VPS. Não mexa em servidor, VPS, Sonarr ou Jellyfin.

## Entrega
- Um handoff `docs/HANDOFF_GPT_ENTREGA_<data>.md`, item por item: o que mudou (arquivos), commit, testes rodados (comando e
  resultado), o que não foi testado e divergências achadas.
- O link do APK de cada versão (Actions do ramo), conferindo que o run terminou verde.
