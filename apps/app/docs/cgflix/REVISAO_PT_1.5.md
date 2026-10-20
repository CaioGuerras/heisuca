# Revisão da tradução pt-BR — versão 1.5.0 (refino 1, item F)

**Resumo dos padrões aplicados**

1. Erros reescritos em linguagem de gente: "Falha ao…/Não foi possível…" → "Não deu para…" + o que fazer ("Confira a internet e tente de novo."); "Tentar novamente" → "Tentar de novo"; "Tem certeza de que deseja…" → "Quer mesmo…?".
2. Title Case do inglês removido (só a primeira letra maiúscula, salvo nomes próprios) e "Insira/Pressione/Selecionar/Pesquisar/Dispositivo" → "Digite/Toque/Escolher/Buscar/Aparelho".
3. Jargão trocado: URL → endereço ("Endereços do servidor"), Buffer → "Carregamento antecipado"/"Memória de reprodução", Hub → seção, Log(s) → "registros (logs)", Depuração → diagnóstico, Cache → "Memória de imagens"/"memória temporária", Scrobble → "Marcar como assistido", Downmix/passthrough → "Juntar canais em estéreo"/"Enviar áudio direto ao receptor", Shader → "Filtro de imagem", Mecanismo de reprodução → "Reprodutor de vídeo", offline → "sem internet".
4. Termos fixos unificados: Baixados/baixar, Avançar e voltar ("Avançar X s"/"Voltar X s"), Pular abertura/Pular créditos, Assistir juntos, Continuar assistindo, Ligado/Desligado, Séries (sem "de TV"), lista para assistir (antes misturava "lista de interesses").
5. Nas mensagens de login/conexão e de falha do vídeo, o `${error}` ficou (o slang exige o mesmo parâmetro do inglês), mas quem chama passa um motivo já em português, nunca a exceção crua; chaves, ordem, plurais e demais `${param}` estão iguais. Nenhum texto menciona "Plezy" nem milissegundos.

Total de chaves alteradas: **998**.

## auth (9)

| Chave | Antes | Depois |
|---|---|---|
| `auth.authenticate` | Autenticar | Confirmar acesso |
| `auth.authenticationTimeout` | A autenticação expirou. Tente novamente. | O tempo para entrar acabou. Tente de novo. |
| `auth.waitingForAuth` | Aguardando autenticação...\nEntre pelo navegador. | Esperando você entrar...\nConclua o acesso no navegador. |
| `auth.connectToMediaBrowser` | Conectar ao ${product} | Entrar no ${product} |
| `auth.quickConnectInstructions` | Abra o Quick Connect no Jellyfin e insira este código. | Abra o Quick Connect no Jellyfin (em outro aparelho já conectado) e digite este código. |
| `auth.quickConnectWaiting` | Aguardando aprovação… | Esperando a aprovação… |
| `auth.quickConnectExpired` | Quick Connect expirou. Tente novamente. | O código do Quick Connect expirou. Tente de novo. |
| `auth.localDataRecoveryRequired` | O CGFLIX não conseguiu recuperar com segurança os dados locais de acesso e de reproduções pendentes. Entre novamente. | O CGFLIX não conseguiu recuperar com segurança seus dados de acesso e o que você assistiu sem internet. Entre de novo. |
| `auth.pinCheckRejected` | A verificação do PIN do Plex foi rejeitada | O Plex recusou o código de acesso. Tente de novo. |

## common (7)

| Chave | Antes | Depois |
|---|---|---|
| `common.retry` | Tentar novamente | Tentar de novo |
| `common.resume` | Retomar | Continuar |
| `common.off` | Desativado | Desligado |
| `common.checkingNetwork` | Verificando rede... | Verificando a internet... |
| `common.startingOfflineMode` | Iniciando modo offline... | Abrindo o modo sem internet... |
| `common.pressBackAgainToExit` | Pressione voltar novamente para sair | Toque em voltar de novo para sair |
| `common.url` | URL | Endereço |

## screens (3)

| Chave | Antes | Depois |
|---|---|---|
| `screens.switchProfile` | Trocar Perfil | Trocar perfil |
| `screens.subtitleStyling` | Estilo de Legendas | Estilo das legendas |
| `screens.logs` | Logs | Registros (logs) |

## update (3)

| Chave | Antes | Depois |
|---|---|---|
| `update.viewRelease` | Ver Lançamento | Ver novidades |
| `update.latestVersion` | Você está na versão mais recente | Você já está na versão mais recente |
| `update.checkFailed` | Falha ao verificar atualizações | Não deu para procurar atualizações. Confira a internet e tente de novo. |

## settings (206)

| Chave | Antes | Depois |
|---|---|---|
| `settings.supportDeveloperDescription` | Doe via Liberapay para financiar o desenvolvimento | Doe pelo Liberapay para ajudar no desenvolvimento |
| `settings.videoPlayback` | Reprodução de Vídeo | Reprodução de vídeo |
| `settings.videoPlaybackDescription` | Configurar comportamento de reprodução | Escolha como os vídeos são reproduzidos |
| `settings.episodePosterMode` | Estilo do pôster do episódio | Imagem dos episódios |
| `settings.showHeroSectionDescription` | Exibir carrossel de conteúdo em destaque na tela inicial | Mostrar um carrossel de destaques na tela inicial |
| `settings.minutesShort` | m | min |
| `settings.durationHint` | Insira a duração (${min}-${max}) | Digite um valor de ${min} a ${max} |
| `settings.libraryDensity` | Densidade da Biblioteca | Tamanho dos itens na biblioteca |
| `settings.displayScale` | Escala de exibição | Tamanho da interface |
| `settings.tvCornerSpotlightBackdropDescription` | Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela | Mostrar a imagem de destaque no canto superior direito em vez de ocupar a tela toda |
| `settings.viewMode` | Modo de Visualização | Modo de exibição |
| `settings.showHeroSection` | Mostrar Seção de Destaque | Mostrar destaques |
| `settings.continueWatchingAction` | Ação da seção Continuar assistindo | Ao tocar em Continuar assistindo |
| `settings.continueWatchingPlay` | Reproduzir | Assistir |
| `settings.episodeAction` | Ação do episódio | Ao tocar em um episódio |
| `settings.episodePlay` | Reproduzir | Assistir |
| `settings.useGlobalHubs` | Usar layout inicial | Usar tela inicial unificada |
| `settings.useGlobalHubsDescription` | Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca. | Mostrar as seções da tela inicial juntas. Se desligado, usa as recomendações de cada biblioteca. |
| `settings.showServerNameOnHubs` | Mostrar Nome do Servidor nos Hubs | Mostrar nome do servidor nas seções |
| `settings.showServerNameOnHubsDescription` | Sempre mostrar nomes dos servidores nos títulos dos hubs. | Sempre mostrar o nome do servidor no título das seções. |
| `settings.groupLibrariesByServer` | Agrupar Bibliotecas por Servidor | Agrupar bibliotecas por servidor |
| `settings.groupLibrariesByServerDescription` | Agrupar bibliotecas da barra lateral por servidor de mídia. | Agrupar as bibliotecas do menu lateral por servidor. |
| `settings.alwaysKeepSidebarOpen` | Manter Barra Lateral Sempre Aberta | Manter menu lateral sempre aberto |
| `settings.alwaysKeepSidebarOpenDescription` | A barra lateral fica expandida e a área de conteúdo se ajusta | O menu lateral fica aberto e o conteúdo se ajusta ao lado |
| `settings.showUnwatchedCount` | Mostrar Contagem de Não Assistidos | Mostrar quantos faltam assistir |
| `settings.showUnwatchedCountDescription` | Exibir contagem de episódios não assistidos em séries e temporadas | Mostrar o número de episódios não assistidos em séries e temporadas |
| `settings.showWatchedIndicators` | Mostrar Indicadores de Assistidos | Marcar o que já foi assistido |
| `settings.showWatchedIndicatorsDescription` | Exibir uma marca de verificação em filmes, séries e episódios assistidos | Mostrar um sinal de visto em filmes, séries e episódios já assistidos |
| `settings.showEpisodeNumberOnCards` | Mostrar Número do Episódio nos Cards | Mostrar número do episódio |
| `settings.showEpisodeNumberOnCardsDescription` | Mostrar temporada e episódio nos cartões de episódio | Mostrar temporada e episódio nas capas dos episódios |
| `settings.showSeasonPostersOnTabs` | Mostrar Pôsteres de Temporada nas Abas | Mostrar pôsteres nas abas de temporada |
| `settings.tvFullCardLayout` | Cartões TV completos | Capas completas na TV |
| `settings.tvFullCardLayoutDescription` | Usar cartões de TV só com imagem e nomes dos atores sobrepostos | Na TV, mostrar capas só com a imagem e os nomes dos atores por cima |
| `settings.focusGlow` | Brilho de foco | Brilho na seleção |
| `settings.focusGlowDescription` | Mostrar um brilho suave ao redor do cartão em foco | Mostrar um brilho suave em volta da capa selecionada |
| `settings.visualEffectsAutoDescription` | Reduzir os efeitos automaticamente em dispositivos de baixo consumo | Reduzir os efeitos sozinho em aparelhos mais simples |
| `settings.hideSpoilersDescription` | Desfocar miniaturas e descrições de episódios não assistidos | Desfocar imagens e resumos dos episódios que você ainda não viu |
| `settings.playerBackend` | Mecanismo de reprodução | Reprodutor de vídeo |
| `settings.hardwareDecoding` | Decodificação por Hardware | Decodificação por hardware |
| `settings.hardwareDecodingDescription` | Usar aceleração por hardware quando disponível | Usar o chip de vídeo do aparelho quando possível (mais leve e economiza bateria) |
| `settings.playbackBuffer` | Buffer de reprodução | Carregamento antecipado |
| `settings.playbackBufferDescription` | Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer. | Carrega mais vídeo antes para evitar travadas em internet instável. Também depende do tamanho da memória de reprodução. |
| `settings.directPlayCoveredQuality` | Reproduzir Vídeos Menores na Qualidade Original | Vídeos menores na qualidade original |
| `settings.directPlayCoveredQualityDescription` | Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los | Tocar direto, sem conversão no servidor, os vídeos que já cabem no limite de qualidade |
| `settings.videoCodecsDescription` | Codecs desmarcados são transcodificados pelo servidor | Formatos desmarcados são convertidos pelo servidor |
| `settings.subtitleStyling` | Estilo de Legendas | Estilo das legendas |
| `settings.subtitleStylingDescription` | Personalizar aparência das legendas | Mudar a aparência das legendas |
| `settings.smallSkipDuration` | Duração do Avanço Curto | Avançar e voltar (toque curto) |
| `settings.largeSkipDuration` | Duração do Avanço Longo | Avançar e voltar (toque longo) |
| `settings.rewindOnResume` | Rebobinar ao retomar | Voltar um pouco ao continuar |
| `settings.defaultSleepTimer` | Temporizador de suspensão padrão | Desligar automaticamente após (padrão) |
| `settings.rememberTrackSelections` | Lembrar seleção de faixas por série/filme | Lembrar áudio e legenda de cada série/filme |
| `settings.rememberTrackSelectionsDescription` | Lembrar escolhas de áudio e legendas por título | Guardar suas escolhas de áudio e legenda para cada título |
| `settings.rememberTrackSelectionsBackendRule` | O Plex salva cada escolha no servidor por arquivo; o Jellyfin também ativa a opção Lembrar seleções da conta; o Emby não é compatível | No Plex, cada escolha fica salva no servidor por arquivo; no Jellyfin, também liga a opção "Lembrar seleções" da sua conta; no Emby não funciona |
| `settings.followServerTrackSelections` | Usar a seleção de faixas do servidor por episódio | Usar o áudio e a legenda do servidor em cada episódio |
| `settings.followServerTrackSelectionsDescription` | Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual | Ao trocar de episódio, usar o áudio e a legenda escolhidos no servidor em vez de manter a escolha atual |
| `settings.resumeMusicOnLaunchDescription` | Ao iniciar a aplicação, reabrir a última música em pausa onde parou | Ao abrir o app, retomar a última música de onde parou |
| `settings.showChapterMarkersOnTimeline` | Mostrar marcadores de capítulos na barra de reprodução | Mostrar capítulos na barra de progresso |
| `settings.showChapterMarkersOnTimelineDescription` | Segmentar a barra de reprodução nos limites dos capítulos | Dividir a barra de progresso no início de cada capítulo |
| `settings.specialsOrderingDescription` | Onde os especiais são reproduzidos na ordem de exibição de uma série | Em que ponto da série os especiais aparecem |
| `settings.specialsOrderingAirDate` | Intercalar pela data de exibição | Misturar pela data de exibição |
| `settings.specialsOrderingLast` | Após as temporadas regulares | Depois das temporadas normais |
| `settings.clickVideoTogglesPlayback` | Clicar no vídeo para alternar reprodução/pausa | Clicar no vídeo para pausar/continuar |
| `settings.clickVideoTogglesPlaybackDescription` | Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controles. | Um clique no vídeo pausa ou continua, em vez de mostrar os controles. |
| `settings.keyboardShortcuts` | Atalhos de Teclado | Atalhos de teclado |
| `settings.keyboardShortcutsDescription` | Personalizar atalhos de teclado | Mudar os atalhos de teclado |
| `settings.videoPlayerNavigationDescription` | Usar as teclas de seta para navegar pelos controles do reprodutor | Usar as setas para andar pelos controles do reprodutor |
| `settings.watchTogetherRelay` | Servidor de retransmissão do Assistir Juntos | Servidor do Assistir juntos |
| `settings.watchTogetherRelayDescription` | Definir um servidor de retransmissão personalizado. Todos devem usar o mesmo servidor. | Usar outro servidor para o Assistir juntos. Todos precisam usar o mesmo. |
| `settings.watchTogetherRelayInvalid` | Insira uma URL base de retransmissão HTTP ou HTTPS válida. | Digite um endereço válido, começando com http:// ou https://. |
| `settings.crashReporting` | Relatório de Erros | Relatório de erros |
| `settings.crashReportingDescription` | Enviar relatórios de erros para ajudar a melhorar o app | Enviar relatórios de erro para ajudar a melhorar o app |
| `settings.debugLogging` | Log de Depuração | Registros de diagnóstico |
| `settings.debugLoggingDescription` | Ativar log detalhado para solução de problemas | Guardar registros detalhados para ajudar a resolver problemas |
| `settings.viewLogs` | Ver Logs | Ver registros (logs) |
| `settings.viewLogsDescription` | Ver logs do app | Ver os registros do app |
| `settings.clearImageCache` | Limpar cache de imagens | Limpar memória de imagens |
| `settings.clearImageCacheDescription` | Limpar artes e miniaturas em cache. As imagens podem carregar mais devagar até serem baixadas novamente. | Apagar capas e miniaturas guardadas no aparelho. As imagens podem demorar um pouco mais para aparecer até serem baixadas de novo. |
| `settings.clearImageCacheSuccess` | Cache de imagens limpo com sucesso | Memória de imagens limpa |
| `settings.resetSettings` | Redefinir Configurações | Restaurar configurações |
| `settings.resetSettingsDescription` | Restaurar configurações padrão. Não pode ser desfeito. | Voltar todas as configurações ao padrão. Não dá para desfazer. |
| `settings.resetSettingsSuccess` | Configurações redefinidas com sucesso | Configurações restauradas |
| `settings.exportSettings` | Exportar Configurações | Exportar configurações |
| `settings.importSettings` | Importar Configurações | Importar configurações |
| `settings.importSettingsDescription` | Restaurar preferências a partir de um arquivo | Trazer preferências de um arquivo |
| `settings.importSettingsConfirm` | Isso substituirá suas configurações atuais. Continuar? | Isso vai substituir suas configurações atuais. Continuar? |
| `settings.importSettingsNoUser` | Entre na conta antes de importar as configurações | Entre na sua conta antes de importar as configurações |
| `settings.shortcutsReset` | Atalhos redefinidos para o padrão | Atalhos voltaram ao padrão |
| `settings.resetShortcutsConfirm` | Isto troca os seus atalhos personalizados pelos padrões. Continuar? | Isso troca seus atalhos personalizados pelos padrões. Continuar? |
| `settings.updateAvailable` | Atualização Disponível | Atualização disponível |
| `settings.checkForUpdates` | Verificar Atualizações | Procurar atualizações |
| `settings.autoCheckUpdatesOnStartup` | Verificar atualizações automaticamente ao iniciar | Procurar atualizações ao abrir o app |
| `settings.autoCheckUpdatesOnStartupDescription` | Notificar ao iniciar quando houver atualização disponível | Avisar ao abrir o app quando houver uma atualização |
| `settings.validationErrorEnterNumber` | Insira um número válido | Digite um número válido |
| `settings.shortcutAlreadyAssigned` | Atalho já atribuído a ${action} | Este atalho já é usado em ${action} |
| `settings.saveFailed` | Não foi possível salvar as alterações. Tente novamente. | Não deu para salvar as alterações. Tente de novo. |
| `settings.autoPlayAndSkip` | Reprodução automática e pulos | Reprodução automática e pular trechos |
| `settings.autoPlayNextEpisode` | Reproduzir próximo episódio automaticamente | Assistir o próximo episódio automaticamente |
| `settings.autoPlayNextEpisodeDescription` | Iniciar o próximo episódio automaticamente quando um terminar | Começar o próximo episódio quando o atual terminar |
| `settings.shuffleStartsFromBeginning` | Reprodução Aleatória Começa do Início | Modo aleatório começa do início |
| `settings.shuffleStartsFromBeginningDescription` | Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo | No modo aleatório, começar cada episódio do início em vez de continuar de onde parou |
| `settings.playNextCountdown` | Contagem regressiva do próximo episódio | Contagem para o próximo episódio |
| `settings.playNextCountdownImmediate` | Reproduzir imediatamente | Começar na hora |
| `settings.skipIntroMode` | Pular Abertura | Pular abertura |
| `settings.skipIntroModeOffDescription` | Reproduzir as aberturas normalmente sem botão de pulo | Mostrar a abertura normalmente, sem botão para pular |
| `settings.skipIntroModeButtonDescription` | Mostrar um botão de pulo quando uma abertura começar | Mostrar o botão "Pular abertura" quando a abertura começar |
| `settings.skipIntroModeAutoDescription` | Pular as aberturas automaticamente após o atraso abaixo | Pular a abertura sozinho depois do tempo de espera abaixo |
| `settings.skipCreditsMode` | Pular Créditos | Pular créditos |
| `settings.skipCreditsModeOffDescription` | Reproduzir os créditos normalmente sem botão de pulo | Mostrar os créditos normalmente, sem botão para pular |
| `settings.skipCreditsModeButtonDescription` | Mostrar um botão de pulo quando os créditos começarem | Mostrar o botão "Pular créditos" quando os créditos começarem |
| `settings.skipCreditsModeAutoDescription` | Pular os créditos automaticamente e reproduzir o próximo episódio | Pular os créditos sozinho e começar o próximo episódio |
| `settings.skipMarkerModeOff` | Desativado | Desligado |
| `settings.forceSkipMarkerFallback` | Forçar marcadores alternativos | Sempre detectar abertura pelos capítulos |
| `settings.forceSkipMarkerFallbackDescription` | Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores | Procurar a abertura e os créditos pelo nome dos capítulos, mesmo quando o Plex já tiver essa informação |
| `settings.autoSkipDelay` | Atraso para pular automaticamente | Espera antes de pular |
| `settings.autoSkipDelayDescription` | Aguardar ${seconds} segundos antes de pular automaticamente | Esperar ${seconds} segundos antes de pular sozinho |
| `settings.introPattern` | Padrão do marcador de introdução | Nome do capítulo de abertura |
| `settings.introPatternDescription` | Expressão regular que identifica marcadores de introdução nos títulos dos capítulos | Expressão regular que reconhece a abertura pelo nome do capítulo |
| `settings.creditsPattern` | Padrão do marcador de créditos | Nome do capítulo de créditos |
| `settings.creditsPatternDescription` | Expressão regular que identifica marcadores de créditos nos títulos dos capítulos | Expressão regular que reconhece os créditos pelo nome do capítulo |
| `settings.downloads` | Downloads | Baixados |
| `settings.downloadLocationDescription` | Escolha onde armazenar conteúdo baixado | Escolha onde guardar o que você baixar |
| `settings.downloadLocationDefault` | Padrão (Armazenamento do App) | Padrão (memória do app) |
| `settings.downloadLocationCustom` | Local Personalizado | Outra pasta |
| `settings.selectFolder` | Selecionar Pasta | Escolher pasta |
| `settings.resetToDefault` | Redefinir para Padrão | Voltar ao padrão |
| `settings.downloadLocationChanged` | Local de download alterado | Pasta dos baixados alterada |
| `settings.downloadLocationReset` | Local de download redefinido para padrão | Pasta dos baixados voltou ao padrão |
| `settings.downloadLocationInvalid` | A pasta selecionada não permite gravação | Não dá para salvar arquivos nessa pasta. Escolha outra. |
| `settings.downloadLocationPickerUnavailable` | A seleção de pasta não está disponível neste dispositivo | Não dá para escolher pasta neste aparelho |
| `settings.downloadOnWifiOnly` | Baixar apenas por Wi-Fi | Baixar só no Wi-Fi |
| `settings.downloadOnWifiOnlyDescription` | Impedir downloads ao usar dados móveis | Não baixar usando dados móveis |
| `settings.autoRemoveWatchedDownloads` | Remover automaticamente os downloads assistidos | Apagar baixados já assistidos |
| `settings.autoRemoveWatchedDownloadsDescription` | Excluir automaticamente os downloads assistidos | Apagar sozinho os vídeos baixados depois que você assistir |
| `settings.cellularDownloadBlocked` | Os downloads estão bloqueados nos dados móveis. Use Wi-Fi ou altere a configuração. | Baixar está bloqueado nos dados móveis. Conecte no Wi-Fi ou mude essa opção nas Configurações. |
| `settings.maxVolume` | Volume Máximo | Volume máximo |
| `settings.maxVolumeDescription` | Permitir aumento de volume acima de 100% para mídias silenciosas | Deixar o volume passar de 100% para vídeos com som baixo |
| `settings.servicesDescription` | Conecte Trakt, MyAnimeList, Seerr e mais | Conecte Trakt, MyAnimeList, Seerr e outros |
| `settings.manageLibrariesDescription` | Reordene e oculte bibliotecas | Mudar a ordem e ocultar bibliotecas |
| `settings.companionRemoteServerDescription` | Permitir que dispositivos móveis na sua rede controlem este app | Deixar celulares na sua rede Wi-Fi controlarem este app |
| `settings.companionRemoteServerStartFailed` | Não foi possível iniciar o servidor de controle remoto | Não deu para ligar o controle remoto. Tente de novo. |
| `settings.companionRemoteServerStopFailed` | Não foi possível parar o servidor de controle remoto | Não deu para desligar o controle remoto. Tente de novo. |
| `settings.autoPip` | Picture-in-picture automático | Janelinha automática (picture-in-picture) |
| `settings.autoPipDescription` | Entrar automaticamente no modo picture-in-picture ao sair do app durante a reprodução | Continuar o vídeo numa janelinha ao sair do app durante a reprodução |
| `settings.matchContentFrameRateDescription` | Ajustar a taxa de atualização da tela ao conteúdo de vídeo | Ajustar a frequência da tela ao vídeo (evita imagem tremida) |
| `settings.matchContentResolutionDescription` | Muda a tela para a resolução nativa do vídeo para que a TV cuide do upscaling. Menus e legendas também são ampliados durante a reprodução | Muda a tela para a resolução original do vídeo, para a TV fazer a ampliação. Menus e legendas também ficam maiores durante a reprodução |
| `settings.matchRefreshRate` | Ajustar à taxa de atualização | Ajustar à frequência da tela |
| `settings.matchRefreshRateDescription` | Ajustar a taxa de atualização da tela em tela cheia | Ajustar a frequência da tela no modo tela cheia |
| `settings.matchDynamicRangeDescription` | Ativar HDR para conteúdo HDR e depois voltar para SDR | Ligar o HDR da tela em vídeos HDR e depois voltar ao normal (SDR) |
| `settings.displaySwitchDelay` | Atraso na troca do modo de exibição | Espera ao trocar o modo da tela |
| `settings.tunneledPlaybackDescription` | Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou o movimento travar. | Usar o modo túnel de vídeo. Desligue se o vídeo ficar preto em HDR ou se a imagem travar. |
| `settings.audioPassthrough` | Passagem direta de áudio | Enviar áudio direto ao receptor |
| `settings.audioPassthroughDescription` | Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som. | Mandar o áudio Dolby/DTS sem conversão para o receptor ou a TV, mantendo o som surround. Desligue se ficar sem som. |
| `settings.audioPassthroughDescriptionAppleTv` | Usar o decodificador Dolby nativo da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam sendo reproduzidos como PCM multicanal. Desative se não houver som. | Usar o decodificador Dolby da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam tocando como PCM multicanal. Desligue se ficar sem som. |
| `settings.audioPassthroughOverriddenByNormalization` | Desativada enquanto a normalização de intensidade sonora estiver ativa | Desligado enquanto o nivelamento de volume estiver ligado |
| `settings.audioChannelLimitDescription` | Mistura o áudio para caixas de som, fones ou sistemas HDMI que não tocam todos os canais | Junta os canais de áudio para caixas de som, fones ou aparelhos HDMI que não tocam todos os canais |
| `settings.audioChannelLimitSurround51Description` | Mistura 7.1 em 5.1 para TVs e receivers que só aceitam PCM 5.1. A passagem direta não muda. | Junta 7.1 em 5.1 para TVs e receptores que só aceitam PCM 5.1. O envio direto não muda. |
| `settings.audioChannelLimitStereo` | Estéreo | Som em estéreo |
| `settings.audioChannelLimitStereoDescription` | Mistura em dois canais para caixas de som estéreo ou fones. Desliga a passagem direta. | Junta os canais de áudio em estéreo, para caixas de som comuns ou fones. Desliga o envio direto. |
| `settings.downmixCenterBoost` | Reforço do canal central | Reforço das vozes (canal central) |
| `settings.audioDownmixNormalize` | Normalizar volume na conversão para estéreo | Nivelar volume no som em estéreo |
| `settings.audioDownmixNormalizeDescription` | Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas. | Baixar um pouco o volume ao juntar os canais para não estourar o som. Desligue para manter o volume original, que pode distorcer em cenas muito altas. |
| `settings.dvConversionModeDescription` | Escolha como os arquivos Dolby Vision Profile 7 são tratados. | Escolha como tratar os arquivos Dolby Vision perfil 7. |
| `settings.dvConversionNative` | Nativo / desativado | Nativo / desligado |
| `settings.dvConversionAutoDescription` | Usar a detecção de recursos do dispositivo e o comportamento alternativo padrão | Detectar o que o aparelho suporta e usar o comportamento padrão |
| `settings.dvConversionNativeDescription` | Forçar DV7 nativo e impedir uma nova tentativa de conversão de DV | Forçar DV7 nativo e não tentar converter o Dolby Vision |
| `settings.dvConversionDv81Description` | Forçar a conversão RPU integrada para Dolby Vision perfil 8.1 | Forçar a conversão RPU para Dolby Vision perfil 8.1 |
| `settings.dvConversionHevcStripDescription` | Remover as camadas RPU/EL do Dolby Vision e apresentar HEVC sem Dolby Vision | Remover as camadas RPU/EL do Dolby Vision e mostrar HEVC comum, sem Dolby Vision |
| `settings.disableDolbyVision` | Desativar Dolby Vision | Desligar Dolby Vision |
| `settings.disableDolbyVisionDescription` | Reproduzir a camada HDR10 ou HLG do arquivo em vez de Dolby Vision, quando houver | Usar a versão HDR10 ou HLG do arquivo em vez do Dolby Vision, quando houver |
| `settings.hdrSdrConversionDescription` | Escolha o que converte vídeos HDR quando a tela não consegue exibir HDR. | Escolha quem converte vídeos HDR quando a tela não mostra HDR. |
| `settings.hdrSdrConversionAutoDescription` | Dispositivo no Android 9 ou posterior, reprodutor em versões anteriores | O aparelho no Android 9 ou mais novo; o reprodutor nas versões anteriores |
| `settings.hdrSdrConversionDevice` | Dispositivo | Aparelho |
| `settings.hdrSdrConversionDeviceDescription` | O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo | O chip de vídeo do aparelho converte. Mais rápido, mas as cores variam de aparelho para aparelho |
| `settings.hdrSdrConversionPlayerDescription` | O reprodutor faz a conversão. Cores consistentes, mas o 4K pode travar em TV boxes mais simples | O reprodutor converte. Cores mais fiéis, mas vídeo 4K pode travar em TV boxes mais simples |
| `settings.deinterlaceDescription` | Remover artefatos de pente de vídeo entrelaçado (apenas no reprodutor mpv) | Tirar as listras (efeito pente) de vídeos antigos entrelaçados (só no reprodutor mpv) |
| `settings.requireProfileSelectionOnOpen` | Pedir perfil ao abrir o app | Perguntar o perfil ao abrir o app |
| `settings.requireProfileSelectionOnOpenDescription` | Mostrar a seleção de perfil sempre que o app for aberto | Mostrar a escolha de perfil sempre que abrir o app |
| `settings.forceTvModeDescription` | Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app. | Usar o visual de TV em aparelhos que não são reconhecidos como TV. Precisa reiniciar o app. |
| `settings.startInFullscreenDescription` | Abrir o CGFLIX em modo de tela cheia ao iniciar | Abrir o CGFLIX em tela cheia |
| `settings.autoHidePerformanceOverlay` | Ocultar automaticamente o painel de desempenho | Esconder sozinho o painel de desempenho |
| `settings.autoHidePerformanceOverlayDescription` | Esmaecer o painel de desempenho junto com os controles de reprodução | Esconder o painel de desempenho junto com os controles do reprodutor |
| `settings.showNavBarLabels` | Mostrar Rótulos da Barra de Navegação | Mostrar nomes na barra de navegação |
| `settings.showNavBarLabelsDescription` | Exibir rótulos de texto sob os ícones da barra de navegação | Mostrar o nome embaixo de cada ícone da barra de navegação |
| `settings.startupSection` | Seção inicial | Tela ao abrir o app |
| `settings.showExploreTabDescription` | Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados | Mostrar a aba Explorar com conteúdo do Plex Discover e dos serviços conectados |
| `settings.liveTvDefaultFavoritesDescription` | Mostrar apenas os canais favoritos ao abrir a TV ao vivo | Mostrar só os canais favoritos ao abrir a TV ao vivo |
| `settings.generalDescription` | Idioma, inicialização e comportamento da janela | Idioma, abertura do app e janela |
| `settings.languageAndRegion` | Idioma e Região | Idioma e região |
| `settings.startup` | Inicialização | Ao abrir o app |
| `settings.libraryAndCards` | Biblioteca e Cards | Biblioteca e capas |
| `settings.liveTv` | TV ao Vivo | TV ao vivo |
| `settings.videoAndDisplay` | Vídeo e Tela | Vídeo e tela |
| `settings.seekAndTiming` | Busca e tempo | Avançar e voltar |
| `settings.gestureBrightnessSwipe` | Deslize para brilho | Deslizar para mudar o brilho |
| `settings.gestureBrightnessSwipeDescription` | Deslize para cima ou para baixo na borda esquerda para ajustar o brilho | Deslize para cima ou para baixo no lado esquerdo para mudar o brilho |
| `settings.gestureVolumeSwipe` | Deslize para volume | Deslizar para mudar o volume |
| `settings.gestureVolumeSwipeDescription` | Deslize para cima ou para baixo na borda direita para ajustar o volume | Deslize para cima ou para baixo no lado direito para mudar o volume |
| `settings.gesturePinchToZoom` | Pinça para zoom | Pinçar para dar zoom |
| `settings.gesturePinchToZoomDescription` | Pince o vídeo para ampliar ou reduzir | Use dois dedos no vídeo para ampliar ou reduzir |
| `settings.rememberBrightnessLevel` | Lembrar Nível de Brilho | Lembrar o brilho |
| `settings.rememberBrightnessLevelDescription` | Iniciar a reprodução com o brilho definido pelo último deslize | Começar o vídeo com o brilho que você ajustou da última vez |
| `settings.rememberPlayerChanges` | Lembrar alterações do reprodutor | Lembrar ajustes do reprodutor |
| `settings.rememberPlayerChangesDescription` | Onde uma alteração feita durante a reprodução é salva e reaplicada | Onde guardar e repetir um ajuste feito durante o vídeo |
| `settings.scopeShaderPreset` | Predefinição de shader | Filtro de imagem (shader) |
| `settings.playerScopeGlobal` | Em todos os lugares | Em todos os vídeos |

## search (3)

| Chave | Antes | Depois |
|---|---|---|
| `search.tryDifferentTerm` | Tente um termo de busca diferente | Tente buscar com outras palavras |
| `search.searchYourMedia` | Buscar suas mídias | Buscar no seu servidor |
| `search.enterTitleActorOrKeyword` | Insira um título, ator ou palavra-chave | Digite um título, ator ou palavra-chave |

## hotkeys (26)

| Chave | Antes | Depois |
|---|---|---|
| `hotkeys.setShortcutFor` | Definir Atalho para ${actionName} | Definir atalho para ${actionName} |
| `hotkeys.pressToRecord` | Selecionar para gravar um atalho | Selecione para gravar um atalho |
| `hotkeys.recordingShortcut` | Pressione o atalho agora | Aperte o atalho agora |
| `hotkeys.actions.playPause` | Reproduzir/Pausar | Reproduzir/pausar |
| `hotkeys.actions.volumeUp` | Aumentar Volume | Aumentar volume |
| `hotkeys.actions.volumeDown` | Diminuir Volume | Diminuir volume |
| `hotkeys.actions.seekForward` | Avançar (${seconds}s) | Avançar ${seconds} s |
| `hotkeys.actions.seekBackward` | Retroceder (${seconds}s) | Voltar ${seconds} s |
| `hotkeys.actions.fullscreenToggle` | Alternar Tela Cheia | Tela cheia (ligar/desligar) |
| `hotkeys.actions.muteToggle` | Alternar Silêncio | Silenciar (ligar/desligar) |
| `hotkeys.actions.subtitleToggle` | Alternar Legendas | Legendas (ligar/desligar) |
| `hotkeys.actions.audioTrackNext` | Próxima Faixa de Áudio | Próximo áudio |
| `hotkeys.actions.subtitleTrackNext` | Próxima Faixa de Legenda | Próxima legenda |
| `hotkeys.actions.chapterNext` | Próximo Capítulo | Próximo capítulo |
| `hotkeys.actions.chapterPrevious` | Capítulo Anterior | Capítulo anterior |
| `hotkeys.actions.episodeNext` | Próximo Episódio | Próximo episódio |
| `hotkeys.actions.episodePrevious` | Episódio Anterior | Episódio anterior |
| `hotkeys.actions.speedIncrease` | Aumentar Velocidade | Aumentar velocidade |
| `hotkeys.actions.speedDecrease` | Diminuir Velocidade | Diminuir velocidade |
| `hotkeys.actions.speedReset` | Redefinir Velocidade | Velocidade normal |
| `hotkeys.actions.zoomReset` | Redefinir zoom | Zoom normal |
| `hotkeys.actions.subSeekNext` | Ir para Próxima Legenda | Ir para a próxima fala da legenda |
| `hotkeys.actions.subSeekPrev` | Ir para Legenda Anterior | Ir para a fala anterior da legenda |
| `hotkeys.actions.shaderToggle` | Alternar Shaders | Filtros de imagem (ligar/desligar) |
| `hotkeys.actions.skipMarker` | Pular introdução/créditos | Pular abertura/créditos |
| `hotkeys.actions.screenshot` | Capturar tela | Tirar foto da tela |

## fileInfo (11)

| Chave | Antes | Depois |
|---|---|---|
| `fileInfo.noStreams` | O servidor não relatou fluxos para este arquivo. | O servidor não informou as faixas deste arquivo. |
| `fileInfo.frameRate` | Taxa de Quadros | Taxa de quadros |
| `fileInfo.sidecarFile` | Arquivo sidecar | Arquivo separado |
| `fileInfo.colorSpace` | Espaço de Cor | Espaço de cor |
| `fileInfo.colorRange` | Faixa de Cor | Faixa de cor |
| `fileInfo.colorPrimaries` | Primárias de Cor | Primárias de cor |
| `fileInfo.chromaSubsampling` | Subamostragem de Croma | Subamostragem de croma |
| `fileInfo.subtitleFormat` | Formato sidecar | Formato do arquivo separado |
| `fileInfo.sidecarPath` | Caminho do sidecar | Caminho do arquivo separado |
| `fileInfo.flagHearingImpaired` | Deficiência auditiva | Para surdos (SDH) |
| `fileInfo.subtitlesOff` | Desativadas | Desligadas |

## mediaMenu (12)

| Chave | Antes | Depois |
|---|---|---|
| `mediaMenu.markAsWatched` | Marcar como Assistido | Marcar como assistido |
| `mediaMenu.markAsUnwatched` | Marcar como Não Assistido | Marcar como não assistido |
| `mediaMenu.removeFromContinueWatching` | Remover de Continuar Assistindo | Tirar de Continuar assistindo |
| `mediaMenu.shufflePlay` | Reprodução Aleatória | Assistir em ordem aleatória |
| `mediaMenu.shuffleNotAvailableOffline` | Reprodução aleatória indisponível offline | A ordem aleatória não funciona sem internet |
| `mediaMenu.confirmDeleteTarget` | Excluir permanentemente ${title} do seu servidor? | Apagar ${title} do seu servidor para sempre? |
| `mediaMenu.deleteScopeUnverifiedProbeFailed` | O CGFLIX não conseguiu verificar quais arquivos serão removidos, então pode excluir mais do que o item acima. Cancele e tente novamente, ou exclua mesmo assim. | O CGFLIX não conseguiu conferir quais arquivos serão apagados, então pode apagar mais do que o item acima. Cancele e tente de novo, ou exclua mesmo assim. |
| `mediaMenu.deleteScopeUnverifiedNoFileInfo` | Seu servidor não forneceu detalhes do arquivo para este item, então o CGFLIX não pode verificar quais arquivos serão removidos. Pode excluir mais do que o item acima. | O servidor não informou os arquivos deste item, então o CGFLIX não consegue conferir o que será apagado. Pode apagar mais do que o item acima. |
| `mediaMenu.mediaDeletedSuccessfully` | Item de mídia excluído com sucesso | Item excluído |
| `mediaMenu.mediaFailedToDelete` | Falha ao excluir item de mídia | Não deu para excluir o item. Tente de novo. |
| `mediaMenu.playFromBeginning` | Reproduzir do início | Assistir do início |
| `mediaMenu.playVersion` | Reproduzir versão... | Assistir versão... |

## rateSheet (2)

| Chave | Antes | Depois |
|---|---|---|
| `rateSheet.notAvailable` | Nenhuma correspondência encontrada | Não encontrado neste serviço |
| `rateSheet.noConnectedServices` | Conecte um serviço nas Configurações para avaliar por lá. | Conecte um serviço nas Configurações para avaliar por ele. |

## accessibility (3)

| Chave | Antes | Depois |
|---|---|---|
| `accessibility.mediaCardShow` | ${title}, série de TV | ${title}, série |
| `accessibility.tapToPlay` | Toque para reproduzir | Toque para assistir |
| `accessibility.alphabetScrollHint` | Deslize para cima ou para baixo para avançar por letra | Deslize para cima ou para baixo para pular de letra em letra |

## tooltips (2)

| Chave | Antes | Depois |
|---|---|---|
| `tooltips.shufflePlay` | Reprodução aleatória | Assistir em ordem aleatória |
| `tooltips.playTrailer` | Reproduzir trailer | Ver trailer |

## videoControls (36)

| Chave | Antes | Depois |
|---|---|---|
| `videoControls.letterbox` | Letterbox | Ajustar à tela |
| `videoControls.fillScreen` | Preencher tela | Preencher a tela |
| `videoControls.timerActive` | Temporizador ativo | Desligamento automático ligado |
| `videoControls.playbackWillPauseIn` | A reprodução pausará em ${duration} | O vídeo vai pausar em ${duration} |
| `videoControls.sleepTimerDurationHeader` | Temporizador | Pausar depois de |
| `videoControls.playbackWillPauseAtEnd` | A reprodução pausará no final deste vídeo | O vídeo vai pausar no final |
| `videoControls.stillWatching` | Ainda assistindo? | Você ainda está assistindo? |
| `videoControls.pausingIn` | Pausando em ${seconds}s | Pausando em ${seconds} s |
| `videoControls.autoPlayNext` | Reproduzir Próximo Automaticamente | Próximo automaticamente |
| `videoControls.playNext` | Reproduzir Próximo | Assistir o próximo |
| `videoControls.seekBackwardButton` | Retroceder ${seconds} segundos | Voltar ${seconds} segundos |
| `videoControls.unmuteButton` | Ativar som | Ligar o som |
| `videoControls.transcodeUnavailableFallback` | Transcodificação indisponível — reproduzindo qualidade original | Não dá para converter este vídeo no servidor — tocando na qualidade original |
| `videoControls.subtitleUnavailableFallback` | Não foi possível carregar as legendas selecionadas — a reprodução continuará sem legendas | Não deu para carregar a legenda escolhida — o vídeo vai continuar sem legenda |
| `videoControls.pipButton` | Modo Picture-in-Picture | Janelinha (picture-in-picture) |
| `videoControls.alwaysOnTopButton` | Sempre no topo | Sempre visível por cima |
| `videoControls.longPressToUnlock` | Pressione e segure para destravar | Toque e segure para destravar |
| `videoControls.timelineSlider` | Linha do tempo do vídeo | Barra de progresso do vídeo |
| `videoControls.volumeSlider` | Nível de volume | Volume |
| `videoControls.pipActive` | Reproduzindo em Picture-in-Picture | Tocando na janelinha |
| `videoControls.pipFailed` | Falha ao iniciar picture-in-picture | Não deu para abrir a janelinha |
| `videoControls.screenshotSaved` | Captura de tela salva | Foto da tela salva |
| `videoControls.pipErrors.androidVersion` | Requer Android 8.0 ou superior | Precisa do Android 8.0 ou mais novo |
| `videoControls.pipErrors.iosVersion` | Requer iOS 15.0 ou superior | Precisa do iOS 15.0 ou mais novo |
| `videoControls.pipErrors.permissionDisabled` | Picture-in-picture está desativado. Ative nas configurações do sistema. | A janelinha (picture-in-picture) está desligada. Ligue nas configurações do aparelho. |
| `videoControls.pipErrors.notSupported` | O dispositivo não suporta modo picture-in-picture | Este aparelho não tem o modo janelinha (picture-in-picture) |
| `videoControls.pipErrors.voSwitchFailed` | Falha ao trocar saída de vídeo para picture-in-picture | Não deu para passar o vídeo para a janelinha |
| `videoControls.pipErrors.failed` | Falha ao iniciar picture-in-picture | Não deu para abrir a janelinha |
| `videoControls.pipErrors.prepareFailed` | Não foi possível preparar o picture-in-picture | Não deu para preparar a janelinha |
| `videoControls.noAudioDevicesAvailable` | Nenhum dispositivo de áudio disponível | Nenhuma saída de áudio disponível |
| `videoControls.searchSubtitles` | Pesquisar legendas | Buscar legendas |
| `videoControls.subtitleDownloadedNotApplied` | A legenda foi baixada, mas não foi possível selecioná-la | A legenda foi baixada, mas não deu para ativá-la |
| `videoControls.subtitleDownloadFailed` | Falha ao baixar legenda | Não deu para baixar a legenda. Tente de novo. |
| `videoControls.searchLanguages` | Pesquisar idiomas... | Buscar idiomas... |
| `videoControls.forcedTrack` | ${label} (Forçada) | ${label} (forçada) |
| `videoControls.osdSubtitlesOff` | Legendas: desativadas | Legendas: desligadas |

## messages (53)

| Chave | Antes | Depois |
|---|---|---|
| `messages.markedAsWatchedOffline` | Marcado como assistido (será sincronizado quando online) | Marcado como assistido (será atualizado quando voltar a internet) |
| `messages.markedAsUnwatchedOffline` | Marcado como não assistido (será sincronizado quando online) | Marcado como não assistido (será atualizado quando voltar a internet) |
| `messages.autoRemovedWatchedDownload` | Removido automaticamente: ${title} | Apagado automaticamente: ${title} |
| `messages.autoRemovedWatchedDownloads.one` | Removido automaticamente ${n} download assistido | ${n} baixado já assistido foi apagado automaticamente |
| `messages.autoRemovedWatchedDownloads.other` | Removidos automaticamente ${n} downloads assistidos | ${n} baixados já assistidos foram apagados automaticamente |
| `messages.removedFromContinueWatching` | Removido de Continuar assistindo | Tirado de Continuar assistindo |
| `messages.searchPartialResults` | Alguns servidores de mídia não puderam ser pesquisados. Exibindo os resultados disponíveis. | Não deu para buscar em todos os servidores. Mostrando o que foi encontrado. |
| `messages.streamInterrupted` | A transmissão foi interrompida. Pressione reproduzir ou avance para tentar novamente. | O vídeo foi interrompido. Toque em reproduzir ou avance para tentar de novo. |
| `messages.liveStreamInterrupted` | A transmissão ao vivo foi interrompida. Pressione reproduzir para tentar novamente. | A transmissão ao vivo foi interrompida. Toque em reproduzir para tentar de novo. |
| `messages.fileInfoNotAvailable` | Informações do arquivo não disponíveis | Informações do arquivo indisponíveis |
| `messages.playbackAuthenticationRequired` | Entre novamente no servidor de mídia para reproduzir este item. | Entre de novo no servidor para assistir este título. |
| `messages.playbackServerUnavailable` | O servidor de mídia está indisponível. Tente novamente mais tarde. | O servidor está fora do ar. Tente de novo daqui a pouco. |
| `messages.playbackDataInvalid` | O servidor retornou informações de reprodução inválidas. | O servidor mandou informações erradas para tocar este vídeo. Tente de novo. |
| `messages.playbackCancelled` | A reprodução foi cancelada. | O vídeo foi cancelado. |
| `messages.playbackFailed` | Não foi possível iniciar a reprodução. | Não deu para começar o vídeo. Confira a internet e tente de novo. |
| `messages.playbackFailedDetail` | Não foi possível iniciar a reprodução: ${error} | Não deu para começar o vídeo (${error}). Confira a internet e tente de novo. |
| `messages.audioOutputFailed` | A saída de áudio parou de responder. Verifique a conexão de áudio da TV ou do receptor; se outros aplicativos também estiverem sem som, reinicie o dispositivo. | O som parou de responder. Confira a conexão de áudio da TV ou do receptor; se outros apps também estiverem sem som, reinicie o aparelho. |
| `messages.errorLoadingFileInfo` | Erro ao carregar as informações do arquivo: ${error} | Não deu para carregar as informações do arquivo: ${error} |
| `messages.errorLoadingSeries` | Erro ao carregar série | Não deu para carregar a série. Tente de novo. |
| `messages.musicNotSupported` | A reprodução de música ainda não é compatível | Ainda não dá para tocar música |
| `messages.contactAdminForProfiles` | Entre em contato com o administrador do servidor para adicionar perfis | Peça ao responsável pelo servidor para criar perfis |
| `messages.unableToDetermineLibrarySection` | Não foi possível determinar a seção da biblioteca deste item | Não deu para saber de qual biblioteca é este item |
| `messages.logsCleared` | Logs limpos | Registros apagados |
| `messages.logsCopied` | Logs copiados para a área de transferência | Registros copiados |
| `messages.noLogsAvailable` | Nenhum log disponível | Nenhum registro disponível |
| `messages.libraryScanning` | Escaneando "${title}"... | Procurando novidades em "${title}"... |
| `messages.libraryScanStarted` | Escaneamento da biblioteca iniciado para "${title}" | Começou a busca por novidades em "${title}" |
| `messages.libraryScanFailed` | Falha ao escanear biblioteca: ${error} | Não deu para atualizar a biblioteca: ${error} |
| `messages.metadataRefreshing` | Atualizando metadados de "${title}"... | Atualizando as informações de "${title}"... |
| `messages.metadataRefreshStarted` | Atualização de metadados iniciada para "${title}" | Começou a atualização das informações de "${title}" |
| `messages.metadataRefreshFailed` | Falha ao atualizar metadados: ${error} | Não deu para atualizar as informações: ${error} |
| `messages.logoutConfirm` | Tem certeza de que deseja sair? | Quer mesmo sair? |
| `messages.seasonsLoadFailed` | Não foi possível carregar as temporadas | Não deu para carregar as temporadas. Tente de novo. |
| `messages.episodesLoadFailed` | Não foi possível carregar os episódios | Não deu para carregar os episódios. Tente de novo. |
| `messages.sleepTimerSet` | Temporizador de suspensão definido como ${label} | O vídeo vai pausar em ${label} |
| `messages.failedToCreatePlayQueueNoItems` | Falha ao criar a fila de reprodução — nenhum item | Não deu para montar a fila — não há nada para tocar |
| `messages.failedPlayback` | Falha ao ${action}: ${error} | Não deu para ${action}: ${error} |
| `messages.switchingToCompatiblePlayer` | Alternando para um reprodutor compatível... | Trocando para outro reprodutor que funciona com este vídeo... |
| `messages.mediaUnreadableBody` | O servidor encontrou este item, mas não conseguiu ler o arquivo (HTTP 404). O arquivo provavelmente foi movido, excluído ou o armazenamento está offline. Peça ao responsável pelo servidor para verificar o arquivo e reexaminar a biblioteca. | O servidor achou este título, mas não conseguiu abrir o arquivo (erro 404). Ele pode ter sido movido ou apagado, ou o disco do servidor está desligado. Avise o responsável pelo servidor. |
| `messages.serverBusyTitle` | Transmissão indisponível | Vídeo indisponível agora |
| `messages.serverBusyBody` | O servidor continuou se recusando a transmitir este arquivo (HTTP 503). Ele pode estar reiniciando ou ocupado, ou o armazenamento do arquivo pode estar offline. Tente novamente em instantes — se isso continuar acontecendo, peça ao proprietário do servidor para verificar o servidor e o armazenamento do arquivo. | O servidor não conseguiu enviar este vídeo (erro 503). Ele pode estar reiniciando, ocupado, ou com o disco desligado. Tente de novo daqui a pouco; se continuar, avise o responsável pelo servidor. |
| `messages.logsUploaded` | Logs enviados | Registros enviados |
| `messages.logsUploadFailed` | Falha ao enviar logs | Não deu para enviar os registros. Confira a internet e tente de novo. |
| `messages.logId` | ID do log | Código do registro |
| `messages.burnedSubtitlesUseMenu` | As legendas estão incorporadas a esta transmissão. Altere-as no menu de legendas. | A legenda está gravada na imagem deste vídeo. Para trocar, use o menu de legendas. |
| `messages.noVideoUrl` | Nenhuma URL de vídeo disponível | Não foi encontrado o endereço do vídeo |
| `messages.playbackNoMediaSources` | O servidor não retornou nenhuma fonte de mídia reproduzível | O servidor não mandou nenhuma versão deste vídeo que dê para tocar |
| `messages.playbackDataNotPrepared` | A reprodução foi iniciada antes que os dados estivessem prontos | O vídeo começou antes de estar pronto. Tente de novo. |
| `messages.streamSelectionUnavailable` | A seleção de fluxos não está disponível para esta fonte | Não dá para trocar áudio ou legenda neste vídeo |
| `messages.streamSelectionFailed` | Não foi possível aplicar os fluxos selecionados | Não deu para trocar o áudio ou a legenda. Tente de novo. |
| `messages.trackSelectionNotRemembered` | Esta escolha de faixa se aplica apenas à reprodução atual. | Esta escolha de áudio ou legenda vale só para este vídeo. |
| `messages.serverUnavailableForProfile` | Nenhum servidor está disponível para o perfil ativo | Nenhum servidor disponível para este perfil |
| `messages.serverLimitBody` | O servidor recusou este play. O mais comum é o limite de 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho (ou espere um minuto) e tente de novo. Se continuar, avise o Caio. | O servidor não deixou tocar este vídeo. O mais comum é o limite de 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho (ou espere um minuto) e tente de novo. Se continuar, avise o Caio. |

## subtitlingStyling (16)

| Chave | Antes | Depois |
|---|---|---|
| `subtitlingStyling.fontSize` | Tamanho da Fonte | Tamanho da letra |
| `subtitlingStyling.textColor` | Cor do Texto | Cor do texto |
| `subtitlingStyling.borderSize` | Tamanho da Borda | Tamanho da borda |
| `subtitlingStyling.borderColor` | Cor da Borda | Cor da borda |
| `subtitlingStyling.backgroundOpacity` | Opacidade do Fundo | Transparência do fundo |
| `subtitlingStyling.backgroundColor` | Cor de Fundo | Cor do fundo |
| `subtitlingStyling.assOverride` | Substituição ASS | Estilo das legendas ASS (anime) |
| `subtitlingStyling.overrideScale` | Dimensionar | Só ajustar o tamanho |
| `subtitlingStyling.overrideForce` | Forçar | Forçar o meu estilo |
| `subtitlingStyling.overrideStrip` | Remover estilo | Remover o estilo original |
| `subtitlingStyling.positionTop` | Superior | Em cima |
| `subtitlingStyling.positionBottom` | Inferior | Embaixo |
| `subtitlingStyling.useMarginsDescription` | Permitir legendas de texto no espaço fora do vídeo. Legendas estilizadas podem manter sua posição original. | Deixar a legenda aparecer fora da área do vídeo. Legendas com estilo próprio podem manter a posição original. |
| `subtitlingStyling.anchorToScreen` | Ancorar à tela | Prender na tela |
| `subtitlingStyling.anchorToScreenDescription` | Exibir as legendas de texto nas faixas pretas abaixo de vídeos em tela ampla | Mostrar a legenda nas faixas pretas abaixo de vídeos em tela larga |
| `subtitlingStyling.renderResolution` | Resolução de renderização | Resolução da legenda |

## mpvConfig (13)

| Chave | Antes | Depois |
|---|---|---|
| `mpvConfig.description` | Configurações avançadas do reprodutor de vídeo | Opções avançadas do reprodutor de vídeo (para quem entende) |
| `mpvConfig.presets` | Predefinições | Configurações salvas |
| `mpvConfig.noPresets` | Nenhuma predefinição salva | Nenhuma configuração salva |
| `mpvConfig.saveAsPreset` | Salvar como Predefinição... | Salvar configuração... |
| `mpvConfig.presetName` | Nome da Predefinição | Nome da configuração |
| `mpvConfig.presetNameHint` | Insira um nome para esta predefinição | Digite um nome para esta configuração |
| `mpvConfig.presetSaved` | Predefinição salva | Configuração salva |
| `mpvConfig.presetLoaded` | Predefinição carregada | Configuração carregada |
| `mpvConfig.presetDeleted` | Predefinição excluída | Configuração excluída |
| `mpvConfig.confirmDeletePreset` | Tem certeza de que deseja excluir esta predefinição? | Quer mesmo excluir esta configuração? |
| `mpvConfig.configPlaceholder` | gpu-api=vulkan\nhwdec=auto\n# comment | gpu-api=vulkan\nhwdec=auto\n# comentário |
| `mpvConfig.lineHint` | option=value | opção=valor |
| `mpvConfig.embeddedVoHint` | vo, gpu-context e gpu-api são ignorados no Linux: o vídeo incorporado é sempre renderizado via vo=libmpv no plano de vídeo, e gpu-next (necessário para shaders de computação como ArtCNN) não pode ser executado incorporado. | No Linux, vo, gpu-context e gpu-api são ignorados: o vídeo dentro do app sempre usa vo=libmpv, e o gpu-next (necessário para filtros como o ArtCNN) não funciona dentro do app. |

## dialog (1)

| Chave | Antes | Depois |
|---|---|---|
| `dialog.confirmAction` | Confirmar Ação | Confirmar |

## profiles (22)

| Chave | Antes | Depois |
|---|---|---|
| `profiles.switchingProfile` | Mudando perfil… | Trocando de perfil… |
| `profiles.deleteThisProfileMessage` | Remover ${displayName}. As conexões não serão afetadas. | Remover ${displayName}. As conexões com os servidores continuam. |
| `profiles.signOutPlexMessage` | Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar novamente quando quiser. | Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar de novo quando quiser. |
| `profiles.signOutFailed` | Falha ao sair. | Não deu para sair. Tente de novo. |
| `profiles.summarySingle` | Adicione perfis para combinar usuários gerenciados e identidades locais | Crie perfis para separar o que cada pessoa da casa assiste |
| `profiles.removeConnectionMessage` | Remover acesso de ${displayName} a ${connectionLabel}. Outros perfis mantêm o acesso. | Tirar o acesso de ${displayName} a ${connectionLabel}. Os outros perfis continuam com acesso. |
| `profiles.deleteProfileMessage` | Remover ${displayName} e suas conexões. Servidores continuam disponíveis. | Remover ${displayName} e as conexões dele. Os servidores continuam disponíveis. |
| `profiles.pinManagedByPlex` | PIN gerenciado pelo Plex. Edite em plex.tv. | O PIN é definido pelo Plex. Mude em plex.tv. |
| `profiles.noPinSetEditOnPlex` | Nenhum PIN definido. Para exigir um, edite o usuário do Plex Home em plex.tv. | Nenhum PIN definido. Para pedir um PIN, edite o usuário do Plex Home em plex.tv. |
| `profiles.noConnectionsHint` | Sem conexões — adicione uma para usar este perfil. | Sem conexões — adicione um servidor para usar este perfil. |
| `profiles.borrowExplain` | Use a conexão de outro perfil. Perfis protegidos por PIN exigem PIN. | Usar a conexão de outro perfil. Perfis com PIN pedem o PIN. |
| `profiles.borrowEmptySubtitle` | Conecte Plex, Jellyfin ou Emby a outro perfil primeiro. | Primeiro conecte Plex, Jellyfin ou Emby em outro perfil. |
| `profiles.borrowLoadFailed` | Não foi possível carregar as conexões disponíveis. Tente novamente. | Não deu para carregar as conexões. Tente de novo. |
| `profiles.borrowFailed` | Não foi possível adicionar a conexão. | Não deu para adicionar a conexão. Tente de novo. |
| `profiles.incorrectPinTryAgain` | PIN incorreto. Tente novamente. | PIN incorreto. Tente de novo. |
| `profiles.sourceProfileMissingParentAccount` | O perfil de origem não tem a conta principal. | O perfil escolhido não tem a conta principal. |
| `profiles.failedToLoadHomeUsers` | Não foi possível carregar os usuários do Plex Home. Verifique sua conexão e tente novamente. | Não deu para carregar os usuários do Plex Home. Confira a internet e tente de novo. |
| `profiles.failedToVerifyPin` | Não foi possível verificar o PIN. | Não deu para conferir o PIN. Tente de novo. |
| `profiles.profileNameHint` | Ex.: Visitantes, Crianças, Sala de família | Ex.: Visitas, Crianças, Sala |
| `profiles.pinExplain` | PIN de 4 dígitos necessário para trocar perfis. | PIN de 4 números para trocar de perfil. |
| `profiles.pinsDontMatch` | Os PINs não correspondem | Os PINs não são iguais |
| `profiles.tokenIdentityMismatch` | O token do perfil do Plex foi associado a um servidor inesperado | O acesso deste perfil do Plex veio de um servidor diferente do esperado. Entre de novo. |

## connections (7)

| Chave | Antes | Depois |
|---|---|---|
| `connections.addConnectionSubtitleScoped` | Adicionar a ${displayName}: Plex, Jellyfin, Emby ou outra conexão de perfil | Adicionar a ${displayName}: Plex, Jellyfin, Emby ou a conexão de outro perfil |
| `connections.sessionExpiredOne` | Sessão de ${name} expirada | O acesso a ${name} expirou |
| `connections.sessionExpiredMany` | Sessões expiradas em ${count} servidores | O acesso a ${count} servidores expirou |
| `connections.accessDeniedOne` | ${name} negou acesso a esta conta | ${name} recusou o acesso desta conta |
| `connections.accessDeniedMany` | ${count} servidores negaram acesso a esta conta | ${count} servidores recusaram o acesso desta conta |
| `connections.signInAgain` | Entrar novamente | Entrar de novo |
| `connections.editMediaBrowserIntro` | Adicione ou remova URLs para ${serverName}. O CGFLIX usará a URL acessível com menor latência. | Adicione ou remova endereços de ${serverName}. O CGFLIX usa o endereço que responder mais rápido. |

## accountPreferences (38)

| Chave | Antes | Depois |
|---|---|---|
| `accountPreferences.pickAccount` | Cada conta armazena suas próprias preferências. Escolha a que deseja editar. | Cada conta guarda suas próprias preferências. Escolha qual quer editar. |
| `accountPreferences.storedOnAccount` | Estas opções são salvas na própria conta, então todos os apps conectados a ela as utilizam — inclusive o CGFLIX nos seus outros dispositivos. | Estas opções ficam salvas na sua conta do servidor, então valem em todos os apps conectados a ela — inclusive o CGFLIX nos seus outros aparelhos. |
| `accountPreferences.noAccountsHint` | Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências armazenadas nessa conta aparecerão aqui. | Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências dessa conta aparecem aqui. |
| `accountPreferences.unavailable` | Não foi possível acessar esta conta | Não deu para acessar esta conta |
| `accountPreferences.loadFailed` | Não foi possível carregar estas preferências | Não deu para carregar estas preferências. Tente de novo. |
| `accountPreferences.autoSelectAudioDescription` | Desativado mantém a faixa de áudio que o arquivo marca como padrão. | Se desligado, usa o áudio que o arquivo marca como padrão. |
| `accountPreferences.subtitleMode` | Ativar legendas | Quando mostrar legendas |
| `accountPreferences.subtitleModes.none` | Seleção manual | Só quando eu escolher |
| `accountPreferences.subtitleModes.noneDescription` | Nunca ativar legendas por conta própria. | Nunca ligar legendas sozinho. |
| `accountPreferences.subtitleModes.defaultMode` | Seguir as marcações da faixa | Seguir o que o arquivo indica |
| `accountPreferences.subtitleModes.defaultModeDescription` | Usar as marcações padrão e forçada armazenadas em cada faixa de legenda. | Usar as marcações de padrão e forçada de cada legenda. |
| `accountPreferences.subtitleModes.always` | Sempre ativado | Sempre ligadas |
| `accountPreferences.subtitleModes.alwaysDescription` | Ativar uma faixa de legenda no idioma preferido sempre que houver uma. | Ligar a legenda no idioma preferido sempre que existir. |
| `accountPreferences.subtitleModes.onlyForced` | Apenas legendas forçadas | Só legendas forçadas |
| `accountPreferences.subtitleModes.onlyForcedDescription` | Carregar apenas as faixas marcadas como forçadas. | Ligar só as legendas marcadas como forçadas (trechos em outro idioma). |
| `accountPreferences.subtitleModes.smart` | Exibir com áudio estrangeiro | Quando o áudio for estrangeiro |
| `accountPreferences.subtitleModes.smartDescription` | Ativar legendas apenas quando o áudio estiver em outro idioma. | Ligar legendas só quando o áudio estiver em outro idioma. |
| `accountPreferences.subtitleAccessibility` | Legendas SDH | Legendas para surdos (SDH) |
| `accountPreferences.subtitleAccessibilityOptions.onlySdh` | Apenas legendas SDH | Só legendas SDH |
| `accountPreferences.subtitleAccessibilityOptions.onlyNonSdh` | Apenas legendas não SDH | Só legendas não SDH |
| `accountPreferences.forcedSubtitleOptions.onlyForced` | Apenas legendas forçadas | Só legendas forçadas |
| `accountPreferences.forcedSubtitleOptions.onlyNonForced` | Apenas legendas não forçadas | Só legendas não forçadas |
| `accountPreferences.displayMissingEpisodes` | Mostrar episódios ausentes | Mostrar episódios que faltam |
| `accountPreferences.displayMissingEpisodesDescription` | Listar episódios que o servidor conhece, mas para os quais não há arquivo. | Listar episódios que existem, mas ainda não estão no servidor. |
| `accountPreferences.hidePlayedInLatest` | Ocultar itens assistidos em Recentes | Esconder o que já foi assistido em Recentes |
| `accountPreferences.hidePlayedInLatestDescription` | Manter fora das linhas Recentes do servidor os itens que você já assistiu. | Não mostrar nas linhas de Recentes o que você já assistiu. |
| `accountPreferences.displayCollectionsView` | Mostrar a visualização de Coleções | Mostrar Coleções |
| `accountPreferences.displayCollectionsViewDescription` | Oferecer a visualização de Coleções do servidor junto às suas bibliotecas. | Mostrar as Coleções do servidor junto com as suas bibliotecas. |
| `accountPreferences.rewatchingInNextUp` | Manter séries reassistidas em A seguir | Manter em A seguir as séries que você está revendo |
| `accountPreferences.rewatchingInNextUpDescription` | Ao terminar uma série, comece a assistir de novo e A seguir acompanha a reexibição em vez de remover a série. | Se você terminar uma série e começar de novo, ela continua em A seguir em vez de sumir. |
| `accountPreferences.watchedIndicator` | Indicadores de assistido | Marcar o que já foi assistido |
| `accountPreferences.watchedIndicatorOptions.moviesAndShows` | Filmes e séries de TV | Filmes e séries |
| `accountPreferences.watchedIndicatorOptions.movies` | Apenas filmes | Só filmes |
| `accountPreferences.watchedIndicatorOptions.shows` | Apenas séries de TV | Só séries |
| `accountPreferences.mediaReviewsVisibility` | Avaliações e resenhas | Notas e críticas |
| `accountPreferences.mediaReviewsOptions.usersAndCritics` | Usuários e críticos | Público e críticos |
| `accountPreferences.mediaReviewsOptions.usersOnly` | Apenas usuários | Só público |
| `accountPreferences.mediaReviewsOptions.criticsOnly` | Apenas críticos | Só críticos |

## discover (6)

| Chave | Antes | Depois |
|---|---|---|
| `discover.addMediaToLibraries` | Adicione mídias às suas bibliotecas | Adicione filmes e séries às suas bibliotecas |
| `discover.continueWatching` | Continuar Assistindo | Continuar assistindo |
| `discover.recentlyPlayedIn` | Reproduzidos recentemente em ${library} | Tocados recentemente em ${library} |
| `discover.mostPlayedIn` | Mais reproduzidos em ${library} | Mais tocados em ${library} |
| `discover.tvShow` | Série de TV | Série |
| `discover.minutesLeft` | ${minutes} min restantes | Faltam ${minutes} min |

## errors (18)

| Chave | Antes | Depois |
|---|---|---|
| `errors.searchFailed` | Falha na busca: ${error} | Não deu para buscar: ${error} |
| `errors.searchUnavailable` | A busca não conseguiu alcançar nenhum servidor de mídia. | Não deu para buscar: nenhum servidor respondeu. Confira a internet e tente de novo. |
| `errors.connectionTimeout` | Tempo de conexão esgotado ao carregar ${context} | O servidor demorou demais para responder ao carregar ${context}. Tente de novo. |
| `errors.connectionFailed` | Não foi possível conectar ao servidor de mídia | Não deu para falar com o servidor. Confira a internet e tente de novo. |
| `errors.unableToLoad` | Não foi possível carregar ${context}. Tente novamente. | Não deu para carregar ${context}. Tente de novo. |
| `errors.noClientAvailable` | Nenhum cliente disponível | Nenhum servidor conectado |
| `errors.pleaseEnterToken` | Insira um token | Digite o código de acesso (token) |
| `errors.invalidToken` | Token inválido | Código de acesso (token) inválido |
| `errors.failedToVerifyToken` | Falha ao verificar token: ${error} | Não deu para conferir o código de acesso: ${error} |
| `errors.failedToSwitchProfile` | Falha ao trocar para ${displayName} | Não deu para trocar para ${displayName} |
| `errors.failedToDeleteProfile` | Falha ao excluir ${displayName} | Não deu para excluir ${displayName} |
| `errors.failedToRate` | Não foi possível atualizar a classificação | Não deu para salvar a avaliação. Tente de novo. |
| `errors.reasonTimedOut` | o tempo de conexão se esgotou | o servidor demorou demais para responder |
| `errors.reasonUnreachable` | não foi possível alcançar o servidor | não deu para falar com o servidor |
| `errors.reasonRefused` | o servidor recusou a solicitação | o servidor recusou o pedido |
| `errors.reasonServerError` | o servidor relatou um erro | o servidor teve um problema |
| `errors.reasonCancelled` | a solicitação foi cancelada | o pedido foi cancelado |
| `errors.reasonUnexpected` | ocorreu um erro inesperado | aconteceu um erro inesperado |

## libraries (30)

| Chave | Antes | Depois |
|---|---|---|
| `libraries.scanLibraryFiles` | Escanear Arquivos da Biblioteca | Procurar arquivos novos |
| `libraries.scanLibrary` | Escanear Biblioteca | Atualizar biblioteca |
| `libraries.analyzeLibrary` | Analisar Biblioteca | Analisar biblioteca |
| `libraries.refreshMetadata` | Atualizar Metadados | Atualizar informações |
| `libraries.emptyTrash` | Esvaziar Lixeira | Esvaziar lixeira |
| `libraries.emptyingTrash` | Esvaziando lixeira de "${title}"... | Esvaziando a lixeira de "${title}"... |
| `libraries.trashEmptied` | Lixeira esvaziada de "${title}" | Lixeira de "${title}" esvaziada |
| `libraries.failedToEmptyTrash` | Falha ao esvaziar lixeira: ${error} | Não deu para esvaziar a lixeira: ${error} |
| `libraries.analysisStarted` | Análise iniciada para "${title}" | Começou a análise de "${title}" |
| `libraries.failedToAnalyze` | Falha ao analisar biblioteca: ${error} | Não deu para analisar a biblioteca: ${error} |
| `libraries.noItemsMatchFilters` | Nenhum item corresponde aos filtros ativos | Nada encontrado com esses filtros |
| `libraries.resetFilters` | Redefinir filtros | Limpar filtros |
| `libraries.scanLibraryConfirm` | Tem certeza de que deseja escanear "${title}"? | Quer mesmo atualizar "${title}"? |
| `libraries.analyzeLibraryConfirm` | Tem certeza de que deseja analisar "${title}"? | Quer mesmo analisar "${title}"? |
| `libraries.refreshMetadataConfirm` | Tem certeza de que deseja atualizar os metadados de "${title}"? | Quer mesmo atualizar as informações de "${title}"? |
| `libraries.emptyTrashConfirm` | Tem certeza de que deseja esvaziar a lixeira de "${title}"? | Quer mesmo esvaziar a lixeira de "${title}"? |
| `libraries.manageLibraries` | Gerenciar Bibliotecas | Organizar bibliotecas |
| `libraries.confirmActionMessage` | Tem certeza de que deseja realizar esta ação? | Quer mesmo fazer isso? |
| `libraries.selectLibrary` | Selecionar biblioteca | Escolher biblioteca |
| `libraries.tabs.browse` | Navegar | Ver tudo |
| `libraries.groupings.title` | Agrupamento | Mostrar |
| `libraries.groupings.shows` | Séries de TV | Séries |
| `libraries.filterCategories.unplayed` | Não reproduzidos | Não tocados |
| `libraries.sortLabels.dateAdded` | Data de adição | Data em que foi adicionado |
| `libraries.sortLabels.datePlayed` | Data de reprodução | Data em que foi assistido |
| `libraries.sortLabels.playCount` | Reproduções | Vezes assistido |
| `libraries.sortLabels.dateShared` | Data de compartilhamento | Data em que foi compartilhado |
| `libraries.sortLabels.latestEpisodeAirDate` | Última data de exibição do episódio | Data do episódio mais recente |
| `libraries.sortLabels.lastEpisodeDateAdded` | Data de adição do último episódio | Último episódio adicionado |
| `libraries.sortLabels.dateDownloaded` | Data de download | Data em que foi baixado |

## serverSelection (2)

| Chave | Antes | Depois |
|---|---|---|
| `serverSelection.failedToLoadServers` | Falha ao carregar servidores: ${error} | Não deu para carregar os servidores: ${error} |
| `serverSelection.noValidServers` | Nenhum servidor utilizável foi encontrado nesta conta | Nenhum servidor disponível nesta conta |

## hubDetail (2)

| Chave | Antes | Depois |
|---|---|---|
| `hubDetail.releaseYear` | Ano de Lançamento | Ano de lançamento |
| `hubDetail.dateAdded` | Data de Adição | Data em que foi adicionado |

## logs (3)

| Chave | Antes | Depois |
|---|---|---|
| `logs.clearLogs` | Limpar Logs | Apagar registros |
| `logs.copyLogs` | Copiar Logs | Copiar registros |
| `logs.uploadLogs` | Enviar Logs | Enviar registros |

## startup (19)

| Chave | Antes | Depois |
|---|---|---|
| `startup.failedBody` | Algo deu errado durante a inicialização. Os detalhes abaixo identificam o que falhou. | Algo deu errado ao abrir o app. Os detalhes abaixo mostram o que falhou. |
| `startup.failedBodyRepairable` | O arquivo de configurações salvo do CGFLIX está danificado e precisa ser reconstruído antes que o CGFLIX possa iniciar. Tentar novamente não vai ajudar — escolha Reparar armazenamento. | O arquivo de configurações do CGFLIX está danificado e precisa ser refeito antes de o app abrir. Tentar de novo não resolve — toque em Reparar dados. |
| `startup.detailsCopied` | Detalhes copiados para a área de transferência | Detalhes copiados |
| `startup.repairStorage` | Reparar armazenamento | Reparar dados |
| `startup.repairTitle` | Reparar dados armazenados? | Reparar dados salvos? |
| `startup.repairBodyCommon` | O arquivo de configurações do CGFLIX está danificado e não pode ser lido. Reparar redefine todas as configurações para o padrão. | O arquivo de configurações do CGFLIX está danificado e não dá para ler. Reparar volta todas as configurações ao padrão. |
| `startup.repairBodyOneCredential` | Um login salvo está danificado e não pode ser lido. Reparar remove apenas ele; suas outras configurações permanecem intactas. | Um acesso salvo está danificado e não dá para ler. Reparar apaga só ele; suas outras configurações continuam. |
| `startup.repairBodySignInsKept` | Seus servidores e perfis devem permanecer conectados. | Seus servidores e perfis devem continuar conectados. |
| `startup.repairBodySignInsLost` | A chave que protege seus logins salvos não pode ser recuperada deste arquivo, então você terá que entrar novamente em todos os servidores e perfis. Nada no seu servidor de mídia é afetado. | Não dá para recuperar a chave que protege seus acessos salvos, então você vai precisar entrar de novo em todos os servidores e perfis. Nada muda no seu servidor. |
| `startup.repairBodySessionsUncertain` | Os rastreadores (MAL, AniList, Simkl, Trakt) e o Seerr são armazenados separadamente e podem ou não ser preservados. O CGFLIX informará exatamente o que foi mantido. | Os serviços conectados (MAL, AniList, Simkl, Trakt) e o Seerr ficam guardados à parte e podem ou não ser mantidos. O CGFLIX vai dizer exatamente o que ficou. |
| `startup.repairSucceeded` | Armazenamento reparado | Dados reparados |
| `startup.repairNeedsRestart` | Armazenamento reparado — reinício necessário | Dados reparados — reinicie o app |
| `startup.restartRequiredBody` | Seus dados foram reparados, mas o CGFLIX precisa iniciar do zero antes de usá-los. Feche o CGFLIX e abra-o novamente. | Seus dados foram reparados, mas o CGFLIX precisa ser reiniciado. Feche o CGFLIX e abra de novo. |
| `startup.repairFailed` | Falha no reparo | Não deu para reparar |
| `startup.repairLostSignIns` | A chave que protege seus logins salvos não pôde ser recuperada. Você terá que entrar novamente em todos os servidores e perfis. | Não deu para recuperar a chave que protege seus acessos salvos. Você vai precisar entrar de novo em todos os servidores e perfis. |
| `startup.repairLostSessions` | Pelo menos uma conexão de rastreador ou do Seerr foi perdida e precisa ser reconectada. | Pelo menos um serviço conectado (ou o Seerr) foi desconectado e precisa ser conectado de novo. |
| `startup.backupTitle` | Uma cópia do arquivo danificado foi mantida | Uma cópia do arquivo danificado foi guardada |
| `startup.backupWarning` | Ele contém suas credenciais de login. Não envie nem compartilhe. | Ela tem seus dados de acesso. Não envie nem compartilhe. |
| `startup.previousFailureTitle` | O CGFLIX falhou ao iniciar da última vez | O CGFLIX não conseguiu abrir da última vez |

## licenses (1)

| Chave | Antes | Depois |
|---|---|---|
| `licenses.relatedPackages` | Pacotes Relacionados | Pacotes relacionados |

## navigation (1)

| Chave | Antes | Depois |
|---|---|---|
| `navigation.liveTv` | TV ao Vivo | TV ao vivo |

## explore (29)

| Chave | Antes | Depois |
|---|---|---|
| `explore.selectSource` | Selecionar fonte | Escolher fonte |
| `explore.rows.suggestedAnime` | Anime sugerido | Animes sugeridos |
| `explore.rows.trendingAnime` | Anime em alta | Animes em alta |
| `explore.rows.popularAnime` | Anime mais popular | Animes mais populares |
| `explore.rows.upcomingMovies` | Próximos filmes | Filmes que vão estrear |
| `explore.rows.upcomingShows` | Próximas séries | Séries que vão estrear |
| `explore.addedToWatchlist` | Adicionado à lista de interesses | Adicionado à lista para assistir |
| `explore.removedFromWatchlist` | Removido da lista de interesses | Removido da lista para assistir |
| `explore.watchlistUpdateFailed` | Não foi possível atualizar a lista para assistir | Não deu para atualizar a lista para assistir. Tente de novo. |
| `explore.watchlistNoMatch` | Não foi possível associar este item a uma lista de interesses | Não deu para encontrar este título na lista para assistir |
| `explore.checkingLibrary` | Verificando sua biblioteca... | Procurando na sua biblioteca... |
| `explore.libraryCheckFailed.one` | Não foi possível verificar ${n} servidor | Não deu para procurar em ${n} servidor |
| `explore.libraryCheckFailed.other` | Não foi possível verificar ${n} servidores | Não deu para procurar em ${n} servidores |
| `explore.emptyMessage` | As linhas de ${source} aparecerão aqui quando tiverem conteúdo. | As linhas de ${source} vão aparecer aqui quando tiverem conteúdo. |
| `explore.searchFailed` | Falha na busca. Verifique sua conexão e tente novamente. | Não deu para buscar. Confira a internet e tente de novo. |
| `explore.badge.rankPopular` | #${n} popular | #${n} em popularidade |
| `explore.badge.rankRated` | #${n} avaliado | #${n} em avaliação |
| `explore.badge.requested` | Solicitado | Pedido |
| `explore.badge.pendingApproval` | Aguardando aprovação | Esperando aprovação |
| `explore.badge.processing` | Processando | Em preparo |
| `explore.badge.requestFailed` | Falha na solicitação | Pedido falhou |
| `explore.badge.requested4k` | 4K solicitado | 4K pedido |
| `explore.badge.episodesShort` | ${n} epps | ${n} eps |
| `explore.stats.favorited` | ${n} favoritos | ${n} favoritaram |
| `explore.format.tvShort` | Curta de TV | Curta para TV |
| `explore.relation.prequel` | Prequela | Antecessor |
| `explore.relation.sequel` | Sequela | Continuação |
| `explore.detail.revealSpoilerTags` | Mostrar tags de spoiler | Mostrar tags com spoiler |
| `explore.detail.background` | Contexto | Por trás da obra |

## liveTv (32)

| Chave | Antes | Depois |
|---|---|---|
| `liveTv.title` | TV ao Vivo | TV ao vivo |
| `liveTv.noDvr` | Nenhum DVR configurado em nenhum servidor | Nenhum servidor tem gravador de TV (DVR) configurado |
| `liveTv.serverUnavailable` | O servidor de TV ao vivo não está disponível. | O servidor de TV ao vivo está fora do ar. Tente de novo daqui a pouco. |
| `liveTv.noPrograms` | Nenhum dado de programação disponível | Sem programação disponível |
| `liveTv.liveStreamFailed` | Falha na transmissão ao vivo | Não deu para abrir a transmissão ao vivo. Tente de novo. |
| `liveTv.reloadGuide` | Recarregar Guia | Recarregar guia |
| `liveTv.searchNoResults` | Nenhuma correspondência para "${query}" | Nada encontrado para "${query}" |
| `liveTv.daytime` | Dia | Tarde |
| `liveTv.reorderFavorites` | Reordenar favoritos | Mudar a ordem dos favoritos |
| `liveTv.noFavoriteChannelsHint` | Mostre todos os canais e mantenha um canal pressionado para adicioná-lo aos favoritos. | Mostre todos os canais e toque e segure num canal para adicioná-lo aos favoritos. |
| `liveTv.favoritesLoadFailed` | Não foi possível carregar os favoritos. Verifique sua conexão e tente novamente. | Não deu para carregar os favoritos. Confira a internet e tente de novo. |
| `liveTv.favoritesUpdateFailed` | Não foi possível atualizar os favoritos. Verifique sua conexão e tente novamente. | Não deu para atualizar os favoritos. Confira a internet e tente de novo. |
| `liveTv.joinSession` | Entrar na sessão em andamento | Entrar no que está passando |
| `liveTv.watchFromStart` | Assistir do início (${minutes} min atrás) | Assistir do início (começou há ${minutes} min) |
| `liveTv.goToLive` | Ir para o ponto ao vivo | Voltar para o ao vivo |
| `liveTv.dvrAdminRequired` | As configurações de DVR exigem uma conta de administrador | Só o administrador do servidor pode mudar as gravações |
| `liveTv.recordingFailed` | Não foi possível agendar a gravação | Não deu para agendar a gravação. Tente de novo. |
| `liveTv.recordingTargetMissing` | Não foi possível determinar a biblioteca de gravação | Não deu para saber em qual biblioteca gravar |
| `liveTv.processRecordingRules` | Reavaliar regras | Aplicar regras de novo |
| `liveTv.guideReloadRequested` | Atualização do guia solicitada | O guia vai ser atualizado |
| `liveTv.guideReloadFailed` | Não foi possível atualizar o guia | Não deu para atualizar o guia. Tente de novo. |
| `liveTv.rulesProcessRequested` | Reavaliação de regras solicitada | As regras vão ser aplicadas de novo |
| `liveTv.rulesProcessFailed` | Não foi possível reavaliar as regras de gravação | Não deu para aplicar as regras de gravação. Tente de novo. |
| `liveTv.recordSettings.newOnly` | Apenas episódios novos | Só episódios novos |
| `liveTv.recordSettings.skipInLibrary` | Ignorar episódios que já estão na biblioteca | Pular episódios que já estão na biblioteca |
| `liveTv.recordSettings.keepUpTo` | Episódios a manter | Quantos episódios guardar |
| `liveTv.recordSettings.keepUpToHint` | 0 mantém todos os episódios | 0 guarda todos os episódios |
| `liveTv.invalidPlaybackData` | ${product} retornou dados inválidos de reprodução de TV ao Vivo | O ${product} mandou informações erradas para a TV ao vivo. Tente de novo. |
| `liveTv.failedToStartChannel` | Não foi possível iniciar o canal ao vivo | Não deu para abrir o canal ao vivo. Tente de novo. |
| `liveTv.failedToBuildStreamUrl` | Não foi possível gerar a URL da transmissão | Não deu para montar o endereço da transmissão |
| `liveTv.playbackStartFailed` | Não foi possível iniciar o canal: ${reason} | Não deu para abrir o canal: ${reason} |
| `liveTv.channelSwitchFailed` | Não foi possível trocar de canal: ${reason} | Não deu para trocar de canal: ${reason} |

## collections (11)

| Chave | Antes | Depois |
|---|---|---|
| `collections.deleteCollection` | Excluir Coleção | Excluir coleção |
| `collections.deleteConfirm` | Excluir "${title}"? Não pode ser desfeito. | Excluir "${title}"? Não dá para desfazer. |
| `collections.deleteFailed` | Falha ao excluir coleção | Não deu para excluir a coleção. Tente de novo. |
| `collections.deleteFailedWithError` | Falha ao excluir coleção: ${error} | Não deu para excluir a coleção: ${error} |
| `collections.selectCollection` | Selecionar Coleção | Escolher coleção |
| `collections.collectionName` | Nome da Coleção | Nome da coleção |
| `collections.enterCollectionName` | Insira o nome da coleção | Digite o nome da coleção |
| `collections.errorAddingToCollection` | Falha ao adicionar à coleção | Não deu para adicionar à coleção. Tente de novo. |
| `collections.removeFromCollectionFailed` | Falha ao remover da coleção | Não deu para remover da coleção. Tente de novo. |
| `collections.removeFromCollectionError` | Erro ao remover da coleção: ${error} | Não deu para remover da coleção: ${error} |
| `collections.searchCollections` | Pesquisar coleções... | Buscar coleções... |

## playlists (16)

| Chave | Antes | Depois |
|---|---|---|
| `playlists.create` | Criar Playlist | Criar playlist |
| `playlists.playlistName` | Nome da Playlist | Nome da playlist |
| `playlists.enterPlaylistName` | Insira o nome da playlist | Digite o nome da playlist |
| `playlists.delete` | Excluir Playlist | Excluir playlist |
| `playlists.removeItem` | Remover da Playlist | Remover da playlist |
| `playlists.smartPlaylist` | Playlist Inteligente | Playlist inteligente |
| `playlists.deleteConfirm` | Excluir Playlist? | Excluir playlist? |
| `playlists.deleteMessage` | Tem certeza de que deseja excluir "${name}"? | Quer mesmo excluir "${name}"? |
| `playlists.selectPlaylist` | Selecionar Playlist | Escolher playlist |
| `playlists.searchPlaylists` | Pesquisar playlists... | Buscar playlists... |
| `playlists.errorCreating` | Falha ao criar playlist | Não deu para criar a playlist. Tente de novo. |
| `playlists.errorDeleting` | Falha ao excluir playlist | Não deu para excluir a playlist. Tente de novo. |
| `playlists.errorLoading` | Falha ao carregar playlists | Não deu para carregar as playlists. Tente de novo. |
| `playlists.errorAdding` | Falha ao adicionar à playlist | Não deu para adicionar à playlist. Tente de novo. |
| `playlists.errorReordering` | Falha ao reordenar item da playlist | Não deu para mudar a ordem da playlist. Tente de novo. |
| `playlists.errorRemoving` | Falha ao remover da playlist | Não deu para remover da playlist. Tente de novo. |

## music (11)

| Chave | Antes | Depois |
|---|---|---|
| `music.playNext` | Reproduzir a seguir | Tocar em seguida |
| `music.nowPlaying` | Reproduzindo agora | Tocando agora |
| `music.playingFrom` | Reproduzindo de ${title} | Tocando de ${title} |
| `music.noLyrics` | Nenhuma letra disponível | Sem letra disponível |
| `music.sleepTimer` | Temporizador de suspensão | Desligar automaticamente |
| `music.stopPlayback` | Parar reprodução | Parar de tocar |
| `music.repeatOne` | Repetir uma faixa | Repetir esta faixa |
| `music.instantMixNoServer` | Nenhum servidor está disponível para uma mistura instantânea | Nenhum servidor disponível para o mix instantâneo |
| `music.instantMixFailed` | Falha ao carregar o mix instantâneo | Não deu para carregar o mix instantâneo. Tente de novo. |
| `music.instantMixEmpty` | O mix instantâneo não retornou nenhuma faixa | O mix instantâneo veio sem nenhuma faixa |
| `music.noAudioUrl` | Nenhuma URL de áudio está disponível para ${track} | Não foi encontrado o endereço do áudio de ${track} |

## watchTogether (45)

| Chave | Antes | Depois |
|---|---|---|
| `watchTogether.title` | Assistir Juntos | Assistir juntos |
| `watchTogether.description` | Assista a conteúdos sincronizados com amigos e familiares | Assista ao mesmo tempo com amigos e família, cada um na sua tela |
| `watchTogether.controlModeQuestion` | Quem pode controlar a reprodução? | Quem pode pausar e avançar? |
| `watchTogether.hostOnly` | Apenas o anfitrião | Só o anfitrião |
| `watchTogether.hostingSession` | Hospedando uma sessão | Você criou uma sessão |
| `watchTogether.openSessionControls` | Abrir os controles da sessão Assistir Juntos | Abrir os controles do Assistir juntos |
| `watchTogether.hostControlsPlayback` | O anfitrião controla a reprodução | Só o anfitrião pode pausar e avançar |
| `watchTogether.anyoneCanControl` | Qualquer pessoa pode controlar a reprodução | Qualquer pessoa pode pausar e avançar |
| `watchTogether.hostControls` | Controle do anfitrião | Anfitrião controla |
| `watchTogether.anyoneControls` | Controle por qualquer pessoa | Todos controlam |
| `watchTogether.makeHostQuestion` | Transferir anfitrião? | Passar o controle de anfitrião? |
| `watchTogether.makeHostConfirm` | ${name} controlará a reprodução e conduzirá a sessão para todos. | ${name} vai controlar o vídeo e conduzir a sessão para todos. |
| `watchTogether.transfer` | Transferir | Passar |
| `watchTogether.hostTransferFailed` | Não foi possível tornar ${name} o anfitrião | Não deu para passar o controle para ${name} |
| `watchTogether.endSessionConfirm` | Isso encerrará a sessão para todos os participantes. | Isso vai encerrar a sessão para todo mundo. |
| `watchTogether.leaveSessionConfirm` | Você será removido da sessão. | Você vai sair da sessão. |
| `watchTogether.endSessionConfirmOverlay` | Isso encerrará a sessão do Assistir Juntos para todos os participantes. | Isso vai encerrar o Assistir juntos para todo mundo. |
| `watchTogether.leaveSessionConfirmOverlay` | Você será desconectado da sessão do Assistir Juntos. | Você vai sair do Assistir juntos. |
| `watchTogether.enterCodeHint` | Insira o código de 5 caracteres | Digite o código de 5 letras e números |
| `watchTogether.pasteFromClipboard` | Colar da área de transferência | Colar |
| `watchTogether.pleaseEnterCode` | Insira um código de sessão | Digite o código da sessão |
| `watchTogether.codeMustBe5Chars` | O código da sessão deve ter 5 caracteres | O código da sessão tem 5 letras e números |
| `watchTogether.joinInstructions` | Insira o código de sessão do anfitrião para entrar. | Digite o código que o anfitrião passou para entrar. |
| `watchTogether.failedToCreate` | Falha ao criar sessão | Não deu para criar a sessão. Confira a internet e tente de novo. |
| `watchTogether.failedToJoin` | Falha ao entrar na sessão | Não deu para entrar na sessão. Confira o código e tente de novo. |
| `watchTogether.sessionCodeCopied` | Código da sessão copiado para a área de transferência | Código da sessão copiado |
| `watchTogether.relayUnreachable` | Servidor de retransmissão inacessível. O bloqueio pelo provedor de internet pode impedir o uso do Assistir Juntos. | Não deu para falar com o servidor do Assistir juntos. Sua operadora de internet pode estar bloqueando. |
| `watchTogether.currentPlayback` | Reprodução atual | O que está passando |
| `watchTogether.joinCurrentPlayback` | Entrar na reprodução atual | Ir para o que está passando |
| `watchTogether.joinCurrentPlaybackDescription` | Voltar ao conteúdo que o anfitrião está assistindo agora | Voltar para o que o anfitrião está assistindo agora |
| `watchTogether.failedToOpenCurrentPlayback` | Falha ao abrir a reprodução atual | Não deu para abrir o que está passando. Tente de novo. |
| `watchTogether.participantResumed` | ${name} retomou | ${name} continuou |
| `watchTogether.participantSeeked` | ${name} mudou a posição da reprodução | ${name} avançou ou voltou o vídeo |
| `watchTogether.participantChangedSpeed` | ${name} definiu a velocidade para ${speed} | ${name} mudou a velocidade para ${speed} |
| `watchTogether.participantBuffering` | ${name} está aguardando o carregamento | ${name} está carregando o vídeo |
| `watchTogether.participantNeedsUpdate` | ${name} está usando uma versão mais antiga do app — sincronização indisponível | ${name} está com uma versão antiga do app — precisa atualizar para assistirem juntos |
| `watchTogether.resumingWithout` | Retomando sem ${name} | Continuando sem ${name} |
| `watchTogether.waitingForParticipants` | Aguardando o carregamento dos outros participantes... | Esperando os outros carregarem o vídeo... |
| `watchTogether.waitingForName` | Aguardando ${name}... | Esperando ${name}... |
| `watchTogether.guestSwitchUnavailable` | Não foi possível trocar — servidor indisponível para sincronização | Não deu para trocar — o servidor não está disponível |
| `watchTogether.guestSwitchFailed` | Não foi possível trocar — conteúdo não encontrado neste servidor | Não deu para trocar — este título não está no seu servidor |
| `watchTogether.errors.timedOut` | O servidor de retransmissão não respondeu a tempo | O servidor do Assistir juntos demorou demais para responder. Tente de novo. |
| `watchTogether.errors.connectionLost` | A conexão foi encerrada antes de a sessão ficar pronta | A conexão caiu antes de a sessão ficar pronta. Tente de novo. |
| `watchTogether.errors.invalidRelayResponse` | O servidor de retransmissão enviou uma resposta inesperada | O servidor do Assistir juntos respondeu algo inesperado. Tente de novo. |
| `watchTogether.errors.sessionUnavailable` | Não foi possível retomar esta sessão. Entre em uma sala ou crie uma para continuar. | Não deu para voltar a esta sessão. Entre em uma sala ou crie uma nova. |

## downloads (87)

| Chave | Antes | Depois |
|---|---|---|
| `downloads.manage` | Gerenciar | Organizar |
| `downloads.tvShows` | Séries de TV | Séries |
| `downloads.tracksQueued` | ${count} faixas na fila para download | ${count} faixas na fila para baixar |
| `downloads.noDownloads` | Nenhum download ainda | Nada baixado ainda |
| `downloads.noDownloadsDescription` | O conteúdo baixado aparecerá aqui para assistir offline | O que você baixar aparece aqui para assistir sem internet |
| `downloads.deleteDownload` | Excluir download | Apagar baixado |
| `downloads.retryDownload` | Tentar download novamente | Tentar baixar de novo |
| `downloads.downloadQueued` | Download na fila | Na fila para baixar |
| `downloads.downloadResumed` | Download retomado | Voltou a baixar |
| `downloads.serverErrorBitrate` | Erro do servidor: o arquivo pode exceder o limite remoto de taxa de bits | Erro no servidor: o arquivo pode passar do limite de qualidade permitido fora de casa |
| `downloads.storageFull` | Os downloads foram interrompidos para proteger o espaço disponível. Libere espaço ou escolha outro local de download e tente novamente. | Paramos de baixar para não lotar a memória do aparelho. Libere espaço ou escolha outra pasta e tente de novo. |
| `downloads.storageUnavailable` | Os downloads foram interrompidos porque não foi possível verificar o armazenamento disponível. Verifique o local de download e tente novamente. | Paramos de baixar porque não deu para conferir o espaço livre. Confira a pasta dos baixados e tente de novo. |
| `downloads.episodesQueued` | ${count} episódios na fila de download | ${count} episódios na fila para baixar |
| `downloads.downloadDeleted` | Download excluído | Baixado apagado |
| `downloads.deleteConfirm` | Excluir "${title}" deste dispositivo? | Apagar "${title}" deste aparelho? |
| `downloads.cancelledDownloadMessage` | Este download foi cancelado. O que você deseja fazer? | Este download foi cancelado. O que você quer fazer? |
| `downloads.resumeDownload` | Retomar download | Continuar baixando |
| `downloads.syncingFile` | ${file} (sincronizando ${status}) | ${file} (atualizando ${status}) |
| `downloads.downloadedFileClickToComplete` | ${file} baixado — clique para concluir | ${file} baixado — toque para concluir |
| `downloads.partialDownloadClickToComplete` | Parcialmente baixado — clique para concluir | Baixado em parte — toque para concluir |
| `downloads.deleting` | Excluindo... | Apagando... |
| `downloads.deletingWithProgress` | Excluindo ${title}... (${current} de ${total}) | Apagando ${title}... (${current} de ${total}) |
| `downloads.noDownloadsTree` | Nenhum download | Nada baixado |
| `downloads.resumeAll` | Retomar todos | Continuar todos |
| `downloads.deleteAll` | Excluir todos | Apagar todos |
| `downloads.selectVersion` | Selecionar versão | Escolher versão |
| `downloads.unwatchedOnly` | Apenas não assistidos | Só não assistidos |
| `downloads.customAmount` | Quantidade personalizada... | Outra quantidade... |
| `downloads.invalidEpisodeCount` | Insira uma quantidade válida de episódios. | Digite uma quantidade válida de episódios. |
| `downloads.keepSynced` | Manter sincronizado | Baixar novos sozinho |
| `downloads.keepNUnwatched` | Manter ${count} episódios não assistidos | Manter ${count} episódios não assistidos baixados |
| `downloads.editSyncRule` | Editar regra de sincronização | Editar download automático |
| `downloads.removeSyncRule` | Remover regra de sincronização | Parar download automático |
| `downloads.removeSyncRuleConfirm` | Parar de sincronizar "${title}"? Os episódios baixados serão mantidos. | Parar de baixar "${title}" automaticamente? Os episódios já baixados continuam no aparelho. |
| `downloads.removeListSyncRuleConfirm` | Parar a sincronização de "${title}"? | Parar de baixar "${title}" automaticamente? |
| `downloads.deleteSyncRuleDownloads` | Também excluir downloads associados | Apagar também os baixados desta regra |
| `downloads.deleteSyncRuleDownloadsDescription` | Downloads usados por outra regra de sincronização ou perfil serão mantidos. | Baixados usados por outra regra ou outro perfil continuam no aparelho. |
| `downloads.syncRuleCreated` | Regra de sincronização criada — mantendo ${count} episódios não assistidos | Download automático ligado — mantendo ${count} episódios não assistidos |
| `downloads.syncRuleUpdated` | Regra de sincronização atualizada | Download automático atualizado |
| `downloads.syncRuleRemoved` | Regra de sincronização removida | Download automático desligado |
| `downloads.syncRuleAndDownloadsRemoved` | Regra de sincronização e downloads associados removidos | Download automático desligado e baixados apagados |
| `downloads.syncRuleCleanupBusy` | As regras de sincronização estão sendo atualizadas. Tente novamente em instantes. | Os downloads automáticos estão sendo atualizados. Tente de novo daqui a pouco. |
| `downloads.syncRuleCleanupUnavailable` | Os downloads associados não puderam ser identificados com segurança. Reconecte o servidor e tente novamente, ou remova a regra sem excluir os downloads. | Não deu para saber com segurança quais baixados são desta regra. Conecte o servidor de novo e tente outra vez, ou desligue a regra sem apagar os baixados. |
| `downloads.syncedNewEpisodes` | ${count} novos episódios sincronizados para ${title} | ${count} episódios novos de ${title} baixados |
| `downloads.activeSyncRules` | Regras de sincronização | Downloads automáticos |
| `downloads.noSyncRules` | Nenhuma regra de sincronização | Nenhum download automático |
| `downloads.manageSyncRule` | Gerenciar sincronização | Ajustar download automático |
| `downloads.editSyncFilter` | Filtro de sincronização | O que baixar |
| `downloads.syncAllItems` | Sincronizando todos os itens | Baixando todos os itens |
| `downloads.syncUnwatchedItems` | Sincronizando itens não assistidos | Baixando os não assistidos |
| `downloads.syncRuleOffline` | Offline | Sem conexão |
| `downloads.syncRuleSignInRequired` | É necessário entrar | Precisa entrar de novo |
| `downloads.syncRuleNotAvailableForProfile` | Indisponível para o perfil atual | Indisponível para este perfil |
| `downloads.syncRuleListCreated` | Regra de sincronização criada | Download automático ligado |
| `downloads.backgroundWarning.bannerBlocked` | Os downloads serão interrompidos ao sair do app | Os downloads vão parar quando você sair do app |
| `downloads.backgroundWarning.bannerDegraded` | Os downloads em segundo plano podem ser limitados | Os downloads com o app fechado podem ficar lentos ou parar |
| `downloads.backgroundWarning.sheetTitle` | Os downloads em segundo plano estão bloqueados | Os downloads com o app fechado estão bloqueados |
| `downloads.backgroundWarning.sheetTitleDegraded` | Os downloads em segundo plano podem ser limitados | Os downloads com o app fechado podem ficar lentos ou parar |
| `downloads.backgroundWarning.sheetIntro` | O Android está impedindo que o CGFLIX faça downloads de forma confiável em segundo plano. | O Android está impedindo o CGFLIX de baixar direito com o app fechado. |
| `downloads.backgroundWarning.sheetIntroDegraded` | Seu dispositivo está limitando quando o CGFLIX pode fazer downloads em segundo plano. | Seu aparelho está limitando quando o CGFLIX pode baixar com o app fechado. |
| `downloads.backgroundWarning.reasonBackgroundRestricted` | O uso em segundo plano do CGFLIX está restrito. Defina o uso da bateria ou o uso em segundo plano como "Sem restrições". | O CGFLIX está com o uso em segundo plano restrito. Mude o uso da bateria (ou uso em segundo plano) para "Sem restrições". |
| `downloads.backgroundWarning.reasonStandbyRestricted` | O Android colocou o CGFLIX em um modo de espera restrito. Defina o uso da bateria como "Sem restrições". | O Android colocou o CGFLIX em modo de espera restrito. Mude o uso da bateria para "Sem restrições". |
| `downloads.backgroundWarning.reasonDownloadChannelBlocked` | As notificações de download estão desativadas; por isso, o progresso e os controles podem ficar indisponíveis. | As notificações de download estão desligadas, então o progresso e os botões podem não aparecer. |
| `downloads.backgroundWarning.reasonNotificationsDisabled` | As notificações estão desativadas. No Android 13 ou mais recente, elas são necessárias para downloads longos em segundo plano. | As notificações estão desligadas. No Android 13 ou mais novo, elas são necessárias para baixar com o app fechado. |
| `downloads.backgroundWarning.reasonDataSaver` | A Economia de dados está ativada e bloqueia downloads em segundo plano usando dados móveis. Os downloads ainda devem funcionar no Wi-Fi. | A Economia de dados está ligada e bloqueia downloads com o app fechado nos dados móveis. No Wi-Fi deve funcionar normalmente. |
| `downloads.backgroundWarning.reasonOemUnknown` | Os downloads foram interrompidos várias vezes enquanto o CGFLIX estava em segundo plano. Verifique as configurações de bateria ou uso em segundo plano do CGFLIX. | Os downloads pararam várias vezes com o CGFLIX em segundo plano. Confira as configurações de bateria e de uso em segundo plano do CGFLIX. |
| `downloads.backgroundWarning.stillNotWorking` | Ajuda específica para o dispositivo | Ajuda para o seu aparelho |
| `downloads.backgroundWarning.stillNotWorkingDescription` | Veja as instruções para seu dispositivo ou, se o problema persistir, envie um log em Configurações › Ver Logs. | Veja as instruções para o seu aparelho ou, se continuar, envie os registros em Configurações › Ver registros (logs). |
| `downloads.backgroundWarning.dialogTitle` | Os downloads podem não ser concluídos | Os downloads podem não terminar |
| `downloads.backgroundWarning.dialogFixFirst` | Corrigir primeiro | Resolver antes |
| `downloads.backgroundWarning.statusTile` | Downloads em segundo plano | Baixar com o app fechado |
| `downloads.backgroundWarning.statusOk` | Execução em segundo plano permitida | Permitido baixar com o app fechado |
| `downloads.backgroundWarning.statusBlocked` | Bloqueado pelas configurações do sistema | Bloqueado pelas configurações do aparelho |
| `downloads.backgroundWarning.statusDegraded` | Limitado pelas configurações do sistema | Limitado pelas configurações do aparelho |
| `downloads.backgroundWarning.statusUnknown` | Ainda não verificado | Ainda não conferido |
| `downloads.backgroundWarning.settingsUnavailable` | Não foi possível abrir as configurações do sistema neste dispositivo | Não deu para abrir as configurações do aparelho |
| `downloads.backgroundWarning.linkUnavailable` | Não foi possível abrir dontkillmyapp.com neste dispositivo | Não deu para abrir dontkillmyapp.com neste aparelho |
| `downloads.options` | Opções de downloads | Opções dos baixados |
| `downloads.errorFileNotFound` | Arquivo não encontrado (404) | Arquivo não encontrado no servidor (404) |
| `downloads.errorDownloadNotAllowed` | Download não permitido pelo servidor (403) | O servidor não permite baixar este item (403) |
| `downloads.errorDownloadFailed` | Falha no download | Não deu para baixar. Confira a internet e tente de novo. |
| `downloads.errorDownloadFailedWithReason` | Falha no download: ${reason} | Não deu para baixar: ${reason} |
| `downloads.errorHttpStatus` | Falha no download (HTTP ${status}) | Não deu para baixar (erro ${status}) |
| `downloads.errorPostProcessing` | Falha no pós-processamento: ${reason} | Não deu para finalizar o arquivo baixado: ${reason} |
| `downloads.reasonFileNotSaved` | não foi possível salvar o arquivo neste dispositivo | não deu para salvar o arquivo neste aparelho |
| `downloads.reasonCannotResume` | não foi possível retomar o download parcial | não deu para continuar de onde parou |
| `downloads.reasonDeviceStorageFull` | este dispositivo está sem espaço de armazenamento | o aparelho está sem espaço |

## shaders (9)

| Chave | Antes | Depois |
|---|---|---|
| `shaders.title` | Shaders | Filtros de imagem (shaders) |
| `shaders.noShaderDescription` | Sem aprimoramento de vídeo | Sem melhoria de imagem |
| `shaders.nvscalerDescription` | Dimensionamento de imagem da NVIDIA para vídeos mais nítidos | Ampliação de imagem da NVIDIA para vídeos mais nítidos |
| `shaders.qualityHQ` | Alta Qualidade | Alta qualidade |
| `shaders.importShader` | Importar Shader | Importar filtro |
| `shaders.customShaderDescription` | Shader GLSL personalizado | Filtro GLSL personalizado |
| `shaders.shaderImported` | Shader importado | Filtro importado |
| `shaders.shaderImportFailed` | Falha ao importar shader | Não deu para importar o filtro. Confira o arquivo e tente de novo. |
| `shaders.deleteShader` | Excluir Shader | Excluir filtro |

## companionRemote (41)

| Chave | Antes | Depois |
|---|---|---|
| `companionRemote.unknownDevice` | Dispositivo desconhecido | Aparelho desconhecido |
| `companionRemote.session.startingServer` | Iniciando servidor remoto... | Ligando o controle remoto... |
| `companionRemote.session.hostAddress` | Endereço do host | Endereço deste aparelho |
| `companionRemote.session.serverRunning` | Servidor remoto ativo | Controle remoto ligado |
| `companionRemote.session.serverStopped` | Servidor remoto parado | Controle remoto desligado |
| `companionRemote.session.serverRunningDescription` | Dispositivos móveis na sua rede podem se conectar a este app | Celulares na sua rede Wi-Fi podem se conectar a este app |
| `companionRemote.session.serverStoppedDescription` | Inicie o servidor para permitir que dispositivos móveis se conectem | Ligue o controle remoto para que celulares possam se conectar |
| `companionRemote.session.usePhoneToControl` | Use seu dispositivo móvel para controlar este app | Use seu celular para controlar este app |
| `companionRemote.session.startServer` | Iniciar servidor | Ligar |
| `companionRemote.session.stopServer` | Parar servidor | Desligar |
| `companionRemote.session.manualAddressHint` | Endereço de conexão manual: | Endereço para conectar manualmente: |
| `companionRemote.pairing.discoveryDescription` | Dispositivos CGFLIX com a mesma conta Plex aparecem aqui | Aparelhos com o CGFLIX na mesma conta Plex aparecem aqui |
| `companionRemote.pairing.searchingForDevices` | Procurando dispositivos... | Procurando aparelhos... |
| `companionRemote.pairing.noDevicesFound` | Nenhum dispositivo encontrado na sua rede | Nenhum aparelho encontrado na sua rede |
| `companionRemote.pairing.noDevicesHint` | Abra o CGFLIX no desktop e use a mesma rede Wi-Fi | Abra o CGFLIX no computador e use a mesma rede Wi-Fi |
| `companionRemote.pairing.availableDevices` | Dispositivos disponíveis | Aparelhos disponíveis |
| `companionRemote.pairing.manualConnection` | Conexão manual | Conectar manualmente |
| `companionRemote.pairing.cryptoInitFailed` | Não foi possível iniciar a conexão segura. Entre no Plex primeiro. | Não deu para iniciar a conexão segura. Entre no Plex primeiro. |
| `companionRemote.pairing.validationHostRequired` | Insira o endereço do host | Digite o endereço do aparelho |
| `companionRemote.pairing.validationHostFormat` | O formato deve ser IP:porta (ex.: 192.168.1.100:48632) | Use o formato IP:porta (ex.: 192.168.1.100:48632) |
| `companionRemote.pairing.connectionTimedOut` | A conexão atingiu o tempo limite. Use a mesma rede nos dois dispositivos. | O outro aparelho demorou demais para responder. Use a mesma rede Wi-Fi nos dois. |
| `companionRemote.pairing.sessionNotFound` | Dispositivo não encontrado. Verifique se o CGFLIX está em execução no host. | Aparelho não encontrado. Confira se o CGFLIX está aberto nele. |
| `companionRemote.pairing.authFailed` | Falha na autenticação. Ambos os dispositivos precisam da mesma conta Plex. | Não deu para conectar. Os dois aparelhos precisam estar na mesma conta Plex. |
| `companionRemote.pairing.failedToConnect` | Falha ao conectar: ${error} | Não deu para conectar: ${error} |
| `companionRemote.remote.disconnectConfirm` | Deseja desconectar da sessão remota? | Quer desconectar do controle remoto? |
| `companionRemote.remote.tabRemote` | Remoto | Controle |
| `companionRemote.remote.tabPlay` | Reproduzir | Assistir |
| `companionRemote.remote.tabNavigation` | Navegação por abas | Abas |
| `companionRemote.remote.tabDownloads` | Downloads | Baixados |
| `companionRemote.remote.playPause` | Reproduzir/Pausar | Reproduzir/pausar |
| `companionRemote.remote.seekBack` | Retroceder | Voltar |
| `companionRemote.remote.searchHint` | Buscar no desktop... | Buscar no computador... |
| `companionRemote.errors.noNetworkInterface` | Nenhuma interface de rede encontrada | Nenhuma conexão de rede encontrada. Confira o Wi-Fi. |
| `companionRemote.errors.authenticationFailed` | Falha na autenticação | Não deu para confirmar o acesso |
| `companionRemote.errors.serverStartFailed` | Falha ao iniciar o servidor remoto: ${error} | Não deu para ligar o controle remoto: ${error} |
| `companionRemote.errors.commandFailed` | Falha ao enviar o comando remoto: ${error} | Não deu para enviar o comando: ${error} |
| `companionRemote.errors.joinTimedOut` | Tempo esgotado ao entrar na sessão | Demorou demais para conectar. Tente de novo. |
| `companionRemote.errors.failedToConnectAnyAddress` | Falha ao conectar a qualquer endereço | Não deu para conectar em nenhum endereço |
| `companionRemote.errors.connectionLostAfterAttempts` | Conexão perdida após ${attempts} tentativas | A conexão caiu depois de ${attempts} tentativas |
| `companionRemote.errors.connectionLost` | Conexão perdida | A conexão caiu |
| `companionRemote.closedBeforeAuth` | A conexão foi encerrada antes da autenticação | A conexão caiu antes de confirmar o acesso |

## videoSettings (14)

| Chave | Antes | Depois |
|---|---|---|
| `videoSettings.playbackSpeed` | Velocidade de Reprodução | Velocidade |
| `videoSettings.sleepTimerActive` | Ativo (${duration}) | Ligado (${duration}) |
| `videoSettings.sleepTimer` | Temporizador de suspensão | Desligar automaticamente |
| `videoSettings.audioSync` | Sincronia de áudio | Atraso do áudio |
| `videoSettings.subtitleSync` | Sincronia de legendas | Atraso da legenda |
| `videoSettings.hdrUnsupported` | O HDR não está disponível aqui — este compositor da área de trabalho ou esta saída de vídeo não é compatível com ele. | HDR não está disponível aqui — a tela ou o sistema do computador não é compatível. |
| `videoSettings.hdrToneMapping` | Mapeamento de tons HDR | Ajuste de cores HDR |
| `videoSettings.hdrToneMappingCompositor` | Compositor | Sistema |
| `videoSettings.hdrToneMappingCompositorDescription` | Repassar os metadados HDR da fonte e deixar que o compositor da área de trabalho faça o mapeamento. | Mandar as informações de HDR do vídeo e deixar o sistema do computador ajustar as cores. |
| `videoSettings.hdrToneMappingPlayerDescription` | Mapear para o brilho máximo da tela no reprodutor e informar o resultado ao compositor. | O reprodutor ajusta as cores para o brilho máximo da tela e avisa o sistema. |
| `videoSettings.hdrToneMappingFailed` | Não foi possível alterar o mapeamento de tons HDR — o modo anterior continua ativo. | Não deu para mudar o ajuste de cores HDR — continua o modo anterior. |
| `videoSettings.audioNormalization` | Normalizar intensidade sonora | Nivelar volume |
| `videoSettings.audioNormalizationDisablesPassthrough` | Decodifica o áudio para PCM; a passagem direta fica desativada enquanto esta opção estiver ativa | Converte o áudio para PCM; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada |
| `videoSettings.audioNormalizationStereoMix` | Decodifica o áudio para uma mixagem estéreo; a passagem direta fica desativada enquanto esta opção estiver ativa | Junta os canais de áudio em estéreo; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada |

## performanceOverlay (6)

| Chave | Antes | Depois |
|---|---|---|
| `performanceOverlay.buffer` | Buffer | Memória de reprodução |
| `performanceOverlay.passthrough` | Passagem direta | Envio direto |
| `performanceOverlay.uiFps` | UI FPS | FPS da interface |
| `performanceOverlay.tunnelingActive` | Ativo | Ligado |
| `performanceOverlay.cacheUsed` | Cache usado | Memória temporária usada |
| `performanceOverlay.cacheLimit` | Limite do cache | Limite da memória temporária |

## externalPlayer (6)

| Chave | Antes | Depois |
|---|---|---|
| `externalPlayer.useExternalPlayerDescription` | Abrir vídeos em outro app | Abrir os vídeos em outro app |
| `externalPlayer.selectPlayer` | Selecionar reprodutor | Escolher reprodutor |
| `externalPlayer.playerUrlScheme` | Esquema de URL | Esquema de endereço (URL) |
| `externalPlayer.off` | Desativado | Desligado |
| `externalPlayer.launchFailed` | Falha ao abrir o reprodutor externo | Não deu para abrir o reprodutor externo. Confira se ele está instalado. |
| `externalPlayer.playInExternalPlayer` | Reproduzir no reprodutor externo | Assistir no reprodutor externo |

## metadataEdit (42)

| Chave | Antes | Depois |
|---|---|---|
| `metadataEdit.screenTitle` | Editar Metadados | Editar informações |
| `metadataEdit.basicInfo` | Informações Básicas | Informações básicas |
| `metadataEdit.artwork` | Arte | Imagens |
| `metadataEdit.advancedSettings` | Configurações Avançadas | Configurações avançadas |
| `metadataEdit.sortTitle` | Título para Ordenação | Título para ordenar |
| `metadataEdit.originalTitle` | Título Original | Título original |
| `metadataEdit.releaseDate` | Data de Lançamento | Data de lançamento |
| `metadataEdit.contentRating` | Classificação Indicativa | Classificação indicativa |
| `metadataEdit.background` | Plano de Fundo | Imagem de fundo |
| `metadataEdit.squareArt` | Imagem Quadrada | Imagem quadrada |
| `metadataEdit.selectPoster` | Selecionar pôster | Escolher pôster |
| `metadataEdit.selectBackground` | Selecionar Plano de Fundo | Escolher imagem de fundo |
| `metadataEdit.selectLogo` | Selecionar Logo | Escolher logo |
| `metadataEdit.selectSquareArt` | Selecionar Imagem Quadrada | Escolher imagem quadrada |
| `metadataEdit.fromUrl` | Da URL | De um endereço (URL) |
| `metadataEdit.uploadFile` | Enviar Arquivo | Enviar arquivo |
| `metadataEdit.enterImageUrl` | Insira a URL da imagem | Digite o endereço da imagem |
| `metadataEdit.imageUrl` | URL da Imagem | Endereço da imagem |
| `metadataEdit.metadataUpdated` | Metadados atualizados | Informações atualizadas |
| `metadataEdit.metadataUpdateFailed` | Falha ao atualizar metadados | Não deu para atualizar as informações. Tente de novo. |
| `metadataEdit.artworkUpdated` | Arte atualizada | Imagem atualizada |
| `metadataEdit.artworkUpdateFailed` | Falha ao atualizar arte | Não deu para atualizar a imagem. Tente de novo. |
| `metadataEdit.noArtworkAvailable` | Nenhuma arte disponível | Nenhuma imagem disponível |
| `metadataEdit.artworkOption` | Opção de arte ${index} | Opção de imagem ${index} |
| `metadataEdit.selectedArtworkOption` | Opção de arte ${index}, selecionada | Opção de imagem ${index}, selecionada |
| `metadataEdit.episodeSorting` | Ordenação de Episódios | Ordem dos episódios |
| `metadataEdit.deleteAfterPlaying` | Excluir Episódios Após Reproduzir | Apagar episódios depois de assistir |
| `metadataEdit.afterADay` | Após um dia | Depois de um dia |
| `metadataEdit.afterAWeek` | Após uma semana | Depois de uma semana |
| `metadataEdit.afterAMonth` | Após um mês | Depois de um mês |
| `metadataEdit.episodeOrdering` | Ordenação de Episódios | Ordem dos episódios |
| `metadataEdit.tmdbAiring` | The Movie Database (Exibição) | The Movie Database (exibição) |
| `metadataEdit.tvdbAiring` | TheTVDB (Exibição) | TheTVDB (exibição) |
| `metadataEdit.tvdbAbsolute` | TheTVDB (Absoluto) | TheTVDB (absoluta) |
| `metadataEdit.metadataLanguage` | Idioma dos Metadados | Idioma das informações |
| `metadataEdit.useOriginalTitle` | Usar Título Original | Usar título original |
| `metadataEdit.preferredAudioLanguage` | Idioma de Áudio Preferido | Idioma de áudio preferido |
| `metadataEdit.preferredSubtitleLanguage` | Idioma de Legenda Preferido | Idioma de legenda preferido |
| `metadataEdit.subtitleMode` | Modo de Seleção Automática de Legendas | Quando mostrar legendas |
| `metadataEdit.manuallySelected` | Seleção manual | Só quando eu escolher |
| `metadataEdit.shownWithForeignAudio` | Exibir com áudio estrangeiro | Quando o áudio for estrangeiro |
| `metadataEdit.alwaysEnabled` | Sempre ativado | Sempre ligadas |

## matchScreen (10)

| Chave | Antes | Depois |
|---|---|---|
| `matchScreen.match` | Associar... | Identificar... |
| `matchScreen.fixMatch` | Corrigir correspondência... | Corrigir identificação... |
| `matchScreen.unmatch` | Desassociar | Remover identificação |
| `matchScreen.unmatchConfirm` | Limpar esta correspondência? Plex tratará como sem correspondência até refazer. | Remover a identificação deste item? O Plex vai tratá-lo como não identificado até você identificar de novo. |
| `matchScreen.unmatchSuccess` | Item desassociado | Identificação removida |
| `matchScreen.unmatchFailed` | Falha ao desassociar item | Não deu para remover a identificação. Tente de novo. |
| `matchScreen.matchApplied` | Correspondência aplicada | Identificação aplicada |
| `matchScreen.matchFailed` | Falha ao aplicar correspondência | Não deu para aplicar a identificação. Tente de novo. |
| `matchScreen.search` | Pesquisar | Buscar |
| `matchScreen.noMatchesFound` | Nenhuma correspondência encontrada | Nada encontrado |

## serverTasks (1)

| Chave | Antes | Depois |
|---|---|---|
| `serverTasks.failedToLoad` | Falha ao carregar tarefas | Não deu para carregar as tarefas. Tente de novo. |

## trakt (5)

| Chave | Antes | Depois |
|---|---|---|
| `trakt.disconnectConfirmBody` | O CGFLIX deixará de enviar eventos ao Trakt. Você pode reconectar quando quiser. | O CGFLIX vai parar de enviar ao Trakt o que você assiste. Você pode conectar de novo quando quiser. |
| `trakt.scrobble` | Scrobbling em tempo real | Marcar como assistido em tempo real |
| `trakt.scrobbleDescription` | Envia eventos de reprodução, pausa e parada ao Trakt durante a exibição. | Avisa o Trakt quando você começa, pausa ou para um vídeo. |
| `trakt.watchedSync` | Sincronizar status de assistido | Sincronizar o que foi assistido |
| `trakt.watchedSyncDescription` | Ao marcar itens como assistidos no CGFLIX, eles também serão marcados no Trakt. | O que você marcar como assistido no CGFLIX também fica marcado no Trakt. |

## seerr (31)

| Chave | Antes | Depois |
|---|---|---|
| `seerr.serverUrl` | URL do servidor | Endereço do servidor |
| `seerr.serverUrlHelper` | O endereço da sua instância do Seerr | O endereço do seu Seerr |
| `seerr.signInWithLocal` | Usar uma conta local | Usar uma conta do próprio Seerr |
| `seerr.noSignInMethods` | Esta instância do Seerr não oferece nenhum método de acesso compatível com o CGFLIX. | Este Seerr não tem nenhuma forma de entrar que funcione com o CGFLIX. |
| `seerr.instance` | Instância | Servidor |
| `seerr.disconnectConfirmBody` | O CGFLIX esquecerá esta instância do Seerr. Reconecte quando quiser. | O CGFLIX vai esquecer este Seerr. Você pode conectar de novo quando quiser. |
| `seerr.request` | Solicitar | Pedir |
| `seerr.request4k` | Solicitar em 4K | Pedir em 4K |
| `seerr.advancedOptions` | Avançado | Opções avançadas |
| `seerr.requestSubmitted` | Solicitação enviada | Pedido enviado |
| `seerr.requestFailed` | Falha na solicitação: ${error} | Não deu para enviar o pedido: ${error} |
| `seerr.requestsLoadFailed` | Não foi possível carregar as opções de solicitação | Não deu para carregar as opções do pedido. Tente de novo. |
| `seerr.nothingToRequest` | Tudo já está disponível ou solicitado. | Tudo já está disponível ou já foi pedido. |
| `seerr.statusRequested` | Solicitado | Pedido |
| `seerr.statusProcessing` | Processando | Em preparo |
| `seerr.statusBlocklisted` | Na lista de bloqueio | Bloqueado |
| `seerr.couldNotReach` | Não foi possível acessar ${url}: ${error} | Não deu para falar com ${url}: ${error} |
| `seerr.noInstanceAtUrl` | Nenhuma instância do Seerr em ${url} (HTTP ${status}) | Nenhum Seerr encontrado em ${url} (erro ${status}) |
| `seerr.behindAuthProxy` | Um proxy reverso com autenticação (SSO ou autenticação HTTP) respondeu no lugar do Seerr. O CGFLIX não consegue entrar através dele: permita que o caminho /api/v1 do Seerr ignore o proxy para este aplicativo, ou use um endereço que alcance o Seerr diretamente. | Um sistema de login (SSO ou senha HTTP) respondeu no lugar do Seerr, e o CGFLIX não consegue passar por ele. Peça ao responsável pelo servidor para liberar o caminho /api/v1 do Seerr, ou use um endereço que chegue direto ao Seerr. |
| `seerr.invalidUrl` | Insira um endereço de servidor como https://seerr.example.com | Digite um endereço de servidor, por exemplo https://seerr.example.com |
| `seerr.quickConnectUnsupported` | Esta instância do Seerr não oferece suporte a Quick Connect. Ela precisa do Seerr 3.4 ou mais recente. | Este Seerr não aceita Quick Connect. Ele precisa do Seerr 3.4 ou mais novo. |
| `seerr.notInitialized` | Esta instância do Seerr não concluiu a configuração inicial | Este Seerr ainda não terminou a configuração inicial |
| `seerr.noPlexTokenForReauth` | Nenhum token do Plex está disponível para entrar novamente | Não há acesso do Plex salvo para entrar de novo |
| `seerr.noStoredCredentials` | Nenhuma credencial armazenada está disponível para entrar novamente | Não há dados de acesso salvos para entrar de novo |
| `seerr.signInRejected` | A entrada foi rejeitada | O acesso foi recusado. Confira os dados e tente de novo. |
| `seerr.noSessionCookie` | O Seerr não forneceu um cookie de sessão | O Seerr não confirmou o acesso. Tente entrar de novo. |
| `seerr.freshCookieRejected` | O Seerr rejeitou o novo cookie de sessão | O Seerr recusou o novo acesso. Tente entrar de novo. |
| `seerr.noUserInformation` | O Seerr não retornou informações do usuário | O Seerr não mandou as informações do usuário |
| `seerr.sessionRejectedAfterReauth` | A sessão foi rejeitada após entrar novamente | O acesso foi recusado mesmo depois de entrar de novo |
| `seerr.permissionDenied` | O Seerr negou esta ação: sua conta não tem mais a permissão necessária | O Seerr não deixou fazer isso: sua conta não tem mais essa permissão |
| `seerr.permissionRevoked` | Você não tem mais permissão para solicitar isso | Você não tem mais permissão para pedir isso |

## services (10)

| Chave | Antes | Depois |
|---|---|---|
| `services.hubSubtitle` | Sincronize o progresso de exibição e solicite novos títulos. | Sincronize o que você assistiu e peça novos títulos. |
| `services.scrobble` | Registrar progresso automaticamente | Marcar como assistido automaticamente |
| `services.disconnectConfirmBody` | O CGFLIX deixará de atualizar ${service}. Reconecte quando quiser. | O CGFLIX vai parar de atualizar o ${service}. Você pode conectar de novo quando quiser. |
| `services.connectFailed` | Não foi possível conectar ao ${service}. Tente novamente. | Não deu para conectar ao ${service}. Confira a internet e tente de novo. |
| `services.deviceCode.instructions` | Leia o código QR ou acesse o endereço abaixo e insira este código: | Leia o código QR ou abra o endereço abaixo e digite este código: |
| `services.deviceCode.waitingForAuthorization` | Aguardando autorização… | Esperando a autorização… |
| `services.oauthProxy.body` | Leia este código QR ou abra a URL em qualquer dispositivo. | Leia este código QR ou abra o endereço em qualquer aparelho. |
| `services.pendingAuth.copyUrl` | Copiar URL de acesso | Copiar endereço de acesso |
| `services.pendingAuth.urlCopied` | URL copiada | Endereço copiado |
| `services.libraryFilter.modeHintWhitelist` | Sincronizar apenas as bibliotecas marcadas abaixo. | Sincronizar só as bibliotecas marcadas abaixo. |

## addServer (37)

| Chave | Antes | Depois |
|---|---|---|
| `addServer.serverUrls` | URLs do servidor | Endereços do servidor |
| `addServer.serverUrlsHelper` | Várias URLs são permitidas, separadas por vírgulas. | Pode colocar mais de um endereço, separados por vírgula. |
| `addServer.searchingLocalMediaBrowserServers` | Procurando servidores ${product} locais... | Procurando servidores ${product} na sua rede... |
| `addServer.localMediaBrowserServers` | Servidores ${product} locais | Servidores ${product} na sua rede |
| `addServer.change` | Alterar | Trocar |
| `addServer.couldNotReachServer` | Não foi possível conectar ao servidor: ${error} | Não deu para falar com o servidor (${error}). Confira o endereço e a internet. |
| `addServer.signInFailed` | Falha ao entrar: ${error} | Não deu para entrar (${error}). Confira a internet e tente de novo. |
| `addServer.quickConnectFailed` | Quick Connect falhou: ${error} | Não deu para entrar com o Quick Connect (${error}). Tente de novo. |
| `addServer.pinExpired` | O PIN expirou antes de entrar. Tente novamente. | O código expirou antes de você entrar. Tente de novo. |
| `addServer.failedToRegisterAccount` | Falha ao registrar a conta: ${error} | Não deu para salvar a conta neste aparelho (${error}). Tente de novo. |
| `addServer.enterMediaBrowserUrlError` | Digite a URL do seu servidor ${product} | Digite o endereço do seu servidor ${product} |
| `addServer.connectToMediaBrowserCard` | Conectar ao ${product} | Entrar no ${product} |
| `addServer.signInWithPlexCardSubtitle` | Autorize este dispositivo. Servidores compartilhados são adicionados. | Autorize este aparelho. Os servidores compartilhados com você são adicionados. |
| `addServer.signInWithPlexCardSubtitleScoped` | Autorize uma conta Plex. Os usuários do Plex Home se tornam perfis. | Autorize uma conta Plex. Os usuários do Plex Home viram perfis. |
| `addServer.connectToMediaBrowserCardSubtitle` | Digite a URL do servidor, o nome de usuário e a senha. | Digite o endereço do servidor, seu usuário e sua senha. |
| `addServer.connectToMediaBrowserCardSubtitleScoped` | Entre no seu servidor ${product}. Vinculado a ${name}. | Entre no seu servidor ${product}. Fica ligado a ${name}. |
| `addServer.borrowFromAnotherProfile` | Pegar emprestado de outro perfil | Usar a conexão de outro perfil |
| `addServer.borrowFromAnotherProfileSubtitle` | Reutilize a conexão de outro perfil. Perfis protegidos por PIN exigem PIN. | Aproveite a conexão de outro perfil. Perfis com PIN pedem o PIN. |
| `addServer.invalidCredentials` | Usuário ou senha inválidos | Usuário ou senha incorretos |
| `addServer.authResponseNotJson` | A resposta de autenticação não era um JSON válido | O servidor respondeu algo inesperado ao entrar. Confira o endereço. |
| `addServer.authResponseIncomplete` | A resposta de login do servidor estava incompleta | O servidor respondeu pela metade ao entrar. Tente de novo. |
| `addServer.quickConnectRejected` | O Quick Connect foi rejeitado pelo servidor | O servidor recusou o Quick Connect |
| `addServer.quickConnectNotJson` | A resposta do Quick Connect não era um JSON válido | O servidor respondeu algo inesperado no Quick Connect. Tente de novo. |
| `addServer.quickConnectMissingFields` | A resposta do Quick Connect não contém um código ou segredo | O servidor não mandou o código do Quick Connect. Tente de novo. |
| `addServer.quickConnectPollRejected` | A consulta do Quick Connect foi rejeitada pelo servidor | O servidor recusou o Quick Connect enquanto esperava a aprovação |
| `addServer.serverTimedOut` | O servidor não respondeu a tempo | O servidor demorou demais para responder. Tente de novo. |
| `addServer.responseNotJson` | A resposta do servidor não era um JSON válido | O servidor respondeu algo inesperado. Confira o endereço. |
| `addServer.responseMissingIdentity` | A resposta não contém um ID ou nome de servidor — este é um servidor ${product}? | A resposta não parece de um servidor ${product}. Confira o endereço. |
| `addServer.probeFailed` | Não foi possível conectar ao servidor: ${error} | Não deu para falar com o servidor (${error}). Confira o endereço e a internet. |
| `addServer.enterAtLeastOneUrl` | Insira pelo menos uma URL de servidor ${product} | Digite pelo menos um endereço de servidor ${product} |
| `addServer.noReachableServer` | Nenhum servidor ${product} acessível foi encontrado | Não deu para encontrar nenhum servidor ${product}. Confira o endereço e a internet. |
| `addServer.urlsPointToDifferentServers` | Estas URLs apontam para servidores ${product} diferentes | Esses endereços levam a servidores ${product} diferentes |
| `addServer.urlDoesNotMatchServer` | Esta URL não corresponde ao servidor ${product} | Este endereço não é deste servidor ${product} |
| `addServer.redirectUnsupported` | O servidor redirecionou para uma URL não compatível | O servidor mandou para um endereço que não funciona aqui |
| `addServer.redirectDifferentHost` | O servidor redirecionou para outro host. Insira diretamente a URL final do ${product}. | O servidor mandou para outro endereço. Digite direto o endereço final do ${product}. |
| `addServer.redirectInsecure` | O servidor redirecionou de HTTPS para uma URL insegura | O servidor mandou de HTTPS para um endereço sem segurança |
| `addServer.redirectUnsupportedEnterFinal` | O servidor redirecionou para uma URL não compatível. Insira diretamente a URL final do ${product}. | O servidor mandou para um endereço que não funciona aqui. Digite direto o endereço final do ${product}. |
