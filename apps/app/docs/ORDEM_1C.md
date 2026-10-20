# CGFLIX: Etapa 1C (remodelagem a partir da 1B) — 07/10/2026

Referência para as rotinas. Resumo da ordem de serviço:

1. **Busca unificada**: um cartão por título/pessoa, mesmo vindo de vários servidores (CGFLIX, Tucho Pictures Studios,
   Locadora+, GuedesFlix, gabiflix). Agrupar por IDs externos (tmdb/imdb/tvdb) ou título normalizado + ano + tipo; pessoas
   por ID ou nome. Sem nome de servidor no cartão. Fonte: CGFLIX → progresso → resolução → primeiro. Seletor
   "Disponível em N servidores" na página do título. Filmografia da pessoa juntando os servidores. Ordem: Títulos, Pessoas,
   Coleções. Testes do agrupamento.
2. **Navegação enxuta**: um só perfil (aba Você); barra inferior só com ícones (sem rótulos, ~56–64 dp, indicador roxo
   `#a855f7`, cheio/contornado, TalkBack lendo o nome, translúcida com desfoque, edge-to-edge); chips Filmes · Séries ·
   Animes filtrando a própria Início com "×" para voltar (antes não funcionavam: `_selectLibrary` saía sem a aba
   Bibliotecas); topo some ao rolar para baixo; sem botões duplicados.
3. **Polimento e Android**: cores e tipografia do site, cartões com canto ~8 dp, edge-to-edge, voltar preditivo, Splash
   Screen API, háptico, transições de 250–350 ms ease-out, esqueletos, rolagem preservada; busca com foco automático,
   histórico e "Pedir" (Seerr). TV só não pode quebrar.
4. Entrega: PR com antes/depois, `CGFLIX.md`, CI verde, resumo de 10 linhas para o dono. Subir o versionCode.
