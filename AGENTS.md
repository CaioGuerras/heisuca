# Heisuca — continuidade entre agentes

## Regras fixas para agentes (Caio, 24/10/2026) — leia antes de tudo

1. **Ramo único: `codex/heisuca-home-site`.** Não crie ramo novo: o cache do GitHub Actions é separado por ramo, e um ramo
   novo gera outra chave de teste; o APK deixa de instalar por cima (aconteceu em 24/10). Nunca faça merge no `main`.
0. **Ambiente do Codex:** o setup do ambiente roda `bash scripts/codex-setup.sh` (Flutter 3.47.1 em `$HOME/sdk/flutter`).
   Em cada terminal novo: `export PATH="$HOME/sdk/flutter/bin:$PATH"`.
2. **Validação = GitHub Actions** (`.github/workflows/heisuca-android.yml`, que roda `scripts/heisuca-checar.sh` e gera o
   APK). Se o ambiente tiver Flutter, rode `bash apps/app/scripts/heisuca-checar.sh` antes do push; se não tiver, não perca
   tempo montando: faça o push e leia o run.
3. **Um item por vez:** commit e push ao terminar cada item; só avance com o run **verde**. Commit que tem `[skip ci]` não
   gera build: nunca deixe o código de um item só num commit `[skip ci]`.
4. **Versão:** suba `version:` em `apps/app/pubspec.yaml` a cada item que gera APK (próxima: 2.0.16+17).
5. **Registro:** atualize `docs/HANDOFF_GPT_ENTREGA_2026-10-24.md` a cada item (commit, link do run verde e do APK, o que
   não foi testado em aparelho). Se a sessão acabar, o que já foi enviado fica salvo.
6. Regras do fork em `apps/app/CLAUDE.md`; pedidos e desenho em `docs/HANDOFF_GPT_2026-10-24.md` e
   `docs/PLANO_RODADA_2026-10-24.md`. Sem segredos no código. "Não testado em aparelho" quando for o caso.

Estado em 24/10 à tarde: itens 1 e 2 do handoff concluídos (APK 2.0.15+16, run 40124421365 verde, mesma assinatura da
instalação do Caio). Faltam os itens 3 a 7.

## Estado mais recente — Codex 24/10/2026, 2.0.9+10

Leia primeiro `docs/HANDOFF_CORRECOES_2026-10-24.md`: retorno após o Claude 2.0.8,
correções, evidências de testes e limites. Não confundir código implementado com teste
físico aprovado. O documento registra o status final do APK quando disponível.

Antes de alterar Android, leia `apps/app/CLAUDE.md` e `docs/HANDOFF_ANDROID_2026-10-22.md`.
A instrução atual de Caio é usar o SITE como referência de Home, incluindo composição,
logo que encaixa no topo, bibliotecas e Em breve. O esboço Android antigo não prevalece
sobre esse pedido. Não confundir um protótipo com uma integração real.

Trabalho atual: `codex/heisuca-home-site`, sobre `codex/heisuca-configuracoes-reais`.
O trabalho Android anterior está em `gemini/heisuca-plex-home`; não existe `main`.
Não fazer merge nem publicar releases automaticamente. Os APKs de Actions são para
avaliação de Caio. Não alterar o site em produção nesta tarefa.

O ai-memory roda em outro ambiente. A documentação neste repositório não significa
que foi importada. O handoff explica como o agente conectado deve gravá-la e conferir
por leitura. Não marcar uma importação, teste físico ou validação visual como concluída
sem executá-los.

## Retorno de Caio em 23/10/2026

A Home do APK 2.0.2 ficou correta nos testes preliminares dele. Preservar esse resultado.
Antes da próxima alteração, ler `docs/PROXIMA_ETAPA_TITULO_FONTES_AJUSTES_2026-10-23.md`:
ficha de conteúdo inspirada no VidHub, referências visuais recuperadas e seus nomes
corrigidos, configurações completas, player e seleção independente de fonte/perfil.
Esse documento é análise/proposta; não significa que tais integrações já foram feitas.

Etapa implementada: ficha, fontes, ajustes e HUD do player em 2.0.3+4.
Leia primeiro `docs/HANDOFF_FICHA_FONTES_PLAYER_2026-10-23.md` para estado de build,
validação e limites. A proposta anterior é histórica, não a lista do que ainda falta.

## Claude em 23/10/2026 — 2.0.4+5

Corrigida a ficha para episódio vindo da Home (abre a série) e os rótulos de temporada/
episódio (`displayTitle` é o nome da série; não usar como rótulo). Ver a seção do Claude no
topo de `docs/HANDOFF_FICHA_FONTES_PLAYER_2026-10-23.md`. Aguarda teste do Caio no aparelho.
Portão local: `apps/app/scripts/heisuca-checar.sh` com Flutter 3.47.1 em `~/sdk/flutter`.
Commitar na própria branch `codex/heisuca-*`: a chave de teste do cache é por branch.

## Claude em 23/10/2026 noite — 2.0.8+9

Ler `docs/REVISAO_CLAUDE_2026-10-23.md` (estado por pilar: feito × aparelho × pendente). Modo infantil em
`lib/heisuca/kids/` (servidor: cgflix-kids na VPS, rota `/__kids/`). Temas Ichigo/Sorairo só pelo perfil infantil.
Guarda de player neutro: `test/heisuca/heisuca_neutral_server_test.dart` (nenhum docaio.com.br no código).

## Claude em 24/10/2026 — 2.0.10+11

Estado e próximos passos no topo de `docs/HANDOFF_CORRECOES_2026-10-24.md` (build do GPT destravado, ficha
paralelizada, diagnósticos de servidor: cache rclone cheio e imagens a frio). Aguarda teste do Caio no aparelho.
