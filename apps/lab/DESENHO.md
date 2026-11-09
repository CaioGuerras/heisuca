# Lume: desenho (lab do Heisuca, 09/11/2026)

Site novo, feito do zero, em `labheisuca.docaio.com.br`, a pedido do Caio (08/11): "versão diferente, completa,
bonita, elegante, totalmente nova". É um laboratório: só contas de teste (Caio e Rosiel), `noindex`, nada vai para o
Heisuca sem aprovação dele.

## Ideia
- **Nome:** Lume (a luz da sala de cinema). Marca: chama + "Lume" em Fraunces itálico.
- **Três temas:** Sala (escuro quente, padrão), Matinê (claro, papel de cartaz, acento tijolo), Projetor (preto OLED).
  Cores em OKLCH (`src/estilo/tokens.css`). O tema vem antes do primeiro quadro (script no `index.html`) e a troca
  "acende" em círculo a partir do botão (View Transition; com "reduzir movimento", só esmaece).
- **Movimento:** a mesma família do Heisuca de 08/11: 120/180/260/320/420 ms, curvas `entra`, `sai`, `padrao`;
  reduzir movimento = esmaecido de 180 ms. Nada se mexe sozinho (herói troca só quando a pessoa pede).
- **Título tingido pela cor do pôster** (`--tinta`), sem mudar o tema.

## Telas (`src/telas/`)
| Tela | O que tem |
|---|---|
| Entrada | servidor + usuário/senha ou Quick Connect |
| Início | herói, Continuar assistindo, Em alta com ranking, novidades por biblioteca, Em breve |
| Explorar | bibliotecas, gêneros, ordem (Chegaram agora, A–Z, Lançamento, Mais bem avaliados), só não vistos; grade aos poucos; escolha lembrada por biblioteca |
| Título | abre na hora com a prévia do cartão; completa quando o servidor responde; Mais como este |
| Minha lista | favoritos do servidor, mais recentes primeiro |

Casca (`src/app.tsx`): barra de vidro em cima (computador), abas embaixo (celular), **paleta de comandos** (⌘K ou `/`:
busca ao vivo, recentes, temas, ir a, sair) e **folha de atalhos** (`?`).

## Reaproveitado do Heisuca (alias `@w/` → `apps/web/src`)
Adaptador de servidor e sessão, rota, continuidade da arte (cartão → fundo do título → volta), rolagem do Voltar,
player completo (as variáveis `--hs-*` são mapeadas para os tokens do Lume). Consultas extras em `src/dados/catalogo.ts`.

## Limites conhecidos
- Consultas extras (explorar, gêneros, similares, paleta) só no **Jellyfin**; Plex fica para depois.
- Alvo de navegador moderno (o lab não tem a restrição chrome88 do Heisuca para TVs).
- Sem teste em aparelho real; prints da bancada (Chrome na VPS) foram enviados ao Caio.

## Publicar e desfazer
- Build: `npx vite build` em `apps/lab`; cópia para `/var/www/labheisuca/site` na VPS (rsync com `--chown`).
- Desfazer: mover o conteúdo do site para `Arquivos_Obsoletos` e tirar o nginx
  (`rm /etc/nginx/sites-enabled/labheisuca && nginx -s reload`). O ramo `claude/lab-heisuca` não toca no `main`.
