# P1 — imagem nativa e limite exato da ATENÇÃO

P em andamento, não é entrega final nem release candidate aprovado.
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
