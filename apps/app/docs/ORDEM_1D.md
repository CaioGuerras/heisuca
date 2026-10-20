# CGFLIX: Etapa 1D (barra única no topo + paisagem + testes) — 07/10/2026

Referência para as rotinas. Resumo da ordem de serviço (a partir do 1.1.0 (300) testado no motorola edge 70):

- **A. Barra única no topo**: sem barra inferior. Emblema à esquerda abre o menu do usuário (perfil, Baixados,
  Configurações, Sair); ao centro, alinhados e centralizados, chips Filmes · Séries · Animes, Busca e "Pedir" (Seerr).
  Sem botão Início (a Início é a raiz; o resto tem Voltar). Topo some ao rolar.
- **B. Tema único** OLED (`#07060a`, roxo `#a855f7`/`#9333ea`), num só `ThemeData`; nada de opções de tema.
- **C. Paisagem**: tudo funciona deitado, sem trilho lateral no celular, sem tela preta. Tablet e TV não quebram.
- **D. Testes**: widget da barra (360/412/800 dp, em pé e deitado) e job de emulador (Android 34, perfil do edge 70) com
  roteiro, giro e capturas; falha com tela preta, overflow ou exceção no logcat.
- **E/F/H**: relatórios em `docs/cgflix/` (Google, telas, código) e correção dos críticos e altos.
- **G. Dedicatória** em destaque ("Feito com amor, para Isis e Heitor", coração roxo e verde) com interruptor em Avançado.
- Prioridade se o tempo apertar: A, B, C, G, H, D, E, F. Versão 1.2.0 (400).
