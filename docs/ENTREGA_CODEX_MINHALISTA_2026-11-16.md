# Entrega — Jocasta, Minha lista com Plex — noite 16→17/11

Implementação concluída no worktree `heisuca-minhalista-plex`, base `6677c9a20b8ca7d636a9c9c51ae0dc3c43e273b7`. Sem push, merge, APK ou publicação. Não testado em aparelho nem contra contas/servidores reais. Aguarda revisão independente do Visão.

## Commits e limitação do ambiente

- `ab1aa638`: une favoritos dos servidores e Watchlist Plex; carregador e testes de regressão.
- `e51a9c71`: usa todos os servidores online visíveis ao perfil, mesmo ao navegar por uma biblioteca de servidor específico; cliente de imagem por item também na tela antiga.

**Os commits estão em metadados Git isolados em `/tmp/heisuca-minhalista-git`, no ramo `claude/heisuca-v2-minhalista-plex`. O ramo do repositório compartilhado continua na base.** O sandbox permite editar os arquivos deste worktree, mas os metadados reais ficam em outro worktree e são somente leitura:

```text
fatal: Unable to create '/mnt/nvme4n1/caioguerras/TMP/heisuca-visao/.git/worktrees/heisuca-minhalista-plex/index.lock': Read-only file system
```

Foi usado um índice/objetos/referências próprios em `/tmp`, com leitura dos objetos da base por alternates. Nenhum arquivo do outro worktree foi alterado. O bundle `/tmp/heisuca-minhalista-plex.bundle` preserva os commits para incorporação após revisão. Os arquivos corrigidos também estão neste worktree, como alterações locais em relação à base compartilhada.

A pasta externa solicitada para a entrega também fica fora das raízes graváveis do sandbox. Esta cópia no repositório e suas evidências ficam disponíveis para o coordenador copiar para `~/cgflix/handoffs/NOITE_2026-11-16/ENTREGA_CODEX_MINHALISTA.md`.

## O que mudou

`CgflixFavoritesSource.of` reúne todos os clientes Jellyfin/Emby online visíveis ao perfil e a fonte Plex de `CatalogSourcesProvider.connectedSources`, independentemente da fonte escolhida no catálogo. A seleção de uma biblioteca não limita a Minha lista ao servidor daquela biblioteca. Não atravessa os limites de visibilidade do perfil.

O novo `favorites_loader.dart`:

- Lê favoritos de todas as bibliotecas de cada Jellyfin/Emby, com páginas de 300 itens e `ProviderIds` para reconhecer duplicatas entre servidores. Preserva os campos de cartão, os campos retidos pelo Emby e o nome da biblioteca para classificação de anime.
- Lê páginas de 100 títulos da Watchlist até `hasMore == false`; cada título único é resolvido nos servidores Plex ligados por `findByExternalIds`, com o `plex://movie/...` ou `plex://show/...` reconstruído da chave da conta e os identificadores externos. Reutiliza a busca reversa existente por `/library/all?guid=`, sem busca por nome nem resolução no cartão.
- Executa até quatro resoluções de títulos Plex simultaneamente, uma por título único/servidor. Há também limite de quatro trabalhos de fontes; as bibliotecas de cada Jellyfin são consultadas em sequência. Não há uma consulta única para a Watchlist inteira: o lote é uma fila limitada de consultas exatas.
- Descarta títulos da Watchlist que não estejam em nenhum servidor Plex online do perfil. Conserva apenas uma cópia por identidade global/ID externo/guid, separando filmes e séries.
- Ordena alfabeticamente como antes. `agruparFavoritos` e sua ordem Séries, Filmes, Animes ficaram intactos.
- Isola falhas de fontes e de servidores Plex; sem nenhuma fonte bem-sucedida, propaga erro para o estado que a tela já oferece. Uma resposta vazia bem-sucedida é lista vazia, não erro.
- Marca os títulos Plex resolvidos como pertencentes à lista para o menu oferecer remoção.

A ligação da tela, a ficha e `HeisucaStateStore` preservam seus caminhos de gravação. O teste de cartão chama a loja padrão, verifica `gravar(false)` na ponte da conta Plex e comprova o recarregamento que retira o cartão. A ficha já recarrega a aba ao voltar.

## Prova negativa obrigatória

Teste: `apps/app/test/features/minha_lista/fontes_plex_test.dart`, nove casos, nenhum skip novo.

Após o commit de trabalho, foi executado `git checkout 6677c9a2 -- apps/app/lib/cgflix/you/cgflix_favorites_screen.dart`, com `GIT_DIR`/`GIT_WORK_TREE` apontando aos metadados isolados. Em seguida:

```sh
cd apps/app
flutter test --no-pub test/features/minha_lista/fontes_plex_test.dart --reporter expanded
```

A restauração ocorreu em `finally`, com `git checkout HEAD -- apps/app/lib/cgflix/you/cgflix_favorites_screen.dart`. Não foi usado stash. O carregador novo ficou sem importação e sem uso quando a fonte antiga foi restaurada. A falha foi de comportamento, sem erro de compilação.

Saída real na base (código de saída 1):

```text
00:00 +0: só Plex: a Watchlist entra na Minha lista com o título do servidor
The following TestFailure was thrown running a test:
Expected: not null
  Actual: <null>
Minha lista também existe com só Plex

Jellyfin + Emby + Plex: todos entram, sem duplicar o mesmo título
Expected: ['Jellyfin 1', 'Jellyfin 3', 'Plex 2']
  Actual: MappedListIterable<MediaItem, String?>:['Jellyfin 1']

Plex falhando: mantém os favoritos do Jellyfin
Expected: [1]
  Actual: []
```

O último caso também exige provar que a fonte Plex foi consultada e falhou: a base ignora o Plex inteiramente e não satisfaz essa prova.

Saída completa, inclusive os nove casos que falharam: [prova_negativa.log](evidencias/minhalista_2026-11-16/prova_negativa.log). Depois da restauração, a mesma suíte passou nos nove casos: [teste_corrigido.log](evidencias/minhalista_2026-11-16/teste_corrigido.log).

## Validação

SDK isolado: `/tmp/heisuca-minhalista-flutter` (cópia do SDK indicado nas regras). O cache do Pub também precisou ser copiado para `/tmp/heisuca-minhalista-pub-cache`, pois o original não permite criar `active_roots`. `TMPDIR=/tmp` evita a pasta temporária original somente leitura.

```sh
export TMPDIR=/tmp PUB_CACHE=/tmp/heisuca-minhalista-pub-cache
export XDG_CACHE_HOME=/tmp/heisuca-minhalista-cache
export PATH="/tmp/heisuca-minhalista-flutter/bin:$PATH"
dart format -l 120 lib/design test/design
flutter test test/design
flutter test test/heisuca
flutter test --no-pub test/features/minha_lista/fontes_plex_test.dart --reporter expanded
flutter() { /tmp/heisuca-minhalista-flutter/bin/flutter "$@"; }
python3() { command python3 -I "$@"; }
export -f flutter python3
bash scripts/heisuca-checar.sh
```

A função exportada de Flutter faz o portão usar o SDK isolado, apesar do PATH próprio do script; o script do portão não foi alterado. A função de Python aplica `-I`.

- Formatação de design: sem alteração nos 35 arquivos de design; os arquivos novos também foram formatados.
- `test/design`: 155 testes aprovados.
- `test/heisuca`: 1.538 aprovados; três capturas condicionais já existentes não executadas porque `HEISUCA_SNAPSHOT` não foi ligado. Não foram criados nem alterados skips.
- Teste novo, estado final: nove aprovados, incluindo o cartão Plex removido pelo caminho padrão e o limite de quatro consultas.
- Portão completo: **APROVADO**, código de saída 0. Foram 181 testes Python, 2.790 testes Flutter aprovados (três capturas condicionais preexistentes) e oito testes adicionais com Impeller. A análise reportou 42 avisos/informações preexistentes em outros arquivos e nenhum erro, sem diagnóstico nos arquivos desta alteração. [Resumo do portão](evidencias/minhalista_2026-11-16/portao_resumo.log); log integral em `/tmp/minhalista-portao-final.log`.

A primeira execução do portão coincidiu com o ajuste final do escopo de servidores durante a compilação e falhou em quatro testes da fonte. Foi repetida integralmente depois da prova negativa final, com os arquivos de código congelados. O registro do resultado acima refere-se à execução final.

## Riscos, limites e o que não foi feito

- Sem teste físico, sem servidor Plex/Jellyfin/Emby real, sem conta Plex real. O teste de gravação usa a ponte falsa `ListaDoPlex`; o transporte e o resolvedor existentes não foram reescritos.
- Bibliotecas com metadados incompletos, sem identificadores externos comuns, podem manter duas cópias. Não se unem títulos só pelo nome, para não misturar obras diferentes.
- Havendo favorito Jellyfin e Watchlist Plex da mesma obra, a cópia Jellyfin tem prioridade, para preservar o comportamento anterior. Remover o favorito de uma fonte não remove a marcação da outra; ela pode aparecer no próximo carregamento. Não foi criada uma operação de apagar de todas as contas.
- Falha ao ler uma página da Watchlist invalida essa fonte no carregamento; as outras fontes continuam. Falha em um servidor Plex não descarta os resultados dos outros.
- O tempo total depende do tamanho da Watchlist e do número de servidores. Os lotes limitam a concorrência, mas não impõem truncamento à lista; cada leitura de página/resolução usa o prazo de consulta existente.
- Não foram alterados versão, applicationId, workflows, design, agrupamento, lógica de player ou outro worktree. Não houve push, publicação, merge, leitura de segredos nem envio a terceiros.
- A entrega externa e a atualização da referência Git compartilhada precisam ser feitas pelo coordenador fora deste sandbox. O bundle permite incorporar os commits sem reconstituir o código à mão.

## Como desfazer

Depois de incorporar os dois commits de código, revertê-los na ordem inversa (`e51a9c71`, depois `ab1aa638`). Neste worktree ainda não incorporado ao Git compartilhado: guardar os dois arquivos novos em `~/Arquivos_Obsoletos/<data>_minhalista_plex/` e restaurar `apps/app/lib/cgflix/you/cgflix_favorites_screen.dart` da base `6677c9a2`. Nenhum desses comandos de desfazer foi executado. A documentação e os logs podem permanecer como registro.
