// Vocabulário comum: Type = Movie/Series/Season/Episode/BoxSet; CollectionType = movies/tvshows/boxsets etc.
// Tempos SEMPRE em ticks de 100 ns; o adaptador Plex converterá de milissegundos.
// Id é string opaca (não exige UUID). ImageTags contém tags opacos, interpretados apenas pelo adaptador.
// BlurHash pode faltar. Os nomes atuais são preservados para não alterar as telas.
export type TipoServidor = 'jellyfin' | 'plex';
export type Servidor = { url: string; id: string; nome: string; versao?: string; tipo?: TipoServidor };
export type Sessao = {
  tipo: TipoServidor; servidor: string; token: string; usuarioId: string; nome: string;
  servidorId?: string; nomeServidor?: string; fotoTag?: string;
};
export type Hashes = Partial<Record<'Primary' | 'Backdrop' | 'Thumb' | 'Logo' | 'Banner', Record<string, string>>>;
export type Pessoa = { Id: string; Name: string; Role?: string; Type?: string; PrimaryImageTag?: string };
export type Capitulo = { Name?: string; StartPositionTicks: number };
export type Item = {
  Id: string; Name: string; Type: string; SeriesName?: string; SeriesId?: string; SeasonId?: string; SeasonName?: string;
  ProductionYear?: number; PremiereDate?: string; EndDate?: string; Status?: string; Overview?: string;
  ImageTags?: Record<string, string>; BackdropImageTags?: string[]; ImageBlurHashes?: Hashes;
  ParentBackdropItemId?: string; ParentBackdropImageTags?: string[]; ParentThumbItemId?: string; ParentThumbImageTag?: string;
  SeriesPrimaryImageTag?: string; ParentLogoItemId?: string; ParentLogoImageTag?: string; ParentId?: string;
  IndexNumber?: number; ParentIndexNumber?: number; CollectionType?: string; ChildCount?: number;
  OfficialRating?: string; CommunityRating?: number; RunTimeTicks?: number; Genres?: string[]; Taglines?: string[];
  Studios?: { Name: string }[]; People?: Pessoa[]; Chapters?: Capitulo[]; MediaStreams?: Fluxo[];
  UserData?: { PlayedPercentage?: number; Played?: boolean; PlaybackPositionTicks?: number; UnplayedItemCount?: number; IsFavorite?: boolean };
};

export type Usuario = { Id: string; Name: string; HasPassword?: boolean; PrimaryImageTag?: string;
  Policy?: { IsAdministrator?: boolean; EnableSubtitleManagement?: boolean } };
export type LegendaRemota = { Id: string; Name?: string; ProviderName?: string; Format?: string; DownloadCount?: number;
  ThreeLetterISOLanguageName?: string; IsHashMatch?: boolean; Comment?: string };
export type Fluxo = {
  Index: number; Type: 'Video' | 'Audio' | 'Subtitle' | string; Codec?: string; Language?: string; DisplayTitle?: string;
  Title?: string; IsDefault?: boolean; IsForced?: boolean; IsExternal?: boolean; IsTextSubtitleStream?: boolean;
  DeliveryMethod?: 'External' | 'Encode' | 'Embed' | 'Hls' | 'Drop'; DeliveryUrl?: string; Channels?: number; ChannelLayout?: string;
  Width?: number; Height?: number; Profile?: string; RealFrameRate?: number; AverageFrameRate?: number; BitRate?: number;
  VideoRange?: string; VideoRangeType?: string; SampleRate?: number; AspectRatio?: string; BitDepth?: number;
};
export type EmBreve = { nome: string; sub: string; capa: string; jf?: string; tmdb?: number; tipo: 'tv' | 'movie' };
