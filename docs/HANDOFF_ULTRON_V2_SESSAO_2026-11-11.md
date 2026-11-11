# Heisuca V2 — correção da sessão de mídia — 11/11/2026

Ramo `codex/heisuca-v2-sessao`. Rebase autorizado sobre
`4f3ab38ae8e4661d796675e17cfc530b1ba734b4`, sem conflitos. A correção dos tokens `1dc43485`
entra pela base, sem edição desta frente em design/, test/design/ ou docs/marca_2026-11-09/.
Versão, applicationIds, assinatura e motores preservados. **não testado em aparelho**.

## Diagnóstico antes de alterar o app

Três testes novos escritos antes da correção da mensagem: estado diferente, posição zero e bits ausentes.
A mensagem agora informa estado lido/esperado, posição, ações/obrigatórias/faltantes em hexadecimal e nomes dos bits.
Negativo `/tmp/ultron-v2-correcao-diagnostico-red.log`; depois **17 testes Python passaram**, incluindo fixture literal da run.
Na etapa de diagnóstico, nenhuma condição de aprovação nem o prazo de oito segundos mudou.

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
(32) estão presentes. As 27 amostras mostram estado 3, posições 2462/5265/8227 e a mesma máscara.
Não é problema de parse do Android 15: o parser já leu corretamente PLAYING(3). Não há evidência de atraso do motor.

## Causa encontrada na Media3

A porta já declara `Player.COMMAND_PLAY_PAUSE`. Na fonte da versão efetivamente embarcada, Media3 **1.11.0**,
`MediaSessionLegacyStub.convertCommandToPlaybackStateActions` publica Tocar+Alternar quando deve mostrar Tocar,
e Pausar+Alternar no outro estado. O comando público da porta não possui flags independentes Play/Pause.
Assim, a prova anterior exige dois bits simultâneos que a conversão padrão da Media3 alterna por estado.
[Arquivo oficial da versão 1.11.0](https://github.com/androidx/media/blob/1.11.0/libraries/session/src/main/java/androidx/media3/session/MediaSessionLegacyStub.java).

## Decisão do revisor — contrato por estado

Em 11/11, o revisor confirmou o diagnóstico e retirou a premissa de defeito do app: a alternância dos bits é normal
na Media3. O erro estava no contrato da prova. Foi autorizado exigir os comandos por estado esperado:

| Estado | Ações obrigatórias, além de Próximo (32) quando existe |
| --- | --- |
| 3, tocando | Pausar (2) + Tocar/Pausar (512) + Buscar (256) |
| 2, pausado | Tocar (4) + Tocar/Pausar (512) + Buscar (256) |

Com Próximo, máscaras 0x322/0x324; sem Próximo, 0x302/0x304. Estados fora de 2/3 continuam reprovados.
A mensagem preserva estado lido/esperado, posição e bits ausentes em hexadecimal e por nome.
O dump real acima agora é aprovado. Cada bit obrigatório tem prova negativa; Tocar ausente ao tocar e Pausar
ausente ao pausar são aceitos. O dump sintético segue o mesmo contrato, sem apagar os testes existentes.

Não houve mudança na Media3, no serviço, no app, no percurso de integração nem em PortaSessaoPlayerTest.kt.
Permanecem oito segundos, mesma frequência e mesmo número de tentativas; não há novo skip ou tolerância de erro.
O percurso existente comprova tocar→pausa real pelo sistema→estado 2→tocar real pelo sistema nos dois motores.
Testes escritos antes da mudança da máscara falharam; depois, 25 testes Python da prova passaram.
Logs privados: ultron-v2-contrato-red.log e ultron-v2-contrato-green.log.

## Validação anterior ao contrato autorizado

Portão local verde:198 Python na execução inicial,2.386 Flutter / 3 pulados,8 Impeller e 15 Kotlin / 0 falhas.
A fixture real foi acrescentada após a etapa Python; suíte Python final separada:199 passaram.
Novo teste Kotlin confirma COMMAND_PLAY_PAUSE e encaminhamento de pause/play nos dois estados, sem alterar o app.
Código publicado `deff9130727273baf58748067418af5922b8509e`, usando force-with-lease com cabeça esperada 6003c4a6.
- [Android Build 42987214757](https://github.com/CaioGuerras/heisuca/actions/runs/42987214757): **verde**, APKs ARM64/universal e MobSF; AAB pulado.
- [Segurança 42987214595](https://github.com/CaioGuerras/heisuca/actions/runs/42987214595): verde, segredos e dependências.
- Bancada 42886090476: vermelho anterior diagnosticado acima; a decisão do revisor autoriza o contrato corrigido.
APKs de teste ARM64/universal gerados e retidos, sem distribuição. ARM64 efetivo conferido:versionCode 2047,
pacote app.heisuca.player.teste.home, certificado SHA-256 d415544dae728cd8d402827f1bf17b6af00b2443295b3bad8b463d65d3acd4c1, igual à base.
A validação do contrato autorizado está registrada a seguir.
Uma sessão somente; nenhum plugin legado restaurado; nenhum segredo/telemetria adicionado.
Não testados Bluetooth, fone físico, carro e aparelho real. Retomada com transporte Dart encerrado permanece
limitada como na entrega de 10/11; nenhum motor headless foi criado.
Provas completas: `~/cgflix/handoffs/PROVAS_ULTRON_V2_SESSAO_CORRECAO_2026-11-11/`.

Desfazer o rebase publicado exige coordenar com quem integrou o ramo. A cabeça anterior era
`6003c4a682c1aa9a22a722549d154654dd6db139`; não mover outros ramos nem publicar APK de produção.

## Execução do contrato autorizado

Portão local concluído com saída `APROVADO: análise e testes concluídos.` e código de saída 0.
207 testes Python, 2.386 Flutter (3 pulos preexistentes), 8 Impeller e 15 Kotlin: nenhuma falha.
A análise mantém 40 avisos/informações herdados, com as opções existentes do portão, sem novos erros.
Código: commit que introduz esta seção. Bancada: aguardando publicação e execução; ainda sem aprovação.
Desfazer somente este ajuste: `git revert <commit do contrato por estado>`.

Primeira run do contrato, [43010848612](https://github.com/CaioGuerras/heisuca/actions/runs/43010848612):
reprovada depois de aprovar mpv tocando (3, posição 2086, ações 4452347), pausa do sistema,
mpv pausado (2, posição 3086, ações 4452349), retomada e capturas do HUD.
Falha nova: `Botão PiP não apareceu em 8 segundos: Pausar`; sem ANR. Não classificada como infraestrutura.
A prova agora preserva captura, XML, atividades e sessão também nessa falha, sem tocar, repetir a ação,
reconhecer sucesso ou ampliar o prazo. Teste novo falhou antes e passou depois; 208 testes Python aprovados.
Nova execução para diagnóstico e conclusão; esta run vermelha não é aprovação.

Segunda run [43012943290](https://github.com/CaioGuerras/heisuca/actions/runs/43012943290):
mesma reprovação PiP, sem ANR. Captura mostra vídeo em janela fixada, sessão PLAYING(3), posição 44637,
ações 4452347; XML do uiautomator contém apenas o launcher. O menu não permaneceu visível na coleta.
A leitura da prova passou ao helper UiAutomation já compilado pelo workflow: consulta todas as janelas
sem esperar idle, encontra somente botão visível/habilitado pelo rótulo e continua tocando no retângulo real.
Não há botão inventado, nova tentativa, alteração no app ou relaxamento de prazo/asserção.
Teste escrito antes do ajuste comprova envio único do helper e leitura instantânea, sem uiautomator;
209 testes Python passaram. Helper compilado localmente. Nova execução obrigatória, sem aprovação antecipada.
