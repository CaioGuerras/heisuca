# Lacunas de UX do Heisuca web — 09/11/2026

Implementação no worktree `claude/heisuca-web-lacunas`. Todas as alterações ficam em `apps/web/`. Sem commit, push, publicação, acesso ao acervo ou comunicação externa. Documento colocado em `apps/web/docs/` para respeitar o limite de escrita solicitado.

## Entrega por item

| Item | Implementação | Arquivos principais (relativos a apps/web) |
| --- | --- | --- |
| 1. Imagem no canto | Botão condicionado a `document.pictureInPictureEnabled`; tecla P alterna; acompanha entrada/saída nativa e fecha a janela do próprio vídeo ao desmontar ou sair da página. Falha da API gera aviso. | `src/telas/Player.tsx`, `src/player/controles.ts`, `src/comp/Icone.tsx` |
| 2. Velocidade | Seis opções no painel: 0,5×, 0,75×, 1×, 1,25×, 1,5× e 2×. Mantém velocidade na recarga de faixa e restaura 1× em vídeo novo. | `src/player/PainelFaixas.tsx`, `src/player/controles.ts`, `src/telas/Player.tsx`, `src/telas/player.css` |
| 3. Atalhos | ↑/↓ alteram volume em 5%, C desliga/restaura a última legenda escolhida, J/L recuam/avançam 10 segundos, P alterna imagem no canto. Preservados espaço/K, setas horizontais, F, M, Esc e códigos de controle remoto. Campos de texto, seleção e conteúdo editável não são interceptados; barras de ajuste preservam os atalhos. Não havia lista de atalhos na ajuda. | `src/player/controles.ts`, `src/telas/Player.tsx` |
| 4. Prévia na barra | Balão com o tempo no ponto do ponteiro. Jellyfin usa metadados Trickplay do item, escolhe largura adequada, calcula folha/coluna/linha e recorta com `background-position`, incluindo escala de imagens maiores. Nenhuma imagem é pedida antes de entrar na barra. Imagem ausente ou inválida e Plex mostram somente o tempo. | `src/player/PreviaBarra.tsx`, `src/api/trickplay.ts`, `src/api/tipos.ts`, `src/api/servidor.ts`, `src/api/jellyfin.ts`, `src/api/plex.ts`, `src/telas/player.css` |
| 5. Fim de filme | Estado final com foco em “Voltar ao título”, “Assistir de novo” e até seis recomendações. Repetir prepara sessão nova desde zero, inclusive no Plex, cujas legendas temporárias são liberadas ao terminar. Fluxo existente de próximo episódio preservado. | `src/telas/Player.tsx`, `src/comp/MaisComoEste.tsx`, `src/telas/player.css` |
| 6. Mais como este | Fileira ao fim do título, compartilhada com o fim do filme. Jellyfin pede `/Items/{id}/Similar` com usuário, limite 12 e campo de proporção da imagem; Plex consulta `/library/metadata/{ratingKey}/similar`. Falha no Plex torna a capacidade falsa naquela sessão; outra sessão inicia nova detecção. Fileira vazia desaparece. Respostas após desmontagem são ignoradas. | `src/comp/MaisComoEste.tsx`, `src/telas/Titulo.tsx`, `src/api/servidor.ts`, `src/api/jellyfin.ts`, `src/api/plex.ts`, `src/telas/titulo.css` |
| 7. Trailer e compartilhar | Trailer local é obtido pelo adaptador ao clicar e abre no player; remoto HTTP(S) abre em nova aba com `rel="noopener"`. Compartilhar usa o link do título e `navigator.share`; sem ele, copia e avisa “Link copiado”. Cancelamento nativo é silencioso; erros de cópia não anunciam sucesso. Capacidade de trailer local falsa no Plex. | `src/telas/Titulo.tsx`, `src/dados/compartilhar.ts`, `src/api/tipos.ts`, `src/api/servidor.ts`, `src/api/jellyfin.ts`, `src/api/plex.ts`, `src/telas/titulo.css` |
| 8. Ordenar e filtrar | Menu com quatro ordens e alternância “Só não vistos”, enviados aos adaptadores em todas as páginas. Escolha salva com try/catch por servidor, usuário e biblioteca. Mudança remonta a grade e reinicia o cursor; respostas antigas não alteram a grade ou sua contagem. `aria-busy` existente mantido. | `src/telas/Biblioteca.tsx`, `src/dados/ordem-biblioteca.ts`, `src/api/servidor.ts`, `src/api/jellyfin.ts`, `src/api/plex.ts`, `src/telas/biblioteca.css` |
| 9. Buscas recentes | Campo vazio mostra até oito buscas que resultaram em abertura de título. Repetir busca não registra outra entrada por si só. Botões de remover e limpar; chave `heisuca.buscas`; guarda somente textos, sem identificadores, contas, datas ou títulos abertos. Tolera armazenamento bloqueado e JSON inválido; deduplica sem distinguir maiúsculas. | `src/telas/Busca.tsx`, `src/dados/buscas-recentes.ts`, `src/telas/busca.css` |

## Testes

Base antes de editar: `node --test testes/*.test.ts` — **225 passaram, zero falhas**. Nenhum teste já falhava antes.

Testes novos:

- `testes/lacunas-player.test.ts`: cinco casos de PiP, velocidades, teclas/campos/volume, carregamento tardio da prévia e ações do fim do filme.
- `testes/lacunas-catalogo.test.ts`: cinco casos de recorte Trickplay, endpoints/capacidades de similares, trailer/compartilhamento, ordenação/filtro e armazenamento de recentes.
- `testes/lacunas-interacoes.test.ts`: oito casos executando os componentes reais em portas de memória, com eventos de mídia, teclado, ponteiro, clique, desmontagem e respostas pendentes. Verificam também os atalhos anteriores, última legenda, nova sessão ao repetir, recorte reduzido, limite de recomendações, botões de trailer/compartilhar e paginação de biblioteca com filtros.

Os dois primeiros arquivos foram executados antes da implementação e falharam pela ausência dos novos módulos. Os comportamentos cobertos não existiam na base.

Testes existentes atualizados para a ampliação do contrato: `testes/contrato.test.ts` (campos do item/capacidades), `testes/plex.test.ts` (capacidades), `testes/busca8.test.ts` (porta de armazenamento de recentes na bancada). As verificações anteriores foram preservadas.

Portão final, executado em `apps/web/`:

- `npx tsc -b`: sem erros.
- `npx vite build`: sem erros, com o alvo existente `chrome88` preservado.
- `node --test testes/*.test.ts`: **243 passaram, zero falhas**.
- `git diff --check`: sem erros.

Não foram introduzidas animações contínuas nem novas APIs/CSS proibidas. Os componentes visuais e ícones usam o sistema existente.

## Ambiente de compilação

As mudanças em `tsconfig.app.json`, `tsconfig.node.json` e `.gitignore` (cache em `.cache/`) foram desfeitas na revisão: eram um contorno do ambiente do worktree, fora do escopo. Nenhum pacote foi instalado ou modificado.

## Limites e pendências

Nenhum dos nove itens ficou de fora. Ainda falta homologação em navegador/aparelho real, especialmente PiP, legendas em reprodução, trailer e compartilhamento nativo. A bancada automatizada não substitui essa verificação. Não foram usados servidor, credenciais ou acervo reais.

## Como desfazer

Commit único no ramo `claude/heisuca-web-lacunas`: desfazer com `git revert <commit>`. Para desfazer as escolhas na interface, desativar o filtro/reselecionar A–Z e usar “Limpar” nas buscas recentes.
