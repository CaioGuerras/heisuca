# P3 — estados e avisos: diagnóstico antes dos patches finais

Base enviada: df479e5, APK 40524767696 verde, bancada 40524767724 ATENÇÃO.
Os patches abaixo estão em trabalho local; não confundir a prova daquele commit
com o conjunto ainda não enviado.

## Avisos e diálogos

72 combinações de sono/episódios/próximo reproduziram títulos fora da fonte e
superfícies fora da paleta. Sono em fonte 200% também estourou 32 px à direita;
episódios ficaram acima da janela no celular em paisagem. Prova:
`evidencias/p3_prompts_antes_2026-10-27.txt` e `p3/prompts-antes/`.

O cartão ganhou largura conforme a fonte/área disponível e o texto do botão
pode quebrar linha. Tipografia/cor usam os papéis existentes. 72 visuais e os
fluxos preexistentes de sono/EOF passaram juntos: **99 testes** em
`/tmp/p3-prompts-and-behavior-after.log`. Timers e callbacks não foram alterados.

120 combinações dos diálogos compartilhados: 114 passaram; seis casos do
diálogo com alternância estouraram 57/64 px em fonte 200%. O AlertDialog passa
a usar `scrollable: true`, mantendo ações acessíveis. Resultado posterior:
**120/120**, `/tmp/p3-dialogs-after.log`. A fixture só abre os componentes com
argumentos dos chamadores reais; não cria recurso offline nem altera seu esquema.

## Dados e estados: falha identificada na causa

Matriz de 168 estados de Início/Biblioteca: **96 aprovados, 72 com falha**.

- `_cachedThenNetwork` transformava exceção em `CgflixRowData(items: [])` se
  não tinha mostrado cache. A UI já tem `_HomeLoadFailed`, mas esse fluxo não
  chegava nela. A resposta de erro do servidor era indistinguível de consulta
  bem-sucedida sem títulos. Prova adicional do repositório: erro sem cache
  não lançou a exceção esperada; cache com conteúdo foi mantido corretamente.
- Cache vazio conhecido também aparecia como resposta nova (`fromCache:false`)
  após falhar a rede. A correção deve representá-lo como cache, preservando a
  busca por conteúdo novo e a proteção contra esqueleto permanente.
- Biblioteca mostrava a mensagem de erro e o estado de coleção vazia juntos.
  A condição de vazio precisa exigir ausência de erro.
- O título de fonte indisponível usa Inter em vez de Sora. Capturas anteriores
  estão em `p3/estados-antes/`.

Correção prevista: cache conhecido é apresentado como cache; sem cache, a
exceção chega ao tratamento de falha JÁ EXISTENTE da tela. Manter cache válido
quando a rede falha e não mudar a composição da Início com dados. Conferir o
contraste do texto de orientação quando esse erro passar a ser exibido; hoje
esse ramo usa branco translúcido inclusive no tema claro.

## Limites que não autorizam inventar estado

Hero vazio não prova acervo vazio: a consulta filtra Backdrop/Logo. Não adicionar
aviso global de “acervo vazio” usando apenas esse resultado. A composição aprovada
continua preservada, e os estados vazios reais de Biblioteca/Baixados/Busca são
verificados pelos seus próprios dados.

A prova de faixas GRAVADAS NO ARQUIVO continua bloqueada: no run 40524767724 o
motor informou 1920×1080, mas `screenshot-to-file ... video` devolveu
PlatformException e nenhum quadro decodificado foi produzido. O recorte nativo
comprova o pillarbox geométrico de 120 px na janela 1200×540; isso não autoriza
atribuir outras faixas ao arquivo. Falta o original/quadro de origem verificável
(pode ser conferido pela Jocasta/Visão onde têm acesso à mídia). Nenhum zoom,
corte ou proporção do app foi alterado para esconder barras.

Não testado em aparelho. Revisão independente pendente.

## Correções e prova posterior local

O repositório agora emite qualquer cache conhecido com `fromCache:true`;
cache vazio continua consultando a rede. Sem cache, a exceção chega à tela,
em vez de virar lista vazia. Cache com títulos permanece disponível na falha.
Os três casos novos e o conjunto anterior do repositório passaram juntos
(**21 testes**; `/tmp/p3-home-repository-after.log`).

Com o erro real exposto, a matriz reproduziu mais oito falhas de contraste no
Hisui claro: a orientação usava branco translúcido. A cor passa pelo token
`textOn`, e o ícone usa destaque. Prova anterior:
`evidencias/p3_erro_contraste_antes_2026-10-27.txt` e
`p3/estados-erro-exposto/`.

Biblioteca só mostra vazio se não há carregamento nem erro. Na fonte
indisponível, o título usa Sora. A mudança revelou overflow de 26 px em três
casos de celular/paisagem/200%: a coluna rígida não cabia na altura disponível.
Prova em `evidencias/p3_fonte_offline_altura_antes_2026-10-27.txt`.
O conteúdo mantém o centro quando cabe e permite rolagem quando necessário,
sem limitar a fonte. A Início com dados conserva sua composição.

Matriz posterior de estados: **168/168**
(`/tmp/p3-states-after-final.log`). Avisos e diálogos somam mais 192
combinações. O portão completo desta árvore ainda está em execução;
seu resultado e os runs seguintes serão registrados no HANDOFF.

**Portão completo posterior concluído:** 2.118 Flutter + 3 skips opcionais
herdados, 8 Impeller, 46 Python. Inclui os testes adicionais de digitação e
alternância dos diálogos e todas as matrizes antigas. Log preservado em
`evidencias/p3_segunda_coleta_portao_2026-10-27.txt`. Analyze sem erros;
os warnings preexistentes continuam identificados para P4.
