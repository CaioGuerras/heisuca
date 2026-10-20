# Refino 2 — menus, ícones, textos e dicas (1.6.0, versionCode 800)

Ordem de serviço do dono (11/10). Omakase: o app vem arrumado do jeito que o dono usaria; nada foi removido, o
técnico só saiu da frente. Código novo em `lib/cgflix/`; nos arquivos do Plezy, ganchos curtos marcados `CGFLIX`.

## A. Menus: ordem antiga → ordem nova

| Menu | Ordem antiga | Ordem nova | Por quê |
|---|---|---|---|
| Menu do usuário (emblema) | Favoritos · Bibliotecas · Meus pedidos · Baixados ─ Configurações · Trocar usuário · Sobre · Sair ─ Apoie | Favoritos · Baixados · Meus pedidos · Bibliotecas ─ *Ajustes e ajuda*: Configurações · Sobre e dicas ─ *Conta*: Trocar usuário · Sair ─ Apoie | Favoritos e Baixados são semanais; Bibliotecas (ver tudo) é eventual. Conta (trocar/sair) junta e embaixo, longe de toque sem querer. "Sobre e dicas" diz onde estão as dicas. Apoie continua o último |
| Configurações (tela principal) | Geral · Aparência · Reprodução · Gerenciar bibliotecas · Serviços ─ Conexões (aberto: Adicionar conexão · Perfis · Preferências da conta) ─ Baixados ─ Cópia de segurança ─ Avançado ─ Sobre ─ Apoie | Ao assistir · Áudio, legenda e conta · Aparência · Geral ─ Baixados ─ Contas e servidores (fechado: Adicionar conexão · Perfis · Organizar bibliotecas · Serviços) ─ Avançado (+ Cópia de segurança) ─ Sobre ─ Apoie | O que mexe no dia a dia (assistir, idioma do áudio/legenda, tema) em cima. Conexões quase nunca muda depois do primeiro acesso: fechado. Exportar/importar configurações em arquivo é técnico: Avançado |
| Ao assistir (era "Reprodução de vídeo") | Reprodutor · Vídeo e tela · Áudio (aberto) · Qualidade · Legendas (aberto) · Avançar e voltar · Reprodução automática e pular trechos · Comportamento · Gestos · Lembrar ajustes | Pular abertura e próximo episódio (aberto) · Legendas (aberto) · Gestos · Avançar e voltar · Comportamento · Reprodutor · Vídeo e tela · Áudio (fechado) · Qualidade · Lembrar ajustes | Pular abertura/próximo episódio e legenda são o que a pessoa procura; reprodutor, HDR, canais de áudio e qualidade (o servidor não converte vídeo) são técnicos e foram para baixo |
| Pular abertura e próximo episódio (dentro de Ao assistir) | Próximo automático · Aleatório do início · Contagem · Pular abertura · Pular créditos · Detectar pelos capítulos · Espera · Nome do capítulo de abertura · Nome do capítulo de créditos | Pular abertura (com "?") · Pular créditos · Próximo episódio sozinho · Contagem · Espera · Aleatório do início — *Avançado*: Detectar pelos capítulos · Nomes dos capítulos | "Detectar pelos capítulos" fala do Plex e os nomes são expressões regulares: técnico, vai para o Avançado (sem repetir em dois lugares) |
| Menu do título (cartão e ⋮ — o mesmo menu no Plezy) | Assistir do início · Trailer · Marcar · Tirar de Continuar · Ver detalhes · Avaliar · Editar (admin) · … · Versão · Informações do arquivo · Outro player · Baixar · Lista para assistir · Adicionar a… · Excluir | Ver detalhes · Assistir do começo · Ir para a série · Aleatório · Trailer ─ Baixar · Lista para assistir · Adicionar a… ─ Marcar · Tirar de Continuar · Avaliar ─ Outra versão · Detalhes técnicos · Outro player ─ Editar/Etiqueta/Corrigir (admin) ─ Excluir do servidor | Primeiro o que leva a assistir, depois o que guarda para depois; técnico e administração embaixo; apagar sempre o último, separado |
| Ajustes do vídeo (engrenagem no player) | Velocidade · Zoom · Versão e qualidade · Desligar automaticamente · Atraso do áudio · Atraso da legenda · HDR · Próximo automático · Saída de áudio · Nivelar volume · Canais · Filtros · Luz ambiente · Painel de desempenho · Informações do arquivo | Versão e qualidade · Velocidade · Próximo episódio sozinho · Zoom · Desligar automaticamente ─ *Som e legenda*: Atraso do áudio · Atraso da legenda · Saída · Nivelar volume · Canais ─ *Imagem e técnico*: HDR · Filtros · Luz ambiente · Informações técnicas na tela · Detalhes técnicos | Agrupado por assunto, com cabeçalhos curtos |
| Áudio e legendas (player) | — | sem mudança | já é uma lista por idioma, simples |
| Aparência / Geral | — | sem mudança de ordem | no celular já mostram só Tema, cartões e idioma (1D) |

## B. Ícones

Estilo único: Material Symbols Rounded (o Plezy já usava `AppIcon` com Symbols Rounded em todo o app). Regra:
**preenchido = ativo (ligado/selecionado), contorno = desligado**; 24 dp nas listas, 28 dp no player do celular
com 48 dp de toque.

| Onde | Antes | Depois |
|---|---|---|
| Chaves das Configurações | sempre preenchido | preenchido ligado, contorno desligado |
| Player › ajustes do vídeo | `tune` (controles deslizantes) | `settings` (engrenagem) |
| Player › áudio (vídeo sem legenda) | `audiotrack` (nota musical) | `voice_selection` |
| Player › capítulos | `bookmarks` | `toc` |
| Player › lista | `queue` | `playlist_play` |
| Player › botões do celular | 24 dp, 40 dp de toque, sempre preenchidos | 28 dp, 48 dp de toque, contorno quando a chave está desligada (ex.: travar rotação) |
| Ajustes do vídeo › qualidade | `art_track` | `high_quality` |
| Ajustes do vídeo › atraso do áudio | `sync` | `av_timer` |
| Ajustes do vídeo › nivelar volume | `graphic_eq` | `equalizer` |
| Detalhes técnicos do arquivo (menu e player) | `info` (o mesmo do Ver detalhes) | `description` |
| Configurações › Geral | `settings` (a mesma engrenagem das Configurações) | `language` |
| Configurações › Áudio, legenda e conta | `manage_accounts` | `voice_selection` |
| Dicas | — | `help` em contorno (48 dp), `lightbulb` no Sobre |

**Não deu / não existe**: *transmitir* (Chromecast) não existe no Plezy, não há botão para trocar; a dica "Ver na TV"
explica o caminho. Os botões grandes do centro (play/pausa, anterior/próximo) já eram 48–72 dp e ficaram. Na TV e no
computador os botões do player ficam com o tamanho do upstream (o foco do controle remoto depende dele).

## C. Textos (antes → depois)

| Chave | Antes | Depois |
|---|---|---|
| `settings.videoPlayback` | Reprodução de vídeo | Ao assistir |
| `settings.videoPlaybackDescription` | Escolha como os vídeos são reproduzidos | Pular abertura, legendas, gestos e próximo episódio |
| `settings.generalDescription` | Idioma, abertura do app e janela | Idioma do app e modo TV |
| `settings.aboutDescription` | Informações do app e licenças | Versão, dicas do CGFLIX e licenças |
| `settings.autoPlayAndSkip` | Reprodução automática e pular trechos | Pular abertura e próximo episódio |
| `settings.autoPlayNextEpisode` | Assistir o próximo episódio automaticamente | Próximo episódio sozinho |
| `settings.hardwareDecoding` | Decodificação por hardware | Aceleração de vídeo |
| `settings.autoPip` | Janelinha automática (picture-in-picture) | Abrir a janelinha ao sair |
| `settings.servicesDescription` | Conecte Trakt, MyAnimeList, Seerr e outros | Conecte o Trakt para registrar o que você assiste |
| `settings.downloadOnWifiOnlyDescription` | Não baixar usando dados móveis | Não gasta seus dados móveis (4G/5G) |
| `settings.scopeShaderPreset` | Filtro de imagem (shader) | Filtro de imagem |
| `connections.sectionTitle` | Conexões | Contas e servidores |
| `accountPreferences.sectionTitle` | Preferências da conta | Áudio, legenda e conta |
| `accountPreferences.hubSubtitleSingle` | Opções de áudio, legendas e biblioteca salvas em ${account} | Idioma do áudio e da legenda, salvo em ${account} |
| `accountPreferences.hubSubtitleMultiple` | Opções de áudio, legendas e biblioteca salvas em ${count} contas | Idioma do áudio e da legenda, salvo em ${count} contas |
| `common.play` | Reproduzir | Assistir |
| `videoControls.playButton` | Reproduzir | Assistir |
| `videoControls.settingsButton` | Configurações de reprodução | Ajustes do vídeo |
| `videoControls.pipButton` | Janelinha (picture-in-picture) | Janelinha |
| `videoControls.queue` | Fila | A seguir |
| `videoControls.noQueueItems` | Nenhum item na fila | Nada a seguir |
| `videoControls.autoPlayNext` | Próximo automaticamente | Próximo episódio sozinho |
| `videoControls.playbackResumed` | Reproduzindo | Tocando |
| `videoControls.showPlaybackControls` | Mostrar controles de reprodução | Mostrar os botões |
| `videoControls.hidePlaybackControls` | Ocultar controles de reprodução | Esconder os botões |
| `videoSettings.performanceOverlay` | Painel de desempenho | Informações técnicas na tela |
| `shaders.title` | Filtros de imagem (shaders) | Filtros de imagem |
| `mediaMenu.playVersion` | Assistir versão... | Assistir outra versão |
| `mediaMenu.fileInfo` | Informações do arquivo | Detalhes técnicos do arquivo |
| `mediaMenu.playFromBeginning` | Assistir do início | Assistir do começo |
| `settings.skipIntroModeOffDescription` | Mostrar a abertura normalmente, sem botão para pular | a abertura passa normalmente |
| `settings.skipIntroModeButtonDescription` | Mostrar o botão "Pular abertura" quando a abertura começar | o botão aparece quando a abertura começa |
| `settings.skipIntroModeAutoDescription` | Pular a abertura sozinho depois do tempo de espera abaixo | pula sozinho depois da espera abaixo |
| `settings.skipCreditsModeButtonDescription` | Mostrar o botão "Pular créditos" quando os créditos começarem | o botão aparece quando os créditos começam |
| `settings.skipCreditsModeAutoDescription` | Pular os créditos sozinho e começar o próximo episódio | pula os créditos e começa o próximo episódio |
| `settings.skipCreditsModeOffDescription` | Mostrar os créditos normalmente, sem botão para pular | os créditos passam normalmente |
| tema (tela) | Isis (escuro, roxo) / Heitor (claro, verde) / Automático (segue o aparelho) | Isis / Heitor / Automático (o leitor de tela continua dizendo "escuro, roxo"…) |
| Menu do usuário | Sobre o CGFLIX | Sobre e dicas |
| Avançado › Opções do mpv | Ajustes técnicos do player… | Ajustes técnicos do reprodutor de vídeo… |

Jargão que ficou, de propósito, só em telas técnicas (Avançado, Reprodutor, Vídeo e tela, Detalhes técnicos do
arquivo, Informações técnicas na tela): mpv, ExoPlayer, Dolby Vision, HDR/SDR, codec, transcodificação, SDH.

## D. Dicas

Todas em `lib/cgflix/cgflix_dicas.dart` (editar só ali).

| Dica | Onde aparece |
|---|---|
| Pular abertura e créditos | "?" em Ao assistir › Pular abertura |
| Áudio e legenda preferidos | "?" em Configurações › Áudio, legenda e conta |
| Qualidade e dados móveis | "?" em Ao assistir › Qualidade padrão |
| Baixar para ver sem internet | "?" em Configurações › Baixados › Baixar só no Wi-Fi |
| Entrar na TV com um código (Quick Connect) | Sobre › Dicas |
| Ver na TV | Sobre › Dicas |
| Meus pedidos | Sobre › Dicas |
| Minha conta | Sobre › Dicas |
| Gestos na tela do vídeo | "?" em Ao assistir › Gestos; dica única no player |
| Travar a tela | Sobre › Dicas |
| Janelinha | "?" em Ao assistir › Abrir a janelinha ao sair |

Dica do player: aparece uma vez (primeiro vídeo no celular), acima do centro, some em 8 s ou com um toque, e não volta
(`cgflix_dica_player_vista` no aparelho). Sobre › Dicas do CGFLIX › "Ver de novo a dica dos gestos" faz ela voltar no
próximo vídeo. Com "remover animações", aparece e some sem esmaecer.

## E. Padrões (antes → depois → por quê)

| Padrão | Antes | Depois | Por quê |
|---|---|---|---|
| Baixar só no Wi-Fi | desligado | **ligado** | quem não sabe que um filme passa de 2 GB não perde o plano de dados; quem quiser desliga em Configurações › Baixados |

Revistos e **mantidos**: qualidade = original (o servidor não converte vídeo; qualquer outra quebraria o play);
Pular abertura e créditos = mostrar botão (automático pula sem a pessoa entender; o botão é o que o Netflix faz);
próximo episódio sozinho = ligado; apagar baixados assistidos = desligado (apagar sozinho assusta); janelinha ao sair =
ligada; áudio e legenda seguem o servidor (aprovado na 1A). **Legenda automática quando o áudio não é português**
é preferência da conta no Jellyfin (Modo de legenda "Inteligente"/Smart + idioma `por`): é no servidor, não no app;
o painel do Jellyfin deve ficar assim para cada usuário (as Preferências da conta no app mostram e mudam isso).

## F. Testes e capturas

- `test/cgflix/cgflix_menus_test.dart`: ordem do menu do título (grupos, nada some nem repete, extras, música),
  ícones do player, 48 dp no celular, ordem de Ao assistir e Avançado com a parte técnica.
- `test/cgflix/cgflix_dicas_test.dart`: textos (2–4 frases, sem jargão), dica do player aparece uma vez, some com
  toque, some sozinha, não volta, "remover animações", reabre pelo Sobre, "?" de 48 dp abre e fecha a folha, tema Heitor.
- `test/cgflix/cgflix_refino1_telas_test.dart`, `cgflix_navigation_test.dart`: nova ordem do menu, cabeçalhos e traços.
- Capturas: `CGFLIX_CAPTURAS=docs/prints/refino2/depois flutter test test/cgflix/capturas/capturas_test.dart`
  (telas reais com Inter e Symbols). "antes" = mesmo teste no `main` da 1.5.0.
- Emulador (job do CI, artifact `cgflix-capturas`): `20-ao-assistir`, `21-dica-pular-abertura`, `22-dicas`,
  `23-dica-gestos`, `heitor-20-ao-assistir`, `heitor-22-dicas`, além das telas de antes.

## G. Passada final — visto e **não** mudado

- Botões do topo do player na TV e no computador: continuam 40 dp (foco do controle remoto).
- Botões grandes do centro do player: já tinham 48–72 dp.
- Ícones de linhas montadas à mão em telas do Plezy (local dos downloads, verificar atualização, licenças): continuam
  preenchidos (não são chaves; mudar mexeria em muitas linhas do upstream).
- Aparência e Geral: a ordem ficou; no celular já só aparecem Tema/cartões e Idioma.
- Menu de áudio e legendas do player: só a lista de faixas, sem o que reordenar.
- "Detalhes técnicos do arquivo", "Informações técnicas na tela", HDR e filtros continuam no player (embaixo, em
  "Imagem e técnico"): tirar do player seria remover.
- Música (qualidade da música, retomar música): o CGFLIX quase não tem música, mas o Jellyfin pode ter; ficou embaixo.
- Textos de erro técnicos do Seerr e dos logs: só aparecem no registro (logs), não na tela.
- A captura feita em teste não mostra o relógio do sistema nem o vídeo (o player é de mentira); o real fica com o
  vídeo por trás.
