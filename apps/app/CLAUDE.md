# CGFLIX (app completo) — fork do Plezy

Base: [Plezy](https://github.com/edde746/plezy) (Flutter, GPL-3.0; cliente de **Plex e Jellyfin**, player mpv, Android/iOS/
Windows/macOS/Linux). Este é o app "completo" do CGFLIX. Irmão leve: `CaioGuerras/cgflix-lite` (fork do Findroid).
Plano do Caio (resumo): Android primeiro; iPhone fica para depois; PC (Windows) virá deste mesmo código.


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
1. **Diferença mínima do original** (para puxar as atualizações do upstream toda semana sem conflito): marca, endereço sugerido
   e padrões em arquivos próprios/isolados; não reformatar nem renomear o que não precisa.
2. **Sem servidor embutido nem pré-preenchido** (decisão da Etapa 1A, por segurança): o campo do Jellyfin começa vazio, com a dica neutra `https://seu.servidor.com`.
3. Sem segredos, tokens, chaves ou telemetria no código, nos logs e nos workflows.
4. Manter a licença e os créditos do projeto original (tela "Sobre" + README). Nome e logo do app passam a ser **CGFLIX**;
   não usar o nome/logo do upstream como marca do app.
5. Identidade visual: preto OLED `#07060a`, superfícies `#120e1a`, roxo `#9333ea` (destaque `#a855f7`, lilás `#c084fc`),
   fonte Inter. Marca em `cgflix-brand/` (emblema "C com play", ícone quadrado, marca horizontal, PNG 512).
6. Trabalhe num ramo e abra **Pull Request para o `main` deste repositório** (nunca para o upstream), com descrição em PT-BR:
   o que mudou, como testar, riscos. Não faça merge sozinho.

## Etapa 0 (esta sessão): APK do CGFLIX compilando sozinho
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
