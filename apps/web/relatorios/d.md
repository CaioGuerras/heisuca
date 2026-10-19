# Sessão D — Busca, menu do usuário e páginas (PLANO §8–§12)

Ramo `site-v2-d-paginas`, a partir do `site-v2`. `npx tsc -b` e `npm run build` sem erro. Bundle principal:
**60,35 KB gzip** (era 55,29 no `site-v2`; +5,1 KB). As páginas do menu carregam sob demanda (`Paginas-*.js`, 5,7 KB gzip).

## O que fiz

| Tela | Arquivos | Notas |
|---|---|---|
| **Busca** (§8) | `telas/Busca.tsx`, `busca.css` | ← Buscar; campo em pílula com 🔍 e ✕ (Esc também limpa). Busca a partir de 2 letras, 300 ms depois de parar de digitar (conferido: digitar "alien" gera um só lote de pedidos, nada para "al"/"ali"). Do acervo: pôster, título, `BR-14 • 2015 • 2h 28m • 6,6★`, sinopse em 3 linhas, `<servidor> • <biblioteca>`. "Disponível para pedir" só com `temSeerr(s)`: pôster pequeno, título, `2006 · Filme`, **+ Pedir** → `FolhaPedido` (série escolhe temporadas). O que já foi pedido/está baixando mostra o selo no lugar do botão; depois de pedir, o item vira "Pedido" na hora. Esqueleto enquanto carrega; "Nada encontrado para “x”"; erro em uma linha. |
| **Menu do usuário** (§9) | `comp/MenuUsuario.tsx`, `menu-usuario.css` | Balão que nasce da foto na ilha (já existia). Refino pela ref: cabeçalho com foto 52 px + nome + "Minha conta: foto e senha ›"; ícones na cor do tema; grupos com linha fina; sem setas nos itens. Ordem do PLANO: [Como usar · Meus pedidos] — [Tema · Baixar os apps · Sobre · (Como usar, quando completo)] — [Apoiar o Heisuca] — [Sair]. **Tema** abre dentro do próprio balão com três pílulas só com o nome (Roxo · Verde · Automático) e a tela muda na hora. |
| **Minha conta** (§10) | `telas/Paginas.tsx` (`Conta`) | Foto grande, nome, **Trocar foto** (pílula clara) e **Remover foto** (lixeira; só aparece se há foto). Trocar senha com o texto explicativo, três campos com o olho, **Salvar nova senha**. Senha atual pode ficar vazia. Erros sob o campo culpado (nova vazia, confirmação diferente, senha atual incorreta = 403); sucesso e falhas de rede com `avisar`. Depois de trocar/remover a foto, o tag novo vai para a sessão e a foto da ilha e do menu acompanha. Sem Quick Connect. |
| **Como usar** (§11) | `Paginas.tsx` (`ComoUsar`) | 5 passos (o 5º, Pedir, só com Seerr) com caixinha **Feito** guardada no aparelho (`heisuca.ajuda.feitos`); barra de progresso "2 de 5 feitos". Com todos marcados grava `heisuca.ajuda.completa=1` (e apaga se desmarcar) — conferido: o menu move "Como usar" para o fim. Depois: "Avisos no aparelho — Em breve" e Dúvidas (esqueci a senha → quem administra o servidor; como sair; como trocar as cores). Nada de CGFLIX, endereço, regras da casa, Stremio. |
| **Baixar os apps** (§12) | `Paginas.tsx` (`Apps`) + `comp/instalar.ts` | Cartão "Instalar o site como app — Disponível" com os passos por navegador (Chrome no Android, Safari no iPhone/iPad, Edge no Windows) em sanfona; a do aparelho atual já vem aberta. Se o navegador dispara `beforeinstallprompt`, aparece o botão **Instalar o Heisuca**; se já está instalado, aparece "Você já está usando o Heisuca como app". Android, Android TV, TVs Samsung e LG, iPhone e iPad: **Em breve**. Os mesmos passos de instalação aparecem no passo 4 do Como usar. |
| **Sobre** (§9) | `Paginas.tsx` (`Sobre`) | Logo (o `comp/Logo` da sessão A, só usado), "Nada entre você e o filme.", versão (`VERSAO` do cliente, 0.2.0), "Código aberto — GPL-3.0" com link do código, créditos (Preact, hls.js, JASSUB, blurhash, Material Symbols, Inter, Sora, com licença e para que servem), "Com a ajuda de Rosiel Victor · Locadora" e uma dedicatória curta sem nomes. |
| **Meus pedidos** | `Paginas.tsx` (`MeusPedidos`) | Só com Seerr (`meusPedidos`). Nome/pôster/ano vêm do `detalhe` de cada pedido, em paralelo. Selo: Aguardando aprovação · Pedido · Baixando · Em parte · Disponível · Recusado; quando disponível e com `jellyfinMediaId`, a linha abre o título. Vazio: "Você ainda não pediu nada" + Buscar e pedir. |
| **Apoiar o Heisuca** | `Paginas.tsx` (`Apoiar`) | "Em breve". |

## Comparações (`testes/comparacoes/d/`)
- `busca_celular.jpg` (Roxo, Verde × CGFLIX completo × VidHub), `busca_computador_{roxo,verde}.jpg`
- `menu_celular.jpg` (Roxo; Verde com o Tema aberto × ref), `menutema_computador_{roxo,verde}.jpg`
- `conta_celular.jpg`, `conta_computador_{roxo,verde}.jpg`
- `paginas_celular_{roxo,verde}.jpg` (Como usar, Apps, Sobre, Pedidos, Apoiar — sem print de referência; o PLANO cita páginas do site antigo que não estão no `falso-dados`), `{ajuda,apps,sobre,pedidos}_computador_{roxo,verde}.jpg`

Console sem erro nos 4 perfis (celular/computador × Roxo/Verde). Teclado: Esc limpa a busca e fecha o menu; Tab circula dentro do balão (da `Folha`); todos os controles são botões/inputs nativos com foco visível.

## O que difere das referências e por quê
- **Nota com vírgula** (`6,6★`), não `6.6★` como no print e no texto do PLANO §8: o resto do site (cartões, home) já usa vírgula. **[C]**
- **Duração só em filme.** Na série o servidor dá a duração média de um episódio, que no lugar do `2h 28m` engana; fica `BR-14 • 2015 • 8,1★`.
- **Ícone da origem**: a ref usa o logo do CGFLIX; usei o ícone genérico de servidor (`dns`), porque o servidor pode ser qualquer um.
- **Biblioteca da origem**: o Jellyfin não diz a biblioteca de um item (o `ParentId` é a pasta). A busca roda uma vez por biblioteca de vídeo (com `parentId`) e marca de onde veio; se o mesmo item aparecer em duas, fica a do tipo dele. **No servidor falso** o `parentId` é ignorado na busca, então as séries de "Séries" podem aparecer como "Animes" — no Jellyfin de verdade não acontece. Custa N pedidos por busca (N = bibliotecas; no CGSERVER, 3).
- **Fundo**: a ref é preto puro; aqui é o fundo do tema (Shikkoku/Hisui), como as outras telas.
- **Tamanhos**: os prints da ref são de um Android com fonte do sistema maior/densa; mantive o desenho (posição, proporção, ordem) e usei tamanhos confortáveis (campos de 52–54 px, texto do campo 16–17 px para o iPhone não dar zoom).
- **Menu**: no app completo "Apoie" vem depois de Sair; segui a ordem do PLANO §9 (Apoiar antes de Sair). As seções com título ("Ajustes e ajuda", "Conta") viraram só linhas finas, porque o menu enxugado ficou curto.
- **Computador**: Busca numa coluna de até 960 px, com os pedidos em duas colunas; páginas numa coluna de 640 px. Não há ref de computador.
- **Pôsteres do Seerr no falso**: o Seerr falso não manda `posterPath`, então aparecem caixas com ícone de filme/série no lugar. Com o Seerr de verdade vem o pôster.

## O que não ficou bom (honesto)
- **Busca no computador** fica com muito vazio à direita da lista do acervo (a sinopse vai até ~720 px). Funciona, mas não é bonito como no celular.
- **Meus pedidos** no falso mostra "Filme" como nome (o Seerr falso não dá título no detalhe). Com o Seerr real deve vir o nome; **não testei com o real**.
- **Como usar** fica longo no celular por causa dos passos de instalação dentro do passo 4 (fechados, exceto o do aparelho atual).
- **Troca de foto**: no falso o tag não muda, então não deu para ver a foto nova na hora; o código relê o usuário e grava o tag novo. Não limitei o tamanho da imagem além de 10 MB nem reduzo antes de enviar.
- O texto "Depois da troca, os outros aparelhos pedem para entrar de novo" é o do PLANO ("a conferir no teste"): o Jellyfin 10.9+ revoga os outros tokens na troca de senha, mas **não conferi** no CGSERVER.

## Dúvidas para o Caio
- **[C1]** Nota com vírgula (`6,6★`) ou ponto, como no app completo?
- **[C2]** Dedicatória: escrevi "Para a família, que sempre se reuniu diante da tela." como provisória. Qual é o texto da NOVA_FASE/BASE_MARCA (sem nomes)?
- **[C3]** Créditos: "Com a ajuda de Rosiel Victor · Locadora" — que papel escrever para cada um, se algum?
- **[C4]** Link do código: usei `https://github.com/caioguerras/heisuca`. O repositório vai ser público? Se não, tiro o link e deixo só "GPL-3.0".
- **[C5]** Como usar, passo 1 ("Entrar no site"): quem está vendo a página já entrou. Marco sozinho como feito ou deixo para a pessoa marcar (como está)?
- **[C6]** Na escolha do Tema, tirei a explicação do Automático ("segue o aparelho") para ficar só com os nomes; ela aparece só nas Dúvidas do Como usar. Ok?

## O que mexi fora dos meus arquivos
- `src/app.tsx`: as rotas `busca`, `conta`, `ajuda`, `apps`, `sobre`, `pedidos`, `apoiar` (troca das linhas `EmConstrucao`); um `atualizar` na `Casca` (grava a sessão e faz `setS` sem a transição) para a foto nova chegar à ilha; o carregador sob demanda `Paginas` no fim do arquivo; `import './comp/instalar'`.
- `src/comp/Folha.tsx`: o balão aberto **para cima** (âncora na metade de baixo da tela) agora é preso pela base (`bottom`) em vez do topo, para crescer para cima quando o conteúdo aumenta (o Tema abre dentro do menu). Para quem abre para baixo nada muda.
- `src/comp/Icone.tsx`: ícones novos no glob (android, mobile, desktop_windows, install_desktop, connected_tv, ios_share, more_vert, code, open_in_new, notifications).
- `src/api/jellyfin.ts`: `VERSAO` passou a ser exportada (o Sobre mostra a versão).
- Novo `src/comp/instalar.ts`: ouve o `beforeinstallprompt` desde a abertura (as páginas carregam depois e perderiam o aviso).
- `paginas.css` define `.pagina-corpo { max-width: 640px }` (era 760 em `pagina.css`); só carrega junto das páginas do menu.
