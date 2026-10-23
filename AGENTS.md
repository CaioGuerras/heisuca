# Heisuca — continuidade entre agentes

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
