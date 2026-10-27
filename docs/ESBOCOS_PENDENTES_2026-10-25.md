# Esboços ainda não feitos — 25/10/2026

Fonte: dossiê de 21/10 (`docs/dossie_2026-10-21/`) e a análise de 23/10 (`PROXIMA_ETAPA_TITULO_FONTES_AJUSTES_2026-10-23.md`).
Conferido contra o código em 25/10 pelo Claude. Os esboços 01 a 08 (abertura, login, Início e pílula, ficha e menu de
toque longo, biblioteca e busca, configurações, player, mola e reconhecimento do aparelho) estão no app, com os ajustes
dos retornos. Falta o **esboço 04C** inteiro e duas pendências da auditoria Google.

## Esboço 04C — mídia fora do app (imagem `05_biblioteca_filtros_busca_unificada.png`, nome antigo errado)
O esboço mostra 4 peças. Como fazer do jeito do Android (sem imitar o iPhone):

| Peça do esboço | Jeito certo no Android | Situação hoje |
|---|---|---|
| "Ilha dinâmica" no furo da câmera (cápsula com o que toca e com download) | **Não há jeito certo no Android.** Não existe API para desenhar em volta da câmera, e o Live Updates do Android 16 (chip na barra de status) é proibido para mídia e para download (verificado em 25/10, ver `GUIA_ANDROID_GOOGLE.md`). O equivalente oficial são os **controles de mídia do sistema** (painel e tela de bloqueio) e a notificação comum de progresso do download | **não fazer a ilha** |
| Mini player na notificação (barra com busca, −10/+10 s, saída de som) | **MediaSession + notificação MediaStyle** com serviço em primeiro plano (`mediaPlayback`) | só a música usa; o **vídeo pausa** ao sair do app (`setBackgroundMode(true)` só na música; auditoria 1D) |
| Tela de bloqueio com controles | Vem da mesma MediaSession | não existe para vídeo |
| PiP 16:9 com legendas ASS/SRT, entrada automática, virar só som ao fechar | PiP já entra sozinho; falta `setSourceRectHint` (transição suave), `setSeamlessResizeEnabled(false)`, legendas estilizadas dentro da janelinha e, ao fechar a janelinha com "continuar ouvindo" ligado, seguir só com o som e a notificação | parcial |
| Notificação de download agrupada e silenciosa | Notificação de progresso agrupada, sem som, com pausar/cancelar (sem Live Update: não permitido para download) | conferir |
| Tudo no tema claro Hisui | Cores da notificação seguem o tema do app | — |

**Decisão do Caio (25/10):** opção **"Continuar ouvindo ao sair", desligada por padrão**; o padrão ao sair é a janelinha
(PiP). Ligada, o vídeo segue só com o som, com serviço em primeiro plano `mediaPlayback` (exigido pelo Android 17 para
qualquer áudio fora da tela), controles no painel e na tela de bloqueio.

## Pendências da auditoria Google (`apps/app/docs/cgflix/AUDITORIA_GOOGLE_1D.md`)
- **Voltar preditivo:** foi feito na 1.6.1 (CGFLIX), a tela acompanhava o dedo. O movimento novo do item 4 (2.0.17) deve
  ter passado por cima: as telas voltaram a deslizar de um lado só (vídeo do Caio, 25/10). Restaurar ao fazer a etapa F.
- Outros itens "parcial/pendente" da auditoria entram na varredura contra `docs/GUIA_ANDROID_GOOGLE.md`.
