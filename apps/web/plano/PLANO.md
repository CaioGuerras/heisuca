# Heisuca Web — plano tela por tela (v1.1, 19/10/2026) — APROVADO pelo Caio (19/10 tarde), com as decisões da §16

Nada aqui é código. Cada regra traz a origem: o print (`ref/<pasta>/<arquivo>`) ou a fala do Caio (data e hora).
**[C]** = decisão do Caio pendente; **[P]** = proposta minha (vale se o Caio não vetar); **[V]** = conferido em 19/10.
Coleta bruta e histórico: `COLETA.md`. Prints: `ref/` (vidhub, app_completo, site_atual, streamyfin, heisuca_reprovado).

---

## 1. Princípios (Caio)

1. O produto é a **suíte de players Heisuca**. O CGSERVER é só um servidor entre outros, de amigos e conhecidos.
   O site fica no docaio **temporariamente**; virá domínio próprio. Nada de CGSERVER pré-preenchido, nem "CGFLIX" na tela (19/10 13:00).
2. O site é o **cartão de visitas**: bonito, responsivo, minimalista, com requinte. Não é o melhor player; os ajustes
   profundos ficam nos apps nativos (18/10 21:09).
3. **Algo nosso.** Inspiração e trechos de outros players são bem-vindos; nada de "mais um fork do Jellyfin". O Moonfin web
   funciona, mas é pesado e feio (19/10).
4. **Referência principal: VidHub.** Busca e menu do usuário seguem o CGFLIX completo, porque o VidHub não tem essas telas (19/10 13:00).
5. **Os temas são detalhe, não uma cara imutável:** a cor de cada tela sai do pôster, e o tema entra como toque (19/10).
6. **Não rebaixar o produto** para caber onde não dá. Navegador de TV incompatível não recebe o site (19/10 13:00).
7. **Não inventar:** dado que não existe não aparece; função que ainda não temos fica "Em breve" (19/10 13:00).

---

## 2. Sistema visual

### 2.1 Temas
| Opção no site | Tema da marca | Aparência |
|---|---|---|
| **Roxo** | Shikkoku 漆黒 (padrão) | escuro: `#0E0B14` / primária `#9D74FF` |
| **Verde** | Hisui 翡翠 | **claro** (decidido 19/10): papel morno, primária `#047857` |
| **Automático** | segue o aparelho | aparelho escuro → Roxo; aparelho claro → Verde |

- [V] No app CGFLIX completo, Heitor (verde) é **claro** e Automático = `system` (`cgflix_theme.dart:40`).
  No token do Heisuca, Hisui está **escuro** (`marca/temas/hisui.css`); a BASE_MARCA §3 tem as duas versões.
  **Decidido (19/10):** Verde = claro "papel morno" (BASE_MARCA §3: fundo `#F7F3EC`, primária `#047857`), igual ao app.
  Os prints do VidHub (todos em modo claro) são a referência direta do Verde. O token Hisui da marca passa a ser o claro.
- Vermelho/Azul (Ichigo/Sorairo) só no Modo Kids, que não existe no site. Dourado (Shinju) só no iOS (18/10 20:54).
- Na escolha aparece só o nome; a tela muda na hora, sem amostra de cor (padrão do app: `cgflix_theme_picker.dart`).
  As bolinhas de cor do Heisuca v1 foram reprovadas (`heisuca_reprovado/…foto16`).

### 2.2 Cor tirada do pôster (o "refino")
- Origem: o **BlurHash** que o Jellyfin já guarda de cada imagem. [V] O CGSERVER tem BlurHash de Backdrop, Primary,
  Logo, Thumb e Banner. Por isso a cor sai **antes de a imagem baixar**, sem processar nada no navegador e sem depender de CORS.
- Cálculo: cor média do BlurHash → espaço OKLCH → claridade ajustada ao tema (escuro: fundo profundo; claro: fundo
  pastel, como o InuYasha em `vidhub/…home_topo`) → mistura leve com a primária do tema → **contraste AA medido em código**
  para todo texto. Se não passar, o texto escurece ou clareia; a cor do pôster nunca fica ilegível.
- Fundo desfocado (como em `vidhub/…favoritos`): o BlurHash desenhado em 32×32 e ampliado. Dá o desfoque sem custo,
  sem `backdrop-filter` pesado.
- Troca de cor e de imagem: crossfade de 600 ms depois de `img.decode()`, nunca troca seca (padrão P16 do cgflix-tv).
- Onde vale: home (cor do destaque da vez), título (cor da série), favoritos e biblioteca (cor do 1º item). O player é
  sempre preto.

### 2.3 Tipografia, ícones e formas
- Inter para o texto; Sora para títulos e logotipo (tokens da marca). Logo do título em imagem quando existe; se não
  existir, o nome em Sora.
- Ícones: Material Symbols Rounded 300, que já estão no projeto (BASE_MARCA §5). A escolha continua aberta desde 18/10;
  mantenho, salvo veto.
- Botões em pílula. Vidro (desfoque) só na ilha inferior e nas pílulas do topo, em áreas pequenas.
- Movimento com os tempos e curvas dos tokens; "reduzir movimento" do aparelho respeitado (vira só esmaecimento).

---

## 3. Entrada e animações

### 3.1 Fluxo
1. **Abertura** (a de hoje, ~2,3 s, carimbo 炳素華 + HEISUCA + ヘイスカ + traço de luz + slogan): uma vez por sessão, e
   um toque ou tecla pula, como hoje (19/10: "pode ser curta como está").
2. Ao terminar, **a logo voa até o lugar dela na tela de entrada** (selo + HEISUCA; katakana e slogan esmaecem). A
   técnica é FLIP com Web Animations, que roda igual em todo navegador moderno.
3. **Tela única de entrada** (19/10 13:00: servidor, usuário e senha juntos; seção 3.2).
4. **Iniciar sessão** → a logo **cresce até ocupar a tela** → **2ª animação**, de 3 a 5 s, enquanto a home carrega.
5. A home aparece já pronta.
- **Sessão salva** (decidido 19/10): abertura → a logo cresce → 2ª animação → home. Total de ~5–7 s, a validar no teste.
- **Servidor lembrado** (decidido 19/10): a tela de entrada já vem com o endereço preenchido.

### 3.2 Tela única de entrada (base: `streamyfin/…servidor` e `streamyfin/…login`, com os cortes do Caio)
- Topo: à direita, o ícone de **Quick Connect** (discreto). À esquerda, nada: na tela única não há "voltar".
- A **logo** no lugar em que a abertura pousou.
- Campo **"Digite o endereço do servidor"**. Quando o servidor responde, aparece embaixo, bem discreto, **"✓ <nome do
  servidor>"** (vindo do próprio servidor). Isso substitui o "Iniciar sessão em CGFLIX" e a URL, que o Caio cortou.
- Campo **Usuário** e campo **Senha**. A senha pode ficar vazia: [V] 28 das 35 contas do CGSERVER não têm senha.
- Botão **Iniciar sessão**. Sem "Guardar esta conta" (a sessão fica salva), sem "custom headers", sem "procurar servidores locais".
- Erros em uma linha, sob o campo culpado: servidor não encontrado, usuário ou senha incorretos, etc.
- Endereço: aceita sem `https://` e tenta também o caminho `/jellyfin`, como os clientes fazem.
  - [V] O Jellyfin responde CORS `*`, local e pela VPS, então outro servidor Jellyfin funciona.
  - Limite do navegador: um site em https não fala com servidor `http://`. Nesse caso a mensagem explica e indica os apps.
- **Quick Connect** [V], ligado no CGSERVER: ativo só depois que o servidor responde. Abre uma folha pequena com o código
  grande e "Autorize em outro aparelho já conectado"; entra sozinho quando alguém autoriza.
- Computador: o mesmo conteúdo numa coluna central de ~400 px.

### 3.3 Segunda animação [P]
Pedido do Caio: "inversa da primeira ou algo assim", fluida, de 3 a 5 s. A ideia:
- a logo cresce e ocupa a tela;
- o selo "respira" e o traço de luz percorre o HEISUCA;
- o campo de cor do selo **muda para a cor tirada do pôster do 1º destaque**;
- o selo se desfaz e a imagem do destaque aparece.

A animação termina já com a home na cor certa. Duração: no mínimo 3 s e no máximo 5 s; fecha quando o destaque, o
Continuar e a 1ª fileira estiverem prontos, com as imagens decodificadas. Rede lenta: aos 5 s a home abre, com
esqueleto no que faltar. **Antes de entrar no site, as duas animações vão em vídeo (MP4 da bancada) para você aprovar.**

### 3.4 Navegador de TV
Sem modo TV no site. A TV terá app próprio. O teste é **por recurso** (o que o navegador realmente faz), não pelo nome:
- TV moderna compatível: o site normal, com ponteiro.
- TV incompatível: uma tela limpa, "O Heisuca na TV é pelo app", com o link para Baixar os apps.

---

## 4. Home (`vidhub/…home_topo`, `vidhub/…home_rolada`, `vidhub/…foto67`; Caio 18/10 22:17 e 19/10 06:08)
- **Topo sem barra:** à esquerda, a pílula [foto + nome do servidor], que abre o "Trocar servidor" discreto; à direita,
  a busca redonda. **Sem os 3 pontinhos.** Nada de faixa semi-transparente de ponta a ponta (erro de `heisuca_reprovado/…foto66`).
- **Destaque:** a arte vai até o topo e se dissolve na cor tirada do pôster, sem faixa separando. No centro:
  - a logo do título;
  - a linha `★ 8,6 | 2000–2010 | gêneros | [BR-12]`;
  - a sinopse em 2 linhas no formato `「Título」 texto`;
  - os pontinhos do carrossel.

  A troca é automática e para quando o dedo ou o mouse está em cima. Os itens são **[P]** os ~9 últimos adicionados
  que tenham arte e logo.
- **Ao rolar:** a logo sobe e encaixa no topo, entre a pílula e a busca (`vidhub/…home_rolada`).
- **Fileiras, nesta ordem:**
  1. **Continuar**: 16:9, ▶ no centro, `26:44 / 40:39`, barra de progresso, título + `S1:E1 - nome`;
  2. **Próximo**: 16:9; **[P]** sem repetir o que já está em Continuar;
  3. **Mídia**: as bibliotecas como cartões 16:9 com o nome por cima. **É aqui que as bibliotecas ficam**, nunca em
     chips sob o destaque;
  4. uma fileira por biblioteca, com "Ver tudo ›": pôster 2:3, nota no canto inferior direito, título + anos.
- **Em alta no Brasil e Em breve entram (decidido 19/10)**, quando o servidor oferece. "Em alta" é o Top 10 com os números
  em contorno alinhados à base do pôster (`app_completo/…foto21`), vindo do `emalta.json` que o servidor publica. "Em breve" fica
  **no fim** (P13) e vem do plugin Home Screen Sections + `embreve.json`. O código do `master` já lê os dois. Servidor sem
  essas listas: as fileiras não aparecem.
- **Ordem final:** Continuar · Próximo · Em alta no Brasil · Mídia · uma fileira por biblioteca · Em breve.
- **Ilha inferior** flutuante de vidro, centralizada e compacta: **Início · Biblioteca · Favoritos · [foto] Usuário**
  (18/10 22:17). Nada de barra cheia presa embaixo (erro de `heisuca_reprovado/…foto66`).
- **Botão direito no cartão** (toque longo no celular): Marcar como visto/não visto · Favoritar/Desfavoritar (18/10 22:24).
- **Computador:** a mesma estrutura, com destaque mais largo (até ~80% da altura), mais cartões por fileira e a ilha
  centralizada embaixo (decidido 19/10).

## 5. Título (`vidhub/…foto42`, `…foto43`, `…foto44`; Caio 18/10 22:17–22:24 e 19/10 06:27)
- A arte vai até o topo e se dissolve na cor tirada do pôster. ← voltar no topo. **Sem ⋯ no topo:** as ações viram **♡ e ⚑
  abaixo do Reproduzir** (Favoritar · Visto/Não visto).
- Logo centralizada. A linha `★ 7,1 | 20/03/2004 | HBO | gêneros | [BR-18]` e, embaixo, em letra pequena,
  `3 temps. · 1h2min · 1080p H264 SDR`.
- **Reproduzir**: largo, em pílula translúcida; mostra "Continuar T1:E3" quando houver progresso. **Ao rolar, gruda no topo**
  com a linha pequena (`vidhub/…foto43`).
- Sinopse pequena do episódio da vez: `「Deadwood·Temp. 1·EP 1」 …`.
- `Temporada 1 ⌄` à esquerda e `Ver tudo ›` à direita. A temporada abre **contida**: folha no celular, caixa flutuante no
  computador, com rolagem própria. Fecha ao escolher ou ao tocar fora. Nunca empurra nem cobre a página (erro de
  `heisuca_reprovado/…foto72`).
- Episódios em fileira 16:9; o atual com borda; `1. Título` embaixo. Páginas `1-10` e `11-12` em pílulas quando a temporada é longa.
- **Elenco:** fotos em **quadrado arredondado** (não círculo), com nome e personagem. Sem foto, uma silhueta discreta, nunca
  uma letra por cima da foto (erro de `heisuca_reprovado/…foto71`).
- Gêneros em pílulas.
- **Info mídia (decidido 19/10): tabela refinada, sem o caminho do arquivo.** Dois cartões, Vídeo e Áudio, com tipografia
  fina e divisórias leves:
  - Vídeo: resolução, codec e perfil, HDR/SDR, quadros por segundo, bitrate;
  - Áudio: idioma, codec, canais, padrão.

  **Linha sem dado não aparece.** O Gemini escrevia "HEVC / H.264" e "AAC / EAC3" quando faltava (`Titulo.tsx:339,364` do
  ramo dele): isso é proibido.
- Idioma: a sinopse do HSOTD veio em inglês (`heisuca_reprovado/…foto70`). Usar o que o servidor tiver em PT; se só houver
  inglês, mostrar o inglês. Conferir a configuração de metadados do CGSERVER à parte.

## 6. Biblioteca (`vidhub/…foto50`, `…foto51`; Caio 18/10 22:24)
- Topo: ← | nome da biblioteca no centro | ícone à direita que abre o **menu lateral direito com as bibliotecas**, para trocar direto.
- **Somem** as abas Séries/Episódios/Gêneros/Pastas. **Sem ordenar e sem filtrar** (decidido 19/10). Ordem alfabética,
  como no print.
- Grade: 3 colunas no celular, mais no computador. Pôster 2:3, nota no canto inferior direito, ✓ visto no canto superior
  direito, título + anos. Carrega aos poucos, conforme a rolagem.
- Botão direito: Marcar visto · Favoritar (o "Excluir" do VidHub não entra).

## 7. Favoritos (`vidhub/…favoritos`; Caio 19/10 13:00: "separam por biblioteca")
- O mesmo topo da home (pílula do servidor e busca); fundo desfocado tirado do 1º favorito.
- Uma seção por biblioteca (o nome da biblioteca + "Ver tudo ›"), com pôster 2:3, nota, ✓ e título + anos.
- Vazio: uma frase curta, "Toque em ♡ num título para guardá-lo aqui". Sincronizado com o servidor (o favorito do Jellyfin).

## 8. Busca (`app_completo/…busca_seerr`; o VidHub não tem pedidos: `vidhub/…busca`)
- Topo: ← **Buscar**; campo em pílula com 🔍 e ✕. Busca a partir de 2 letras, 300 ms depois de parar de digitar.
- **Do acervo:** pôster à esquerda, título, `BR-14 • 2015 • 2h 28m • 6.6★`, sinopse em 3 linhas e a origem `<servidor> • <biblioteca>`.
- **"Disponível para pedir"**, só se o servidor tiver Seerr: "Ainda não temos. Peça e avisamos quando chegar." Linhas com
  pôster pequeno, título, `2006 · Filme` e o botão **+ Pedir**. Na série, abre a escolha de temporadas, como já existe.
- **Detecção do Seerr** (decidido 19/10): [V] o CGSERVER responde `/__seerr/api/v1/status` na mesma origem. Se o
  endereço não responder, a busca fica só no acervo. O login no Seerr é por Quick Connect, sem segunda senha: o código do
  `master` já faz isso (`api/seerr.ts`).

## 9. Menu do usuário (`app_completo/…menu_usuario`, enxugado; Caio 18/10 22:24 e 19/10 13:00)
- **Abre a partir da foto na ilha**: cresce do ícone, e não de baixo para cima (pedido de 18/10 21:00). No computador, igual.
- Itens:
  1. Cabeçalho: foto + nome + "Minha conta: foto e senha ›";
  2. **Como usar**: no topo enquanto houver passo sem marcar; com tudo marcado, desce para o fim, junto do Sobre
     (18/10 21:00; **[P]**, porque o site não tem tela de configurações);
  3. **Meus pedidos**: só com Seerr (**[P]**, está no menu do app completo);
  4. **Tema**: abre a escolha Roxo · Verde · Automático;
  5. **Baixar os apps**;
  6. **Sobre**;
  7. **Apoiar o Heisuca**: "Em breve" até existir a doação;
  8. **Sair**.
- Saem, em relação ao app completo: Favoritos e Bibliotecas (já estão na ilha), Baixados (o navegador não baixa),
  Configurações e Avançado (o site não tem ajustes avançados), Trocar usuário (Sair resolve, e o servidor fica lembrado).
- **Sobre:** nome, versão, "Nada entre você e o filme.", licença GPL-3.0 com link do código, créditos (bibliotecas usadas,
  Rosiel Victor, "Locadora" só pelo nome) e a dedicatória, **sem nomes da família** (NOVA_FASE/BASE_MARCA).

## 10. Minha conta (`app_completo/…minha_conta`)
- ← Minha conta; foto grande; nome; **Trocar foto** (pílula clara) e **Remover foto** (ícone de lixeira).
- **Trocar senha:** "A senha vale para todos os aparelhos. Depois da troca, os outros aparelhos pedem para entrar de novo"
  (a conferir no teste). Campos Senha atual ("vazia se você não tem"), Nova senha e Confirmar, com o olho para mostrar. Botão
  **Salvar nova senha**.
- **Sem "autorizar aparelho" (Quick Connect) no site** (decidido 19/10): fica para os apps e para o app de TV. O site só
  **entra** por Quick Connect (o ícone da tela de entrada).

## 11. Como usar (referência: `netflix.docaio.com.br/cgflix/ajuda.html`)
Passos com caixinha de "Feito", a mesma mecânica de hoje, guardada no aparelho:
1. Entrar no site;
2. Criar ou trocar a senha (→ Minha conta);
3. Pôr uma foto no perfil (→ Minha conta);
4. Instalar no aparelho: as instruções de iPhone/Safari, Android/Chrome e Edge, iguais às de hoje, + "Baixar os apps";
5. Pedir filmes e séries: só com Seerr.

Depois dos passos:
- **Avisos no aparelho:** "Em breve";
- **Dúvidas:** só as que valem para qualquer servidor. Esqueci a senha → "fale com quem administra o seu servidor"; como
  sair → menu do usuário → Sair.

**Fica de fora**, porque é do CGSERVER e não do Heisuca: Stremio/Nuvio, as regras da casa (2 telas, suporte com o Caio), o
endereço netflix.docaio e o "áudio em português por padrão".

## 12. Baixar os apps (referência: `netflix.docaio.com.br/cgflix/apps.html`)
- A mesma estrutura de cartões por plataforma da página de hoje, com a marca Heisuca.
- **Instalar o site como app**: o único disponível agora, com os passos por navegador (Chrome no Android, Safari no iPhone, Edge no Windows).
- Android, Android TV, TVs Samsung e LG, iPhone e iPad: **"Em breve"**. São as plataformas do README do Heisuca.
- Nada de CGFLIX, Swiftfin, Streamyfin ou Infuse, que eram recomendações do CGSERVER.

## 13. Player (`vidhub/…foto44–49`; `app_completo/…foto24–25`; Caio 18/10 22:24 e 19/10 06:27)
- **Carregamento:** a nossa animação (o selo), no lugar dos pontinhos "Carregando" (`vidhub/…foto45`).
- **Controles:**
  - topo: ← + título (`Deadwood S1E1`);
  - centro: ⏮ · −10 · ⏯ · +10 · ⏭ (anterior e próximo só em série);
  - base: barra fina com o tempo, **Áudio e legendas**, **tela cheia**.
- **Removidos** (decidido): girar, trava, ícones de capítulos e episódios, menu avançado ⋮, transmitir, captura,
  velocidade, gestos de brilho e volume, PiP e "Carregar legenda local".
- **Áudio e legendas:** painel em duas colunas com ✕, como o do app completo (`app_completo/…foto25`), que você elogiou.
  Fecha no ✕, ao tocar fora ou ao escolher. Nunca fica preso sobre o vídeo (erro de `heisuca_reprovado/…foto20`).
- **"Buscar legendas…"** (decidido 19/10: os plugins de legenda têm de ajudar o usuário). [V] O Open Subtitles está
  instalado com credenciais válidas. Fluxo: Buscar → lista de resultados em PT → baixar → a legenda entra na lista na hora.
  **Liberado (19/10):** as 35 contas do CGSERVER têm "gerenciar legendas" (antes só 1; backup em
  `~/.cgflix/state/backup_politicas_jellyfin_20261019.json`). Em servidor de outra pessoa, sem a permissão, o botão não aparece.
  Busca testada: o código `pob` traz PT-BR e o `por` mistura Portugal; o site busca `pob` primeiro e mostra `por` depois,
  separado. O limite diário de downloads da conta do Open Subtitles é dividido entre todos: mais contas ficaram anotadas
  para depois (RETOMADA).
- **Pular abertura e créditos com dado real** (decidido): botão "Pular abertura" ou "Pular créditos", no canto inferior
  esquerdo, acima da barra, como no `vidhub/…foto48`. Aparece **só dentro do capítulo** e pula para o início do capítulo
  seguinte; se os créditos forem o fim da série, vai para o próximo episódio. Nomes reconhecidos (contados no acervo): Intro,
  Opening, OP, Opening Credits, Title Sequence, Abertura → abertura; Credits, End Credits, ED, Ending, Encerramento → créditos.
  [V] Cobertura medida em 19/10 (só pela API, sem ler o Drive):

  | | Total | Com capítulos | Com abertura | Com créditos |
  |---|---|---|---|---|
  | Episódios | 13.428 | 9.698 (72%) | ~5.850 (44%) | 7.316 (54%) |
  | Filmes | 1.074 | 633 | 56 | 432 (40%) |

  Onde não há capítulo, não há botão. O Intro Skipper (que ouve o áudio de cada episódio) cobriria o resto, mas lê o acervo
  inteiro no Drive: fica para depois, com medição de custo e o seu OK.
- **Motor que fica** (do `master`, testado em 18/10): perfil do aparelho perguntado ao navegador, toca direto quando dá,
  senão HLS fMP4 (remonta, sem converter o vídeo), guarda "toca sem quadro" (o caso do One Piece no Chrome do Android),
  ASS pelo JASSUB, retomar, relatório de progresso e próximo episódio.
- **Ao sair, o vídeo para de verdade:** pausa, descarrega e encerra a conversão no servidor (bug de `heisuca_reprovado/…foto18`).
- Limite de telas do servidor (o CGSERVER tem 2): mensagem clara de "limite de telas atingido", não erro genérico.
- Computador **[P]**: atalhos padrão de player web (espaço, ←/→ 10 s, F tela cheia, Esc).

---

## 14. Código: o que fica, o que é refeito e o que sai
| Parte | Destino |
|---|---|
| Vite + Preact + TypeScript, build e `publicar-teste` | **fica** (leve: a v1 mediu 222 ms e 249 KB contra 1.125 ms e 5,9 MB do site atual) |
| `api/jellyfin.ts`, `api/perfil.ts`, `api/seerr.ts`, motor do player, bancadas | **fica**, revisado |
| Todas as telas e todo o CSS | **refeito**, seguindo este plano |
| `tv.ts`, `foco.ts`, pacote Tizen | **sai do site** (vão para o app de TV) |
| Ramo `gemini/recriacao-site` | **fica intocado**, só para consulta |

**Licenças (decidido 19/10):** "se o que vamos usar é igual entre eles, pegue o do Jellyfin; se não, o que for melhor, e damos
os créditos".
- O jellyfin-web é GPL-2.0-or-later, compatível com a nossa GPL-3.0 ([V], rodada 1): pode ser copiado. O
  jellyfin-androidtv é GPL-2.0 sem "or later": esse continua fora.
- Plezy e Findroid (GPL-3), MIT e Apache: podem ser copiados.
- Todo trecho copiado leva o crédito no arquivo e na lista `CREDITOS.md` do repositório (que aparece no Sobre).
- O VidHub é fechado: dele só aproveitamos as ideias.

## 15. Execução (depois do seu OK)
**Fase 0 — Fundação** (sessão principal, eu):
1. Ramo novo `site-v2`, a partir do `master`.
2. Temas, motor de cor (BlurHash → OKLCH → contraste) e as peças comuns: topo flutuante, ilha, folha/caixa contida,
   menu de contexto, cartões, fileira e voo da logo.
3. **Respostas reais da API** de 6 títulos (InuYasha, Deadwood, One Piece, HSOTD, Aoashi e um filme), limpas (sem token,
   sem caminho de arquivo), mais um servidor de teste local. Assim as sessões da nuvem trabalham sem acesso ao CGSERVER.
4. **Comparador:** tira o print no tamanho do seu celular e monta lado a lado com o `ref/`.
   O tamanho exato do Moto edge 60 pro, meço na sua 1ª visita ao teste.

**Fase 1 — Telas em paralelo** (sessões na nuvem, crédito até 05/11), cada uma num ramo, com este plano, os prints e a fundação:

| Sessão | Telas |
|---|---|
| A | Entrada + animações (com vídeo para aprovação) |
| B | Home + Favoritos |
| C | Título + Biblioteca |
| D | Busca + Usuário + Minha conta + Como usar + Baixar os apps |
| E | Interface do player (o teste com vídeo real é aqui, na bancada da VPS) |

Eu reviso e junto cada uma.

**Fase 2 — Verificação:**
- prints lado a lado no celular e no computador;
- **revisão independente dos Minions** (Gemini, pelo cgmind, só consulta) com a lista de regras de cada tela;
- testes na VPS: navegação, login com e sem senha, Quick Connect, player (direto, HLS, ASS, guarda, pular abertura,
  legendas) e 2 telas;
- **disputa** contra o site atual e contra a v1 do Gemini: abertura, peso, memória, DOM;
- contraste AA em todas as cores tiradas de pôster.

Consultas mecânicas vão para o `braco` e os testes/relatórios para o `operario`.

**Fase 3 — Entrega por tela**, no teste exclusivo seu (`/__heisuca/`), com aviso no Telegram (o que mudou, onde, como
desfazer). Você testa no celular, eu ajusto, e refaço se for preciso.

**Uma tela só está "pronta" quando:**
1. o print lado a lado com a referência não tem diferença de estrutura (posição, proporção, ordem) e tem as suas mudanças;
2. a revisão dos Minions não aponta nada grave;
3. não há erro no console, o contraste é AA e o teclado funciona no computador;
4. só aparece dado real (nada fixo, nada inventado);
5. a medição não piora o orçamento de desempenho.

---

## 16. Decisões do Caio (respondidas em 19/10, tarde)
1. **Verde é claro**; Automático = aparelho escuro → Roxo / claro → Verde. (§2.1)
2. **Legendas liberadas** para todas as contas (feito 19/10); mais contas do Open Subtitles depois. (§13)
3. **Em alta e Em breve entram** na home. (§4)
4. **Sem autorizar aparelho no site**: fica para os apps e o app de TV. (§10)
5. **Licenças:** se a peça é igual, a do Jellyfin; se não, a melhor; sempre com crédito. (§14)

Valem se você não vetar: [P] da §3.3 (2ª animação), §4 (itens do destaque, Próximo sem repetir), §9 (Como usar no fim
quando completo, Meus pedidos com Seerr) e §13 (atalhos de teclado).
