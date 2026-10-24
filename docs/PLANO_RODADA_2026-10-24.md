# Plano da rodada: pedidos do Caio de 24/10/2026

Feito nesta rodada (APK 2.0.13+14, ramo `codex/heisuca-home-site`): pílula só com ícones, com Baixados no lugar de
Favoritos (no modo infantil continua Favoritos); botão Favoritos na Biblioteca; menu Você por assunto (Conta · Família ·
Privacidade e segurança · App · Sair); Assistir juntos no relay próprio (2.0.12). Nada foi testado em aparelho.

Ordem proposta para o que falta: uma etapa por sessão, cada uma com APK de teste e comparação lado a lado com os players
de referência (regra de 19/10).

## 1. Ficha da pessoa: filmografia completa (Sadie Sink)
- **Fato:** Stranger Things **não está no acervo** (nem no Jellyfin, nem no pool, nem no Sonarr). O app mostra só o que o
  Jellyfin liga à pessoa, então mostrou apenas o filme. Não é bug de consulta.
- **Proposta:** duas partes na ficha. **No acervo** (como hoje) e **Também atuou em**, com a filmografia do TMDB via Seerr
  (`/api/v1/person/{tmdbId}/combined_credits`; o app já tem cliente do Seerr). Cada título fora do acervo ganha o
  botão **Pedir**, igual à busca. No modo infantil, só "No acervo".
- O id TMDB da pessoa vem do Jellyfin (`ProviderIds.Tmdb` do Person).

## 2. Player: episódios no título
- Hoje: o título no canto superior esquerdo é texto; existe botão de próximo e os ajustes ficam no meio.
- **Proposta:**
  - **Topo esquerdo:** o **logo** da série (imagem `Logo` do Jellyfin, como no site), com o texto como reserva quando não houver
    logo. Embaixo, pequeno: "T5 · E16 · nome do episódio". **Tocar no logo abre o seletor de episódios da SÉRIE**: temporadas
    em abas, lista com miniatura, progresso e duração, com rolagem já no episódio atual.
  - **Sai o botão Próximo.** O cartão "Próximo episódio" perto do fim e a opção "Próximo episódio sozinho" continuam.
  - **Ajustes alinhados à direita:** legendas/áudio, velocidade e ajustes, num grupo só.
- Arquivo: `lib/heisuca/player/heisuca_player_hud.dart`. `lib/heisuca/heisuca_player_screen.dart` parece não ter uso (conferir
  e mover para `Arquivos_Obsoletos` do repo, se confirmado).

## 3. Transmitir para a TV
O servidor não converte vídeo, e isso decide o desenho:
- **Fase 1, "Tocar na TV" (recomendada):** usa o controle remoto de sessões do Jellyfin. O celular manda a TV (com Heisuca,
  Jellyfin ou Moonfin aberto) tocar o título, e vira controle remoto (play, pausa, legenda, posição). A TV toca o arquivo
  original, então funciona com MKV, ASS e HEVC. O app herdou um "Controle remoto" do Plezy; ver o que dá para reaproveitar.
- **Fase 2, Chromecast/Google TV:** só para arquivos que o Cast toca direto (MP4/H.264/AAC). MKV e legenda ASS não tocam
  sem conversão. O app avisa antes, em vez de falhar.
- **DLNA (TVs Samsung/LG sem app):** depois, se fizer falta.
- **[C]** Caio: começar pela Fase 1?

## 4. Medidor do aparelho
Base existente: `services/device_performance.dart` (níveis completo/reduzido, por RAM, 32 bits e o sinal de pouca memória).
- **Tela em Você › App › "Este aparelho":** um medidor de 3 faixas.
  - **Verde, "No máximo":** tudo ligado.
  - **Âmbar, "Com ajustes":** lista o que foi cortado e por quê (desfoque, parallax, pré-carregamento, decodificação por
    software no HEVC 10 bits…).
  - **Vermelho, "No limite":** "Este aparelho roda melhor o Heisuca Lite" (quando o Lite existir; até lá, só o aviso).
- Sinais extras para a faixa vermelha: decodificação de vídeo sem suporte de hardware (o mpv informa), quadros perdidos
  medidos nos primeiros plays, pouca RAM com processo de 32 bits.

## 5. Refinos visuais
- **Parallax** (o que o Caio pediu antes): no destaque da Início e na capa da ficha, com o fundo andando mais devagar que o
  conteúdo. Desligado na faixa "Com ajustes".
- **Transições de tela:** pôster → ficha com elemento compartilhado (Hero, a capa "voa" para a ficha); entre abas, fade-through;
  sheets com mola. Uma curva e uma duração únicas para o app todo, para não parecer remendado.
- **Ícone do app:** hoje o selo 炳 sobre a cor da superfície some entre os outros ícones. Estudar com o Caio, lado a lado na tela
  inicial do Android: selo com relevo/gradiente sutil, fundo com textura de laca, versão "temática" monocromática do
  Android 13. Mostrar 3 variantes renderizadas antes de trocar.

## 6. Trackers MAL/AniList
- O login usa o relay do Plezy (`/auth`). **Recomendação:** esconder MAL/AniList (ninguém usa; o Trakt já cobre o histórico).
  **[C]** Caio.

## Pendências técnicas
- **16 testes já falhavam antes desta rodada** (navegação no topo em paisagem, abas do celular etc.; lista no fim da sessão de
  24/10). Corrigir ou atualizar numa etapa própria antes de crescer o app.
