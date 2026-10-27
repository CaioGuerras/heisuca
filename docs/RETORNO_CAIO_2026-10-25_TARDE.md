# Retorno do Caio — 25/10 (tarde), enquanto o Codex rodava C–M

Diagnóstico do Claude no código do ramo `codex/heisuca-home-site` (commit `1866854`). Entra como etapa N, depois da M.

## N1. Login: indicador de servidor falso e com marca do CGSERVER
- **Sintoma (print do Caio):** com uma letra no campo Servidor, aparece "● CGSERVER · Jellyfin pronto para autenticar".
- **Causa:** `apps/app/lib/heisuca/heisuca_login_screen.dart` ~l. 440–452 (de `c7d45b6`, 22/10) só confere se o campo não está
  vazio. Não consulta servidor nenhum, e o nome CGSERVER está fixo no texto. O produto é o player; o CGSERVER é só um servidor
  entre outros (amigos e família) e não pode aparecer na tela de entrada.
- **Correção na causa:** usar a sondagem que o app já tem (`services/jellyfin_endpoint_discovery.dart`, `/System/Info/Public`;
  a mesma de `screens/settings/add_jellyfin_screen.dart`), com espera depois da digitação e cancelamento a cada tecla.
  O estado mostra o que o servidor responde: procurando / "Jellyfin <versão> · <ServerName>" / endereço sem servidor ou erro.
  Campo vazio = nenhum indicador. Nenhum nome de servidor fixo no app.
- O ponto colorido e o "●" do texto se repetem: deixar só o ponto desenhado.
- Teste de widget: uma letra digitada não pode mostrar "pronto"; o servidor falso responde → mostra o nome dele.
- Ajustar também `scripts/render_revalidacao_login.py` e `scripts/deploy_heisuca_artifact.py` (repetem o texto antigo).

## N2. Login: "+" em dobro em "Outros servidores e pastas locais"
- **Causa:** mesmo arquivo, ~l. 615–618: `TextButton.icon` com `Icons.add_circle_outline_rounded` **e** o texto começando por
  `'+ '`. Tirar o `+` do texto.

## N3. "Este aparelho" diz "No máximo" no Tab A9 (aparelho básico de referência)
- **O que o código faz** (`services/device_performance.dart`, herdado do original): 3 níveis por RAM.
  - Reduzido: 32 bits, aviso de pouca RAM do Android ou até ~2,2 GiB.
  - Completo: o meio (Tab A9 = 3,6 GiB, aqui). Cache de imagens 100 MiB / 800 itens; 6 downloads de arte ao mesmo tempo.
  - Topo (≥ ~6,6 GiB, aparelhos de 8 GB ou mais): 250 MiB / 1500 itens; 12 downloads de arte.
- A tela `heisuca/heisuca_device_screen.dart` (`heisucaDeviceTier`) junta Completo e Topo em "No máximo". Por isso o Tab A9
  aparece igual a um topo de linha. **Não é que o app esteja tão leve:** a tela não distingue os dois níveis e não mede nada
  do desempenho real.
- **Nada de recurso fica preso aos topo de linha.** Animações, desfoques e efeitos são iguais em Completo e Topo; muda só o
  cache de imagens e o paralelismo de download (rolagem mais lisa em listas longas). O player (mpv, decodificação por
  hardware) não depende do nível.
- RAM não mede GPU/CPU. O Tab A9 (Helio G99, 60 Hz) pode ter 4 GB e mesmo assim engasgar com desfoque. A regra hoje não
  vê isso.
- **Decidido (Caio, 25/10):** o medidor mostra os 3 níveis reais: "Reduzido", "Padrão", "Topo de linha"; o Tab A9 aparece
  em "Padrão", com o motivo (RAM ~3,6 GiB). Junta com a etapa H: o medidor vai para o popup "Funções e desempenho" e a tela
  "Este aparelho" sai.
- **Decidido (Caio, 25/10): "Medir fluidez" no popup "Funções e desempenho".** O `dumpsys gfxinfo` (Medidor/Shizuku) só
  conta os quadros da interface nativa do Android; o Flutter desenha no próprio Surface, então ali a medida sai vazia ou
  enganosa. O app grava os próprios tempos de quadro (`SchedulerBinding.addTimingsCallback`: construção, rasterização e total)
  por ~20 s enquanto a pessoa usa o app, e mostra em texto simples: fluidez boa/média/ruim, p50/p90/p99 e % de quadros acima
  do limite da tela (16,7 ms a 60 Hz; usar a taxa real da tela), com o detalhe técnico recolhido. Sem coleta enviada para
  fora do aparelho. Teste de widget com tempos falsos.
- **Depois da medição no Tab A9:** se passar do limite com efeitos completos, o critério de nível passa a usar o tempo de
  quadro medido (e não só a RAM). Decisão de regra fica para depois do número real.
