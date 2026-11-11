# Heisuca V2 — sessão de mídia — 11/11/2026

## Rodada atual — conserto do leitor e espelho reserva

Revisão de a5d064d3: contrato de sessão aprovado e intocado. A causa comprovada da leitura vazia
é consultar janelas logo após setServiceInfo, antes da lista interativa estar disponível.
A aceitação de `<hierarchy />` em 00302532 foi retirada: vazio ou helper com erro reprova como leitor.
--dump agora espera raiz não nula até 2.500 ms (leituras a cada 50 ms); sem raiz, imprime contagens e falha.
--pip-botao conecta uma vez, aguarda raízes, abre no máximo uma vez e procura o rótulo habilitado
na mesma conexão, com prazo total de oito segundos incluindo conexão e primeira leitura.
Toda chamada preserva pip-botao-N.txt e duração do host; o helper registra conexão, primeira leitura,
abertura, busca e total, além das janelas com número de nós e XML final.
Botão ausente em leitor válido mantém mensagem própria de oito segundos. Falha preserva captura
e o XML da própria consulta, sem reconectar nem substituir a causa por uma segunda leitura.
Instalação ffmpeg: archive e mirrors.kernel.org como reserva, update 45 s / instalação 120 s por espelho, conexão 5 s;
se ambos falharem, falha o passo. Lista original restaurada ao sair. Nenhum outro passo foi alterado.
Testes escritos antes: negativos do leitor falharam (8 falhas/2 erros); seis testes dos espelhos tiveram
cinco falhas antes. Depois, 33 testes da sessão e seis dos espelhos passaram. Helper Java compilado.
Portão local APROVADO, saída 0: 221 Python na execução, 2.386 Flutter (3 pulos herdados),
8 Impeller e 15 Kotlin. Após acrescentar a regressão do empacotamento DEX, suíte Python final: 222 passaram.
A análise mantém os 40 avisos/informações herdados, sem novo erro. DEX conferido com classe principal e auxiliares.
Nova bancada: aguardando execução, sem aprovação antecipada.
Se botão ausente com leitor válido, parar e entregar evidência ao revisor. Se FrameTiming falhar,
relatar números e preservar mínimo de 30. Nenhuma edição no app, versão, IDs ou assinatura.

As tentativas 1–3 da run 43058775685 falharam antes de compilar: archive e azure atingiram 45 s cada.
Reserva substituída por mirrors.kernel.org, em domínio independente, mantendo exatamente dois destinos,
limites e verificação APT das assinaturas Ubuntu. Origem da lista e consulta do InRelease conferidas:
https://packages.ubuntu.com/jammy-updates/amd64/linux-image-5.15.0-164-generic/download
A consulta local de https://mirrors.kernel.org/ubuntu/dists/resolute/InRelease respondeu 200 em 3,44 s;
isso não substitui a validação no Actions. Novo teste da reserva falhou antes da mudança e passou depois.

## Histórico anterior — bloqueado, sem aprovação da bancada

Ramo `codex/heisuca-v2-sessao`; início desta rodada em `d88f553b`.
Contrato por estado implementado e provado. **Entrega ainda não pronta**: falta prova completa de PiP nos dois motores.
As três tentativas mais recentes não compilaram nem executaram o percurso: falha de DNS nos repositórios Ubuntu.
**não testado em aparelho**. Nenhum APK distribuído.

## Decisão do revisor incorporada

O revisor retirou a premissa de defeito no app: a Media3 alterna Tocar/Pausar por estado normalmente.
Não houve mudança na Media3, no serviço, no app nem em `PortaSessaoPlayerTest.kt` nesta rodada.

| Estado esperado | Obrigatórias sem próximo | Com próximo |
| --- | --- | --- |
| 3, tocando | Pausar (2), Tocar/Pausar (512), Buscar (256): `0x302` | + Próximo (32): `0x322` |
| 2, pausado | Tocar (4), Tocar/Pausar (512), Buscar (256): `0x304` | + Próximo (32): `0x324` |

Estados diferentes de 2/3 continuam reprovados. Tocando sem Tocar e pausado sem Pausar são aprovados.
Cada bit obrigatório ausente tem prova negativa nos estados pertinentes. Dump sintético atualizado, sem excluir testes.
Diagnóstico mantém estado lido/esperado, posição, máscaras em hexadecimal e nomes dos bits faltantes.
Convergência de oito segundos, frequência e tentativas preservadas; nenhuma tolerância de erro ou teste pulado.
O percurso de integração existente continua intacto.

## Diagnóstico original e fixture real

Artefato `13796583682` da [run 42886090476](https://github.com/CaioGuerras/heisuca/actions/runs/42886090476).
Trecho literal preservado em `fixtures/media_session_android15_42886090476.txt`:

```text
state=PlaybackState {state=PLAYING(3), position=2462, buffered position=2462, speed=1.0, updated=345440, actions=4452347, custom actions=[], active item id=1, error=null}
metadata: size=5, description=Vídeo de amostra, null, null
```

As 27 amostras tinham estado 3, posições 2462/5265/8227 e ações `0x43effb`.
A máscara antiga `0x126` reprovava apenas a ausência de Tocar (4). Não era erro de parse nem posição zero.
Agora a fixture é aprovada com estado 3 e próximo existente.
Fonte da alternância na versão embarcada: [MediaSessionLegacyStub, Media3 1.11.0](https://github.com/androidx/media/blob/1.11.0/libraries/session/src/main/java/androidx/media3/session/MediaSessionLegacyStub.java).
O rebase anterior sobre `4f3ab38a` trouxe `1dc43485` pela base, sem editar os arquivos de design nesta frente.

## Commits desta rodada

| Commit | Mudança |
| --- | --- |
| `a28f3229cc28ed643106855211cf33ed245d9d98` | Contrato por estado, fixture aprovada e provas negativas. |
| `a023f373` | Preservação de captura/XML/atividades/sessão quando o botão PiP falta. |
| `cd491bdc` | Leitura de todas as janelas com UiAutomation, sem esperar idle do vídeo. |
| `00302532` | Extração aceita XML vazio válido `<hierarchy />`, sem nova consulta. |
| `447dec7c` | Abertura do menu pela ACTION_CLICK da janela PiP do Android. |
| `b17c6efd6431aaba13cc800ca7e2a0d172b2bc43` | Preserva hierarquia na conexão que solicita abertura, antes de desconectar. |

Somente `scripts/bancada/HeisucaPipClose.java`, `sessao_media.py`, `test_sessao_media.py` e este handoff mudaram.
Nenhuma mudança em lib/, android/, design/, integração, marca, versão, applicationIds, assinatura ou workflows.
O helper Java é da bancada e não entra no APK. Não há segredo ou telemetria adicionados.
Testes escritos antes dos respectivos ajustes falharam, depois passaram; nenhum teste foi apagado ou afrouxado.

## Resultados das execuções Android

| Run | Resultado real |
| --- | --- |
| [43010848612](https://github.com/CaioGuerras/heisuca/actions/runs/43010848612) | Sessão mpv tocando/pausada aprovada; botão PiP Pausar não apareceu em oito segundos; reprovada. |
| [43012943290](https://github.com/CaioGuerras/heisuca/actions/runs/43012943290) | Mesma falha PiP; captura mostra vídeo em janela fixada e XML somente do launcher; reprovada. |
| [43015408212, tentativa 1](https://github.com/CaioGuerras/heisuca/actions/runs/43015408212/attempts/1) | Sessões tocando/pausadas dos dois motores aprovadas; FrameTiming 29/21 quadros, abaixo dos 30 exigidos; reprovada. |
| [43015408212, tentativa 2](https://github.com/CaioGuerras/heisuca/actions/runs/43015408212/attempts/2) | Extração rejeitou hierarquia vazia válida; corrigida em 00302532. Depois, encerramento do emulador preso até o limite do job; não aprovado. |
| [43027989859](https://github.com/CaioGuerras/heisuca/actions/runs/43027989859) | Sessão mpv aprovada; Pausar PiP não apareceu; reprovada. |
| [43030274371](https://github.com/CaioGuerras/heisuca/actions/runs/43030274371) | Mesmo botão ausente após abertura pela ação do sistema; reprovada. |
| [43032929026, tentativas 1–3](https://github.com/CaioGuerras/heisuca/actions/runs/43032929026) | Infraestrutura: preparação falhou por DNS/pacotes Ubuntu; não compilou nem executou o percurso. Dois reruns dos jobs falhos, sem alterar workflow. |

Na terceira tentativa de infraestrutura, o log contém:

```text
Temporary failure resolving 'archive.ubuntu.com'
Temporary failure resolving 'security.ubuntu.com'
The action 'Preparar KVM e espaço' has timed out after 10 minutes.
```

As runs que executaram o percurso não registraram ANR. Isso não substitui prova completa.
A última coleta, antes de desconectar acessibilidade, ainda não foi exercitada por causa da infraestrutura.
Não foi comprovado `testeEncerrado=true` com ambos os motores e todas as verificações de sessão/PiP verdadeiras.
Não há bancada verde nesta entrega, nem classificação de falha PiP como infraestrutura.

## Prova do PiP: o que mudou e o que falta

A leitura inicial com uiautomator retornou apenas o launcher, sem menu; a captura também mostrou menu fechado.
O leitor rápido consulta todas as janelas; o menu continua selecionado por rótulo exato, visibilidade e habilitação.
A abertura usa uma ACTION_CLICK da janela PiP, sem chamar transporte do app nem fabricar resposta.
AOSP 15 encaminha essa ação a `onAccessibilityShowMenu()`:
[fonte do Android](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android15-release/libs/WindowManager/Shell/src/com/android/wm/shell/pip/phone/PipAccessibilityInteractionConnection.java).
Mesmo essa abertura não completou a prova. Ainda não sabemos se o menu não abre ou se some entre consultas.
O commit b17c6efd preserva a hierarquia antes da desconexão para resolver essa dúvida; precisa de execução.
O prazo externo permanece oito segundos, sem solicitação adicional de abertura ou mudança de asserção.
Não alterar o app com essa causa ainda incerta; não reduzir os 30 quadros nem ampliar prazo para aprovar.

## Validação local e CI

Portão local final executado: `APROVADO: análise e testes concluídos.`, saída 0.
209 Python, 2.386 Flutter (3 pulos preexistentes), 8 Impeller e 15 Kotlin, nenhuma falha.
Após os dois ajustes apenas de Python/diagnóstico, suíte Python completa repetida: **211 testes passaram**.
Helper Java compilado localmente após as mudanças; nenhuma mudança em Kotlin do app.
Análise do portão mantém 40 avisos/informações herdados com suas opções existentes; não é análise estrita sem avisos.
[Android Build 43015390118](https://github.com/CaioGuerras/heisuca/actions/runs/43015390118): verde no cd491bdc.
[Segurança 43032912234](https://github.com/CaioGuerras/heisuca/actions/runs/43032912234): verde no b17c6efd.
Build 43032912271 ainda em execução ao registrar este handoff; sem afirmar resultado antecipado.
Provas locais privadas: `~/cgflix/handoffs/PROVAS_ULTRON_V2_SESSAO_CONTRATO_2026-11-11/`.
Logs de testes seguem o padrão `ultron-v2-*-red.log` e `*-green.log`; portão `ultron-v2-contrato-gate-final.log`.

## Retomada e limites

Quando a infraestrutura voltar, executar a bancada no b17c6efd ou sucessor e ler a hierarquia de abertura.
Exigir prova completa nos dois motores; se falhar, corrigir somente causa demonstrada dentro do escopo autorizado.
Bluetooth, fone físico, carro e aparelho real não foram testados. Retomada com Dart encerrado mantém a limitação anterior.
Sem produção, merge, distribuição de APK ou alteração nos motores/superfícies.
Desfazer: reverter os commits da tabela, do mais recente ao a28f3229, e o commit documental desta atualização.
