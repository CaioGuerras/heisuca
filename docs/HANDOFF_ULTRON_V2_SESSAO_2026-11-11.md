# Heisuca V2 — correção do leitor PiP — 11/11/2026

## Resultado: parado no item G, entrega NÃO pronta

Ramo `codex/heisuca-v2-sessao`, base desta rodada `a5d064d3`.
[Bancada 43060805478](https://github.com/CaioGuerras/heisuca/actions/runs/43060805478), código `f7320485`:
**reprovada com leitor válido e botão Pausar ausente**. Não é hierarquia vazia nem falha de infraestrutura.
Conforme a ordem G, parei com a evidência; não alterei o app e não reexecutei para tentar aprovar.
**não testado em aparelho**. Nenhum APK distribuído. A decisão sobre menu/app é do revisor.

## Causa anterior confirmada e corrigida

Na run 43030274371, `--dump` retornava `<hierarchy />` com PiP e launcher visíveis.
A consulta ocorria imediatamente após `setServiceInfo`, antes de o Android entregar as janelas interativas.
A aceitação desse vazio em 00302532 foi retirada, e o teste histórico foi invertido.
Agora `--dump` espera até 2.500 ms, consultando a cada 50 ms, até existir raiz não nula.
Sem raiz, imprime `BANCADA_PIP: janelas=N raizes=M` e termina com erro, sem XML vazio de sucesso.
Antes do XML, cada janela tem tipo, condição PiP, pacote da raiz e número de nós.

O contrato da sessão por estado já aprovado ficou **idêntico** à base; comparação por AST conferida.
Nenhum teste anterior foi apagado. O dump real da run 42886090476 e as provas negativas por bit permanecem.
Nenhuma mudança em Media3, serviço, app, integração ou `PortaSessaoPlayerTest.kt`.

## Commits

| Commit | Mudança |
| --- | --- |
| `aa9d651e` | Dois espelhos para ffmpeg, prazos curtos, restauração da lista e seis testes comportamentais. |
| `041e0d51b80d600166db50d57487e53e09d7507e` | Espera de raízes, botão na mesma conexão, diagnósticos, tempos e separação de erros. Empacota classes auxiliares no DEX. |
| `f73204850db72c205309befd80dc9ed13f7a07a4` | Reserva em domínio independente, `mirrors.kernel.org`, e regressão correspondente. |

O commit documental posterior registra os resultados desta execução; não modifica a prova.

## Implementação da prova

`--pip-botao` conecta uma vez, espera raízes, lê e solicita no máximo uma abertura por ACTION_CLICK.
Se o menu já tem controles, aguarda o rótulo atualizar sem outro toque que o fecharia.
Procura na mesma conexão um controle SystemUI visível/habilitado com rótulo exato e retângulo não vazio.
Retorna XML e centro. O toque real continua sendo `adb shell input tap`; não há comando de transporte do app.
Prazo de busca configurado: 8.000 ms desde o início do helper, incluindo conexão e primeira leitura.
Não houve aumento desse prazo, nova tentativa de abertura, skip, tolerância de erro ou redução do mínimo de quadros.

Cada pedido preserva `pip-botao-N.txt` e `pip-botao-N-host.json`, com falha ou sucesso.
As durações são registradas também quando uma etapa iniciada falha; `-1` indica etapa não iniciada.
Erro do helper/XML sem nós reprova como `Leitor de janelas vazio`, com seu diagnóstico.
Ausência do botão em XML válido tem resultado próprio: `Botão PiP não apareceu em 8 segundos`.
Na falha, captura, XML da própria consulta, atividades e sessão são preservados sem uma segunda conexão.

## Infraestrutura destravada

Somente o bloco de instalação ffmpeg do passo `Preparar KVM e espaço` foi alterado.
Prefixo e sufixo desse bloco foram comparados e são idênticos à base.
Tentativas 1–4 da run 43058775685 não chegaram a compilar: archive/Azure atingiram os limites de 45 s.
A reserva passou a `mirrors.kernel.org`, listado pelo Ubuntu, mantendo **dois** destinos:
https://packages.ubuntu.com/jammy-updates/amd64/linux-image-5.15.0-164-generic/download
A consulta local do InRelease de resolute respondeu 200, com metadados assinados; isso não foi contado como bancada.

Na run 43060805478, archive falhou em 45 s e a reserva instalou o ffmpeg; preparação e compilação passaram.
Cada espelho tem update de até 45 s e instalação de até 120 s, conexões de 5 s e sem retries do APT.
A lista é recriada da cópia original em cada tentativa e restaurada ao sair. Se ambos falham, o passo falha.
Não há `continue-on-error` nem `|| true` na instalação; chaves/validação de assinaturas do APT são preservadas.

## Evidência do item G

Artefato `13874447400` da run 43060805478, pedido `mpv-pip-pausa`, saída `pip-botao-1.txt`:

```text
BANCADA_PIP: ACTION_CLICK do Android aceito
BANCADA_PIP: janelas=3 raizes=3
BANCADA_JANELA: tipo=3 pip=false pacote=com.android.systemui nos=27
BANCADA_JANELA: tipo=1 pip=true pacote=app.heisuca.player.teste.home nos=12
BANCADA_JANELA: tipo=1 pip=false pacote=com.google.android.apps.nexuslauncher nos=34
BANCADA_BOTAO_AUSENTE: prazo_ms=8000
BANCADA_TEMPOS: conectar_ms=137 primeira_leitura_ms=288 abertura_ms=27 achar_rotulo_ms=7609 aberturas=1 total_ms=8052
```

O XML foi analisado: **73 nós**, zero ocorrências de qualquer dos cinco rótulos de transporte.
Os 27 nós SystemUI são da barra de status; não há menu PiP nessa leitura.
A captura `mpv-pip-pausa-falha.png`, inspecionada, mostra launcher e vídeo na janela PiP, sem menu.
`mpv-pip-pausa-falha.xml` é o XML dessa mesma consulta; dumps de atividades e sessão também foram preservados.
O host mediu **9.412,17 ms**, código 0, incluindo invocação ADB/envio inicial do helper e seu processamento.
O helper mediu **8.052 ms** ao todo; não afirmo que a medição externa coube em oito segundos exatos.
A busca registra 7.609 ms e inclui a abertura; as durações não são parcelas independentes para somar.
Não aumentei o prazo para acomodar essas medidas. Nenhum clique no botão ausente foi enviado.

Sessão mpv tocando (3, posição 2420, ações 4452347), pausa real pelo sistema e sessão pausada
(2, posição 3962, ações 4452349) passaram; a última prova confirmada foi `mpv-hud-degrade`, sequência 7.
Sem ANR (`anrDoApp=false`). Não houve nova falha FrameTiming nessa run; mínimo de 30 mantido.
Não há `resultado-teste.json`: `testeEncerrado=true`, ExoPlayer e todas as ações PiP **não estão comprovados**.
Não há bancada verde. O leitor agora fornece evidência válida; a ausência do menu/botão segue para o revisor.

## Validação local e limites

Portão: `APROVADO: análise e testes concluídos.`, saída 0.
221 Python naquela execução, 2.386 Flutter (3 pulos preexistentes), 8 Impeller e 15 Kotlin, sem falhas.
Depois das regressões de DEX e reserva independente: suíte Python completa repetida, **223 passaram**.
Análise mantém 40 avisos/informações herdados, com as mesmas opções do portão; não é análise estrita sem avisos.
Testes negativos foram executados antes das correções. Helper compilado e DEX conferido com classe principal e auxiliares.
[Segurança 43060807611](https://github.com/CaioGuerras/heisuca/actions/runs/43060807611): verde.
Android Build 43060807555 ainda em execução ao registrar; sem antecipar resultado.

Provas privadas: `~/cgflix/handoffs/PROVAS_ULTRON_V2_SESSAO_LEITOR_2026-11-11/`;
artefatos em `run-43060805478/`, incluindo saída completa com XML, captura, dumps e durações.
Só scripts/bancada, este handoff e o bloco ffmpeg autorizado mudaram.
App, Android, design, marca, versão, applicationIds, assinatura e dependências ficaram intactos.
Bluetooth, fone físico, carro e aparelho real não foram testados. Nenhum segredo, telemetria ou APK distribuído.
Desfazer: reverter o commit documental desta entrega e depois `f7320485`, `041e0d51`, `aa9d651e`, nessa ordem.
Próxima ação depende da decisão do revisor sobre a evidência do item G; nenhuma alteração no app foi autorizada aqui.
