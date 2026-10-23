# Heisuca Android — ficha, fontes, ajustes e player — 23/10/2026

## Pedido e referência

Caio aprovou preliminarmente a Home 2.0.2+3 e autorizou implementar a etapa seguinte.
Referências e decisões estão em `PROXIMA_ETAPA_TITULO_FONTES_AJUSTES_2026-10-23.md`.
Esse documento é a análise anterior, não o estado atual da implementação.
Os dois novos prints VidHub mostram DanMachi, arte imersiva, logo, continuação,
temporadas, cartões horizontais, elenco e detalhes de mídia. As referências aprovadas
recuperadas são step_511 (ficha), step_695 (configurações), 07b (player) e step_791
(painéis). Alguns nomes dos arquivos do dossiê eram incorretos; seguir a análise.

Branch: `codex/heisuca-home-site`. PR #2 permanece draft, sobre
`codex/heisuca-configuracoes-reais`. Não houve merge, release ou deploy do site.
Versão desta etapa: **2.0.3+4**. A Home online conserva seu desenho aprovado.

## Implementação real

### Ficha

`heisuca_title_sheet.dart` agora busca os metadados completos e o on-deck do servidor,
usa a paleta/BlurHash e máscara da Home, mostra logo com fallback textual e metadados
existentes. O play informa o alvo real (ex.: Continuar T1:E7) e encaixa no topo quando
o botão original saiu da área visível. O mesmo callback atende as duas posições.

Temporadas vêm de fetchChildren(show); episódios vêm de fetchChildren(season), cujo
cliente Jellyfin já pagina internamente. A interface divide a temporada em grupos de
10, oferece Ver tudo e inicia a faixa horizontal no episódio de continuação. Temporada
0 aparece como Especiais. Respostas de temporada e atualização do título têm geração
para não sobrescrever escolhas novas. Ao voltar da reprodução, a ficha atualiza progresso
e continuação. Respeita hideSpoilers em miniaturas e títulos dos episódios não vistos.

Favorito consulta a capacidade do backend; marcar visto usa WatchActions. Download
seleciona temporada ou episódio e usa queueDownloadWithFeedback. O ícone de espera só
indica inserção na fila: não afirma que o arquivo foi baixado. Corrigido também o falso
sucesso do favorito quando não havia cliente disponível.

Elenco e gêneros usam dados reais. Gêneros são etiquetas descritivas nesta versão, sem
filtro ao tocar. Extras/trailers e relacionados são consultados ao expandir. Informações
de arquivo usam getFileInfo, listando versões, streams e caminho expansível/copiar;
ausência/erro têm estado próprio e retry. O seletor de versões da reprodução permanece
no fluxo real do player. Os cartões de filmes/séries online no celular abrem esta ficha;
rotas específicas de episódios, temporadas, offline, catálogo, TV e desktop continuam
usando suas regras existentes. Não alterar essas rotas indiscriminadamente.

### Fontes

`HeisucaSourceScope` persiste a seleção por ID do perfil em SharedPreferences, acima
da árvore de navegação. Você > Fonte atual permite escolher um servidor; Trocar perfil
é uma ação separada. Configurações > Avançado também expõe fonte e gestão de conexões.
A seleção identifica servidor, não somente tipo de serviço ou conta Plex.

`MultiServerManager.navigationServerId/navigationOnlineClients` é um filtro adicional:
NÃO substitui visibleServerIds/expectedServerIds de autorização. DataAggregationService
usa a interseção para Home, bibliotecas e busca; favoritos Jellyfin usa a mesma fonte.
Clientes de reprodução/download permanecem acessíveis por origem. Reconexões entregam
apenas a fonte selecionada aos listeners de navegação. Trocar fonte remonta o subtree de
consumidores/navegador, descartando respostas e telas antigas, sem trocar credenciais.
Isso também descarta estado temporário das abas e da sessão musical desse subtree.

A seleção offline permanece selecionada. A Home mostra aviso, retry e seletor, sem
fallback para outro Jellyfin. Fonte removida do conjunto esperado é invalidada depois
do binding. Não há opção Todos nesta etapa. Plex não oferece o favorito por coração
usado pelo Jellyfin; a interface respeita a capacidade existente.

### Ajustes

O hub Heisuca expõe Ao assistir, Vídeo e áudio avançados, Áudio e legendas, Downloads,
Fontes/conexões e Diagnóstico/backup. Reutiliza PlaybackSettingsScreen e seções reais de
SettingsScreen em vez de duplicar chaves ou criar controles inertes. Inclui opções
existentes de motor, PiP/gestos, abertura/créditos, HDR/DV, taxa de quadros, áudio,
legendas ASS, pasta/Wi-Fi, limpeza, logs e backup. As restrições por motor/plataforma
continuam nas implementações originais. Não promete Vulkan, 144 Hz ou buffer mpv editável.
O botão de restauração do hub foi renomeado para deixar claro seu escopo: os seis
controles dessa tela. As subpáginas mantêm seus controles/restauração existentes.

### Player

O fluxo continua VideoPlayerScreen com mpv/ExoPlayer reais. MobileVideoControls recebeu
comandos na base, com rolagem para caber em telas estreitas, labels visíveis, episódios/
capítulos e navegação anterior/próximo. Centro: play/pausa e seek relativo pelo callback
real. Timeline, faixas, PiP, bloqueio, rotação, marcadores e painéis existentes continuam
conectados. Proporção distingue Original/Ajustar, Preencher (corta bordas), Esticar
(deforma). O protótipo HeisucaPlayerScreen continua FORA da navegação.

Esta etapa reorganiza o HUD e mantém os painéis funcionais do upstream. Não declarar
paridade pixel a pixel com todos os esboços, nem suporte HDR/ASS validado em aparelho.

## Validação e entrega

Código: `0c2df181d25d40a60a250ca000211e5e62826584`.
Run: https://github.com/CaioGuerras/heisuca/actions/runs/39959931134
Análise e suíte passaram; compilação nativa em andamento. Completar número de testes,
artifact e certificado após a conclusão. O portão inclui test/heisuca, regressões da Home/Seerr/bootstrap/seleção de
faixas e agora test/widgets/video_controls_test.dart.

Primeira rodada: análise sem erros bloqueantes, 230 avisos/infos, 185 testes passaram,
2 falharam procurando Sinopse. Segunda: 187 passaram, os testes novos da ficha passaram;
os dois antigos precisavam rolar até a sinopse no novo hero maior. A correção mantém a
verificação do conteúdo e acrescenta scrollUntilVisible, não ignora a falha.

Testes adicionais: seleção de fonte não muda clientes de download nem autorização;
fonte offline não cai em outro servidor; on-deck E7/paginação/docking nos dois temas;
persistência por perfil/remoção da fonte; seek real e dock em paisagem. O passo de análise/testes da última rodada terminou com sucesso; registrar a contagem
final a partir do log completo ao concluir o job.

Package de teste permanece `app.heisuca.player.teste.home`, label Heisuca Teste, com a
chave cacheada da mesma branch. Esperado o mesmo certificado SHA-256 do 2.0.2:
`19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
Conferir o APK efetivo. Cache não substitui assinatura durável de produção.

## Teste no aparelho e continuidade

Ainda depende de Caio: fidelidade da arte/logo com dados reais, texto ampliado, troca
Jellyfin/Plex/servidores da mesma conta, servidor offline/reconectado, temporada 0,
ASS/libass, seleção de áudio/legenda, retomada, PiP/rotação/background e próximo episódio.
Os testes usam clientes/players de teste, não a conta de mídia de Caio.

O ai-memory NÃO está conectado a este ambiente. Documentação em git não equivale a
importação. No host do usuário, ler este handoff e a análise, importar no escopo que o
briefing/marker indicar e conferir o corpo por leitura. Não inventar workspace/projeto,
não abrir portas nem copiar credenciais. O script em docs ajuda na importação explícita.
