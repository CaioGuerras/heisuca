# Especificação e Reclamações de UX/UI — Heisuca Web (Padrão VidHub)

> Documento gerado em 19/10/2026 às 06:30 SP a pedido de **Caio Guerras** para transferência da recriação do site ao **Claude Code**.
> Cópia sincronizada do handoff em `~/cgflix/handoffs/2026-10-19_0630_gemini_para_claude.md`.

---

## 1. Diretriz Central: O Modelo VidHub
O Caio decidiu recriar o Heisuca Web tendo como referência visual e funcional o aplicativo **VidHub** (com Plezy como secundário).
O site é o cartão de visitas: minimalista, clean, cinematográfico, com foco em usabilidade essencial e leveza máxima.

---

## 2. Mapa dos Prints de Referência (em `/home/caioguerras/.cgflix/state/geminions/midia/`)

### Telas do VidHub (A Meta):
- `foto41.jpg`: Home VidHub (sem menu 3 pontos, logo e servidor no topo, dock inferior flutuante com 4 botões).
- `foto42.jpg` e `foto43.jpg`: Detalhes de Conteúdo (temporadas contidas em ponto único, botões de ação limpos).
- `foto44.jpg` a `foto49.jpg`: Player minimalista (sem giros, travas ou gestos desnecessários; pular abertura/créditos real).
- `foto50.jpg`: Menu de Bibliotecas contidas (gaveta lateral/dropdown sem quebrar a tela).
- `foto51.jpg` e `foto52.jpg`: Ajustes enxutos e múltiplos servidores isolados (Jellyfin, Plex, WebDAV, SMB).

### Telas dos Erros que o Claude Deve Corrigir:
- `foto70.jpg`: Tela de detalhes com desalinhamentos.
- `foto71.jpg`: Letra do fallback sobreposta nas fotos do elenco (`J`, `M`, `M`, `E`) e blocos de informações técnicas grosseiros.
- `foto72.jpg`: Ao abrir o seletor de temporada, as opções de temporada quebram o fluxo e sobrepõem o elenco e a página inteira.
- Player: Botão de "Pular Abertura" não pode ser fixo em 85s; deve usar os marcadores de intro/capítulos reais da mídia no Jellyfin.

---

## 3. Estado Atual no Repo
- Branch: `gemini/recriacao-site`
- Topo flutuante e dock inferior flutuante (estilo VidHub) já implementados e validados na Home.
- Modal funcional de múltiplos servidores Jellyfin criado em `apps/web/src/comp/ModalServidores.tsx`.
- Testes automatizados passando (`heisuca_teste.py` e `heisuca_nav.py`).
- URL de teste na VPS: `https://netflix.docaio.com.br/__heisuca/`
