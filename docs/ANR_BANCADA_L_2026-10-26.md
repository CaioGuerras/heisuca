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
