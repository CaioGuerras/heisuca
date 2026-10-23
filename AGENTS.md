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
