# M: PiP/áudio — diagnóstico para revisão do Claude

Investigação adicional encerrada por decisão do Caio, sem aprovação integral.
Ele confere PiP no aparelho. Seguir N → O; não repetir bancada para investigar M
sem novo pedido. Não ignorar exceções nem chamar este defeito de infraestrutura.

## Estado reproduzido

- Código `0e3d77320ca4d02fbfb8525f9e373ead70dcd68c`, APK **2.0.31+32**.
- [APK verde](https://github.com/CaioGuerras/heisuca/actions/runs/40368590970),
  [bancada vermelha](https://github.com/CaioGuerras/heisuca/actions/runs/40368590994),
  [leitura do artifact](https://github.com/CaioGuerras/heisuca/actions/runs/40371170100).
- 20 marcos executados, flags PiP/FGS/MediaSession/áudio após fechar PiP verdadeiras.
  Back único chega ao app e retorna à ficha; restauração dos dados confirmada.
  Diagnóstico nativo disponível: **anrDoApp=false**. Não é o antigo foco no launcher.
- **Seis RenderFlex overflows** em janela pequena: cabeçalho (147 px e outra
  ocorrência), transporte (7,2 px e outra ocorrência), coluna (212 px, repetido).
  Dimensão registrada: **240,8 × 108,2 dp**. Referências:
  `video_controls_header.dart:59`, `mobile_video_controls.dart:387` e `:237`.
- **21-imagem-apos-audio.png preta; 06-player.png preta com spinner**.
  Inspeção visual feita, não apenas leitura das flags.
- Sem prova física. Não está demonstrado que a imagem preta seja exclusiva do
  emulador. Faixa selecionada/posição avançando não comprovam vídeo restaurado.

## O que foi tentado e o limite da prova

`PlexVideoControls` já retirava o HUD quando `isPipActive` ficava verdadeiro.
Em `0e3d773`, foi acrescentado estado separado de transição: aviso nativo
`onPictureInPictureUiStateChanged/isTransitioningToPip` (API 35), aviso em
`onUserLeaveHint`, entrada manual antecipada e limpeza em saída/cancelamento.
Não houve mudança em mpv, filtros, Surface, navegação, foco ou prazos.

O teste isolado passou, mas a bancada continuou com os seis erros. Portanto,
**antecipar esse aviso não resolveu a integração**. Não temos registro que
estabeleça a ordem real entre cada callback e a alteração das métricas.

Há uma lacuna concreta no teste `heisuca_pip_transition_test.dart`: ele anuncia
entrada **antes** de diminuir a janela; ao sair, **aumenta** a janela antes de
desligar `isPipActive`. Assim, não reproduz a ordem inversa possível na integração
(métrica pequena antes do aviso de entrada, ou modo inativo antes da expansão).
Investigar essa ordem é uma hipótese de trabalho, não causa comprovada. Não
foram adicionados recortes, redução artificial de botões ou exceções por tamanho.

## Imagem: evidência separada do layout

A coleta anterior `40359810049` tinha imagem antes do áudio. Depois: vid=1,
pause=no, current-vo=gpu, hwdec-current=mediacodec, entrada 1920×1080, saída
sem dimensões, vo-configured=no. Screenshot decodificado do mpv indisponível.
Logs mostram criação/troca de Surface, placeholder e reinicialização do VO GPU;
isso **não demonstra qual operação perdeu o quadro**. GPU funcionava antes,
portanto não foi justificado desativar shaders nem atribuir a falha ao emulador.

Preservar as correções K (`cc5c6ad`, `479b129`, `7d1e1bf`) e o retorno aprovado
em `e02fcd5`. Dados completos, hashes e limites estão no final da seção M de
`HANDOFF_GPT_ENTREGA_2026-10-24.md`. A N não corrige nem oculta esta pendência.
