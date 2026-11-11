# Heisuca V2 — correção da sessão de mídia — 11/11/2026

Ramo `codex/heisuca-v2-sessao`. Rebase autorizado sobre
`4f3ab38ae8e4661d796675e17cfc530b1ba734b4`, sem conflitos. A correção dos tokens `1dc43485`
entra pela base, sem edição desta frente em design/, test/design/ ou docs/marca_2026-11-09/.
Versão, applicationIds, assinatura e motores preservados. **não testado em aparelho**.

## Diagnóstico antes de alterar o app

Três testes novos escritos antes da correção da mensagem: estado diferente, posição zero e bits ausentes.
A mensagem agora informa estado lido/esperado, posição, ações/obrigatórias/faltantes em hexadecimal e nomes dos bits.
Negativo `/tmp/ultron-v2-correcao-diagnostico-red.log`; depois **17 testes Python passaram**, incluindo fixture literal da run.
Nenhuma condição de aprovação nem o prazo de oito segundos mudou.

Artefato `13796583682` da run [42886090476](https://github.com/CaioGuerras/heisuca/actions/runs/42886090476)
baixado. Os dumps `mpv-sessao-tocando-media-session*.txt` foram lidos e preservados privadamente.
Trecho literal de `mpv-sessao-tocando-media-session.txt`:

```text
state=PlaybackState {state=PLAYING(3), position=2462, buffered position=2462, speed=1.0, updated=345440, actions=4452347, custom actions=[], active item id=1, error=null}
metadata: size=5, description=Vídeo de amostra, null, null
```

Reprodução com a mensagem nova:

```text
estado lido=3 esperado=3; posição=2462 ms (esperado > 0); ações=0x43effb obrigatórias=0x126 faltantes=0x4 (tocar=0x4).
```

Condição que falhou: **ação Tocar (4) ausente**. Estado e posição estão corretos; Pausar (2), Buscar (256) e Próximo
(32) estão presentes. As27amostras mostram estado3, posições2462/5265/8227 e a mesma máscara.
Não é problema de parse do Android15: o parser já leu corretamente PLAYING(3). Não há evidência de atraso do motor.

## Causa encontrada na Media3

A porta já declara `Player.COMMAND_PLAY_PAUSE`. Na fonte da versão efetivamente embarcada, Media3 **1.11.0**,
`MediaSessionLegacyStub.convertCommandToPlaybackStateActions` publica Tocar+Alternar quando deve mostrar Tocar,
e Pausar+Alternar no outro estado. O comando público da porta não possui flags independentes Play/Pause.
Assim, a prova anterior exige dois bits simultâneos que a conversão padrão da Media3 alterna por estado.
[Arquivo oficial da versão1.11.0](https://github.com/androidx/media/blob/1.11.0/libraries/session/src/main/java/androidx/media3/session/MediaSessionLegacyStub.java).

Não substituí a sessão, não falsifiquei estado, não fiz reflexão/patch privado da biblioteca e não retirei o bit
obrigatório da prova. Como a ordem exige conservar a checagem, foi pedida decisão ao dono: autorizar prova por estado
com Pausar→Tocar reais, ou discutir mudança na Media3 para expor ambos os bits simultâneos. **Decisão pendente**.
A validação do Android Build após o rebase é independente dessa decisão e continua.

## Validação e entrega

Portão local verde:198Python na execução inicial,2386Flutter/3pulados,8Impeller e15Kotlin/0falhas.
A fixture real foi acrescentada após a etapa Python; suíte Python final separada:199passaram.
Novo teste Kotlin confirma COMMAND_PLAY_PAUSE e encaminhamento de pause/play nos dois estados, sem alterar o app.
Android Build/segurança após rebase: aguardando runs.
Bancada verde após diagnóstico: pendente da decisão/correção de contrato acima, sem aprovação afirmada.
Uma sessão somente; nenhum plugin legado restaurado; nenhum segredo/telemetria adicionado.
Não testados Bluetooth, fone físico, carro e aparelho real. Retomada com transporte Dart encerrado permanece
limitada como na entrega de10/11; nenhum motor headless foi criado.
Provas completas: `~/cgflix/handoffs/PROVAS_ULTRON_V2_SESSAO_CORRECAO_2026-11-11/`.

Desfazer o rebase publicado exige coordenar com quem integrou o ramo. A cabeça anterior era
`6003c4a682c1aa9a22a722549d154654dd6db139`; não mover outros ramos nem publicar APK de produção.
