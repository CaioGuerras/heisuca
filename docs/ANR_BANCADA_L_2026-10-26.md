# ANR observado na bancada da L — 26/10/2026

A causa ainda não foi demonstrada. Não foi aplicada correção na navegação ou no
mpv, nem foi classificado como falha de infraestrutura.

| Execução | Código | Evidência |
|---|---|---|
| K 40251727025 | e02fcd5 | Verde; Caio conferiu 06-player.png com vídeo normal. |
| L 40256320245 | f617c2e | Falhou esperando a ficha após Back. Caio conferiu ANR “Heisuca Teste isn't responding”, Close app/Wait, em 06-player.png. Restauração confirmada. |
| L 40258843944 | 741e7a7 | Verde: mpv, quadro nativo, avanço de 3,448 s, percurso completo/restauração confirmada. Só havia sido acrescentada coleta de estado no timeout; lógica do app não mudou. |

`capturas.py` salva 06-player.png **antes** de injetar Back. Portanto o diálogo
já existia antes desse comando; não se pode atribuí-lo ao pop/dispose sem provar
a cronologia (inclusive eventual saída automática do vídeo).

O Caio confirmou que o execucao.log completo não contém ANR in/Reason. O trecho
final do Actions contém `aimagereader: Waiting for frame timed out`, que sozinho
não explica o ANR. O driver acompanha o processo do app; o motivo fica no
system_server. Download dos artifacts neste ambiente retorna 403; o conteúdo da
imagem acima foi informado pelo Caio, não inspecionado localmente pelo Codex.

Comparação direta com e02fcd5:
- MainActivity, MpvPlayerCore e MpvPlayerPlugin são idênticos depois de normalizar
  namespace/canais e o nome da fábrica de renderers. Não há mudança no corpo da
  lógica de saída desses arquivos.
- PlayerNative é idêntico depois de normalizar nomes de canais.
- No dispose do VideoPlayerScreen foi retirado um breadcrumb Sentry. As demais
  diferenças desse arquivo são import do SDK, pacote Dart e comentário de marca.
- cc5c6ad, 479b129 e 7d1e1bf permanecem. Os arquivos de rota de sessão, descoberta
  de endpoint e escolha da navegação não tiveram alteração funcional na L.

Essa comparação não prova a causa: mudança de identidade/dependências também
pode alterar carregamento ou tempo de execução. Não inferir “culpa do emulador”
nem “Sentry removido causou” só dessa lista. A repetição verde não corrige o ANR.

Coleta nativa acrescentada em scripts/bancada/diagnosticos.py: logcat dos buffers
events/system e dumpsys activity lastanr, **antes** de force-stop/restauração,
com redação antes de gravar/publicar. Se houver ANR do próprio pacote, a bancada
fica vermelha mesmo que o percurso termine; coleta indisponível também não vira
verde. Sem classificação automática de infraestrutura. Testes cobrem motivo,
evento am_anr, pacote diferente e indisponibilidade. Execução real da coleta
aguarda o próximo run; não se afirma que esse run reproduzirá o ANR.

A coleta real no run 40261399848 (`2d47850`) registrou ANR próprio: am_anr às
03:10:47, **Input dispatching timed out / FocusEvent(hasFocus=true) / 5009 ms**.
No mesmo intervalo o Android abriu ANR de com.google.android.apps.messaging.
Carga: 42.15 / 15.07 / 5.44; pressão CPU some.avg10=91.61, some.avg60=79.17;
pressão de memória some.avg10=9.53. Restauração confirmada. O registro nativo
identifica saturação sistêmica, mas não contém a stack main do aplicativo.

Próximo experimento mantém o mesmo app, API, ABI, dispositivo, RAM e renderizador;
troca google_apis pela imagem AOSP `default` (sem GMS/Mensagens do Google, que o
login Jellyfin/player não usam). Existência conferida no catálogo oficial:
https://dl.google.com/android/repository/sys-img/android/sys-img2-3.xml
`system-images;android-35;default;x86_64` — Intel x86_64 Atom System Image.
Não se alteram pop, prazos, player nem se envia Back adicional. A hipótese é
reduzir a disputa de CPU do boot; o resultado ainda precisa ser observado.

O emulador de teste passa a permitir leitura de /data/anr com adb root. Em ANR,
a coleta lê os três arquivos recentes e conserva só blocos `Cmd line` do próprio
pacote, redigidos; imprime a stack main, quando disponível. O dumpsys passa a ser
preservado integralmente após redação, sem substituir o texto original por uma
interpretação do parser. ANR próprio continua impedindo verde. Não há mudança
nas permissões nem no código do APK de produto.

Retorno do Caio sobre o run AOSP 40264419251: `BANCADA_RETORNO` mostrou player
visível/presente, ficha presente mas fora de cena, busca/Início fora de cena.
12-falha-retorno.png mostra **Quickstep isn't responding**, do launcher AOSP,
não ANR do Heisuca. O dump indica launcher topResumedActivity, sem janela focada,
PiP=false e nenhuma Activity do app resumed/focada. A coleta marcou corretamente
anrDoApp=false; o teste de retorno, porém, continuou falhando. Não atribuir toda
a falha a um ANR do app, nem classificar esse percurso como aprovado/instável.

O manifest fonte é byte a byte igual a e02fcd5 (SHA-256
45c47d787b33a14dc5feda2cf5ee58833abdc6c1ebd9e479e627c03a35e957dc):
launchMode=singleTop, taskAffinity vazia, configChanges e PiP iguais. O namespace
Gradle mudou; portanto os nomes completos das Activities/aliases relativos no
APK mudaram, como pedido na L. Isso não prova que a troca perdeu o foco.

A próxima comparação volta para google_apis, imagem da K. Sem trazer o app para
frente e sem repetir Back: grava activity/window imediatamente antes e depois
do comando, atributos/callback da janela do próprio app, ciclo de vida nativo,
marcos do teste, estado da rota/navigators e chegada do pop ao Flutter. O
observador retorna false, não consome eventos. Flags passam direto ao Actions e
ao JSON final, em vez de depender das últimas 60 linhas. Resultado ainda pendente.

## Execução com foco instrumentado — 40269817747

Commit 43ad4df, imagem google_apis API35, resultado aprovado. Às 04:53:28,
antes do Back, topResumedActivity/mFocusedApp/mCurrentFocus apontavam ao Heisuca;
às 04:53:29 continuavam nele. Flutter resumed, rota atual/não inicial com
popDisposition=pop. Evento pop recebido às 04:53:29 e ficha capturada às 04:53:38.
Percurso completo, mpv/quadro nativo +3,22 s, restauração confirmada e anrDoApp=false.

Essa execução não reproduz a perda de foco. Não houve correção de navegação/mpv,
nem se demonstrou causa dos ANRs intermitentes. L tem agora APK e bancada verdes;
o histórico permanece aberto e a coleta/guard continua nas próximas etapas.
Não foi atribuída classificação de infraestrutura aos runs vermelhos.
