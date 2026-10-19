# Sessão A: entrada e animações (ramo `site-v2-a-entrada`)

PLANO §3 (entrada e animações) e §2 (sistema visual). Tudo contra o servidor falso (`testes/falso`), Chromium da bancada.

## Para aprovar primeiro: os vídeos

Em `testes/comparacoes/a/`. Cada um mostra a sequência inteira, na velocidade real:
**abertura → voo da logo → entrada (digitando o endereço, o ✓ do servidor, o usuário) → Iniciar sessão → 2ª animação → home**
e depois **recarrega com a sessão salva** (abertura → 2ª animação → home, sem a entrada).

| Vídeo | Aparelho | Tema |
|---|---|---|
| `video_cel_roxo.mp4` | celular 412×915 (MP4 ampliado para 824 px de largura) | Roxo |
| `video_cel_verde.mp4` | celular | Verde |
| `video_desk_roxo.mp4` | computador 1440×900 | Roxo |
| `video_desk_verde.mp4` | computador | Verde |

Para gravar de novo: `python3 testes/sequencia_entrada.py --video --salva` (e `--quadros` para os prints; `--reduzido` simula
"reduzir movimento"). Ver o cabeçalho do script. Observação de bancada: o Playwright pede um ffmpeg próprio para gravar;
na nuvem eu apontei `PLAYWRIGHT_BROWSERS_PATH` para uma pasta com links para o Chromium de `/opt/pw-browsers` e para o
`/usr/bin/ffmpeg` do sistema, sem baixar nada.

## O que fiz

### 1. Abertura (`Logo.tsx`, `Logo.css`)
- O desenho aprovado não mudou (tempos, carimbo, luz, slogan). Mudou só o **enquadramento**: o SVG da abertura era um
  quadro 640×360 com a logo ocupando ~64% da largura dele. Recortei as laterais vazias (`viewBox 90 50 450 260`).
- **Celular em pé:** a logo passou de ~59% para ~80% da largura da tela (de ~245 px para ~330 px no 412).
- **"Um pouco à esquerda":** medi, e a logo já estava centrada pela caixa (selo 114 → fim do HEISUCA 524, centro 319 no
  quadro de 640). O que dá a impressão de desvio é o peso: o selo cheio à esquerda e as letras finas à direita. Desloquei o
  recorte 4 unidades para a direita (≈ 3 px no celular) como compensação ótica. Se ainda parecer à esquerda no seu
  aparelho, é só um número (`'90 50 450 260'` em `Logo.tsx`): ver [C1].
- **Computador:** o tamanho continua o mesmo de antes (a regra de largura foi convertida para o quadro recortado).

### 2. Entrada (`Entrada.tsx`, `entrada.css`)
- **A logo não pula mais.** A linha "✓ nome do servidor" agora existe sempre (vazia e invisível até o servidor responder),
  e o erro de endereço entra nessa mesma linha. Além disso, o bloco logo + formulário começa a uma altura fixa
  (perto do centro) em vez de ser centrado pela altura total: qualquer mensagem nova (usuário/senha incorretos etc.) só
  cresce para baixo. A logo fica parada em todos os casos.
- **Saída:** ao entrar, o formulário e o ícone do Quick Connect esmaecem (240 ms) e só a logo fica; é dela que a 2ª
  animação parte. Antes o formulário sumia de uma vez.
- Refino visual, sem mudar a estrutura: campos com uma borda fina (`--hs-linha`) e um halo leve no foco, na cor do tema;
  o ícone do Quick Connect sem o disco de vidro (só o ícone, discreto, como pede o §3.2); botão em pílula com peso 600.
- O que já existia continua igual: endereço sem `https://`, `/jellyfin`, Quick Connect só depois que o servidor responde,
  erros sob o campo culpado, senha vazia.

### 2b. Entrada aberta de dentro do site (revisão da sessão principal)
- Quando a pessoa já está logada e escolhe **Trocar servidor → Adicionar servidor** (ou um servidor sem sessão guardada),
  a entrada mostra um **"←" no canto superior esquerdo** (e **Esc** no computador) para desistir e voltar para onde estava,
  com a sessão atual intacta. No primeiro acesso não há "←". Prop nova `voltar?: () => void` em `Entrada`; a casca
  (`app.tsx`) passa `volta: true` na fase de entrada aberta por ela.
- Nesse caminho a página ainda estava na cor do pôster da home; a entrada agora chama `usePaleta(null)` e volta à cor do tema.
- Print: `testes/comparacoes/a/entrada_pela_casca_cel.jpg` (Roxo e Verde).
- Testado: 1º acesso sem "←"; pela casca com "←"; o "←" e o Esc voltam para a home sem erro no console.

### 3. 2ª animação (`Transicao.tsx`, `transicao.css`): "a inversa da primeira"
Linha do tempo (contada a partir do clique em Iniciar sessão):

| Tempo | O que acontece |
|---|---|
| 0–0,24 s | o formulário esmaece; só a logo fica |
| 0,24–1,0 s | **a logo cresce** do lugar dela até o centro da tela (voo FLIP; 232 → 330 px no celular, → 540 px no computador) |
| 1,0–1,5 s | começa a abertura **ao contrário**: o ヘイスカ some e o traço de luz nasce sob o "H", como na abertura |
| 1,5–2,2 s | **a luz atravessa o HEISUCA e apaga a palavra** atrás dela (recorte da esquerda para a direita) |
| 2,2–2,8 s | o selo, sozinho, desliza para o centro da tela e cresce um pouco |
| espera | o selo **respira** (escala 1 → 1,035, 2,2 s) enquanto a home não fica pronta |
| últimos 1,25 s | **o selo se abre até cobrir a tela**: o fundo dele vira um campo que cresce (clip-path) e passa da cor do tema para o matiz do pôster do 1º destaque até a cor da página da home; o kanji cresce e esmaece; a home aparece por baixo, já na mesma cor |

- **Tempos:** do clique até a home deu 4,5–4,8 s com o servidor falso (dados instantâneos). A camada nunca passa de 5 s
  desde que monta: com rede lenta, a revelação começa aos 3,75 s de qualquer jeito e a home abre com esqueleto no que
  faltar (o controle de tempo e o carregamento por baixo vieram da fundação; não mexi na lógica, só nos números).
  Com a **sessão salva**: abertura + transição ≈ 7,1 s (o plano previa 5–7 s): ver [C3].
- A cor final é exatamente `paletaDe(corDaBase(hash do 1º destaque)).pagina`, a mesma que a home usa: o fim da animação e
  o começo da home não têm "degrau" de cor.
- Só `transform`, `opacity` e `clip-path` (GPU); nenhuma propriedade de layout é animada.

### 4. "Reduzir movimento"
- Abertura: já virava só opacidade (CSS da marca); mantido.
- Voo da logo: não acontece (a logo já aparece no lugar).
- 2ª animação: a logo aparece parada; no fim, só um esmaecimento do fundo para a cor do pôster e da camada (450 ms).
  O mínimo cai de 3 s para 1,2 s (não há movimento a mostrar; a espera é só o carregamento): ver [C4].

## Comparações (`testes/comparacoes/a/`)
- `cmp_entrada_<cel|desk>_<roxo|verde>.jpg`: abertura · entrada vazia · entrada com o ✓ · **Streamyfin servidor** · **Streamyfin login**.
- `cmp_transicao_<cel|desk>_<roxo|verde>.jpg`: a 2ª animação em quadros (600 ms … 3200 ms) até a home.

## O que difere da referência (Streamyfin) e por quê
1. **Logo centralizada, não alinhada à esquerda.** O Streamyfin alinha logo e título à esquerda. Aqui a logo é a que pousou
   da abertura, que é centrada; alinhar à esquerda obrigaria o voo a atravessar a tela de lado. Fiquei com o centro.
2. **Uma tela só** (servidor + usuário + senha), em vez das duas do Streamyfin, e **sem** título "Iniciar sessão em CGFLIX",
   URL repetida, "Guardar esta conta", "custom headers" e "Procurar servidores locais": tudo cortado pelo Caio (§3.2).
3. **Quick Connect no canto superior direito**, e não ao lado do botão (Streamyfin): decisão do §3.2.
4. **Botão em pílula** (Streamyfin usa retângulo arredondado): regra do §2.3.
5. Bloco um pouco acima do centro (o do Streamyfin fica no meio-baixo). É consequência de a logo não poder pular: a altura
   é fixa a partir do topo. Em telas baixas (celular deitado) o bloco encosta no topo e a página rola.

## O que não ficou bom (honesto)
- **A espera "respirando" quase não aparece nos vídeos**, porque o servidor falso responde na hora: a revelação começa assim
  que o selo chega ao centro. Com a rede real do CGSERVER o selo deve respirar por 0,5–1,5 s; não consegui ver isso aqui.
- **No computador, o selo é alto e estreito e a tela é larga:** a abertura do campo cresce mais na horizontal do que na
  vertical, e no meio do caminho lembra um retângulo esticado. No celular em pé fica natural (o selo e a tela têm a mesma
  proporção). Se incomodar, uma alternativa é o campo se abrir como um círculo a partir do selo ([C2]).
- **Pôster de pouca cor** (o 1º destaque do servidor falso, *Buddy*, é quase cinza): a passagem pelo "matiz do pôster" não
  aparece, e o campo vai do roxo/verde do selo direto para um cinza-escuro (Roxo) ou cinza-claro (Verde). É o dado real; com
  um pôster colorido o meio do caminho ganha a cor dele. Não testei com outro destaque, porque o falso tem um só na ordem.
- **Vídeo do Playwright:** a gravação do Chromium sem tela tem quadros irregulares (às vezes ~20 qps). Pequenos
  "soluços" no vídeo podem ser da gravação, não da animação; no aparelho de verdade deve ficar mais liso.
- O tempo total depois do clique soma o login (a chamada `AuthenticateByName`) e os 240 ms do esmaecimento antes de a
  camada montar; com servidor lento isso pode passar um pouco dos 5 s contados do clique.

## Dúvidas para o Caio
- **[C1]** A abertura no celular em pé ficou ~80% da largura e com um leve deslocamento ótico à direita. Está bom, ou quer
  maior ainda / sem a compensação?
- **[C2]** A abertura final do selo: retângulo que cresce até a tela (atual, "o carimbo se abre") ou círculo que nasce do
  selo? No computador o círculo talvez fique mais elegante.
- **[C3]** Com a sessão salva, o total ficou ~7,1 s (abertura 2,3 s + voo + 2ª animação). Quer encurtar (por exemplo, pular a
  parte "luz apaga a palavra" quando vem direto da abertura, ficando ~5,5 s)?
- **[C4]** Com "reduzir movimento", deixei a espera mínima em 1,2 s em vez de 3 s. Pode?
- **[C5]** O bloco da entrada fica um pouco acima do centro (para a logo não pular). Prefere mais para baixo, como no
  Streamyfin?

## O que mexi fora dos meus arquivos
- `src/anim/voo.ts` é meu (anim/*): acrescentei `animar()` (Web Animations com `fill: forwards` e a curva da casa). Nada
  do que já existia mudou.
- `src/app.tsx`: só o necessário para o "←" (campo `volta` na fase de entrada e a função `voltar` passada à `Entrada`).
- `testes/sequencia_entrada.py` (novo): grava a sequência em vídeo e em quadros.
- Juntei o `site-v2` no meu ramo (merge, não rebase, porque o ramo já estava publicado), com as correções da Folha e dos scripts de prints.
- Nenhum componente comum foi alterado.
