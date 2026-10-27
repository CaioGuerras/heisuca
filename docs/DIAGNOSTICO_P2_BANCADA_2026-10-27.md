# P2 — captura preta no segundo retorno do player

Candidato `88c6810`, versão 2.0.34+36:

- APK [40478590176](https://github.com/CaioGuerras/heisuca/actions/runs/40478590176)
  verde, pacote `app.heisuca.player.teste.home`, 97.138.729 bytes, certificado
  `19160423a510868e98375fa1b85f9ee4da9fb8b9ad7a13208db07bcac026f95c`.
  SHA-256 APK no job: `7ee4ac856a3cab029ab812675142af0b45e1e5a997a65c2b16380a4a103cc878`.
  Artifact `12723326118`, ZIP `e26fc213a3ea634b2b0f24e37f2306f6117402e08f224c8a5a1059de02293ea7`.
- Bancada [40478590180](https://github.com/CaioGuerras/heisuca/actions/runs/40478590180)
  **vermelha**, artifact `12722372783`, ZIP baixado/conferido:
  `393fbcac912da032b0250c48b712e67c30cb9b55156baa4ea65a63a035968753`.
  Erro: `RuntimeError: Imagem nativa preta: 06-player`. RGB máximo 0, PNG
  original inspecionado. Sem ANR (`anrDoApp: false`); restauração confirmada.
- Marco 21, após o primeiro retorno do áudio: imagem real presente (entrevista),
  RGB máximo 237. O preto ocorreu depois do fechamento manual do PiP com áudio
  e da segunda reabertura (marco 20 → 06). Não é caso de ATENÇÃO.

## Contrato da prova que precisa ser corrigido/verificado

O roteiro chama o comando de reabertura e espera apenas `resumed`,
`debugBackgroundAudioActive == false` e janela expandida. Esses sinais confirmam
ciclo de vida/comando, mas não exigem um novo quadro. `hasRenderedFrame` também
é histórico do arquivo; permanece verdadeiro desde um `playback-restart` anterior.
O player já expõe o stream nativo `playbackRestart`.

O log mostra restauração `vid=1`, seek exato de ressincronização e inicialização
da cadeia de vídeo. Há `first video frame after restart shown` no fim do log,
mas o log coletado/bufferizado sozinho não prova o instante relativo ao PNG.
Ainda não se pode concluir defeito permanente do app, regressão causada pela
paleta ou falha de infraestrutura. A única afirmação comprovada é que a captura
06 estava preta e o critério de prontidão do roteiro não exige um quadro novo.

Próximo ajuste de prova: assinar o stream existente ANTES da ação de retorno e
exigir o evento novo de playback-restart, com prazo que falha (sem pausa fixa).
Manter a leitura nativa dos pixels obrigatória e o vermelho para preto/ANR/crash.
Teste local deve provar que o retorno do comando sozinho não libera a captura,
que evento síncrono durante a ação não se perde e que erro cancela a assinatura.
Isso não autoriza alterar a M, AAR, codec ou declarar imagem restaurada sem PNG.
Os runs de `9113a40` já haviam sido disparados pelo ajuste de contraste; não são
reruns manuais para investigar M. Aguardar/registrar suas conclusões.


## Prova local e ajuste do roteiro

Extraído o limite da segunda reabertura para `support/video_restore.dart`,
primeiro preservando a semântica anterior (aguardar apenas a ação). Testes
escritos antes de corrigir esse limite: **1 passou / 4 falharam**. A captura era
liberada antes do evento; a ação não tinha assinante; ausência de evento e fim
do stream eram aceitos. Log `evidencias/p2_prontidao_antes_2026-10-27.txt`.
O run vermelho/PNG preto acima é a prova negativa original no percurso real.

Depois: assinatura antes da ação, exigência de novo playback-restart e conclusão
da ação; erro/prazo sem evento encerram em falha e cancelam assinatura/prazo.
Cinco testes locais passaram, incluindo evento síncrono durante a ação. Mesmo
limite aplicado às duas reaberturas (18 e 20), com confirmação no resultado do
driver/relatório. Sem pausa fixa, nova tentativa de captura ou mudança no app.
Um evento sozinho não comprova imagem: o PNG nativo continua obrigatório;
qualquer preto continua vermelho. A próxima execução precisa provar os pixels.
Não foi alegada correção física da M ou de um defeito permanente do player.


No marco 06, a checagem dos pixels precede o `keyevent 4` em `capturas.py`.
Como houve preto, o Voltar ainda não foi enviado nesta execução. Não atribuir
a falha ao retorno K aprovado ou ao tratamento do Back.
