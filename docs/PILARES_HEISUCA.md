# Pilares do Heisuca — leia antes de mexer em qualquer tela

Escrito em 25/10/2026, a partir das decisões do Caio (marca 18/10, site 19/10, retornos de 22 a 25/10). Vale para
qualquer agente (Claude, Codex, Gemini). Se uma tarefa entra em conflito com isto, pare e pergunte.

## 1. O que é
- **"Nada entre você e o filme."** O app some e o conteúdo aparece. Menos botões, menos texto, menos moldura.
- Uma **suíte própria, elegante, que não parece com nenhum outro app**: direção japonesa, minimalista e refinada, no nível
  das marcas de luxo e da Apple. A referência visual mais próxima é o **VidHub**; o Plezy é só a base técnica herdada.
- Público: família e amigos no Brasil, pouco técnicos. Português do Brasil simples, sem jargão.

## 1.1 Como trabalhamos (Caio, 25/10)
- **Sem remendos.** Problema se corrige na causa, do jeito certo, mesmo que dê mais trabalho. Nada de contorno, condição
  especial para esconder sintoma ou "por enquanto" que fica para sempre.
- **Seguir o que o Google ensina para apps Android** (developer.android.com, Material 3, qualidade de apps, voltar
  preditivo, edge-to-edge, acessibilidade, desempenho), **adaptado ao estilo Heisuca**. Resumo em
  `docs/GUIA_ANDROID_GOOGLE.md`. Divergir do Google só com motivo escrito.
- **Estudar outros apps é bem-vindo** (Plezy, VidHub, Infuse, Netflix, os players de referência): ver como resolvem e
  aprender. Copiar código de fora só com licença compatível e registro.
- **Fork independente:** não seguimos mais o upstream do Plezy; o código herdado vira nosso e evolui do nosso jeito.

## 2. Visual
- **Uma linguagem só em todas as telas.** Nenhuma tela pode parecer "padrão do Android/Material" ou "herdada": listas
  genéricas com ícone cinza à esquerda, cartões com borda de sistema, AppBar crua, diálogos de sistema. Use os
  componentes Heisuca (`heisuca_design_system.dart`, `heisuca_theme.dart`).
- **Tipografia:** Sora para títulos e marca (precisa estar declarada no `pubspec.yaml`), Inter para texto. A marca
  HEISUCA é o **SVG** `assets/heisuca/marca_site_*.svg`, nunca texto digitado (o texto muda de peso conforme o aparelho).
- **Ícones:** traço fino e consistente. Nada de ícone genérico de sistema onde há um conceito nosso (servidor, fonte,
  perfil). Ícone decorativo ao lado de rótulo só quando todos os vizinhos também têm (ex.: não pôr coração só em
  "Favoritos").
- **Cor:** a do tema (Shikkoku/Fukamurasaki, Hisui, Ichigo, Sorairo, Shinju) e a cor do pôster. Status por cor
  discreta (bolinha verde = on-line), não por palavra.
- **Selo 炳** é a assinatura (`docs/marca/`). Brilho e efeito nunca podem apagar texto.

## 3. Movimento
- Uma curva e uma duração (`heisuca_motion.dart`). Movimento serve para orientar, nunca para enfeitar.
- **Direção coerente com o gesto:** voltar segue o lado de onde o dedo veio (voltar preditivo do Android). Troca de aba
  sem direção (esmaecer), nunca corte seco.
- Mesmo comportamento de cabeçalho em telas parecidas (o título que encaixa no topo da Início também encaixa na ficha).
- Tudo se desliga em aparelho fraco (`DevicePerformance.isReduced`) e com "reduzir movimento" do sistema.

## 4. Texto
- Frases curtas, voz ativa, segunda pessoa ("Baixe no Wi-Fi"). Sem "orçamento de efeitos", "pressão de memória",
  "decodificador efetivo" na interface; isso vai para um detalhe técnico recolhido, se for preciso.
- Nada de texto desatualizado: ao mudar navegação, revise as Dicas e as mensagens que citam o caminho antigo.

## 5. Produto
- **Independente:** nada do app fala com serviços do Plezy ou de terceiros que não escolhemos (Discord, MAL, AniList,
  envio de logs). Canal da família é o Telegram.
- **Mesma experiência em todas as fontes:** Jellyfin e Plex com a mesma Início, a mesma ficha e o mesmo player; o que é
  exclusivo do CGSERVER (Em alta, Em breve) aparece quando a fonte é o CGSERVER.
- Sempre dizer de onde vem o conteúdo quando há mais de uma fonte.
- **Não inventar:** antes de criar uma tela, procurar como os bons players resolvem e reaproveitar (Caio, 18/10). Antes de
  entregar, comparar lado a lado com a referência.
- Nunca dizer "funciona" sem prova; "não testado em aparelho" quando for o caso.

## 6. Onde estão as decisões
`docs/marca/` (logo, ícones, temas), `docs/PLANO_RODADA_2026-10-24.md`, `docs/RETORNO_CAIO_2026-10-25.md`,
`docs/HANDOFF_*`, `apps/app/CLAUDE.md`.
