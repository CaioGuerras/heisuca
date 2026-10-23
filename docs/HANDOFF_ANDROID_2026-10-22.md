# Passagem de contexto — Heisuca Android — 22/10/2026

## Comece aqui, Claude

**Atualização de 23/10:** Caio informou que a Home ficou correta em testes preliminares.
A próxima pauta é ficha do conteúdo, configurações completas, player e troca de serviço.
Ler [a análise e proposta atual](PROXIMA_ETAPA_TITULO_FONTES_AJUSTES_2026-10-23.md),
que também corrige o índice das imagens do dossiê antigo. Não declarar essas próximas
integrações como prontas; esta atualização não muda o código do APK abaixo.

Caio testou o APK do commit `5947c76f63c9a4830812a63be2689bc0ac32b7e1` e relatou melhora.
Agora quer a Home no padrão EXATO do site, não no padrão dos esboços Android antigos.
Também pediu contexto compartilhado no ai-memory, resolução das pendências e novo APK.
Não repetir pesquisa do zero nem descartar as correções da primeira etapa.

Branch desta etapa: `codex/heisuca-home-site`; base: `codex/heisuca-configuracoes-reais`.
PR anterior: https://github.com/CaioGuerras/heisuca/pull/1 (não foi feito merge).
O site está em `site-v2`, SHA `ff7e787b8c13808999861363e29094f8b9441dfc`.
Os arquivos web também existem na árvore Android. Não substituir a árvore Flutter pela
branch do site: os históricos contêm trabalhos diferentes.

## Evidência trazida por Caio

Prints anexados na conversa: `Screenshot_20261022-223617_Heisuca.png` e `16360.png` são
APK; `16361.png` e `16362.png` são o site em heisuca.docaio.com.br.
O acesso público ao site não abriu neste ambiente; o código-fonte e os prints foram
inspecionados. Não houve login na conta Jellyfin de Caio nem acesso físico ao telefone.

Problemas observados no APK: roda roxa antes da abertura; hero curto; arte termina em
uma faixa preta e a fileira seguinte começa sobre um halo de outra cor; logo do título
não acompanha a rolagem; cabeçalho largo com vidro; fileiras Lançamentos/Novidades/gêneros
em vez das bibliotecas; falta Em breve. O site é a referência para corrigir isso.

## Implementação desta etapa

- `main.dart`: no bootstrap transparente usado pelo Android, mantém o fundo nativo sem
  desenhar a roda. Falhas/reparo continuam visíveis e as demais plataformas mantêm indicador.
- `heisuca_home_style.dart`: máscara alpha igual ao CSS do site (0%, 52%, 74%, 94%);
  decodifica BlurHash 12×10 e usa média dos 40% inferiores, paleta OKLCH e fundo único.
  Sem cor sorteada a partir do nome e sem halo separado. Fallback estável se falta hash.
- `heisuca_home_chrome.dart`: uma única logo de título é posicionada a partir de sua
  âncora real e encaixa entre marca e busca. Sem BackdropFilter/barra retangular; apenas
  véu em degradê quando encaixada. A rotação para enquanto a pessoa lê abaixo do hero.
- `heisuca_home_screen.dart`: altura/máscara e arte orientadas pelo site; metadados e
  classificação reais; fileiras Continuar, Em alta, bibliotecas na ordem do servidor,
  Em breve. Streams são mantidos pelo State, sem reiniciar por mudança de cor/topo.
  Troca de servidor limpa o hero anterior; troca manual de slide atualiza a cor também.
- `cgflix_home_repository.dart` e `cgflix_jellyfin_queries.dart`: bibliotecas de vídeo,
  Items/Latest por ParentId, cache existente por servidor/usuário; calendário real de
  `/HomeScreen/Section/UpcomingShows`, `UpcomingMovies` + `/cgflix/embreve.json`.
- `heisuca_upcoming.dart`: mapeamento Sonarr/Radarr → Jellyfin/TMDB igual ao site,
  deduplicação e informação de data/episódio. Não inventa disponibilidade. Ausência do
  plugin/mapa esconde a fileira; um servidor genérico pode não oferecer esses endpoints.
- Em breve abre a ficha real se há item Jellyfin. Caso contrário, abre a busca REAL de
  pedidos para escolher o resultado correto, sem solicitar um título só por coincidência
  de nome. A autenticação existente usa Quick Connect e sessão da própria pessoa.
- `heisuca_seerr_sheet.dart`: remove atraso/sucesso fictício e seletor de qualidade
  desconectado; passa pelo mesmo CgflixRequestSection e backend real já existente.
- Marca de topo usa selo E palavra extraídos do SVG oficial do site, com a mesma transformação geométrica e recorte da versão web e variantes Shikkoku/Hisui. Ilha mais compacta,
  Favoritos reais no terceiro destino, busca no topo e nome/avatar do perfil.
- Workflow exige análise/testes antes do APK; alterações apenas documentais não iniciam
  outra compilação. Assim o resultado pode ser registrado sem cancelar o build de código.

## Primeira etapa já validada (não regredir)

Commit `5947c76`: preferências ligadas a SettingsService; áudio português opcional com
prioridade da seleção manual; identificação Android real, sem Edge 60 Pro fixo; buffer
editável só no ExoPlayer e automático no libmpv; SMB indisponível sem coleta de senha;
WebDAV apenas teste PROPFIND, sem anunciar biblioteca adicionada ou iniciar proxy.
128 testes aprovados, análise sem erros bloqueantes (258 avisos/infos ainda existentes).
APK anterior: https://github.com/CaioGuerras/heisuca/actions/runs/39882985093/artifacts/12471389349

## Ajuste final de paridade

Após a primeira execução aprovar análise/testes, a revisão comparou os tokens CSS:
primária Shikkoku #9d74ff, fundo #0e0b14, selo #7444e0; Hisui usa selo #05805c.
A marca passou a usar caminhos vetoriais oficiais em vez de texto aproximado. Os cartões
seguem as medidas móveis do site: pôster 80 px, Continuar 180 px, Top 10 proporcional,
play central e progresso/tempo reais em branco. Removido o badge TOP 10 extra do app.
Os componentes compartilhados preservam o estilo antigo por padrão; só a Home ativa
`siteStyle`. A versão do app foi elevada para 2.0.2+3.

## Identidade e assinatura do APK de avaliação

Foi baixado o APK anterior de 5947c76 e lido seu certificado público v2:
SHA-256 `2474b51d778c36719b5ad428ca053a0fa253fc47e52085335b0c5e851320dfd7`,
CN Android Debug, criado em 23/10 01:28:34 UTC. O log da execução confirma que não há
keystore nos secrets. Não há acesso à chave privada anterior; o certificado não permite
recuperá-la. Uma chave debug nova não é uma estratégia de atualização confiável.

Para não exigir desinstalar o app de Caio, o workflow das branches codex/heisuca-* passa
`-PheisucaPreview=true`. O APK tem applicationId `app.heisuca.player.teste.home`, nome
`Heisuca Teste` e dados separados do app anterior (`app.heisuca.player.teste`). Exige novo
login, sem apagar o anterior. Providers FileProvider e SystemShelf passam a acompanhar
applicationId; o manifesto antigo fixava br.com.docaio.cgflix e impediria coexistência.
ExternalPlayerChannel e SystemShelfArtworkProvider usam a identidade efetiva do app.

A chave DEBUG é preservada no cache desta branch para os próximos testes. Cache pode
ser limpo/expirar e não substitui configurar uma chave de assinatura durável por secrets.
Claude deve continuar nesta branch para reaproveitar o cache, ou configurar a assinatura
com autorização/contexto apropriados. Nunca salvar uma chave privada de produção no git.
O workflow verifica assinatura, package, label e providers do APK efetivo antes de
publicar o artifact, e confere os providers privados/grants no manifesto fonte E no manifesto binário.

A primeira execução dessa variante (39889881411, fb52b918) passou análise e 185 testes,
compilou o APK (98,3 MB), mas NÃO publicou artifact: a tarefa extra testReleaseUnitTest
não existia. Foi um erro de configuração do workflow desta sessão. AGP 9 só cria unidades
para testBuildType (debug aqui), conforme documentação oficial das mudanças de defaults:
https://developer.android.com/build/releases/agp-9-0-0-release-notes#behavior-changes
O teste JVM de fonte não foi executado nesta sessão. O fluxo corrigido preserva as
mesmas verificações de isolamento via XML e as amplia ao APK efetivo via aapt/apksigner;
não há continue-on-error nem conversão de falha em sucesso. Artifacts de diagnóstico,
se houver erro depois de compilar, ficam explicitamente marcados como NÃO APROVADOS.
Para suites JVM completas no futuro, usar o build type habilitado ou configurar
plezy.testBuildType/onlyEnableUnitTestForTheTestedBuildType explicitamente, sem confundir
um problema de seleção de tarefa com falha funcional do app.

## Validação desta etapa

Código do APK validado: `6a526bdc449a76034ce1a31d2b67934176036dd1`.
PR: https://github.com/CaioGuerras/heisuca/pull/2 (draft, sem merge).
Execução concluída com SUCESSO em 23/10/2026 UTC (noite de 22/10 no Brasil):
https://github.com/CaioGuerras/heisuca/actions/runs/39892410268

- 185 testes Flutter aprovados; análise sem erros bloqueantes, com 240 avisos/infos.
- APK Release arm64-v8a, versão 2.0.2+3, 98.254.933 bytes (98,3 MB).
- Assinatura verificada com apksigner; pacote, nome e providers privados/grants
  conferidos no manifesto binário com aapt, além da conferência do manifesto fonte.
- Artifact aprovado (ZIP com heisuca-arm64-v8a.apk), retenção até 06/11/2026:
  https://github.com/CaioGuerras/heisuca/actions/runs/39892410268/artifacts/12476266298
- SHA-256 do APK extraído: `f5abdd37fda147efba669a2d5cf2b625490267b0a14962ac5d53add639276905`.
- SHA-256 do certificado desta variante:
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
- Instalado como Heisuca Teste / app.heisuca.player.teste.home, separado do anterior;
  exige novo login. A coexistência foi preparada e conferida no manifesto, mas não
  instalada fisicamente nesta sessão. Não mandar desinstalar o app antigo.
- A chave de teste foi salva no cache da branch ao concluir a execução.
- O teste JVM mencionado acima NÃO foi executado. Não confundir os 185 testes Flutter
  e as verificações de XML/APK com uma execução de suites JVM.

Commits posteriores apenas em docs não alteram o código deste APK. Não houve teste
físico, login no servidor de Caio ou comparação pixel a pixel de uma execução no aparelho.
Testes adicionados: máscara/paleta, BlurHash inválido, calendário, deduplicação, logo
encaixada ao rolar, busca acessível e consulta Items/Latest/cache. O portão inclui os
suites Home/Seerr existentes e bootstrap, além dos testes da primeira etapa.

## Pendências conhecidas e ordem para continuar

1. Teste físico/visual de Caio: topo/rolagem nos dois temas, ausência de linha no fim do
   hero, primeira abertura e abertura com cache, bibliotecas e calendário do servidor real.
   Testes de widgets não comprovam fidelidade pixel a pixel nem uso em 120/144 Hz.
2. Player cinematográfico: `heisuca_player_screen.dart` continua sendo um protótipo
   FORA do fluxo. O fluxo real é Home/ficha → cgflixPlay → navigateToVideoPlayer →
   VideoPlayerScreen. Integrar os elementos aprovados aos controles/callbacks reais.
   Não trocar por um Container preto com horários e faixas fixos.
3. `heisuca_library_screen.dart` e `heisuca_search_screen.dart` ainda são protótipos
   com conteúdo demonstrativo. NÃO ligá-los à navegação. A shell usa LibrariesScreen
   e SearchScreen reais do app. Falta portar o desenho mantendo os dados e o ciclo de vida.
4. Calendário é específico do plugin do servidor. Para Plex, a Home continua com hubs
   reais; esta etapa só exibe Top 10 brasileiro se o hub trouxer esse nome, sem inferir
   tendência a partir do primeiro hub. Validar paridade do Plex em conta real.
5. SMB e catálogo WebDAV completos não existem. Implementar transporte, autenticação,
   catálogo persistente e streaming antes de exibir sucesso. Não ressuscitar simulações.
6. Verificar anime com ASS/libass, áudio português e fallback, retomada, rotação,
   segundo plano, fim do episódio, limite de duas sessões e mensagens de erro no aparelho.
7. Rever avisos de analyzer relevantes. Não transformar aprovação sem erros bloqueantes
   em alegação de projeto sem problemas. Não limpar centenas de avisos em diff sem relação.

## ai-memory: estado e procedimento honesto

O MCP/CLI do ai-memory NÃO está conectado a esta sessão ChatGPT. O repositório CGFLIX
contém `bin/cgf-ai-memory`, que inicia o daemon em `127.0.0.1:49374` NO SERVIDOR do usuário;
essa porta local não aponta para o servidor a partir deste contêiner. Não houve escrita
no banco/wiki remoto. Não expor porta, copiar tokens, ler segredos ou inventar credenciais.

Claude no servidor deve atualizar este checkout/branch e usar seu MCP ai-memory:
1. Confirmar workspace/projeto existentes pelo marker/briefing da instalação; não criar
   escopo errado nem sobrescrever o handoff de outra sessão.
2. Ler este documento e `docs/HEISUCA_VALIDACAO_FUNCIONAL.md`.
3. Gravar uma página durável via `memory_write_page`, por exemplo
   `handoffs/heisuca-android-2026-10-22`, com este conteúdo e os links de commit/build.
4. Ler de volta via `memory_read_page` e registrar que foi importado SOMENTE se a leitura
   confirmar o corpo e o escopo. Se apropriado, criar handoff via `memory_handoff_begin`.

Referências oficiais verificadas nesta sessão: https://github.com/akitaonrails/ai-memory/blob/main/docs/cookbook.md
(“save a durable page”, “save context for next session”) e docs/usage.md (handoff entre agentes).
Este arquivo e AGENTS.md garantem contexto em git mesmo antes dessa importação.
Também está preparado `docs/importar-ai-memory.sh`, com `write-page --body -` e leitura
integral de volta, conforme a CLI oficial consultada. No host conectado, após confirmar
os nomes existentes: `bash docs/importar-ai-memory.sh WORKSPACE_EXISTENTE PROJETO_EXISTENTE`.
O script não foi executado contra o daemon remoto nesta sessão.

## Regras de operação

Não fazer merge nem deploy do site/release automaticamente. APK de teste é apenas para
Caio avaliar. Não disparar mensagens Telegram/e-mail a usuários. O servidor não transcodifica
vídeo: preservar reprodução direta/remux e libass. Não embutir endereço/token/conta.
Não alegar funcionamento de hardware por modelo comercial. Licença/créditos do upstream
continuam obrigatórios. Commits e documentação em PT-BR.
