# Bancada Android — etapa K

Workflow separado: `.github/workflows/heisuca-bancada-android.yml`, acionado no
mesmo ramo autorizado. API 35, Pixel 6, x86_64, 4 GiB; usa o mpv nativo que já
existe nessa ABI. Não substitui aparelho real, Android 17 nem teste de fluidez.
O APK de avaliação continua no workflow Heisuca Android Build: a bancada não
bloqueia seu artifact quando o emulador falha. Workflow da bancada fica vermelho
com relatório **instável**, jamais transforma falta de teste em aprovação.

## Percurso

`integration_test/bancada_android_test.dart` inicia o app real, com os mesmos
mixins de entrada/semântica no binding oficial `integration_test`. O bootstrap
aceita uma fábrica do binding; teste local verifica criação única e composição.
Não há cliente falso, servidor local de demonstração nem player substituído.

Abertura e login vazio; autenticação real; Início; busca de um filme identificado
pelo ID; ficha; reprodução de trecho por pelo menos 3 segundos, após evento de
quadro nativo e avanço da posição; retorno com Back do Android (`adb`); Biblioteca,
Baixados e Você. O perfil local do emulador é anonimizado antes das capturas,
sem alterar nome/foto no servidor. Chaves estáveis de campos e abas só identificam
os componentes; não mudam apresentação ou lógica de navegação.

Marcos chegam ao host por arquivo JSON privado publicado por rename. O teste
espera um ACK com o mesmo número, também publicado atomicamente. O host para e
aguarda o processo de gravação, salva a captura nativa e envia Back quando pedido;
só então confirma o marco. Em particular, a digitação só começa após confirmar
que o vídeo do login vazio terminou. Não há conversão da superfície Flutter nem
callbacks de screenshot do SDK (que no Android chegam somente ao final).

Capturas pelo `adb screencap` incluem superfícies nativas. Vídeos separados por
orientação/fase: abertura/login vazio, acervo/busca/ficha, player nativo e
retorno/abas. Não se grava a digitação de endereço/usuário/senha. O relatório
registra motor efetivo, evento de quadro e segundos avançados; não declara que
outro motor foi testado. `ffprobe` verifica que os MP4 contêm imagem.
O arquivo do servidor pode ser longo: o teste reproduz um trecho curto; duração
real consta no relatório. Prefere filmes curtos/AVC disponíveis, sem alterar mídia.

## Conta e restauração

Segredos do job: `HEISUCA_TESTE_SERVIDOR` e `HEISUCA_TESTE_CONTAS`, conforme o
handoff. Senha vazia. Prioridade para teste-sem-senha; demais em ordem. Nunca
entra em conta terminada em `-kids`. Consulta `/Sessions` com o próprio token;
qualquer sessão com item em reprodução, inclusive pausada, faz poupar a conta.
Falha de consulta não é interpretada como conta livre. Confere novamente antes
do play. Nenhum nome de conta vai para mensagens ou relatório público.

Somente filme **sem histórico**: Played=false, posição=0, contagem=0 e data nula.
Uma leitura individual confirma isso antes de usar. Não sobrescreve um resume
anterior nem tenta reconstruir histórico por eventos fictícios de reprodução.

O host para o app, lê a sessão criada no armazenamento privado do APK de teste,
valida o usuário selecionado e encerra essa sessão pelo próprio token. Depois,
se necessário, usa `DELETE /Users/{userId}/PlayedItems/{itemId}` e compara os
campos anteriores/atuais: progresso, assistido, contagem, data, favorito, avaliação
para confirmar a restauração. Não limpa enquanto outra sessão usa o mesmo item.
Encerra também a sessão do host e apaga os dados locais do emulador.

Protocolo conferido no Jellyfin upstream, commit
`ca6dcf73d65ebd896153bdd9a6def580c0ef6d1f`:
- [PlaystateController](https://github.com/jellyfin/jellyfin/blob/ca6dcf73d65ebd896153bdd9a6def580c0ef6d1f/Jellyfin.Api/Controllers/PlaystateController.cs)
- [BaseItem.ResetPlayedState](https://github.com/jellyfin/jellyfin/blob/ca6dcf73d65ebd896153bdd9a6def580c0ef6d1f/MediaBrowser.Controller/Entities/BaseItem.cs)
- [SessionController](https://github.com/jellyfin/jellyfin/blob/ca6dcf73d65ebd896153bdd9a6def580c0ef6d1f/Jellyfin.Api/Controllers/SessionController.cs)

Não foi presumido um endpoint genérico de escrita de UserData: o reset oficial
limpa exatamente os quatro campos de reprodução; por isso a seleção exige o
estado inicial vazio. A resposta real do servidor ainda precisa passar no CI.

Restauração não confirmada deixa a bancada vermelha com **restauração pendente**,
posição da conta na lista e item que precisa de conferência. Nunca anuncia verde
nesse caso. Timeout e término do processo têm limpeza; perda completa do runner
não foi simulada. Se houver interrupção, conferir o relatório antes de repetir.

## Dados privados

O APK de teste é compilado antes de iniciar o emulador, sem credenciais nem defines
privados. Configuração chega por stdin ao diretório privado do app (0600) e é
apagada na limpeza. APK debug, banco e sessão não são publicados. Cache de resultados de compilação Gradle fica
desligado na bancada; não se guarda build nem `.dart_tool` entre runs. Log é
redigido antes de gravar: nomes, formas codificadas, tokens, identificadores e URLs
omitidos. Artifact contém apenas capturas, vídeos, log redigido e relatório.
O intervalo de digitação do login não entra nos vídeos; perfil local usa nome e
imagem anônimos antes de registrar a Início.

## Validação local e limites

Treze testes Python verificam rodízio, contas infantis, ocupação, erro de sondagem,
seleção sem histórico, restauração efetiva, concorrência no item e redação do log; também ordem de parada/captura/ACK,
falha sem confirmação, Back nativo e rejeição de marcos inválidos.
Teste Flutter verifica o binding composto. Análise estática inclui integração e
driver. A execução Android autenticada depende do job; não foi rodada localmente,
nem se afirma aprovação física. Segredos não são legíveis pelo token local: o CI
recebe os valores diretamente do GitHub, sem expô-los ao agente.
