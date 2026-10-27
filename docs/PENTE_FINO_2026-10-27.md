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
