# P3 — pente fino, em andamento

Base antes dos ajustes visuais: P2 concluída, código 13e8f76, docs 966b55e.
Versão final pedida: 2.0.34+36. Isto é registro de trabalho, não aprovação visual
independente nem teste físico. Não publicar o APK.

## Prova antes de alterar o produto

`test/heisuca/heisuca_p3_style_test.dart`: **14 falhas reais antes do patch**,
log em `evidencias/p3_estilo_antes_2026-10-27.txt`. Títulos do tema herdavam
Inter; logo completo e Sobre digitavam HEISUCA; login/Você usavam canvases
soltos antigos; dicas do login não passavam AA no preenchimento renderizado.

Matriz inicial de telas reais, 1080×2400, fonte 100/200%: overflow de 9 px na
Início e 11 px na Biblioteca com fonte 200%; Aparência também estourou à direita.
Ao assistir/Reprodução não pôde montar SettingNumberTile: o pref de episódios
clampa 0…20 no serviço, mas falta na tabela numericBounds consultada pela UI.
Isso é uma inconsistência do contrato numérico, não motivo para inventar faixa.
Registro/capturas completos da matriz ainda em preparação; nenhum patch visual
foi aplicado até estas capturas anteriores estarem prontas.

## Método e limites

A matriz monta os widgets/rotas REAIS com fixture local determinística de
Jellyfin, banco em memória e download vazio; não há conta real. Busca é
`SearchScreen` (rota de MainScreen), NÃO o protótipo `HeisucaSearchScreen`.
Os testes exercitam corpo/rolagem/semântica de toque; rotas secundárias têm uma
rota anterior para que o botão Voltar corresponda ao fluxo real.

Celular: 1080×2400, DPR 2,625; tablet: 1200×1920, DPR 1,5 (invertidos em
paisagem). DPRs são parâmetros da fixture, não medições dos aparelhos do Caio.
Fontes carregadas dos arquivos reais Sora/Inter e ícones empacotados. Host Linux:
ramos condicionados a dart:io Platform não equivalem a Android nativo.
Capturas de widget não comprovam superfícies mpv, rede, autenticação ou download.
Esses limites devem permanecer explícitos no fechamento, junto dos testes CI.

`P3_CAPTURE_PHASE=antes/depois` grava PNGs/JSONs em `docs/evidencias/p3/`.
JSON por combinação registra dimensão, DPR, fonte, páginas verificadas e erros.
Capturas representativas por tela/tema, de estresse e falhas são preservadas;
`P3_CAPTURE_ALL=1` permite todas. `P3_SCREEN`/`P3_CASE` isolam reprodução.
Qualquer erro de layout/toque torna o teste vermelho; coleta não é aprovação.
Não confundir falha de configuração da fixture com defeito do app: o provider de
preferências foi registrado antes da coleta válida; semântica/imagem são
fechadas na zona correta do Flutter Test. Nenhuma regra de overflow foi relaxada.

## Pendente nesta parte

Concluir matriz anterior, corrigir causas com testes, gerar comparação posterior,
conferir subsettings/estados/HUD/folhas, toque ≥48 dp e foco, cores por tokens,
Sora/Inter, PT-BR, PNGs e goldens. Preservar composição aprovada da Início em 100%;
respeitar fonte 200% sem limitar a escala para esconder overflow.

Barras/iluminação: ainda sem prova do arquivo de origem nesta P3. Não atribuir
letterbox gravado só pela captura; não alterar proporção/recorte para maquiar.
P4–P7 continuam pendentes. Revisão independente e aparelhos pendentes.

## P3 — base visual e acessibilidade, progresso local (sem fechamento)

A coleta válida anterior cobriu **624 combinações** (26 telas × 3 temas ×
2 tamanhos × 2 orientações × fontes 100/200%): 435 passaram e 189 tiveram
apontamentos. Isso NÃO significa 189 defeitos diferentes. Log completo:
`evidencias/p3_matriz_antes_2026-10-27.txt`. As capturas e os JSONs ficam em
`evidencias/p3/antes/`. Os 14 testes de estilo anteriores, mais as provas de
teclado, escala dos cartões/opções e títulos de seção, reproduzem causas reais.

Correções locais, ainda sem commit de código nesta anotação:

- Tipografia do tema: títulos Sora, corpo Inter; marca completa e Sobre usam o
  SVG oficial, sem HEISUCA digitado. Canvas de login/Você e campo de login
  seguem tokens. O campo tem um único preenchimento/borda; o botão usa ação e
  texto da paleta, cresce com o texto e dispensa o degradê/sombra antigos.
- Reprodução: o limite de episódios já era 0–20 no serviço, mas não constava
  em numericBounds; a tela agora recebe os mesmos limites. Padrão 3, sono de
  20 minutos e fluxo de continuação preservados.
- Pôsteres, grade da Biblioteca e episódios reservam altura com a fonte e a
  largura reais, mantendo as dimensões anteriores quando o conteúdo cabe.
  Cartões largos e grupos de opções deixam de encolher a fonte. A faixa de
  episódios mede o título e os metadados de cada episódio; não corta o texto
  para esconder o overflow. Início em 100% mantém a composição aprovada.
- Abas de Configurações, Voltar de Você, ações do menu, Restaurar e Assistir
  encaixado respeitam o mínimo de 48 dp. O botão Heisuca reaproveita
  FocusableWrapper para teclado/controle, preservando o gesto de toque.

A primeira comparação após essas correções teve 603/624 aprovados; os 21
restantes eram medições de fragmentos recortados na borda da rolagem. A inspeção
confirmou, por exemplo, o campo de 79 dp reduzido semanticamente a 24,3 dp na
borda superior. O guia do Flutter ignora bordas de ancestrais com rolagem
implícita, mas não esse recorte diretamente no nó. O auxiliar de teste passa a
consultar parentPaintClipRect com a mesma tolerância de borda (0,001); conserva
48 dp para controles inteiros. Não altera o app, não libera overflow nem reduz
a exigência. Provas com as coordenadas coletadas: dois recortes falhavam antes,
controle inteiro de 40 dp continua elegível para reprovação; quatro casos passam
com o auxiliar correto. Evidência:
`evidencias/p3_medicao_recorte_antes_2026-10-27.txt`.

Matriz posterior: **624/624 aprovados** (`/tmp/p3-matrix-after-clips.log`).
Testes focados de estilo/acessibilidade/medição: **21 aprovados** antes dos dois
ajustes finais de títulos de seção. Os testes existentes de flagship passaram
**16/16**; o teste de abertura foi ajustado para rolar uma lista preguiçosa antes
de procurar a opção e depois de reabrir, mantendo a verificação de persistência.
Paridade do topo/gesto da ficha e cartões também passaram; o portão completo
está em execução em `/tmp/p3-first-gate.log`. Ainda não há run novo da P3.

A matriz é local com fixture. Não prova aparelho, servidor real, imagem nativa
nem revisão independente. Ainda faltam HUD/folhas/diálogos/estados e revisão do
restante das cores/textos, capturas finais e goldens. P3 não está fechada.

## Galeria para revisão independente

O portão final desta coleta passou: **1.755 testes Flutter, 3 skips de capturas
opcionais, 8 Impeller e 46 Python** (`/tmp/p3-adjusted-final-gate.log`).
As 624 combinações de telas e 96 do player foram refeitas com a árvore final.
Não é aprovação visual independente nem teste em aparelho.

A tabela liga capturas representativas de cada tela: celular/retrato/100% nos
três temas e tablet/paisagem/200% em Shikkoku. Os JSONs registram as 24
combinações por tela, incluindo a rolagem. Quadros byte a byte idênticos da
mesma combinação foram deduplicados; `capturas_duplicadas.json` aponta o
arquivo preservado e seu SHA-256. Capturas posteriores de coletas anteriores
foram retiradas; as imagens posteriores são da execução final.

| Tela/caso | Antes | Depois |
|---|---|---|
| baixados-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/baixados-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/baixados-oled-moto-retrato-f100.png) |
| baixados-light-moto-retrato-f100 | [antes](evidencias/p3/antes/baixados-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/baixados-light-moto-retrato-f100.png) |
| baixados-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/baixados-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/baixados-dark-moto-retrato-f100.png) |
| baixados-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/baixados-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/baixados-oled-tab-paisagem-f200.png) |
| barra-abas-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/barra-abas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/barra-abas-oled-moto-retrato-f100.png) |
| barra-abas-light-moto-retrato-f100 | [antes](evidencias/p3/antes/barra-abas-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/barra-abas-light-moto-retrato-f100.png) |
| barra-abas-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/barra-abas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/barra-abas-dark-moto-retrato-f100.png) |
| barra-abas-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/barra-abas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/barra-abas-oled-tab-paisagem-f200.png) |
| biblioteca-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/biblioteca-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/biblioteca-oled-moto-retrato-f100.png) |
| biblioteca-light-moto-retrato-f100 | [antes](evidencias/p3/antes/biblioteca-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/biblioteca-light-moto-retrato-f100.png) |
| biblioteca-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/biblioteca-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/biblioteca-dark-moto-retrato-f100.png) |
| biblioteca-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/biblioteca-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/biblioteca-oled-tab-paisagem-f200.png) |
| busca-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/busca-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/busca-oled-moto-retrato-f100.png) |
| busca-light-moto-retrato-f100 | [antes](evidencias/p3/antes/busca-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/busca-light-moto-retrato-f100.png) |
| busca-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/busca-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/busca-dark-moto-retrato-f100.png) |
| busca-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/busca-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/busca-oled-tab-paisagem-f200.png) |
| config-aparencia-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-aparencia-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-aparencia-oled-moto-retrato-f100.png) |
| config-aparencia-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-aparencia-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-aparencia-light-moto-retrato-f100.png) |
| config-aparencia-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-aparencia-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-aparencia-dark-moto-retrato-f100.png) |
| config-aparencia-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-aparencia-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-aparencia-oled-tab-paisagem-f200.png) |
| config-avancada-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-avancada-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-avancada-oled-moto-retrato-f100.png) |
| config-avancada-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-avancada-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-avancada-light-moto-retrato-f100.png) |
| config-avancada-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-avancada-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-avancada-dark-moto-retrato-f100.png) |
| config-avancada-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-avancada-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-avancada-oled-tab-paisagem-f200.png) |
| config-basicas-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-basicas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-basicas-oled-moto-retrato-f100.png) |
| config-basicas-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-basicas-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-basicas-light-moto-retrato-f100.png) |
| config-basicas-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-basicas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-basicas-dark-moto-retrato-f100.png) |
| config-basicas-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-basicas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-basicas-oled-tab-paisagem-f200.png) |
| config-completas-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-completas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-completas-oled-moto-retrato-f100.png) |
| config-completas-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-completas-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-completas-light-moto-retrato-f100.png) |
| config-completas-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-completas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-completas-dark-moto-retrato-f100.png) |
| config-completas-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-completas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-completas-oled-tab-paisagem-f200.png) |
| config-geral-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-geral-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-geral-oled-moto-retrato-f100.png) |
| config-geral-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-geral-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-geral-light-moto-retrato-f100.png) |
| config-geral-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-geral-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-geral-dark-moto-retrato-f100.png) |
| config-geral-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-geral-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-geral-oled-tab-paisagem-f200.png) |
| config-legendas-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-legendas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-legendas-oled-moto-retrato-f100.png) |
| config-legendas-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-legendas-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-legendas-light-moto-retrato-f100.png) |
| config-legendas-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-legendas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-legendas-dark-moto-retrato-f100.png) |
| config-legendas-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-legendas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-legendas-oled-tab-paisagem-f200.png) |
| config-mpv-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-mpv-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-mpv-oled-moto-retrato-f100.png) |
| config-mpv-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-mpv-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-mpv-light-moto-retrato-f100.png) |
| config-mpv-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-mpv-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-mpv-dark-moto-retrato-f100.png) |
| config-mpv-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-mpv-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-mpv-oled-tab-paisagem-f200.png) |
| config-player-externo-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-player-externo-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-player-externo-oled-moto-retrato-f100.png) |
| config-player-externo-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-player-externo-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-player-externo-light-moto-retrato-f100.png) |
| config-player-externo-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-player-externo-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-player-externo-dark-moto-retrato-f100.png) |
| config-player-externo-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-player-externo-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-player-externo-oled-tab-paisagem-f200.png) |
| config-reproducao-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-oled-moto-retrato-f100.png) |
| config-reproducao-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-light-moto-retrato-f100.png) |
| config-reproducao-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-dark-moto-retrato-f100.png) |
| config-reproducao-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-reproducao-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-reproducao-oled-tab-paisagem-f200.png) |
| config-reproducao-avancada-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-avancada-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-avancada-oled-moto-retrato-f100.png) |
| config-reproducao-avancada-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-avancada-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-avancada-light-moto-retrato-f100.png) |
| config-reproducao-avancada-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-reproducao-avancada-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-reproducao-avancada-dark-moto-retrato-f100.png) |
| config-reproducao-avancada-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-reproducao-avancada-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-reproducao-avancada-oled-tab-paisagem-f200.png) |
| config-servicos-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/config-servicos-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-servicos-oled-moto-retrato-f100.png) |
| config-servicos-light-moto-retrato-f100 | [antes](evidencias/p3/antes/config-servicos-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-servicos-light-moto-retrato-f100.png) |
| config-servicos-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/config-servicos-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/config-servicos-dark-moto-retrato-f100.png) |
| config-servicos-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/config-servicos-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/config-servicos-oled-tab-paisagem-f200.png) |
| ficha-filme-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-filme-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-filme-oled-moto-retrato-f100.png) |
| ficha-filme-light-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-filme-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-filme-light-moto-retrato-f100.png) |
| ficha-filme-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-filme-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-filme-dark-moto-retrato-f100.png) |
| ficha-filme-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/ficha-filme-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/ficha-filme-oled-tab-paisagem-f200.png) |
| ficha-serie-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-serie-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-serie-oled-moto-retrato-f100.png) |
| ficha-serie-light-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-serie-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-serie-light-moto-retrato-f100.png) |
| ficha-serie-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/ficha-serie-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/ficha-serie-dark-moto-retrato-f100.png) |
| ficha-serie-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/ficha-serie-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/ficha-serie-oled-tab-paisagem-f200.png) |
| inicio-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/inicio-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/inicio-oled-moto-retrato-f100.png) |
| inicio-light-moto-retrato-f100 | [antes](evidencias/p3/antes/inicio-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/inicio-light-moto-retrato-f100.png) |
| inicio-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/inicio-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/inicio-dark-moto-retrato-f100.png) |
| inicio-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/inicio-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/inicio-oled-tab-paisagem-f200.png) |
| kids-config-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/kids-config-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/kids-config-oled-moto-retrato-f100.png) |
| kids-config-light-moto-retrato-f100 | [antes](evidencias/p3/antes/kids-config-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/kids-config-light-moto-retrato-f100.png) |
| kids-config-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/kids-config-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/kids-config-dark-moto-retrato-f100.png) |
| kids-config-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/kids-config-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/kids-config-oled-tab-paisagem-f200.png) |
| licencas-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/licencas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/licencas-oled-moto-retrato-f100.png) |
| licencas-light-moto-retrato-f100 | [antes](evidencias/p3/antes/licencas-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/licencas-light-moto-retrato-f100.png) |
| licencas-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/licencas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/licencas-dark-moto-retrato-f100.png) |
| licencas-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/licencas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/licencas-oled-tab-paisagem-f200.png) |
| login-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/login-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/login-oled-moto-retrato-f100.png) |
| login-light-moto-retrato-f100 | [antes](evidencias/p3/antes/login-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/login-light-moto-retrato-f100.png) |
| login-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/login-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/login-dark-moto-retrato-f100.png) |
| login-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/login-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/login-oled-tab-paisagem-f200.png) |
| menu-titulo-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/menu-titulo-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/menu-titulo-oled-moto-retrato-f100.png) |
| menu-titulo-light-moto-retrato-f100 | [antes](evidencias/p3/antes/menu-titulo-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/menu-titulo-light-moto-retrato-f100.png) |
| menu-titulo-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/menu-titulo-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/menu-titulo-dark-moto-retrato-f100.png) |
| menu-titulo-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/menu-titulo-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/menu-titulo-oled-tab-paisagem-f200.png) |
| novidades-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/novidades-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/novidades-oled-moto-retrato-f100.png) |
| novidades-light-moto-retrato-f100 | [antes](evidencias/p3/antes/novidades-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/novidades-light-moto-retrato-f100.png) |
| novidades-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/novidades-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/novidades-dark-moto-retrato-f100.png) |
| novidades-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/novidades-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/novidades-oled-tab-paisagem-f200.png) |
| perfis-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/perfis-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/perfis-oled-moto-retrato-f100.png) |
| perfis-light-moto-retrato-f100 | [antes](evidencias/p3/antes/perfis-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/perfis-light-moto-retrato-f100.png) |
| perfis-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/perfis-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/perfis-dark-moto-retrato-f100.png) |
| perfis-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/perfis-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/perfis-oled-tab-paisagem-f200.png) |
| sobre-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/sobre-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/sobre-oled-moto-retrato-f100.png) |
| sobre-light-moto-retrato-f100 | [antes](evidencias/p3/antes/sobre-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/sobre-light-moto-retrato-f100.png) |
| sobre-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/sobre-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/sobre-dark-moto-retrato-f100.png) |
| sobre-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/sobre-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/sobre-oled-tab-paisagem-f200.png) |
| voce-oled-moto-retrato-f100 | [antes](evidencias/p3/antes/voce-oled-moto-retrato-f100.png) | [depois](evidencias/p3/depois/voce-oled-moto-retrato-f100.png) |
| voce-light-moto-retrato-f100 | [antes](evidencias/p3/antes/voce-light-moto-retrato-f100.png) | [depois](evidencias/p3/depois/voce-light-moto-retrato-f100.png) |
| voce-dark-moto-retrato-f100 | [antes](evidencias/p3/antes/voce-dark-moto-retrato-f100.png) | [depois](evidencias/p3/depois/voce-dark-moto-retrato-f100.png) |
| voce-oled-tab-paisagem-f200 | [antes](evidencias/p3/antes/voce-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/depois/voce-oled-tab-paisagem-f200.png) |

### Player

HUD/faixas/ajustes/qualidade usam os widgets reais e um player falso de teste,
com as mesmas faixas JA/PT/ASS do teste de HUD preexistente. Não comprovam
frame nativo; a correção dessa prova está em
[DIAGNOSTICO_P_IMAGEM_2026-10-27.md](DIAGNOSTICO_P_IMAGEM_2026-10-27.md).

| Cena/caso | Antes | Depois |
|---|---|---|
| hud-oled-moto-retrato-f100 | [antes](evidencias/p3/player-antes/hud-oled-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/hud-oled-moto-retrato-f100.png) |
| hud-light-moto-retrato-f100 | [antes](evidencias/p3/player-antes/hud-light-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/hud-light-moto-retrato-f100.png) |
| hud-dark-moto-retrato-f100 | [antes](evidencias/p3/player-antes/hud-dark-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/hud-dark-moto-retrato-f100.png) |
| hud-oled-tab-paisagem-f200 | [antes](evidencias/p3/player-antes/hud-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/player-depois/hud-oled-tab-paisagem-f200.png) |
| faixas-oled-moto-retrato-f100 | [antes](evidencias/p3/player-antes/faixas-oled-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/faixas-oled-moto-retrato-f100.png) |
| faixas-light-moto-retrato-f100 | [antes](evidencias/p3/player-antes/faixas-light-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/faixas-light-moto-retrato-f100.png) |
| faixas-dark-moto-retrato-f100 | [antes](evidencias/p3/player-antes/faixas-dark-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/faixas-dark-moto-retrato-f100.png) |
| faixas-oled-tab-paisagem-f200 | [antes](evidencias/p3/player-antes/faixas-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/player-depois/faixas-oled-tab-paisagem-f200.png) |
| ajustes-oled-moto-retrato-f100 | [antes](evidencias/p3/player-antes/ajustes-oled-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/ajustes-oled-moto-retrato-f100.png) |
| ajustes-light-moto-retrato-f100 | [antes](evidencias/p3/player-antes/ajustes-light-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/ajustes-light-moto-retrato-f100.png) |
| ajustes-dark-moto-retrato-f100 | [antes](evidencias/p3/player-antes/ajustes-dark-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/ajustes-dark-moto-retrato-f100.png) |
| ajustes-oled-tab-paisagem-f200 | [antes](evidencias/p3/player-antes/ajustes-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/player-depois/ajustes-oled-tab-paisagem-f200.png) |
| qualidade-oled-moto-retrato-f100 | [antes](evidencias/p3/player-antes/qualidade-oled-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/qualidade-oled-moto-retrato-f100.png) |
| qualidade-light-moto-retrato-f100 | [antes](evidencias/p3/player-antes/qualidade-light-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/qualidade-light-moto-retrato-f100.png) |
| qualidade-dark-moto-retrato-f100 | [antes](evidencias/p3/player-antes/qualidade-dark-moto-retrato-f100.png) | [depois](evidencias/p3/player-depois/qualidade-dark-moto-retrato-f100.png) |
| qualidade-oled-tab-paisagem-f200 | [antes](evidencias/p3/player-antes/qualidade-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/player-depois/qualidade-oled-tab-paisagem-f200.png) |

## P3 — avisos, diálogos e estados (segunda coleta)

Acrescentadas 360 combinações aos widgets reais: 72 de sono/episódios/próximo,
120 de diálogos compartilhados e 168 de estados Início/Biblioteca. Mantém-se
3 modos, 2 tamanhos, 2 orientações e fonte 100/200%. Cada combinação tem PNG e
JSON. Não comprova aparelho nativo nem revisão independente.

Os defeitos e provas negativas estão em
[DIAGNOSTICO_P3_ESTADOS_2026-10-27.md](DIAGNOSTICO_P3_ESTADOS_2026-10-27.md).
Os avisos usam Sora/Inter e tokens, adaptam largura à fonte sem limitar escala;
o botão admite quebra de linha. Temporizadores/callbacks permanecem iguais;
os testes de sono/EOF passam junto com as 72 capturas (99 testes).
O diálogo com alternância permite rolagem sem perder as ações. Os estados
passam a distinguir falha de rede e acervo vazio, preservando cache conhecido.
O erro claro tem contraste AA e a tela indisponível pode rolar em fonte 200%.

### Comparações representativas

| Caso | Antes | Depois |
|---|---|---|
| episodios-dark-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/episodios-dark-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/episodios-dark-moto-retrato-f100.png) |
| episodios-light-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/episodios-light-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/episodios-light-moto-retrato-f100.png) |
| episodios-oled-moto-paisagem-f200 | [antes](evidencias/p3/prompts-antes/episodios-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/episodios-oled-moto-paisagem-f200.png) |
| episodios-oled-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/episodios-oled-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/episodios-oled-moto-retrato-f100.png) |
| episodios-oled-tab-paisagem-f200 | [antes](evidencias/p3/prompts-antes/episodios-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/episodios-oled-tab-paisagem-f200.png) |
| proximo-dark-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/proximo-dark-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/proximo-dark-moto-retrato-f100.png) |
| proximo-light-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/proximo-light-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/proximo-light-moto-retrato-f100.png) |
| proximo-oled-moto-paisagem-f200 | [antes](evidencias/p3/prompts-antes/proximo-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/proximo-oled-moto-paisagem-f200.png) |
| proximo-oled-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/proximo-oled-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/proximo-oled-moto-retrato-f100.png) |
| proximo-oled-tab-paisagem-f200 | [antes](evidencias/p3/prompts-antes/proximo-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/proximo-oled-tab-paisagem-f200.png) |
| sono-dark-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/sono-dark-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/sono-dark-moto-retrato-f100.png) |
| sono-light-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/sono-light-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/sono-light-moto-retrato-f100.png) |
| sono-oled-moto-paisagem-f200 | [antes](evidencias/p3/prompts-antes/sono-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/sono-oled-moto-paisagem-f200.png) |
| sono-oled-moto-retrato-f100 | [antes](evidencias/p3/prompts-antes/sono-oled-moto-retrato-f100.png) | [depois](evidencias/p3/prompts-depois/sono-oled-moto-retrato-f100.png) |
| sono-oled-tab-paisagem-f200 | [antes](evidencias/p3/prompts-antes/sono-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/prompts-depois/sono-oled-tab-paisagem-f200.png) |
| carregando-dark-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/carregando-dark-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/carregando-dark-moto-retrato-f100.png) |
| carregando-light-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/carregando-light-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/carregando-light-moto-retrato-f100.png) |
| carregando-oled-moto-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/carregando-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/carregando-oled-moto-paisagem-f200.png) |
| carregando-oled-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/carregando-oled-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/carregando-oled-moto-retrato-f100.png) |
| carregando-oled-tab-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/carregando-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/carregando-oled-tab-paisagem-f200.png) |
| confirmar-dark-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/confirmar-dark-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/confirmar-dark-moto-retrato-f100.png) |
| confirmar-light-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/confirmar-light-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/confirmar-light-moto-retrato-f100.png) |
| confirmar-oled-moto-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/confirmar-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/confirmar-oled-moto-paisagem-f200.png) |
| confirmar-oled-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/confirmar-oled-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/confirmar-oled-moto-retrato-f100.png) |
| confirmar-oled-tab-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/confirmar-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/confirmar-oled-tab-paisagem-f200.png) |
| erro-dark-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/erro-dark-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/erro-dark-moto-retrato-f100.png) |
| erro-light-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/erro-light-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/erro-light-moto-retrato-f100.png) |
| erro-oled-moto-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/erro-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/erro-oled-moto-paisagem-f200.png) |
| erro-oled-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/erro-oled-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/erro-oled-moto-retrato-f100.png) |
| erro-oled-tab-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/erro-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/erro-oled-tab-paisagem-f200.png) |
| nome-dark-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/nome-dark-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/nome-dark-moto-retrato-f100.png) |
| nome-light-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/nome-light-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/nome-light-moto-retrato-f100.png) |
| nome-oled-moto-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/nome-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/nome-oled-moto-paisagem-f200.png) |
| nome-oled-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/nome-oled-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/nome-oled-moto-retrato-f100.png) |
| nome-oled-tab-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/nome-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/nome-oled-tab-paisagem-f200.png) |
| opcao-dark-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/opcao-dark-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/opcao-dark-moto-retrato-f100.png) |
| opcao-light-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/opcao-light-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/opcao-light-moto-retrato-f100.png) |
| opcao-oled-moto-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/opcao-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/opcao-oled-moto-paisagem-f200.png) |
| opcao-oled-moto-retrato-f100 | [antes](evidencias/p3/dialogos-antes/opcao-oled-moto-retrato-f100.png) | [depois](evidencias/p3/dialogos-depois/opcao-oled-moto-retrato-f100.png) |
| opcao-oled-tab-paisagem-f200 | [antes](evidencias/p3/dialogos-antes/opcao-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/dialogos-depois/opcao-oled-tab-paisagem-f200.png) |
| biblioteca-carregando-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-carregando-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-carregando-dark-moto-retrato-f100.png) |
| biblioteca-carregando-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-carregando-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-carregando-light-moto-retrato-f100.png) |
| biblioteca-carregando-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-carregando-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-carregando-oled-moto-paisagem-f200.png) |
| biblioteca-carregando-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-carregando-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-carregando-oled-moto-retrato-f100.png) |
| biblioteca-carregando-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-carregando-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-carregando-oled-tab-paisagem-f200.png) |
| biblioteca-erro-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-erro-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-erro-dark-moto-retrato-f100.png) |
| biblioteca-erro-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-erro-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-erro-light-moto-retrato-f100.png) |
| biblioteca-erro-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-erro-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-erro-oled-moto-paisagem-f200.png) |
| biblioteca-erro-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-erro-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-erro-oled-moto-retrato-f100.png) |
| biblioteca-erro-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-erro-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-erro-oled-tab-paisagem-f200.png) |
| biblioteca-vazio-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-vazio-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-vazio-dark-moto-retrato-f100.png) |
| biblioteca-vazio-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-vazio-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-vazio-light-moto-retrato-f100.png) |
| biblioteca-vazio-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-vazio-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-vazio-oled-moto-paisagem-f200.png) |
| biblioteca-vazio-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/biblioteca-vazio-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/biblioteca-vazio-oled-moto-retrato-f100.png) |
| biblioteca-vazio-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/biblioteca-vazio-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/biblioteca-vazio-oled-tab-paisagem-f200.png) |
| inicio-carregando-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-carregando-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-carregando-dark-moto-retrato-f100.png) |
| inicio-carregando-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-carregando-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-carregando-light-moto-retrato-f100.png) |
| inicio-carregando-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-carregando-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-carregando-oled-moto-paisagem-f200.png) |
| inicio-carregando-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-carregando-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-carregando-oled-moto-retrato-f100.png) |
| inicio-carregando-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-carregando-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-carregando-oled-tab-paisagem-f200.png) |
| inicio-erro-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-erro-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-erro-dark-moto-retrato-f100.png) |
| inicio-erro-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-erro-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-erro-light-moto-retrato-f100.png) |
| inicio-erro-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-erro-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-erro-oled-moto-paisagem-f200.png) |
| inicio-erro-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-erro-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-erro-oled-moto-retrato-f100.png) |
| inicio-erro-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-erro-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-erro-oled-tab-paisagem-f200.png) |
| inicio-offline-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-offline-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-offline-dark-moto-retrato-f100.png) |
| inicio-offline-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-offline-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-offline-light-moto-retrato-f100.png) |
| inicio-offline-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-offline-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-offline-oled-moto-paisagem-f200.png) |
| inicio-offline-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-offline-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-offline-oled-moto-retrato-f100.png) |
| inicio-offline-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-offline-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-offline-oled-tab-paisagem-f200.png) |
| inicio-vazio-dark-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-vazio-dark-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-vazio-dark-moto-retrato-f100.png) |
| inicio-vazio-light-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-vazio-light-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-vazio-light-moto-retrato-f100.png) |
| inicio-vazio-oled-moto-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-vazio-oled-moto-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-vazio-oled-moto-paisagem-f200.png) |
| inicio-vazio-oled-moto-retrato-f100 | [antes](evidencias/p3/estados-antes/inicio-vazio-oled-moto-retrato-f100.png) | [depois](evidencias/p3/estados-depois/inicio-vazio-oled-moto-retrato-f100.png) |
| inicio-vazio-oled-tab-paisagem-f200 | [antes](evidencias/p3/estados-antes/inicio-vazio-oled-tab-paisagem-f200.png) | [depois](evidencias/p3/estados-depois/inicio-vazio-oled-tab-paisagem-f200.png) |

A composição aprovada da Início com dados foi preservada; consulta de hero
filtrada não autoriza afirmar que todo o acervo está vazio. A origem das faixas
gravadas no arquivo continua sem prova de mídia original. Não houve alteração
de zoom/proporção para esconder barras. P4–P7 e revisão física/independente
continuam pendentes.
