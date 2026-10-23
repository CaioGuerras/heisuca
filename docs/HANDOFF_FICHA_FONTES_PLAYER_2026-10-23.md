# Heisuca Android — ficha, fontes, ajustes e player — 23/10/2026

## Polimento do Claude — 23/10/2026 noite — 2.0.8+9 (AGUARDA TESTE NO APARELHO)

Retorno do Caio no 2.0.4 (ficha, player, fontes, modo kids, fluidez). Detalhe completo, por pilar, em
[`REVISAO_CLAUDE_2026-10-23.md`](REVISAO_CLAUDE_2026-10-23.md). Resumo: ficha no Esboço 04 com medidas do site
(2.0.5); HUD do player no 07A (2.0.6); adicionar fonte corrigido e modo infantil Ichigo/Sorairo com PIN (2.0.7);
taxa alta da UI reaplicada após o player e conexão rápida sem servidor embutido (2.0.8). Rota `/__kids/` do nginx
da VPS restaurada (`cgf-kids testar` OK). Capturas de revisão: `HEISUCA_SNAPSHOT=1 flutter test ... --update-goldens`
(saem em `apps/app/test/visual/out/`, fora do git). Mesma branch e mesmo certificado de teste.


## Correção do Claude — 23/10/2026 — 2.0.4+5 (AGUARDA TESTE NO APARELHO)

Commit `04c8e07` em `codex/heisuca-home-site` (mesma branch: a chave de teste do cache
do Actions é por branch; outra branch quebraria a atualização por cima). Sem merge/release.

**Diagnóstico confrontado com o Jellyfin real do CGSERVER (leitura, usuário caioguerras):**

- **Re:ZERO:** o print é o EPISÓDIO T4:E19 "Shaula / Herói" (30/09/2026, 41 min, sinopse
  "Enquanto Emilia…"). Banners, Top 10, faixas e Em breve da Home chamam
  `HeisucaTitleSheet.show(item)` sem olhar o tipo; com `kind=episode` a ficha não monta a
  seção de temporadas. Servidor correto: 4 temporadas, 73 episódios.
- **One Piece:** o servidor devolve `Especiais`, `Temporada 1`…`Temporada 23` (ChildCount 24
  conta Especiais) e nomes próprios dos episódios. A ficha usava `MediaItem.displayTitle`,
  que para temporada/episódio devolve o nome da SÉRIE (é título de cabeçalho) → "One Piece"
  repetido. A T1 tem 8 episódios de 52–65 min segundo o próprio servidor (RunTimeTicks);
  isso é dado do acervo, não do app — não foi investigado se são edições especiais.
- "Assistir T1:E1" estava certo: NextUp do servidor = T1:E1, 0 episódios vistos.
- Testes antigos não pegavam porque o fixture não tinha SeriesName/SeriesId.

**Mudanças (`heisuca_title_sheet.dart`):** episódio/temporada recebidos abrem a série
(`SeriesId`/`grandparentId`, temporada `grandparentId ?? parentId`), com aquele episódio como
alvo ou aquela temporada selecionada; se o servidor não confirmar a série, mantém o item.
Recargas após assistir/marcar seguem o on-deck. Rótulos `heisucaSeasonLabel` /
`heisucaEpisodeLabel` (nome próprio; "Temporada N"/"Episódio N" se repetir a série).
Contagem sem Especiais. Nota via `ratingSourceLabel` (sem "audience" cru, sem repetir a ★).
Episódio tocado e não iniciado mostra "Assistir T4:E19". O play entrega o alvo exato a
`navigateToVideoPlayer` (conferido no código; reprodução não testada em aparelho).

**Testes:** `test/heisuca/heisuca_title_seasons_real_test.dart` com JSON no formato real pelo
`JellyfinMappers`: 6 testes que FALHAM no código anterior e passam agora. Portão local
(Flutter 3.47.1 em ~/sdk/flutter): 300 testes, análise sem erros bloqueantes.

**Entrega:** run https://github.com/CaioGuerras/heisuca/actions/runs/39976107470 (verde).
APK: https://github.com/CaioGuerras/heisuca/actions/runs/39976107470/artifacts/12512705592
(expira 06/11/2026). ZIP sha256 `82ed43f9778659fe7205705e75a20483250f1c45eddd4df8f4e59290f438da81`
(= digest do Actions); APK `heisuca-arm64-v8a.apk` 98.387.569 bytes, sha256
`398e97dd5dfa2c32ea2efdbbf693cdf34a39f2cef965d638a1aa22c171aeafda`. Conferido aqui com
androguard: pacote `app.heisuca.player.teste.home`, 2.0.4 (versionCode 2005), assinatura v2,
certificado `19160423…f95c` (o mesmo do 2.0.2/2.0.3: atualiza por cima). O libapp.so contém o
commit e literais novos. Instalação física não executada.

**Depende do Caio no aparelho:** abrir Re:ZERO pelo card da Home (deve abrir a série na
Temporada 4, alvo T4:E19) e pela Biblioteca (série, T1:E1); One Piece: seletor com
Especiais/Temporada N, trocar temporada, Ver tudo, tocar e conferir o episódio que abre.

---

## Retorno de Caio após teste no aparelho — 23/10/2026 — TRATADO NA SEÇÃO ACIMA

**Instrução expressa:** “não tente corrigir, apenas reporte, o Claude vai atuar”.
Este registro altera apenas documentação. Não houve investigação da causa, correção,
novo teste ou novo APK após este retorno. A aprovação automatizada abaixo NÃO significa
que a navegação de temporadas foi aprovada no aparelho.

Contexto: retorno após a entrega do APK 2.0.3+4 (código
`4f42c29fdff9f977628a3be53479cfc1f29a74e4`). A versão instalada não aparece nos prints.
Caio relata que temporadas de animes não aparecem ou aparecem incorretamente.

### Evidências dos prints enviados

- **16840.png — Re:ZERO:** a ficha mostra logo, data 2026-09-30, duração 41 min,
  botão “Assistir” e sinopse “Enquanto Emilia tenta passar pelo teste do topo,
  Subaru e os demais continuam lutando.” Depois aparecem extras, relacionados e
  informações da mídia, sem seção de temporadas/episódios visível entre esses blocos.
  A arte e a sinopse parecem específicas de um episódio, mas isso é uma hipótese;
  o print não identifica o tipo/ID do item nem a rota de entrada.
- **16841.png — One Piece:** o cabeçalho informa “24 temporadas”, mas o seletor da
  temporada atual exibe apenas “One Piece”. A faixa mostra “1. One Piece” (65 min)
  e “2. One Piece” (56 min), com grupo “1–8”. O botão indica “Assistir T1:E1” e o
  próximo item “T1:E1 · One Piece”. Há inconsistência aparente entre a identificação
  da série, os nomes genéricos e a organização apresentada; não é possível concluir
  pelo print a quantidade correta de episódios daquela temporada nem sua duração.
- **16842.png — One Piece, seletor aberto:** a folha “Temporadas” mostra “Especiais”
  e várias entradas repetidas “One Piece”, sem número ou nome distinto da temporada.
  Uma entrada está selecionada. Isso impede identificar visualmente qual temporada
  está sendo escolhida. O print não mostra a lista inteira.
- Observação secundária no print de One Piece: a nota aparece como texto cru
  “audience 8.8”. Não é a reclamação principal, mas fica registrada para revisão visual.

### Esperado e impacto

A ficha da série deve disponibilizar as temporadas e seus episódios corretamente.
O seletor deve distinguir temporadas por número/nome, inclusive Especiais, e os
cartões devem apresentar os episódios correspondentes. O defeito prejudica a escolha
do conteúdo e pode comprometer a confiança no alvo de reprodução; reprodução errada
não foi demonstrada pelos prints.

### Pistas de investigação para Claude — não são diagnóstico

Conferir o tipo e os IDs do item que chega à ficha (série/temporada/episódio), sua
origem/servidor e relações pai/série. Comparar a resposta real de metadados,
fetchChildren e on-deck com os objetos convertidos e os rótulos apresentados.
Verificar se nomes genéricos da série estão substituindo nomes/índices das temporadas
ou episódios e se algum caminho abre episódio como ficha de série. Não assumir que
o servidor está errado, que há mistura de adaptações de One Piece ou que a causa é
somente visual sem comparar os dados.

Pontos da implementação para localizar: `apps/app/lib/heisuca/heisuca_title_sheet.dart`,
`apps/app/lib/utils/media_navigation_helper.dart` e mapeamento do cliente de mídia.
Os testes anteriores usam fixtures e não cobriram estes casos reais. Claude deve
reproduzir Re:ZERO e One Piece, conferir seleção/episódios/alvo de reprodução e
acrescentar cobertura representativa ao corrigir.

Os três prints foram anexados à conversa do ChatGPT; este registro transcreve as
evidências, mas os arquivos de imagem não foram copiados para o repositório.
ai-memory continua não importado por esta sessão.

---


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

A troca manual marca o prompt inicial como já tratado no novo navegador, evitando
pedir novamente o perfil. O filtro tem proprietário e é limpo no dispose do escopo;
um escopo antigo não pode apagar a seleção de outro. Sem seleção ativa, consultas
explícitas de servidores mantêm o comportamento anterior (incluindo desktop).

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

Código: `4f42c29fdff9f977628a3be53479cfc1f29a74e4`.
Run: https://github.com/CaioGuerras/heisuca/actions/runs/39961563161
Execução concluída com sucesso: **294 testes passaram**, análise sem erros bloqueantes,
com 230 avisos/infos. O portão inclui test/heisuca, regressões da Home/Seerr/bootstrap/seleção de
faixas e agora test/widgets/video_controls_test.dart.

Primeira rodada: análise sem erros bloqueantes, 230 avisos/infos, 185 testes passaram,
2 falharam procurando Sinopse. Segunda: 187 passaram, os testes novos da ficha passaram;
os dois antigos precisavam rolar até a sinopse no novo hero maior. A correção mantém a
verificação do conteúdo e acrescenta scrollUntilVisible, não ignora a falha.

Testes adicionais: seleção de fonte não muda clientes de download nem autorização;
fonte offline não cai em outro servidor; on-deck E7/paginação/docking nos dois temas;
persistência por perfil/remoção da fonte, limpeza do escopo e prompt inicial; seek real
e dock em paisagem. Os erros de bootstrap nos logs são cenários deliberados dos testes.

Package de teste permanece `app.heisuca.player.teste.home`, label Heisuca Teste, com a
chave cacheada da mesma branch. Confirmado o mesmo certificado SHA-256 do 2.0.2:
`19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
APK efetivo baixado, hash do ZIP conferido com Actions e certificado extraído da
assinatura v2 conferido com o anterior. O CI também verificou assinatura, pacote e
providers privados no binário. Cache não substitui assinatura durável de produção.

APK arm64-v8a: 98.387.569 bytes (98,4 MB), versão 2.0.3+4.
SHA-256 APK: `99bd9cabc2cada5aee437b7bf392ed7ecf167a9c3279d350e528652c6cc28261`.
Artifact ZIP: https://github.com/CaioGuerras/heisuca/actions/runs/39961563161/artifacts/12506130922
Expira em 06/11/2026. Extrair `heisuca-arm64-v8a.apk` e instalar sobre Heisuca Teste
2.0.2; pacote e certificado são compatíveis com atualização. Instalação física não
foi executada nesta sessão. Não desinstalar para testar uma atualização normal.

## Teste no aparelho e continuidade

Ainda depende de Caio: fidelidade da arte/logo com dados reais, texto ampliado, troca
Jellyfin/Plex/servidores da mesma conta, servidor offline/reconectado, temporada 0,
ASS/libass, seleção de áudio/legenda, retomada, PiP/rotação/background e próximo episódio.
Os testes usam clientes/players de teste, não a conta de mídia de Caio.

Roteiro de aceite no aparelho:

1. Instalar sobre Heisuca Teste 2.0.2, confirmar versão 2.0.3 e login preservado.
2. Abrir série parcialmente assistida: alvo de Continuar, episódio selecionado,
   temporada e progresso devem corresponder ao servidor. Rolar a ficha para conferir
   o botão encaixado no topo e voltar da reprodução para conferir atualização.
3. Trocar temporada e grupos 1–10/11–20; abrir Ver tudo e Especiais quando existirem.
   Conferir filme sem temporadas, título sem logo e conteúdo sem extras.
4. Você > Fonte atual: alternar entre duas fontes, conferir Home/Biblioteca/Busca e
   favoritos; fechar/reabrir o app, trocar perfil e retornar. A escolha deve persistir
   por perfil, sem pergunta extra de perfil causada apenas pela troca de fonte.
5. Desligar a fonte selecionada: manter seu nome, mostrar indisponibilidade e permitir
   reconectar ou escolher outra. Downloads existentes conservam sua origem.
6. Configurações > Avançado: mudar uma preferência aplicável ao motor em uso, sair e
   voltar; conferir persistência e efeito. Preferências indisponíveis seguem o motor.
7. Reproduzir: seek, áudio, legenda, proporção, próximo episódio, rotação e PiP.
   Validar legendas ASS reais e texto ampliado. Não aceitar sucesso visual sem efeito.

O ai-memory NÃO está conectado a este ambiente. Documentação em git não equivale a
importação. No host do usuário, ler este handoff e a análise, importar no escopo que o
briefing/marker indicar e conferir o corpo por leitura. Não inventar workspace/projeto,
não abrir portas nem copiar credenciais. O script em docs ajuda na importação explícita.
