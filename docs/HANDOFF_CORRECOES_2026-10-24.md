# Heisuca Android — retorno após Claude 2.0.8 — 24/10/2026

## Claude retomou em 24/10 — estado atual: 2.0.10+11 (AGUARDA TESTE NO APARELHO)

O Codex/GPT parou com o código da rodada pronto e o **build reprovado** (3 runs com falha/cancelados; o último,
40043854184 em `afec0ac`: 349 testes ok, 1 falha). Claude, a partir de `2106db4`:

- **Build destravado (`6990283`):** a falha era do teste do buffer, que procurava o controle sem rolar a lista
  preguiçosa da aba Avançado. O controle estava certo. Biometria isolada em `@RequiresApi(28)` para o lint NewApi
  do release (minSdk 25). Run 40048315939 **verde** (2.0.9+10): o Kotlin novo compila e passa no lint.
- **Revisão das mudanças do GPT:** detecção de tablet (menor lado ≥ 600 dp) está certa e explica o "player com
  estilo antigo" (com tamanho de exibição menor, o Edge virava tablet e caía na régua antiga). Buffer mpv com teto
  (≤ 512 MB ou metade do heap), splash claro (mesmo selo, cor Hisui) e workflow: sem problemas.
- **Ficha lenta (`cd9a012`, 2.0.10+11):** medido no servidor: o Jellyfin responde a cadeia da ficha em 8–130 ms,
  mas pelo endereço público cada ida custa ~250 ms (conexão reaproveitada) e a ficha fazia 5 em fila ≈ 1,7 s de
  espera. Agora temporadas e episódios da temporada conhecida saem junto com o item; ancestrais e NextUp em
  paralelo; recarga ao voltar do player é silenciosa. Teste prova o paralelismo.
- **Apotecária lenta (servidor, sem mudança):** o episódio fica no gdrive10. O log do rclone mostra o arquivo
  removido do cache VFS com `maxAge=0` 4 min depois do play (cache de 10 GB cheio, despejo imediato): todo play a
  partir da nuvem começa a frio. Ajustar cache/tiering é mudança de armazenamento ([C], pede OK do Caio).
- **Imagens na 1ª abertura:** 1ª busca de cada imagem 0,35–0,95 s (o Jellyfin redimensiona); a VPS já guarda 30
  dias (proxy_cache). Proposta [C]: aquecer o cache da VPS com as imagens da Home dos perfis.
- **Parallax (pergunta do Caio):** faz sentido com moderação, só no topo (arte do destaque e da ficha rolando mais
  devagar), barato com Transform e desligado em "reduzir movimento". Nada de inclinação em cartões. Depois de validar
  o player e a fluidez no aparelho.
- **APK 2.0.10+11:** run https://github.com/CaioGuerras/heisuca/actions/runs/40049863934 (verde), artifact
  https://github.com/CaioGuerras/heisuca/actions/runs/40049863934/artifacts/12543147457 (expira 07/11/2026). ZIP sha256
  `f3c75ca4…7516` (= digest do Actions); APK 98.612.338 bytes, sha256 `5e846610…f9fc`; versionCode 2011; certificado
  `19160423…f95c` (atualiza por cima); permissões de biometria presentes. Conferido com androguard; sem teste físico.
- **Plex ao vivo:** o Caio adicionou o Plex dele e confirmou que funciona como o Jellyfin; não testado por automação.


## Ponto de partida e autorização

Caio pediu ao Codex para assumir as correções após testar as atualizações do Claude
até 2.0.8+9 (head 07cb49a). A Home havia sido aprovada preliminarmente; preservar sua
composição. A lista atual é o retorno sobre imagens, ficha, favoritos, biblioteca,
buffer, fontes, diagnóstico, conta, kids, biometria, splash e player. Não retomar como
se estivéssemos no antigo 2.0.3: Claude já corrigiu temporadas, rótulos, ficha e HUD.

Branch: `codex/heisuca-home-site`; PR #2 continua rascunho. Versão desta rodada:
**2.0.9+10**. Nenhum merge, release ou deploy do site autorizado/executado nesta rodada.
Credenciais fornecidas na conversa não devem ser copiadas para código, docs ou CI.

## Alterações e limites

- **Player antigo em celulares altos:** `PlatformDetector.isTablet` usava diagonal em
  pixels lógicos dividida por 160 como se fosse medida física. Um celular 412×960 era
  tablet e caía no HUD legado. Agora a menor dimensão ≥600 dp define tablet. Preserva
  o HUD 07A implementado por Claude, também em rotação; não substitui motores.
- **Ficha:** exibe metadados assim que `onItemReady` os entrega; mantém temporadas e
  episódios ao atualizar após reprodução; cache em memória de 12 fichas por instância
  do cliente autenticado, TTL de 2 minutos, com revalidação. Não compartilha cache entre
  clientes/perfis; não armazena URLs autenticadas em disco. Dados técnicos e relacionados
  ainda são consultados separadamente. Não foi medido ganho em milissegundos no aparelho.
- **Elenco:** atores com ID válido abrem `ActorMediaScreen`, com servidor e backend de
  origem; consultas da filmografia respeitam `navigationOnlineClients`. Sem ID não há
  promessa de filmografia. API e permissões do servidor continuam determinantes.
- **Favoritos Jellyfin/Emby:** filtros Todos/Filmes/Séries/Animes. Consulta paginada por
  biblioteca preserva seu nome para classificar animes, além do gênero explícito Anime.
  Não trata toda animação como anime. Plex continua sem o coração de favorito Jellyfin;
  não foi inventada equivalência com a watchlist do Plex.
- **Biblioteca mobile online:** substitui o protótipo/rota antiga por grade de pôsteres
  com categorias, seletor da biblioteca, busca no servidor, ordenação e páginas de 60.
  Fonte ativa delimita as consultas; respostas antigas são descartadas por geração.
  Respeita bibliotecas ocultas. Todos significa todas as categorias da fonte, e o
  seletor determina qual biblioteca ocupa a grade; não agrega servidores silenciosamente.
  Downloads continuam na rota offline existente. Desktop/TV mantêm rota original.
- **Logo Heisuca:** abre o seletor real de fonte. Logo do título ainda abre a ficha.
  Troca de fonte permanece bloqueada dentro do perfil kids.
- **Buffer:** controle disponível para mpv e ExoPlayer. Exo conserva sua política
  existente; mpv recebe preferência antes de abrir mídia e limita o cache pelo heap.
  Automático não sobrescreve a configuração própria do mpv. Pressão de memória pode
  reduzir o limite. Grande e Extra grande podem coincidir quando atingem o teto seguro.
  Alteração vale na próxima reprodução; não promete que buffer maior acelera o início.
- **Aparelho:** diálogo mostra renderizador informado, Hz atual/máximo, efeitos efetivos,
  redução de movimento, pressão de memória, cache e motor selecionado. Hardware decoding
  é apresentado como solicitado, não confirmado. HDR/DV dependem da mídia e do decoder.
- **Conta:** acesso visível à tela existente de foto/senha da conta Jellyfin/Emby da fonte
  selecionada. Não modifica senha da conta Plex nem executou troca de senha real.
- **Kids:** nome obrigatório e foto opcional na criação; tela de editar nome/foto no menu
  do responsável; arquivo copiado para armazenamento privado do app. Nome alimenta a
  animação. Cobertura padrão reduzida para 1,84s; movimento reduzido, 0,6s. A cobertura
  permanece enquanto a sessão troca, evitando um intervalo vazio. Serviço kids remoto
  e criação do usuário ainda dependem da rede. Persistência já havia sido confirmada
  por Caio no 2.0.8; isso não é uma nova validação física do 2.0.9.
- **PIN:** campo invisível que recebe o teclado tem todas as bordas desativadas,
  evitando herdar a linha vermelha do tema. PIN do responsável continua válido.
- **Biometria:** canal nativo `app.heisuca/security` com BiometricPrompt; nenhuma digital
  chega ao Dart. Bloqueio opcional do app ao abrir/voltar do segundo plano; Android 10+
  com credencial do dispositivo como alternativa. Saída kids opcional por biometria
  com fallback para PIN. Aviso: todas as biometrias cadastradas devem pertencer aos
  responsáveis. Não identifica qual pessoa cadastrou cada digital. Ainda requer teste
  físico de cancelamento, credencial e ciclo de vida.
- **Splash claro:** fundo e selo do tema claro corrigidos; tema escuro preservado.
  Android 12+ usa drawable próprio claro. Não foi observado o cold start físico.
- **Imagens:** pré-carrega apenas o próximo banner na mesma resolução/cache do widget.
  Não baixa o acervo inteiro e não garante eliminar o tempo da primeira requisição.
- **Parallax:** não foi acrescentado. Primeiro validar fluidez, rede e player corrigido;
  efeitos novos só se respeitarem reduzir movimento e política de desempenho.

## Validação — atualizar ao encerrar a rodada

Status de compilação e resultados finais ainda em verificação. Não distribuir esta
versão como aprovada antes de registrar o workflow concluído e a assinatura do APK.
A primeira execução detectou API antiga do FilePicker; a chamada foi corrigida para a
API estática da versão 11 usada neste projeto. O portão continua obrigatório.

Testes adicionados: classificação de telefone/tablet nas duas orientações, categorias
reais de favoritos, biblioteca usando somente a fonte selecionada e pesquisa remota,
biometria cancelada/sucesso/segundo plano com canal simulado e bordas do PIN. Teste de
cache da ficha cobre reabertura lenta e separação entre clientes autenticados.
A suíte também inclui filmografia, detalhes Plex e isolamento de favoritos Jellyfin.
Simulação de canal biométrico não equivale a teste do sensor Android.

## Pontos que exigem aparelho/servidor

Não há dispositivo Android conectado neste ambiente. Testar no APK: HUD em portrait/
landscape, HDR/DV, ASS com estilos, PiP, rotação, retomada, biometria e splash após
encerrar o processo. Comparar tempo até primeiro frame do episódio de Apotecária com
mesmo arquivo, rede e motor; não atribuir lentidão a buffer sem medir.

Plex Web abriu sem sessão autenticada. O navegador exige autenticação pelo fluxo seguro;
a senha escrita no chat não foi inserida por automação. Não confundir testes unitários
Plex com teste ao vivo das bibliotecas da conta. Teste real ainda não confirmado.

## Continuidade / ai-memory

Leia este documento antes dos handoffs antigos; preserve as correções do Claude e a
Home aprovada. `docs/importar-ai-memory.sh` deve ser executado no host que já possui
ai-memory, com workspace/projeto existentes. O script grava e confere por leitura.
O ai-memory não está conectado aqui: commit de documentação NÃO significa importação.
