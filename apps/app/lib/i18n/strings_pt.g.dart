///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsPt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsPt _root = this; // ignore: unused_field

	@override 
	TranslationsPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$pt app = _Translations$app$pt._(_root);
	@override late final _Translations$auth$pt auth = _Translations$auth$pt._(_root);
	@override late final _Translations$common$pt common = _Translations$common$pt._(_root);
	@override late final _Translations$screens$pt screens = _Translations$screens$pt._(_root);
	@override late final _Translations$update$pt update = _Translations$update$pt._(_root);
	@override late final _Translations$settings$pt settings = _Translations$settings$pt._(_root);
	@override late final _Translations$search$pt search = _Translations$search$pt._(_root);
	@override late final _Translations$hotkeys$pt hotkeys = _Translations$hotkeys$pt._(_root);
	@override late final _Translations$fileInfo$pt fileInfo = _Translations$fileInfo$pt._(_root);
	@override late final _Translations$mediaMenu$pt mediaMenu = _Translations$mediaMenu$pt._(_root);
	@override late final _Translations$rateSheet$pt rateSheet = _Translations$rateSheet$pt._(_root);
	@override late final _Translations$accessibility$pt accessibility = _Translations$accessibility$pt._(_root);
	@override late final _Translations$tooltips$pt tooltips = _Translations$tooltips$pt._(_root);
	@override late final _Translations$audioTracks$pt audioTracks = _Translations$audioTracks$pt._(_root);
	@override late final _Translations$videoControls$pt videoControls = _Translations$videoControls$pt._(_root);
	@override late final _Translations$messages$pt messages = _Translations$messages$pt._(_root);
	@override late final _Translations$subtitlingStyling$pt subtitlingStyling = _Translations$subtitlingStyling$pt._(_root);
	@override late final _Translations$mpvConfig$pt mpvConfig = _Translations$mpvConfig$pt._(_root);
	@override late final _Translations$dialog$pt dialog = _Translations$dialog$pt._(_root);
	@override late final _Translations$profiles$pt profiles = _Translations$profiles$pt._(_root);
	@override late final _Translations$connections$pt connections = _Translations$connections$pt._(_root);
	@override late final _Translations$accountPreferences$pt accountPreferences = _Translations$accountPreferences$pt._(_root);
	@override late final _Translations$discover$pt discover = _Translations$discover$pt._(_root);
	@override late final _Translations$errors$pt errors = _Translations$errors$pt._(_root);
	@override late final _Translations$libraries$pt libraries = _Translations$libraries$pt._(_root);
	@override late final _Translations$about$pt about = _Translations$about$pt._(_root);
	@override late final _Translations$serverSelection$pt serverSelection = _Translations$serverSelection$pt._(_root);
	@override late final _Translations$hubDetail$pt hubDetail = _Translations$hubDetail$pt._(_root);
	@override late final _Translations$logs$pt logs = _Translations$logs$pt._(_root);
	@override late final _Translations$startup$pt startup = _Translations$startup$pt._(_root);
	@override late final _Translations$licenses$pt licenses = _Translations$licenses$pt._(_root);
	@override late final _Translations$navigation$pt navigation = _Translations$navigation$pt._(_root);
	@override late final _Translations$explore$pt explore = _Translations$explore$pt._(_root);
	@override late final _Translations$liveTv$pt liveTv = _Translations$liveTv$pt._(_root);
	@override late final _Translations$collections$pt collections = _Translations$collections$pt._(_root);
	@override late final _Translations$playlists$pt playlists = _Translations$playlists$pt._(_root);
	@override late final _Translations$music$pt music = _Translations$music$pt._(_root);
	@override late final _Translations$watchTogether$pt watchTogether = _Translations$watchTogether$pt._(_root);
	@override late final _Translations$downloads$pt downloads = _Translations$downloads$pt._(_root);
	@override late final _Translations$shaders$pt shaders = _Translations$shaders$pt._(_root);
	@override late final _Translations$companionRemote$pt companionRemote = _Translations$companionRemote$pt._(_root);
	@override late final _Translations$videoSettings$pt videoSettings = _Translations$videoSettings$pt._(_root);
	@override late final _Translations$performanceOverlay$pt performanceOverlay = _Translations$performanceOverlay$pt._(_root);
	@override late final _Translations$externalPlayer$pt externalPlayer = _Translations$externalPlayer$pt._(_root);
	@override late final _Translations$metadataEdit$pt metadataEdit = _Translations$metadataEdit$pt._(_root);
	@override late final _Translations$matchScreen$pt matchScreen = _Translations$matchScreen$pt._(_root);
	@override late final _Translations$serverTasks$pt serverTasks = _Translations$serverTasks$pt._(_root);
	@override late final _Translations$trakt$pt trakt = _Translations$trakt$pt._(_root);
	@override late final _Translations$seerr$pt seerr = _Translations$seerr$pt._(_root);
	@override late final _Translations$services$pt services = _Translations$services$pt._(_root);
	@override late final _Translations$addServer$pt addServer = _Translations$addServer$pt._(_root);
}

// Path: app
class _Translations$app$pt extends Translations$app$en {
	_Translations$app$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'CGFLIX';
}

// Path: auth
class _Translations$auth$pt extends Translations$auth$en {
	_Translations$auth$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get signInWithPlex => 'Entrar com Plex';
	@override String get showQRCode => 'Mostrar código QR';
	@override String get authenticate => 'Confirmar acesso';
	@override String get authenticationTimeout => 'O tempo para entrar acabou. Tente de novo.';
	@override String get scanQRToSignIn => 'Leia este código QR para entrar';
	@override String get waitingForAuth => 'Esperando você entrar...\nConclua o acesso no navegador.';
	@override String get useBrowser => 'Usar navegador';
	@override String get or => 'ou';
	@override String connectToMediaBrowser({required Object product}) => 'Entrar no ${product}';
	@override String get quickConnect => 'Quick Connect';
	@override String get useQuickConnect => 'Usar Quick Connect';
	@override String get quickConnectInstructions => 'Abra o Quick Connect no Jellyfin (em outro aparelho já conectado) e digite este código.';
	@override String get quickConnectWaiting => 'Esperando a aprovação…';
	@override String get quickConnectCancel => 'Cancelar';
	@override String get quickConnectExpired => 'O código do Quick Connect expirou. Tente de novo.';
	@override String get localDataRecoveryRequired => 'O CGFLIX não conseguiu recuperar com segurança seus dados de acesso e o que você assistiu sem internet. Entre de novo.';
	@override String get pinCheckRejected => 'O Plex recusou o código de acesso. Tente de novo.';
}

// Path: common
class _Translations$common$pt extends Translations$common$en {
	_Translations$common$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get clear => 'Limpar';
	@override String get reset => 'Redefinir';
	@override String get later => 'Depois';
	@override String get submit => 'Enviar';
	@override String get confirm => 'Confirmar';
	@override String get retry => 'Tentar de novo';
	@override String get logout => 'Sair';
	@override String get unknown => 'Desconhecido';
	@override String get refresh => 'Atualizar';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String get delete => 'Excluir';
	@override String get edit => 'Editar';
	@override String get shuffle => 'Aleatório';
	@override String get addTo => 'Adicionar a...';
	@override String get createNew => 'Criar novo';
	@override String get connect => 'Conectar';
	@override String get disconnect => 'Desconectar';
	@override String get play => 'Assistir';
	@override String get pause => 'Pausar';
	@override String get resume => 'Continuar';
	@override String get error => 'Erro';
	@override String get search => 'Buscar';
	@override String get home => 'Início';
	@override String get back => 'Voltar';
	@override String get settings => 'Configurações';
	@override String get mute => 'Silenciar';
	@override String get ok => 'OK';
	@override String get off => 'Desligado';
	@override String get options => 'Opções';
	@override String seasonNumber({required Object number}) => 'Temporada ${number}';
	@override String episodeNumberTitle({required Object number, required Object title}) => 'Episódio ${number} - ${title}';
	@override String chapterNumber({required Object number}) => 'Capítulo ${number}';
	@override String get reconnect => 'Reconectar';
	@override String get viewAll => 'Ver tudo';
	@override String get checkingNetwork => 'Verificando a internet...';
	@override String get loadingServers => 'Carregando servidores...';
	@override String get connectingToServers => 'Conectando aos servidores...';
	@override String get startingOfflineMode => 'Abrindo o modo sem internet...';
	@override String get loading => 'Carregando...';
	@override String get fullscreen => 'Tela cheia';
	@override String get exitFullscreen => 'Sair da tela cheia';
	@override String get pressBackAgainToExit => 'Toque em voltar de novo para sair';
	@override late final _Translations$common$ratingSource$pt ratingSource = _Translations$common$ratingSource$pt._(_root);
	@override String get notAvailable => 'N/D';
	@override String get url => 'Endereço';
	@override String get letterKeys => 'ABC';
	@override late final _Translations$common$mediaKind$pt mediaKind = _Translations$common$mediaKind$pt._(_root);
}

// Path: screens
class _Translations$screens$pt extends Translations$screens$en {
	_Translations$screens$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get licenses => 'Licenças';
	@override String get switchProfile => 'Trocar perfil';
	@override String get subtitleStyling => 'Estilo das legendas';
	@override String get mpvConfig => 'mpv.conf';
	@override String get logs => 'Registros (logs)';
}

// Path: update
class _Translations$update$pt extends Translations$update$en {
	_Translations$update$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get available => 'Atualização disponível';
	@override String versionAvailable({required Object version}) => 'A versão ${version} está disponível';
	@override String currentVersion({required Object version}) => 'Atual: ${version}';
	@override String get skipVersion => 'Pular esta versão';
	@override String get viewRelease => 'Ver novidades';
	@override String get latestVersion => 'Você já está na versão mais recente';
	@override String get checkFailed => 'Não deu para procurar atualizações. Confira a internet e tente de novo.';
}

// Path: settings
class _Translations$settings$pt extends Translations$settings$en {
	_Translations$settings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configurações';
	@override String get supportDeveloper => 'Apoie o CGFLIX';
	@override String get supportDeveloperDescription => 'Doe pelo Liberapay para ajudar no desenvolvimento';
	@override String get language => 'Idioma';
	@override String get theme => 'Tema';
	@override String get appearance => 'Aparência';
	@override String get videoPlayback => 'Ao assistir';
	@override String get videoPlaybackDescription => 'gestos e janelinha';
	@override String get advanced => 'Avançado';
	@override String get episodePosterMode => 'Imagem dos episódios';
	@override String get seriesPoster => 'Pôster da série';
	@override String get seasonPoster => 'Pôster da temporada';
	@override String get episodeThumbnail => 'Miniatura';
	@override String get showHeroSectionDescription => 'Mostrar um carrossel de destaques na tela inicial';
	@override String get secondsLabel => 'Segundos';
	@override String get minutesLabel => 'Minutos';
	@override String get secondsShort => 's';
	@override String get minutesShort => 'min';
	@override String durationHint({required Object min, required Object max}) => 'Digite um valor de ${min} a ${max}';
	@override String get systemTheme => 'Sistema';
	@override String get lightTheme => 'Claro';
	@override String get darkTheme => 'Escuro';
	@override String get oledTheme => 'OLED';
	@override String get libraryDensity => 'Tamanho dos itens na biblioteca';
	@override String get displayScale => 'Tamanho da interface';
	@override String get compact => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get gridSpacing => 'Espaçamento da grade';
	@override String get gridSpacingTight => 'Compacto';
	@override String get gridSpacingNormal => 'Normal';
	@override String get gridSpacingSpacious => 'Espaçoso';
	@override String get tvCornerSpotlightBackdrop => 'Imagem de destaque no canto';
	@override String get tvCornerSpotlightBackdropDescription => 'Mostrar a imagem de destaque no canto superior direito em vez de ocupar a tela toda';
	@override String get viewMode => 'Modo de exibição';
	@override String get gridView => 'Grade';
	@override String get listView => 'Lista';
	@override String get showHeroSection => 'Mostrar destaques';
	@override String get continueWatchingAction => 'Ao tocar em Continuar assistindo';
	@override String get continueWatchingPlay => 'Assistir';
	@override String get continueWatchingDetails => 'Abrir detalhes';
	@override String get episodeAction => 'Ao tocar em um episódio';
	@override String get episodePlay => 'Assistir';
	@override String get episodeDetails => 'Abrir detalhes';
	@override String get useGlobalHubs => 'Usar tela inicial unificada';
	@override String get useGlobalHubsDescription => 'Mostrar as seções da tela inicial juntas. Se desligado, usa as recomendações de cada biblioteca.';
	@override String get showServerNameOnHubs => 'Mostrar nome do servidor nas seções';
	@override String get showServerNameOnHubsDescription => 'Sempre mostrar o nome do servidor no título das seções.';
	@override String get groupLibrariesByServer => 'Agrupar bibliotecas por servidor';
	@override String get groupLibrariesByServerDescription => 'Agrupar as bibliotecas do menu lateral por servidor.';
	@override String get alwaysKeepSidebarOpen => 'Manter menu lateral sempre aberto';
	@override String get alwaysKeepSidebarOpenDescription => 'O menu lateral fica aberto e o conteúdo se ajusta ao lado';
	@override String get showUnwatchedCount => 'Mostrar quantos faltam assistir';
	@override String get showUnwatchedCountDescription => 'Mostrar o número de episódios não assistidos em séries e temporadas';
	@override String get showWatchedIndicators => 'Marcar o que já foi assistido';
	@override String get showWatchedIndicatorsDescription => 'Mostrar um sinal de visto em filmes, séries e episódios já assistidos';
	@override String get showEpisodeNumberOnCards => 'Mostrar número do episódio';
	@override String get showEpisodeNumberOnCardsDescription => 'Mostrar temporada e episódio nas capas dos episódios';
	@override String get showSeasonPostersOnTabs => 'Mostrar pôsteres nas abas de temporada';
	@override String get showSeasonPostersOnTabsDescription => 'Mostrar o pôster de cada temporada acima da aba';
	@override String get tvFullCardLayout => 'Capas completas na TV';
	@override String get tvFullCardLayoutDescription => 'Na TV, mostrar capas só com a imagem e os nomes dos atores por cima';
	@override String get focusGlow => 'Brilho na seleção';
	@override String get focusGlowDescription => 'Mostrar um brilho suave em volta da capa selecionada';
	@override String get visualEffects => 'Efeitos visuais';
	@override String get visualEffectsAuto => 'Automático';
	@override String get visualEffectsAutoDescription => 'Reduzir os efeitos sozinho em aparelhos mais simples';
	@override String get visualEffectsFull => 'Completos';
	@override String get visualEffectsReduced => 'Reduzidos';
	@override String get visualEffectsReducedDescription => 'Menos animações e imagens em menor resolução';
	@override String get hideSpoilers => 'Ocultar spoilers de episódios não assistidos';
	@override String get hideSpoilersDescription => 'Desfocar imagens e resumos dos episódios que você ainda não viu';
	@override String get playerBackend => 'Reprodutor de vídeo';
	@override String get exoPlayer => 'ExoPlayer';
	@override String get mpv => 'mpv';
	@override String get hardwareDecoding => 'Aceleração de vídeo';
	@override String get hardwareDecodingDescription => 'Usar o chip de vídeo do aparelho quando possível (mais leve e economiza bateria)';
	@override String get playbackBuffer => 'Carregamento antecipado';
	@override String get playbackBufferAuto => 'Automático (recomendado)';
	@override String get playbackBufferLarge => 'Grande';
	@override String get playbackBufferExtraLarge => 'Extra grande';
	@override String get playbackBufferDescription => 'Carrega mais vídeo antes para evitar travadas em internet instável. Também depende do tamanho da memória de reprodução.';
	@override String get defaultQualityTitle => 'Qualidade padrão';
	@override String get cellularQualityTitle => 'Qualidade padrão nos dados móveis';
	@override String get cellularQualitySameAsDefault => 'Igual à qualidade padrão';
	@override String get directPlayCoveredQuality => 'Vídeos menores na qualidade original';
	@override String get directPlayCoveredQualityDescription => 'Tocar direto, sem conversão no servidor, os vídeos que já cabem no limite de qualidade';
	@override String get videoCodecs => 'Codecs de vídeo';
	@override String get videoCodecsDescription => 'Formatos desmarcados são convertidos pelo servidor';
	@override String get videoCodecsAlwaysAccepted => 'Sempre aceito';
	@override String get musicQualityTitle => 'Qualidade da música';
	@override String get subtitleStyling => 'Estilo das legendas';
	@override String get subtitleStylingDescription => 'Tamanho, cor, contorno e fundo da legenda';
	@override String get smallSkipDuration => 'Avançar e voltar (toque curto)';
	@override String get largeSkipDuration => 'Avançar e voltar (toque longo)';
	@override String get rewindOnResume => 'Voltar um pouco ao continuar';
	@override String secondsUnit({required Object seconds}) => '${seconds} segundos';
	@override String get defaultSleepTimer => 'Desligar automaticamente após (padrão)';
	@override String minutesUnit({required Object minutes}) => '${minutes} minutos';
	@override String get rememberTrackSelections => 'Lembrar áudio e legenda de cada série/filme';
	@override String get rememberTrackSelectionsDescription => 'Guardar suas escolhas de áudio e legenda para cada título';
	@override String get rememberTrackSelectionsBackendRule => 'No Plex, cada escolha fica salva no servidor por arquivo; no Jellyfin, também liga a opção "Lembrar seleções" da sua conta; no Emby não funciona';
	@override String get followServerTrackSelections => 'Usar o áudio e a legenda do servidor em cada episódio';
	@override String get followServerTrackSelectionsDescription => 'Ao trocar de episódio, usar o áudio e a legenda escolhidos no servidor em vez de manter a escolha atual';
	@override String get resumeMusicOnLaunch => 'Lembrar a sessão de música';
	@override String get resumeMusicOnLaunchDescription => 'Ao abrir o app, retomar a última música de onde parou';
	@override String get showChapterMarkersOnTimeline => 'Mostrar capítulos na barra de progresso';
	@override String get showChapterMarkersOnTimelineDescription => 'Dividir a barra de progresso no início de cada capítulo';
	@override String get specialsOrdering => 'Especiais na ordem dos episódios';
	@override String get specialsOrderingDescription => 'Em que ponto da série os especiais aparecem';
	@override String get specialsOrderingServer => 'Seguir a ordem do servidor';
	@override String get specialsOrderingAirDate => 'Misturar pela data de exibição';
	@override String get specialsOrderingLast => 'Depois das temporadas normais';
	@override String get clickVideoTogglesPlayback => 'Clicar no vídeo para pausar/continuar';
	@override String get clickVideoTogglesPlaybackDescription => 'Um clique no vídeo pausa ou continua, em vez de mostrar os controles.';
	@override String get videoPlayerControls => 'Controles do reprodutor de vídeo';
	@override String get keyboardShortcuts => 'Atalhos de teclado';
	@override String get keyboardShortcutsDescription => 'Mudar os atalhos de teclado';
	@override String get videoPlayerNavigation => 'Navegação do reprodutor de vídeo';
	@override String get videoPlayerNavigationDescription => 'Usar as setas para andar pelos controles do reprodutor';
	@override String get watchTogetherRelay => 'Servidor do Assistir juntos';
	@override String get watchTogetherRelayDescription => 'Usar outro servidor para o Assistir juntos. Todos precisam usar o mesmo.';
	@override String get watchTogetherRelayHint => 'https://minha-retransmissao.exemplo.com.br';
	@override String get watchTogetherRelayInvalid => 'Digite um endereço válido, começando com http:// ou https://.';
	@override String get crashReporting => 'Relatório de erros';
	@override String get crashReportingDescription => 'Enviar relatórios de erro para ajudar a melhorar o app';
	@override String get debugLogging => 'Registros de diagnóstico';
	@override String get debugLoggingDescription => 'Guardar registros detalhados para ajudar a resolver problemas';
	@override String get viewLogs => 'Ver registros (logs)';
	@override String get viewLogsDescription => 'Ver os registros do app';
	@override String get clearImageCache => 'Limpar memória de imagens';
	@override String get clearImageCacheDescription => 'Apagar capas e miniaturas guardadas no aparelho. As imagens podem demorar um pouco mais para aparecer até serem baixadas de novo.';
	@override String get clearImageCacheSuccess => 'Memória de imagens limpa';
	@override String get resetSettings => 'Restaurar configurações';
	@override String get resetSettingsDescription => 'Voltar todas as configurações ao padrão. Não dá para desfazer.';
	@override String get resetSettingsSuccess => 'Configurações restauradas';
	@override String get backup => 'Cópia de segurança';
	@override String get exportSettings => 'Exportar configurações';
	@override String get exportSettingsDescription => 'Salvar suas preferências em um arquivo';
	@override String get exportSettingsSuccess => 'Configurações exportadas';
	@override String get importSettings => 'Importar configurações';
	@override String get importSettingsDescription => 'Trazer preferências de um arquivo';
	@override String get importSettingsConfirm => 'Isso vai substituir suas configurações atuais. Continuar?';
	@override String get importSettingsSuccess => 'Configurações importadas';
	@override String get importSettingsInvalidFile => 'Este arquivo não é uma exportação válida do CGFLIX';
	@override String get importSettingsNoUser => 'Entre na sua conta antes de importar as configurações';
	@override String get shortcutsReset => 'Atalhos voltaram ao padrão';
	@override String get resetShortcutsConfirm => 'Isso troca seus atalhos personalizados pelos padrões. Continuar?';
	@override String get about => 'Sobre';
	@override String get aboutDescription => 'Versão, dicas do CGFLIX e licenças';
	@override String get updates => 'Atualizações';
	@override String get updateAvailable => 'Atualização disponível';
	@override String get checkForUpdates => 'Procurar atualizações';
	@override String get autoCheckUpdatesOnStartup => 'Procurar atualizações ao abrir o app';
	@override String get autoCheckUpdatesOnStartupDescription => 'Avisar ao abrir o app quando houver uma atualização';
	@override String get validationErrorEnterNumber => 'Digite um número válido';
	@override String validationErrorDuration({required Object min, required Object max, required Object unit}) => 'Use um valor de ${min} a ${max} (${unit})';
	@override String shortcutAlreadyAssigned({required Object action}) => 'Este atalho já é usado em ${action}';
	@override String shortcutUpdated({required Object action}) => 'Atalho atualizado para ${action}';
	@override String get saveFailed => 'Não deu para salvar as alterações. Tente de novo.';
	@override String get autoPlayAndSkip => 'Pular abertura e próximo episódio';
	@override String get autoPlayNextEpisode => 'Próximo episódio sozinho';
	@override String get autoPlayNextEpisodeDescription => 'Começar o próximo episódio quando o atual terminar';
	@override String get shuffleStartsFromBeginning => 'Modo aleatório começa do início';
	@override String get shuffleStartsFromBeginningDescription => 'No modo aleatório, começar cada episódio do início em vez de continuar de onde parou';
	@override String get playNextCountdown => 'Contagem para o próximo episódio';
	@override String get playNextCountdownImmediate => 'Começar na hora';
	@override String get skipIntroMode => 'Pular abertura';
	@override String get skipIntroModeOffDescription => 'a abertura passa normalmente';
	@override String get skipIntroModeButtonDescription => 'o botão aparece quando a abertura começa';
	@override String get skipIntroModeAutoDescription => 'pula sozinho depois da espera abaixo';
	@override String get skipCreditsMode => 'Pular créditos';
	@override String get skipCreditsModeOffDescription => 'os créditos passam normalmente';
	@override String get skipCreditsModeButtonDescription => 'o botão aparece quando os créditos começam';
	@override String get skipCreditsModeAutoDescription => 'pula os créditos e começa o próximo episódio';
	@override String get skipMarkerModeOff => 'Desligado';
	@override String get skipMarkerModeButton => 'Mostrar botão';
	@override String get skipMarkerModeAuto => 'Automático';
	@override String get forceSkipMarkerFallback => 'Sempre detectar abertura pelos capítulos';
	@override String get forceSkipMarkerFallbackDescription => 'Procurar a abertura e os créditos pelo nome dos capítulos, mesmo quando o Plex já tiver essa informação';
	@override String get autoSkipDelay => 'Espera antes de pular';
	@override String autoSkipDelayDescription({required Object seconds}) => 'Esperar ${seconds} segundos antes de pular sozinho';
	@override String get introPattern => 'Nome do capítulo de abertura';
	@override String get introPatternDescription => 'Expressão regular que reconhece a abertura pelo nome do capítulo';
	@override String get creditsPattern => 'Nome do capítulo de créditos';
	@override String get creditsPatternDescription => 'Expressão regular que reconhece os créditos pelo nome do capítulo';
	@override String get invalidRegex => 'Expressão regular inválida';
	@override String get regex => 'Expressão regular';
	@override String get downloads => 'Baixados';
	@override String get downloadLocationDescription => 'Escolha onde guardar o que você baixar';
	@override String get downloadLocationDefault => 'Padrão (memória do app)';
	@override String get downloadLocationCustom => 'Outra pasta';
	@override String get selectFolder => 'Escolher pasta';
	@override String get resetToDefault => 'Voltar ao padrão';
	@override String currentPath({required Object path}) => 'Atual: ${path}';
	@override String get downloadLocationChanged => 'Pasta dos baixados alterada';
	@override String get downloadLocationReset => 'Pasta dos baixados voltou ao padrão';
	@override String get downloadLocationInvalid => 'Não dá para salvar arquivos nessa pasta. Escolha outra.';
	@override String get downloadLocationPickerUnavailable => 'Não dá para escolher pasta neste aparelho';
	@override String get downloadOnWifiOnly => 'Baixar só no Wi-Fi';
	@override String get downloadOnWifiOnlyDescription => 'Não gasta seus dados móveis (4G/5G)';
	@override String get autoRemoveWatchedDownloads => 'Apagar baixados já assistidos';
	@override String get autoRemoveWatchedDownloadsDescription => 'Apagar sozinho os vídeos baixados depois que você assistir';
	@override String get cellularDownloadBlocked => 'Baixar está bloqueado nos dados móveis. Conecte no Wi-Fi ou mude essa opção nas Configurações.';
	@override String get maxVolume => 'Volume máximo';
	@override String get maxVolumeDescription => 'Deixar o volume passar de 100% para vídeos com som baixo';
	@override String maxVolumePercent({required Object percent}) => '${percent}%';
	@override String get discordRichPresence => 'Discord Rich Presence';
	@override String get discordRichPresenceDescription => 'Mostrar o que você está assistindo no Discord';
	@override String get services => 'Serviços';
	@override String get servicesDescription => 'Conecte o Trakt para registrar o que você assiste';
	@override String get manageLibrariesDescription => 'Mudar a ordem e ocultar bibliotecas';
	@override String get companionRemoteServer => 'Servidor de controle remoto';
	@override String get companionRemoteServerDescription => 'Deixar celulares na sua rede Wi-Fi controlarem este app';
	@override String get companionRemoteServerStartFailed => 'Não deu para ligar o controle remoto. Tente de novo.';
	@override String get companionRemoteServerStopFailed => 'Não deu para desligar o controle remoto. Tente de novo.';
	@override String get autoPip => 'Abrir a janelinha ao sair';
	@override String get autoPipDescription => 'Continuar o vídeo numa janelinha ao sair do app durante a reprodução';
	@override String get matchContentFrameRate => 'Ajustar à taxa de quadros do conteúdo';
	@override String get matchContentFrameRateDescription => 'Ajustar a frequência da tela ao vídeo (evita imagem tremida)';
	@override String get matchContentResolution => 'Ajustar à resolução do conteúdo';
	@override String get matchContentResolutionDescription => 'Muda a tela para a resolução original do vídeo, para a TV fazer a ampliação. Menus e legendas também ficam maiores durante a reprodução';
	@override String get matchRefreshRate => 'Ajustar à frequência da tela';
	@override String get matchRefreshRateDescription => 'Ajustar a frequência da tela no modo tela cheia';
	@override String get matchDynamicRange => 'Ajustar à faixa dinâmica';
	@override String get matchDynamicRangeDescription => 'Ligar o HDR da tela em vídeos HDR e depois voltar ao normal (SDR)';
	@override String get displaySwitchDelay => 'Espera ao trocar o modo da tela';
	@override String get tunneledPlayback => 'Reprodução em túnel';
	@override String get tunneledPlaybackDescription => 'Usar o modo túnel de vídeo. Desligue se o vídeo ficar preto em HDR ou se a imagem travar.';
	@override String get audioPassthrough => 'Enviar áudio direto ao receptor';
	@override String get audioPassthroughDescription => 'Mandar o áudio Dolby/DTS sem conversão para o receptor ou a TV, mantendo o som surround. Desligue se ficar sem som.';
	@override String get audioPassthroughDescriptionAppleTv => 'Usar o decodificador Dolby da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam tocando como PCM multicanal. Desligue se ficar sem som.';
	@override String get audioPassthroughOverriddenByNormalization => 'Desligado enquanto o nivelamento de volume estiver ligado';
	@override String get audioChannelLimit => 'Canais de áudio';
	@override String get audioChannelLimitDescription => 'Junta os canais de áudio para caixas de som, fones ou aparelhos HDMI que não tocam todos os canais';
	@override String get audioChannelLimitOriginal => 'Original';
	@override String get audioChannelLimitOriginalDescription => 'Toca todos os canais da faixa';
	@override String get audioChannelLimitSurround51 => 'Até 5.1';
	@override String get audioChannelLimitSurround51Description => 'Junta 7.1 em 5.1 para TVs e receptores que só aceitam PCM 5.1. O envio direto não muda.';
	@override String get audioChannelLimitStereo => 'Som em estéreo';
	@override String get audioChannelLimitStereoDescription => 'Junta os canais de áudio em estéreo, para caixas de som comuns ou fones. Desliga o envio direto.';
	@override String get downmixCenterBoost => 'Reforço das vozes (canal central)';
	@override String downmixCenterBoostValue({required Object db}) => '${db} dB';
	@override String get downmixCenterBoostLabel => 'Reforço (dB)';
	@override String get downmixCenterBoostShort => 'dB';
	@override String get audioDownmixNormalize => 'Nivelar volume no som em estéreo';
	@override String get audioDownmixNormalizeDescription => 'Baixar um pouco o volume ao juntar os canais para não estourar o som. Desligue para manter o volume original, que pode distorcer em cenas muito altas.';
	@override String get dvConversionMode => 'Conversão Dolby Vision';
	@override String get dvConversionModeDescription => 'Escolha como tratar os arquivos Dolby Vision perfil 7.';
	@override String get dvConversionAuto => 'Automático';
	@override String get dvConversionNative => 'Nativo / desligado';
	@override String get dvConversionDv81 => 'P7 → P8.1';
	@override String get dvConversionHevcStrip => 'P7 → HEVC';
	@override String get dvConversionAutoDescription => 'Detectar o que o aparelho suporta e usar o comportamento padrão';
	@override String get dvConversionNativeDescription => 'Forçar DV7 nativo e não tentar converter o Dolby Vision';
	@override String get dvConversionDv81Description => 'Forçar a conversão RPU para Dolby Vision perfil 8.1';
	@override String get dvConversionHevcStripDescription => 'Remover as camadas RPU/EL do Dolby Vision e mostrar HEVC comum, sem Dolby Vision';
	@override String get disableDolbyVision => 'Desligar Dolby Vision';
	@override String get disableDolbyVisionDescription => 'Usar a versão HDR10 ou HLG do arquivo em vez do Dolby Vision, quando houver';
	@override String get hdrSdrConversion => 'Conversão de HDR para SDR';
	@override String get hdrSdrConversionDescription => 'Escolha quem converte vídeos HDR quando a tela não mostra HDR.';
	@override String get hdrSdrConversionAuto => 'Automático';
	@override String get hdrSdrConversionAutoDescription => 'O aparelho no Android 9 ou mais novo; o reprodutor nas versões anteriores';
	@override String get hdrSdrConversionDevice => 'Aparelho';
	@override String get hdrSdrConversionDeviceDescription => 'O chip de vídeo do aparelho converte. Mais rápido, mas as cores variam de aparelho para aparelho';
	@override String get hdrSdrConversionPlayer => 'Reprodutor';
	@override String get hdrSdrConversionPlayerDescription => 'O reprodutor converte. Cores mais fiéis, mas vídeo 4K pode travar em TV boxes mais simples';
	@override String get deinterlace => 'Desentrelaçamento';
	@override String get deinterlaceDescription => 'Tirar as listras (efeito pente) de vídeos antigos entrelaçados (só no reprodutor mpv)';
	@override String get requireProfileSelectionOnOpen => 'Perguntar o perfil ao abrir o app';
	@override String get requireProfileSelectionOnOpenDescription => 'Mostrar a escolha de perfil sempre que abrir o app';
	@override String get forceTvMode => 'Forçar modo TV';
	@override String get forceTvModeDescription => 'Usar o visual de TV em aparelhos que não são reconhecidos como TV. Precisa reiniciar o app.';
	@override String get startInFullscreen => 'Iniciar em tela cheia';
	@override String get startInFullscreenDescription => 'Abrir o CGFLIX em tela cheia';
	@override String get exitFullscreenOnPlayerClose => 'Sair da tela cheia ao fechar o reprodutor';
	@override String get exitFullscreenOnPlayerCloseDescription => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo';
	@override String get autoHidePerformanceOverlay => 'Esconder sozinho o painel de desempenho';
	@override String get autoHidePerformanceOverlayDescription => 'Esconder o painel de desempenho junto com os controles do reprodutor';
	@override String get showNavBarLabels => 'Mostrar nomes na barra de navegação';
	@override String get showNavBarLabelsDescription => 'Mostrar o nome embaixo de cada ícone da barra de navegação';
	@override String get startupSection => 'Tela ao abrir o app';
	@override String get showExploreTab => 'Mostrar aba Explorar';
	@override String get showExploreTabDescription => 'Mostrar a aba Explorar com conteúdo do Plex Discover e dos serviços conectados';
	@override String get liveTvDefaultFavorites => 'Canais favoritos por padrão';
	@override String get liveTvDefaultFavoritesDescription => 'Mostrar só os canais favoritos ao abrir a TV ao vivo';
	@override String get general => 'Geral';
	@override String get generalDescription => 'Modo TV, perfil ao abrir e som de abertura';
	@override String get languageAndRegion => 'Idioma e região';
	@override String get startup => 'Ao abrir o app';
	@override String get display => 'Tela';
	@override String get libraryAndCards => 'Biblioteca e capas';
	@override String get homeScreen => 'Tela inicial';
	@override String get navigation => 'Navegação';
	@override String get window => 'Janela';
	@override String get liveTv => 'TV ao vivo';
	@override String get player => 'Reprodutor';
	@override String get videoAndDisplay => 'Vídeo e tela';
	@override String get audio => 'Áudio';
	@override String get quality => 'Qualidade';
	@override String get subtitles => 'Legendas';
	@override String get seekAndTiming => 'Avançar e voltar';
	@override String get behavior => 'Comportamento';
	@override String get gestures => 'Gestos';
	@override String get gestureBrightnessSwipe => 'Deslizar para mudar o brilho';
	@override String get gestureBrightnessSwipeDescription => 'Deslize para cima ou para baixo no lado esquerdo para mudar o brilho';
	@override String get gestureVolumeSwipe => 'Deslizar para mudar o volume';
	@override String get gestureVolumeSwipeDescription => 'Deslize para cima ou para baixo no lado direito para mudar o volume';
	@override String get gesturePinchToZoom => 'Pinçar para dar zoom';
	@override String get gesturePinchToZoomDescription => 'Use dois dedos no vídeo para ampliar ou reduzir';
	@override String get rememberBrightnessLevel => 'Lembrar o brilho';
	@override String get rememberBrightnessLevelDescription => 'Começar o vídeo com o brilho que você ajustou da última vez';
	@override String get controls => 'Controles';
	@override String get rememberPlayerChanges => 'Lembrar ajustes do reprodutor';
	@override String get rememberPlayerChangesDescription => 'Onde guardar e repetir um ajuste feito durante o vídeo';
	@override String get scopePlaybackSpeed => 'Velocidade de reprodução';
	@override String get scopeShaderPreset => 'Filtro de imagem';
	@override String get scopeAspectRatio => 'Proporção da tela';
	@override String get scopeSyncOffsets => 'Sincronização de áudio e legendas';
	@override String get playerScopeOff => 'Não salvar';
	@override String get playerScopeGlobal => 'Em todos os vídeos';
	@override String get playerScopeLibrary => 'Por biblioteca';
	@override String get playerScopeTitle => 'Por série ou filme';
	@override String get exportDialogTitle => 'Exportar configurações do CGFLIX';
}

// Path: search
class _Translations$search$pt extends Translations$search$en {
	_Translations$search$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hint => 'Buscar filmes, séries, músicas...';
	@override String get tryDifferentTerm => 'Tente buscar com outras palavras';
	@override String get searchYourMedia => 'Buscar no seu servidor';
	@override String get enterTitleActorOrKeyword => 'Digite um título, ator ou palavra-chave';
	@override String get people => 'Pessoas';
}

// Path: hotkeys
class _Translations$hotkeys$pt extends Translations$hotkeys$en {
	_Translations$hotkeys$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String setShortcutFor({required Object actionName}) => 'Definir atalho para ${actionName}';
	@override String get clearShortcut => 'Limpar atalho';
	@override String get noShortcutSet => 'Nenhum atalho definido';
	@override String get currentShortcut => 'Atalho atual:';
	@override String get pressToRecord => 'Selecione para gravar um atalho';
	@override String get recordingShortcut => 'Aperte o atalho agora';
	@override late final _Translations$hotkeys$actions$pt actions = _Translations$hotkeys$actions$pt._(_root);
}

// Path: fileInfo
class _Translations$fileInfo$pt extends Translations$fileInfo$en {
	_Translations$fileInfo$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informações do arquivo';
	@override String get overview => 'Visão geral';
	@override String get video => 'Vídeo';
	@override String get audio => 'Áudio';
	@override String get subtitles => 'Legendas';
	@override String get images => 'Imagens incorporadas';
	@override String get dataStreams => 'Fluxos de dados';
	@override String get lyrics => 'Letras';
	@override String get file => 'Arquivo';
	@override String get attachments => 'Anexos';
	@override String get delivery => 'Entrega';
	@override String versionCounter({required Object index, required Object count}) => 'Versão ${index} de ${count}';
	@override String fileCounter({required Object index, required Object count}) => 'Arquivo ${index} de ${count}';
	@override String get noStreams => 'O servidor não informou as faixas deste arquivo.';
	@override String get copyPath => 'Copiar caminho';
	@override String get pathCopied => 'Caminho do arquivo copiado';
	@override String get codec => 'Codec';
	@override String get codecTag => 'Tag do codec';
	@override String get resolution => 'Resolução';
	@override String get codedResolution => 'Resolução codificada';
	@override String get bitrate => 'Taxa de bits';
	@override String get frameRate => 'Taxa de quadros';
	@override String get rotation => 'Rotação';
	@override String get comment => 'Comentário';
	@override String get audioDescription => 'Descrição de áudio';
	@override String get headerCompression => 'Compactação de cabeçalho';
	@override String get sidecarFile => 'Arquivo separado';
	@override String get transportTimestamp => 'Carimbo de transporte';
	@override String get displayOffset => 'Deslocamento de exibição';
	@override String get previewFailureCode => 'Código de falha da pré-visualização';
	@override String get previewRetries => 'Tentativas da pré-visualização';
	@override String get aspectRatio => 'Proporção';
	@override String get pixelAspectRatio => 'Proporção de aspecto de pixel';
	@override String get profile => 'Perfil';
	@override String get level => 'Nível';
	@override String get bitDepth => 'Profundidade de bits';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get colorSpace => 'Espaço de cor';
	@override String get colorRange => 'Faixa de cor';
	@override String get colorPrimaries => 'Primárias de cor';
	@override String get colorTransfer => 'Transferência de cor';
	@override String get chromaSubsampling => 'Subamostragem de croma';
	@override String get chromaLocation => 'Localização do croma';
	@override String get scanType => 'Tipo de varredura';
	@override String get interlaced => 'Entrelaçado';
	@override String get anamorphic => 'Anamórfico';
	@override String get referenceFrames => 'Quadros de referência';
	@override String get dynamicRange => 'Faixa dinâmica';
	@override String get dolbyVision => 'Dolby Vision';
	@override String get dolbyVisionLevel => 'Nível Dolby Vision';
	@override String get dolbyVisionVersion => 'Versão Dolby Vision';
	@override String get dolbyVisionLayers => 'Camadas Dolby Vision';
	@override String get baseLayerCompatibility => 'Compatibilidade da camada base';
	@override String get avcBitstream => 'Bitstream AVC';
	@override String get nalLengthSize => 'Tamanho do comprimento NAL';
	@override String get scalingMatrix => 'Matriz de dimensionamento personalizada';
	@override String get streamIdentifier => 'Identificador do fluxo';
	@override String get streamIndex => 'Índice do fluxo';
	@override String get streamId => 'ID do fluxo';
	@override String get language => 'Idioma';
	@override String get languageCode => 'Código do idioma';
	@override String get streamTitle => 'Título da faixa';
	@override String get channels => 'Canais';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get spatialAudio => 'Áudio espacial';
	@override String get textBased => 'Baseado em texto';
	@override String get subtitleFormat => 'Formato do arquivo separado';
	@override String get provider => 'Provedor';
	@override String get matchScore => 'Pontuação de correspondência';
	@override String get externalDelivery => 'Pode ser servido separadamente';
	@override String get sidecarPath => 'Caminho do arquivo separado';
	@override String get sourceStream => 'Copiado de';
	@override String get temporary => 'Temporário';
	@override String get timeBase => 'Base de tempo';
	@override String get overallBitrate => 'Taxa de bits total';
	@override String get path => 'Caminho';
	@override String get fileName => 'Nome do arquivo';
	@override String get size => 'Tamanho';
	@override String get totalSize => 'Tamanho total';
	@override String get container => 'Contêiner';
	@override String get duration => 'Duração';
	@override String get previewThumbnails => 'Miniaturas de pré-visualização';
	@override String get previewIndex => 'Índice de pré-visualização';
	@override String get packetLength => 'Tamanho do pacote';
	@override String get filePresent => 'Arquivo presente';
	@override String get fileReadable => 'Legível pelo servidor';
	@override String get streamPath => 'Caminho do fluxo';
	@override String get optimizedForStreaming => 'Otimizado para transmissão';
	@override String get has64bitOffsets => 'Deslocamentos de 64 bits';
	@override String get protocol => 'Protocolo';
	@override String get mediaType => 'Tipo de mídia';
	@override String get sourceKind => 'Tipo de origem';
	@override String get optimizedVersion => 'Versão otimizada';
	@override String get optimizationTarget => 'Alvo de otimização';
	@override String get deletedAt => 'Excluído';
	@override String get remoteSource => 'Origem remota';
	@override String get infiniteStream => 'Fluxo infinito';
	@override String get directPlay => 'Reprodução direta';
	@override String get directStream => 'Fluxo direto';
	@override String get transcoding => 'Transcodificação';
	@override String get etag => 'ETag';
	@override String get versionId => 'ID da versão';
	@override String get fileId => 'ID do arquivo';
	@override String get defaultAudioTrack => 'Faixa de áudio padrão';
	@override String get defaultSubtitleTrack => 'Faixa de legenda padrão';
	@override String get subtitlesOff => 'Desligadas';
	@override String get flagDefault => 'Padrão';
	@override String get flagForced => 'Forçada';
	@override String get flagSelected => 'Selecionada';
	@override String get flagExternal => 'Externa';
	@override String get flagHearingImpaired => 'Para surdos (SDH)';
	@override String get flagDub => 'Dublada';
	@override String get flagOriginal => 'Original';
	@override String get channelsMono => 'Mono';
	@override String dolbyVisionProfile({required Object profile}) => 'Perfil ${profile}';
}

// Path: mediaMenu
class _Translations$mediaMenu$pt extends Translations$mediaMenu$en {
	_Translations$mediaMenu$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
	@override String get removeFromContinueWatching => 'Tirar de Continuar assistindo';
	@override String get viewDetails => 'Ver detalhes';
	@override String get goToSeries => 'Ir para a série';
	@override String get shufflePlay => 'Assistir em ordem aleatória';
	@override String get shuffleNotAvailableOffline => 'A ordem aleatória não funciona sem internet';
	@override String get fileInfo => 'Detalhes técnicos do arquivo';
	@override String get deleteEpisodeFromServer => 'Excluir episódio do servidor';
	@override String get deleteSeasonFromServer => 'Excluir temporada do servidor';
	@override String get deleteShowFromServer => 'Excluir série do servidor';
	@override String get deleteMovieFromServer => 'Excluir filme do servidor';
	@override String get deleteEpisodeTitle => 'Excluir este episódio?';
	@override String get deleteSeasonTitle => 'Excluir esta temporada?';
	@override String get deleteShowTitle => 'Excluir esta série?';
	@override String get deleteMovieTitle => 'Excluir este filme?';
	@override String get deleteEpisodeConfirm => 'Excluir episódio';
	@override String get deleteSeasonConfirm => 'Excluir temporada';
	@override String get deleteShowConfirm => 'Excluir série';
	@override String get deleteMovieConfirm => 'Excluir filme';
	@override String get deleteAnyway => 'Excluir mesmo assim';
	@override String confirmDeleteTarget({required Object title}) => 'Apagar ${title} do seu servidor para sempre?';
	@override String get deleteMultipleWarning => 'Isso inclui todos os episódios e seus arquivos.';
	@override String deleteEpisodeCountWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Isso exclui o ${n} episódio e o arquivo dele.',
		other: 'Isso exclui todos os ${n} episódios e os arquivos deles.',
	);
	@override String deleteMultiPartWarning({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Este item está armazenado como ${n} arquivo, que será excluído.',
		other: 'Este item está armazenado em ${n} arquivos, e todos eles serão excluídos.',
	);
	@override String deleteSharedFileHeading({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Mais ${n} episódio está armazenado no mesmo arquivo e também será excluído:',
		other: 'Mais ${n} episódios estão armazenados no mesmo arquivo e também serão excluídos:',
	);
	@override String get deleteScopeUnverifiedProbeFailed => 'O CGFLIX não conseguiu conferir quais arquivos serão apagados, então pode apagar mais do que o item acima. Cancele e tente de novo, ou exclua mesmo assim.';
	@override String get deleteScopeUnverifiedNoFileInfo => 'O servidor não informou os arquivos deste item, então o CGFLIX não consegue conferir o que será apagado. Pode apagar mais do que o item acima.';
	@override String get mediaDeletedSuccessfully => 'Item excluído';
	@override String get mediaFailedToDelete => 'Não deu para excluir o item. Tente de novo.';
	@override String get rate => 'Avaliar';
	@override String get playFromBeginning => 'Assistir do começo';
	@override String get playVersion => 'Assistir outra versão';
}

// Path: rateSheet
class _Translations$rateSheet$pt extends Translations$rateSheet$en {
	_Translations$rateSheet$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Avaliar';
	@override String get server => 'Servidor';
	@override String get favorite => 'Favorito';
	@override String get favorited => 'Adicionado aos favoritos';
	@override String get saved => 'Salvo';
	@override String get notAvailable => 'Não encontrado neste serviço';
	@override String get noConnectedServices => 'Conecte um serviço nas Configurações para avaliar por ele.';
}

// Path: accessibility
class _Translations$accessibility$pt extends Translations$accessibility$en {
	_Translations$accessibility$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String mediaCardMovie({required Object title}) => '${title}, filme';
	@override String mediaCardShow({required Object title}) => '${title}, série';
	@override String mediaCardEpisode({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}';
	@override String mediaCardSeason({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}';
	@override String get mediaCardWatched => 'assistido';
	@override String mediaCardPartiallyWatched({required Object percent}) => '${percent} por cento assistido';
	@override String get mediaCardUnwatched => 'não assistido';
	@override String get tapToPlay => 'Toque para assistir';
	@override String get decrease => 'Diminuir';
	@override String get increase => 'Aumentar';
	@override String decreaseValue({required Object label}) => 'Diminuir ${label}';
	@override String increaseValue({required Object label}) => 'Aumentar ${label}';
	@override String get hue => 'Matiz';
	@override String get saturation => 'Saturação';
	@override String get brightness => 'Brilho';
	@override String get hexColor => 'Cor hexadecimal';
	@override String get expandText => 'Expandir texto';
	@override String get collapseText => 'Recolher texto';
	@override String get alphabetNavigation => 'Navegação alfabética';
	@override String get alphabetScrollHint => 'Deslize para cima ou para baixo para pular de letra em letra';
	@override String rowColumnPosition({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Linha ${row} de ${rowCount}, coluna ${column} de ${columnCount}';
	@override String rowPosition({required Object row, required Object rowCount}) => 'Linha ${row} de ${rowCount}';
	@override String get autoScrollPlay => 'Iniciar rolagem automática';
	@override String get autoScrollPause => 'Pausar rolagem automática';
	@override String get hueShort => 'M';
	@override String get saturationShort => 'S';
	@override String get valueShort => 'V';
}

// Path: tooltips
class _Translations$tooltips$pt extends Translations$tooltips$en {
	_Translations$tooltips$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get shufflePlay => 'Assistir em ordem aleatória';
	@override String get playTrailer => 'Ver trailer';
	@override String get markAsWatched => 'Marcar como assistido';
	@override String get markAsUnwatched => 'Marcar como não assistido';
}

// Path: audioTracks
class _Translations$audioTracks$pt extends Translations$audioTracks$en {
	_Translations$audioTracks$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String track({required Object n}) => 'Faixa de áudio ${n}';
}

// Path: videoControls
class _Translations$videoControls$pt extends Translations$videoControls$en {
	_Translations$videoControls$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get audioLabel => 'Áudio';
	@override String get subtitlesLabel => 'Legendas';
	@override String addTime({required Object amount, required Object unit}) => '+${amount}${unit}';
	@override String get letterbox => 'Ajustar à tela';
	@override String get fillScreen => 'Preencher a tela';
	@override String get stretch => 'Esticar';
	@override String get lockRotation => 'Travar rotação';
	@override String get unlockRotation => 'Destravar rotação';
	@override String get timerActive => 'Desligamento automático ligado';
	@override String playbackWillPauseIn({required Object duration}) => 'O vídeo vai pausar em ${duration}';
	@override String get sleepTimerEndOfVideo => 'Fim do vídeo atual';
	@override String get sleepTimerStopAtHeader => 'Parar em';
	@override String get sleepTimerDurationHeader => 'Pausar depois de';
	@override String get playbackWillPauseAtEnd => 'O vídeo vai pausar no final';
	@override String get stillWatching => 'Você ainda está assistindo?';
	@override String pausingIn({required Object seconds}) => 'Pausando em ${seconds} s';
	@override String get continueWatching => 'Continuar';
	@override String get autoPlayNext => 'Próximo episódio sozinho';
	@override String get playNext => 'Assistir o próximo';
	@override String get playButton => 'Assistir';
	@override String get pauseButton => 'Pausar';
	@override String get playbackPaused => 'Pausado';
	@override String get playbackResumed => 'Tocando';
	@override String get loadingVideo => 'Carregando vídeo';
	@override String get showPlaybackControls => 'Mostrar os botões';
	@override String get hidePlaybackControls => 'Esconder os botões';
	@override String seekBackwardButton({required Object seconds}) => 'Voltar ${seconds} segundos';
	@override String seekForwardButton({required Object seconds}) => 'Avançar ${seconds} segundos';
	@override String get previousButton => 'Episódio anterior';
	@override String get nextButton => 'Próximo episódio';
	@override String get previousChapterButton => 'Capítulo anterior';
	@override String get nextChapterButton => 'Próximo capítulo';
	@override String get muteButton => 'Silenciar';
	@override String get unmuteButton => 'Ligar o som';
	@override String get settingsButton => 'Ajustes do vídeo';
	@override String get tracksButton => 'Áudio e legendas';
	@override String get chaptersButton => 'Capítulos';
	@override String get versionQualityButton => 'Versão e qualidade';
	@override String get versionColumnHeader => 'Versão';
	@override String get qualityColumnHeader => 'Qualidade';
	@override String get qualityOriginal => 'Original';
	@override String qualityPresetLabel({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps';
	@override String get transcodeUnavailableFallback => 'Não dá para converter este vídeo no servidor — tocando na qualidade original';
	@override String get subtitleUnavailableFallback => 'Não deu para carregar a legenda escolhida — o vídeo vai continuar sem legenda';
	@override String get pipButton => 'Janelinha';
	@override String get aspectRatioButton => 'Proporção';
	@override String get ambientLighting => 'Iluminação ambiente';
	@override String get fullscreenButton => 'Entrar em tela cheia';
	@override String get exitFullscreenButton => 'Sair da tela cheia';
	@override String get alwaysOnTopButton => 'Sempre visível por cima';
	@override String get rotationLockButton => 'Travar rotação';
	@override String get lockScreen => 'Travar tela';
	@override String get screenLockButton => 'Travar tela';
	@override String get longPressToUnlock => 'Toque e segure para destravar';
	@override String get timelineSlider => 'Barra de progresso do vídeo';
	@override String get volumeSlider => 'Volume';
	@override String endsAt({required Object time}) => 'Termina às ${time}';
	@override String get pipActive => 'Tocando na janelinha';
	@override String get pipFailed => 'Não deu para abrir a janelinha';
	@override String get screenshotSaved => 'Foto da tela salva';
	@override String zoomPercent({required Object percent}) => 'Zoom ${percent}%';
	@override String volumePercent({required Object percent}) => 'Volume ${percent}%';
	@override late final _Translations$videoControls$pipErrors$pt pipErrors = _Translations$videoControls$pipErrors$pt._(_root);
	@override String get chapters => 'Capítulos';
	@override String get noChaptersAvailable => 'Nenhum capítulo disponível';
	@override String get queue => 'A seguir';
	@override String get noQueueItems => 'Nada a seguir';
	@override String get noAudioDevicesAvailable => 'Nenhuma saída de áudio disponível';
	@override String get searchSubtitles => 'Buscar legendas';
	@override String get language => 'Idioma';
	@override String get noSubtitlesFound => 'Nenhuma legenda encontrada';
	@override String get subtitleDownloaded => 'Legenda baixada';
	@override String get subtitleDownloadedNotApplied => 'A legenda foi baixada, mas não deu para ativá-la';
	@override String get subtitleDownloadFailed => 'Não deu para baixar a legenda. Tente de novo.';
	@override String get searchLanguages => 'Buscar idiomas...';
	@override String get skipIntro => 'Pular abertura';
	@override String get skipCredits => 'Pular créditos';
	@override String get nextEpisode => 'Próximo episódio';
	@override String subtitleTrack({required Object n}) => 'Faixa ${n}';
	@override String subtitleFile({required Object name}) => 'Legenda ${name}';
	@override String forcedTrack({required Object label}) => '${label} (forçada)';
	@override String get osdSubtitlesOff => 'Legendas: desligadas';
	@override String osdSubtitles({required Object track}) => 'Legendas: ${track}';
	@override String osdAudio({required Object track}) => 'Áudio: ${track}';
}

// Path: messages
class _Translations$messages$pt extends Translations$messages$en {
	_Translations$messages$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get markedAsWatched => 'Marcado como assistido';
	@override String get markedAsUnwatched => 'Marcado como não assistido';
	@override String get markedAsWatchedOffline => 'Marcado como assistido (será atualizado quando voltar a internet)';
	@override String get markedAsUnwatchedOffline => 'Marcado como não assistido (será atualizado quando voltar a internet)';
	@override String autoRemovedWatchedDownload({required Object title}) => 'Apagado automaticamente: ${title}';
	@override String autoRemovedWatchedDownloads({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} baixado já assistido foi apagado automaticamente',
		other: '${n} baixados já assistidos foram apagados automaticamente',
	);
	@override String get removedFromContinueWatching => 'Tirado de Continuar assistindo';
	@override String errorLoading({required Object error}) => 'Não deu para carregar: ${error}';
	@override String get searchPartialResults => 'Não deu para buscar em todos os servidores. Mostrando o que foi encontrado.';
	@override String get streamInterrupted => 'O vídeo foi interrompido. Toque em reproduzir ou avance para tentar de novo.';
	@override String get liveStreamInterrupted => 'A transmissão ao vivo foi interrompida. Toque em reproduzir para tentar de novo.';
	@override String get fileInfoNotAvailable => 'Informações do arquivo indisponíveis';
	@override String get playbackAuthenticationRequired => 'Entre de novo no servidor para assistir este título.';
	@override String get playbackServerUnavailable => 'O servidor está fora do ar. Tente de novo daqui a pouco.';
	@override String get playbackDataInvalid => 'O servidor mandou informações erradas para tocar este vídeo. Tente de novo.';
	@override String get playbackCancelled => 'O vídeo foi cancelado.';
	@override String get playbackFailed => 'Não deu para começar o vídeo. Confira a internet e tente de novo.';
	@override String playbackFailedDetail({required Object error}) => 'Não deu para começar o vídeo (${error}). Confira a internet e tente de novo.';
	@override String get audioOutputFailed => 'O som parou de responder. Confira a conexão de áudio da TV ou do receptor; se outros apps também estiverem sem som, reinicie o aparelho.';
	@override String get mediaUnavailable => 'Este conteúdo não está mais disponível.';
	@override String errorLoadingFileInfo({required Object error}) => 'Não deu para carregar as informações do arquivo: ${error}';
	@override String get errorLoadingSeries => 'Não deu para carregar a série. Tente de novo.';
	@override String get musicNotSupported => 'Ainda não dá para tocar música';
	@override String get noDescriptionAvailable => 'Nenhuma descrição disponível';
	@override String get noProfilesAvailable => 'Nenhum perfil disponível';
	@override String get contactAdminForProfiles => 'Peça ao responsável pelo servidor para criar perfis';
	@override String get unableToDetermineLibrarySection => 'Não deu para saber de qual biblioteca é este item';
	@override String get logsCleared => 'Registros apagados';
	@override String get logsCopied => 'Registros copiados';
	@override String get noLogsAvailable => 'Nenhum registro disponível';
	@override String libraryScanning({required Object title}) => 'Procurando novidades em "${title}"...';
	@override String libraryScanStarted({required Object title}) => 'Começou a busca por novidades em "${title}"';
	@override String libraryScanFailed({required Object error}) => 'Não deu para atualizar a biblioteca: ${error}';
	@override String metadataRefreshing({required Object title}) => 'Atualizando as informações de "${title}"...';
	@override String metadataRefreshStarted({required Object title}) => 'Começou a atualização das informações de "${title}"';
	@override String metadataRefreshFailed({required Object error}) => 'Não deu para atualizar as informações: ${error}';
	@override String get logoutConfirm => 'Quer mesmo sair?';
	@override String get noSeasonsFound => 'Nenhuma temporada encontrada';
	@override String get seasonsLoadFailed => 'Não deu para carregar as temporadas. Tente de novo.';
	@override String get noEpisodesFound => 'Nenhum episódio encontrado na primeira temporada';
	@override String get noEpisodesFoundGeneral => 'Nenhum episódio encontrado';
	@override String get episodesLoadFailed => 'Não deu para carregar os episódios. Tente de novo.';
	@override String get noResultsFound => 'Nenhum resultado encontrado';
	@override String sleepTimerSet({required Object label}) => 'O vídeo vai pausar em ${label}';
	@override String get noItemsAvailable => 'Nenhum item disponível';
	@override String get failedToCreatePlayQueueNoItems => 'Não deu para montar a fila — não há nada para tocar';
	@override String failedPlayback({required Object action, required Object error}) => 'Não deu para ${action}: ${error}';
	@override String get switchingToCompatiblePlayer => 'Trocando para outro reprodutor que funciona com este vídeo...';
	@override String get serverLimitTitle => 'Não deu para tocar agora';
	@override String get serverLimitBody => 'O servidor não deixou tocar este vídeo. O mais comum é o limite de 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho (ou espere um minuto) e tente de novo. Se continuar, avise o Caio.';
	@override String get mediaUnreadableTitle => 'Arquivo indisponível';
	@override String get mediaUnreadableBody => 'O servidor achou este título, mas não conseguiu abrir o arquivo (erro 404). Ele pode ter sido movido ou apagado, ou o disco do servidor está desligado. Avise o responsável pelo servidor.';
	@override String get serverBusyTitle => 'Vídeo indisponível agora';
	@override String get serverBusyBody => 'O servidor não conseguiu enviar este vídeo (erro 503). Ele pode estar reiniciando, ocupado, ou com o disco desligado. Tente de novo daqui a pouco; se continuar, avise o responsável pelo servidor.';
	@override String get playbackNotAllowedTitle => 'Limite de telas ou sem permissão';
	@override String get playbackNotAllowedBody => 'O servidor não deixou tocar este título. Cada conta assiste em até 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho e tente de novo. Se não for isso, sua conta pode não ter acesso a este título.';
	@override String get logsUploaded => 'Registros enviados';
	@override String get logsUploadFailed => 'Não deu para enviar os registros. Confira a internet e tente de novo.';
	@override String get logId => 'Código do registro';
	@override String get burnedSubtitlesUseMenu => 'A legenda está gravada na imagem deste vídeo. Para trocar, use o menu de legendas.';
	@override String get noVideoUrl => 'Não foi encontrado o endereço do vídeo';
	@override String get playbackNoMediaSources => 'O servidor não mandou nenhuma versão deste vídeo que dê para tocar';
	@override String get playbackDataNotPrepared => 'O vídeo começou antes de estar pronto. Tente de novo.';
	@override String get streamSelectionUnavailable => 'Não dá para trocar áudio ou legenda neste vídeo';
	@override String get streamSelectionFailed => 'Não deu para trocar o áudio ou a legenda. Tente de novo.';
	@override String get trackSelectionNotRemembered => 'Esta escolha de áudio ou legenda vale só para este vídeo.';
	@override String get serverUnavailableForProfile => 'Nenhum servidor disponível para este perfil';
}

// Path: subtitlingStyling
class _Translations$subtitlingStyling$pt extends Translations$subtitlingStyling$en {
	_Translations$subtitlingStyling$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get text => 'Texto';
	@override String get border => 'Contorno';
	@override String get background => 'Fundo';
	@override String get fontSize => 'Tamanho';
	@override String get textColor => 'Cor do texto';
	@override String get borderSize => 'Espessura do contorno';
	@override String get borderColor => 'Cor do contorno';
	@override String get backgroundOpacity => 'Fundo atrás do texto';
	@override String get backgroundColor => 'Cor do fundo';
	@override String get position => 'Altura na tela';
	@override String get assOverride => 'Estilo das legendas ASS (anime)';
	@override String get overrideScale => 'Só ajustar o tamanho';
	@override String get overrideForce => 'Forçar o meu estilo';
	@override String get overrideStrip => 'Remover o estilo original';
	@override String get positionTop => 'Em cima';
	@override String get positionBottom => 'Embaixo';
	@override String get useMargins => 'Usar margens';
	@override String get useMarginsDescription => 'Deixar a legenda aparecer fora da área do vídeo. Legendas com estilo próprio podem manter a posição original.';
	@override String get anchorToScreen => 'Prender na tela';
	@override String get anchorToScreenDescription => 'Mostrar a legenda nas faixas pretas abaixo de vídeos em tela larga';
	@override String get bold => 'Negrito';
	@override String get italic => 'Itálico';
	@override String get renderResolution => 'Resolução da legenda';
	@override String get renderResolutionScreen => 'Resolução da tela';
	@override String get renderResolutionVideo => 'Resolução do vídeo';
}

// Path: mpvConfig
class _Translations$mpvConfig$pt extends Translations$mpvConfig$en {
	_Translations$mpvConfig$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'mpv.conf';
	@override String get description => 'Opções avançadas do reprodutor de vídeo (para quem entende)';
	@override String get presets => 'Configurações salvas';
	@override String get noPresets => 'Nenhuma configuração salva';
	@override String get saveAsPreset => 'Salvar configuração...';
	@override String get presetName => 'Nome da configuração';
	@override String get presetNameHint => 'Digite um nome para esta configuração';
	@override String get loadPreset => 'Carregar';
	@override String get deletePreset => 'Excluir';
	@override String get presetSaved => 'Configuração salva';
	@override String get presetLoaded => 'Configuração carregada';
	@override String get presetDeleted => 'Configuração excluída';
	@override String get confirmDeletePreset => 'Quer mesmo excluir esta configuração?';
	@override String get configPlaceholder => 'gpu-api=vulkan\nhwdec=auto\n# comentário';
	@override String get lineHint => 'opção=valor';
	@override String get addLine => 'Adicionar linha';
	@override String get removeLine => 'Remover linha';
	@override String get embeddedVoHint => 'No Linux, vo, gpu-context e gpu-api são ignorados: o vídeo dentro do app sempre usa vo=libmpv, e o gpu-next (necessário para filtros como o ArtCNN) não funciona dentro do app.';
}

// Path: dialog
class _Translations$dialog$pt extends Translations$dialog$en {
	_Translations$dialog$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get confirmAction => 'Confirmar';
}

// Path: profiles
class _Translations$profiles$pt extends Translations$profiles$en {
	_Translations$profiles$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get addPlezyProfile => 'Adicionar perfil CGFLIX';
	@override String get switchingProfile => 'Trocando de perfil…';
	@override String get deleteThisProfileTitle => 'Excluir este perfil?';
	@override String deleteThisProfileMessage({required Object displayName}) => 'Remover ${displayName}. As conexões com os servidores continuam.';
	@override String get active => 'Ativo';
	@override String get manage => 'Gerenciar';
	@override String get delete => 'Excluir';
	@override String get signOut => 'Sair';
	@override String get signOutPlexTitle => 'Sair do Plex?';
	@override String signOutPlexMessage({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar de novo quando quiser.';
	@override String get signOutPlexDeleteDownloads => 'Apagar também os baixados';
	@override String get signOutPlexDeleteDownloadsDescription => 'Se não apagar, eles ficam neste aparelho e voltam quando você entrar de novo nesta conta.';
	@override String get signedOutPlex => 'Saiu do Plex.';
	@override String get signOutFailed => 'Não deu para sair. Tente de novo.';
	@override String get sectionTitle => 'Perfis';
	@override String get summarySingle => 'Crie perfis para separar o que cada pessoa da casa assiste';
	@override String summaryMultipleWithActive({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}';
	@override String summaryMultiple({required Object count}) => '${count} perfis';
	@override String get removeConnectionTitle => 'Remover conexão?';
	@override String removeConnectionMessage({required Object displayName, required Object connectionLabel}) => 'Tirar o acesso de ${displayName} a ${connectionLabel}. Os outros perfis continuam com acesso.';
	@override String get deleteProfileTitle => 'Excluir perfil?';
	@override String deleteProfileMessage({required Object displayName}) => 'Remover ${displayName} e as conexões dele. Os servidores continuam disponíveis.';
	@override String get profileNameLabel => 'Nome do perfil';
	@override String get pinProtectionLabel => 'Proteção por PIN';
	@override String get pinManagedByPlex => 'O PIN é definido pelo Plex. Mude em plex.tv.';
	@override String get noPinSetEditOnPlex => 'Nenhum PIN definido. Para pedir um PIN, edite o usuário do Plex Home em plex.tv.';
	@override String get setPin => 'Definir PIN';
	@override String get setPinTitle => 'Definir PIN';
	@override String get confirmPinTitle => 'Confirmar PIN';
	@override String get pinSet => 'PIN definido';
	@override String get changePin => 'Alterar';
	@override String get removePin => 'Remover';
	@override String get connectionsLabel => 'Conexões';
	@override String get add => 'Adicionar';
	@override String get deleteProfileButton => 'Excluir perfil';
	@override String get noConnectionsHint => 'Sem conexões — adicione um servidor para usar este perfil.';
	@override String get noConnections => 'Sem conexões';
	@override String get plexHomeAccount => 'Conta Plex Home';
	@override String plexAccountChip({required Object account}) => 'Conta Plex: ${account}';
	@override String plexAccountUserChip({required Object user, required Object account}) => '${user} via ${account}';
	@override String get connectionDefault => 'Padrão';
	@override String connectionAs({required Object displayName}) => 'como ${displayName}';
	@override String get makeDefault => 'Definir como padrão';
	@override String get removeConnection => 'Remover';
	@override String get profileRenamed => 'Perfil renomeado.';
	@override String borrowAddTo({required Object displayName}) => 'Adicionar a ${displayName}';
	@override String get borrowExplain => 'Usar a conexão de outro perfil. Perfis com PIN pedem o PIN.';
	@override String get borrowEmpty => 'Nenhuma conexão disponível ainda.';
	@override String get borrowEmptySubtitle => 'Primeiro conecte Plex, Jellyfin ou Emby em outro perfil.';
	@override String get borrowLoadFailed => 'Não deu para carregar as conexões. Tente de novo.';
	@override String borrowFromProfile({required Object displayName}) => 'De ${displayName}';
	@override String get borrowConnectionBorrowed => 'Conexão adicionada ao perfil.';
	@override String get borrowFailed => 'Não deu para adicionar a conexão. Tente de novo.';
	@override String get incorrectPin => 'PIN incorreto.';
	@override String get incorrectPinTryAgain => 'PIN incorreto. Tente de novo.';
	@override String get sourceProfileMissingParentAccount => 'O perfil escolhido não tem a conta principal.';
	@override String get failedToLoadHomeUsers => 'Não deu para carregar os usuários do Plex Home. Confira a internet e tente de novo.';
	@override String get failedToVerifyPin => 'Não deu para conferir o PIN. Tente de novo.';
	@override String get newProfile => 'Novo perfil';
	@override String get profileNameHint => 'Ex.: Visitas, Crianças, Sala';
	@override String get pinProtectionOptional => 'Proteção por PIN (opcional)';
	@override String get pinExplain => 'PIN de 4 números para trocar de perfil.';
	@override String get continueButton => 'Continuar';
	@override String get pinsDontMatch => 'Os PINs não são iguais';
	@override String get tokenIdentityMismatch => 'O acesso deste perfil do Plex veio de um servidor diferente do esperado. Entre de novo.';
}

// Path: connections
class _Translations$connections$pt extends Translations$connections$en {
	_Translations$connections$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Contas e servidores';
	@override String get addConnection => 'Adicionar conexão';
	@override String get addConnectionSubtitleNoProfile => 'Servidor novo: Plex, Jellyfin ou Emby';
	@override String addConnectionSubtitleScoped({required Object displayName}) => 'Servidor novo no perfil ${displayName}: Plex, Jellyfin ou Emby';
	@override String sessionExpiredOne({required Object name}) => 'O acesso a ${name} expirou';
	@override String sessionExpiredMany({required Object count}) => 'O acesso a ${count} servidores expirou';
	@override String accessDeniedOne({required Object name}) => '${name} recusou o acesso desta conta';
	@override String accessDeniedMany({required Object count}) => '${count} servidores recusaram o acesso desta conta';
	@override String get signInAgain => 'Entrar de novo';
	@override String editMediaBrowserTitle({required Object product}) => 'Editar conexão do ${product}';
	@override String editMediaBrowserIntro({required Object serverName}) => 'Adicione ou remova endereços de ${serverName}. O CGFLIX usa o endereço que responder mais rápido.';
}

// Path: accountPreferences
class _Translations$accountPreferences$pt extends Translations$accountPreferences$en {
	_Translations$accountPreferences$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Áudio e legenda';
	@override String hubSubtitleSingle({required Object account}) => 'Idioma do áudio e da legenda da conta ${account}';
	@override String hubSubtitleMultiple({required Object count}) => 'Idioma do áudio e da legenda de ${count} contas';
	@override String get pickAccount => 'Cada conta guarda suas próprias preferências. Escolha qual quer editar.';
	@override String get storedOnAccount => 'Estas opções ficam salvas na sua conta do servidor, então valem em todos os apps conectados a ela — inclusive o CGFLIX nos seus outros aparelhos.';
	@override String get noAccounts => 'Nenhuma conta para configurar';
	@override String get noAccountsHint => 'Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências dessa conta aparecem aqui.';
	@override String get unavailable => 'Não deu para acessar esta conta';
	@override String get loadFailed => 'Não deu para carregar estas preferências. Tente de novo.';
	@override String get noPreference => 'Sem preferência';
	@override String get notSet => 'Não definido';
	@override late final _Translations$accountPreferences$groups$pt groups = _Translations$accountPreferences$groups$pt._(_root);
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get autoSelectAudio => 'Escolher áudio pelo idioma';
	@override String get autoSelectAudioDescription => 'Se desligado, usa o áudio que o arquivo marca como padrão.';
	@override String get preferredSubtitleLanguage => 'Idioma de legenda preferido';
	@override String get subtitleMode => 'Quando mostrar legendas';
	@override late final _Translations$accountPreferences$subtitleModes$pt subtitleModes = _Translations$accountPreferences$subtitleModes$pt._(_root);
	@override String get subtitleAccessibility => 'Legendas para surdos (SDH)';
	@override late final _Translations$accountPreferences$subtitleAccessibilityOptions$pt subtitleAccessibilityOptions = _Translations$accountPreferences$subtitleAccessibilityOptions$pt._(_root);
	@override String get forcedSubtitles => 'Legendas forçadas';
	@override late final _Translations$accountPreferences$forcedSubtitleOptions$pt forcedSubtitleOptions = _Translations$accountPreferences$forcedSubtitleOptions$pt._(_root);
	@override String get displayMissingEpisodes => 'Mostrar episódios que faltam';
	@override String get displayMissingEpisodesDescription => 'Listar episódios que existem, mas ainda não estão no servidor.';
	@override String get hidePlayedInLatest => 'Esconder o que já foi assistido em Recentes';
	@override String get hidePlayedInLatestDescription => 'Não mostrar nas linhas de Recentes o que você já assistiu.';
	@override String get displayCollectionsView => 'Mostrar Coleções';
	@override String get displayCollectionsViewDescription => 'Mostrar as Coleções do servidor junto com as suas bibliotecas.';
	@override String get rewatchingInNextUp => 'Manter em A seguir as séries que você está revendo';
	@override String get rewatchingInNextUpDescription => 'Se você terminar uma série e começar de novo, ela continua em A seguir em vez de sumir.';
	@override String get watchedIndicator => 'Marcar o que já foi assistido';
	@override late final _Translations$accountPreferences$watchedIndicatorOptions$pt watchedIndicatorOptions = _Translations$accountPreferences$watchedIndicatorOptions$pt._(_root);
	@override String get mediaReviewsVisibility => 'Notas e críticas';
	@override late final _Translations$accountPreferences$mediaReviewsOptions$pt mediaReviewsOptions = _Translations$accountPreferences$mediaReviewsOptions$pt._(_root);
}

// Path: discover
class _Translations$discover$pt extends Translations$discover$en {
	_Translations$discover$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descobrir';
	@override String get noContentAvailable => 'Nenhum conteúdo disponível';
	@override String get addMediaToLibraries => 'Adicione filmes e séries às suas bibliotecas';
	@override String get continueWatching => 'Continuar assistindo';
	@override String continueWatchingIn({required Object library}) => 'Continuar assistindo em ${library}';
	@override String get nextUp => 'A seguir';
	@override String nextUpIn({required Object library}) => 'A seguir em ${library}';
	@override String get recentlyAdded => 'Adicionados recentemente';
	@override String recentlyAddedIn({required Object library}) => 'Adicionados recentemente em ${library}';
	@override String latestAlbumsIn({required Object library}) => 'Álbuns mais recentes em ${library}';
	@override String recentlyPlayedIn({required Object library}) => 'Tocados recentemente em ${library}';
	@override String mostPlayedIn({required Object library}) => 'Mais tocados em ${library}';
	@override String playEpisode({required Object season, required Object episode}) => 'S${season}E${episode}';
	@override String get overview => 'Sinopse';
	@override String get cast => 'Elenco';
	@override String get extras => 'Trailers e extras';
	@override String get studio => 'Estúdio';
	@override String get rating => 'Classificação indicativa';
	@override String get director => 'Diretor';
	@override String get directors => 'Diretores';
	@override String get movie => 'Filme';
	@override String get tvShow => 'Série';
	@override String minutesLeft({required Object minutes}) => 'Faltam ${minutes} min';
	@override String get moreLikeThis => 'Mais como este';
	@override String titleCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} título',
		other: '${n} títulos',
	);
}

// Path: errors
class _Translations$errors$pt extends Translations$errors$en {
	_Translations$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String searchFailed({required Object error}) => 'Não deu para buscar: ${error}';
	@override String get searchUnavailable => 'Não deu para buscar: nenhum servidor respondeu. Confira a internet e tente de novo.';
	@override String connectionTimeout({required Object context}) => 'O servidor demorou demais para responder ao carregar ${context}. Tente de novo.';
	@override String get connectionFailed => 'Não deu para falar com o servidor. Confira a internet e tente de novo.';
	@override String unableToLoad({required Object context}) => 'Não deu para carregar ${context}. Tente de novo.';
	@override String get noClientAvailable => 'Nenhum servidor conectado';
	@override String get pleaseEnterToken => 'Digite o código de acesso (token)';
	@override String get invalidToken => 'Código de acesso (token) inválido';
	@override String failedToVerifyToken({required Object error}) => 'Não deu para conferir o código de acesso: ${error}';
	@override String failedToSwitchProfile({required Object displayName}) => 'Não deu para trocar para ${displayName}';
	@override String failedToDeleteProfile({required Object displayName}) => 'Não deu para excluir ${displayName}';
	@override String get failedToRate => 'Não deu para salvar a avaliação. Tente de novo.';
	@override String get reasonTimedOut => 'o servidor demorou demais para responder';
	@override String get reasonUnreachable => 'não deu para falar com o servidor';
	@override String get reasonRefused => 'o servidor recusou o pedido';
	@override String get reasonNotFound => 'o item não está mais no servidor';
	@override String get reasonServerError => 'o servidor teve um problema';
	@override String get reasonCancelled => 'o pedido foi cancelado';
	@override String get reasonUnexpected => 'aconteceu um erro inesperado';
}

// Path: libraries
class _Translations$libraries$pt extends Translations$libraries$en {
	_Translations$libraries$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bibliotecas';
	@override String get fallbackTitle => 'Biblioteca';
	@override String get scanLibraryFiles => 'Procurar arquivos novos';
	@override String get scanLibrary => 'Atualizar biblioteca';
	@override String get analyze => 'Analisar';
	@override String get analyzeLibrary => 'Analisar biblioteca';
	@override String get refreshMetadata => 'Atualizar informações';
	@override String get emptyTrash => 'Esvaziar lixeira';
	@override String emptyingTrash({required Object title}) => 'Esvaziando a lixeira de "${title}"...';
	@override String trashEmptied({required Object title}) => 'Lixeira de "${title}" esvaziada';
	@override String failedToEmptyTrash({required Object error}) => 'Não deu para esvaziar a lixeira: ${error}';
	@override String analyzing({required Object title}) => 'Analisando "${title}"...';
	@override String analysisStarted({required Object title}) => 'Começou a análise de "${title}"';
	@override String failedToAnalyze({required Object error}) => 'Não deu para analisar a biblioteca: ${error}';
	@override String get noLibrariesFound => 'Nenhuma biblioteca encontrada';
	@override String get allLibrariesHidden => 'Todas as bibliotecas estão ocultas';
	@override String hiddenLibrariesCount({required Object count}) => 'Bibliotecas ocultas (${count})';
	@override String get thisLibraryIsEmpty => 'Esta biblioteca está vazia';
	@override String get noItemsMatchFilters => 'Nada encontrado com esses filtros';
	@override String get resetFilters => 'Limpar filtros';
	@override String get all => 'Todos';
	@override String get clearAll => 'Limpar tudo';
	@override String scanLibraryConfirm({required Object title}) => 'Quer mesmo atualizar "${title}"?';
	@override String analyzeLibraryConfirm({required Object title}) => 'Quer mesmo analisar "${title}"?';
	@override String refreshMetadataConfirm({required Object title}) => 'Quer mesmo atualizar as informações de "${title}"?';
	@override String emptyTrashConfirm({required Object title}) => 'Quer mesmo esvaziar a lixeira de "${title}"?';
	@override String get manageLibraries => 'Organizar bibliotecas';
	@override String get sort => 'Ordenar';
	@override String get sortBy => 'Ordenar por';
	@override String get filters => 'Filtros';
	@override String get confirmActionMessage => 'Quer mesmo fazer isso?';
	@override String get showLibrary => 'Mostrar biblioteca';
	@override String get hideLibrary => 'Ocultar biblioteca';
	@override String get libraryOptions => 'Opções da biblioteca';
	@override String get content => 'conteúdo da biblioteca';
	@override String get selectLibrary => 'Escolher biblioteca';
	@override String filtersWithCount({required Object count}) => 'Filtros (${count})';
	@override String get noRecommendations => 'Nenhuma recomendação disponível';
	@override String get noCollections => 'Nenhuma coleção nesta biblioteca';
	@override String get noFoldersFound => 'Nenhuma pasta encontrada';
	@override String get folders => 'pastas';
	@override late final _Translations$libraries$tabs$pt tabs = _Translations$libraries$tabs$pt._(_root);
	@override late final _Translations$libraries$groupings$pt groupings = _Translations$libraries$groupings$pt._(_root);
	@override late final _Translations$libraries$filterCategories$pt filterCategories = _Translations$libraries$filterCategories$pt._(_root);
	@override late final _Translations$libraries$sortLabels$pt sortLabels = _Translations$libraries$sortLabels$pt._(_root);
	@override late final _Translations$libraries$advancedFilters$pt advancedFilters = _Translations$libraries$advancedFilters$pt._(_root);
}

// Path: about
class _Translations$about$pt extends Translations$about$en {
	_Translations$about$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sobre';
	@override String get openSourceLicenses => 'Licenças de código aberto';
	@override String versionLabel({required Object version}) => 'Versão ${version}';
	@override String get appDescription => 'Os filmes e séries da família, em qualquer tela';
	@override String get viewLicensesDescription => 'Ver as licenças de bibliotecas de terceiros';
}

// Path: serverSelection
class _Translations$serverSelection$pt extends Translations$serverSelection$en {
	_Translations$serverSelection$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String noServersFoundForAccount({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})';
	@override String failedToLoadServers({required Object error}) => 'Não deu para carregar os servidores: ${error}';
	@override String get noValidServers => 'Nenhum servidor disponível nesta conta';
}

// Path: hubDetail
class _Translations$hubDetail$pt extends Translations$hubDetail$en {
	_Translations$hubDetail$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get releaseYear => 'Ano de lançamento';
	@override String get dateAdded => 'Data em que foi adicionado';
	@override String get rating => 'Avaliação';
	@override String get noItemsFound => 'Nenhum item encontrado';
}

// Path: logs
class _Translations$logs$pt extends Translations$logs$en {
	_Translations$logs$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get clearLogs => 'Apagar registros';
	@override String get copyLogs => 'Copiar registros';
	@override String get uploadLogs => 'Enviar registros';
}

// Path: startup
class _Translations$startup$pt extends Translations$startup$en {
	_Translations$startup$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get failedTitle => 'O CGFLIX não conseguiu iniciar';
	@override String get failedBody => 'Algo deu errado ao abrir o app. Os detalhes abaixo mostram o que falhou.';
	@override String get failedBodyRepairable => 'O arquivo de configurações do CGFLIX está danificado e precisa ser refeito antes de o app abrir. Tentar de novo não resolve — toque em Reparar dados.';
	@override String get phaseLabel => 'Etapa';
	@override String get showDetails => 'Mostrar detalhes';
	@override String get hideDetails => 'Ocultar detalhes';
	@override String get copyDetails => 'Copiar detalhes';
	@override String get detailsCopied => 'Detalhes copiados';
	@override String get uploadDetails => 'Enviar detalhes';
	@override String get repairStorage => 'Reparar dados';
	@override String get repairTitle => 'Reparar dados salvos?';
	@override String get repairBodyCommon => 'O arquivo de configurações do CGFLIX está danificado e não dá para ler. Reparar volta todas as configurações ao padrão.';
	@override String get repairBodyOneCredential => 'Um acesso salvo está danificado e não dá para ler. Reparar apaga só ele; suas outras configurações continuam.';
	@override String get repairBodySignInsKept => 'Seus servidores e perfis devem continuar conectados.';
	@override String get repairBodySignInsLost => 'Não dá para recuperar a chave que protege seus acessos salvos, então você vai precisar entrar de novo em todos os servidores e perfis. Nada muda no seu servidor.';
	@override String get repairBodySessionsUncertain => 'Os serviços conectados (MAL, AniList, Simkl, Trakt) e o Seerr ficam guardados à parte e podem ou não ser mantidos. O CGFLIX vai dizer exatamente o que ficou.';
	@override String get repairConfirm => 'Reparar';
	@override String get repairSucceeded => 'Dados reparados';
	@override String get repairNeedsRestart => 'Dados reparados — reinicie o app';
	@override String get restartRequiredBody => 'Seus dados foram reparados, mas o CGFLIX precisa ser reiniciado. Feche o CGFLIX e abra de novo.';
	@override String get quitPlezy => 'Sair do CGFLIX';
	@override String get repairFailed => 'Não deu para reparar';
	@override String get repairKeptSignIns => 'Seus servidores e perfis ainda estão conectados.';
	@override String get repairLostSignIns => 'Não deu para recuperar a chave que protege seus acessos salvos. Você vai precisar entrar de novo em todos os servidores e perfis.';
	@override String get repairLostSessions => 'Pelo menos um serviço conectado (ou o Seerr) foi desconectado e precisa ser conectado de novo.';
	@override String get backupTitle => 'Uma cópia do arquivo danificado foi guardada';
	@override String get backupWarning => 'Ela tem seus dados de acesso. Não envie nem compartilhe.';
	@override String get deleteBackup => 'Excluir cópia';
	@override String get backupDeleted => 'Cópia excluída.';
	@override String get previousFailureTitle => 'O CGFLIX não conseguiu abrir da última vez';
}

// Path: licenses
class _Translations$licenses$pt extends Translations$licenses$en {
	_Translations$licenses$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get relatedPackages => 'Pacotes relacionados';
	@override String get license => 'Licença';
	@override String licenseNumber({required Object number}) => 'Licença ${number}';
	@override String licensesCount({required Object count}) => '${count} licenças';
}

// Path: navigation
class _Translations$navigation$pt extends Translations$navigation$en {
	_Translations$navigation$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get libraries => 'Bibliotecas';
	@override String get downloads => 'Baixados';
	@override String get liveTv => 'TV ao vivo';
	@override String get explore => 'Explorar';
}

// Path: explore
class _Translations$explore$pt extends Translations$explore$en {
	_Translations$explore$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Explorar';
	@override String get selectSource => 'Escolher fonte';
	@override late final _Translations$explore$rows$pt rows = _Translations$explore$rows$pt._(_root);
	@override late final _Translations$explore$status$pt status = _Translations$explore$status$pt._(_root);
	@override String episodeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} episódio',
		other: '${n} episódios',
	);
	@override String get cast => 'Elenco';
	@override String get characters => 'Personagens';
	@override String get addToWatchlist => 'Adicionar à lista para assistir';
	@override String get removeFromWatchlist => 'Remover da lista para assistir';
	@override String get addedToWatchlist => 'Adicionado à lista para assistir';
	@override String get removedFromWatchlist => 'Removido da lista para assistir';
	@override String get watchlistUpdateFailed => 'Não deu para atualizar a lista para assistir. Tente de novo.';
	@override String get watchlistNoMatch => 'Não deu para encontrar este título na lista para assistir';
	@override String get notInLibrary => 'Não está na sua biblioteca';
	@override String get inTheseLibraries => 'Nestas bibliotecas';
	@override String get checkingLibrary => 'Procurando na sua biblioteca...';
	@override String libraryCheckFailed({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Não deu para procurar em ${n} servidor',
		other: 'Não deu para procurar em ${n} servidores',
	);
	@override String get emptyTitle => 'Ainda não há nada aqui';
	@override String emptyMessage({required Object source}) => 'As linhas de ${source} vão aparecer aqui quando tiverem conteúdo.';
	@override String searchHint({required Object source}) => 'Buscar em ${source}';
	@override String searchEmpty({required Object query}) => 'Nenhum resultado para "${query}"';
	@override String searchPrompt({required Object source}) => 'Busque filmes e séries em ${source}.';
	@override String get searchFailed => 'Não deu para buscar. Confira a internet e tente de novo.';
	@override late final _Translations$explore$badge$pt badge = _Translations$explore$badge$pt._(_root);
	@override late final _Translations$explore$stats$pt stats = _Translations$explore$stats$pt._(_root);
	@override late final _Translations$explore$season$pt season = _Translations$explore$season$pt._(_root);
	@override late final _Translations$explore$format$pt format = _Translations$explore$format$pt._(_root);
	@override late final _Translations$explore$sourceMaterial$pt sourceMaterial = _Translations$explore$sourceMaterial$pt._(_root);
	@override late final _Translations$explore$creditRole$pt creditRole = _Translations$explore$creditRole$pt._(_root);
	@override late final _Translations$explore$relation$pt relation = _Translations$explore$relation$pt._(_root);
	@override String broadcast({required Object day, required Object time}) => 'Vai ao ar ${day} às ${time}';
	@override String broadcastWithZone({required Object day, required Object time, required Object timezone}) => 'Vai ao ar ${day} às ${time} ${timezone}';
	@override late final _Translations$explore$detail$pt detail = _Translations$explore$detail$pt._(_root);
	@override String totalResults({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} resultado',
		other: '${n} resultados',
	);
}

// Path: liveTv
class _Translations$liveTv$pt extends Translations$liveTv$en {
	_Translations$liveTv$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'TV ao vivo';
	@override String get guide => 'Guia';
	@override String get noChannels => 'Nenhum canal disponível';
	@override String get noDvr => 'Nenhum servidor tem gravador de TV (DVR) configurado';
	@override String get serverUnavailable => 'O servidor de TV ao vivo está fora do ar. Tente de novo daqui a pouco.';
	@override String get serverNotConnected => 'O servidor de TV ao vivo não está conectado.';
	@override String get noPrograms => 'Sem programação disponível';
	@override String get liveStreamFailed => 'Não deu para abrir a transmissão ao vivo. Tente de novo.';
	@override String get unknownProgram => 'Programa desconhecido';
	@override String get unknownHub => 'Desconhecido';
	@override String get unknownError => 'Erro desconhecido';
	@override String channelNumber({required Object number}) => 'Canal ${number}';
	@override String get unknownChannel => 'Canal desconhecido';
	@override String get live => 'AO VIVO';
	@override String get reloadGuide => 'Recarregar guia';
	@override String get searchGuide => 'Buscar no guia';
	@override String get searchHint => 'Buscar canais e programas';
	@override String searchNoResults({required Object query}) => 'Nada encontrado para "${query}"';
	@override String get channelsSection => 'Canais';
	@override String get programsSection => 'Programas';
	@override String get now => 'Agora';
	@override String get today => 'Hoje';
	@override String get tomorrow => 'Amanhã';
	@override String get midnight => 'Meia-noite';
	@override String get overnight => 'Madrugada';
	@override String get morning => 'Manhã';
	@override String get daytime => 'Tarde';
	@override String get evening => 'Noite';
	@override String get lateNight => 'Madrugada';
	@override String get whatsOn => 'O que está passando';
	@override String get watchChannel => 'Assistir ao canal';
	@override String get favorites => 'Favoritos';
	@override String get reorderFavorites => 'Mudar a ordem dos favoritos';
	@override String get noFavoriteChannels => 'Nenhum canal favorito';
	@override String get noFavoriteChannelsHint => 'Mostre todos os canais e toque e segure num canal para adicioná-lo aos favoritos.';
	@override String get showAllChannels => 'Mostrar todos os canais';
	@override String get favoritesLoadFailed => 'Não deu para carregar os favoritos. Confira a internet e tente de novo.';
	@override String get favoritesUpdateFailed => 'Não deu para atualizar os favoritos. Confira a internet e tente de novo.';
	@override String get joinSession => 'Entrar no que está passando';
	@override String watchFromStart({required Object minutes}) => 'Assistir do início (começou há ${minutes} min)';
	@override String get watchLive => 'Assistir ao vivo';
	@override String get goToLive => 'Voltar para o ao vivo';
	@override String get record => 'Gravar';
	@override String get recordEpisode => 'Gravar episódio';
	@override String get recordSeries => 'Gravar série';
	@override String get recordOptions => 'Opções de gravação';
	@override String get saveTo => 'Salvar em';
	@override String get recordings => 'Gravações';
	@override String get scheduledRecordings => 'Agendadas';
	@override String get recordingRules => 'Regras de gravação';
	@override String get noScheduledRecordings => 'Sem gravações agendadas';
	@override String get manageRecording => 'Gerenciar gravação';
	@override String get cancelRecording => 'Cancelar gravação';
	@override String get cancelRecordingTitle => 'Cancelar esta gravação?';
	@override String cancelRecordingMessage({required Object title}) => '${title} não será mais gravado.';
	@override String get deleteRule => 'Excluir regra';
	@override String get deleteRuleTitle => 'Excluir regra de gravação?';
	@override String deleteRuleMessage({required Object title}) => 'Episódios futuros de ${title} não serão gravados.';
	@override String get recordingScheduled => 'Gravação agendada';
	@override String get alreadyScheduled => 'Este programa já está agendado';
	@override String get dvrAdminRequired => 'Só o administrador do servidor pode mudar as gravações';
	@override String get recordingFailed => 'Não deu para agendar a gravação. Tente de novo.';
	@override String get recordingTargetMissing => 'Não deu para saber em qual biblioteca gravar';
	@override String get recordNotAvailable => 'Gravação indisponível para este programa';
	@override String get recordingCancelled => 'Gravação cancelada';
	@override String get recordingRuleDeleted => 'Regra de gravação excluída';
	@override String get processRecordingRules => 'Aplicar regras de novo';
	@override String get recordingInProgress => 'Gravando agora';
	@override String recordingsCount({required Object count}) => '${count} agendadas';
	@override String get editRule => 'Editar regra';
	@override String get editRuleAction => 'Editar';
	@override String get recordingRuleUpdated => 'Regra de gravação atualizada';
	@override String get guideReloadRequested => 'O guia vai ser atualizado';
	@override String get guideReloadFailed => 'Não deu para atualizar o guia. Tente de novo.';
	@override String get rulesProcessRequested => 'As regras vão ser aplicadas de novo';
	@override String get rulesProcessFailed => 'Não deu para aplicar as regras de gravação. Tente de novo.';
	@override String get recordShow => 'Gravar programa';
	@override late final _Translations$liveTv$recordSettings$pt recordSettings = _Translations$liveTv$recordSettings$pt._(_root);
	@override String startingInMinutes({required Object minutes}) => 'Começa em ${minutes} min';
	@override String dayAtTime({required Object day, required Object time}) => '${day} às ${time}';
	@override String invalidPlaybackData({required Object product}) => 'O ${product} mandou informações erradas para a TV ao vivo. Tente de novo.';
	@override String get failedToStartChannel => 'Não deu para abrir o canal ao vivo. Tente de novo.';
	@override String get failedToBuildStreamUrl => 'Não deu para montar o endereço da transmissão';
	@override String playbackStartFailed({required Object reason}) => 'Não deu para abrir o canal: ${reason}';
	@override String channelSwitchFailed({required Object reason}) => 'Não deu para trocar de canal: ${reason}';
}

// Path: collections
class _Translations$collections$pt extends Translations$collections$en {
	_Translations$collections$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Coleções';
	@override String get collection => 'Coleção';
	@override String get empty => 'A coleção está vazia';
	@override String get deleteCollection => 'Excluir coleção';
	@override String deleteConfirm({required Object title}) => 'Excluir "${title}"? Não dá para desfazer.';
	@override String get deleted => 'Coleção excluída';
	@override String get deleteFailed => 'Não deu para excluir a coleção. Tente de novo.';
	@override String deleteFailedWithError({required Object error}) => 'Não deu para excluir a coleção: ${error}';
	@override String get selectCollection => 'Escolher coleção';
	@override String get collectionName => 'Nome da coleção';
	@override String get enterCollectionName => 'Digite o nome da coleção';
	@override String get addedToCollection => 'Adicionado à coleção';
	@override String get errorAddingToCollection => 'Não deu para adicionar à coleção. Tente de novo.';
	@override String get created => 'Coleção criada';
	@override String get removeFromCollection => 'Remover da coleção';
	@override String removeFromCollectionConfirm({required Object title}) => 'Remover "${title}" desta coleção?';
	@override String get removedFromCollection => 'Removido da coleção';
	@override String get removeFromCollectionFailed => 'Não deu para remover da coleção. Tente de novo.';
	@override String removeFromCollectionError({required Object error}) => 'Não deu para remover da coleção: ${error}';
	@override String get searchCollections => 'Buscar coleções...';
}

// Path: playlists
class _Translations$playlists$pt extends Translations$playlists$en {
	_Translations$playlists$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Playlists';
	@override String get playlist => 'Playlist';
	@override String get noPlaylists => 'Nenhuma playlist encontrada';
	@override String get create => 'Criar playlist';
	@override String get playlistName => 'Nome da playlist';
	@override String get enterPlaylistName => 'Digite o nome da playlist';
	@override String get delete => 'Excluir playlist';
	@override String get removeItem => 'Remover da playlist';
	@override String get smartPlaylist => 'Playlist inteligente';
	@override String itemCount({required Object count}) => '${count} itens';
	@override String get oneItem => '1 item';
	@override String get emptyPlaylist => 'Esta playlist está vazia';
	@override String get deleteConfirm => 'Excluir playlist?';
	@override String deleteMessage({required Object name}) => 'Quer mesmo excluir "${name}"?';
	@override String get created => 'Playlist criada';
	@override String get deleted => 'Playlist excluída';
	@override String get itemAdded => 'Adicionado à playlist';
	@override String get itemRemoved => 'Removido da playlist';
	@override String get selectPlaylist => 'Escolher playlist';
	@override String get searchPlaylists => 'Buscar playlists...';
	@override String get errorCreating => 'Não deu para criar a playlist. Tente de novo.';
	@override String get errorDeleting => 'Não deu para excluir a playlist. Tente de novo.';
	@override String get errorLoading => 'Não deu para carregar as playlists. Tente de novo.';
	@override String get errorAdding => 'Não deu para adicionar à playlist. Tente de novo.';
	@override String get errorReordering => 'Não deu para mudar a ordem da playlist. Tente de novo.';
	@override String get errorRemoving => 'Não deu para remover da playlist. Tente de novo.';
}

// Path: music
class _Translations$music$pt extends Translations$music$en {
	_Translations$music$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get goToAlbum => 'Ir para o álbum';
	@override String get goToArtist => 'Ir para o artista';
	@override String get instantMix => 'Mix instantâneo';
	@override String get playNext => 'Tocar em seguida';
	@override String get addToQueue => 'Adicionar à fila';
	@override String discNumber({required Object n}) => 'Disco ${n}';
	@override String trackCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} faixa',
		other: '${n} faixas',
	);
	@override String get nowPlaying => 'Tocando agora';
	@override String playingFrom({required Object title}) => 'Tocando de ${title}';
	@override String get queue => 'Fila';
	@override String get clearQueue => 'Limpar fila';
	@override String get lyrics => 'Letra';
	@override String get noLyrics => 'Sem letra disponível';
	@override String get sleepTimer => 'Desligar automaticamente';
	@override String get sleepTimerEndOfTrack => 'Fim da faixa';
	@override String sleepTimerMinutes({required Object n}) => '${n} minutos';
	@override String get stopPlayback => 'Parar de tocar';
	@override String get previousTrack => 'Faixa anterior';
	@override String get nextTrack => 'Próxima faixa';
	@override String get repeat => 'Repetir';
	@override String get repeatAll => 'Repetir tudo';
	@override String get repeatOne => 'Repetir esta faixa';
	@override String get instantMixNoServer => 'Nenhum servidor disponível para o mix instantâneo';
	@override String get instantMixFailed => 'Não deu para carregar o mix instantâneo. Tente de novo.';
	@override String get instantMixEmpty => 'O mix instantâneo veio sem nenhuma faixa';
	@override String noAudioUrl({required Object track}) => 'Não foi encontrado o endereço do áudio de ${track}';
	@override late final _Translations$music$discography$pt discography = _Translations$music$discography$pt._(_root);
}

// Path: watchTogether
class _Translations$watchTogether$pt extends Translations$watchTogether$en {
	_Translations$watchTogether$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assistir juntos';
	@override String get description => 'Assista ao mesmo tempo com amigos e família, cada um na sua tela';
	@override String get createSession => 'Criar sessão';
	@override String get creating => 'Criando...';
	@override String get joinSession => 'Entrar na sessão';
	@override String get joining => 'Entrando...';
	@override String get controlMode => 'Modo de controle';
	@override String get controlModeQuestion => 'Quem pode pausar e avançar?';
	@override String get hostOnly => 'Só o anfitrião';
	@override String get anyone => 'Qualquer pessoa';
	@override String get hostingSession => 'Você criou uma sessão';
	@override String get inSession => 'Em uma sessão';
	@override String get sessionCode => 'Código da sessão';
	@override String get openSessionControls => 'Abrir os controles do Assistir juntos';
	@override String get copySessionCode => 'Copiar código da sessão';
	@override String get hostControlsPlayback => 'Só o anfitrião pode pausar e avançar';
	@override String get anyoneCanControl => 'Qualquer pessoa pode pausar e avançar';
	@override String get hostControls => 'Anfitrião controla';
	@override String get anyoneControls => 'Todos controlam';
	@override String get participants => 'Participantes';
	@override String get host => 'Anfitrião';
	@override String get hostBadge => 'ANFITRIÃO';
	@override String get youAreHost => 'Você é o anfitrião';
	@override String get makeHost => 'Tornar anfitrião';
	@override String get makeHostQuestion => 'Passar o controle de anfitrião?';
	@override String makeHostConfirm({required Object name}) => '${name} vai controlar o vídeo e conduzir a sessão para todos.';
	@override String get transfer => 'Passar';
	@override String hostChangedTo({required Object name}) => '${name} agora é o anfitrião';
	@override String get youAreNowHost => 'Agora você é o anfitrião';
	@override String hostTransferFailed({required Object name}) => 'Não deu para passar o controle para ${name}';
	@override String get watchingWithOthers => 'Assistindo com outras pessoas';
	@override String get endSession => 'Encerrar sessão';
	@override String get leaveSession => 'Sair da sessão';
	@override String get endSessionQuestion => 'Encerrar sessão?';
	@override String get leaveSessionQuestion => 'Sair da sessão?';
	@override String get endSessionConfirm => 'Isso vai encerrar a sessão para todo mundo.';
	@override String get leaveSessionConfirm => 'Você vai sair da sessão.';
	@override String get endSessionConfirmOverlay => 'Isso vai encerrar o Assistir juntos para todo mundo.';
	@override String get leaveSessionConfirmOverlay => 'Você vai sair do Assistir juntos.';
	@override String get end => 'Encerrar';
	@override String get leave => 'Sair';
	@override String get syncing => 'Sincronizando...';
	@override String get joinWatchSession => 'Entrar na sessão';
	@override String get enterCodeHint => 'Digite o código de 5 letras e números';
	@override String get pasteFromClipboard => 'Colar';
	@override String get pleaseEnterCode => 'Digite o código da sessão';
	@override String get codeMustBe5Chars => 'O código da sessão tem 5 letras e números';
	@override String get joinInstructions => 'Digite o código que o anfitrião passou para entrar.';
	@override String get failedToCreate => 'Não deu para criar a sessão. Confira a internet e tente de novo.';
	@override String get failedToJoin => 'Não deu para entrar na sessão. Confira o código e tente de novo.';
	@override String get sessionCodeCopied => 'Código da sessão copiado';
	@override String get relayUnreachable => 'Não deu para falar com o servidor do Assistir juntos. Sua operadora de internet pode estar bloqueando.';
	@override String get reconnectingToHost => 'Reconectando ao anfitrião...';
	@override String get currentPlayback => 'O que está passando';
	@override String get joinCurrentPlayback => 'Ir para o que está passando';
	@override String get joinCurrentPlaybackDescription => 'Voltar para o que o anfitrião está assistindo agora';
	@override String get failedToOpenCurrentPlayback => 'Não deu para abrir o que está passando. Tente de novo.';
	@override String participantJoined({required Object name}) => '${name} entrou';
	@override String participantLeft({required Object name}) => '${name} saiu';
	@override String participantPaused({required Object name}) => '${name} pausou';
	@override String participantResumed({required Object name}) => '${name} continuou';
	@override String participantSeeked({required Object name}) => '${name} avançou ou voltou o vídeo';
	@override String participantChangedSpeed({required Object name, required Object speed}) => '${name} mudou a velocidade para ${speed}';
	@override String participantBuffering({required Object name}) => '${name} está carregando o vídeo';
	@override String participantNeedsUpdate({required Object name}) => '${name} está com uma versão antiga do app — precisa atualizar para assistirem juntos';
	@override String resumingWithout({required Object name}) => 'Continuando sem ${name}';
	@override String get waitingForParticipants => 'Esperando os outros carregarem o vídeo...';
	@override String waitingForName({required Object name}) => 'Esperando ${name}...';
	@override String get recentRooms => 'Salas recentes';
	@override String get renameRoom => 'Renomear sala';
	@override String get removeRoom => 'Remover';
	@override String get guestSwitchUnavailable => 'Não deu para trocar — o servidor não está disponível';
	@override String get guestSwitchFailed => 'Não deu para trocar — este título não está no seu servidor';
	@override String get defaultDisplayName => 'Usuário';
	@override late final _Translations$watchTogether$errors$pt errors = _Translations$watchTogether$errors$pt._(_root);
}

// Path: downloads
class _Translations$downloads$pt extends Translations$downloads$en {
	_Translations$downloads$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Baixados';
	@override String get manage => 'Organizar';
	@override String get tvShows => 'Séries';
	@override String get movies => 'Filmes';
	@override String get music => 'Música';
	@override String tracksQueued({required Object count}) => '${count} faixas na fila para baixar';
	@override String get noDownloads => 'Nada baixado ainda';
	@override String get noDownloadsDescription => 'O que você baixar aparece aqui para assistir sem internet';
	@override String get downloadNow => 'Baixar';
	@override String get deleteDownload => 'Apagar baixado';
	@override String get retryDownload => 'Tentar baixar de novo';
	@override String get downloadQueued => 'Na fila para baixar';
	@override String get downloadResumed => 'Voltou a baixar';
	@override String get serverErrorBitrate => 'Erro no servidor: o arquivo pode passar do limite de qualidade permitido fora de casa';
	@override String get storageFull => 'Paramos de baixar para não lotar a memória do aparelho. Libere espaço ou escolha outra pasta e tente de novo.';
	@override String get storageUnavailable => 'Paramos de baixar porque não deu para conferir o espaço livre. Confira a pasta dos baixados e tente de novo.';
	@override String episodesQueued({required Object count}) => '${count} episódios na fila para baixar';
	@override String get downloadDeleted => 'Baixado apagado';
	@override String deleteConfirm({required Object title}) => 'Apagar "${title}" deste aparelho?';
	@override String get cancelledDownloadTitle => 'Download cancelado';
	@override String get cancelledDownloadMessage => 'Este download foi cancelado. O que você quer fazer?';
	@override String get allEpisodesAlreadyDownloaded => 'Todos os episódios já foram baixados';
	@override String get resumeDownload => 'Continuar baixando';
	@override String get cancelledDownload => 'Download cancelado';
	@override String syncingFile({required Object file, required Object status}) => '${file} (atualizando ${status})';
	@override String downloadedFileClickToComplete({required Object file}) => '${file} baixado — toque para concluir';
	@override String get partialDownloadClickToComplete => 'Baixado em parte — toque para concluir';
	@override String get deleting => 'Apagando...';
	@override String deletingWithProgress({required Object title, required Object current, required Object total}) => 'Apagando ${title}... (${current} de ${total})';
	@override String get queuedTooltip => 'Na fila';
	@override String queuedFilesTooltip({required Object files}) => 'Na fila: ${files}';
	@override String get downloadingTooltip => 'Baixando...';
	@override String downloadingFilesTooltip({required Object files}) => 'Baixando ${files}';
	@override String get noDownloadsTree => 'Nada baixado';
	@override String get pauseAll => 'Pausar todos';
	@override String get resumeAll => 'Continuar todos';
	@override String get deleteAll => 'Apagar todos';
	@override String get selectVersion => 'Escolher versão';
	@override String get allEpisodes => 'Todos os episódios';
	@override String get unwatchedOnly => 'Só não assistidos';
	@override String nextNUnwatched({required Object count}) => 'Próximos ${count} episódios não assistidos';
	@override String get customAmount => 'Outra quantidade...';
	@override String get includeSpecials => 'Incluir especiais';
	@override String get howManyEpisodes => 'Quantos episódios?';
	@override String get invalidEpisodeCount => 'Digite uma quantidade válida de episódios.';
	@override String get keepSynced => 'Baixar novos sozinho';
	@override String get downloadOnce => 'Baixar uma vez';
	@override String keepNUnwatched({required Object count}) => 'Manter ${count} episódios não assistidos baixados';
	@override String get editSyncRule => 'Editar download automático';
	@override String get removeSyncRule => 'Parar download automático';
	@override String removeSyncRuleConfirm({required Object title}) => 'Parar de baixar "${title}" automaticamente? Os episódios já baixados continuam no aparelho.';
	@override String removeListSyncRuleConfirm({required Object title}) => 'Parar de baixar "${title}" automaticamente?';
	@override String get deleteSyncRuleDownloads => 'Apagar também os baixados desta regra';
	@override String get deleteSyncRuleDownloadsDescription => 'Baixados usados por outra regra ou outro perfil continuam no aparelho.';
	@override String syncRuleCreated({required Object count}) => 'Download automático ligado — mantendo ${count} episódios não assistidos';
	@override String get syncRuleUpdated => 'Download automático atualizado';
	@override String get syncRuleRemoved => 'Download automático desligado';
	@override String get syncRuleAndDownloadsRemoved => 'Download automático desligado e baixados apagados';
	@override String get syncRuleCleanupBusy => 'Os downloads automáticos estão sendo atualizados. Tente de novo daqui a pouco.';
	@override String get syncRuleCleanupUnavailable => 'Não deu para saber com segurança quais baixados são desta regra. Conecte o servidor de novo e tente outra vez, ou desligue a regra sem apagar os baixados.';
	@override String syncedNewEpisodes({required Object count, required Object title}) => '${count} episódios novos de ${title} baixados';
	@override String get activeSyncRules => 'Downloads automáticos';
	@override String get noSyncRules => 'Nenhum download automático';
	@override String get manageSyncRule => 'Ajustar download automático';
	@override String get editEpisodeCount => 'Número de episódios';
	@override String get editSyncFilter => 'O que baixar';
	@override String get syncAllItems => 'Baixando todos os itens';
	@override String get syncUnwatchedItems => 'Baixando os não assistidos';
	@override String syncRuleServerContext({required Object server, required Object status}) => 'Servidor: ${server} • ${status}';
	@override String get syncRuleAvailable => 'Disponível';
	@override String get syncRuleOffline => 'Sem conexão';
	@override String get syncRuleSignInRequired => 'Precisa entrar de novo';
	@override String get syncRuleAccessDenied => 'Acesso negado';
	@override String get syncRuleNotAvailableForProfile => 'Indisponível para este perfil';
	@override String get syncRuleUnknownServer => 'Servidor desconhecido';
	@override String get syncRuleListCreated => 'Download automático ligado';
	@override late final _Translations$downloads$backgroundWarning$pt backgroundWarning = _Translations$downloads$backgroundWarning$pt._(_root);
	@override String get options => 'Opções dos baixados';
	@override late final _Translations$downloads$groupings$pt groupings = _Translations$downloads$groupings$pt._(_root);
	@override String get unknownLibrary => 'Biblioteca desconhecida';
	@override String get unknownShow => 'Série desconhecida';
	@override String get unknownSeason => 'Temporada desconhecida';
	@override String get unknownAlbum => 'Álbum desconhecido';
	@override String completedOfTotal({required Object completed, required Object total}) => '${completed}/${total} concluídos';
	@override String get errorFileNotFound => 'Arquivo não encontrado no servidor (404)';
	@override String get errorDownloadNotAllowed => 'O servidor não permite baixar este item (403)';
	@override String get errorDownloadFailed => 'Não deu para baixar. Confira a internet e tente de novo.';
	@override String errorDownloadFailedWithReason({required Object reason}) => 'Não deu para baixar: ${reason}';
	@override String errorHttpStatus({required Object status}) => 'Não deu para baixar (erro ${status})';
	@override String errorPostProcessing({required Object reason}) => 'Não deu para finalizar o arquivo baixado: ${reason}';
	@override String get reasonFileNotSaved => 'não deu para salvar o arquivo neste aparelho';
	@override String get reasonCannotResume => 'não deu para continuar de onde parou';
	@override String get reasonDeviceStorageFull => 'o aparelho está sem espaço';
	@override String get notificationDownloading => 'Baixando...';
	@override String get notificationComplete => 'Download concluído';
	@override String get notificationPaused => 'Download pausado';
}

// Path: shaders
class _Translations$shaders$pt extends Translations$shaders$en {
	_Translations$shaders$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtros de imagem';
	@override String get noShaderDescription => 'Sem melhoria de imagem';
	@override String get nvscalerDescription => 'Ampliação de imagem da NVIDIA para vídeos mais nítidos';
	@override String get artcnnVariantNeutral => 'Neutro';
	@override String get artcnnVariantDenoise => 'Redução de ruído';
	@override String get artcnnVariantDenoiseSharpen => 'Redução de ruído + nitidez';
	@override String get qualityFast => 'Rápido';
	@override String get qualityHQ => 'Alta qualidade';
	@override String get mode => 'Modo';
	@override String get importShader => 'Importar filtro';
	@override String get customShaderDescription => 'Filtro GLSL personalizado';
	@override String get shaderImported => 'Filtro importado';
	@override String get shaderImportFailed => 'Não deu para importar o filtro. Confira o arquivo e tente de novo.';
	@override String get deleteShader => 'Excluir filtro';
	@override String deleteShaderConfirm({required Object name}) => 'Excluir "${name}"?';
}

// Path: companionRemote
class _Translations$companionRemote$pt extends Translations$companionRemote$en {
	_Translations$companionRemote$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Controle remoto';
	@override String connectedTo({required Object name}) => 'Conectado a ${name}';
	@override String get unknownDevice => 'Aparelho desconhecido';
	@override late final _Translations$companionRemote$session$pt session = _Translations$companionRemote$session$pt._(_root);
	@override late final _Translations$companionRemote$pairing$pt pairing = _Translations$companionRemote$pairing$pt._(_root);
	@override late final _Translations$companionRemote$remote$pt remote = _Translations$companionRemote$remote$pt._(_root);
	@override late final _Translations$companionRemote$errors$pt errors = _Translations$companionRemote$errors$pt._(_root);
	@override String get closedBeforeAuth => 'A conexão caiu antes de confirmar o acesso';
}

// Path: videoSettings
class _Translations$videoSettings$pt extends Translations$videoSettings$en {
	_Translations$videoSettings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playbackSpeed => 'Velocidade';
	@override String get normalSpeed => 'Normal';
	@override String sleepTimerActive({required Object duration}) => 'Ligado (${duration})';
	@override String get zoom => 'Zoom';
	@override String get sleepTimer => 'Desligar automaticamente';
	@override String get audioSync => 'Atraso do áudio';
	@override String get subtitleSync => 'Atraso da legenda';
	@override String get hdr => 'HDR';
	@override String get hdrUnsupported => 'HDR não está disponível aqui — a tela ou o sistema do computador não é compatível.';
	@override String get hdrToneMapping => 'Ajuste de cores HDR';
	@override String get hdrToneMappingCompositor => 'Sistema';
	@override String get hdrToneMappingCompositorDescription => 'Mandar as informações de HDR do vídeo e deixar o sistema do computador ajustar as cores.';
	@override String get hdrToneMappingPlayer => 'Reprodutor';
	@override String get hdrToneMappingPlayerDescription => 'O reprodutor ajusta as cores para o brilho máximo da tela e avisa o sistema.';
	@override String get hdrToneMappingFailed => 'Não deu para mudar o ajuste de cores HDR — continua o modo anterior.';
	@override String get audioOutput => 'Saída de áudio';
	@override String get performanceOverlay => 'Informações técnicas na tela';
	@override String get audioOutputDolbyAtmos => 'Dolby Atmos';
	@override String get audioOutputDolbyAudio => 'Dolby Audio';
	@override String get audioOutputSurround => 'Surround';
	@override String get audioOutputSpatial => 'Áudio espacial';
	@override String get audioOutputStereo => 'Estéreo';
	@override String get audioNormalization => 'Nivelar volume';
	@override String get audioNormalizationDisablesPassthrough => 'Converte o áudio para PCM; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada';
	@override String get audioNormalizationStereoMix => 'Junta os canais de áudio em estéreo; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada';
}

// Path: performanceOverlay
class _Translations$performanceOverlay$pt extends Translations$performanceOverlay$en {
	_Translations$performanceOverlay$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get color => 'Cor';
	@override String get performance => 'Desempenho';
	@override String get buffer => 'Memória de reprodução';
	@override String get app => 'App';
	@override String get decoder => 'Decodificador';
	@override String get rawDecoder => 'Decodificador bruto';
	@override String get tunneling => 'Túnel';
	@override String get passthrough => 'Envio direto';
	@override String get aspect => 'Aspecto';
	@override String get rotation => 'Rotação';
	@override String get dvSource => 'Fonte DV';
	@override String get dvPath => 'Caminho DV';
	@override String get dvRouteDecoder => 'Decodificador Dolby Vision';
	@override String get dvRouteDecoderP81 => 'Decodificador Dolby Vision (P7→8.1)';
	@override String get dvRouteBaseLayer => 'Camada base';
	@override String get dvRouteBaseLayerHdr10 => 'Camada base HDR10';
	@override String get dvRouteBaseLayerHlg => 'Camada base HLG';
	@override String get dvRouteBaseLayerSdr => 'Camada base SDR';
	@override String get dvRouteReshaped => 'RPU remodelada (gpu-next)';
	@override String get p7Conversion => 'Conv. P7';
	@override String get sampleRate => 'Taxa de amostragem';
	@override String get pixelFormat => 'Formato de pixel';
	@override String get hwFormat => 'Formato HW';
	@override String get matrix => 'Matriz';
	@override String get primaries => 'Primárias';
	@override String get transfer => 'Transferência';
	@override String get renderFps => 'FPS de renderização';
	@override String get displayFps => 'FPS da tela';
	@override String get avSync => 'Sincronia A/V';
	@override String get dropped => 'Descartados';
	@override String get dvRpus => 'DV RPUs';
	@override String get dvRpuAverage => 'Média DV RPU';
	@override String get dvSampleAverage => 'Média amostra DV';
	@override String get maxLuma => 'Luma máx.';
	@override String get minLuma => 'Luma mín.';
	@override String get maxCll => 'MaxCLL';
	@override String get maxFall => 'MaxFALL';
	@override String get cacheUsed => 'Memória temporária usada';
	@override String get cacheLimit => 'Limite da memória temporária';
	@override String get speed => 'Velocidade';
	@override String get player => 'Reprodutor';
	@override String get memory => 'Memória';
	@override String get uiFps => 'FPS da interface';
	@override String get fps => 'FPS';
	@override String get decoderAndroidHw => 'Android HW';
	@override String get decoderNvidiaHw => 'NVIDIA HW';
	@override String get decoderQualcommHw => 'Qualcomm HW';
	@override String get decoderMediatekHw => 'MediaTek HW';
	@override String get decoderExynosHw => 'Exynos HW';
	@override String get decoderSoftware => 'Software';
	@override String get decoderHardware => 'Hardware';
	@override String get tunnelingActive => 'Ligado';
	@override String dvRpuFailed({required Object converted, required Object failures}) => '${converted} (${failures} com falha)';
}

// Path: externalPlayer
class _Translations$externalPlayer$pt extends Translations$externalPlayer$en {
	_Translations$externalPlayer$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reprodutor externo';
	@override String get useExternalPlayer => 'Usar reprodutor externo';
	@override String get useExternalPlayerDescription => 'Abrir os vídeos em outro app';
	@override String get selectPlayer => 'Escolher reprodutor';
	@override String get customPlayers => 'Reprodutores personalizados';
	@override String get systemDefault => 'Padrão do sistema';
	@override String get addCustomPlayer => 'Adicionar reprodutor personalizado';
	@override String get playerName => 'Nome do reprodutor';
	@override String get playerNameHint => 'Meu reprodutor';
	@override String get playerCommand => 'Comando';
	@override String get playerPackage => 'Nome do pacote';
	@override String get playerUrlScheme => 'Esquema de endereço (URL)';
	@override String get off => 'Desligado';
	@override String get launchFailed => 'Não deu para abrir o reprodutor externo. Confira se ele está instalado.';
	@override String appNotInstalled({required Object name}) => '${name} não está instalado';
	@override String get playInExternalPlayer => 'Assistir no reprodutor externo';
}

// Path: metadataEdit
class _Translations$metadataEdit$pt extends Translations$metadataEdit$en {
	_Translations$metadataEdit$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get editMetadata => 'Editar...';
	@override String get screenTitle => 'Editar informações';
	@override String get basicInfo => 'Informações básicas';
	@override String get artwork => 'Imagens';
	@override String get advancedSettings => 'Configurações avançadas';
	@override String get title => 'Título';
	@override String get sortTitle => 'Título para ordenar';
	@override String get originalTitle => 'Título original';
	@override String get releaseDate => 'Data de lançamento';
	@override String get contentRating => 'Classificação indicativa';
	@override String get studio => 'Estúdio';
	@override String get tagline => 'Slogan';
	@override String get summary => 'Sinopse';
	@override String get poster => 'Pôster';
	@override String get background => 'Imagem de fundo';
	@override String get logo => 'Logo';
	@override String get squareArt => 'Imagem quadrada';
	@override String get selectPoster => 'Escolher pôster';
	@override String get selectBackground => 'Escolher imagem de fundo';
	@override String get selectLogo => 'Escolher logo';
	@override String get selectSquareArt => 'Escolher imagem quadrada';
	@override String get fromUrl => 'De um endereço (URL)';
	@override String get uploadFile => 'Enviar arquivo';
	@override String get enterImageUrl => 'Digite o endereço da imagem';
	@override String get imageUrl => 'Endereço da imagem';
	@override String get metadataUpdated => 'Informações atualizadas';
	@override String get metadataUpdateFailed => 'Não deu para atualizar as informações. Tente de novo.';
	@override String get artworkUpdated => 'Imagem atualizada';
	@override String get artworkUpdateFailed => 'Não deu para atualizar a imagem. Tente de novo.';
	@override String get noArtworkAvailable => 'Nenhuma imagem disponível';
	@override String artworkOption({required Object index}) => 'Opção de imagem ${index}';
	@override String selectedArtworkOption({required Object index}) => 'Opção de imagem ${index}, selecionada';
	@override String get notSet => 'Não definido';
	@override String get libraryDefault => 'Padrão da biblioteca';
	@override String get accountDefault => 'Padrão da conta';
	@override String get seriesDefault => 'Padrão da série';
	@override String get episodeSorting => 'Ordem dos episódios';
	@override String get oldestFirst => 'Mais antigos primeiro';
	@override String get newestFirst => 'Mais recentes primeiro';
	@override String get keep => 'Manter';
	@override String get allEpisodes => 'Todos os episódios';
	@override String latestEpisodes({required Object count}) => '${count} episódios mais recentes';
	@override String get latestEpisode => 'Episódio mais recente';
	@override String episodesAddedPastDays({required Object count}) => 'Episódios adicionados nos últimos ${count} dias';
	@override String get deleteAfterPlaying => 'Apagar episódios depois de assistir';
	@override String get never => 'Nunca';
	@override String get afterADay => 'Depois de um dia';
	@override String get afterAWeek => 'Depois de uma semana';
	@override String get afterAMonth => 'Depois de um mês';
	@override String get onNextRefresh => 'Na próxima atualização';
	@override String get seasons => 'Temporadas';
	@override String get show => 'Mostrar';
	@override String get hide => 'Ocultar';
	@override String get episodeOrdering => 'Ordem dos episódios';
	@override String get tmdbAiring => 'The Movie Database (exibição)';
	@override String get tvdbAiring => 'TheTVDB (exibição)';
	@override String get tvdbAbsolute => 'TheTVDB (absoluta)';
	@override String get metadataLanguage => 'Idioma das informações';
	@override String get useOriginalTitle => 'Usar título original';
	@override String get preferredAudioLanguage => 'Idioma de áudio preferido';
	@override String get preferredSubtitleLanguage => 'Idioma de legenda preferido';
	@override String get subtitleMode => 'Quando mostrar legendas';
	@override String get manuallySelected => 'Só quando eu escolher';
	@override String get shownWithForeignAudio => 'Quando o áudio for estrangeiro';
	@override String get alwaysEnabled => 'Sempre ligadas';
	@override String get tags => 'Tags';
	@override String get addTag => 'Adicionar tag';
	@override String get genre => 'Gênero';
	@override String get director => 'Diretor';
	@override String get writer => 'Roteirista';
	@override String get producer => 'Produtor';
	@override String get country => 'País';
	@override String get collection => 'Coleção';
	@override String get label => 'Rótulo';
	@override String get quickTag => 'Tag rápida...';
}

// Path: matchScreen
class _Translations$matchScreen$pt extends Translations$matchScreen$en {
	_Translations$matchScreen$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get match => 'Identificar...';
	@override String get fixMatch => 'Corrigir identificação...';
	@override String get unmatch => 'Remover identificação';
	@override String get unmatchConfirm => 'Remover a identificação deste item? O Plex vai tratá-lo como não identificado até você identificar de novo.';
	@override String get unmatchSuccess => 'Identificação removida';
	@override String get unmatchFailed => 'Não deu para remover a identificação. Tente de novo.';
	@override String get matchApplied => 'Identificação aplicada';
	@override String get matchFailed => 'Não deu para aplicar a identificação. Tente de novo.';
	@override String get titleHint => 'Título';
	@override String get yearHint => 'Ano';
	@override String get search => 'Buscar';
	@override String get noMatchesFound => 'Nada encontrado';
}

// Path: serverTasks
class _Translations$serverTasks$pt extends Translations$serverTasks$en {
	_Translations$serverTasks$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas do servidor';
	@override String get failedToLoad => 'Não deu para carregar as tarefas. Tente de novo.';
	@override String get noTasks => 'Nenhuma tarefa em execução';
}

// Path: trakt
class _Translations$trakt$pt extends Translations$trakt$en {
	_Translations$trakt$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trakt';
	@override String get connected => 'Conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get disconnectConfirm => 'Desconectar a conta do Trakt?';
	@override String get disconnectConfirmBody => 'O CGFLIX vai parar de enviar ao Trakt o que você assiste. Você pode conectar de novo quando quiser.';
	@override String get scrobble => 'Marcar como assistido em tempo real';
	@override String get scrobbleDescription => 'Avisa o Trakt quando você começa, pausa ou para um vídeo.';
	@override String get watchedSync => 'Sincronizar o que foi assistido';
	@override String get watchedSyncDescription => 'O que você marcar como assistido no CGFLIX também fica marcado no Trakt.';
}

// Path: seerr
class _Translations$seerr$pt extends Translations$seerr$en {
	_Translations$seerr$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seerr';
	@override String get connectTitle => 'Conectar ao Seerr';
	@override String get serverUrl => 'Endereço do servidor';
	@override String get serverUrlHelper => 'O endereço do seu Seerr';
	@override String get checkServer => 'Continuar';
	@override String get signInWithJellyfin => 'Entrar com Jellyfin';
	@override String get signInWithEmby => 'Entrar com Emby';
	@override String get signInWithLocal => 'Usar uma conta do próprio Seerr';
	@override String get email => 'E-mail';
	@override String get noSignInMethods => 'Este Seerr não tem nenhuma forma de entrar que funcione com o CGFLIX.';
	@override String get instance => 'Servidor';
	@override String get disconnectConfirm => 'Desconectar Seerr?';
	@override String get disconnectConfirmBody => 'O CGFLIX vai esquecer este Seerr. Você pode conectar de novo quando quiser.';
	@override String get request => 'Pedir';
	@override String get request4k => 'Pedir em 4K';
	@override String get seasons => 'Temporadas';
	@override String get allSeasons => 'Todas as temporadas';
	@override String get advancedOptions => 'Opções avançadas';
	@override String get destinationServer => 'Servidor de destino';
	@override String get qualityProfile => 'Perfil de qualidade';
	@override String get rootFolder => 'Pasta raiz';
	@override String get languageProfile => 'Perfil de idioma';
	@override String get tags => 'Etiquetas';
	@override String get noTags => 'Sem etiquetas';
	@override String defaultOption({required Object name}) => '${name} (padrão)';
	@override String get animeNote => 'Esta série é um anime.';
	@override String get requestSubmitted => 'Pedido enviado';
	@override String requestFailed({required Object error}) => 'Não deu para enviar o pedido: ${error}';
	@override String get requestsLoadFailed => 'Não deu para carregar as opções do pedido. Tente de novo.';
	@override String get nothingToRequest => 'Tudo já está disponível ou já foi pedido.';
	@override String get statusAvailable => 'Disponível';
	@override String get statusPartiallyAvailable => 'Parcialmente disponível';
	@override String get statusRequested => 'Pedido';
	@override String get statusProcessing => 'Em preparo';
	@override String get statusBlocklisted => 'Bloqueado';
	@override String couldNotReach({required Object url, required Object error}) => 'Não deu para falar com ${url}: ${error}';
	@override String noInstanceAtUrl({required Object url, required Object status}) => 'Nenhum Seerr encontrado em ${url} (erro ${status})';
	@override String get behindAuthProxy => 'Um sistema de login (SSO ou senha HTTP) respondeu no lugar do Seerr, e o CGFLIX não consegue passar por ele. Peça ao responsável pelo servidor para liberar o caminho /api/v1 do Seerr, ou use um endereço que chegue direto ao Seerr.';
	@override String get invalidUrl => 'Digite um endereço de servidor, por exemplo https://seerr.example.com';
	@override String get quickConnectUnsupported => 'Este Seerr não aceita Quick Connect. Ele precisa do Seerr 3.4 ou mais novo.';
	@override String get notInitialized => 'Este Seerr ainda não terminou a configuração inicial';
	@override String get noPlexTokenForReauth => 'Não há acesso do Plex salvo para entrar de novo';
	@override String get noStoredCredentials => 'Não há dados de acesso salvos para entrar de novo';
	@override String get signInRejected => 'O acesso foi recusado. Confira os dados e tente de novo.';
	@override String get noSessionCookie => 'O Seerr não confirmou o acesso. Tente entrar de novo.';
	@override String get freshCookieRejected => 'O Seerr recusou o novo acesso. Tente entrar de novo.';
	@override String get noUserInformation => 'O Seerr não mandou as informações do usuário';
	@override String get sessionRejectedAfterReauth => 'O acesso foi recusado mesmo depois de entrar de novo';
	@override String get permissionDenied => 'O Seerr não deixou fazer isso: sua conta não tem mais essa permissão';
	@override String get permissionRevoked => 'Você não tem mais permissão para pedir isso';
}

// Path: services
class _Translations$services$pt extends Translations$services$en {
	_Translations$services$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Serviços';
	@override String get hubSubtitle => 'Sincronize o que você assistiu e peça novos títulos.';
	@override String get integrations => 'Integrações';
	@override String get notConnected => 'Não conectado';
	@override String connectedAs({required Object username}) => 'Conectado como @${username}';
	@override String get scrobble => 'Marcar como assistido automaticamente';
	@override String get scrobbleDescription => 'Atualiza sua lista quando você termina um episódio ou filme.';
	@override String disconnectConfirm({required Object service}) => 'Desconectar ${service}?';
	@override String disconnectConfirmBody({required Object service}) => 'O CGFLIX vai parar de atualizar o ${service}. Você pode conectar de novo quando quiser.';
	@override String connectFailed({required Object service}) => 'Não deu para conectar ao ${service}. Confira a internet e tente de novo.';
	@override late final _Translations$services$names$pt names = _Translations$services$names$pt._(_root);
	@override late final _Translations$services$simklReconnect$pt simklReconnect = _Translations$services$simklReconnect$pt._(_root);
	@override late final _Translations$services$deviceCode$pt deviceCode = _Translations$services$deviceCode$pt._(_root);
	@override late final _Translations$services$oauthProxy$pt oauthProxy = _Translations$services$oauthProxy$pt._(_root);
	@override late final _Translations$services$pendingAuth$pt pendingAuth = _Translations$services$pendingAuth$pt._(_root);
	@override late final _Translations$services$libraryFilter$pt libraryFilter = _Translations$services$libraryFilter$pt._(_root);
}

// Path: addServer
class _Translations$addServer$pt extends Translations$addServer$en {
	_Translations$addServer$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String addMediaBrowserTitle({required Object product}) => 'Adicionar servidor ${product}';
	@override String get serverUrls => 'Endereços do servidor';
	@override String get serverUrlsHelper => 'Pode colocar mais de um endereço, separados por vírgula.';
	@override String get findServer => 'Encontrar servidor';
	@override String searchingLocalMediaBrowserServers({required Object product}) => 'Procurando servidores ${product} na sua rede...';
	@override String localMediaBrowserServers({required Object product}) => 'Servidores ${product} na sua rede';
	@override String get username => 'Usuário';
	@override String get password => 'Senha';
	@override String get signIn => 'Entrar';
	@override String get change => 'Trocar';
	@override String get required => 'Obrigatório';
	@override String couldNotReachServer({required Object error}) => 'Não deu para falar com o servidor (${error}). Confira o endereço e a internet.';
	@override String signInFailed({required Object error}) => 'Não deu para entrar (${error}). Confira a internet e tente de novo.';
	@override String quickConnectFailed({required Object error}) => 'Não deu para entrar com o Quick Connect (${error}). Tente de novo.';
	@override String get addPlexTitle => 'Entrar com Plex';
	@override String get pinExpired => 'O código expirou antes de você entrar. Tente de novo.';
	@override String failedToRegisterAccount({required Object error}) => 'Não deu para salvar a conta neste aparelho (${error}). Tente de novo.';
	@override String enterMediaBrowserUrlError({required Object product}) => 'Digite o endereço do seu servidor ${product}';
	@override String get addConnectionTitle => 'Adicionar conexão';
	@override String addConnectionTitleScoped({required Object name}) => 'Adicionar a ${name}';
	@override String get signInWithPlexCard => 'Entrar com Plex';
	@override String get signInWithPlexCardSubtitle => 'Autorize este aparelho. Os servidores compartilhados com você são adicionados.';
	@override String get signInWithPlexCardSubtitleScoped => 'Autorize uma conta Plex. Os usuários do Plex Home viram perfis.';
	@override String connectToMediaBrowserCard({required Object product}) => 'Entrar no ${product}';
	@override String get connectToMediaBrowserCardSubtitle => 'Digite o endereço do servidor, seu usuário e sua senha.';
	@override String connectToMediaBrowserCardSubtitleScoped({required Object product, required Object name}) => 'Entre no seu servidor ${product}. Fica ligado a ${name}.';
	@override String get borrowFromAnotherProfile => 'Usar a conexão de outro perfil';
	@override String get borrowFromAnotherProfileSubtitle => 'Aproveite a conexão de outro perfil. Perfis com PIN pedem o PIN.';
	@override String get invalidCredentials => 'Usuário ou senha incorretos';
	@override String get authResponseNotJson => 'O servidor respondeu algo inesperado ao entrar. Confira o endereço.';
	@override String get authResponseIncomplete => 'O servidor respondeu pela metade ao entrar. Tente de novo.';
	@override String get quickConnectRejected => 'O servidor recusou o Quick Connect';
	@override String get quickConnectNotJson => 'O servidor respondeu algo inesperado no Quick Connect. Tente de novo.';
	@override String get quickConnectMissingFields => 'O servidor não mandou o código do Quick Connect. Tente de novo.';
	@override String get quickConnectPollRejected => 'O servidor recusou o Quick Connect enquanto esperava a aprovação';
	@override String get serverTimedOut => 'O servidor demorou demais para responder. Tente de novo.';
	@override String get responseNotJson => 'O servidor respondeu algo inesperado. Confira o endereço.';
	@override String responseMissingIdentity({required Object product}) => 'A resposta não parece de um servidor ${product}. Confira o endereço.';
	@override String probeFailed({required Object error}) => 'Não deu para falar com o servidor (${error}). Confira o endereço e a internet.';
	@override String enterAtLeastOneUrl({required Object product}) => 'Digite pelo menos um endereço de servidor ${product}';
	@override String noReachableServer({required Object product}) => 'Não deu para encontrar nenhum servidor ${product}. Confira o endereço e a internet.';
	@override String urlsPointToDifferentServers({required Object product}) => 'Esses endereços levam a servidores ${product} diferentes';
	@override String urlDoesNotMatchServer({required Object product}) => 'Este endereço não é deste servidor ${product}';
	@override String get redirectUnsupported => 'O servidor mandou para um endereço que não funciona aqui';
	@override String redirectDifferentHost({required Object product}) => 'O servidor mandou para outro endereço. Digite direto o endereço final do ${product}.';
	@override String get redirectInsecure => 'O servidor mandou de HTTPS para um endereço sem segurança';
	@override String redirectUnsupportedEnterFinal({required Object product}) => 'O servidor mandou para um endereço que não funciona aqui. Digite direto o endereço final do ${product}.';
}

// Path: common.ratingSource
class _Translations$common$ratingSource$pt extends Translations$common$ratingSource$en {
	_Translations$common$ratingSource$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get critic => 'Críticos';
	@override String get audience => 'Público';
	@override String get imdb => 'IMDb';
	@override String get tmdb => 'TMDB';
	@override String get rottenTomatoes => 'Rotten Tomatoes';
	@override String get simkl => 'Simkl';
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get trakt => 'Trakt';
	@override String get rottenTomatoesCritic => 'Críticos do Rotten Tomatoes';
	@override String get rottenTomatoesAudience => 'Público do Rotten Tomatoes';
}

// Path: common.mediaKind
class _Translations$common$mediaKind$pt extends Translations$common$mediaKind$en {
	_Translations$common$mediaKind$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get movie => 'Filme';
	@override String get show => 'Série';
	@override String get season => 'Temporada';
	@override String get episode => 'Episódio';
	@override String get artist => 'Artista';
	@override String get album => 'Álbum';
	@override String get track => 'Faixa';
	@override String get collection => 'Coleção';
	@override String get playlist => 'Playlist';
	@override String get clip => 'Clipe';
	@override String get photo => 'Foto';
	@override String get folder => 'Pasta';
}

// Path: hotkeys.actions
class _Translations$hotkeys$actions$pt extends Translations$hotkeys$actions$en {
	_Translations$hotkeys$actions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get playPause => 'Reproduzir/pausar';
	@override String get volumeUp => 'Aumentar volume';
	@override String get volumeDown => 'Diminuir volume';
	@override String seekForward({required Object seconds}) => 'Avançar ${seconds} s';
	@override String seekBackward({required Object seconds}) => 'Voltar ${seconds} s';
	@override String get fullscreenToggle => 'Tela cheia (ligar/desligar)';
	@override String get muteToggle => 'Silenciar (ligar/desligar)';
	@override String get subtitleToggle => 'Legendas (ligar/desligar)';
	@override String get audioTrackNext => 'Próximo áudio';
	@override String get subtitleTrackNext => 'Próxima legenda';
	@override String get chapterNext => 'Próximo capítulo';
	@override String get chapterPrevious => 'Capítulo anterior';
	@override String get episodeNext => 'Próximo episódio';
	@override String get episodePrevious => 'Episódio anterior';
	@override String get speedIncrease => 'Aumentar velocidade';
	@override String get speedDecrease => 'Diminuir velocidade';
	@override String get speedReset => 'Velocidade normal';
	@override String get zoomIn => 'Aumentar zoom';
	@override String get zoomOut => 'Diminuir zoom';
	@override String get zoomReset => 'Zoom normal';
	@override String get subSeekNext => 'Ir para a próxima fala da legenda';
	@override String get subSeekPrev => 'Ir para a fala anterior da legenda';
	@override String get shaderToggle => 'Filtros de imagem (ligar/desligar)';
	@override String get skipMarker => 'Pular abertura/créditos';
	@override String get screenshot => 'Tirar foto da tela';
}

// Path: videoControls.pipErrors
class _Translations$videoControls$pipErrors$pt extends Translations$videoControls$pipErrors$en {
	_Translations$videoControls$pipErrors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get androidVersion => 'Precisa do Android 8.0 ou mais novo';
	@override String get iosVersion => 'Precisa do iOS 15.0 ou mais novo';
	@override String get permissionDisabled => 'A janelinha (picture-in-picture) está desligada. Ligue nas configurações do aparelho.';
	@override String get notSupported => 'Este aparelho não tem o modo janelinha (picture-in-picture)';
	@override String get voSwitchFailed => 'Não deu para passar o vídeo para a janelinha';
	@override String get failed => 'Não deu para abrir a janelinha';
	@override String get prepareFailed => 'Não deu para preparar a janelinha';
	@override String unknown({required Object error}) => 'Ocorreu um erro: ${error}';
}

// Path: accountPreferences.groups
class _Translations$accountPreferences$groups$pt extends Translations$accountPreferences$groups$en {
	_Translations$accountPreferences$groups$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get audioAndSubtitles => 'Áudio e legendas';
	@override String get libraryDisplay => 'Biblioteca';
	@override String get personalMedia => 'Mídia pessoal';
}

// Path: accountPreferences.subtitleModes
class _Translations$accountPreferences$subtitleModes$pt extends Translations$accountPreferences$subtitleModes$en {
	_Translations$accountPreferences$subtitleModes$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Só quando eu escolher';
	@override String get noneDescription => 'Nunca ligar legendas sozinho.';
	@override String get defaultMode => 'Seguir o que o arquivo indica';
	@override String get defaultModeDescription => 'Usar as marcações de padrão e forçada de cada legenda.';
	@override String get always => 'Sempre ligadas';
	@override String get alwaysDescription => 'Ligar a legenda no idioma preferido sempre que existir.';
	@override String get onlyForced => 'Só legendas forçadas';
	@override String get onlyForcedDescription => 'Ligar só as legendas marcadas como forçadas (trechos em outro idioma).';
	@override String get smart => 'Quando o áudio for estrangeiro';
	@override String get smartDescription => 'Ligar legendas só quando o áudio estiver em outro idioma.';
}

// Path: accountPreferences.subtitleAccessibilityOptions
class _Translations$accountPreferences$subtitleAccessibilityOptions$pt extends Translations$accountPreferences$subtitleAccessibilityOptions$en {
	_Translations$accountPreferences$subtitleAccessibilityOptions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonSdh => 'Preferir legendas não SDH';
	@override String get preferSdh => 'Preferir legendas SDH';
	@override String get onlySdh => 'Só legendas SDH';
	@override String get onlyNonSdh => 'Só legendas não SDH';
}

// Path: accountPreferences.forcedSubtitleOptions
class _Translations$accountPreferences$forcedSubtitleOptions$pt extends Translations$accountPreferences$forcedSubtitleOptions$en {
	_Translations$accountPreferences$forcedSubtitleOptions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get preferNonForced => 'Preferir legendas não forçadas';
	@override String get preferForced => 'Preferir legendas forçadas';
	@override String get onlyForced => 'Só legendas forçadas';
	@override String get onlyNonForced => 'Só legendas não forçadas';
}

// Path: accountPreferences.watchedIndicatorOptions
class _Translations$accountPreferences$watchedIndicatorOptions$pt extends Translations$accountPreferences$watchedIndicatorOptions$en {
	_Translations$accountPreferences$watchedIndicatorOptions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get none => 'Nunca';
	@override String get moviesAndShows => 'Filmes e séries';
	@override String get movies => 'Só filmes';
	@override String get shows => 'Só séries';
}

// Path: accountPreferences.mediaReviewsOptions
class _Translations$accountPreferences$mediaReviewsOptions$pt extends Translations$accountPreferences$mediaReviewsOptions$en {
	_Translations$accountPreferences$mediaReviewsOptions$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get usersAndCritics => 'Público e críticos';
	@override String get usersOnly => 'Só público';
	@override String get criticsOnly => 'Só críticos';
	@override String get nobody => 'Oculto';
}

// Path: libraries.tabs
class _Translations$libraries$tabs$pt extends Translations$libraries$tabs$en {
	_Translations$libraries$tabs$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get recommended => 'Recomendados';
	@override String get browse => 'Ver tudo';
	@override String get collections => 'Coleções';
	@override String get playlists => 'Playlists';
}

// Path: libraries.groupings
class _Translations$libraries$groupings$pt extends Translations$libraries$groupings$en {
	_Translations$libraries$groupings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mostrar';
	@override String get all => 'Todos';
	@override String get movies => 'Filmes';
	@override String get shows => 'Séries';
	@override String get seasons => 'Temporadas';
	@override String get episodes => 'Episódios';
	@override String get artists => 'Artistas';
	@override String get albums => 'Álbuns';
	@override String get tracks => 'Faixas';
	@override String get folders => 'Pastas';
}

// Path: libraries.filterCategories
class _Translations$libraries$filterCategories$pt extends Translations$libraries$filterCategories$en {
	_Translations$libraries$filterCategories$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get genre => 'Gênero';
	@override String get year => 'Ano';
	@override String get contentRating => 'Classificação indicativa';
	@override String get tag => 'Tag';
	@override String get unwatched => 'Não assistidos';
	@override String get unplayed => 'Não tocados';
	@override String get favorites => 'Favoritos';
	@override String get filePath => 'Caminho do arquivo';
}

// Path: libraries.sortLabels
class _Translations$libraries$sortLabels$pt extends Translations$libraries$sortLabels$en {
	_Translations$libraries$sortLabels$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título';
	@override String get dateAdded => 'Data em que foi adicionado';
	@override String get releaseDate => 'Data de lançamento';
	@override String get rating => 'Avaliação';
	@override String get communityRating => 'Avaliação da comunidade';
	@override String get criticRating => 'Avaliação da crítica';
	@override String get userRating => 'Avaliação do usuário';
	@override String get datePlayed => 'Data em que foi assistido';
	@override String get playCount => 'Vezes assistido';
	@override String get productionYear => 'Ano de produção';
	@override String get runtime => 'Duração';
	@override String get officialRating => 'Classificação oficial';
	@override String get premiereDate => 'Data de estreia';
	@override String get startDate => 'Data de início';
	@override String get airTime => 'Horário de exibição';
	@override String get studio => 'Estúdio';
	@override String get random => 'Aleatório';
	@override String get dateShared => 'Data em que foi compartilhado';
	@override String get latestEpisodeAirDate => 'Data do episódio mais recente';
	@override String get lastEpisodeDateAdded => 'Último episódio adicionado';
	@override String get dateDownloaded => 'Data em que foi baixado';
	@override String get size => 'Tamanho';
	@override String get library => 'Biblioteca';
}

// Path: libraries.advancedFilters
class _Translations$libraries$advancedFilters$pt extends Translations$libraries$advancedFilters$en {
	_Translations$libraries$advancedFilters$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get include => 'Incluir';
	@override String get exclude => 'Excluir';
	@override String get any => 'Qualquer';
	@override String get yes => 'Sim';
	@override String get no => 'Não';
	@override String not({required Object value}) => 'Não ${value}';
	@override String valueCount({required Object count}) => '${count} selecionados';
	@override String valueCountExcluded({required Object count}) => '${count} excluídos';
	@override String get searchValues => 'Buscar valores';
	@override String get noValues => 'Nenhum valor';
	@override String get matchContains => 'Contém';
	@override String get matchNotContains => 'Não contém';
	@override String get matchIs => 'É';
	@override String get matchIsNot => 'Não é';
	@override String get matchBeginsWith => 'Começa com';
	@override String get matchEndsWith => 'Termina com';
	@override String get textHint => 'Digite para filtrar';
	@override String get from => 'De';
	@override String get to => 'Até';
	@override String range({required Object from, required Object to}) => '${from} a ${to}';
	@override String atLeast({required Object value}) => '${value} ou mais';
	@override String atMost({required Object value}) => 'Até ${value}';
	@override String dateLastDays({required Object count}) => 'Últimos ${count} dias';
	@override String get dateLastYear => 'Último ano';
	@override String dateOlderThanDays({required Object count}) => 'Há mais de ${count} dias';
	@override String get dateOlderThanYear => 'Há mais de um ano';
}

// Path: explore.rows
class _Translations$explore$rows$pt extends Translations$explore$rows$en {
	_Translations$explore$rows$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get watchlist => 'Lista para assistir';
	@override String get recommendedMovies => 'Filmes recomendados';
	@override String get recommendedShows => 'Séries recomendadas';
	@override String get trendingMovies => 'Filmes em alta';
	@override String get trendingShows => 'Séries em alta';
	@override String get popularMovies => 'Filmes populares';
	@override String get popularShows => 'Séries populares';
	@override String get trendingAnime => 'Animes em alta';
	@override String get suggestedAnime => 'Animes sugeridos';
	@override String get airingAnime => 'Melhores animes em exibição';
	@override String get popularAnime => 'Animes mais populares';
	@override String get trending => 'Em alta';
	@override String get upcomingMovies => 'Filmes que vão estrear';
	@override String get upcomingShows => 'Séries que vão estrear';
}

// Path: explore.status
class _Translations$explore$status$pt extends Translations$explore$status$en {
	_Translations$explore$status$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get airing => 'Em exibição';
	@override String get ended => 'Finalizada';
	@override String get canceled => 'Cancelada';
	@override String get upcoming => 'Em breve';
}

// Path: explore.badge
class _Translations$explore$badge$pt extends Translations$explore$badge$en {
	_Translations$explore$badge$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String rankPopular({required Object n}) => '#${n} em popularidade';
	@override String rankAiring({required Object n}) => '#${n} no ar';
	@override String rankRated({required Object n}) => '#${n} em avaliação';
	@override String rankTrending({required Object n}) => '#${n} em alta';
	@override String rankSeasonal({required Object n, required Object season}) => '#${n} em ${season}';
	@override String watchingNow({required Object n}) => '${n} assistindo';
	@override String get available => 'Disponível';
	@override String get partiallyAvailable => 'Parcialmente disponível';
	@override String get availableIn4k => '4K disponível';
	@override String get requested => 'Pedido';
	@override String get pendingApproval => 'Esperando aprovação';
	@override String get processing => 'Em preparo';
	@override String get declined => 'Recusado';
	@override String get requestFailed => 'Pedido falhou';
	@override String get requested4k => '4K pedido';
	@override String seasonsAvailable({required Object available, required Object total}) => '${available}/${total} temporadas';
	@override String nextEpisodeIn({required Object episode, required Object duration}) => 'Ep ${episode} em ${duration}';
	@override String nextAiringIn({required Object duration}) => 'Próximo em ${duration}';
	@override String episodesShort({required Object n}) => '${n} eps';
	@override String minutesPerEpisode({required Object n}) => '${n} min/ep';
	@override String get adult => '18+';
}

// Path: explore.stats
class _Translations$explore$stats$pt extends Translations$explore$stats$en {
	_Translations$explore$stats$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String listed({required Object n}) => '${n} listados';
	@override String viewersDay({required Object n}) => '${n} assistiram hoje';
	@override String viewersWeek({required Object n}) => '${n} assistiram esta semana';
	@override String viewersMonth({required Object n}) => '${n} assistiram este mês';
	@override String viewersYear({required Object n}) => '${n} assistiram este ano';
	@override String viewersAllTime({required Object n}) => '${n} espectadores';
	@override String planning({required Object n}) => '${n} pretendem assistir';
	@override String favorited({required Object n}) => '${n} favoritaram';
	@override String dropRate({required Object percent}) => '${percent} abandonaram';
	@override String comments({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '${n} comentário',
		other: '${n} comentários',
	);
	@override String votes({required Object n}) => '${n} votos';
	@override String watching({required Object n}) => '${n} assistindo';
	@override String completed({required Object n}) => '${n} concluíram';
	@override String onHold({required Object n}) => '${n} em pausa';
	@override String dropped({required Object n}) => '${n} abandonaram';
}

// Path: explore.season
class _Translations$explore$season$pt extends Translations$explore$season$en {
	_Translations$explore$season$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Inverno';
	@override String get spring => 'Primavera';
	@override String get summer => 'Verão';
	@override String get fall => 'Outono';
	@override String withYear({required Object season, required Object year}) => '${season} ${year}';
}

// Path: explore.format
class _Translations$explore$format$pt extends Translations$explore$format$en {
	_Translations$explore$format$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get tv => 'TV';
	@override String get tvShort => 'Curta para TV';
	@override String get movie => 'Filme';
	@override String get special => 'Especial';
	@override String get ova => 'OVA';
	@override String get ona => 'ONA';
	@override String get music => 'Música';
	@override String get other => 'Outro';
}

// Path: explore.sourceMaterial
class _Translations$explore$sourceMaterial$pt extends Translations$explore$sourceMaterial$en {
	_Translations$explore$sourceMaterial$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get original => 'Original';
	@override String get manga => 'Mangá';
	@override String get lightNovel => 'Light novel';
	@override String get novel => 'Romance';
	@override String get visualNovel => 'Visual novel';
	@override String get game => 'Jogo';
	@override String get webComic => 'Webcomic';
	@override String get musicRelease => 'Música';
	@override String get otherMedia => 'Outro';
}

// Path: explore.creditRole
class _Translations$explore$creditRole$pt extends Translations$explore$creditRole$en {
	_Translations$explore$creditRole$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get actor => 'Ator/Atriz';
	@override String get director => 'Diretor';
	@override String get writer => 'Roteirista';
	@override String get producer => 'Produtor';
	@override String get creator => 'Criador';
	@override String get composer => 'Compositor';
}

// Path: explore.relation
class _Translations$explore$relation$pt extends Translations$explore$relation$en {
	_Translations$explore$relation$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get prequel => 'Antecessor';
	@override String get sequel => 'Continuação';
	@override String get sideStory => 'História paralela';
	@override String get spinOff => 'Spin-off';
	@override String get alternativeVersion => 'Versão alternativa';
	@override String get summary => 'Resumo';
	@override String get parentStory => 'História principal';
	@override String get adaptation => 'Adaptação';
	@override String get other => 'Relacionado';
}

// Path: explore.detail
class _Translations$explore$detail$pt extends Translations$explore$detail$en {
	_Translations$explore$detail$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get originalTitle => 'Título original';
	@override String get alsoKnownAs => 'Também conhecido como';
	@override String get studios => 'Estúdios';
	@override String get country => 'País';
	@override String get language => 'Idioma';
	@override String get released => 'Lançado';
	@override String get physicalRelease => 'Em disco';
	@override String get ended => 'Encerrado';
	@override String addedOn({required Object date}) => 'Adicionado em ${date}';
	@override String get yourRating => 'Sua avaliação';
	@override String get budget => 'Orçamento';
	@override String get revenue => 'Bilheteria';
	@override String get contentAdvisory => 'Classificação indicativa';
	@override String get tags => 'Tags';
	@override String get revealSpoilerTags => 'Mostrar tags com spoiler';
	@override String get links => 'Links';
	@override String get watchOn => 'Assistir em';
	@override String get watchTrailer => 'Ver trailer';
	@override String openOn({required Object site}) => 'Abrir em ${site}';
	@override String get crew => 'Equipe';
	@override String get ratings => 'Avaliações';
	@override String get schedule => 'Programação';
	@override String recommendedByUsers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: 'Recomendado por ${n} usuário',
		other: 'Recomendado por ${n} usuários',
	);
	@override String recommendedBy({required Object who}) => 'Recomendado por ${who}';
	@override String favoritedBy({required Object who}) => 'Favoritado por ${who}';
	@override String unairedEpisodes({required Object n}) => '${n} ainda não exibidos';
	@override String recommendedByPercent({required Object percent}) => 'Recomendado por ${percent} dos espectadores';
	@override String get relatedTitles => 'Títulos relacionados';
	@override String get background => 'Por trás da obra';
}

// Path: liveTv.recordSettings
class _Translations$liveTv$recordSettings$pt extends Translations$liveTv$recordSettings$en {
	_Translations$liveTv$recordSettings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get startEarly => 'Começar antes (segundos)';
	@override String get endLate => 'Terminar depois (segundos)';
	@override String get newOnly => 'Só episódios novos';
	@override String get anyChannel => 'Gravar em qualquer canal';
	@override String get anyTime => 'Gravar a qualquer hora';
	@override String get skipInLibrary => 'Pular episódios que já estão na biblioteca';
	@override String get keepUpTo => 'Quantos episódios guardar';
	@override String get keepUpToHint => '0 guarda todos os episódios';
}

// Path: music.discography
class _Translations$music$discography$pt extends Translations$music$discography$en {
	_Translations$music$discography$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get singlesAndEps => 'Singles e EPs';
	@override String get live => 'Ao vivo';
	@override String get compilations => 'Compilações';
}

// Path: watchTogether.errors
class _Translations$watchTogether$errors$pt extends Translations$watchTogether$errors$en {
	_Translations$watchTogether$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get timedOut => 'O servidor do Assistir juntos demorou demais para responder. Tente de novo.';
	@override String get connectionLost => 'A conexão caiu antes de a sessão ficar pronta. Tente de novo.';
	@override String get invalidRelayResponse => 'O servidor do Assistir juntos respondeu algo inesperado. Tente de novo.';
	@override String get sessionEnded => 'O anfitrião encerrou a sessão';
	@override String get sessionUnavailable => 'Não deu para voltar a esta sessão. Entre em uma sala ou crie uma nova.';
}

// Path: downloads.backgroundWarning
class _Translations$downloads$backgroundWarning$pt extends Translations$downloads$backgroundWarning$en {
	_Translations$downloads$backgroundWarning$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get bannerBlocked => 'Os downloads vão parar quando você sair do app';
	@override String get bannerDegraded => 'Os downloads com o app fechado podem ficar lentos ou parar';
	@override String get bannerAction => 'Detalhes';
	@override String get sheetTitle => 'Os downloads com o app fechado estão bloqueados';
	@override String get sheetTitleDegraded => 'Os downloads com o app fechado podem ficar lentos ou parar';
	@override String get sheetIntro => 'O Android está impedindo o CGFLIX de baixar direito com o app fechado.';
	@override String get sheetIntroDegraded => 'Seu aparelho está limitando quando o CGFLIX pode baixar com o app fechado.';
	@override String get reasonBackgroundRestricted => 'O CGFLIX está com o uso em segundo plano restrito. Mude o uso da bateria (ou uso em segundo plano) para "Sem restrições".';
	@override String get reasonStandbyRestricted => 'O Android colocou o CGFLIX em modo de espera restrito. Mude o uso da bateria para "Sem restrições".';
	@override String get reasonDownloadChannelBlocked => 'As notificações de download estão desligadas, então o progresso e os botões podem não aparecer.';
	@override String get reasonNotificationsDisabled => 'As notificações estão desligadas. No Android 13 ou mais novo, elas são necessárias para baixar com o app fechado.';
	@override String get reasonDataSaver => 'A Economia de dados está ligada e bloqueia downloads com o app fechado nos dados móveis. No Wi-Fi deve funcionar normalmente.';
	@override String get reasonOemUnknown => 'Os downloads pararam várias vezes com o CGFLIX em segundo plano. Confira as configurações de bateria e de uso em segundo plano do CGFLIX.';
	@override String get openSettings => 'Abrir configurações';
	@override String get stillNotWorking => 'Ajuda para o seu aparelho';
	@override String get stillNotWorkingDescription => 'Veja as instruções para o seu aparelho ou, se continuar, envie os registros em Configurações › Ver registros (logs).';
	@override String get dialogTitle => 'Os downloads podem não terminar';
	@override String get dialogDownloadAnyway => 'Baixar mesmo assim';
	@override String get dialogFixFirst => 'Resolver antes';
	@override String get statusTile => 'Baixar com o app fechado';
	@override String get statusOk => 'Permitido baixar com o app fechado';
	@override String get statusBlocked => 'Bloqueado pelas configurações do aparelho';
	@override String get statusDegraded => 'Limitado pelas configurações do aparelho';
	@override String get statusUnknown => 'Ainda não conferido';
	@override String get settingsUnavailable => 'Não deu para abrir as configurações do aparelho';
	@override String get linkUnavailable => 'Não deu para abrir dontkillmyapp.com neste aparelho';
}

// Path: downloads.groupings
class _Translations$downloads$groupings$pt extends Translations$downloads$groupings$en {
	_Translations$downloads$groupings$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get library => 'Biblioteca';
}

// Path: companionRemote.session
class _Translations$companionRemote$session$pt extends Translations$companionRemote$session$en {
	_Translations$companionRemote$session$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get startingServer => 'Ligando o controle remoto...';
	@override String get hostAddress => 'Endereço deste aparelho';
	@override String get connected => 'Conectado';
	@override String get serverRunning => 'Controle remoto ligado';
	@override String get serverStopped => 'Controle remoto desligado';
	@override String get serverRunningDescription => 'Celulares na sua rede Wi-Fi podem se conectar a este app';
	@override String get serverStoppedDescription => 'Ligue o controle remoto para que celulares possam se conectar';
	@override String get usePhoneToControl => 'Use seu celular para controlar este app';
	@override String get startServer => 'Ligar';
	@override String get stopServer => 'Desligar';
	@override String get minimize => 'Minimizar';
	@override String get manualAddressHint => 'Endereço para conectar manualmente:';
}

// Path: companionRemote.pairing
class _Translations$companionRemote$pairing$pt extends Translations$companionRemote$pairing$en {
	_Translations$companionRemote$pairing$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get discoveryDescription => 'Aparelhos com o CGFLIX na mesma conta Plex aparecem aqui';
	@override String get hostAddressHint => '192.168.1.100:48632';
	@override String get connecting => 'Conectando...';
	@override String get searchingForDevices => 'Procurando aparelhos...';
	@override String get noDevicesFound => 'Nenhum aparelho encontrado na sua rede';
	@override String get noDevicesHint => 'Abra o CGFLIX no computador e use a mesma rede Wi-Fi';
	@override String get availableDevices => 'Aparelhos disponíveis';
	@override String get manualConnection => 'Conectar manualmente';
	@override String get cryptoInitFailed => 'Não deu para iniciar a conexão segura. Entre no Plex primeiro.';
	@override String get validationHostRequired => 'Digite o endereço do aparelho';
	@override String get validationHostFormat => 'Use o formato IP:porta (ex.: 192.168.1.100:48632)';
	@override String get connectionTimedOut => 'O outro aparelho demorou demais para responder. Use a mesma rede Wi-Fi nos dois.';
	@override String get sessionNotFound => 'Aparelho não encontrado. Confira se o CGFLIX está aberto nele.';
	@override String get authFailed => 'Não deu para conectar. Os dois aparelhos precisam estar na mesma conta Plex.';
	@override String failedToConnect({required Object error}) => 'Não deu para conectar: ${error}';
}

// Path: companionRemote.remote
class _Translations$companionRemote$remote$pt extends Translations$companionRemote$remote$en {
	_Translations$companionRemote$remote$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get disconnectConfirm => 'Quer desconectar do controle remoto?';
	@override String get reconnecting => 'Reconectando...';
	@override String attemptOf({required Object current}) => 'Tentativa ${current} de 5';
	@override String get retryNow => 'Tentar agora';
	@override String get tabRemote => 'Controle';
	@override String get tabPlay => 'Assistir';
	@override String get tabMore => 'Mais';
	@override String get menu => 'Menu';
	@override String get tabNavigation => 'Abas';
	@override String get tabDiscover => 'Descobrir';
	@override String get tabLibraries => 'Bibliotecas';
	@override String get tabSearch => 'Buscar';
	@override String get tabDownloads => 'Baixados';
	@override String get tabSettings => 'Configurações';
	@override String get previous => 'Anterior';
	@override String get playPause => 'Reproduzir/pausar';
	@override String get next => 'Próximo';
	@override String get seekBack => 'Voltar';
	@override String get stop => 'Parar';
	@override String get seekForward => 'Avançar';
	@override String get volume => 'Volume';
	@override String get volumeDown => 'Diminuir';
	@override String get volumeUp => 'Aumentar';
	@override String get fullscreen => 'Tela cheia';
	@override String get subtitles => 'Legendas';
	@override String get audio => 'Áudio';
	@override String get searchHint => 'Buscar no computador...';
}

// Path: companionRemote.errors
class _Translations$companionRemote$errors$pt extends Translations$companionRemote$errors$en {
	_Translations$companionRemote$errors$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get noNetworkInterface => 'Nenhuma conexão de rede encontrada. Confira o Wi-Fi.';
	@override String get authenticationFailed => 'Não deu para confirmar o acesso';
	@override String serverStartFailed({required Object error}) => 'Não deu para ligar o controle remoto: ${error}';
	@override String commandFailed({required Object error}) => 'Não deu para enviar o comando: ${error}';
	@override String get joinTimedOut => 'Demorou demais para conectar. Tente de novo.';
	@override String get failedToConnectAnyAddress => 'Não deu para conectar em nenhum endereço';
	@override String connectionLostAfterAttempts({required Object attempts}) => 'A conexão caiu depois de ${attempts} tentativas';
	@override String get connectionLost => 'A conexão caiu';
}

// Path: services.names
class _Translations$services$names$pt extends Translations$services$names$en {
	_Translations$services$names$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get mal => 'MyAnimeList';
	@override String get anilist => 'AniList';
	@override String get simkl => 'Simkl';
	@override String get seerr => 'Seerr';
	@override String get mdblist => 'MDBList';
}

// Path: services.simklReconnect
class _Translations$services$simklReconnect$pt extends Translations$services$simklReconnect$en {
	_Translations$services$simklReconnect$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reconectar o Simkl';
	@override String get subtitle => 'O Simkl vai desativar o tipo de login desta conexão. Reconectar abre o simkl.com para você autorizar o CGFLIX — o CGFLIX nunca vê a sua senha. Seu histórico continua no Simkl.';
}

// Path: services.deviceCode
class _Translations$services$deviceCode$pt extends Translations$services$deviceCode$en {
	_Translations$services$deviceCode$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Ativar o CGFLIX no ${service}';
	@override String get instructions => 'Leia o código QR ou abra o endereço abaixo e digite este código:';
	@override String openToActivate({required Object service}) => 'Abrir ${service} para ativar';
	@override String get copyCode => 'Copiar código de ativação';
	@override String get waitingForAuthorization => 'Esperando a autorização…';
	@override String get codeCopied => 'Código copiado';
}

// Path: services.oauthProxy
class _Translations$services$oauthProxy$pt extends Translations$services$oauthProxy$en {
	_Translations$services$oauthProxy$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String title({required Object service}) => 'Entrar no ${service}';
	@override String get body => 'Leia este código QR ou abra o endereço em qualquer aparelho.';
	@override String openToSignIn({required Object service}) => 'Abrir ${service} para entrar';
}

// Path: services.pendingAuth
class _Translations$services$pendingAuth$pt extends Translations$services$pendingAuth$en {
	_Translations$services$pendingAuth$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get copyUrl => 'Copiar endereço de acesso';
	@override String get urlCopied => 'Endereço copiado';
}

// Path: services.libraryFilter
class _Translations$services$libraryFilter$pt extends Translations$services$libraryFilter$en {
	_Translations$services$libraryFilter$pt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtro de bibliotecas';
	@override String get subtitleAllSyncing => 'Sincronizando todas as bibliotecas';
	@override String get subtitleNoneSyncing => 'Nada a sincronizar';
	@override String subtitleBlocked({required Object count}) => '${count} bloqueadas';
	@override String subtitleAllowed({required Object count}) => '${count} permitidas';
	@override String get mode => 'Modo de filtro';
	@override String get modeBlacklist => 'Lista de bloqueio';
	@override String get modeWhitelist => 'Lista de permissões';
	@override String get modeHintBlacklist => 'Sincronizar todas as bibliotecas, exceto as marcadas abaixo.';
	@override String get modeHintWhitelist => 'Sincronizar só as bibliotecas marcadas abaixo.';
	@override String get libraries => 'Bibliotecas';
	@override String get noLibraries => 'Nenhuma biblioteca disponível';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'CGFLIX',
			'auth.signInWithPlex' => 'Entrar com Plex',
			'auth.showQRCode' => 'Mostrar código QR',
			'auth.authenticate' => 'Confirmar acesso',
			'auth.authenticationTimeout' => 'O tempo para entrar acabou. Tente de novo.',
			'auth.scanQRToSignIn' => 'Leia este código QR para entrar',
			'auth.waitingForAuth' => 'Esperando você entrar...\nConclua o acesso no navegador.',
			'auth.useBrowser' => 'Usar navegador',
			'auth.or' => 'ou',
			'auth.connectToMediaBrowser' => ({required Object product}) => 'Entrar no ${product}',
			'auth.quickConnect' => 'Quick Connect',
			'auth.useQuickConnect' => 'Usar Quick Connect',
			'auth.quickConnectInstructions' => 'Abra o Quick Connect no Jellyfin (em outro aparelho já conectado) e digite este código.',
			'auth.quickConnectWaiting' => 'Esperando a aprovação…',
			'auth.quickConnectCancel' => 'Cancelar',
			'auth.quickConnectExpired' => 'O código do Quick Connect expirou. Tente de novo.',
			'auth.localDataRecoveryRequired' => 'O CGFLIX não conseguiu recuperar com segurança seus dados de acesso e o que você assistiu sem internet. Entre de novo.',
			'auth.pinCheckRejected' => 'O Plex recusou o código de acesso. Tente de novo.',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
			'common.clear' => 'Limpar',
			'common.reset' => 'Redefinir',
			'common.later' => 'Depois',
			'common.submit' => 'Enviar',
			'common.confirm' => 'Confirmar',
			'common.retry' => 'Tentar de novo',
			'common.logout' => 'Sair',
			'common.unknown' => 'Desconhecido',
			'common.refresh' => 'Atualizar',
			'common.yes' => 'Sim',
			'common.no' => 'Não',
			'common.delete' => 'Excluir',
			'common.edit' => 'Editar',
			'common.shuffle' => 'Aleatório',
			'common.addTo' => 'Adicionar a...',
			'common.createNew' => 'Criar novo',
			'common.connect' => 'Conectar',
			'common.disconnect' => 'Desconectar',
			'common.play' => 'Assistir',
			'common.pause' => 'Pausar',
			'common.resume' => 'Continuar',
			'common.error' => 'Erro',
			'common.search' => 'Buscar',
			'common.home' => 'Início',
			'common.back' => 'Voltar',
			'common.settings' => 'Configurações',
			'common.mute' => 'Silenciar',
			'common.ok' => 'OK',
			'common.off' => 'Desligado',
			'common.options' => 'Opções',
			'common.seasonNumber' => ({required Object number}) => 'Temporada ${number}',
			'common.episodeNumberTitle' => ({required Object number, required Object title}) => 'Episódio ${number} - ${title}',
			'common.chapterNumber' => ({required Object number}) => 'Capítulo ${number}',
			'common.reconnect' => 'Reconectar',
			'common.viewAll' => 'Ver tudo',
			'common.checkingNetwork' => 'Verificando a internet...',
			'common.loadingServers' => 'Carregando servidores...',
			'common.connectingToServers' => 'Conectando aos servidores...',
			'common.startingOfflineMode' => 'Abrindo o modo sem internet...',
			'common.loading' => 'Carregando...',
			'common.fullscreen' => 'Tela cheia',
			'common.exitFullscreen' => 'Sair da tela cheia',
			'common.pressBackAgainToExit' => 'Toque em voltar de novo para sair',
			'common.ratingSource.critic' => 'Críticos',
			'common.ratingSource.audience' => 'Público',
			'common.ratingSource.imdb' => 'IMDb',
			'common.ratingSource.tmdb' => 'TMDB',
			'common.ratingSource.rottenTomatoes' => 'Rotten Tomatoes',
			'common.ratingSource.simkl' => 'Simkl',
			'common.ratingSource.mal' => 'MyAnimeList',
			'common.ratingSource.anilist' => 'AniList',
			'common.ratingSource.trakt' => 'Trakt',
			'common.ratingSource.rottenTomatoesCritic' => 'Críticos do Rotten Tomatoes',
			'common.ratingSource.rottenTomatoesAudience' => 'Público do Rotten Tomatoes',
			'common.notAvailable' => 'N/D',
			'common.url' => 'Endereço',
			'common.letterKeys' => 'ABC',
			'common.mediaKind.movie' => 'Filme',
			'common.mediaKind.show' => 'Série',
			'common.mediaKind.season' => 'Temporada',
			'common.mediaKind.episode' => 'Episódio',
			'common.mediaKind.artist' => 'Artista',
			'common.mediaKind.album' => 'Álbum',
			'common.mediaKind.track' => 'Faixa',
			'common.mediaKind.collection' => 'Coleção',
			'common.mediaKind.playlist' => 'Playlist',
			'common.mediaKind.clip' => 'Clipe',
			'common.mediaKind.photo' => 'Foto',
			'common.mediaKind.folder' => 'Pasta',
			'screens.licenses' => 'Licenças',
			'screens.switchProfile' => 'Trocar perfil',
			'screens.subtitleStyling' => 'Estilo das legendas',
			'screens.mpvConfig' => 'mpv.conf',
			'screens.logs' => 'Registros (logs)',
			'update.available' => 'Atualização disponível',
			'update.versionAvailable' => ({required Object version}) => 'A versão ${version} está disponível',
			'update.currentVersion' => ({required Object version}) => 'Atual: ${version}',
			'update.skipVersion' => 'Pular esta versão',
			'update.viewRelease' => 'Ver novidades',
			'update.latestVersion' => 'Você já está na versão mais recente',
			'update.checkFailed' => 'Não deu para procurar atualizações. Confira a internet e tente de novo.',
			'settings.title' => 'Configurações',
			'settings.supportDeveloper' => 'Apoie o CGFLIX',
			'settings.supportDeveloperDescription' => 'Doe pelo Liberapay para ajudar no desenvolvimento',
			'settings.language' => 'Idioma',
			'settings.theme' => 'Tema',
			'settings.appearance' => 'Aparência',
			'settings.videoPlayback' => 'Ao assistir',
			'settings.videoPlaybackDescription' => 'gestos e janelinha',
			'settings.advanced' => 'Avançado',
			'settings.episodePosterMode' => 'Imagem dos episódios',
			'settings.seriesPoster' => 'Pôster da série',
			'settings.seasonPoster' => 'Pôster da temporada',
			'settings.episodeThumbnail' => 'Miniatura',
			'settings.showHeroSectionDescription' => 'Mostrar um carrossel de destaques na tela inicial',
			'settings.secondsLabel' => 'Segundos',
			'settings.minutesLabel' => 'Minutos',
			'settings.secondsShort' => 's',
			'settings.minutesShort' => 'min',
			'settings.durationHint' => ({required Object min, required Object max}) => 'Digite um valor de ${min} a ${max}',
			'settings.systemTheme' => 'Sistema',
			'settings.lightTheme' => 'Claro',
			'settings.darkTheme' => 'Escuro',
			'settings.oledTheme' => 'OLED',
			'settings.libraryDensity' => 'Tamanho dos itens na biblioteca',
			'settings.displayScale' => 'Tamanho da interface',
			'settings.compact' => 'Compacto',
			'settings.comfortable' => 'Confortável',
			'settings.gridSpacing' => 'Espaçamento da grade',
			'settings.gridSpacingTight' => 'Compacto',
			'settings.gridSpacingNormal' => 'Normal',
			'settings.gridSpacingSpacious' => 'Espaçoso',
			'settings.tvCornerSpotlightBackdrop' => 'Imagem de destaque no canto',
			'settings.tvCornerSpotlightBackdropDescription' => 'Mostrar a imagem de destaque no canto superior direito em vez de ocupar a tela toda',
			'settings.viewMode' => 'Modo de exibição',
			'settings.gridView' => 'Grade',
			'settings.listView' => 'Lista',
			'settings.showHeroSection' => 'Mostrar destaques',
			'settings.continueWatchingAction' => 'Ao tocar em Continuar assistindo',
			'settings.continueWatchingPlay' => 'Assistir',
			'settings.continueWatchingDetails' => 'Abrir detalhes',
			'settings.episodeAction' => 'Ao tocar em um episódio',
			'settings.episodePlay' => 'Assistir',
			'settings.episodeDetails' => 'Abrir detalhes',
			'settings.useGlobalHubs' => 'Usar tela inicial unificada',
			'settings.useGlobalHubsDescription' => 'Mostrar as seções da tela inicial juntas. Se desligado, usa as recomendações de cada biblioteca.',
			'settings.showServerNameOnHubs' => 'Mostrar nome do servidor nas seções',
			'settings.showServerNameOnHubsDescription' => 'Sempre mostrar o nome do servidor no título das seções.',
			'settings.groupLibrariesByServer' => 'Agrupar bibliotecas por servidor',
			'settings.groupLibrariesByServerDescription' => 'Agrupar as bibliotecas do menu lateral por servidor.',
			'settings.alwaysKeepSidebarOpen' => 'Manter menu lateral sempre aberto',
			'settings.alwaysKeepSidebarOpenDescription' => 'O menu lateral fica aberto e o conteúdo se ajusta ao lado',
			'settings.showUnwatchedCount' => 'Mostrar quantos faltam assistir',
			'settings.showUnwatchedCountDescription' => 'Mostrar o número de episódios não assistidos em séries e temporadas',
			'settings.showWatchedIndicators' => 'Marcar o que já foi assistido',
			'settings.showWatchedIndicatorsDescription' => 'Mostrar um sinal de visto em filmes, séries e episódios já assistidos',
			'settings.showEpisodeNumberOnCards' => 'Mostrar número do episódio',
			'settings.showEpisodeNumberOnCardsDescription' => 'Mostrar temporada e episódio nas capas dos episódios',
			'settings.showSeasonPostersOnTabs' => 'Mostrar pôsteres nas abas de temporada',
			'settings.showSeasonPostersOnTabsDescription' => 'Mostrar o pôster de cada temporada acima da aba',
			'settings.tvFullCardLayout' => 'Capas completas na TV',
			'settings.tvFullCardLayoutDescription' => 'Na TV, mostrar capas só com a imagem e os nomes dos atores por cima',
			'settings.focusGlow' => 'Brilho na seleção',
			'settings.focusGlowDescription' => 'Mostrar um brilho suave em volta da capa selecionada',
			'settings.visualEffects' => 'Efeitos visuais',
			'settings.visualEffectsAuto' => 'Automático',
			'settings.visualEffectsAutoDescription' => 'Reduzir os efeitos sozinho em aparelhos mais simples',
			'settings.visualEffectsFull' => 'Completos',
			'settings.visualEffectsReduced' => 'Reduzidos',
			'settings.visualEffectsReducedDescription' => 'Menos animações e imagens em menor resolução',
			'settings.hideSpoilers' => 'Ocultar spoilers de episódios não assistidos',
			'settings.hideSpoilersDescription' => 'Desfocar imagens e resumos dos episódios que você ainda não viu',
			'settings.playerBackend' => 'Reprodutor de vídeo',
			'settings.exoPlayer' => 'ExoPlayer',
			'settings.mpv' => 'mpv',
			'settings.hardwareDecoding' => 'Aceleração de vídeo',
			'settings.hardwareDecodingDescription' => 'Usar o chip de vídeo do aparelho quando possível (mais leve e economiza bateria)',
			'settings.playbackBuffer' => 'Carregamento antecipado',
			'settings.playbackBufferAuto' => 'Automático (recomendado)',
			'settings.playbackBufferLarge' => 'Grande',
			'settings.playbackBufferExtraLarge' => 'Extra grande',
			'settings.playbackBufferDescription' => 'Carrega mais vídeo antes para evitar travadas em internet instável. Também depende do tamanho da memória de reprodução.',
			'settings.defaultQualityTitle' => 'Qualidade padrão',
			'settings.cellularQualityTitle' => 'Qualidade padrão nos dados móveis',
			'settings.cellularQualitySameAsDefault' => 'Igual à qualidade padrão',
			'settings.directPlayCoveredQuality' => 'Vídeos menores na qualidade original',
			'settings.directPlayCoveredQualityDescription' => 'Tocar direto, sem conversão no servidor, os vídeos que já cabem no limite de qualidade',
			'settings.videoCodecs' => 'Codecs de vídeo',
			'settings.videoCodecsDescription' => 'Formatos desmarcados são convertidos pelo servidor',
			'settings.videoCodecsAlwaysAccepted' => 'Sempre aceito',
			'settings.musicQualityTitle' => 'Qualidade da música',
			'settings.subtitleStyling' => 'Estilo das legendas',
			'settings.subtitleStylingDescription' => 'Tamanho, cor, contorno e fundo da legenda',
			'settings.smallSkipDuration' => 'Avançar e voltar (toque curto)',
			'settings.largeSkipDuration' => 'Avançar e voltar (toque longo)',
			'settings.rewindOnResume' => 'Voltar um pouco ao continuar',
			'settings.secondsUnit' => ({required Object seconds}) => '${seconds} segundos',
			'settings.defaultSleepTimer' => 'Desligar automaticamente após (padrão)',
			'settings.minutesUnit' => ({required Object minutes}) => '${minutes} minutos',
			'settings.rememberTrackSelections' => 'Lembrar áudio e legenda de cada série/filme',
			'settings.rememberTrackSelectionsDescription' => 'Guardar suas escolhas de áudio e legenda para cada título',
			'settings.rememberTrackSelectionsBackendRule' => 'No Plex, cada escolha fica salva no servidor por arquivo; no Jellyfin, também liga a opção "Lembrar seleções" da sua conta; no Emby não funciona',
			'settings.followServerTrackSelections' => 'Usar o áudio e a legenda do servidor em cada episódio',
			'settings.followServerTrackSelectionsDescription' => 'Ao trocar de episódio, usar o áudio e a legenda escolhidos no servidor em vez de manter a escolha atual',
			'settings.resumeMusicOnLaunch' => 'Lembrar a sessão de música',
			'settings.resumeMusicOnLaunchDescription' => 'Ao abrir o app, retomar a última música de onde parou',
			'settings.showChapterMarkersOnTimeline' => 'Mostrar capítulos na barra de progresso',
			'settings.showChapterMarkersOnTimelineDescription' => 'Dividir a barra de progresso no início de cada capítulo',
			'settings.specialsOrdering' => 'Especiais na ordem dos episódios',
			'settings.specialsOrderingDescription' => 'Em que ponto da série os especiais aparecem',
			'settings.specialsOrderingServer' => 'Seguir a ordem do servidor',
			'settings.specialsOrderingAirDate' => 'Misturar pela data de exibição',
			'settings.specialsOrderingLast' => 'Depois das temporadas normais',
			'settings.clickVideoTogglesPlayback' => 'Clicar no vídeo para pausar/continuar',
			'settings.clickVideoTogglesPlaybackDescription' => 'Um clique no vídeo pausa ou continua, em vez de mostrar os controles.',
			'settings.videoPlayerControls' => 'Controles do reprodutor de vídeo',
			'settings.keyboardShortcuts' => 'Atalhos de teclado',
			'settings.keyboardShortcutsDescription' => 'Mudar os atalhos de teclado',
			'settings.videoPlayerNavigation' => 'Navegação do reprodutor de vídeo',
			'settings.videoPlayerNavigationDescription' => 'Usar as setas para andar pelos controles do reprodutor',
			'settings.watchTogetherRelay' => 'Servidor do Assistir juntos',
			'settings.watchTogetherRelayDescription' => 'Usar outro servidor para o Assistir juntos. Todos precisam usar o mesmo.',
			'settings.watchTogetherRelayHint' => 'https://minha-retransmissao.exemplo.com.br',
			'settings.watchTogetherRelayInvalid' => 'Digite um endereço válido, começando com http:// ou https://.',
			'settings.crashReporting' => 'Relatório de erros',
			'settings.crashReportingDescription' => 'Enviar relatórios de erro para ajudar a melhorar o app',
			'settings.debugLogging' => 'Registros de diagnóstico',
			'settings.debugLoggingDescription' => 'Guardar registros detalhados para ajudar a resolver problemas',
			'settings.viewLogs' => 'Ver registros (logs)',
			'settings.viewLogsDescription' => 'Ver os registros do app',
			'settings.clearImageCache' => 'Limpar memória de imagens',
			'settings.clearImageCacheDescription' => 'Apagar capas e miniaturas guardadas no aparelho. As imagens podem demorar um pouco mais para aparecer até serem baixadas de novo.',
			'settings.clearImageCacheSuccess' => 'Memória de imagens limpa',
			'settings.resetSettings' => 'Restaurar configurações',
			'settings.resetSettingsDescription' => 'Voltar todas as configurações ao padrão. Não dá para desfazer.',
			'settings.resetSettingsSuccess' => 'Configurações restauradas',
			'settings.backup' => 'Cópia de segurança',
			'settings.exportSettings' => 'Exportar configurações',
			'settings.exportSettingsDescription' => 'Salvar suas preferências em um arquivo',
			'settings.exportSettingsSuccess' => 'Configurações exportadas',
			'settings.importSettings' => 'Importar configurações',
			'settings.importSettingsDescription' => 'Trazer preferências de um arquivo',
			'settings.importSettingsConfirm' => 'Isso vai substituir suas configurações atuais. Continuar?',
			'settings.importSettingsSuccess' => 'Configurações importadas',
			'settings.importSettingsInvalidFile' => 'Este arquivo não é uma exportação válida do CGFLIX',
			'settings.importSettingsNoUser' => 'Entre na sua conta antes de importar as configurações',
			'settings.shortcutsReset' => 'Atalhos voltaram ao padrão',
			'settings.resetShortcutsConfirm' => 'Isso troca seus atalhos personalizados pelos padrões. Continuar?',
			'settings.about' => 'Sobre',
			'settings.aboutDescription' => 'Versão, dicas do CGFLIX e licenças',
			'settings.updates' => 'Atualizações',
			'settings.updateAvailable' => 'Atualização disponível',
			'settings.checkForUpdates' => 'Procurar atualizações',
			'settings.autoCheckUpdatesOnStartup' => 'Procurar atualizações ao abrir o app',
			'settings.autoCheckUpdatesOnStartupDescription' => 'Avisar ao abrir o app quando houver uma atualização',
			'settings.validationErrorEnterNumber' => 'Digite um número válido',
			'settings.validationErrorDuration' => ({required Object min, required Object max, required Object unit}) => 'Use um valor de ${min} a ${max} (${unit})',
			'settings.shortcutAlreadyAssigned' => ({required Object action}) => 'Este atalho já é usado em ${action}',
			'settings.shortcutUpdated' => ({required Object action}) => 'Atalho atualizado para ${action}',
			'settings.saveFailed' => 'Não deu para salvar as alterações. Tente de novo.',
			'settings.autoPlayAndSkip' => 'Pular abertura e próximo episódio',
			'settings.autoPlayNextEpisode' => 'Próximo episódio sozinho',
			'settings.autoPlayNextEpisodeDescription' => 'Começar o próximo episódio quando o atual terminar',
			'settings.shuffleStartsFromBeginning' => 'Modo aleatório começa do início',
			'settings.shuffleStartsFromBeginningDescription' => 'No modo aleatório, começar cada episódio do início em vez de continuar de onde parou',
			'settings.playNextCountdown' => 'Contagem para o próximo episódio',
			'settings.playNextCountdownImmediate' => 'Começar na hora',
			'settings.skipIntroMode' => 'Pular abertura',
			'settings.skipIntroModeOffDescription' => 'a abertura passa normalmente',
			'settings.skipIntroModeButtonDescription' => 'o botão aparece quando a abertura começa',
			'settings.skipIntroModeAutoDescription' => 'pula sozinho depois da espera abaixo',
			'settings.skipCreditsMode' => 'Pular créditos',
			'settings.skipCreditsModeOffDescription' => 'os créditos passam normalmente',
			'settings.skipCreditsModeButtonDescription' => 'o botão aparece quando os créditos começam',
			'settings.skipCreditsModeAutoDescription' => 'pula os créditos e começa o próximo episódio',
			'settings.skipMarkerModeOff' => 'Desligado',
			'settings.skipMarkerModeButton' => 'Mostrar botão',
			'settings.skipMarkerModeAuto' => 'Automático',
			'settings.forceSkipMarkerFallback' => 'Sempre detectar abertura pelos capítulos',
			'settings.forceSkipMarkerFallbackDescription' => 'Procurar a abertura e os créditos pelo nome dos capítulos, mesmo quando o Plex já tiver essa informação',
			'settings.autoSkipDelay' => 'Espera antes de pular',
			'settings.autoSkipDelayDescription' => ({required Object seconds}) => 'Esperar ${seconds} segundos antes de pular sozinho',
			'settings.introPattern' => 'Nome do capítulo de abertura',
			'settings.introPatternDescription' => 'Expressão regular que reconhece a abertura pelo nome do capítulo',
			'settings.creditsPattern' => 'Nome do capítulo de créditos',
			'settings.creditsPatternDescription' => 'Expressão regular que reconhece os créditos pelo nome do capítulo',
			'settings.invalidRegex' => 'Expressão regular inválida',
			'settings.regex' => 'Expressão regular',
			'settings.downloads' => 'Baixados',
			'settings.downloadLocationDescription' => 'Escolha onde guardar o que você baixar',
			'settings.downloadLocationDefault' => 'Padrão (memória do app)',
			'settings.downloadLocationCustom' => 'Outra pasta',
			'settings.selectFolder' => 'Escolher pasta',
			'settings.resetToDefault' => 'Voltar ao padrão',
			'settings.currentPath' => ({required Object path}) => 'Atual: ${path}',
			'settings.downloadLocationChanged' => 'Pasta dos baixados alterada',
			'settings.downloadLocationReset' => 'Pasta dos baixados voltou ao padrão',
			'settings.downloadLocationInvalid' => 'Não dá para salvar arquivos nessa pasta. Escolha outra.',
			'settings.downloadLocationPickerUnavailable' => 'Não dá para escolher pasta neste aparelho',
			'settings.downloadOnWifiOnly' => 'Baixar só no Wi-Fi',
			'settings.downloadOnWifiOnlyDescription' => 'Não gasta seus dados móveis (4G/5G)',
			'settings.autoRemoveWatchedDownloads' => 'Apagar baixados já assistidos',
			'settings.autoRemoveWatchedDownloadsDescription' => 'Apagar sozinho os vídeos baixados depois que você assistir',
			'settings.cellularDownloadBlocked' => 'Baixar está bloqueado nos dados móveis. Conecte no Wi-Fi ou mude essa opção nas Configurações.',
			'settings.maxVolume' => 'Volume máximo',
			'settings.maxVolumeDescription' => 'Deixar o volume passar de 100% para vídeos com som baixo',
			'settings.maxVolumePercent' => ({required Object percent}) => '${percent}%',
			'settings.discordRichPresence' => 'Discord Rich Presence',
			'settings.discordRichPresenceDescription' => 'Mostrar o que você está assistindo no Discord',
			'settings.services' => 'Serviços',
			'settings.servicesDescription' => 'Conecte o Trakt para registrar o que você assiste',
			'settings.manageLibrariesDescription' => 'Mudar a ordem e ocultar bibliotecas',
			'settings.companionRemoteServer' => 'Servidor de controle remoto',
			'settings.companionRemoteServerDescription' => 'Deixar celulares na sua rede Wi-Fi controlarem este app',
			'settings.companionRemoteServerStartFailed' => 'Não deu para ligar o controle remoto. Tente de novo.',
			'settings.companionRemoteServerStopFailed' => 'Não deu para desligar o controle remoto. Tente de novo.',
			'settings.autoPip' => 'Abrir a janelinha ao sair',
			'settings.autoPipDescription' => 'Continuar o vídeo numa janelinha ao sair do app durante a reprodução',
			'settings.matchContentFrameRate' => 'Ajustar à taxa de quadros do conteúdo',
			'settings.matchContentFrameRateDescription' => 'Ajustar a frequência da tela ao vídeo (evita imagem tremida)',
			'settings.matchContentResolution' => 'Ajustar à resolução do conteúdo',
			'settings.matchContentResolutionDescription' => 'Muda a tela para a resolução original do vídeo, para a TV fazer a ampliação. Menus e legendas também ficam maiores durante a reprodução',
			'settings.matchRefreshRate' => 'Ajustar à frequência da tela',
			'settings.matchRefreshRateDescription' => 'Ajustar a frequência da tela no modo tela cheia',
			'settings.matchDynamicRange' => 'Ajustar à faixa dinâmica',
			'settings.matchDynamicRangeDescription' => 'Ligar o HDR da tela em vídeos HDR e depois voltar ao normal (SDR)',
			'settings.displaySwitchDelay' => 'Espera ao trocar o modo da tela',
			'settings.tunneledPlayback' => 'Reprodução em túnel',
			'settings.tunneledPlaybackDescription' => 'Usar o modo túnel de vídeo. Desligue se o vídeo ficar preto em HDR ou se a imagem travar.',
			'settings.audioPassthrough' => 'Enviar áudio direto ao receptor',
			'settings.audioPassthroughDescription' => 'Mandar o áudio Dolby/DTS sem conversão para o receptor ou a TV, mantendo o som surround. Desligue se ficar sem som.',
			'settings.audioPassthroughDescriptionAppleTv' => 'Usar o decodificador Dolby da Apple para Dolby Digital Plus, incluindo Atmos. DTS e TrueHD continuam tocando como PCM multicanal. Desligue se ficar sem som.',
			'settings.audioPassthroughOverriddenByNormalization' => 'Desligado enquanto o nivelamento de volume estiver ligado',
			'settings.audioChannelLimit' => 'Canais de áudio',
			'settings.audioChannelLimitDescription' => 'Junta os canais de áudio para caixas de som, fones ou aparelhos HDMI que não tocam todos os canais',
			'settings.audioChannelLimitOriginal' => 'Original',
			'settings.audioChannelLimitOriginalDescription' => 'Toca todos os canais da faixa',
			'settings.audioChannelLimitSurround51' => 'Até 5.1',
			'settings.audioChannelLimitSurround51Description' => 'Junta 7.1 em 5.1 para TVs e receptores que só aceitam PCM 5.1. O envio direto não muda.',
			'settings.audioChannelLimitStereo' => 'Som em estéreo',
			'settings.audioChannelLimitStereoDescription' => 'Junta os canais de áudio em estéreo, para caixas de som comuns ou fones. Desliga o envio direto.',
			'settings.downmixCenterBoost' => 'Reforço das vozes (canal central)',
			'settings.downmixCenterBoostValue' => ({required Object db}) => '${db} dB',
			'settings.downmixCenterBoostLabel' => 'Reforço (dB)',
			'settings.downmixCenterBoostShort' => 'dB',
			'settings.audioDownmixNormalize' => 'Nivelar volume no som em estéreo',
			'settings.audioDownmixNormalizeDescription' => 'Baixar um pouco o volume ao juntar os canais para não estourar o som. Desligue para manter o volume original, que pode distorcer em cenas muito altas.',
			'settings.dvConversionMode' => 'Conversão Dolby Vision',
			'settings.dvConversionModeDescription' => 'Escolha como tratar os arquivos Dolby Vision perfil 7.',
			'settings.dvConversionAuto' => 'Automático',
			'settings.dvConversionNative' => 'Nativo / desligado',
			'settings.dvConversionDv81' => 'P7 → P8.1',
			'settings.dvConversionHevcStrip' => 'P7 → HEVC',
			'settings.dvConversionAutoDescription' => 'Detectar o que o aparelho suporta e usar o comportamento padrão',
			'settings.dvConversionNativeDescription' => 'Forçar DV7 nativo e não tentar converter o Dolby Vision',
			'settings.dvConversionDv81Description' => 'Forçar a conversão RPU para Dolby Vision perfil 8.1',
			'settings.dvConversionHevcStripDescription' => 'Remover as camadas RPU/EL do Dolby Vision e mostrar HEVC comum, sem Dolby Vision',
			'settings.disableDolbyVision' => 'Desligar Dolby Vision',
			'settings.disableDolbyVisionDescription' => 'Usar a versão HDR10 ou HLG do arquivo em vez do Dolby Vision, quando houver',
			'settings.hdrSdrConversion' => 'Conversão de HDR para SDR',
			'settings.hdrSdrConversionDescription' => 'Escolha quem converte vídeos HDR quando a tela não mostra HDR.',
			'settings.hdrSdrConversionAuto' => 'Automático',
			'settings.hdrSdrConversionAutoDescription' => 'O aparelho no Android 9 ou mais novo; o reprodutor nas versões anteriores',
			'settings.hdrSdrConversionDevice' => 'Aparelho',
			'settings.hdrSdrConversionDeviceDescription' => 'O chip de vídeo do aparelho converte. Mais rápido, mas as cores variam de aparelho para aparelho',
			'settings.hdrSdrConversionPlayer' => 'Reprodutor',
			'settings.hdrSdrConversionPlayerDescription' => 'O reprodutor converte. Cores mais fiéis, mas vídeo 4K pode travar em TV boxes mais simples',
			'settings.deinterlace' => 'Desentrelaçamento',
			'settings.deinterlaceDescription' => 'Tirar as listras (efeito pente) de vídeos antigos entrelaçados (só no reprodutor mpv)',
			'settings.requireProfileSelectionOnOpen' => 'Perguntar o perfil ao abrir o app',
			'settings.requireProfileSelectionOnOpenDescription' => 'Mostrar a escolha de perfil sempre que abrir o app',
			'settings.forceTvMode' => 'Forçar modo TV',
			'settings.forceTvModeDescription' => 'Usar o visual de TV em aparelhos que não são reconhecidos como TV. Precisa reiniciar o app.',
			'settings.startInFullscreen' => 'Iniciar em tela cheia',
			'settings.startInFullscreenDescription' => 'Abrir o CGFLIX em tela cheia',
			'settings.exitFullscreenOnPlayerClose' => 'Sair da tela cheia ao fechar o reprodutor',
			'settings.exitFullscreenOnPlayerCloseDescription' => 'Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo',
			'settings.autoHidePerformanceOverlay' => 'Esconder sozinho o painel de desempenho',
			'settings.autoHidePerformanceOverlayDescription' => 'Esconder o painel de desempenho junto com os controles do reprodutor',
			'settings.showNavBarLabels' => 'Mostrar nomes na barra de navegação',
			'settings.showNavBarLabelsDescription' => 'Mostrar o nome embaixo de cada ícone da barra de navegação',
			'settings.startupSection' => 'Tela ao abrir o app',
			'settings.showExploreTab' => 'Mostrar aba Explorar',
			'settings.showExploreTabDescription' => 'Mostrar a aba Explorar com conteúdo do Plex Discover e dos serviços conectados',
			'settings.liveTvDefaultFavorites' => 'Canais favoritos por padrão',
			'settings.liveTvDefaultFavoritesDescription' => 'Mostrar só os canais favoritos ao abrir a TV ao vivo',
			'settings.general' => 'Geral',
			'settings.generalDescription' => 'Modo TV, perfil ao abrir e som de abertura',
			'settings.languageAndRegion' => 'Idioma e região',
			'settings.startup' => 'Ao abrir o app',
			'settings.display' => 'Tela',
			'settings.libraryAndCards' => 'Biblioteca e capas',
			'settings.homeScreen' => 'Tela inicial',
			'settings.navigation' => 'Navegação',
			'settings.window' => 'Janela',
			'settings.liveTv' => 'TV ao vivo',
			'settings.player' => 'Reprodutor',
			'settings.videoAndDisplay' => 'Vídeo e tela',
			'settings.audio' => 'Áudio',
			'settings.quality' => 'Qualidade',
			'settings.subtitles' => 'Legendas',
			'settings.seekAndTiming' => 'Avançar e voltar',
			'settings.behavior' => 'Comportamento',
			'settings.gestures' => 'Gestos',
			'settings.gestureBrightnessSwipe' => 'Deslizar para mudar o brilho',
			'settings.gestureBrightnessSwipeDescription' => 'Deslize para cima ou para baixo no lado esquerdo para mudar o brilho',
			'settings.gestureVolumeSwipe' => 'Deslizar para mudar o volume',
			'settings.gestureVolumeSwipeDescription' => 'Deslize para cima ou para baixo no lado direito para mudar o volume',
			'settings.gesturePinchToZoom' => 'Pinçar para dar zoom',
			'settings.gesturePinchToZoomDescription' => 'Use dois dedos no vídeo para ampliar ou reduzir',
			'settings.rememberBrightnessLevel' => 'Lembrar o brilho',
			'settings.rememberBrightnessLevelDescription' => 'Começar o vídeo com o brilho que você ajustou da última vez',
			'settings.controls' => 'Controles',
			'settings.rememberPlayerChanges' => 'Lembrar ajustes do reprodutor',
			'settings.rememberPlayerChangesDescription' => 'Onde guardar e repetir um ajuste feito durante o vídeo',
			'settings.scopePlaybackSpeed' => 'Velocidade de reprodução',
			'settings.scopeShaderPreset' => 'Filtro de imagem',
			'settings.scopeAspectRatio' => 'Proporção da tela',
			'settings.scopeSyncOffsets' => 'Sincronização de áudio e legendas',
			'settings.playerScopeOff' => 'Não salvar',
			'settings.playerScopeGlobal' => 'Em todos os vídeos',
			'settings.playerScopeLibrary' => 'Por biblioteca',
			'settings.playerScopeTitle' => 'Por série ou filme',
			'settings.exportDialogTitle' => 'Exportar configurações do CGFLIX',
			'search.hint' => 'Buscar filmes, séries, músicas...',
			'search.tryDifferentTerm' => 'Tente buscar com outras palavras',
			'search.searchYourMedia' => 'Buscar no seu servidor',
			'search.enterTitleActorOrKeyword' => 'Digite um título, ator ou palavra-chave',
			'search.people' => 'Pessoas',
			'hotkeys.setShortcutFor' => ({required Object actionName}) => 'Definir atalho para ${actionName}',
			'hotkeys.clearShortcut' => 'Limpar atalho',
			'hotkeys.noShortcutSet' => 'Nenhum atalho definido',
			'hotkeys.currentShortcut' => 'Atalho atual:',
			'hotkeys.pressToRecord' => 'Selecione para gravar um atalho',
			'hotkeys.recordingShortcut' => 'Aperte o atalho agora',
			'hotkeys.actions.playPause' => 'Reproduzir/pausar',
			'hotkeys.actions.volumeUp' => 'Aumentar volume',
			'hotkeys.actions.volumeDown' => 'Diminuir volume',
			'hotkeys.actions.seekForward' => ({required Object seconds}) => 'Avançar ${seconds} s',
			'hotkeys.actions.seekBackward' => ({required Object seconds}) => 'Voltar ${seconds} s',
			'hotkeys.actions.fullscreenToggle' => 'Tela cheia (ligar/desligar)',
			'hotkeys.actions.muteToggle' => 'Silenciar (ligar/desligar)',
			'hotkeys.actions.subtitleToggle' => 'Legendas (ligar/desligar)',
			'hotkeys.actions.audioTrackNext' => 'Próximo áudio',
			'hotkeys.actions.subtitleTrackNext' => 'Próxima legenda',
			'hotkeys.actions.chapterNext' => 'Próximo capítulo',
			'hotkeys.actions.chapterPrevious' => 'Capítulo anterior',
			'hotkeys.actions.episodeNext' => 'Próximo episódio',
			'hotkeys.actions.episodePrevious' => 'Episódio anterior',
			'hotkeys.actions.speedIncrease' => 'Aumentar velocidade',
			'hotkeys.actions.speedDecrease' => 'Diminuir velocidade',
			'hotkeys.actions.speedReset' => 'Velocidade normal',
			'hotkeys.actions.zoomIn' => 'Aumentar zoom',
			'hotkeys.actions.zoomOut' => 'Diminuir zoom',
			'hotkeys.actions.zoomReset' => 'Zoom normal',
			'hotkeys.actions.subSeekNext' => 'Ir para a próxima fala da legenda',
			'hotkeys.actions.subSeekPrev' => 'Ir para a fala anterior da legenda',
			'hotkeys.actions.shaderToggle' => 'Filtros de imagem (ligar/desligar)',
			'hotkeys.actions.skipMarker' => 'Pular abertura/créditos',
			'hotkeys.actions.screenshot' => 'Tirar foto da tela',
			'fileInfo.title' => 'Informações do arquivo',
			'fileInfo.overview' => 'Visão geral',
			'fileInfo.video' => 'Vídeo',
			'fileInfo.audio' => 'Áudio',
			'fileInfo.subtitles' => 'Legendas',
			'fileInfo.images' => 'Imagens incorporadas',
			'fileInfo.dataStreams' => 'Fluxos de dados',
			'fileInfo.lyrics' => 'Letras',
			'fileInfo.file' => 'Arquivo',
			'fileInfo.attachments' => 'Anexos',
			'fileInfo.delivery' => 'Entrega',
			'fileInfo.versionCounter' => ({required Object index, required Object count}) => 'Versão ${index} de ${count}',
			'fileInfo.fileCounter' => ({required Object index, required Object count}) => 'Arquivo ${index} de ${count}',
			'fileInfo.noStreams' => 'O servidor não informou as faixas deste arquivo.',
			'fileInfo.copyPath' => 'Copiar caminho',
			'fileInfo.pathCopied' => 'Caminho do arquivo copiado',
			'fileInfo.codec' => 'Codec',
			'fileInfo.codecTag' => 'Tag do codec',
			'fileInfo.resolution' => 'Resolução',
			'fileInfo.codedResolution' => 'Resolução codificada',
			'fileInfo.bitrate' => 'Taxa de bits',
			'fileInfo.frameRate' => 'Taxa de quadros',
			'fileInfo.rotation' => 'Rotação',
			'fileInfo.comment' => 'Comentário',
			'fileInfo.audioDescription' => 'Descrição de áudio',
			'fileInfo.headerCompression' => 'Compactação de cabeçalho',
			'fileInfo.sidecarFile' => 'Arquivo separado',
			'fileInfo.transportTimestamp' => 'Carimbo de transporte',
			'fileInfo.displayOffset' => 'Deslocamento de exibição',
			'fileInfo.previewFailureCode' => 'Código de falha da pré-visualização',
			'fileInfo.previewRetries' => 'Tentativas da pré-visualização',
			'fileInfo.aspectRatio' => 'Proporção',
			'fileInfo.pixelAspectRatio' => 'Proporção de aspecto de pixel',
			'fileInfo.profile' => 'Perfil',
			'fileInfo.level' => 'Nível',
			'fileInfo.bitDepth' => 'Profundidade de bits',
			'fileInfo.pixelFormat' => 'Formato de pixel',
			'fileInfo.colorSpace' => 'Espaço de cor',
			'fileInfo.colorRange' => 'Faixa de cor',
			'fileInfo.colorPrimaries' => 'Primárias de cor',
			'fileInfo.colorTransfer' => 'Transferência de cor',
			'fileInfo.chromaSubsampling' => 'Subamostragem de croma',
			'fileInfo.chromaLocation' => 'Localização do croma',
			'fileInfo.scanType' => 'Tipo de varredura',
			'fileInfo.interlaced' => 'Entrelaçado',
			'fileInfo.anamorphic' => 'Anamórfico',
			'fileInfo.referenceFrames' => 'Quadros de referência',
			'fileInfo.dynamicRange' => 'Faixa dinâmica',
			'fileInfo.dolbyVision' => 'Dolby Vision',
			'fileInfo.dolbyVisionLevel' => 'Nível Dolby Vision',
			'fileInfo.dolbyVisionVersion' => 'Versão Dolby Vision',
			_ => null,
		} ?? switch (path) {
			'fileInfo.dolbyVisionLayers' => 'Camadas Dolby Vision',
			'fileInfo.baseLayerCompatibility' => 'Compatibilidade da camada base',
			'fileInfo.avcBitstream' => 'Bitstream AVC',
			'fileInfo.nalLengthSize' => 'Tamanho do comprimento NAL',
			'fileInfo.scalingMatrix' => 'Matriz de dimensionamento personalizada',
			'fileInfo.streamIdentifier' => 'Identificador do fluxo',
			'fileInfo.streamIndex' => 'Índice do fluxo',
			'fileInfo.streamId' => 'ID do fluxo',
			'fileInfo.language' => 'Idioma',
			'fileInfo.languageCode' => 'Código do idioma',
			'fileInfo.streamTitle' => 'Título da faixa',
			'fileInfo.channels' => 'Canais',
			'fileInfo.sampleRate' => 'Taxa de amostragem',
			'fileInfo.spatialAudio' => 'Áudio espacial',
			'fileInfo.textBased' => 'Baseado em texto',
			'fileInfo.subtitleFormat' => 'Formato do arquivo separado',
			'fileInfo.provider' => 'Provedor',
			'fileInfo.matchScore' => 'Pontuação de correspondência',
			'fileInfo.externalDelivery' => 'Pode ser servido separadamente',
			'fileInfo.sidecarPath' => 'Caminho do arquivo separado',
			'fileInfo.sourceStream' => 'Copiado de',
			'fileInfo.temporary' => 'Temporário',
			'fileInfo.timeBase' => 'Base de tempo',
			'fileInfo.overallBitrate' => 'Taxa de bits total',
			'fileInfo.path' => 'Caminho',
			'fileInfo.fileName' => 'Nome do arquivo',
			'fileInfo.size' => 'Tamanho',
			'fileInfo.totalSize' => 'Tamanho total',
			'fileInfo.container' => 'Contêiner',
			'fileInfo.duration' => 'Duração',
			'fileInfo.previewThumbnails' => 'Miniaturas de pré-visualização',
			'fileInfo.previewIndex' => 'Índice de pré-visualização',
			'fileInfo.packetLength' => 'Tamanho do pacote',
			'fileInfo.filePresent' => 'Arquivo presente',
			'fileInfo.fileReadable' => 'Legível pelo servidor',
			'fileInfo.streamPath' => 'Caminho do fluxo',
			'fileInfo.optimizedForStreaming' => 'Otimizado para transmissão',
			'fileInfo.has64bitOffsets' => 'Deslocamentos de 64 bits',
			'fileInfo.protocol' => 'Protocolo',
			'fileInfo.mediaType' => 'Tipo de mídia',
			'fileInfo.sourceKind' => 'Tipo de origem',
			'fileInfo.optimizedVersion' => 'Versão otimizada',
			'fileInfo.optimizationTarget' => 'Alvo de otimização',
			'fileInfo.deletedAt' => 'Excluído',
			'fileInfo.remoteSource' => 'Origem remota',
			'fileInfo.infiniteStream' => 'Fluxo infinito',
			'fileInfo.directPlay' => 'Reprodução direta',
			'fileInfo.directStream' => 'Fluxo direto',
			'fileInfo.transcoding' => 'Transcodificação',
			'fileInfo.etag' => 'ETag',
			'fileInfo.versionId' => 'ID da versão',
			'fileInfo.fileId' => 'ID do arquivo',
			'fileInfo.defaultAudioTrack' => 'Faixa de áudio padrão',
			'fileInfo.defaultSubtitleTrack' => 'Faixa de legenda padrão',
			'fileInfo.subtitlesOff' => 'Desligadas',
			'fileInfo.flagDefault' => 'Padrão',
			'fileInfo.flagForced' => 'Forçada',
			'fileInfo.flagSelected' => 'Selecionada',
			'fileInfo.flagExternal' => 'Externa',
			'fileInfo.flagHearingImpaired' => 'Para surdos (SDH)',
			'fileInfo.flagDub' => 'Dublada',
			'fileInfo.flagOriginal' => 'Original',
			'fileInfo.channelsMono' => 'Mono',
			'fileInfo.dolbyVisionProfile' => ({required Object profile}) => 'Perfil ${profile}',
			'mediaMenu.markAsWatched' => 'Marcar como assistido',
			'mediaMenu.markAsUnwatched' => 'Marcar como não assistido',
			'mediaMenu.removeFromContinueWatching' => 'Tirar de Continuar assistindo',
			'mediaMenu.viewDetails' => 'Ver detalhes',
			'mediaMenu.goToSeries' => 'Ir para a série',
			'mediaMenu.shufflePlay' => 'Assistir em ordem aleatória',
			'mediaMenu.shuffleNotAvailableOffline' => 'A ordem aleatória não funciona sem internet',
			'mediaMenu.fileInfo' => 'Detalhes técnicos do arquivo',
			'mediaMenu.deleteEpisodeFromServer' => 'Excluir episódio do servidor',
			'mediaMenu.deleteSeasonFromServer' => 'Excluir temporada do servidor',
			'mediaMenu.deleteShowFromServer' => 'Excluir série do servidor',
			'mediaMenu.deleteMovieFromServer' => 'Excluir filme do servidor',
			'mediaMenu.deleteEpisodeTitle' => 'Excluir este episódio?',
			'mediaMenu.deleteSeasonTitle' => 'Excluir esta temporada?',
			'mediaMenu.deleteShowTitle' => 'Excluir esta série?',
			'mediaMenu.deleteMovieTitle' => 'Excluir este filme?',
			'mediaMenu.deleteEpisodeConfirm' => 'Excluir episódio',
			'mediaMenu.deleteSeasonConfirm' => 'Excluir temporada',
			'mediaMenu.deleteShowConfirm' => 'Excluir série',
			'mediaMenu.deleteMovieConfirm' => 'Excluir filme',
			'mediaMenu.deleteAnyway' => 'Excluir mesmo assim',
			'mediaMenu.confirmDeleteTarget' => ({required Object title}) => 'Apagar ${title} do seu servidor para sempre?',
			'mediaMenu.deleteMultipleWarning' => 'Isso inclui todos os episódios e seus arquivos.',
			'mediaMenu.deleteEpisodeCountWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Isso exclui o ${n} episódio e o arquivo dele.', other: 'Isso exclui todos os ${n} episódios e os arquivos deles.', ), 
			'mediaMenu.deleteMultiPartWarning' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Este item está armazenado como ${n} arquivo, que será excluído.', other: 'Este item está armazenado em ${n} arquivos, e todos eles serão excluídos.', ), 
			'mediaMenu.deleteSharedFileHeading' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Mais ${n} episódio está armazenado no mesmo arquivo e também será excluído:', other: 'Mais ${n} episódios estão armazenados no mesmo arquivo e também serão excluídos:', ), 
			'mediaMenu.deleteScopeUnverifiedProbeFailed' => 'O CGFLIX não conseguiu conferir quais arquivos serão apagados, então pode apagar mais do que o item acima. Cancele e tente de novo, ou exclua mesmo assim.',
			'mediaMenu.deleteScopeUnverifiedNoFileInfo' => 'O servidor não informou os arquivos deste item, então o CGFLIX não consegue conferir o que será apagado. Pode apagar mais do que o item acima.',
			'mediaMenu.mediaDeletedSuccessfully' => 'Item excluído',
			'mediaMenu.mediaFailedToDelete' => 'Não deu para excluir o item. Tente de novo.',
			'mediaMenu.rate' => 'Avaliar',
			'mediaMenu.playFromBeginning' => 'Assistir do começo',
			'mediaMenu.playVersion' => 'Assistir outra versão',
			'rateSheet.title' => 'Avaliar',
			'rateSheet.server' => 'Servidor',
			'rateSheet.favorite' => 'Favorito',
			'rateSheet.favorited' => 'Adicionado aos favoritos',
			'rateSheet.saved' => 'Salvo',
			'rateSheet.notAvailable' => 'Não encontrado neste serviço',
			'rateSheet.noConnectedServices' => 'Conecte um serviço nas Configurações para avaliar por ele.',
			'accessibility.mediaCardMovie' => ({required Object title}) => '${title}, filme',
			'accessibility.mediaCardShow' => ({required Object title}) => '${title}, série',
			'accessibility.mediaCardEpisode' => ({required Object title, required Object episodeInfo}) => '${title}, ${episodeInfo}',
			'accessibility.mediaCardSeason' => ({required Object title, required Object seasonInfo}) => '${title}, ${seasonInfo}',
			'accessibility.mediaCardWatched' => 'assistido',
			'accessibility.mediaCardPartiallyWatched' => ({required Object percent}) => '${percent} por cento assistido',
			'accessibility.mediaCardUnwatched' => 'não assistido',
			'accessibility.tapToPlay' => 'Toque para assistir',
			'accessibility.decrease' => 'Diminuir',
			'accessibility.increase' => 'Aumentar',
			'accessibility.decreaseValue' => ({required Object label}) => 'Diminuir ${label}',
			'accessibility.increaseValue' => ({required Object label}) => 'Aumentar ${label}',
			'accessibility.hue' => 'Matiz',
			'accessibility.saturation' => 'Saturação',
			'accessibility.brightness' => 'Brilho',
			'accessibility.hexColor' => 'Cor hexadecimal',
			'accessibility.expandText' => 'Expandir texto',
			'accessibility.collapseText' => 'Recolher texto',
			'accessibility.alphabetNavigation' => 'Navegação alfabética',
			'accessibility.alphabetScrollHint' => 'Deslize para cima ou para baixo para pular de letra em letra',
			'accessibility.rowColumnPosition' => ({required Object row, required Object rowCount, required Object column, required Object columnCount}) => 'Linha ${row} de ${rowCount}, coluna ${column} de ${columnCount}',
			'accessibility.rowPosition' => ({required Object row, required Object rowCount}) => 'Linha ${row} de ${rowCount}',
			'accessibility.autoScrollPlay' => 'Iniciar rolagem automática',
			'accessibility.autoScrollPause' => 'Pausar rolagem automática',
			'accessibility.hueShort' => 'M',
			'accessibility.saturationShort' => 'S',
			'accessibility.valueShort' => 'V',
			'tooltips.shufflePlay' => 'Assistir em ordem aleatória',
			'tooltips.playTrailer' => 'Ver trailer',
			'tooltips.markAsWatched' => 'Marcar como assistido',
			'tooltips.markAsUnwatched' => 'Marcar como não assistido',
			'audioTracks.track' => ({required Object n}) => 'Faixa de áudio ${n}',
			'videoControls.audioLabel' => 'Áudio',
			'videoControls.subtitlesLabel' => 'Legendas',
			'videoControls.addTime' => ({required Object amount, required Object unit}) => '+${amount}${unit}',
			'videoControls.letterbox' => 'Ajustar à tela',
			'videoControls.fillScreen' => 'Preencher a tela',
			'videoControls.stretch' => 'Esticar',
			'videoControls.lockRotation' => 'Travar rotação',
			'videoControls.unlockRotation' => 'Destravar rotação',
			'videoControls.timerActive' => 'Desligamento automático ligado',
			'videoControls.playbackWillPauseIn' => ({required Object duration}) => 'O vídeo vai pausar em ${duration}',
			'videoControls.sleepTimerEndOfVideo' => 'Fim do vídeo atual',
			'videoControls.sleepTimerStopAtHeader' => 'Parar em',
			'videoControls.sleepTimerDurationHeader' => 'Pausar depois de',
			'videoControls.playbackWillPauseAtEnd' => 'O vídeo vai pausar no final',
			'videoControls.stillWatching' => 'Você ainda está assistindo?',
			'videoControls.pausingIn' => ({required Object seconds}) => 'Pausando em ${seconds} s',
			'videoControls.continueWatching' => 'Continuar',
			'videoControls.autoPlayNext' => 'Próximo episódio sozinho',
			'videoControls.playNext' => 'Assistir o próximo',
			'videoControls.playButton' => 'Assistir',
			'videoControls.pauseButton' => 'Pausar',
			'videoControls.playbackPaused' => 'Pausado',
			'videoControls.playbackResumed' => 'Tocando',
			'videoControls.loadingVideo' => 'Carregando vídeo',
			'videoControls.showPlaybackControls' => 'Mostrar os botões',
			'videoControls.hidePlaybackControls' => 'Esconder os botões',
			'videoControls.seekBackwardButton' => ({required Object seconds}) => 'Voltar ${seconds} segundos',
			'videoControls.seekForwardButton' => ({required Object seconds}) => 'Avançar ${seconds} segundos',
			'videoControls.previousButton' => 'Episódio anterior',
			'videoControls.nextButton' => 'Próximo episódio',
			'videoControls.previousChapterButton' => 'Capítulo anterior',
			'videoControls.nextChapterButton' => 'Próximo capítulo',
			'videoControls.muteButton' => 'Silenciar',
			'videoControls.unmuteButton' => 'Ligar o som',
			'videoControls.settingsButton' => 'Ajustes do vídeo',
			'videoControls.tracksButton' => 'Áudio e legendas',
			'videoControls.chaptersButton' => 'Capítulos',
			'videoControls.versionQualityButton' => 'Versão e qualidade',
			'videoControls.versionColumnHeader' => 'Versão',
			'videoControls.qualityColumnHeader' => 'Qualidade',
			'videoControls.qualityOriginal' => 'Original',
			'videoControls.qualityPresetLabel' => ({required Object resolution, required Object bitrate}) => '${resolution}p ${bitrate} Mbps',
			'videoControls.transcodeUnavailableFallback' => 'Não dá para converter este vídeo no servidor — tocando na qualidade original',
			'videoControls.subtitleUnavailableFallback' => 'Não deu para carregar a legenda escolhida — o vídeo vai continuar sem legenda',
			'videoControls.pipButton' => 'Janelinha',
			'videoControls.aspectRatioButton' => 'Proporção',
			'videoControls.ambientLighting' => 'Iluminação ambiente',
			'videoControls.fullscreenButton' => 'Entrar em tela cheia',
			'videoControls.exitFullscreenButton' => 'Sair da tela cheia',
			'videoControls.alwaysOnTopButton' => 'Sempre visível por cima',
			'videoControls.rotationLockButton' => 'Travar rotação',
			'videoControls.lockScreen' => 'Travar tela',
			'videoControls.screenLockButton' => 'Travar tela',
			'videoControls.longPressToUnlock' => 'Toque e segure para destravar',
			'videoControls.timelineSlider' => 'Barra de progresso do vídeo',
			'videoControls.volumeSlider' => 'Volume',
			'videoControls.endsAt' => ({required Object time}) => 'Termina às ${time}',
			'videoControls.pipActive' => 'Tocando na janelinha',
			'videoControls.pipFailed' => 'Não deu para abrir a janelinha',
			'videoControls.screenshotSaved' => 'Foto da tela salva',
			'videoControls.zoomPercent' => ({required Object percent}) => 'Zoom ${percent}%',
			'videoControls.volumePercent' => ({required Object percent}) => 'Volume ${percent}%',
			'videoControls.pipErrors.androidVersion' => 'Precisa do Android 8.0 ou mais novo',
			'videoControls.pipErrors.iosVersion' => 'Precisa do iOS 15.0 ou mais novo',
			'videoControls.pipErrors.permissionDisabled' => 'A janelinha (picture-in-picture) está desligada. Ligue nas configurações do aparelho.',
			'videoControls.pipErrors.notSupported' => 'Este aparelho não tem o modo janelinha (picture-in-picture)',
			'videoControls.pipErrors.voSwitchFailed' => 'Não deu para passar o vídeo para a janelinha',
			'videoControls.pipErrors.failed' => 'Não deu para abrir a janelinha',
			'videoControls.pipErrors.prepareFailed' => 'Não deu para preparar a janelinha',
			'videoControls.pipErrors.unknown' => ({required Object error}) => 'Ocorreu um erro: ${error}',
			'videoControls.chapters' => 'Capítulos',
			'videoControls.noChaptersAvailable' => 'Nenhum capítulo disponível',
			'videoControls.queue' => 'A seguir',
			'videoControls.noQueueItems' => 'Nada a seguir',
			'videoControls.noAudioDevicesAvailable' => 'Nenhuma saída de áudio disponível',
			'videoControls.searchSubtitles' => 'Buscar legendas',
			'videoControls.language' => 'Idioma',
			'videoControls.noSubtitlesFound' => 'Nenhuma legenda encontrada',
			'videoControls.subtitleDownloaded' => 'Legenda baixada',
			'videoControls.subtitleDownloadedNotApplied' => 'A legenda foi baixada, mas não deu para ativá-la',
			'videoControls.subtitleDownloadFailed' => 'Não deu para baixar a legenda. Tente de novo.',
			'videoControls.searchLanguages' => 'Buscar idiomas...',
			'videoControls.skipIntro' => 'Pular abertura',
			'videoControls.skipCredits' => 'Pular créditos',
			'videoControls.nextEpisode' => 'Próximo episódio',
			'videoControls.subtitleTrack' => ({required Object n}) => 'Faixa ${n}',
			'videoControls.subtitleFile' => ({required Object name}) => 'Legenda ${name}',
			'videoControls.forcedTrack' => ({required Object label}) => '${label} (forçada)',
			'videoControls.osdSubtitlesOff' => 'Legendas: desligadas',
			'videoControls.osdSubtitles' => ({required Object track}) => 'Legendas: ${track}',
			'videoControls.osdAudio' => ({required Object track}) => 'Áudio: ${track}',
			'messages.markedAsWatched' => 'Marcado como assistido',
			'messages.markedAsUnwatched' => 'Marcado como não assistido',
			'messages.markedAsWatchedOffline' => 'Marcado como assistido (será atualizado quando voltar a internet)',
			'messages.markedAsUnwatchedOffline' => 'Marcado como não assistido (será atualizado quando voltar a internet)',
			'messages.autoRemovedWatchedDownload' => ({required Object title}) => 'Apagado automaticamente: ${title}',
			'messages.autoRemovedWatchedDownloads' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} baixado já assistido foi apagado automaticamente', other: '${n} baixados já assistidos foram apagados automaticamente', ), 
			'messages.removedFromContinueWatching' => 'Tirado de Continuar assistindo',
			'messages.errorLoading' => ({required Object error}) => 'Não deu para carregar: ${error}',
			'messages.searchPartialResults' => 'Não deu para buscar em todos os servidores. Mostrando o que foi encontrado.',
			'messages.streamInterrupted' => 'O vídeo foi interrompido. Toque em reproduzir ou avance para tentar de novo.',
			'messages.liveStreamInterrupted' => 'A transmissão ao vivo foi interrompida. Toque em reproduzir para tentar de novo.',
			'messages.fileInfoNotAvailable' => 'Informações do arquivo indisponíveis',
			'messages.playbackAuthenticationRequired' => 'Entre de novo no servidor para assistir este título.',
			'messages.playbackServerUnavailable' => 'O servidor está fora do ar. Tente de novo daqui a pouco.',
			'messages.playbackDataInvalid' => 'O servidor mandou informações erradas para tocar este vídeo. Tente de novo.',
			'messages.playbackCancelled' => 'O vídeo foi cancelado.',
			'messages.playbackFailed' => 'Não deu para começar o vídeo. Confira a internet e tente de novo.',
			'messages.playbackFailedDetail' => ({required Object error}) => 'Não deu para começar o vídeo (${error}). Confira a internet e tente de novo.',
			'messages.audioOutputFailed' => 'O som parou de responder. Confira a conexão de áudio da TV ou do receptor; se outros apps também estiverem sem som, reinicie o aparelho.',
			'messages.mediaUnavailable' => 'Este conteúdo não está mais disponível.',
			'messages.errorLoadingFileInfo' => ({required Object error}) => 'Não deu para carregar as informações do arquivo: ${error}',
			'messages.errorLoadingSeries' => 'Não deu para carregar a série. Tente de novo.',
			'messages.musicNotSupported' => 'Ainda não dá para tocar música',
			'messages.noDescriptionAvailable' => 'Nenhuma descrição disponível',
			'messages.noProfilesAvailable' => 'Nenhum perfil disponível',
			'messages.contactAdminForProfiles' => 'Peça ao responsável pelo servidor para criar perfis',
			'messages.unableToDetermineLibrarySection' => 'Não deu para saber de qual biblioteca é este item',
			'messages.logsCleared' => 'Registros apagados',
			'messages.logsCopied' => 'Registros copiados',
			'messages.noLogsAvailable' => 'Nenhum registro disponível',
			'messages.libraryScanning' => ({required Object title}) => 'Procurando novidades em "${title}"...',
			'messages.libraryScanStarted' => ({required Object title}) => 'Começou a busca por novidades em "${title}"',
			'messages.libraryScanFailed' => ({required Object error}) => 'Não deu para atualizar a biblioteca: ${error}',
			'messages.metadataRefreshing' => ({required Object title}) => 'Atualizando as informações de "${title}"...',
			'messages.metadataRefreshStarted' => ({required Object title}) => 'Começou a atualização das informações de "${title}"',
			'messages.metadataRefreshFailed' => ({required Object error}) => 'Não deu para atualizar as informações: ${error}',
			'messages.logoutConfirm' => 'Quer mesmo sair?',
			'messages.noSeasonsFound' => 'Nenhuma temporada encontrada',
			'messages.seasonsLoadFailed' => 'Não deu para carregar as temporadas. Tente de novo.',
			'messages.noEpisodesFound' => 'Nenhum episódio encontrado na primeira temporada',
			'messages.noEpisodesFoundGeneral' => 'Nenhum episódio encontrado',
			'messages.episodesLoadFailed' => 'Não deu para carregar os episódios. Tente de novo.',
			'messages.noResultsFound' => 'Nenhum resultado encontrado',
			'messages.sleepTimerSet' => ({required Object label}) => 'O vídeo vai pausar em ${label}',
			'messages.noItemsAvailable' => 'Nenhum item disponível',
			'messages.failedToCreatePlayQueueNoItems' => 'Não deu para montar a fila — não há nada para tocar',
			'messages.failedPlayback' => ({required Object action, required Object error}) => 'Não deu para ${action}: ${error}',
			'messages.switchingToCompatiblePlayer' => 'Trocando para outro reprodutor que funciona com este vídeo...',
			'messages.serverLimitTitle' => 'Não deu para tocar agora',
			'messages.serverLimitBody' => 'O servidor não deixou tocar este vídeo. O mais comum é o limite de 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho (ou espere um minuto) e tente de novo. Se continuar, avise o Caio.',
			'messages.mediaUnreadableTitle' => 'Arquivo indisponível',
			'messages.mediaUnreadableBody' => 'O servidor achou este título, mas não conseguiu abrir o arquivo (erro 404). Ele pode ter sido movido ou apagado, ou o disco do servidor está desligado. Avise o responsável pelo servidor.',
			'messages.serverBusyTitle' => 'Vídeo indisponível agora',
			'messages.serverBusyBody' => 'O servidor não conseguiu enviar este vídeo (erro 503). Ele pode estar reiniciando, ocupado, ou com o disco desligado. Tente de novo daqui a pouco; se continuar, avise o responsável pelo servidor.',
			'messages.playbackNotAllowedTitle' => 'Limite de telas ou sem permissão',
			'messages.playbackNotAllowedBody' => 'O servidor não deixou tocar este título. Cada conta assiste em até 2 telas ao mesmo tempo: feche o CGFLIX em outro aparelho e tente de novo. Se não for isso, sua conta pode não ter acesso a este título.',
			'messages.logsUploaded' => 'Registros enviados',
			'messages.logsUploadFailed' => 'Não deu para enviar os registros. Confira a internet e tente de novo.',
			'messages.logId' => 'Código do registro',
			'messages.burnedSubtitlesUseMenu' => 'A legenda está gravada na imagem deste vídeo. Para trocar, use o menu de legendas.',
			'messages.noVideoUrl' => 'Não foi encontrado o endereço do vídeo',
			'messages.playbackNoMediaSources' => 'O servidor não mandou nenhuma versão deste vídeo que dê para tocar',
			'messages.playbackDataNotPrepared' => 'O vídeo começou antes de estar pronto. Tente de novo.',
			'messages.streamSelectionUnavailable' => 'Não dá para trocar áudio ou legenda neste vídeo',
			'messages.streamSelectionFailed' => 'Não deu para trocar o áudio ou a legenda. Tente de novo.',
			'messages.trackSelectionNotRemembered' => 'Esta escolha de áudio ou legenda vale só para este vídeo.',
			'messages.serverUnavailableForProfile' => 'Nenhum servidor disponível para este perfil',
			'subtitlingStyling.text' => 'Texto',
			'subtitlingStyling.border' => 'Contorno',
			'subtitlingStyling.background' => 'Fundo',
			'subtitlingStyling.fontSize' => 'Tamanho',
			'subtitlingStyling.textColor' => 'Cor do texto',
			'subtitlingStyling.borderSize' => 'Espessura do contorno',
			'subtitlingStyling.borderColor' => 'Cor do contorno',
			'subtitlingStyling.backgroundOpacity' => 'Fundo atrás do texto',
			'subtitlingStyling.backgroundColor' => 'Cor do fundo',
			'subtitlingStyling.position' => 'Altura na tela',
			'subtitlingStyling.assOverride' => 'Estilo das legendas ASS (anime)',
			'subtitlingStyling.overrideScale' => 'Só ajustar o tamanho',
			'subtitlingStyling.overrideForce' => 'Forçar o meu estilo',
			'subtitlingStyling.overrideStrip' => 'Remover o estilo original',
			'subtitlingStyling.positionTop' => 'Em cima',
			'subtitlingStyling.positionBottom' => 'Embaixo',
			'subtitlingStyling.useMargins' => 'Usar margens',
			'subtitlingStyling.useMarginsDescription' => 'Deixar a legenda aparecer fora da área do vídeo. Legendas com estilo próprio podem manter a posição original.',
			'subtitlingStyling.anchorToScreen' => 'Prender na tela',
			'subtitlingStyling.anchorToScreenDescription' => 'Mostrar a legenda nas faixas pretas abaixo de vídeos em tela larga',
			'subtitlingStyling.bold' => 'Negrito',
			'subtitlingStyling.italic' => 'Itálico',
			'subtitlingStyling.renderResolution' => 'Resolução da legenda',
			'subtitlingStyling.renderResolutionScreen' => 'Resolução da tela',
			'subtitlingStyling.renderResolutionVideo' => 'Resolução do vídeo',
			'mpvConfig.title' => 'mpv.conf',
			'mpvConfig.description' => 'Opções avançadas do reprodutor de vídeo (para quem entende)',
			'mpvConfig.presets' => 'Configurações salvas',
			'mpvConfig.noPresets' => 'Nenhuma configuração salva',
			'mpvConfig.saveAsPreset' => 'Salvar configuração...',
			'mpvConfig.presetName' => 'Nome da configuração',
			'mpvConfig.presetNameHint' => 'Digite um nome para esta configuração',
			'mpvConfig.loadPreset' => 'Carregar',
			'mpvConfig.deletePreset' => 'Excluir',
			'mpvConfig.presetSaved' => 'Configuração salva',
			'mpvConfig.presetLoaded' => 'Configuração carregada',
			'mpvConfig.presetDeleted' => 'Configuração excluída',
			'mpvConfig.confirmDeletePreset' => 'Quer mesmo excluir esta configuração?',
			'mpvConfig.configPlaceholder' => 'gpu-api=vulkan\nhwdec=auto\n# comentário',
			'mpvConfig.lineHint' => 'opção=valor',
			'mpvConfig.addLine' => 'Adicionar linha',
			'mpvConfig.removeLine' => 'Remover linha',
			'mpvConfig.embeddedVoHint' => 'No Linux, vo, gpu-context e gpu-api são ignorados: o vídeo dentro do app sempre usa vo=libmpv, e o gpu-next (necessário para filtros como o ArtCNN) não funciona dentro do app.',
			'dialog.confirmAction' => 'Confirmar',
			'profiles.addPlezyProfile' => 'Adicionar perfil CGFLIX',
			'profiles.switchingProfile' => 'Trocando de perfil…',
			'profiles.deleteThisProfileTitle' => 'Excluir este perfil?',
			'profiles.deleteThisProfileMessage' => ({required Object displayName}) => 'Remover ${displayName}. As conexões com os servidores continuam.',
			'profiles.active' => 'Ativo',
			'profiles.manage' => 'Gerenciar',
			'profiles.delete' => 'Excluir',
			'profiles.signOut' => 'Sair',
			'profiles.signOutPlexTitle' => 'Sair do Plex?',
			'profiles.signOutPlexMessage' => ({required Object displayName}) => 'Remover ${displayName} e todos os usuários do Plex Home? Você pode entrar de novo quando quiser.',
			'profiles.signOutPlexDeleteDownloads' => 'Apagar também os baixados',
			'profiles.signOutPlexDeleteDownloadsDescription' => 'Se não apagar, eles ficam neste aparelho e voltam quando você entrar de novo nesta conta.',
			'profiles.signedOutPlex' => 'Saiu do Plex.',
			'profiles.signOutFailed' => 'Não deu para sair. Tente de novo.',
			'profiles.sectionTitle' => 'Perfis',
			'profiles.summarySingle' => 'Crie perfis para separar o que cada pessoa da casa assiste',
			'profiles.summaryMultipleWithActive' => ({required Object count, required Object activeName}) => '${count} perfis · ativo: ${activeName}',
			'profiles.summaryMultiple' => ({required Object count}) => '${count} perfis',
			'profiles.removeConnectionTitle' => 'Remover conexão?',
			'profiles.removeConnectionMessage' => ({required Object displayName, required Object connectionLabel}) => 'Tirar o acesso de ${displayName} a ${connectionLabel}. Os outros perfis continuam com acesso.',
			'profiles.deleteProfileTitle' => 'Excluir perfil?',
			'profiles.deleteProfileMessage' => ({required Object displayName}) => 'Remover ${displayName} e as conexões dele. Os servidores continuam disponíveis.',
			'profiles.profileNameLabel' => 'Nome do perfil',
			'profiles.pinProtectionLabel' => 'Proteção por PIN',
			'profiles.pinManagedByPlex' => 'O PIN é definido pelo Plex. Mude em plex.tv.',
			'profiles.noPinSetEditOnPlex' => 'Nenhum PIN definido. Para pedir um PIN, edite o usuário do Plex Home em plex.tv.',
			'profiles.setPin' => 'Definir PIN',
			'profiles.setPinTitle' => 'Definir PIN',
			'profiles.confirmPinTitle' => 'Confirmar PIN',
			'profiles.pinSet' => 'PIN definido',
			'profiles.changePin' => 'Alterar',
			'profiles.removePin' => 'Remover',
			'profiles.connectionsLabel' => 'Conexões',
			'profiles.add' => 'Adicionar',
			'profiles.deleteProfileButton' => 'Excluir perfil',
			'profiles.noConnectionsHint' => 'Sem conexões — adicione um servidor para usar este perfil.',
			'profiles.noConnections' => 'Sem conexões',
			'profiles.plexHomeAccount' => 'Conta Plex Home',
			'profiles.plexAccountChip' => ({required Object account}) => 'Conta Plex: ${account}',
			'profiles.plexAccountUserChip' => ({required Object user, required Object account}) => '${user} via ${account}',
			'profiles.connectionDefault' => 'Padrão',
			'profiles.connectionAs' => ({required Object displayName}) => 'como ${displayName}',
			'profiles.makeDefault' => 'Definir como padrão',
			'profiles.removeConnection' => 'Remover',
			'profiles.profileRenamed' => 'Perfil renomeado.',
			'profiles.borrowAddTo' => ({required Object displayName}) => 'Adicionar a ${displayName}',
			'profiles.borrowExplain' => 'Usar a conexão de outro perfil. Perfis com PIN pedem o PIN.',
			'profiles.borrowEmpty' => 'Nenhuma conexão disponível ainda.',
			'profiles.borrowEmptySubtitle' => 'Primeiro conecte Plex, Jellyfin ou Emby em outro perfil.',
			'profiles.borrowLoadFailed' => 'Não deu para carregar as conexões. Tente de novo.',
			'profiles.borrowFromProfile' => ({required Object displayName}) => 'De ${displayName}',
			'profiles.borrowConnectionBorrowed' => 'Conexão adicionada ao perfil.',
			'profiles.borrowFailed' => 'Não deu para adicionar a conexão. Tente de novo.',
			'profiles.incorrectPin' => 'PIN incorreto.',
			'profiles.incorrectPinTryAgain' => 'PIN incorreto. Tente de novo.',
			'profiles.sourceProfileMissingParentAccount' => 'O perfil escolhido não tem a conta principal.',
			'profiles.failedToLoadHomeUsers' => 'Não deu para carregar os usuários do Plex Home. Confira a internet e tente de novo.',
			'profiles.failedToVerifyPin' => 'Não deu para conferir o PIN. Tente de novo.',
			'profiles.newProfile' => 'Novo perfil',
			'profiles.profileNameHint' => 'Ex.: Visitas, Crianças, Sala',
			'profiles.pinProtectionOptional' => 'Proteção por PIN (opcional)',
			'profiles.pinExplain' => 'PIN de 4 números para trocar de perfil.',
			'profiles.continueButton' => 'Continuar',
			'profiles.pinsDontMatch' => 'Os PINs não são iguais',
			'profiles.tokenIdentityMismatch' => 'O acesso deste perfil do Plex veio de um servidor diferente do esperado. Entre de novo.',
			'connections.sectionTitle' => 'Contas e servidores',
			'connections.addConnection' => 'Adicionar conexão',
			'connections.addConnectionSubtitleNoProfile' => 'Servidor novo: Plex, Jellyfin ou Emby',
			'connections.addConnectionSubtitleScoped' => ({required Object displayName}) => 'Servidor novo no perfil ${displayName}: Plex, Jellyfin ou Emby',
			'connections.sessionExpiredOne' => ({required Object name}) => 'O acesso a ${name} expirou',
			'connections.sessionExpiredMany' => ({required Object count}) => 'O acesso a ${count} servidores expirou',
			'connections.accessDeniedOne' => ({required Object name}) => '${name} recusou o acesso desta conta',
			'connections.accessDeniedMany' => ({required Object count}) => '${count} servidores recusaram o acesso desta conta',
			'connections.signInAgain' => 'Entrar de novo',
			'connections.editMediaBrowserTitle' => ({required Object product}) => 'Editar conexão do ${product}',
			'connections.editMediaBrowserIntro' => ({required Object serverName}) => 'Adicione ou remova endereços de ${serverName}. O CGFLIX usa o endereço que responder mais rápido.',
			'accountPreferences.sectionTitle' => 'Áudio e legenda',
			'accountPreferences.hubSubtitleSingle' => ({required Object account}) => 'Idioma do áudio e da legenda da conta ${account}',
			'accountPreferences.hubSubtitleMultiple' => ({required Object count}) => 'Idioma do áudio e da legenda de ${count} contas',
			'accountPreferences.pickAccount' => 'Cada conta guarda suas próprias preferências. Escolha qual quer editar.',
			'accountPreferences.storedOnAccount' => 'Estas opções ficam salvas na sua conta do servidor, então valem em todos os apps conectados a ela — inclusive o CGFLIX nos seus outros aparelhos.',
			'accountPreferences.noAccounts' => 'Nenhuma conta para configurar',
			'accountPreferences.noAccountsHint' => 'Entre no Plex ou conecte um servidor Jellyfin ou Emby, e as preferências dessa conta aparecem aqui.',
			'accountPreferences.unavailable' => 'Não deu para acessar esta conta',
			'accountPreferences.loadFailed' => 'Não deu para carregar estas preferências. Tente de novo.',
			'accountPreferences.noPreference' => 'Sem preferência',
			'accountPreferences.notSet' => 'Não definido',
			'accountPreferences.groups.audioAndSubtitles' => 'Áudio e legendas',
			'accountPreferences.groups.libraryDisplay' => 'Biblioteca',
			'accountPreferences.groups.personalMedia' => 'Mídia pessoal',
			'accountPreferences.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'accountPreferences.autoSelectAudio' => 'Escolher áudio pelo idioma',
			'accountPreferences.autoSelectAudioDescription' => 'Se desligado, usa o áudio que o arquivo marca como padrão.',
			'accountPreferences.preferredSubtitleLanguage' => 'Idioma de legenda preferido',
			'accountPreferences.subtitleMode' => 'Quando mostrar legendas',
			'accountPreferences.subtitleModes.none' => 'Só quando eu escolher',
			'accountPreferences.subtitleModes.noneDescription' => 'Nunca ligar legendas sozinho.',
			'accountPreferences.subtitleModes.defaultMode' => 'Seguir o que o arquivo indica',
			'accountPreferences.subtitleModes.defaultModeDescription' => 'Usar as marcações de padrão e forçada de cada legenda.',
			'accountPreferences.subtitleModes.always' => 'Sempre ligadas',
			'accountPreferences.subtitleModes.alwaysDescription' => 'Ligar a legenda no idioma preferido sempre que existir.',
			'accountPreferences.subtitleModes.onlyForced' => 'Só legendas forçadas',
			'accountPreferences.subtitleModes.onlyForcedDescription' => 'Ligar só as legendas marcadas como forçadas (trechos em outro idioma).',
			'accountPreferences.subtitleModes.smart' => 'Quando o áudio for estrangeiro',
			'accountPreferences.subtitleModes.smartDescription' => 'Ligar legendas só quando o áudio estiver em outro idioma.',
			'accountPreferences.subtitleAccessibility' => 'Legendas para surdos (SDH)',
			'accountPreferences.subtitleAccessibilityOptions.preferNonSdh' => 'Preferir legendas não SDH',
			'accountPreferences.subtitleAccessibilityOptions.preferSdh' => 'Preferir legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlySdh' => 'Só legendas SDH',
			'accountPreferences.subtitleAccessibilityOptions.onlyNonSdh' => 'Só legendas não SDH',
			'accountPreferences.forcedSubtitles' => 'Legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.preferNonForced' => 'Preferir legendas não forçadas',
			'accountPreferences.forcedSubtitleOptions.preferForced' => 'Preferir legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyForced' => 'Só legendas forçadas',
			'accountPreferences.forcedSubtitleOptions.onlyNonForced' => 'Só legendas não forçadas',
			'accountPreferences.displayMissingEpisodes' => 'Mostrar episódios que faltam',
			'accountPreferences.displayMissingEpisodesDescription' => 'Listar episódios que existem, mas ainda não estão no servidor.',
			'accountPreferences.hidePlayedInLatest' => 'Esconder o que já foi assistido em Recentes',
			'accountPreferences.hidePlayedInLatestDescription' => 'Não mostrar nas linhas de Recentes o que você já assistiu.',
			'accountPreferences.displayCollectionsView' => 'Mostrar Coleções',
			'accountPreferences.displayCollectionsViewDescription' => 'Mostrar as Coleções do servidor junto com as suas bibliotecas.',
			'accountPreferences.rewatchingInNextUp' => 'Manter em A seguir as séries que você está revendo',
			'accountPreferences.rewatchingInNextUpDescription' => 'Se você terminar uma série e começar de novo, ela continua em A seguir em vez de sumir.',
			'accountPreferences.watchedIndicator' => 'Marcar o que já foi assistido',
			'accountPreferences.watchedIndicatorOptions.none' => 'Nunca',
			'accountPreferences.watchedIndicatorOptions.moviesAndShows' => 'Filmes e séries',
			'accountPreferences.watchedIndicatorOptions.movies' => 'Só filmes',
			'accountPreferences.watchedIndicatorOptions.shows' => 'Só séries',
			'accountPreferences.mediaReviewsVisibility' => 'Notas e críticas',
			'accountPreferences.mediaReviewsOptions.usersAndCritics' => 'Público e críticos',
			'accountPreferences.mediaReviewsOptions.usersOnly' => 'Só público',
			'accountPreferences.mediaReviewsOptions.criticsOnly' => 'Só críticos',
			'accountPreferences.mediaReviewsOptions.nobody' => 'Oculto',
			'discover.title' => 'Descobrir',
			'discover.noContentAvailable' => 'Nenhum conteúdo disponível',
			'discover.addMediaToLibraries' => 'Adicione filmes e séries às suas bibliotecas',
			'discover.continueWatching' => 'Continuar assistindo',
			'discover.continueWatchingIn' => ({required Object library}) => 'Continuar assistindo em ${library}',
			'discover.nextUp' => 'A seguir',
			'discover.nextUpIn' => ({required Object library}) => 'A seguir em ${library}',
			'discover.recentlyAdded' => 'Adicionados recentemente',
			'discover.recentlyAddedIn' => ({required Object library}) => 'Adicionados recentemente em ${library}',
			'discover.latestAlbumsIn' => ({required Object library}) => 'Álbuns mais recentes em ${library}',
			'discover.recentlyPlayedIn' => ({required Object library}) => 'Tocados recentemente em ${library}',
			'discover.mostPlayedIn' => ({required Object library}) => 'Mais tocados em ${library}',
			'discover.playEpisode' => ({required Object season, required Object episode}) => 'S${season}E${episode}',
			'discover.overview' => 'Sinopse',
			'discover.cast' => 'Elenco',
			'discover.extras' => 'Trailers e extras',
			'discover.studio' => 'Estúdio',
			'discover.rating' => 'Classificação indicativa',
			'discover.director' => 'Diretor',
			'discover.directors' => 'Diretores',
			'discover.movie' => 'Filme',
			'discover.tvShow' => 'Série',
			'discover.minutesLeft' => ({required Object minutes}) => 'Faltam ${minutes} min',
			'discover.moreLikeThis' => 'Mais como este',
			'discover.titleCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} título', other: '${n} títulos', ), 
			'errors.searchFailed' => ({required Object error}) => 'Não deu para buscar: ${error}',
			'errors.searchUnavailable' => 'Não deu para buscar: nenhum servidor respondeu. Confira a internet e tente de novo.',
			'errors.connectionTimeout' => ({required Object context}) => 'O servidor demorou demais para responder ao carregar ${context}. Tente de novo.',
			'errors.connectionFailed' => 'Não deu para falar com o servidor. Confira a internet e tente de novo.',
			'errors.unableToLoad' => ({required Object context}) => 'Não deu para carregar ${context}. Tente de novo.',
			'errors.noClientAvailable' => 'Nenhum servidor conectado',
			'errors.pleaseEnterToken' => 'Digite o código de acesso (token)',
			'errors.invalidToken' => 'Código de acesso (token) inválido',
			'errors.failedToVerifyToken' => ({required Object error}) => 'Não deu para conferir o código de acesso: ${error}',
			'errors.failedToSwitchProfile' => ({required Object displayName}) => 'Não deu para trocar para ${displayName}',
			'errors.failedToDeleteProfile' => ({required Object displayName}) => 'Não deu para excluir ${displayName}',
			'errors.failedToRate' => 'Não deu para salvar a avaliação. Tente de novo.',
			'errors.reasonTimedOut' => 'o servidor demorou demais para responder',
			'errors.reasonUnreachable' => 'não deu para falar com o servidor',
			'errors.reasonRefused' => 'o servidor recusou o pedido',
			'errors.reasonNotFound' => 'o item não está mais no servidor',
			_ => null,
		} ?? switch (path) {
			'errors.reasonServerError' => 'o servidor teve um problema',
			'errors.reasonCancelled' => 'o pedido foi cancelado',
			'errors.reasonUnexpected' => 'aconteceu um erro inesperado',
			'libraries.title' => 'Bibliotecas',
			'libraries.fallbackTitle' => 'Biblioteca',
			'libraries.scanLibraryFiles' => 'Procurar arquivos novos',
			'libraries.scanLibrary' => 'Atualizar biblioteca',
			'libraries.analyze' => 'Analisar',
			'libraries.analyzeLibrary' => 'Analisar biblioteca',
			'libraries.refreshMetadata' => 'Atualizar informações',
			'libraries.emptyTrash' => 'Esvaziar lixeira',
			'libraries.emptyingTrash' => ({required Object title}) => 'Esvaziando a lixeira de "${title}"...',
			'libraries.trashEmptied' => ({required Object title}) => 'Lixeira de "${title}" esvaziada',
			'libraries.failedToEmptyTrash' => ({required Object error}) => 'Não deu para esvaziar a lixeira: ${error}',
			'libraries.analyzing' => ({required Object title}) => 'Analisando "${title}"...',
			'libraries.analysisStarted' => ({required Object title}) => 'Começou a análise de "${title}"',
			'libraries.failedToAnalyze' => ({required Object error}) => 'Não deu para analisar a biblioteca: ${error}',
			'libraries.noLibrariesFound' => 'Nenhuma biblioteca encontrada',
			'libraries.allLibrariesHidden' => 'Todas as bibliotecas estão ocultas',
			'libraries.hiddenLibrariesCount' => ({required Object count}) => 'Bibliotecas ocultas (${count})',
			'libraries.thisLibraryIsEmpty' => 'Esta biblioteca está vazia',
			'libraries.noItemsMatchFilters' => 'Nada encontrado com esses filtros',
			'libraries.resetFilters' => 'Limpar filtros',
			'libraries.all' => 'Todos',
			'libraries.clearAll' => 'Limpar tudo',
			'libraries.scanLibraryConfirm' => ({required Object title}) => 'Quer mesmo atualizar "${title}"?',
			'libraries.analyzeLibraryConfirm' => ({required Object title}) => 'Quer mesmo analisar "${title}"?',
			'libraries.refreshMetadataConfirm' => ({required Object title}) => 'Quer mesmo atualizar as informações de "${title}"?',
			'libraries.emptyTrashConfirm' => ({required Object title}) => 'Quer mesmo esvaziar a lixeira de "${title}"?',
			'libraries.manageLibraries' => 'Organizar bibliotecas',
			'libraries.sort' => 'Ordenar',
			'libraries.sortBy' => 'Ordenar por',
			'libraries.filters' => 'Filtros',
			'libraries.confirmActionMessage' => 'Quer mesmo fazer isso?',
			'libraries.showLibrary' => 'Mostrar biblioteca',
			'libraries.hideLibrary' => 'Ocultar biblioteca',
			'libraries.libraryOptions' => 'Opções da biblioteca',
			'libraries.content' => 'conteúdo da biblioteca',
			'libraries.selectLibrary' => 'Escolher biblioteca',
			'libraries.filtersWithCount' => ({required Object count}) => 'Filtros (${count})',
			'libraries.noRecommendations' => 'Nenhuma recomendação disponível',
			'libraries.noCollections' => 'Nenhuma coleção nesta biblioteca',
			'libraries.noFoldersFound' => 'Nenhuma pasta encontrada',
			'libraries.folders' => 'pastas',
			'libraries.tabs.recommended' => 'Recomendados',
			'libraries.tabs.browse' => 'Ver tudo',
			'libraries.tabs.collections' => 'Coleções',
			'libraries.tabs.playlists' => 'Playlists',
			'libraries.groupings.title' => 'Mostrar',
			'libraries.groupings.all' => 'Todos',
			'libraries.groupings.movies' => 'Filmes',
			'libraries.groupings.shows' => 'Séries',
			'libraries.groupings.seasons' => 'Temporadas',
			'libraries.groupings.episodes' => 'Episódios',
			'libraries.groupings.artists' => 'Artistas',
			'libraries.groupings.albums' => 'Álbuns',
			'libraries.groupings.tracks' => 'Faixas',
			'libraries.groupings.folders' => 'Pastas',
			'libraries.filterCategories.genre' => 'Gênero',
			'libraries.filterCategories.year' => 'Ano',
			'libraries.filterCategories.contentRating' => 'Classificação indicativa',
			'libraries.filterCategories.tag' => 'Tag',
			'libraries.filterCategories.unwatched' => 'Não assistidos',
			'libraries.filterCategories.unplayed' => 'Não tocados',
			'libraries.filterCategories.favorites' => 'Favoritos',
			'libraries.filterCategories.filePath' => 'Caminho do arquivo',
			'libraries.sortLabels.title' => 'Título',
			'libraries.sortLabels.dateAdded' => 'Data em que foi adicionado',
			'libraries.sortLabels.releaseDate' => 'Data de lançamento',
			'libraries.sortLabels.rating' => 'Avaliação',
			'libraries.sortLabels.communityRating' => 'Avaliação da comunidade',
			'libraries.sortLabels.criticRating' => 'Avaliação da crítica',
			'libraries.sortLabels.userRating' => 'Avaliação do usuário',
			'libraries.sortLabels.datePlayed' => 'Data em que foi assistido',
			'libraries.sortLabels.playCount' => 'Vezes assistido',
			'libraries.sortLabels.productionYear' => 'Ano de produção',
			'libraries.sortLabels.runtime' => 'Duração',
			'libraries.sortLabels.officialRating' => 'Classificação oficial',
			'libraries.sortLabels.premiereDate' => 'Data de estreia',
			'libraries.sortLabels.startDate' => 'Data de início',
			'libraries.sortLabels.airTime' => 'Horário de exibição',
			'libraries.sortLabels.studio' => 'Estúdio',
			'libraries.sortLabels.random' => 'Aleatório',
			'libraries.sortLabels.dateShared' => 'Data em que foi compartilhado',
			'libraries.sortLabels.latestEpisodeAirDate' => 'Data do episódio mais recente',
			'libraries.sortLabels.lastEpisodeDateAdded' => 'Último episódio adicionado',
			'libraries.sortLabels.dateDownloaded' => 'Data em que foi baixado',
			'libraries.sortLabels.size' => 'Tamanho',
			'libraries.sortLabels.library' => 'Biblioteca',
			'libraries.advancedFilters.include' => 'Incluir',
			'libraries.advancedFilters.exclude' => 'Excluir',
			'libraries.advancedFilters.any' => 'Qualquer',
			'libraries.advancedFilters.yes' => 'Sim',
			'libraries.advancedFilters.no' => 'Não',
			'libraries.advancedFilters.not' => ({required Object value}) => 'Não ${value}',
			'libraries.advancedFilters.valueCount' => ({required Object count}) => '${count} selecionados',
			'libraries.advancedFilters.valueCountExcluded' => ({required Object count}) => '${count} excluídos',
			'libraries.advancedFilters.searchValues' => 'Buscar valores',
			'libraries.advancedFilters.noValues' => 'Nenhum valor',
			'libraries.advancedFilters.matchContains' => 'Contém',
			'libraries.advancedFilters.matchNotContains' => 'Não contém',
			'libraries.advancedFilters.matchIs' => 'É',
			'libraries.advancedFilters.matchIsNot' => 'Não é',
			'libraries.advancedFilters.matchBeginsWith' => 'Começa com',
			'libraries.advancedFilters.matchEndsWith' => 'Termina com',
			'libraries.advancedFilters.textHint' => 'Digite para filtrar',
			'libraries.advancedFilters.from' => 'De',
			'libraries.advancedFilters.to' => 'Até',
			'libraries.advancedFilters.range' => ({required Object from, required Object to}) => '${from} a ${to}',
			'libraries.advancedFilters.atLeast' => ({required Object value}) => '${value} ou mais',
			'libraries.advancedFilters.atMost' => ({required Object value}) => 'Até ${value}',
			'libraries.advancedFilters.dateLastDays' => ({required Object count}) => 'Últimos ${count} dias',
			'libraries.advancedFilters.dateLastYear' => 'Último ano',
			'libraries.advancedFilters.dateOlderThanDays' => ({required Object count}) => 'Há mais de ${count} dias',
			'libraries.advancedFilters.dateOlderThanYear' => 'Há mais de um ano',
			'about.title' => 'Sobre',
			'about.openSourceLicenses' => 'Licenças de código aberto',
			'about.versionLabel' => ({required Object version}) => 'Versão ${version}',
			'about.appDescription' => 'Os filmes e séries da família, em qualquer tela',
			'about.viewLicensesDescription' => 'Ver as licenças de bibliotecas de terceiros',
			'serverSelection.noServersFoundForAccount' => ({required Object username, required Object email}) => 'Nenhum servidor encontrado para ${username} (${email})',
			'serverSelection.failedToLoadServers' => ({required Object error}) => 'Não deu para carregar os servidores: ${error}',
			'serverSelection.noValidServers' => 'Nenhum servidor disponível nesta conta',
			'hubDetail.title' => 'Título',
			'hubDetail.releaseYear' => 'Ano de lançamento',
			'hubDetail.dateAdded' => 'Data em que foi adicionado',
			'hubDetail.rating' => 'Avaliação',
			'hubDetail.noItemsFound' => 'Nenhum item encontrado',
			'logs.clearLogs' => 'Apagar registros',
			'logs.copyLogs' => 'Copiar registros',
			'logs.uploadLogs' => 'Enviar registros',
			'startup.failedTitle' => 'O CGFLIX não conseguiu iniciar',
			'startup.failedBody' => 'Algo deu errado ao abrir o app. Os detalhes abaixo mostram o que falhou.',
			'startup.failedBodyRepairable' => 'O arquivo de configurações do CGFLIX está danificado e precisa ser refeito antes de o app abrir. Tentar de novo não resolve — toque em Reparar dados.',
			'startup.phaseLabel' => 'Etapa',
			'startup.showDetails' => 'Mostrar detalhes',
			'startup.hideDetails' => 'Ocultar detalhes',
			'startup.copyDetails' => 'Copiar detalhes',
			'startup.detailsCopied' => 'Detalhes copiados',
			'startup.uploadDetails' => 'Enviar detalhes',
			'startup.repairStorage' => 'Reparar dados',
			'startup.repairTitle' => 'Reparar dados salvos?',
			'startup.repairBodyCommon' => 'O arquivo de configurações do CGFLIX está danificado e não dá para ler. Reparar volta todas as configurações ao padrão.',
			'startup.repairBodyOneCredential' => 'Um acesso salvo está danificado e não dá para ler. Reparar apaga só ele; suas outras configurações continuam.',
			'startup.repairBodySignInsKept' => 'Seus servidores e perfis devem continuar conectados.',
			'startup.repairBodySignInsLost' => 'Não dá para recuperar a chave que protege seus acessos salvos, então você vai precisar entrar de novo em todos os servidores e perfis. Nada muda no seu servidor.',
			'startup.repairBodySessionsUncertain' => 'Os serviços conectados (MAL, AniList, Simkl, Trakt) e o Seerr ficam guardados à parte e podem ou não ser mantidos. O CGFLIX vai dizer exatamente o que ficou.',
			'startup.repairConfirm' => 'Reparar',
			'startup.repairSucceeded' => 'Dados reparados',
			'startup.repairNeedsRestart' => 'Dados reparados — reinicie o app',
			'startup.restartRequiredBody' => 'Seus dados foram reparados, mas o CGFLIX precisa ser reiniciado. Feche o CGFLIX e abra de novo.',
			'startup.quitPlezy' => 'Sair do CGFLIX',
			'startup.repairFailed' => 'Não deu para reparar',
			'startup.repairKeptSignIns' => 'Seus servidores e perfis ainda estão conectados.',
			'startup.repairLostSignIns' => 'Não deu para recuperar a chave que protege seus acessos salvos. Você vai precisar entrar de novo em todos os servidores e perfis.',
			'startup.repairLostSessions' => 'Pelo menos um serviço conectado (ou o Seerr) foi desconectado e precisa ser conectado de novo.',
			'startup.backupTitle' => 'Uma cópia do arquivo danificado foi guardada',
			'startup.backupWarning' => 'Ela tem seus dados de acesso. Não envie nem compartilhe.',
			'startup.deleteBackup' => 'Excluir cópia',
			'startup.backupDeleted' => 'Cópia excluída.',
			'startup.previousFailureTitle' => 'O CGFLIX não conseguiu abrir da última vez',
			'licenses.relatedPackages' => 'Pacotes relacionados',
			'licenses.license' => 'Licença',
			'licenses.licenseNumber' => ({required Object number}) => 'Licença ${number}',
			'licenses.licensesCount' => ({required Object count}) => '${count} licenças',
			'navigation.libraries' => 'Bibliotecas',
			'navigation.downloads' => 'Baixados',
			'navigation.liveTv' => 'TV ao vivo',
			'navigation.explore' => 'Explorar',
			'explore.title' => 'Explorar',
			'explore.selectSource' => 'Escolher fonte',
			'explore.rows.watchlist' => 'Lista para assistir',
			'explore.rows.recommendedMovies' => 'Filmes recomendados',
			'explore.rows.recommendedShows' => 'Séries recomendadas',
			'explore.rows.trendingMovies' => 'Filmes em alta',
			'explore.rows.trendingShows' => 'Séries em alta',
			'explore.rows.popularMovies' => 'Filmes populares',
			'explore.rows.popularShows' => 'Séries populares',
			'explore.rows.trendingAnime' => 'Animes em alta',
			'explore.rows.suggestedAnime' => 'Animes sugeridos',
			'explore.rows.airingAnime' => 'Melhores animes em exibição',
			'explore.rows.popularAnime' => 'Animes mais populares',
			'explore.rows.trending' => 'Em alta',
			'explore.rows.upcomingMovies' => 'Filmes que vão estrear',
			'explore.rows.upcomingShows' => 'Séries que vão estrear',
			'explore.status.airing' => 'Em exibição',
			'explore.status.ended' => 'Finalizada',
			'explore.status.canceled' => 'Cancelada',
			'explore.status.upcoming' => 'Em breve',
			'explore.episodeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} episódio', other: '${n} episódios', ), 
			'explore.cast' => 'Elenco',
			'explore.characters' => 'Personagens',
			'explore.addToWatchlist' => 'Adicionar à lista para assistir',
			'explore.removeFromWatchlist' => 'Remover da lista para assistir',
			'explore.addedToWatchlist' => 'Adicionado à lista para assistir',
			'explore.removedFromWatchlist' => 'Removido da lista para assistir',
			'explore.watchlistUpdateFailed' => 'Não deu para atualizar a lista para assistir. Tente de novo.',
			'explore.watchlistNoMatch' => 'Não deu para encontrar este título na lista para assistir',
			'explore.notInLibrary' => 'Não está na sua biblioteca',
			'explore.inTheseLibraries' => 'Nestas bibliotecas',
			'explore.checkingLibrary' => 'Procurando na sua biblioteca...',
			'explore.libraryCheckFailed' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Não deu para procurar em ${n} servidor', other: 'Não deu para procurar em ${n} servidores', ), 
			'explore.emptyTitle' => 'Ainda não há nada aqui',
			'explore.emptyMessage' => ({required Object source}) => 'As linhas de ${source} vão aparecer aqui quando tiverem conteúdo.',
			'explore.searchHint' => ({required Object source}) => 'Buscar em ${source}',
			'explore.searchEmpty' => ({required Object query}) => 'Nenhum resultado para "${query}"',
			'explore.searchPrompt' => ({required Object source}) => 'Busque filmes e séries em ${source}.',
			'explore.searchFailed' => 'Não deu para buscar. Confira a internet e tente de novo.',
			'explore.badge.rankPopular' => ({required Object n}) => '#${n} em popularidade',
			'explore.badge.rankAiring' => ({required Object n}) => '#${n} no ar',
			'explore.badge.rankRated' => ({required Object n}) => '#${n} em avaliação',
			'explore.badge.rankTrending' => ({required Object n}) => '#${n} em alta',
			'explore.badge.rankSeasonal' => ({required Object n, required Object season}) => '#${n} em ${season}',
			'explore.badge.watchingNow' => ({required Object n}) => '${n} assistindo',
			'explore.badge.available' => 'Disponível',
			'explore.badge.partiallyAvailable' => 'Parcialmente disponível',
			'explore.badge.availableIn4k' => '4K disponível',
			'explore.badge.requested' => 'Pedido',
			'explore.badge.pendingApproval' => 'Esperando aprovação',
			'explore.badge.processing' => 'Em preparo',
			'explore.badge.declined' => 'Recusado',
			'explore.badge.requestFailed' => 'Pedido falhou',
			'explore.badge.requested4k' => '4K pedido',
			'explore.badge.seasonsAvailable' => ({required Object available, required Object total}) => '${available}/${total} temporadas',
			'explore.badge.nextEpisodeIn' => ({required Object episode, required Object duration}) => 'Ep ${episode} em ${duration}',
			'explore.badge.nextAiringIn' => ({required Object duration}) => 'Próximo em ${duration}',
			'explore.badge.episodesShort' => ({required Object n}) => '${n} eps',
			'explore.badge.minutesPerEpisode' => ({required Object n}) => '${n} min/ep',
			'explore.badge.adult' => '18+',
			'explore.stats.listed' => ({required Object n}) => '${n} listados',
			'explore.stats.viewersDay' => ({required Object n}) => '${n} assistiram hoje',
			'explore.stats.viewersWeek' => ({required Object n}) => '${n} assistiram esta semana',
			'explore.stats.viewersMonth' => ({required Object n}) => '${n} assistiram este mês',
			'explore.stats.viewersYear' => ({required Object n}) => '${n} assistiram este ano',
			'explore.stats.viewersAllTime' => ({required Object n}) => '${n} espectadores',
			'explore.stats.planning' => ({required Object n}) => '${n} pretendem assistir',
			'explore.stats.favorited' => ({required Object n}) => '${n} favoritaram',
			'explore.stats.dropRate' => ({required Object percent}) => '${percent} abandonaram',
			'explore.stats.comments' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} comentário', other: '${n} comentários', ), 
			'explore.stats.votes' => ({required Object n}) => '${n} votos',
			'explore.stats.watching' => ({required Object n}) => '${n} assistindo',
			'explore.stats.completed' => ({required Object n}) => '${n} concluíram',
			'explore.stats.onHold' => ({required Object n}) => '${n} em pausa',
			'explore.stats.dropped' => ({required Object n}) => '${n} abandonaram',
			'explore.season.winter' => 'Inverno',
			'explore.season.spring' => 'Primavera',
			'explore.season.summer' => 'Verão',
			'explore.season.fall' => 'Outono',
			'explore.season.withYear' => ({required Object season, required Object year}) => '${season} ${year}',
			'explore.format.tv' => 'TV',
			'explore.format.tvShort' => 'Curta para TV',
			'explore.format.movie' => 'Filme',
			'explore.format.special' => 'Especial',
			'explore.format.ova' => 'OVA',
			'explore.format.ona' => 'ONA',
			'explore.format.music' => 'Música',
			'explore.format.other' => 'Outro',
			'explore.sourceMaterial.original' => 'Original',
			'explore.sourceMaterial.manga' => 'Mangá',
			'explore.sourceMaterial.lightNovel' => 'Light novel',
			'explore.sourceMaterial.novel' => 'Romance',
			'explore.sourceMaterial.visualNovel' => 'Visual novel',
			'explore.sourceMaterial.game' => 'Jogo',
			'explore.sourceMaterial.webComic' => 'Webcomic',
			'explore.sourceMaterial.musicRelease' => 'Música',
			'explore.sourceMaterial.otherMedia' => 'Outro',
			'explore.creditRole.actor' => 'Ator/Atriz',
			'explore.creditRole.director' => 'Diretor',
			'explore.creditRole.writer' => 'Roteirista',
			'explore.creditRole.producer' => 'Produtor',
			'explore.creditRole.creator' => 'Criador',
			'explore.creditRole.composer' => 'Compositor',
			'explore.relation.prequel' => 'Antecessor',
			'explore.relation.sequel' => 'Continuação',
			'explore.relation.sideStory' => 'História paralela',
			'explore.relation.spinOff' => 'Spin-off',
			'explore.relation.alternativeVersion' => 'Versão alternativa',
			'explore.relation.summary' => 'Resumo',
			'explore.relation.parentStory' => 'História principal',
			'explore.relation.adaptation' => 'Adaptação',
			'explore.relation.other' => 'Relacionado',
			'explore.broadcast' => ({required Object day, required Object time}) => 'Vai ao ar ${day} às ${time}',
			'explore.broadcastWithZone' => ({required Object day, required Object time, required Object timezone}) => 'Vai ao ar ${day} às ${time} ${timezone}',
			'explore.detail.originalTitle' => 'Título original',
			'explore.detail.alsoKnownAs' => 'Também conhecido como',
			'explore.detail.studios' => 'Estúdios',
			'explore.detail.country' => 'País',
			'explore.detail.language' => 'Idioma',
			'explore.detail.released' => 'Lançado',
			'explore.detail.physicalRelease' => 'Em disco',
			'explore.detail.ended' => 'Encerrado',
			'explore.detail.addedOn' => ({required Object date}) => 'Adicionado em ${date}',
			'explore.detail.yourRating' => 'Sua avaliação',
			'explore.detail.budget' => 'Orçamento',
			'explore.detail.revenue' => 'Bilheteria',
			'explore.detail.contentAdvisory' => 'Classificação indicativa',
			'explore.detail.tags' => 'Tags',
			'explore.detail.revealSpoilerTags' => 'Mostrar tags com spoiler',
			'explore.detail.links' => 'Links',
			'explore.detail.watchOn' => 'Assistir em',
			'explore.detail.watchTrailer' => 'Ver trailer',
			'explore.detail.openOn' => ({required Object site}) => 'Abrir em ${site}',
			'explore.detail.crew' => 'Equipe',
			'explore.detail.ratings' => 'Avaliações',
			'explore.detail.schedule' => 'Programação',
			'explore.detail.recommendedByUsers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: 'Recomendado por ${n} usuário', other: 'Recomendado por ${n} usuários', ), 
			'explore.detail.recommendedBy' => ({required Object who}) => 'Recomendado por ${who}',
			'explore.detail.favoritedBy' => ({required Object who}) => 'Favoritado por ${who}',
			'explore.detail.unairedEpisodes' => ({required Object n}) => '${n} ainda não exibidos',
			'explore.detail.recommendedByPercent' => ({required Object percent}) => 'Recomendado por ${percent} dos espectadores',
			'explore.detail.relatedTitles' => 'Títulos relacionados',
			'explore.detail.background' => 'Por trás da obra',
			'explore.totalResults' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} resultado', other: '${n} resultados', ), 
			'liveTv.title' => 'TV ao vivo',
			'liveTv.guide' => 'Guia',
			'liveTv.noChannels' => 'Nenhum canal disponível',
			'liveTv.noDvr' => 'Nenhum servidor tem gravador de TV (DVR) configurado',
			'liveTv.serverUnavailable' => 'O servidor de TV ao vivo está fora do ar. Tente de novo daqui a pouco.',
			'liveTv.serverNotConnected' => 'O servidor de TV ao vivo não está conectado.',
			'liveTv.noPrograms' => 'Sem programação disponível',
			'liveTv.liveStreamFailed' => 'Não deu para abrir a transmissão ao vivo. Tente de novo.',
			'liveTv.unknownProgram' => 'Programa desconhecido',
			'liveTv.unknownHub' => 'Desconhecido',
			'liveTv.unknownError' => 'Erro desconhecido',
			'liveTv.channelNumber' => ({required Object number}) => 'Canal ${number}',
			'liveTv.unknownChannel' => 'Canal desconhecido',
			'liveTv.live' => 'AO VIVO',
			'liveTv.reloadGuide' => 'Recarregar guia',
			'liveTv.searchGuide' => 'Buscar no guia',
			'liveTv.searchHint' => 'Buscar canais e programas',
			'liveTv.searchNoResults' => ({required Object query}) => 'Nada encontrado para "${query}"',
			'liveTv.channelsSection' => 'Canais',
			'liveTv.programsSection' => 'Programas',
			'liveTv.now' => 'Agora',
			'liveTv.today' => 'Hoje',
			'liveTv.tomorrow' => 'Amanhã',
			'liveTv.midnight' => 'Meia-noite',
			'liveTv.overnight' => 'Madrugada',
			'liveTv.morning' => 'Manhã',
			'liveTv.daytime' => 'Tarde',
			'liveTv.evening' => 'Noite',
			'liveTv.lateNight' => 'Madrugada',
			'liveTv.whatsOn' => 'O que está passando',
			'liveTv.watchChannel' => 'Assistir ao canal',
			'liveTv.favorites' => 'Favoritos',
			'liveTv.reorderFavorites' => 'Mudar a ordem dos favoritos',
			'liveTv.noFavoriteChannels' => 'Nenhum canal favorito',
			'liveTv.noFavoriteChannelsHint' => 'Mostre todos os canais e toque e segure num canal para adicioná-lo aos favoritos.',
			'liveTv.showAllChannels' => 'Mostrar todos os canais',
			'liveTv.favoritesLoadFailed' => 'Não deu para carregar os favoritos. Confira a internet e tente de novo.',
			'liveTv.favoritesUpdateFailed' => 'Não deu para atualizar os favoritos. Confira a internet e tente de novo.',
			'liveTv.joinSession' => 'Entrar no que está passando',
			'liveTv.watchFromStart' => ({required Object minutes}) => 'Assistir do início (começou há ${minutes} min)',
			'liveTv.watchLive' => 'Assistir ao vivo',
			'liveTv.goToLive' => 'Voltar para o ao vivo',
			'liveTv.record' => 'Gravar',
			'liveTv.recordEpisode' => 'Gravar episódio',
			'liveTv.recordSeries' => 'Gravar série',
			'liveTv.recordOptions' => 'Opções de gravação',
			'liveTv.saveTo' => 'Salvar em',
			'liveTv.recordings' => 'Gravações',
			'liveTv.scheduledRecordings' => 'Agendadas',
			'liveTv.recordingRules' => 'Regras de gravação',
			'liveTv.noScheduledRecordings' => 'Sem gravações agendadas',
			'liveTv.manageRecording' => 'Gerenciar gravação',
			'liveTv.cancelRecording' => 'Cancelar gravação',
			'liveTv.cancelRecordingTitle' => 'Cancelar esta gravação?',
			'liveTv.cancelRecordingMessage' => ({required Object title}) => '${title} não será mais gravado.',
			'liveTv.deleteRule' => 'Excluir regra',
			'liveTv.deleteRuleTitle' => 'Excluir regra de gravação?',
			'liveTv.deleteRuleMessage' => ({required Object title}) => 'Episódios futuros de ${title} não serão gravados.',
			'liveTv.recordingScheduled' => 'Gravação agendada',
			'liveTv.alreadyScheduled' => 'Este programa já está agendado',
			'liveTv.dvrAdminRequired' => 'Só o administrador do servidor pode mudar as gravações',
			'liveTv.recordingFailed' => 'Não deu para agendar a gravação. Tente de novo.',
			'liveTv.recordingTargetMissing' => 'Não deu para saber em qual biblioteca gravar',
			'liveTv.recordNotAvailable' => 'Gravação indisponível para este programa',
			'liveTv.recordingCancelled' => 'Gravação cancelada',
			'liveTv.recordingRuleDeleted' => 'Regra de gravação excluída',
			'liveTv.processRecordingRules' => 'Aplicar regras de novo',
			'liveTv.recordingInProgress' => 'Gravando agora',
			'liveTv.recordingsCount' => ({required Object count}) => '${count} agendadas',
			'liveTv.editRule' => 'Editar regra',
			'liveTv.editRuleAction' => 'Editar',
			'liveTv.recordingRuleUpdated' => 'Regra de gravação atualizada',
			'liveTv.guideReloadRequested' => 'O guia vai ser atualizado',
			'liveTv.guideReloadFailed' => 'Não deu para atualizar o guia. Tente de novo.',
			'liveTv.rulesProcessRequested' => 'As regras vão ser aplicadas de novo',
			'liveTv.rulesProcessFailed' => 'Não deu para aplicar as regras de gravação. Tente de novo.',
			'liveTv.recordShow' => 'Gravar programa',
			'liveTv.recordSettings.startEarly' => 'Começar antes (segundos)',
			'liveTv.recordSettings.endLate' => 'Terminar depois (segundos)',
			'liveTv.recordSettings.newOnly' => 'Só episódios novos',
			'liveTv.recordSettings.anyChannel' => 'Gravar em qualquer canal',
			'liveTv.recordSettings.anyTime' => 'Gravar a qualquer hora',
			'liveTv.recordSettings.skipInLibrary' => 'Pular episódios que já estão na biblioteca',
			'liveTv.recordSettings.keepUpTo' => 'Quantos episódios guardar',
			'liveTv.recordSettings.keepUpToHint' => '0 guarda todos os episódios',
			'liveTv.startingInMinutes' => ({required Object minutes}) => 'Começa em ${minutes} min',
			'liveTv.dayAtTime' => ({required Object day, required Object time}) => '${day} às ${time}',
			'liveTv.invalidPlaybackData' => ({required Object product}) => 'O ${product} mandou informações erradas para a TV ao vivo. Tente de novo.',
			'liveTv.failedToStartChannel' => 'Não deu para abrir o canal ao vivo. Tente de novo.',
			'liveTv.failedToBuildStreamUrl' => 'Não deu para montar o endereço da transmissão',
			'liveTv.playbackStartFailed' => ({required Object reason}) => 'Não deu para abrir o canal: ${reason}',
			'liveTv.channelSwitchFailed' => ({required Object reason}) => 'Não deu para trocar de canal: ${reason}',
			'collections.title' => 'Coleções',
			'collections.collection' => 'Coleção',
			'collections.empty' => 'A coleção está vazia',
			'collections.deleteCollection' => 'Excluir coleção',
			'collections.deleteConfirm' => ({required Object title}) => 'Excluir "${title}"? Não dá para desfazer.',
			'collections.deleted' => 'Coleção excluída',
			'collections.deleteFailed' => 'Não deu para excluir a coleção. Tente de novo.',
			'collections.deleteFailedWithError' => ({required Object error}) => 'Não deu para excluir a coleção: ${error}',
			'collections.selectCollection' => 'Escolher coleção',
			'collections.collectionName' => 'Nome da coleção',
			'collections.enterCollectionName' => 'Digite o nome da coleção',
			'collections.addedToCollection' => 'Adicionado à coleção',
			'collections.errorAddingToCollection' => 'Não deu para adicionar à coleção. Tente de novo.',
			'collections.created' => 'Coleção criada',
			'collections.removeFromCollection' => 'Remover da coleção',
			'collections.removeFromCollectionConfirm' => ({required Object title}) => 'Remover "${title}" desta coleção?',
			'collections.removedFromCollection' => 'Removido da coleção',
			'collections.removeFromCollectionFailed' => 'Não deu para remover da coleção. Tente de novo.',
			'collections.removeFromCollectionError' => ({required Object error}) => 'Não deu para remover da coleção: ${error}',
			'collections.searchCollections' => 'Buscar coleções...',
			'playlists.title' => 'Playlists',
			'playlists.playlist' => 'Playlist',
			'playlists.noPlaylists' => 'Nenhuma playlist encontrada',
			'playlists.create' => 'Criar playlist',
			'playlists.playlistName' => 'Nome da playlist',
			'playlists.enterPlaylistName' => 'Digite o nome da playlist',
			'playlists.delete' => 'Excluir playlist',
			'playlists.removeItem' => 'Remover da playlist',
			'playlists.smartPlaylist' => 'Playlist inteligente',
			'playlists.itemCount' => ({required Object count}) => '${count} itens',
			'playlists.oneItem' => '1 item',
			'playlists.emptyPlaylist' => 'Esta playlist está vazia',
			'playlists.deleteConfirm' => 'Excluir playlist?',
			'playlists.deleteMessage' => ({required Object name}) => 'Quer mesmo excluir "${name}"?',
			'playlists.created' => 'Playlist criada',
			'playlists.deleted' => 'Playlist excluída',
			'playlists.itemAdded' => 'Adicionado à playlist',
			'playlists.itemRemoved' => 'Removido da playlist',
			'playlists.selectPlaylist' => 'Escolher playlist',
			'playlists.searchPlaylists' => 'Buscar playlists...',
			'playlists.errorCreating' => 'Não deu para criar a playlist. Tente de novo.',
			'playlists.errorDeleting' => 'Não deu para excluir a playlist. Tente de novo.',
			'playlists.errorLoading' => 'Não deu para carregar as playlists. Tente de novo.',
			'playlists.errorAdding' => 'Não deu para adicionar à playlist. Tente de novo.',
			'playlists.errorReordering' => 'Não deu para mudar a ordem da playlist. Tente de novo.',
			'playlists.errorRemoving' => 'Não deu para remover da playlist. Tente de novo.',
			'music.goToAlbum' => 'Ir para o álbum',
			'music.goToArtist' => 'Ir para o artista',
			'music.instantMix' => 'Mix instantâneo',
			'music.playNext' => 'Tocar em seguida',
			'music.addToQueue' => 'Adicionar à fila',
			'music.discNumber' => ({required Object n}) => 'Disco ${n}',
			'music.trackCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '${n} faixa', other: '${n} faixas', ), 
			'music.nowPlaying' => 'Tocando agora',
			'music.playingFrom' => ({required Object title}) => 'Tocando de ${title}',
			'music.queue' => 'Fila',
			'music.clearQueue' => 'Limpar fila',
			'music.lyrics' => 'Letra',
			'music.noLyrics' => 'Sem letra disponível',
			'music.sleepTimer' => 'Desligar automaticamente',
			'music.sleepTimerEndOfTrack' => 'Fim da faixa',
			'music.sleepTimerMinutes' => ({required Object n}) => '${n} minutos',
			'music.stopPlayback' => 'Parar de tocar',
			'music.previousTrack' => 'Faixa anterior',
			'music.nextTrack' => 'Próxima faixa',
			'music.repeat' => 'Repetir',
			'music.repeatAll' => 'Repetir tudo',
			'music.repeatOne' => 'Repetir esta faixa',
			'music.instantMixNoServer' => 'Nenhum servidor disponível para o mix instantâneo',
			'music.instantMixFailed' => 'Não deu para carregar o mix instantâneo. Tente de novo.',
			'music.instantMixEmpty' => 'O mix instantâneo veio sem nenhuma faixa',
			'music.noAudioUrl' => ({required Object track}) => 'Não foi encontrado o endereço do áudio de ${track}',
			'music.discography.singlesAndEps' => 'Singles e EPs',
			'music.discography.live' => 'Ao vivo',
			'music.discography.compilations' => 'Compilações',
			'watchTogether.title' => 'Assistir juntos',
			'watchTogether.description' => 'Assista ao mesmo tempo com amigos e família, cada um na sua tela',
			'watchTogether.createSession' => 'Criar sessão',
			'watchTogether.creating' => 'Criando...',
			'watchTogether.joinSession' => 'Entrar na sessão',
			'watchTogether.joining' => 'Entrando...',
			'watchTogether.controlMode' => 'Modo de controle',
			'watchTogether.controlModeQuestion' => 'Quem pode pausar e avançar?',
			'watchTogether.hostOnly' => 'Só o anfitrião',
			'watchTogether.anyone' => 'Qualquer pessoa',
			'watchTogether.hostingSession' => 'Você criou uma sessão',
			'watchTogether.inSession' => 'Em uma sessão',
			'watchTogether.sessionCode' => 'Código da sessão',
			'watchTogether.openSessionControls' => 'Abrir os controles do Assistir juntos',
			'watchTogether.copySessionCode' => 'Copiar código da sessão',
			'watchTogether.hostControlsPlayback' => 'Só o anfitrião pode pausar e avançar',
			'watchTogether.anyoneCanControl' => 'Qualquer pessoa pode pausar e avançar',
			'watchTogether.hostControls' => 'Anfitrião controla',
			'watchTogether.anyoneControls' => 'Todos controlam',
			'watchTogether.participants' => 'Participantes',
			'watchTogether.host' => 'Anfitrião',
			'watchTogether.hostBadge' => 'ANFITRIÃO',
			'watchTogether.youAreHost' => 'Você é o anfitrião',
			'watchTogether.makeHost' => 'Tornar anfitrião',
			'watchTogether.makeHostQuestion' => 'Passar o controle de anfitrião?',
			'watchTogether.makeHostConfirm' => ({required Object name}) => '${name} vai controlar o vídeo e conduzir a sessão para todos.',
			'watchTogether.transfer' => 'Passar',
			'watchTogether.hostChangedTo' => ({required Object name}) => '${name} agora é o anfitrião',
			'watchTogether.youAreNowHost' => 'Agora você é o anfitrião',
			'watchTogether.hostTransferFailed' => ({required Object name}) => 'Não deu para passar o controle para ${name}',
			'watchTogether.watchingWithOthers' => 'Assistindo com outras pessoas',
			'watchTogether.endSession' => 'Encerrar sessão',
			_ => null,
		} ?? switch (path) {
			'watchTogether.leaveSession' => 'Sair da sessão',
			'watchTogether.endSessionQuestion' => 'Encerrar sessão?',
			'watchTogether.leaveSessionQuestion' => 'Sair da sessão?',
			'watchTogether.endSessionConfirm' => 'Isso vai encerrar a sessão para todo mundo.',
			'watchTogether.leaveSessionConfirm' => 'Você vai sair da sessão.',
			'watchTogether.endSessionConfirmOverlay' => 'Isso vai encerrar o Assistir juntos para todo mundo.',
			'watchTogether.leaveSessionConfirmOverlay' => 'Você vai sair do Assistir juntos.',
			'watchTogether.end' => 'Encerrar',
			'watchTogether.leave' => 'Sair',
			'watchTogether.syncing' => 'Sincronizando...',
			'watchTogether.joinWatchSession' => 'Entrar na sessão',
			'watchTogether.enterCodeHint' => 'Digite o código de 5 letras e números',
			'watchTogether.pasteFromClipboard' => 'Colar',
			'watchTogether.pleaseEnterCode' => 'Digite o código da sessão',
			'watchTogether.codeMustBe5Chars' => 'O código da sessão tem 5 letras e números',
			'watchTogether.joinInstructions' => 'Digite o código que o anfitrião passou para entrar.',
			'watchTogether.failedToCreate' => 'Não deu para criar a sessão. Confira a internet e tente de novo.',
			'watchTogether.failedToJoin' => 'Não deu para entrar na sessão. Confira o código e tente de novo.',
			'watchTogether.sessionCodeCopied' => 'Código da sessão copiado',
			'watchTogether.relayUnreachable' => 'Não deu para falar com o servidor do Assistir juntos. Sua operadora de internet pode estar bloqueando.',
			'watchTogether.reconnectingToHost' => 'Reconectando ao anfitrião...',
			'watchTogether.currentPlayback' => 'O que está passando',
			'watchTogether.joinCurrentPlayback' => 'Ir para o que está passando',
			'watchTogether.joinCurrentPlaybackDescription' => 'Voltar para o que o anfitrião está assistindo agora',
			'watchTogether.failedToOpenCurrentPlayback' => 'Não deu para abrir o que está passando. Tente de novo.',
			'watchTogether.participantJoined' => ({required Object name}) => '${name} entrou',
			'watchTogether.participantLeft' => ({required Object name}) => '${name} saiu',
			'watchTogether.participantPaused' => ({required Object name}) => '${name} pausou',
			'watchTogether.participantResumed' => ({required Object name}) => '${name} continuou',
			'watchTogether.participantSeeked' => ({required Object name}) => '${name} avançou ou voltou o vídeo',
			'watchTogether.participantChangedSpeed' => ({required Object name, required Object speed}) => '${name} mudou a velocidade para ${speed}',
			'watchTogether.participantBuffering' => ({required Object name}) => '${name} está carregando o vídeo',
			'watchTogether.participantNeedsUpdate' => ({required Object name}) => '${name} está com uma versão antiga do app — precisa atualizar para assistirem juntos',
			'watchTogether.resumingWithout' => ({required Object name}) => 'Continuando sem ${name}',
			'watchTogether.waitingForParticipants' => 'Esperando os outros carregarem o vídeo...',
			'watchTogether.waitingForName' => ({required Object name}) => 'Esperando ${name}...',
			'watchTogether.recentRooms' => 'Salas recentes',
			'watchTogether.renameRoom' => 'Renomear sala',
			'watchTogether.removeRoom' => 'Remover',
			'watchTogether.guestSwitchUnavailable' => 'Não deu para trocar — o servidor não está disponível',
			'watchTogether.guestSwitchFailed' => 'Não deu para trocar — este título não está no seu servidor',
			'watchTogether.defaultDisplayName' => 'Usuário',
			'watchTogether.errors.timedOut' => 'O servidor do Assistir juntos demorou demais para responder. Tente de novo.',
			'watchTogether.errors.connectionLost' => 'A conexão caiu antes de a sessão ficar pronta. Tente de novo.',
			'watchTogether.errors.invalidRelayResponse' => 'O servidor do Assistir juntos respondeu algo inesperado. Tente de novo.',
			'watchTogether.errors.sessionEnded' => 'O anfitrião encerrou a sessão',
			'watchTogether.errors.sessionUnavailable' => 'Não deu para voltar a esta sessão. Entre em uma sala ou crie uma nova.',
			'downloads.title' => 'Baixados',
			'downloads.manage' => 'Organizar',
			'downloads.tvShows' => 'Séries',
			'downloads.movies' => 'Filmes',
			'downloads.music' => 'Música',
			'downloads.tracksQueued' => ({required Object count}) => '${count} faixas na fila para baixar',
			'downloads.noDownloads' => 'Nada baixado ainda',
			'downloads.noDownloadsDescription' => 'O que você baixar aparece aqui para assistir sem internet',
			'downloads.downloadNow' => 'Baixar',
			'downloads.deleteDownload' => 'Apagar baixado',
			'downloads.retryDownload' => 'Tentar baixar de novo',
			'downloads.downloadQueued' => 'Na fila para baixar',
			'downloads.downloadResumed' => 'Voltou a baixar',
			'downloads.serverErrorBitrate' => 'Erro no servidor: o arquivo pode passar do limite de qualidade permitido fora de casa',
			'downloads.storageFull' => 'Paramos de baixar para não lotar a memória do aparelho. Libere espaço ou escolha outra pasta e tente de novo.',
			'downloads.storageUnavailable' => 'Paramos de baixar porque não deu para conferir o espaço livre. Confira a pasta dos baixados e tente de novo.',
			'downloads.episodesQueued' => ({required Object count}) => '${count} episódios na fila para baixar',
			'downloads.downloadDeleted' => 'Baixado apagado',
			'downloads.deleteConfirm' => ({required Object title}) => 'Apagar "${title}" deste aparelho?',
			'downloads.cancelledDownloadTitle' => 'Download cancelado',
			'downloads.cancelledDownloadMessage' => 'Este download foi cancelado. O que você quer fazer?',
			'downloads.allEpisodesAlreadyDownloaded' => 'Todos os episódios já foram baixados',
			'downloads.resumeDownload' => 'Continuar baixando',
			'downloads.cancelledDownload' => 'Download cancelado',
			'downloads.syncingFile' => ({required Object file, required Object status}) => '${file} (atualizando ${status})',
			'downloads.downloadedFileClickToComplete' => ({required Object file}) => '${file} baixado — toque para concluir',
			'downloads.partialDownloadClickToComplete' => 'Baixado em parte — toque para concluir',
			'downloads.deleting' => 'Apagando...',
			'downloads.deletingWithProgress' => ({required Object title, required Object current, required Object total}) => 'Apagando ${title}... (${current} de ${total})',
			'downloads.queuedTooltip' => 'Na fila',
			'downloads.queuedFilesTooltip' => ({required Object files}) => 'Na fila: ${files}',
			'downloads.downloadingTooltip' => 'Baixando...',
			'downloads.downloadingFilesTooltip' => ({required Object files}) => 'Baixando ${files}',
			'downloads.noDownloadsTree' => 'Nada baixado',
			'downloads.pauseAll' => 'Pausar todos',
			'downloads.resumeAll' => 'Continuar todos',
			'downloads.deleteAll' => 'Apagar todos',
			'downloads.selectVersion' => 'Escolher versão',
			'downloads.allEpisodes' => 'Todos os episódios',
			'downloads.unwatchedOnly' => 'Só não assistidos',
			'downloads.nextNUnwatched' => ({required Object count}) => 'Próximos ${count} episódios não assistidos',
			'downloads.customAmount' => 'Outra quantidade...',
			'downloads.includeSpecials' => 'Incluir especiais',
			'downloads.howManyEpisodes' => 'Quantos episódios?',
			'downloads.invalidEpisodeCount' => 'Digite uma quantidade válida de episódios.',
			'downloads.keepSynced' => 'Baixar novos sozinho',
			'downloads.downloadOnce' => 'Baixar uma vez',
			'downloads.keepNUnwatched' => ({required Object count}) => 'Manter ${count} episódios não assistidos baixados',
			'downloads.editSyncRule' => 'Editar download automático',
			'downloads.removeSyncRule' => 'Parar download automático',
			'downloads.removeSyncRuleConfirm' => ({required Object title}) => 'Parar de baixar "${title}" automaticamente? Os episódios já baixados continuam no aparelho.',
			'downloads.removeListSyncRuleConfirm' => ({required Object title}) => 'Parar de baixar "${title}" automaticamente?',
			'downloads.deleteSyncRuleDownloads' => 'Apagar também os baixados desta regra',
			'downloads.deleteSyncRuleDownloadsDescription' => 'Baixados usados por outra regra ou outro perfil continuam no aparelho.',
			'downloads.syncRuleCreated' => ({required Object count}) => 'Download automático ligado — mantendo ${count} episódios não assistidos',
			'downloads.syncRuleUpdated' => 'Download automático atualizado',
			'downloads.syncRuleRemoved' => 'Download automático desligado',
			'downloads.syncRuleAndDownloadsRemoved' => 'Download automático desligado e baixados apagados',
			'downloads.syncRuleCleanupBusy' => 'Os downloads automáticos estão sendo atualizados. Tente de novo daqui a pouco.',
			'downloads.syncRuleCleanupUnavailable' => 'Não deu para saber com segurança quais baixados são desta regra. Conecte o servidor de novo e tente outra vez, ou desligue a regra sem apagar os baixados.',
			'downloads.syncedNewEpisodes' => ({required Object count, required Object title}) => '${count} episódios novos de ${title} baixados',
			'downloads.activeSyncRules' => 'Downloads automáticos',
			'downloads.noSyncRules' => 'Nenhum download automático',
			'downloads.manageSyncRule' => 'Ajustar download automático',
			'downloads.editEpisodeCount' => 'Número de episódios',
			'downloads.editSyncFilter' => 'O que baixar',
			'downloads.syncAllItems' => 'Baixando todos os itens',
			'downloads.syncUnwatchedItems' => 'Baixando os não assistidos',
			'downloads.syncRuleServerContext' => ({required Object server, required Object status}) => 'Servidor: ${server} • ${status}',
			'downloads.syncRuleAvailable' => 'Disponível',
			'downloads.syncRuleOffline' => 'Sem conexão',
			'downloads.syncRuleSignInRequired' => 'Precisa entrar de novo',
			'downloads.syncRuleAccessDenied' => 'Acesso negado',
			'downloads.syncRuleNotAvailableForProfile' => 'Indisponível para este perfil',
			'downloads.syncRuleUnknownServer' => 'Servidor desconhecido',
			'downloads.syncRuleListCreated' => 'Download automático ligado',
			'downloads.backgroundWarning.bannerBlocked' => 'Os downloads vão parar quando você sair do app',
			'downloads.backgroundWarning.bannerDegraded' => 'Os downloads com o app fechado podem ficar lentos ou parar',
			'downloads.backgroundWarning.bannerAction' => 'Detalhes',
			'downloads.backgroundWarning.sheetTitle' => 'Os downloads com o app fechado estão bloqueados',
			'downloads.backgroundWarning.sheetTitleDegraded' => 'Os downloads com o app fechado podem ficar lentos ou parar',
			'downloads.backgroundWarning.sheetIntro' => 'O Android está impedindo o CGFLIX de baixar direito com o app fechado.',
			'downloads.backgroundWarning.sheetIntroDegraded' => 'Seu aparelho está limitando quando o CGFLIX pode baixar com o app fechado.',
			'downloads.backgroundWarning.reasonBackgroundRestricted' => 'O CGFLIX está com o uso em segundo plano restrito. Mude o uso da bateria (ou uso em segundo plano) para "Sem restrições".',
			'downloads.backgroundWarning.reasonStandbyRestricted' => 'O Android colocou o CGFLIX em modo de espera restrito. Mude o uso da bateria para "Sem restrições".',
			'downloads.backgroundWarning.reasonDownloadChannelBlocked' => 'As notificações de download estão desligadas, então o progresso e os botões podem não aparecer.',
			'downloads.backgroundWarning.reasonNotificationsDisabled' => 'As notificações estão desligadas. No Android 13 ou mais novo, elas são necessárias para baixar com o app fechado.',
			'downloads.backgroundWarning.reasonDataSaver' => 'A Economia de dados está ligada e bloqueia downloads com o app fechado nos dados móveis. No Wi-Fi deve funcionar normalmente.',
			'downloads.backgroundWarning.reasonOemUnknown' => 'Os downloads pararam várias vezes com o CGFLIX em segundo plano. Confira as configurações de bateria e de uso em segundo plano do CGFLIX.',
			'downloads.backgroundWarning.openSettings' => 'Abrir configurações',
			'downloads.backgroundWarning.stillNotWorking' => 'Ajuda para o seu aparelho',
			'downloads.backgroundWarning.stillNotWorkingDescription' => 'Veja as instruções para o seu aparelho ou, se continuar, envie os registros em Configurações › Ver registros (logs).',
			'downloads.backgroundWarning.dialogTitle' => 'Os downloads podem não terminar',
			'downloads.backgroundWarning.dialogDownloadAnyway' => 'Baixar mesmo assim',
			'downloads.backgroundWarning.dialogFixFirst' => 'Resolver antes',
			'downloads.backgroundWarning.statusTile' => 'Baixar com o app fechado',
			'downloads.backgroundWarning.statusOk' => 'Permitido baixar com o app fechado',
			'downloads.backgroundWarning.statusBlocked' => 'Bloqueado pelas configurações do aparelho',
			'downloads.backgroundWarning.statusDegraded' => 'Limitado pelas configurações do aparelho',
			'downloads.backgroundWarning.statusUnknown' => 'Ainda não conferido',
			'downloads.backgroundWarning.settingsUnavailable' => 'Não deu para abrir as configurações do aparelho',
			'downloads.backgroundWarning.linkUnavailable' => 'Não deu para abrir dontkillmyapp.com neste aparelho',
			'downloads.options' => 'Opções dos baixados',
			'downloads.groupings.library' => 'Biblioteca',
			'downloads.unknownLibrary' => 'Biblioteca desconhecida',
			'downloads.unknownShow' => 'Série desconhecida',
			'downloads.unknownSeason' => 'Temporada desconhecida',
			'downloads.unknownAlbum' => 'Álbum desconhecido',
			'downloads.completedOfTotal' => ({required Object completed, required Object total}) => '${completed}/${total} concluídos',
			'downloads.errorFileNotFound' => 'Arquivo não encontrado no servidor (404)',
			'downloads.errorDownloadNotAllowed' => 'O servidor não permite baixar este item (403)',
			'downloads.errorDownloadFailed' => 'Não deu para baixar. Confira a internet e tente de novo.',
			'downloads.errorDownloadFailedWithReason' => ({required Object reason}) => 'Não deu para baixar: ${reason}',
			'downloads.errorHttpStatus' => ({required Object status}) => 'Não deu para baixar (erro ${status})',
			'downloads.errorPostProcessing' => ({required Object reason}) => 'Não deu para finalizar o arquivo baixado: ${reason}',
			'downloads.reasonFileNotSaved' => 'não deu para salvar o arquivo neste aparelho',
			'downloads.reasonCannotResume' => 'não deu para continuar de onde parou',
			'downloads.reasonDeviceStorageFull' => 'o aparelho está sem espaço',
			'downloads.notificationDownloading' => 'Baixando...',
			'downloads.notificationComplete' => 'Download concluído',
			'downloads.notificationPaused' => 'Download pausado',
			'shaders.title' => 'Filtros de imagem',
			'shaders.noShaderDescription' => 'Sem melhoria de imagem',
			'shaders.nvscalerDescription' => 'Ampliação de imagem da NVIDIA para vídeos mais nítidos',
			'shaders.artcnnVariantNeutral' => 'Neutro',
			'shaders.artcnnVariantDenoise' => 'Redução de ruído',
			'shaders.artcnnVariantDenoiseSharpen' => 'Redução de ruído + nitidez',
			'shaders.qualityFast' => 'Rápido',
			'shaders.qualityHQ' => 'Alta qualidade',
			'shaders.mode' => 'Modo',
			'shaders.importShader' => 'Importar filtro',
			'shaders.customShaderDescription' => 'Filtro GLSL personalizado',
			'shaders.shaderImported' => 'Filtro importado',
			'shaders.shaderImportFailed' => 'Não deu para importar o filtro. Confira o arquivo e tente de novo.',
			'shaders.deleteShader' => 'Excluir filtro',
			'shaders.deleteShaderConfirm' => ({required Object name}) => 'Excluir "${name}"?',
			'companionRemote.title' => 'Controle remoto',
			'companionRemote.connectedTo' => ({required Object name}) => 'Conectado a ${name}',
			'companionRemote.unknownDevice' => 'Aparelho desconhecido',
			'companionRemote.session.startingServer' => 'Ligando o controle remoto...',
			'companionRemote.session.hostAddress' => 'Endereço deste aparelho',
			'companionRemote.session.connected' => 'Conectado',
			'companionRemote.session.serverRunning' => 'Controle remoto ligado',
			'companionRemote.session.serverStopped' => 'Controle remoto desligado',
			'companionRemote.session.serverRunningDescription' => 'Celulares na sua rede Wi-Fi podem se conectar a este app',
			'companionRemote.session.serverStoppedDescription' => 'Ligue o controle remoto para que celulares possam se conectar',
			'companionRemote.session.usePhoneToControl' => 'Use seu celular para controlar este app',
			'companionRemote.session.startServer' => 'Ligar',
			'companionRemote.session.stopServer' => 'Desligar',
			'companionRemote.session.minimize' => 'Minimizar',
			'companionRemote.session.manualAddressHint' => 'Endereço para conectar manualmente:',
			'companionRemote.pairing.discoveryDescription' => 'Aparelhos com o CGFLIX na mesma conta Plex aparecem aqui',
			'companionRemote.pairing.hostAddressHint' => '192.168.1.100:48632',
			'companionRemote.pairing.connecting' => 'Conectando...',
			'companionRemote.pairing.searchingForDevices' => 'Procurando aparelhos...',
			'companionRemote.pairing.noDevicesFound' => 'Nenhum aparelho encontrado na sua rede',
			'companionRemote.pairing.noDevicesHint' => 'Abra o CGFLIX no computador e use a mesma rede Wi-Fi',
			'companionRemote.pairing.availableDevices' => 'Aparelhos disponíveis',
			'companionRemote.pairing.manualConnection' => 'Conectar manualmente',
			'companionRemote.pairing.cryptoInitFailed' => 'Não deu para iniciar a conexão segura. Entre no Plex primeiro.',
			'companionRemote.pairing.validationHostRequired' => 'Digite o endereço do aparelho',
			'companionRemote.pairing.validationHostFormat' => 'Use o formato IP:porta (ex.: 192.168.1.100:48632)',
			'companionRemote.pairing.connectionTimedOut' => 'O outro aparelho demorou demais para responder. Use a mesma rede Wi-Fi nos dois.',
			'companionRemote.pairing.sessionNotFound' => 'Aparelho não encontrado. Confira se o CGFLIX está aberto nele.',
			'companionRemote.pairing.authFailed' => 'Não deu para conectar. Os dois aparelhos precisam estar na mesma conta Plex.',
			'companionRemote.pairing.failedToConnect' => ({required Object error}) => 'Não deu para conectar: ${error}',
			'companionRemote.remote.disconnectConfirm' => 'Quer desconectar do controle remoto?',
			'companionRemote.remote.reconnecting' => 'Reconectando...',
			'companionRemote.remote.attemptOf' => ({required Object current}) => 'Tentativa ${current} de 5',
			'companionRemote.remote.retryNow' => 'Tentar agora',
			'companionRemote.remote.tabRemote' => 'Controle',
			'companionRemote.remote.tabPlay' => 'Assistir',
			'companionRemote.remote.tabMore' => 'Mais',
			'companionRemote.remote.menu' => 'Menu',
			'companionRemote.remote.tabNavigation' => 'Abas',
			'companionRemote.remote.tabDiscover' => 'Descobrir',
			'companionRemote.remote.tabLibraries' => 'Bibliotecas',
			'companionRemote.remote.tabSearch' => 'Buscar',
			'companionRemote.remote.tabDownloads' => 'Baixados',
			'companionRemote.remote.tabSettings' => 'Configurações',
			'companionRemote.remote.previous' => 'Anterior',
			'companionRemote.remote.playPause' => 'Reproduzir/pausar',
			'companionRemote.remote.next' => 'Próximo',
			'companionRemote.remote.seekBack' => 'Voltar',
			'companionRemote.remote.stop' => 'Parar',
			'companionRemote.remote.seekForward' => 'Avançar',
			'companionRemote.remote.volume' => 'Volume',
			'companionRemote.remote.volumeDown' => 'Diminuir',
			'companionRemote.remote.volumeUp' => 'Aumentar',
			'companionRemote.remote.fullscreen' => 'Tela cheia',
			'companionRemote.remote.subtitles' => 'Legendas',
			'companionRemote.remote.audio' => 'Áudio',
			'companionRemote.remote.searchHint' => 'Buscar no computador...',
			'companionRemote.errors.noNetworkInterface' => 'Nenhuma conexão de rede encontrada. Confira o Wi-Fi.',
			'companionRemote.errors.authenticationFailed' => 'Não deu para confirmar o acesso',
			'companionRemote.errors.serverStartFailed' => ({required Object error}) => 'Não deu para ligar o controle remoto: ${error}',
			'companionRemote.errors.commandFailed' => ({required Object error}) => 'Não deu para enviar o comando: ${error}',
			'companionRemote.errors.joinTimedOut' => 'Demorou demais para conectar. Tente de novo.',
			'companionRemote.errors.failedToConnectAnyAddress' => 'Não deu para conectar em nenhum endereço',
			'companionRemote.errors.connectionLostAfterAttempts' => ({required Object attempts}) => 'A conexão caiu depois de ${attempts} tentativas',
			'companionRemote.errors.connectionLost' => 'A conexão caiu',
			'companionRemote.closedBeforeAuth' => 'A conexão caiu antes de confirmar o acesso',
			'videoSettings.playbackSpeed' => 'Velocidade',
			'videoSettings.normalSpeed' => 'Normal',
			'videoSettings.sleepTimerActive' => ({required Object duration}) => 'Ligado (${duration})',
			'videoSettings.zoom' => 'Zoom',
			'videoSettings.sleepTimer' => 'Desligar automaticamente',
			'videoSettings.audioSync' => 'Atraso do áudio',
			'videoSettings.subtitleSync' => 'Atraso da legenda',
			'videoSettings.hdr' => 'HDR',
			'videoSettings.hdrUnsupported' => 'HDR não está disponível aqui — a tela ou o sistema do computador não é compatível.',
			'videoSettings.hdrToneMapping' => 'Ajuste de cores HDR',
			'videoSettings.hdrToneMappingCompositor' => 'Sistema',
			'videoSettings.hdrToneMappingCompositorDescription' => 'Mandar as informações de HDR do vídeo e deixar o sistema do computador ajustar as cores.',
			'videoSettings.hdrToneMappingPlayer' => 'Reprodutor',
			'videoSettings.hdrToneMappingPlayerDescription' => 'O reprodutor ajusta as cores para o brilho máximo da tela e avisa o sistema.',
			'videoSettings.hdrToneMappingFailed' => 'Não deu para mudar o ajuste de cores HDR — continua o modo anterior.',
			'videoSettings.audioOutput' => 'Saída de áudio',
			'videoSettings.performanceOverlay' => 'Informações técnicas na tela',
			'videoSettings.audioOutputDolbyAtmos' => 'Dolby Atmos',
			'videoSettings.audioOutputDolbyAudio' => 'Dolby Audio',
			'videoSettings.audioOutputSurround' => 'Surround',
			'videoSettings.audioOutputSpatial' => 'Áudio espacial',
			'videoSettings.audioOutputStereo' => 'Estéreo',
			'videoSettings.audioNormalization' => 'Nivelar volume',
			'videoSettings.audioNormalizationDisablesPassthrough' => 'Converte o áudio para PCM; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada',
			'videoSettings.audioNormalizationStereoMix' => 'Junta os canais de áudio em estéreo; o envio direto ao receptor fica desligado enquanto esta opção estiver ligada',
			'performanceOverlay.color' => 'Cor',
			'performanceOverlay.performance' => 'Desempenho',
			'performanceOverlay.buffer' => 'Memória de reprodução',
			'performanceOverlay.app' => 'App',
			'performanceOverlay.decoder' => 'Decodificador',
			'performanceOverlay.rawDecoder' => 'Decodificador bruto',
			'performanceOverlay.tunneling' => 'Túnel',
			'performanceOverlay.passthrough' => 'Envio direto',
			'performanceOverlay.aspect' => 'Aspecto',
			'performanceOverlay.rotation' => 'Rotação',
			'performanceOverlay.dvSource' => 'Fonte DV',
			'performanceOverlay.dvPath' => 'Caminho DV',
			'performanceOverlay.dvRouteDecoder' => 'Decodificador Dolby Vision',
			'performanceOverlay.dvRouteDecoderP81' => 'Decodificador Dolby Vision (P7→8.1)',
			'performanceOverlay.dvRouteBaseLayer' => 'Camada base',
			'performanceOverlay.dvRouteBaseLayerHdr10' => 'Camada base HDR10',
			'performanceOverlay.dvRouteBaseLayerHlg' => 'Camada base HLG',
			'performanceOverlay.dvRouteBaseLayerSdr' => 'Camada base SDR',
			'performanceOverlay.dvRouteReshaped' => 'RPU remodelada (gpu-next)',
			'performanceOverlay.p7Conversion' => 'Conv. P7',
			'performanceOverlay.sampleRate' => 'Taxa de amostragem',
			'performanceOverlay.pixelFormat' => 'Formato de pixel',
			'performanceOverlay.hwFormat' => 'Formato HW',
			'performanceOverlay.matrix' => 'Matriz',
			'performanceOverlay.primaries' => 'Primárias',
			'performanceOverlay.transfer' => 'Transferência',
			'performanceOverlay.renderFps' => 'FPS de renderização',
			'performanceOverlay.displayFps' => 'FPS da tela',
			'performanceOverlay.avSync' => 'Sincronia A/V',
			'performanceOverlay.dropped' => 'Descartados',
			'performanceOverlay.dvRpus' => 'DV RPUs',
			'performanceOverlay.dvRpuAverage' => 'Média DV RPU',
			'performanceOverlay.dvSampleAverage' => 'Média amostra DV',
			'performanceOverlay.maxLuma' => 'Luma máx.',
			'performanceOverlay.minLuma' => 'Luma mín.',
			'performanceOverlay.maxCll' => 'MaxCLL',
			'performanceOverlay.maxFall' => 'MaxFALL',
			'performanceOverlay.cacheUsed' => 'Memória temporária usada',
			'performanceOverlay.cacheLimit' => 'Limite da memória temporária',
			'performanceOverlay.speed' => 'Velocidade',
			'performanceOverlay.player' => 'Reprodutor',
			'performanceOverlay.memory' => 'Memória',
			'performanceOverlay.uiFps' => 'FPS da interface',
			'performanceOverlay.fps' => 'FPS',
			'performanceOverlay.decoderAndroidHw' => 'Android HW',
			'performanceOverlay.decoderNvidiaHw' => 'NVIDIA HW',
			'performanceOverlay.decoderQualcommHw' => 'Qualcomm HW',
			'performanceOverlay.decoderMediatekHw' => 'MediaTek HW',
			'performanceOverlay.decoderExynosHw' => 'Exynos HW',
			'performanceOverlay.decoderSoftware' => 'Software',
			'performanceOverlay.decoderHardware' => 'Hardware',
			'performanceOverlay.tunnelingActive' => 'Ligado',
			'performanceOverlay.dvRpuFailed' => ({required Object converted, required Object failures}) => '${converted} (${failures} com falha)',
			'externalPlayer.title' => 'Reprodutor externo',
			'externalPlayer.useExternalPlayer' => 'Usar reprodutor externo',
			'externalPlayer.useExternalPlayerDescription' => 'Abrir os vídeos em outro app',
			'externalPlayer.selectPlayer' => 'Escolher reprodutor',
			'externalPlayer.customPlayers' => 'Reprodutores personalizados',
			'externalPlayer.systemDefault' => 'Padrão do sistema',
			'externalPlayer.addCustomPlayer' => 'Adicionar reprodutor personalizado',
			'externalPlayer.playerName' => 'Nome do reprodutor',
			'externalPlayer.playerNameHint' => 'Meu reprodutor',
			'externalPlayer.playerCommand' => 'Comando',
			'externalPlayer.playerPackage' => 'Nome do pacote',
			'externalPlayer.playerUrlScheme' => 'Esquema de endereço (URL)',
			'externalPlayer.off' => 'Desligado',
			'externalPlayer.launchFailed' => 'Não deu para abrir o reprodutor externo. Confira se ele está instalado.',
			'externalPlayer.appNotInstalled' => ({required Object name}) => '${name} não está instalado',
			'externalPlayer.playInExternalPlayer' => 'Assistir no reprodutor externo',
			'metadataEdit.editMetadata' => 'Editar...',
			'metadataEdit.screenTitle' => 'Editar informações',
			'metadataEdit.basicInfo' => 'Informações básicas',
			'metadataEdit.artwork' => 'Imagens',
			'metadataEdit.advancedSettings' => 'Configurações avançadas',
			'metadataEdit.title' => 'Título',
			'metadataEdit.sortTitle' => 'Título para ordenar',
			'metadataEdit.originalTitle' => 'Título original',
			'metadataEdit.releaseDate' => 'Data de lançamento',
			'metadataEdit.contentRating' => 'Classificação indicativa',
			'metadataEdit.studio' => 'Estúdio',
			'metadataEdit.tagline' => 'Slogan',
			'metadataEdit.summary' => 'Sinopse',
			'metadataEdit.poster' => 'Pôster',
			'metadataEdit.background' => 'Imagem de fundo',
			'metadataEdit.logo' => 'Logo',
			'metadataEdit.squareArt' => 'Imagem quadrada',
			'metadataEdit.selectPoster' => 'Escolher pôster',
			'metadataEdit.selectBackground' => 'Escolher imagem de fundo',
			'metadataEdit.selectLogo' => 'Escolher logo',
			'metadataEdit.selectSquareArt' => 'Escolher imagem quadrada',
			'metadataEdit.fromUrl' => 'De um endereço (URL)',
			'metadataEdit.uploadFile' => 'Enviar arquivo',
			'metadataEdit.enterImageUrl' => 'Digite o endereço da imagem',
			'metadataEdit.imageUrl' => 'Endereço da imagem',
			'metadataEdit.metadataUpdated' => 'Informações atualizadas',
			'metadataEdit.metadataUpdateFailed' => 'Não deu para atualizar as informações. Tente de novo.',
			'metadataEdit.artworkUpdated' => 'Imagem atualizada',
			'metadataEdit.artworkUpdateFailed' => 'Não deu para atualizar a imagem. Tente de novo.',
			'metadataEdit.noArtworkAvailable' => 'Nenhuma imagem disponível',
			'metadataEdit.artworkOption' => ({required Object index}) => 'Opção de imagem ${index}',
			'metadataEdit.selectedArtworkOption' => ({required Object index}) => 'Opção de imagem ${index}, selecionada',
			'metadataEdit.notSet' => 'Não definido',
			'metadataEdit.libraryDefault' => 'Padrão da biblioteca',
			'metadataEdit.accountDefault' => 'Padrão da conta',
			'metadataEdit.seriesDefault' => 'Padrão da série',
			'metadataEdit.episodeSorting' => 'Ordem dos episódios',
			'metadataEdit.oldestFirst' => 'Mais antigos primeiro',
			'metadataEdit.newestFirst' => 'Mais recentes primeiro',
			'metadataEdit.keep' => 'Manter',
			'metadataEdit.allEpisodes' => 'Todos os episódios',
			'metadataEdit.latestEpisodes' => ({required Object count}) => '${count} episódios mais recentes',
			'metadataEdit.latestEpisode' => 'Episódio mais recente',
			'metadataEdit.episodesAddedPastDays' => ({required Object count}) => 'Episódios adicionados nos últimos ${count} dias',
			'metadataEdit.deleteAfterPlaying' => 'Apagar episódios depois de assistir',
			'metadataEdit.never' => 'Nunca',
			'metadataEdit.afterADay' => 'Depois de um dia',
			'metadataEdit.afterAWeek' => 'Depois de uma semana',
			'metadataEdit.afterAMonth' => 'Depois de um mês',
			'metadataEdit.onNextRefresh' => 'Na próxima atualização',
			'metadataEdit.seasons' => 'Temporadas',
			'metadataEdit.show' => 'Mostrar',
			'metadataEdit.hide' => 'Ocultar',
			'metadataEdit.episodeOrdering' => 'Ordem dos episódios',
			'metadataEdit.tmdbAiring' => 'The Movie Database (exibição)',
			'metadataEdit.tvdbAiring' => 'TheTVDB (exibição)',
			'metadataEdit.tvdbAbsolute' => 'TheTVDB (absoluta)',
			'metadataEdit.metadataLanguage' => 'Idioma das informações',
			'metadataEdit.useOriginalTitle' => 'Usar título original',
			'metadataEdit.preferredAudioLanguage' => 'Idioma de áudio preferido',
			'metadataEdit.preferredSubtitleLanguage' => 'Idioma de legenda preferido',
			'metadataEdit.subtitleMode' => 'Quando mostrar legendas',
			'metadataEdit.manuallySelected' => 'Só quando eu escolher',
			'metadataEdit.shownWithForeignAudio' => 'Quando o áudio for estrangeiro',
			'metadataEdit.alwaysEnabled' => 'Sempre ligadas',
			'metadataEdit.tags' => 'Tags',
			'metadataEdit.addTag' => 'Adicionar tag',
			'metadataEdit.genre' => 'Gênero',
			'metadataEdit.director' => 'Diretor',
			'metadataEdit.writer' => 'Roteirista',
			'metadataEdit.producer' => 'Produtor',
			'metadataEdit.country' => 'País',
			'metadataEdit.collection' => 'Coleção',
			'metadataEdit.label' => 'Rótulo',
			'metadataEdit.quickTag' => 'Tag rápida...',
			'matchScreen.match' => 'Identificar...',
			'matchScreen.fixMatch' => 'Corrigir identificação...',
			'matchScreen.unmatch' => 'Remover identificação',
			'matchScreen.unmatchConfirm' => 'Remover a identificação deste item? O Plex vai tratá-lo como não identificado até você identificar de novo.',
			'matchScreen.unmatchSuccess' => 'Identificação removida',
			'matchScreen.unmatchFailed' => 'Não deu para remover a identificação. Tente de novo.',
			'matchScreen.matchApplied' => 'Identificação aplicada',
			'matchScreen.matchFailed' => 'Não deu para aplicar a identificação. Tente de novo.',
			'matchScreen.titleHint' => 'Título',
			'matchScreen.yearHint' => 'Ano',
			'matchScreen.search' => 'Buscar',
			'matchScreen.noMatchesFound' => 'Nada encontrado',
			'serverTasks.title' => 'Tarefas do servidor',
			'serverTasks.failedToLoad' => 'Não deu para carregar as tarefas. Tente de novo.',
			'serverTasks.noTasks' => 'Nenhuma tarefa em execução',
			'trakt.title' => 'Trakt',
			'trakt.connected' => 'Conectado',
			'trakt.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'trakt.disconnectConfirm' => 'Desconectar a conta do Trakt?',
			'trakt.disconnectConfirmBody' => 'O CGFLIX vai parar de enviar ao Trakt o que você assiste. Você pode conectar de novo quando quiser.',
			'trakt.scrobble' => 'Marcar como assistido em tempo real',
			'trakt.scrobbleDescription' => 'Avisa o Trakt quando você começa, pausa ou para um vídeo.',
			'trakt.watchedSync' => 'Sincronizar o que foi assistido',
			'trakt.watchedSyncDescription' => 'O que você marcar como assistido no CGFLIX também fica marcado no Trakt.',
			'seerr.title' => 'Seerr',
			'seerr.connectTitle' => 'Conectar ao Seerr',
			'seerr.serverUrl' => 'Endereço do servidor',
			'seerr.serverUrlHelper' => 'O endereço do seu Seerr',
			'seerr.checkServer' => 'Continuar',
			'seerr.signInWithJellyfin' => 'Entrar com Jellyfin',
			'seerr.signInWithEmby' => 'Entrar com Emby',
			'seerr.signInWithLocal' => 'Usar uma conta do próprio Seerr',
			'seerr.email' => 'E-mail',
			'seerr.noSignInMethods' => 'Este Seerr não tem nenhuma forma de entrar que funcione com o CGFLIX.',
			'seerr.instance' => 'Servidor',
			'seerr.disconnectConfirm' => 'Desconectar Seerr?',
			'seerr.disconnectConfirmBody' => 'O CGFLIX vai esquecer este Seerr. Você pode conectar de novo quando quiser.',
			'seerr.request' => 'Pedir',
			'seerr.request4k' => 'Pedir em 4K',
			'seerr.seasons' => 'Temporadas',
			'seerr.allSeasons' => 'Todas as temporadas',
			'seerr.advancedOptions' => 'Opções avançadas',
			'seerr.destinationServer' => 'Servidor de destino',
			'seerr.qualityProfile' => 'Perfil de qualidade',
			'seerr.rootFolder' => 'Pasta raiz',
			'seerr.languageProfile' => 'Perfil de idioma',
			'seerr.tags' => 'Etiquetas',
			'seerr.noTags' => 'Sem etiquetas',
			'seerr.defaultOption' => ({required Object name}) => '${name} (padrão)',
			'seerr.animeNote' => 'Esta série é um anime.',
			'seerr.requestSubmitted' => 'Pedido enviado',
			'seerr.requestFailed' => ({required Object error}) => 'Não deu para enviar o pedido: ${error}',
			'seerr.requestsLoadFailed' => 'Não deu para carregar as opções do pedido. Tente de novo.',
			'seerr.nothingToRequest' => 'Tudo já está disponível ou já foi pedido.',
			'seerr.statusAvailable' => 'Disponível',
			'seerr.statusPartiallyAvailable' => 'Parcialmente disponível',
			'seerr.statusRequested' => 'Pedido',
			'seerr.statusProcessing' => 'Em preparo',
			'seerr.statusBlocklisted' => 'Bloqueado',
			'seerr.couldNotReach' => ({required Object url, required Object error}) => 'Não deu para falar com ${url}: ${error}',
			'seerr.noInstanceAtUrl' => ({required Object url, required Object status}) => 'Nenhum Seerr encontrado em ${url} (erro ${status})',
			'seerr.behindAuthProxy' => 'Um sistema de login (SSO ou senha HTTP) respondeu no lugar do Seerr, e o CGFLIX não consegue passar por ele. Peça ao responsável pelo servidor para liberar o caminho /api/v1 do Seerr, ou use um endereço que chegue direto ao Seerr.',
			'seerr.invalidUrl' => 'Digite um endereço de servidor, por exemplo https://seerr.example.com',
			'seerr.quickConnectUnsupported' => 'Este Seerr não aceita Quick Connect. Ele precisa do Seerr 3.4 ou mais novo.',
			'seerr.notInitialized' => 'Este Seerr ainda não terminou a configuração inicial',
			'seerr.noPlexTokenForReauth' => 'Não há acesso do Plex salvo para entrar de novo',
			'seerr.noStoredCredentials' => 'Não há dados de acesso salvos para entrar de novo',
			'seerr.signInRejected' => 'O acesso foi recusado. Confira os dados e tente de novo.',
			'seerr.noSessionCookie' => 'O Seerr não confirmou o acesso. Tente entrar de novo.',
			'seerr.freshCookieRejected' => 'O Seerr recusou o novo acesso. Tente entrar de novo.',
			'seerr.noUserInformation' => 'O Seerr não mandou as informações do usuário',
			'seerr.sessionRejectedAfterReauth' => 'O acesso foi recusado mesmo depois de entrar de novo',
			'seerr.permissionDenied' => 'O Seerr não deixou fazer isso: sua conta não tem mais essa permissão',
			'seerr.permissionRevoked' => 'Você não tem mais permissão para pedir isso',
			'services.title' => 'Serviços',
			'services.hubSubtitle' => 'Sincronize o que você assistiu e peça novos títulos.',
			'services.integrations' => 'Integrações',
			'services.notConnected' => 'Não conectado',
			'services.connectedAs' => ({required Object username}) => 'Conectado como @${username}',
			'services.scrobble' => 'Marcar como assistido automaticamente',
			'services.scrobbleDescription' => 'Atualiza sua lista quando você termina um episódio ou filme.',
			'services.disconnectConfirm' => ({required Object service}) => 'Desconectar ${service}?',
			'services.disconnectConfirmBody' => ({required Object service}) => 'O CGFLIX vai parar de atualizar o ${service}. Você pode conectar de novo quando quiser.',
			'services.connectFailed' => ({required Object service}) => 'Não deu para conectar ao ${service}. Confira a internet e tente de novo.',
			'services.names.mal' => 'MyAnimeList',
			'services.names.anilist' => 'AniList',
			'services.names.simkl' => 'Simkl',
			'services.names.seerr' => 'Seerr',
			'services.names.mdblist' => 'MDBList',
			'services.simklReconnect.title' => 'Reconectar o Simkl',
			'services.simklReconnect.subtitle' => 'O Simkl vai desativar o tipo de login desta conexão. Reconectar abre o simkl.com para você autorizar o CGFLIX — o CGFLIX nunca vê a sua senha. Seu histórico continua no Simkl.',
			'services.deviceCode.title' => ({required Object service}) => 'Ativar o CGFLIX no ${service}',
			'services.deviceCode.instructions' => 'Leia o código QR ou abra o endereço abaixo e digite este código:',
			'services.deviceCode.openToActivate' => ({required Object service}) => 'Abrir ${service} para ativar',
			_ => null,
		} ?? switch (path) {
			'services.deviceCode.copyCode' => 'Copiar código de ativação',
			'services.deviceCode.waitingForAuthorization' => 'Esperando a autorização…',
			'services.deviceCode.codeCopied' => 'Código copiado',
			'services.oauthProxy.title' => ({required Object service}) => 'Entrar no ${service}',
			'services.oauthProxy.body' => 'Leia este código QR ou abra o endereço em qualquer aparelho.',
			'services.oauthProxy.openToSignIn' => ({required Object service}) => 'Abrir ${service} para entrar',
			'services.pendingAuth.copyUrl' => 'Copiar endereço de acesso',
			'services.pendingAuth.urlCopied' => 'Endereço copiado',
			'services.libraryFilter.title' => 'Filtro de bibliotecas',
			'services.libraryFilter.subtitleAllSyncing' => 'Sincronizando todas as bibliotecas',
			'services.libraryFilter.subtitleNoneSyncing' => 'Nada a sincronizar',
			'services.libraryFilter.subtitleBlocked' => ({required Object count}) => '${count} bloqueadas',
			'services.libraryFilter.subtitleAllowed' => ({required Object count}) => '${count} permitidas',
			'services.libraryFilter.mode' => 'Modo de filtro',
			'services.libraryFilter.modeBlacklist' => 'Lista de bloqueio',
			'services.libraryFilter.modeWhitelist' => 'Lista de permissões',
			'services.libraryFilter.modeHintBlacklist' => 'Sincronizar todas as bibliotecas, exceto as marcadas abaixo.',
			'services.libraryFilter.modeHintWhitelist' => 'Sincronizar só as bibliotecas marcadas abaixo.',
			'services.libraryFilter.libraries' => 'Bibliotecas',
			'services.libraryFilter.noLibraries' => 'Nenhuma biblioteca disponível',
			'addServer.addMediaBrowserTitle' => ({required Object product}) => 'Adicionar servidor ${product}',
			'addServer.serverUrls' => 'Endereços do servidor',
			'addServer.serverUrlsHelper' => 'Pode colocar mais de um endereço, separados por vírgula.',
			'addServer.findServer' => 'Encontrar servidor',
			'addServer.searchingLocalMediaBrowserServers' => ({required Object product}) => 'Procurando servidores ${product} na sua rede...',
			'addServer.localMediaBrowserServers' => ({required Object product}) => 'Servidores ${product} na sua rede',
			'addServer.username' => 'Usuário',
			'addServer.password' => 'Senha',
			'addServer.signIn' => 'Entrar',
			'addServer.change' => 'Trocar',
			'addServer.required' => 'Obrigatório',
			'addServer.couldNotReachServer' => ({required Object error}) => 'Não deu para falar com o servidor (${error}). Confira o endereço e a internet.',
			'addServer.signInFailed' => ({required Object error}) => 'Não deu para entrar (${error}). Confira a internet e tente de novo.',
			'addServer.quickConnectFailed' => ({required Object error}) => 'Não deu para entrar com o Quick Connect (${error}). Tente de novo.',
			'addServer.addPlexTitle' => 'Entrar com Plex',
			'addServer.pinExpired' => 'O código expirou antes de você entrar. Tente de novo.',
			'addServer.failedToRegisterAccount' => ({required Object error}) => 'Não deu para salvar a conta neste aparelho (${error}). Tente de novo.',
			'addServer.enterMediaBrowserUrlError' => ({required Object product}) => 'Digite o endereço do seu servidor ${product}',
			'addServer.addConnectionTitle' => 'Adicionar conexão',
			'addServer.addConnectionTitleScoped' => ({required Object name}) => 'Adicionar a ${name}',
			'addServer.signInWithPlexCard' => 'Entrar com Plex',
			'addServer.signInWithPlexCardSubtitle' => 'Autorize este aparelho. Os servidores compartilhados com você são adicionados.',
			'addServer.signInWithPlexCardSubtitleScoped' => 'Autorize uma conta Plex. Os usuários do Plex Home viram perfis.',
			'addServer.connectToMediaBrowserCard' => ({required Object product}) => 'Entrar no ${product}',
			'addServer.connectToMediaBrowserCardSubtitle' => 'Digite o endereço do servidor, seu usuário e sua senha.',
			'addServer.connectToMediaBrowserCardSubtitleScoped' => ({required Object product, required Object name}) => 'Entre no seu servidor ${product}. Fica ligado a ${name}.',
			'addServer.borrowFromAnotherProfile' => 'Usar a conexão de outro perfil',
			'addServer.borrowFromAnotherProfileSubtitle' => 'Aproveite a conexão de outro perfil. Perfis com PIN pedem o PIN.',
			'addServer.invalidCredentials' => 'Usuário ou senha incorretos',
			'addServer.authResponseNotJson' => 'O servidor respondeu algo inesperado ao entrar. Confira o endereço.',
			'addServer.authResponseIncomplete' => 'O servidor respondeu pela metade ao entrar. Tente de novo.',
			'addServer.quickConnectRejected' => 'O servidor recusou o Quick Connect',
			'addServer.quickConnectNotJson' => 'O servidor respondeu algo inesperado no Quick Connect. Tente de novo.',
			'addServer.quickConnectMissingFields' => 'O servidor não mandou o código do Quick Connect. Tente de novo.',
			'addServer.quickConnectPollRejected' => 'O servidor recusou o Quick Connect enquanto esperava a aprovação',
			'addServer.serverTimedOut' => 'O servidor demorou demais para responder. Tente de novo.',
			'addServer.responseNotJson' => 'O servidor respondeu algo inesperado. Confira o endereço.',
			'addServer.responseMissingIdentity' => ({required Object product}) => 'A resposta não parece de um servidor ${product}. Confira o endereço.',
			'addServer.probeFailed' => ({required Object error}) => 'Não deu para falar com o servidor (${error}). Confira o endereço e a internet.',
			'addServer.enterAtLeastOneUrl' => ({required Object product}) => 'Digite pelo menos um endereço de servidor ${product}',
			'addServer.noReachableServer' => ({required Object product}) => 'Não deu para encontrar nenhum servidor ${product}. Confira o endereço e a internet.',
			'addServer.urlsPointToDifferentServers' => ({required Object product}) => 'Esses endereços levam a servidores ${product} diferentes',
			'addServer.urlDoesNotMatchServer' => ({required Object product}) => 'Este endereço não é deste servidor ${product}',
			'addServer.redirectUnsupported' => 'O servidor mandou para um endereço que não funciona aqui',
			'addServer.redirectDifferentHost' => ({required Object product}) => 'O servidor mandou para outro endereço. Digite direto o endereço final do ${product}.',
			'addServer.redirectInsecure' => 'O servidor mandou de HTTPS para um endereço sem segurança',
			'addServer.redirectUnsupportedEnterFinal' => ({required Object product}) => 'O servidor mandou para um endereço que não funciona aqui. Digite direto o endereço final do ${product}.',
			_ => null,
		};
	}
}
