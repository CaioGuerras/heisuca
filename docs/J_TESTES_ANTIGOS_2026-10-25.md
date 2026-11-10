# Etapa J — os 16 testes antigos

Reproduzidos antes da alteração: `cgflix_navigation_test.dart`, 1 aprovado e
16 falhando, exatamente a lista de `TESTES_FALHANDO_2026-10-24.txt`.
Não se restaurou a barra antiga: a Início aprovada usa `HeisucaHomeChrome`.
A pílula pública é conferida também por `heisuca_flagship_test.dart`.

| Teste antigo | Motivo e cobertura atual |
| --- | --- |
| Conectado: só a Início, sem barra inferior | Desenho mudou de propósito. Confere as seções disponibilizadas ao Main; o teste da pílula confere Início, Biblioteca, Baixados e Você. Busca não é anunciada como quinta aba. |
| Topo em paisagem 360 | Desenho mudou. Testa marca/busca do chrome real em 760×360, alinhamento, limites e toque de 48 dp. |
| Topo em paisagem 412 | Mesmo motivo; chrome real em 914×412. |
| Topo em paisagem 800 | Mesmo motivo; chrome real em 1280×800. |
| Topo em retrato 360 | Mesmo motivo; chrome real em 360×760. |
| Topo em retrato 412 | Mesmo motivo; chrome real em 412×914. |
| Topo em retrato 800 | Mesmo motivo; chrome real em 800×1280. |
| Emblema → menu → Baixados | Na Início atual a marca escolhe fonte; Você fica na pílula. O menu antigo é mantido no cabeçalho offline: teste usa esse componente real e confere o despachante/Voltar. |
| Emblema → menu → Bibliotecas | Mesmo motivo; confere despachante/Voltar do menu mantido, com estado on-line controlado, sem servidor. Não anuncia esse caminho como navegação atual da Home. |
| Emblema → menu → Configurações | Mesmo motivo; confere despachante/Voltar do menu mantido. |
| Emblema → menu → Meus pedidos | Mesmo motivo; confere despachante/Voltar do menu mantido. Pedidos continuam na busca atual. |
| Lupa → Busca | Mesmo destino, acionado pelo botão do chrome real; confere abrir, botão Voltar e `maybePop`. |
| Menu do usuário deitado | Testa o menu do cabeçalho offline em 914×412, rolagem e acesso aos ajustes. |
| Paisagem: lupa → Busca | Mesmo destino; chrome real em 914×412, retorno por botão e sistema. |
| Leitor de tela: botões de ícone | Marca atual identifica trocar fonte; busca tem nome acessível do botão padrão Flutter; menu offline usa Heisuca. Saiu a expectativa antiga "Menu do CGFLIX". |
| Tela estreita/fonte grande: chips | Chips não ficam mais nesse topo. Testa o título encaixado no chrome real, 320×640, texto em dobro, sem cobrir a marca/busca. Filtros atuais têm cobertura nos testes reais da Biblioteca. |

O caso offline que já passava foi preservado: Baixados continua a raiz sem conexão.
Os quatro despachantes usam páginas controladas; isso prova a navegação e o retorno,
não o acesso real a bibliotecas, pedidos ou downloads de servidor.

## Bug real encontrado com os testes atuais

Com o harness ocupando a tela inteira, seis tamanhos falhavam pelo alvo da marca:
**28 dp**, esperado **≥ 48 dp**. O desenho do SVG continuou com 28 dp; apenas a área
invisível de toque passou a 48 dp, mantendo o desenho centralizado na mesma posição.
Antes: seis falhas por 28 vs 48. Depois: **17 testes aprovados**, mais o golden da
Início Jellyfin (parada e rolada), **18 no total**. Os PNGs de referência não mudaram.
Nenhum chip, fileira, recorte ou espaçamento visível da Início foi alterado.

Não testado em aparelho: TalkBack físico, gestos Android/OEM e fluxos autenticados.
