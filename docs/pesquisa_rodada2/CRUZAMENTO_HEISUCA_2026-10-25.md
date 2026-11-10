# Cruzamento: pesquisa de players (18/10) × app Heisuca (25/10)

Somente leitura. Código em `~/heisuca/apps/app/lib` (caminhos abaixo relativos a ele). Fontes: SINTESE_B (seções 3 e 4), SINTESE_C,
SINTESE_A/LICENCAS. TEM só com evidência em grep. "Herdado" = vem do Plezy (GPL-3.0), funciona, mas não foi desenhado por nós.
Licenças: Plezy, Findroid, Fladder, Plozz (GPL-3.0); Moonfin-Core (GPL-2.0-or-later); Moonfin Smart-TV, Streamyfin, Swiftfin, Litefin (MPL-2.0);
plex-mpv-shim (MIT); jellyfin-web (GPL-2.0-or-later). Wholphin, jellyfin-androidtv, Jellium, JellyCon, Roku (GPL-2.0 só): **só ideia**.
Forks do Android (en6ads, sinful1992, capische, almus2zhang) e Reefy: licença herdada do Android/AndroidTV (GPL-2.0 só) ou não verificada: tratar como **só ideia** até conferir.

## 1. Tabela

| # | Funcionalidade | Situação | Evidência / o que falta | Referência (licença) |
|---|---|---|---|---|
| 1 | Player nativo por plataforma (mpv no Android/iOS/desktop) | TEM (herdado) | `mpv/player/platform/player_android.dart:19`, `player_native.dart` | Plezy, Moonfin (GPL-3.0 / GPL-2.0+) |
| 1a | Fallback direct→remux→transcode explicado | PARCIAL | Só `playMethod` interno (`screens/video_player_screen.dart:1030`); sem frase de motivo para a pessoa | Moonfin, Litefin (GPL-2.0+ / MPL) |
| 2 | UI de TV para controle remoto | PARCIAL | D-pad e foco existem (`focus/dpad_navigator.dart:19`, 83 arquivos tratam TV); sem fileira "Continuar+Próximo" nem teclas coloridas; revisão de TV está na varredura "Depois (não agora)" do HANDOFF | Wholphin (só ideia), Moonfin Smart-TV (MPL) |
| 2a | Login por QR / digitar pelo celular | PARCIAL | Quick Connect (Jellyfin) e plex.tv/link (Plex); sem QR nem teclado pelo celular. Existe `screens/video_player/parts/companion_remote.dart` (controle remoto herdado) | Wholphin (só ideia), Moonfin |
| 3 | Passthrough de áudio | TEM (herdado) | `services/settings_service.dart:813`, `mpv/player/platform/player_android.dart:395` | Plezy; ATV beta.3 (só ideia) |
| 3a | Troca automática de taxa de quadros | TEM (herdado) | `screens/video_player/parts/display_matching.dart:12,75`, `frame_rate_matcher.dart`, `player_android.dart:533` | Plezy; Wholphin (só ideia) |
| 3b | HDR / Dolby Vision | PARCIAL | HDR: `display_matching.dart:181` (`enableHDR`). DV: só lê perfil (`media/media_stream.dart:32`, `services/jellyfin_mappers.dart:581`) e põe selo (`cgflix/cgflix_detail.dart:76`); sem tratamento de DV perfil 7 | Moonfin, en6ads (só ideia) |
| 3c | Lista de bugs por modelo de TV | NÃO TEM | `cgflix/cgflix_advanced.dart` e o medidor (etapa H/N3) medem o aparelho, mas não há tabela de bugs conhecidos | Swiftfin players.md (MPL) |
| 4 | Ajuste de sincronia de legenda e áudio | TEM | `widgets/video_controls/widgets/sync_offset_control.dart:20`, `services/player_sync_offsets.dart:25`, `video_settings_sheet.dart:596` | Plezy |
| 4a | Legenda dupla | TEM (herdado) | `player.supportsSecondarySubtitles` em `widgets/video_controls/sheets/track_sheet.dart:73`; `mpv/models.freezed.dart:1325` | Plezy |
| 4b | Busca/download de legenda no player | PARCIAL | Só Plex: `models/plex/plex_subtitle_search_result.dart`; Jellyfin sem | forks do Android (só ideia), Plezy |
| 4c | Escolha lembrada por série, casando idioma | PARCIAL | Idioma preferido da conta (`media/account_preferences.dart:19`, `cgflix/cgflix_config_itens.dart:212`); sem memória por série | Reefy (?), sinful1992 (só ideia) |
| 4d | ASS/PGS no cliente | TEM (mpv renderiza) | mpv/libass; estilo em `cgflix/cgflix_controles.dart`; etapa M prevê "legendas estilizadas" | Plezy |
| 5 | Pular abertura/créditos (botão ou auto) | TEM | `widgets/video_controls/parts/markers.dart:23`, `screens/settings/playback_settings_screen.dart:327`, `cgflix/cgflix_config_itens.dart:273`; padrão de intro por regex `cgflix_advanced.dart:109` | Plezy, Reefy |
| 5a | "Up next" com contagem | TEM | `screens/video_player/widgets/player_prompt_overlays.dart:200-203` (`autoPlayCountdown`), `media/account_preferences.dart:37` | Plezy, Wholphin (só ideia) |
| 5b | Fallback "últimos 2 min" sem marcador; "ainda está assistindo?" / limite de autoplay | NÃO TEM | nenhum termo no código (git grep de `stillWatching`, `autoplayLimit`) | Reefy, Wholphin (só ideia) |
| 6 | Downloads retomáveis, só no Wi-Fi | TEM (herdado) | `services/download_manager_service.dart:138,1730`, `cgflix/cgflix_defaults.dart:48` | Findroid, Plezy |
| 6a | Temporada/série inteira | PARCIAL | Serviço entende `MediaKind.season/show` (`download_manager_service.dart:3315`) e há "Baixar" no menu (`widgets/media_context_menu.dart:1781`); sem estimativa de espaço conferida nem regra "próximos N" | Findroid CE, JollyFin, Moonfin |
| 6b | Downloads transcodificados (qualidade/áudio) | NÃO TEM | `models/transcode_quality_preset.dart` existe só para reprodução; download baixa o original. Pilares dizem "reprodução direta sem transcodificação" | Moonfin, JellyCine (verificar licença) |
| 6c | Regras automáticas ("próximos N episódios") | NÃO TEM | sem grep de `autoDownload`/`keepNext` | JollyFin, Moonfin, Plezy |
| 6d | Progresso offline sincroniza na volta | TEM | `services/offline_watch_sync_service.dart:47` | Plezy |
| 7 | PIN por perfil | TEM (herdado) | `profiles/profile.dart:32` (`pinHash`), `main.dart:1263`, `screens/profile/profile_switch_screen.dart:282` | Plezy; Wholphin (só ideia) |
| 7a | Modo infantil com PIN e classificação | TEM (nosso) | `heisuca/kids/heisuca_kids_flow.dart:2`, `cgflix/home/cgflix_jellyfin_queries.dart:168` (`/__kids/ativar`), `cgflix/cgflix_palette.dart:18`. Depende de rota própria do servidor (armadilha C5). Refinos na etapa **G**; tema escuro infantil em "Depois" | Moonfin, ARVIO |
| 7b | Um device id por conta | NÃO CONFERIDO | não verificado no código (`services/jellyfin_client.dart:331` monta os cabeçalhos) | Streamyfin #1957 (MPL) |
| 8 | Stats for Nerds (codec, bitrate) | TEM (herdado) | `widgets/video_controls/widgets/performance_overlay/performance_stats_service.dart:158,163` | Plezy, Litefin |
| 8a | Motivo do transcode | NÃO TEM | ver 1a | thor2002ro, Litefin |
| 8b | Log compartilhável sem token | PARCIAL | Redação existe (`utils/log_redaction_manager.dart`, usado em `utils/app_logger.dart:68`); envio de logs/Sentry ainda ligado (`main.dart:280`, `pubspec.yaml:76`), a remover na etapa **L**/independência | en6ads (só ideia) |
| 8c | Tela de conexão explica o erro | PARCIAL | `cgflix/cgflix_login_checks.dart`, `exceptions/media_server_exceptions.dart`; etapa **N1** (sondar servidor) | drodriguez97 (?) |
| 9 | Jellyfin + Plex na mesma interface | TEM (nosso) | `heisuca/heisuca_source_scope.dart`, busca com origem (`heisuca_search_origin.dart`); etapa **C** (Início igual nas duas) | GMCA, Moonfin |
| 9a | Cabeçalhos HTTP personalizados / CA / mTLS | NÃO TEM | nenhum `customHeaders`; fixos em `services/jellyfin_client.dart:331` | Streamyfin, Fladder (GPL-3.0) |
| 10 | SyncPlay (Jellyfin) | NÃO TEM nativo; TEM alternativa | só o "Assistir juntos" herdado/próprio via relay `cgflix/cgflix_defaults.dart:39`, `screens/video_player/parts/watch_together.dart` | web (GPL-2.0+), Moonfin |
| 10a | Canais Android TV / Watch Next / Top Shelf | NÃO TEM | nenhum `WatchNext`/`PreviewChannel` em `lib` | Streamyfin (MPL), Tizen PR #319 (MPL) |
| 10b | Cast / transmissão para TV | DESCARTADO PELO CAIO | `cgflix/cgflix_dicas.dart:67` ("não manda o vídeo para a TV"); decisão registrada nos pilares | mpv-shim (GPL-3.0/MIT) |
| 10c | Teclas de mídia / tela de bloqueio | PLANEJADO | etapa **M** (MediaSession, notificação MediaStyle, PiP, "Continuar ouvindo ao sair") | Plezy (`os_media_controls`) |
| 10d | Discord, MAL/AniList | DESCARTADO PELO CAIO | `RETORNO_CAIO_2026-10-25.md` ("remover tudo"), `PILARES_HEISUCA.md` | (fora do escopo) |
| C-6 | Selos Dublado/Legendado, estilo de legenda | TEM | `cgflix/cgflix_detail.dart:57-77` | Infuse (fechado), Plezy |
| C-7 | Qualidade por tipo de rede (720p no celular) | NÃO TEM | ligado ao 6b | Plezy, Plozz (GPL-3.0) |
| C-10 | Desempenho medido no CI | PLANEJADO | etapas **K** (bancada Android) e **N3** (medir fluidez) | PlxNative, ARVIO |

## 2. Lacunas que valem a pena (por impacto para quem assiste)

1. **Motivo do transcode / erro de reprodução em frase curta** (1a, 8a): hoje a pessoa vê "falhou". Copiar de Moonfin/Litefin (GPL-2.0+/MPL); fork en6ads = só ideia.
2. **"Ainda está assistindo?" e limite de autoplay** (5b): evita maratona sem fim em criança e TV. Só ideia (Wholphin); o `autoPlayCountdown` do Plezy já serve de base.
3. **Download de temporada com estimativa de espaço e regra "próximos N episódios"** (6a, 6c): o serviço já entende temporada; falta a regra. Copiar de Plezy/Findroid CE (GPL-3.0); JollyFin e Moonfin como ideia (ver licença).
4. **Download com qualidade escolhida (celular/viagem)** (6b, C-7): maior economia de dados e espaço. Conflita com o pilar "reprodução direta"; **pedir decisão ao Caio** antes. Referência: Moonfin (GPL-2.0+), Plozz (GPL-3.0).
5. **Dolby Vision perfil 7 e lista de bugs por modelo de TV** (3b, 3c): TV Android é o aparelho da sala. Referência: Moonfin (GPL-2.0+), tabela do Swiftfin (MPL).
6. **Canais do Android TV / Continuar assistindo na tela inicial da TV** (10a): a pessoa abre a TV e vê o próximo episódio. Copiar do Streamyfin (MPL-2.0, arquivo-a-arquivo mantendo aviso).
7. **Escolha de áudio/legenda lembrada por série** (4c): evita refazer a cada episódio. Ideia do Reefy/sinful1992 (licença ?).
8. **Legenda: buscar/baixar no Jellyfin** (4b): hoje só no Plex. Referência: Plezy para o Plex; Jellyfin = forks do Android (só ideia).
9. **Login por QR / digitar pelo celular na TV** (2a): reduz o maior atrito de TV. Moonfin (GPL-2.0+) e Fladder (GPL-3.0); Wholphin só ideia.
10. **Log sem token + tirar Sentry** (8b): privacidade da família; já coberto pela independência (L). Plezy já redige; só remover envio.
11. **Cabeçalhos HTTP personalizados** (9a): útil se o acesso passar por proxy/Cloudflare. Fladder (GPL-3.0), Streamyfin (MPL).
12. **SyncPlay do Jellyfin** (10): hoje há relay próprio; o nativo funcionaria entre apps oficiais. Baixa prioridade: web (GPL-2.0+) e Moonfin como referência.

## 3. Armadilhas da seção 4 (SINTESE_B) e da C que o Heisuca ainda corre

1. **Licença (B-2)**: mitigada (fork do Plezy, GPL-3.0). Risco restante: copiar de Wholphin/Android/Roku (GPL-2.0 só) ou Mediora/Ghosten. Conferir antes de usar Reefy e forks. Aviso do Plezy na página de licenças: etapa **L**.
2. **Quebrar quem já usa (B-5)**: etapa **L** renomeia o pacote para `app.heisuca` e os canais `com.plezy/*`; se o `applicationId` mudar, perde-se a atualização por cima. O plano mantém o `applicationId`: cumprir. Migrar ajustes e perfis locais (`pinHash`) ao renomear canais.
3. **Firebase/Sentry/telemetria (B-5, C-5)**: `sentry_flutter` ainda no `pubspec.yaml:76` e iniciado em `main.dart:280`. Remover (L).
4. **Peça frágil fora do app (C-5)**: o modo infantil depende de `/__kids/ativar` no servidor (`cgflix_jellyfin_queries.dart:168`) e o "Assistir juntos" de `heisuca.docaio.com.br/junto` (`cgflix_defaults.dart:39`). Sem o serviço, cai em erro 404 (já tratado em `_cgflixRouteMissing`). Recuperação de PIN esquecido = sair da conta (REVISAO_CLAUDE 23/10).
5. **Mantenedor único e ritmo (B-4, C-2)**: fork independente sem upstream; sem testes de reprodução automáticos além da bancada (etapa **K**, ainda não feita). Falta um "playcheck" de reprodução real (direct/transcode, legenda ASS, DV) como o do sinful1992.
6. **Redesenho sem caminho de volta (C-1)**: navegação do Android e Início novos (etapas C, F) mudam o layout; manter o mesmo caminho para Baixados/Configurações e testar com a família antes de publicar.
7. **Embrulhar web na TV (B-1)**: não corre (Flutter nativo), mas as TVs Samsung/LG usam os apps separados (cgflix-tv, P13–P15), fora deste app.
8. **Escopo inchado (B-3)**: o Heisuca herda do Plezy música, Live TV, metadados, vários servidores (SMB, WebDAV) e o painel "Funções e desempenho"; avaliar o que remover na varredura do Guia Android ("Depois").
9. **Paywall/anúncio (C-4)**: não corre; manter apoio só cosmético.

## Decisões do Caio (25/10)
- Lacunas aceitas para o Heisuca (celular/tablet topo de linha): motivo da conversão, "ainda está assistindo?",
  temporada com estimativa de espaço e regra "próximos N", Dolby Vision perfil 7.
- Canais do Android TV e login por QR/código: são do app de TV, fora do Heisuca celular.
- "Continuar + Próximos" numa fileira: o Heisuca celular já faz (`_mergeContinueWatchingAndNextUp`); a lacuna era só na TV.
- Download já convertido: vai para o app Lite (aparelho simples, pouco espaço), não para o Heisuca.
- Apps com licença incompatível: inspiração permitida (comportamento e fluxo), sem copiar código.
