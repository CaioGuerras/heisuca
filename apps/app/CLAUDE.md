# Heisuca — fork independente (GPL-3.0)

Base: [Plezy](https://github.com/edde746/plezy) (Flutter, GPL-3.0; cliente de **Plex e Jellyfin**, player mpv, Android/iOS/
Windows/macOS/Linux). Este é o app "completo" do CGFLIX. Irmão leve: `CaioGuerras/cgflix-lite` (fork do Findroid).
Plano do Caio (resumo): Android primeiro; iPhone fica para depois; PC (Windows) virá deste mesmo código.


## Origem técnica — auditoria de 26/10/2026

O snapshot inicial `612b0a6` tem **Plezy 2.22.0** como tag mais próxima entre
34 tags comparadas até 2.24.0; não é uma cópia idêntica. O fork continua
independente. Matriz, diferenças reais dos contratos e ports da O ainda não
entregues: `../../docs/DIAGNOSTICO_O_COMPATIBILIDADE_2026-10-26.md`.
Não confundir a versão 2.0.x do Heisuca com a do upstream. Preservar os contratos
próprios de mídia/banco e o JNI renomeado; o diagnóstico não autoriza trocar o
app inteiro pela árvore de uma tag do Plezy.

## Independência — etapa L (26/10/2026)
- Pacote Dart: `heisuca`. Namespace Android e canais próprios: `app.heisuca`.
  JNI, regras R8 e testes nativos acompanham a mudança. **Não alterar os applicationIds**:
  `app.heisuca.player.teste.home` (avaliação) e `app.heisuca.player.teste`.
  Certificado e atualização sobre a instalação anterior são preservados.
- Sentry removido: sem SDK, DSN, inicialização, hooks ou upload de símbolos.
  Diagnósticos ficam nos registros locais, compartilhados por ação do usuário.
  Não introduzir telemetria ou destinos do Plezy. O validador inspeciona o APK.
- Licenças contém a GPL-3.0 completa e o aviso obrigatório da origem Plezy;
  marca e traduções do produto são Heisuca. Textos do Discord foram retirados.
- Chaves históricas de preferências/cache e `DisplayPreferences.client`
  permanecem para conservar dados ao atualizar; não são marca nem destinos de rede.
  IDs Apple permanecem; esta etapa valida Android.
- Atualizador não usa mais feed/repositório do Plezy; feed nativo só mediante
  configuração própria explícita. Não publicar releases automaticamente.

## Contexto (leia antes de tudo)
- **CGFLIX** é um servidor de mídia particular de família e amigos no Brasil (Jellyfin principal; Plex também). Endereço público
  sugerido do Jellyfin: `https://netflix.docaio.com.br`. Público: brasileiros, pouco técnicos, celulares de todo tipo e TV box.
- O dono é o **Caio**. Comente código novo e escreva commits, PRs e docs em **português do Brasil**.
- O servidor **não transcodifica vídeo** (`EnableVideoPlaybackTranscoding=false` nos usuários): o app tem de tocar direto
  (direct play). Anime tem legenda **ASS** com estilo (precisa de libass/mpv). Preferência de áudio e legenda: `por`.
  Legendas externas nossas: `<vídeo>.por.srt`.
- Login: usuário + senha do Jellyfin, ou **Quick Connect** (ligado no servidor). Usuários ficam ocultos na tela de login.
- Limite de **2 telas** por pessoa (plugin StreamLimiter): quando estoura, o servidor recusa o play; mostrar mensagem clara em PT.

## Regras do fork
1. **Fork independente (Caio, 25/10/2026):** não seguimos mais o upstream do Plezy. O código herdado é nosso e pode ser
   reorganizado, renomeado e reescrito para ficar certo (sem remendos). Estudar o Plezy e outros apps continua permitido.
   A licença GPL-3.0 e o aviso de direitos autorais do Plezy ficam (obrigação legal), numa página padrão de licenças.
   Leia `docs/PILARES_HEISUCA.md` antes de qualquer tela.
2. **Sem servidor embutido nem pré-preenchido** (decisão da Etapa 1A, por segurança): o campo do Jellyfin começa vazio, com a dica neutra `https://seu.servidor.com`.
3. Sem segredos, tokens, chaves ou telemetria no código, nos logs e nos workflows.
4. Licença GPL-3.0 e aviso de direitos autorais do Plezy numa página padrão de licenças (obrigação legal). A marca do app
   é **Heisuca** (selo 炳, `docs/marca/`); nada do nome/logo do Plezy nem do "C com play" do CGFLIX antigo.
5. Identidade visual: temas e regras em `docs/PILARES_HEISUCA.md` e `docs/marca/` (Shikkoku/Fukamurasaki padrão, Hisui,
   Ichigo, Sorairo, Shinju); Sora para títulos, Inter para texto; a marca HEISUCA é SVG.
6. Ramo único `codex/heisuca-home-site`, push direto (sem PR, sem ramo novo, sem merge no `main`); regras em `AGENTS.md`.

## Histórico — Etapa 0 (já concluída; NÃO executar): APK do CGFLIX compilando sozinho
1. Ler o projeto (README, `pubspec.yaml`, `android/`, workflows existentes) e entender como o upstream gera o APK.
2. Marca: nome exibido "CGFLIX", `applicationId` Android `br.com.docaio.cgflix` (sem conflitar com o Plezy instalado),
   ícone a partir de `cgflix-brand/cgflix-icone-512.png`/`cgflix-icone.svg` (adaptive icon), splash com fundo `#07060a`.
3. Tela de entrada: servidor Jellyfin com campo vazio (nada pré-preenchido, desde a Etapa 1A); Plex continua
   disponível como no original. Idioma padrão PT-BR quando o app tiver tradução (não quebrar os outros idiomas).
4. **GitHub Actions** `.github/workflows/cgflix-android.yml`: a cada push no `main` e em PRs, gerar o APK de release (assinado
   com chave de debug por enquanto; deixar pronto para receber um keystore por secrets depois) e publicar como artifact; em tags
   `v*`, anexar o APK a uma Release. Desligar/neutralizar workflows do upstream que dependam de segredos que não temos.
5. Rodar o build localmente no contêiner se for viável (Flutter/Android SDK); se não, garantir que o workflow está correto.
6. `CGFLIX.md` na raiz: o que foi mudado em relação ao upstream (lista de arquivos), como sincronizar com o upstream, próximos
   passos sugeridos (selos Dublado/Legendado, Pedidos/Seerr por Quick Connect, aviso das 2 telas, atualização pelo nosso servidor).
7. PR para o `main` deste fork com tudo isso.
Pronto quando: PR aberto, workflow verde (ou erro explicado no PR), APK como artifact.


## Mídia fora do app — etapa M (implementação, 26/10)

- Opção `continueListening` desligada por padrão, só Android de mão; carro e TV
  mantêm suas restrições. Sem Live Updates, ilha ou notificações promovidas.
- Vídeo usa a MediaSession e o serviço `mediaPlayback` já existentes. Consulta
  serviço foreground real; sem serviço aceito, pausa. mpv/Exo mantêm a fonte e
  a posição, desativam só a faixa de vídeo fora da tela e a restauram no retorno.
- PiP usa sourceRectHint, guarda a origem fora do PiP e seamlessResize=false.
  Referência: https://developer.android.com/develop/ui/views/picture-in-picture
  Fechar PiP e remover a tarefa dos Recentes são ações distintas no Android.
- Downloader local em `packages/background_downloader`: base `5d45882`, BSD-3-Clause,
  copyright/licença preservados e alterações em HEISUCA.md. As correções prévias
  de VPN/SAF continuam. Não trocar essa dependência por uma versão remota sem
  preservar as ações da notificação e a contagem correta de tarefas pausadas.
- A bancada testa Home/PiP, áudio com FGS real, transporte MediaSession e botão
  nativo de fechar PiP. Ausência de prova ou ANR mantém vermelho; não há Back extra.
  Estado de validação e limites ficam em HANDOFF_GPT_ENTREGA, não nesta descrição.
