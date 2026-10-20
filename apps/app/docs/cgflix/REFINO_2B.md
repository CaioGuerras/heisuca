# Refino 2b — Configurações no padrão Material 3 / Android (1.6.1, versionCode 810)

Ordem de serviço do dono (11/10, depois de testar a 1.6.0): as Configurações estavam bagunçadas, coisas técnicas
logo no início, o tema não "encaixava" e não parecia Material 3. Referências consultadas nesta etapa:
[padrão Settings do Android](https://developer.android.com/design/ui/mobile/guides/patterns/settings) e
[Switch (Compose M3)](https://developer.android.com/develop/ui/compose/components/switch). O site m3.material.io não
abriu no contêiner (sem resolução de DNS); as regras de lista, switch e divisores do M3 foram conferidas pelas páginas do
developer.android.com e pelo código do Material 3 do próprio Flutter 3.47.1 (`SwitchListTile`, `SliverAppBar.large`,
`PredictiveBackPageTransitionsBuilder`).

Regra do fork mantida: nada some; o que saiu da frente foi para **Avançado**. Código novo em `lib/cgflix/`; nos
arquivos do Plezy, ganchos curtos marcados `CGFLIX`.

## A/B. Item → onde estava (1.6.0) → onde ficou (1.6.1) → por quê

| Item | Onde estava | Onde ficou | Por quê |
|---|---|---|---|
| Visual das Configurações | cartões-sanfona por grupo, chevron em todo item, switch preto e branco | lista plana M3, cabeçalho na cor `primary`, sem chevron, switch do tema | padrão das Configurações do Android (grupos com cabeçalho, nada recolhido, item que abre subtela sem seta) |
| Minha conta | só no menu do usuário | tela principal › **Conta** (com Jellyfin conectado) | o padrão do Android põe conta no topo; antes não dava para achar pelas Configurações |
| Perfis | Contas e servidores (sanfona) | **Conta** (com vários perfis); com um perfil só, Avançado › Contas e servidores | quem tem vários perfis troca com frequência; quem tem um só quase nunca mexe |
| Tema | subtela Aparência | tela principal › **Aparência › Tema** (só o nome) | é o que se troca; ficar a um toque |
| Idioma do app | subtela Geral (sanfona) | **Aparência › Idioma do app** ("Português (Brasil)") | Geral tinha só 2 itens; idioma é aparência |
| Mais opções de aparência (cartões, bibliotecas, efeitos) | subtela Aparência | **Aparência › Mais opções de aparência** (mesma subtela, sem o Tema) | o rótulo do item é igual ao título da subtela (regra do Android) |
| Áudio, legenda e conta ("salvo em CGFLIX", chevron + "?") | topo | **Assistir › Áudio e legenda**, resumo "Áudio: Português · Legenda: Português", com "?" (sem chevron) | mostra o valor atual; tira o "salvo em" que confundia |
| Idioma de áudio/legenda "Portuguese" | inglês | **Português, Inglês, Japonês…** (todos os 185 idiomas); idiomas comuns no topo; áudio sem preferência = "Original do título" | português simples; o Jellyfin toca a faixa original quando não há preferência |
| Estilo das legendas | dentro de Ao assistir › Legendas | **Assistir › Estilo das legendas**, resumo "Tamanho 38 · Texto branco" | legenda é do dia a dia; resumo com o valor |
| Ao assistir (pular abertura, próximo episódio, gestos, janelinha, avançar e voltar) | Ao assistir com 10 sanfonas | **Assistir › Ao assistir** (lista plana: Pular abertura e próximo episódio · Gestos · Janelinha · Avançar e voltar) | o comum em cima; gestos num grupo plano |
| Pular abertura / créditos (resumo redundante) | "Mostrar botão · o botão aparece quando…" | resumo só com o valor; a explicação foi para o diálogo (subtítulo de cada opção) e para o "?" | resumo de uma linha com o estado |
| Qualidade padrão | Ao assistir › Qualidade | **Assistir › Qualidade padrão** ("Original", com "?") | escolha que importa para dados móveis |
| Qualidade nos dados móveis | Ao assistir › Qualidade | **Assistir › Qualidade nos dados móveis** | idem |
| Baixados | sanfona | **Baixados** (um item que abre subtela; resumo "Só no Wi-Fi · Pasta padrão") | não é sanfona; resumo com o estado |
| Dicas do CGFLIX | Sobre › Dicas | **Ajuda › Dicas do CGFLIX** (e continua no Sobre) | achar as dicas sem saber que estão no Sobre |
| Sobre | fim | **Ajuda › Sobre** | grupo de ajuda |
| Avançado | sanfona **aberta** no meio da tela | **um item no fim, fechado, que abre subtela** | técnico longe da frente |
| Apoie o CGFLIX | último | último (depois do Avançado) | aprovado no refino 1/2 |
| Contas e servidores / Adicionar conexão ("Adicionar a caioguerras: …") | sanfona na frente | **Avançado › Contas e servidores**, resumo "Entrar em outro servidor Plex, Jellyfin ou Emby" (o perfil fica para o leitor de tela) | quase ninguém mexe depois do primeiro acesso; texto leigo |
| Organizar bibliotecas, Serviços (Trakt) | Contas e servidores | Avançado › Contas e servidores | idem |
| Assistir juntos, Controle remoto | Avançado (aberto) | Avançado › **Recursos extras** | técnico/raro |
| Opções do mpv | Avançado | Avançado › **Ao assistir (técnico)** | técnico |
| Sempre detectar abertura pelos capítulos, nomes dos capítulos (regex) | Avançado (aberto, na frente) | Avançado › Ao assistir (técnico) | técnico |
| Espera antes de pular | Ao assistir (topo) | Avançado › Ao assistir (técnico) | técnico (só vale no modo automático) |
| Modo aleatório começa do início | Ao assistir (topo) | Avançado › Reprodução avançada › Comportamento | técnico |
| Reprodutor, aceleração de vídeo, buffer, Vídeo e tela (HDR, Dolby Vision), Áudio, qualidade técnica, Comportamento, Lembrar ajustes | sanfonas em Ao assistir | Avançado › **Reprodução avançada** (subtela) | o Android manda agrupar 15+ itens numa subtela; tudo técnico |
| Estilo ASS (anime), Resolução da legenda | Estilo das legendas (topo) | Avançado › **Legendas (técnico)** | jargão |
| Forçar modo TV, perfil ao abrir, seção inicial (TV), tela cheia (PC), Som de abertura | Geral / Avançado | Avançado › **Este aparelho › Geral** | a subtela Geral deixou de existir na frente |
| Diagnóstico (registros, painel de desempenho, limpar imagens, restaurar), Assistir juntos (servidor) | Avançado (aberto) | Avançado › **Diagnóstico** | agrupado por assunto |
| Cópia de segurança | Avançado | Avançado › Cópia de segurança | igual |

Por que **"Assistir"** e não "Ao assistir" no cabeçalho: o item que abre a subtela "Ao assistir" precisa ter o mesmo
nome dela (regra do Android); repetir "Ao assistir" no cabeçalho e no item logo abaixo ficaria estranho.

## C. Textos

- Idiomas em português com inicial maiúscula em todas as listas e resumos (`lib/cgflix/cgflix_idiomas.dart`, gancho em
  `lib/utils/language_codes.dart`): "Português", "Inglês", "Japonês", "Português (Brasil)"; ordem alfabética sem
  tropeçar no acento ("Árabe" entre os "A"). Em inglês, o app continua igual ao upstream.
- Estilo das legendas: "Tamanho", "Cor do texto", "Altura na tela", "Contorno", "Espessura do contorno",
  "Cor do contorno", "Fundo atrás do texto" ("Sem fundo" no 0%), "Cor do fundo"; prévia ao vivo no topo; cores em
  círculos (Branco, Amarelo, Preto, Cinza, Ciano, Verde e "Outra cor") com check e nome para o leitor de tela.
- "Áudio, legenda e conta" → "Áudio e legenda"; sem "salvo em CGFLIX"; sem "Adicionar a caioguerras".

## D. Ícones

Configurações inteiras em **Material Symbols Rounded** empacotado (o `AppIcon` do upstream), **contorno** (gancho no
`AppIcon` dentro das Configurações), 24 dp, `onSurfaceVariant`. Nenhum Material Icons antigo nas Configurações
(`grep Icons. lib/screens/settings` vazio; o teste de consistência de ícones do upstream passa).
Trocas: Avançado `settings_applications`, Mais opções de aparência `dashboard_customize`, Baixados
`download_for_offline`, Reprodução avançada `settings_video_camera`, Opções do mpv `terminal`, Geral `devices`,
detectar pelos capítulos `bookmarks`, Dicas `lightbulb`.
**Não trocados**: o coração do "Apoie" continua rosa (marca do apoio, agora em contorno); os ícones dentro do player
seguem a regra do refino 2 (preenchido = ligado), porque o player não é lista.

## E. Integração com o sistema (checklist)

| Item | Situação | Evidência |
|---|---|---|
| Ponta a ponta nas Configurações e subtelas | OK | barras transparentes (1C); barra de título grande desenha sob a barra de status; `SliverSystemBottomInset` no fim de cada lista (conteúdo rola por baixo da barra de navegação, sem faixa preta) |
| Barra de título grande que recolhe ao rolar | **feito** | `SliverAppBar.large` nas Configurações do celular (gancho em `desktop_app_bar.dart`); TV/PC ficam com a do upstream |
| Voltar preditivo nas subtelas | **feito** | `android:enableOnBackInvokedCallback="true"`; a transição do CGFLIX segue o dedo (encolhe para 90%, cantos de 28 dp) e volta se desistir — `test/cgflix/cgflix_voltar_preditivo_test.dart` |
| Fonte 200% sem corte | OK | capturas `*-fonte200-*` e teste "fonte 200%" (360 dp de largura, sem exceção); títulos e resumos quebram linha |
| TalkBack: cabeçalho como cabeçalho, switch como switch | **feito** | `Semantics(header: true)` nos cabeçalhos; `SwitchListTile` (papel de switch com estado); opções dos diálogos como botões de opção (`checked` + grupo exclusivo); círculos de cor com nome e "selecionado" — `cgflix_configuracoes_test.dart` |
| Foco visível no teclado/controle | **feito** | linha inteira com realce `primary` 16% (teste) |
| Paisagem | OK | teste 914 × 412 na tela principal e no Avançado |
| Tablet ≥ 840 dp em duas colunas (lista-detalhe) | **não feito** | exigiria reescrever a navegação das Configurações (as subtelas são rotas); fica para depois |
| Cor da marca fixa (sem cor dinâmica) | OK | esquemas fixos Isis/Heitor |
| Remover animações | OK | transição seca (inclusive com o voltar preditivo) |

## Componentes M3 usados

`ListTile` (56/72 dp, ícone 24 dp `onSurfaceVariant`, título `bodyLarge` `onSurface`, resumo `bodyMedium`
`onSurfaceVariant`), `SwitchListTile` com `Switch` M3 (trilho `primary`, contorno `outline`, `thumbIcon` com check),
`Slider` M3 (números), diálogo com botões de opção (escolhas curtas), cabeçalhos `titleSmall` em `primary`,
`Divider` `outlineVariant`, `SliverAppBar.large`, folha inferior M3 com alça (dicas), `IconButton` de 48 dp ("?").
Contraste AA conferido em teste para os dois temas (cabeçalho, título, resumo, trilho, contorno, polegar).

## O que decidi não mudar (e por quê)

- **SegmentedButton** para Pular abertura (3 opções): a 200% os rótulos ("Mostrar botão", "Automático") não cabem lado
  a lado em 360 dp; ficou o diálogo com botões de opção, que é o outro padrão do Android para ≤ 5 opções.
- **Duas colunas no tablet**: ver acima.
- **Qualidade dos baixados**: não existe no app (baixa o arquivo original); a subtela Baixados tem pasta, Wi-Fi,
  apagar assistidos e segundo plano.
- **Primary global da Isis**: continua branco fora das Configurações (botões cheios, foco da TV do upstream); o roxo
  entra nas Configurações e em todos os switches/opções do app. Trocar o primary global mexeria em 115 lugares do upstream.
- **Título da barra grande a 200%**: o Flutter limita a escala do título da barra (padrão do M3); o conteúdo escala inteiro.
- **Job do emulador**: passou de novo na run 110 (a correção anterior, desligar o Gradle antes de ligar o emulador,
  resolveu); não precisou de `continue-on-error`.

## Testes e capturas

- `test/cgflix/cgflix_configuracoes_test.dart` (novo): ordem da tela principal, técnico fora da frente, sem chevron
  e sem sanfona, Avançado com tudo, cabeçalho/switch (cor, semântica, 56 dp, o item inteiro alterna), cores do switch,
  contraste AA, fonte 200%, deitado, foco, idiomas em português.
- `test/cgflix/cgflix_voltar_preditivo_test.dart` (novo): gesto arrasta e fecha; desistir devolve; manifesto.
- Testes do upstream ajustados: densidade M3 nas Configurações, número em controle deslizante, estilo ASS no Avançado.
  `cgflixSettingsDebugInline` (só testes) mostra o conteúdo das subtelas na própria tela, como os testes do upstream esperam.
- Capturas: `docs/prints/refino2b/antes` (1.6.0) e `docs/prints/refino2b/depois` (1.6.1), temas Isis e Heitor, fonte
  100% e 200%: `01-principal`, `02-ao-assistir`, `03-audio-e-legenda`, `04-estilo-das-legendas`, `05-baixados`,
  `06-avancado`. Gerar de novo: `CGFLIX_CAPTURAS=<pasta> flutter test test/cgflix/capturas/configuracoes_capturas_test.dart`.
- Emulador (CI): `20-ao-assistir`, `24-estilo-legendas`, `25-avancado`, `22-dicas` nos dois temas.
