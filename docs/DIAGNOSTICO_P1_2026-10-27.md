# P1 — imagem nativa e limite exato da ATENÇÃO

**P1 concluída em 105a697; P2–P7 ainda em andamento. Não é entrega final nem RC aprovado.**

APK [40446725726](https://github.com/CaioGuerras/heisuca/actions/runs/40446725726) verde.
Bancada [40446725637](https://github.com/CaioGuerras/heisuca/actions/runs/40446725637)
concluída com **ATENÇÃO**, exclusivamente pelos três widgets do HUD em PiP
ativo, 227,8 × 128 dp. `testeEncerrado: true`, percurso até `11-voce`, sem ANR
do app e restauração confirmada. PNGs originais 21/06 inspecionados: ambos mostram
a obra (entrevista e bola), além da prova RGB associada a cada ACK.
A regra é a decisão posterior do Caio: widgets permitidos + fase PiP + largura
até 320 dp; os demais casos continuam vermelhos. O mesmo erro fora do PiP ou
em janela cheia é rejeitado por teste. A cronologia abaixo conserva as falhas,
hipóteses e limites anteriores; não representa o estado final desta P1.

Artifacts, assinatura e hashes no fechamento P1 do HANDOFF de entrega.
Não testado em aparelho nesta versão. Tab A9/Moto G77 e revisão do Visão pendentes.
Base 802ffbd. Leitura do artifact original:
https://github.com/CaioGuerras/heisuca/actions/runs/40439214269
Bancada base: https://github.com/CaioGuerras/heisuca/actions/runs/40433379764

## Achados reais

- `testeEncerrado: true`, 20 marcos até `11-voce`. A regressão de Novidades
  não impediu este percurso. `quadroNativo: true`, avanço de 3,837 s.
- As miniaturas de `06-player.png` e `21-imagem-apos-audio.png`, produzidas
  pelo leitor a partir dos PNGs do artifact, estão pretas. A captura original
  já usa **adb exec-out screencap -p** (`scripts/bancada/capturas.py`). Não é
  justificado trocar a captura Flutter ou afirmar problema de imagem apenas
  por uma flag do mpv. A origem da perda da imagem ainda não foi demonstrada.
- Download direto dos PNGs permanece bloqueado com HTTP 403 neste executor.
  O workflow leitor consegue acessar o artifact dentro do Actions. Acrescentada
  leitura dos extremos RGB do PNG ORIGINAL ao leitor, antes de qualquer JPEG.
  Isso permitirá registrar dimensão e imagem sim/não sem depender da miniatura.
- O log real contém **dois** conjuntos de geometria: 240,8 × 108,2 dp e
  227,8 × 128,0 dp. O segundo traz coluna de **192 px**, além de cabeçalho
  161 px e transporte 20 px. O pedido lista 212 px e aproximadamente 240,8 ×
  108,2 dp, exigindo lista exata por widget/fase/tamanho. Pergunta enviada ao
  Caio sobre incluir o segundo conjunto. Até a resposta não ampliar a exceção.
  Nenhuma exceção/ANR/crash/imagem preta pode virar ATENÇÃO por essa lista.

## Prova negativa e correção da coleta (não do player)

Novo `scripts/bancada/test_imagem.py`, antes do patch: PNG nativo válido de
64 × 36, inteiramente preto, era aceito e recebia ACK no marco de restauração.
Teste falhou: **RuntimeError not raised**. Log preservado em
`evidencias/p1_imagem_antes_2026-10-27.txt`.

Após a correção, os marcos 06 e 21 leem os pixels do PNG nativo por ffmpeg,
gravando `<marco>-imagem.json` com método, maior canal RGB e imagem sim/não.
Preto total lança erro **antes do ACK**, não avança o marco e mantém a bancada
vermelha. PNG não decodificável também falha. Pixels não pretos podem ser UI:
este limite fica explícito, não equivale a provar sozinho a obra na Surface.
39 testes Python passaram. O player não foi alterado por hipótese.

## Ainda necessário para fechar P1

1. Conferir os pixels originais e reproduzir no run novo; se preta, identificar
   e corrigir a causa do restauro da imagem com teste antes/depois. Não culpar
   o emulador, desativar shaders, adicionar retries ou ignorar a imagem sem prova.
2. Decisão da lista exata de ATENÇÃO e registrar fase/viewport junto do erro.
3. Executar percurso completo e conferir relatório, restauração e ANR.

P2–P7 ainda não entregues; não publicar changelog prometendo paleta/segurança
que não foram implementadas nem medidas. Não emitir commit ENTREGA-FINAL.

### Contraste antes/depois no mpv desta execução

No mesmo log de 40433379764:

- Inicial: `vid=1`, `pause=no`, `vo-configured=yes`, `current-vo=gpu`,
  `video-out-params/w=1920`, `video-out-params/h=1080`.
- Após áudio: `vid=1`, `pause=no`, `vo-configured=no`, `current-vo=gpu`,
  saída sem largura/altura, screenshot do mpv indisponível (PlatformException).
- O bridge escreve “Video output ready” depois de anexar Surface, mas isso
  não coincide com VO configurado nem com pixels visíveis. É necessário provar
  a configuração/primeiro quadro da saída real, não confundir anexar Surface
  com restaurar a imagem. Contexto GLES e decoder são recriados no retorno;
  o log não estabelece qual operação deixa de produzir o primeiro quadro.

Não houve patch especulativo no player/Surface/codec ou mudança do AAR proibido.

### Decisão de Caio recebida e implementação da regra

Autorizada janela variável até **320 dp de largura**, incluindo 227,8×128,0
com coluna 192 px. Regra usa simultaneamente: erro RenderFlex da biblioteca
rendering, origem nos três pontos do HUD, fase entrada/ativo/saída PiP,
janela válida com largura <=320 dp. Fonte/contexto errado, outra exceção ou
janela cheia seguem o tratador original e ficam vermelhos. Não altera handlers
no APK de uso: somente no teste de integração. A saída espera janela expandida
antes de sair da fase PiP; não presume que o callback nativo já expandiu a janela.

Teste de política: baseline recusava os 3 casos conhecidos (3 falhas); depois
aceita os casos PiP e rejeita a mesma exceção em janela cheia, fora da fase,
com outra origem, outra exceção, largura inválida ou >320. Driver conserva os
avisos no resultado; relatório e resumo exibem verde/ATENÇÃO/vermelho. Qualquer
falha de passo/diagnóstico nativo continua vermelha; preto total continua fatal.

### Pixels originais conferidos

Run leitor **40440212912**, conclusão success, prova dos arquivos originais de
40433379764: `21-imagem-apos-audio.png` e `06-player.png`, ambos **1200×540**,
**imagem: não**, extremos RGB **[[0,0],[0,0],[0,0]]**. Método: PNG original de
adb screencap, leitura RGB por Pillow antes da miniatura JPEG. Preto total real.

### Hipótese de sincronização ainda em teste

O código desativa `vid` para ouvir fora do app e restaura a faixa no retorno,
mas não pede ressincronização da cadeia de vídeo ao ponto atual do áudio.
O próprio `rebuildVideoOutput` documenta que desativar a faixa durante rebuild
pula a ressincronização que o mpv faz com vídeo ativo, usando seek relativo zero
exato após reativar para sincronizar áudio/vídeo. Isso é uma hipótese aplicável
ao retorno do áudio, ainda NÃO provada como causa desta falha.

Acrescentado teste nativo `reativarVideoRessincronizaNoPontoAtualSemTrocarFaixa`
para executar no Actions antes de qualquer patch dessa hipótese. O executor local
não tem Android SDK/Gradle cache; portão Flutter/Python não prova esse teste nativo.
Ainda não há patch no player. Só aceitar a hipótese com prova de falha anterior,
correção e pixels reais restaurados no emulador; não aceitar somente o mock.

### Reprodução nova sem patch de player

Bancada **40440203813**, commit `58d5f09`, vermelha no marco 21:
`BANCADA_IMAGEM: imagem=não, maiorCanalRGB=0`, método PNG de adb screencap
lido por ffmpeg. Diagnóstico Android disponível, **anrDoApp=false**;
restauração confirmada. Artifact **12706228905**, ZIP SHA-256
`4f56d74be7a264dc72d3b8dc77f974cedcc581e4ec2713ae51c9a1971bff1acb`.
Agora a prova de imagem impede a aprovação indevida, sem mudar o app.

### Prova nativa anterior e patch candidato

Run **40441219054**, job **121981762142**, código `b0399d0`: portão local do
runner passou e teste nativo `reativarVideoRessincronizaNoPontoAtualSemTrocarFaixa`
falhou na asserção da ordem `vid=no → vid=7 → seek 0 relative exact` (linha 25).
**12 testes, 1 falha**. Log em `evidencias/p1_ressincronizacao_antes_2026-10-27.txt`.
Só após ler esse resultado foi escrito o patch candidato em `setBackgroundAudio`:
restaura a faixa e ressincroniza o vídeo ao ponto atual do áudio, na mesma fila
ordenada, sem alterar pause/posição deliberada/faixa e sem repetir no segundo
restore. Se o vídeo já estava desligado, não busca. Falha do seek não confirma
restauro e conserva a intenção anterior. Testes nativos cobrem esses limites.

Um teste de widget adicional usa os erros produzidos PELO HUD REAL ao encolher
a janela antes do callback de PiP, e verifica a regra com o diagnóstico do
Flutter: aceita no PiP e rejeita o mesmo erro em janela cheia. Passou localmente.
Isso valida a extração da origem; não é só comparação com uma string fabricada.

A integração agora também exige `vo-configured=yes` nas capturas 21 e 06, além
dos pixels não pretos, avanço e quadro nativo. Snapshot do estado fica no resultado
do driver. Pixels da interface, sozinhos, não podem encobrir uma saída não configurada.
**Patch candidato ainda sem prova de correção no emulador; P1 segue aberta.**

O conector GitHub `download_workflow_artifact` conseguiu baixar o ZIP original
12706228905, embora o CLI falhe. Não pedir mais imagens ao usuário por esse 403.
Originais preservados: `evidencias/p1_05_antes_2026-10-27.png` (vídeo colorido,
RGB máximo 174/247/207) e `evidencias/p1_21_antes_2026-10-27.png` (0/0/0).
Mesmo percurso, mesmo capturador adb e mesma dimensão 1200×540. A captura inicial
inspecionada mostra a abertura da obra; após áudio, preto absoluto. Não é prova
baseada apenas no estado interno do player ou na miniatura JPEG.

### Resultado do candidato 2f526a1 — sem aceite da P1

- APK **40442922526 verde**, testes nativos passaram, pacote
  `app.heisuca.player.teste.home`, 97.138.589 bytes. Certificado SHA-256
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`. APK SHA-256
  `15b04eb59ac78664347aa46e4bb1166b693189b2d8bcb2a511f506075b46c1a5`.
- Bancada **40442922427 vermelha**, artifact **12707875657**, ZIP SHA-256
  `e655cab96a3532ad385ca2a5a4e2dfa4d98fb7593f8cb1c3a6528c170b6f6d26`.
- Originais inspecionados: `p1_21_apos_sync_2026-10-27.png` mostra bola/criança;
  `p1_06_apos_sync_2026-10-27.png` mostra a entrevista. Ambos têm vídeo real,
  não só UI ou spinner. No marco 21, VO GPU configurado e dimensões 1920×1080.
- O marco 06 falhou em uma asserção NOVA da bancada: uma amostra de
  `vo-configured=no` lida antes do PNG. O PNG, capturado segundos depois, já
  tinha vídeo visível. Não é correto usar o probe antigo como veto aos pixels.
- Houve também **ANR real do app**, não do launcher: `Input dispatching timed
  out`, 5002 ms em `FocusEvent(hasFocus=false)`. Diagnóstico disponível, dados
  restaurados. Não converter isso em ATENÇÃO nem declarar infraestrutura.

### Correção da prova da captura

O ACK antigo só continha seq/ok; o teste negativo exigindo os pixels daquela
captura falhou: `imagem not found`. A coleta agora anexa seu resultado de pixels
no ACK; integração e driver conservam `capturasNativas` e exigem imagem sim em
06/21. Probes de propriedades continuam como diagnóstico, não se passam por
medição sincronizada com o PNG. Preto total permanece sem ACK e vermelho.
Prova em `evidencias/p1_ack_antes_2026-10-27.txt`.

### Tratador de diagnóstico e ANR: fatos separados de hipótese

O trace main está executável (state=R), em memcpy, com 97 s acumulados esperando
CPU. Android registrou pressão de CPU avg10=73,67%, total 90%, load 21,66. São
sinais de carga, não demonstração suficiente para dispensar o ANR.

Com símbolos oficiais do engine Flutter 3.47.1, revisão
`5d531788691ec3404cac0cee66ead4007b177363`, addr2line dos PCs anotados:
`0x0229046d` = `dart::TwoByteString::ConcatAll` (object.cc:25275);
`0x0223fcbd` = `dart::NativeEntry::BootstrapNativeCallWrapper`;
`0x01c245df` = `fml::MessageLoopAndroid::Run`. Build IDs foram redigidos pelo
coletor; a revisão dos símbolos segue o SDK fixado no workflow. Isso localiza
concatenação de strings, não prova sozinho qual chamador gerou a carga.

Achado reproduzível no nosso tratador: expandia `toDiagnosticsNode().toStringDeep()`
ANTES de verificar tipo, biblioteca, fase ou viewport, inclusive TestFailure
fora do PiP. Teste do informationCollector: esperado 0 expansões, obtido 1.
Depois da correção, só formata candidatos de rendering em PiP pequeno; demais
exceções vão diretamente ao framework, sem suprimir sua falha. Casos com HUD
REAL continuam passando. Prova em `evidencias/p1_diagnostico_precoce_antes_2026-10-27.txt`.

Essa correção evita trabalho duplicado demonstrado; **não afirmar que curou
sozinho o ANR sem nova prova completa**. P1 segue bloqueada até percurso e
coleta nativa sem ANR. P2–P7 ainda pendentes, sem ENTREGA-FINAL/publicação.
