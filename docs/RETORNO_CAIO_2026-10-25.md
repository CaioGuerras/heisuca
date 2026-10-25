# Retorno do Caio no 2.0.17 (instalação do zero) — 25/10/2026

Analisado pelo Claude (código, prints e 2 vídeos). **Nada corrigido ainda**; o Caio decide antes do próximo prompt.

| # | Ponto | Causa encontrada | Proposta |
|---|---|---|---|
| 1 | "HEISUCA" da abertura mais grosso conforme o aparelho | `heisuca_opening_splash.dart` escreve o nome em texto com `fontFamily: 'Sora'`, peso 800; o arquivo `assets/fonts/Sora-VF.ttf` existe mas **não está declarado no `pubspec.yaml`**, então cada aparelho usa a fonte padrão dele em negrito | Usar o mesmo SVG da Início (`marca_site_*.svg`) na abertura; declarar a Sora no pubspec para os títulos |
| 2 | Hero demorou na instalação do zero | Primeira carga sem cache: dados do destaque e imagens chegam depois das fileiras | Medir na bancada; reservar o espaço com esqueleto e pré-carregar a primeira arte |
| 3 | Coração no botão Favoritos da Biblioteca | Ícone que eu (Claude) pus no `ActionChip`; os vizinhos não têm | Tirar o ícone |
| 4 | Ícones e fontes da área de servidores fora do padrão | Telas herdadas do upstream ("Adicionar a…", "Escolha uma fonte") com `ListTile` e ícone genérico de servidor | Redesenhar no padrão Heisuca: ícone próprio de fonte, bolinha de status (verde on-line, âmbar conectando, cinza fora do ar, vermelho erro), sem a palavra "Conectado" |
| 5 | Tema infantil abre claro mesmo no tema escuro | Ichigo/Sorairo foram desenhados claros (paleta da Maryanne) | Para depois: versão escura dos temas infantis |
| 6 | Campo "Nome da criança" invisível até tocar | Rótulo e fundo do campo no tema claro sem contraste | Corrigir cores do campo nos temas infantis |
| 7 | Foto escolhida não aparece na criação | A tela só troca o texto para "Foto escolhida · trocar" | Mostrar a foto em círculo no lugar |
| 8 | Foto da criança na abertura infantil | Viável e leve (uma imagem local já em disco) | Fazer |
| 9 | Medidor numa tela feia e separada | O Codex criou "Este aparelho" em vez de pôr no popup existente | Medidor estilizado **dentro** do popup "Funções e desempenho" (Configurações › Aparelho reconhecido); apagar a tela e o item do menu Você; reescrever textos em linguagem simples |
| 10 | Dicas desatualizadas | Citam caminhos antigos ("menu (sua foto) › Baixados", "toque no seu nome"), "Entrar na TV" e "Ver na TV" se sobrepõem, citam "TV box", só falam de Quick Connect (Jellyfin) | Reescrever: caminhos atuais, uma dica de TV (Fire TV, Google TV/Android TV, Roku, Apple TV, Samsung/LG com nossos apps), Plex com plex.tv/link. Ícones: Material Symbols (biblioteca do Google, não do Plezy) |
| 11 | No Plex continuam as fileiras do Plex | Item 9 do handoff, decidido, ainda não feito | Fazer o item 9 |
| 12 | Brilho da abertura apaga o slogan | `BoxShadow` largo no selo e slogan em cinza baixo | Brilho menor e slogan com mais contraste |
| 13 | Listra fina abaixo do pôster ao rolar (ficha e Início) | **Parallax** (`HeisucaParallax`) move a arte junto com o degradê de baixo; ao rolar, o degradê sai do recorte e a borda fica seca | Degradê fixo, só a imagem se move |
| 14 | Busca não diz de qual servidor vem | Busca unificada (1C) escondeu o servidor de propósito | Mostrar a fonte em cada resultado (nome curto ou selo); "2 fontes" quando o título existe em mais de uma |
| 15 | Troca de abas abrupta; telas deslizam sempre da esquerda | Abas (vídeo 1) trocam em corte; telas empurradas usam transição de um lado só | Abas: esmaecer (fade-through). Telas: entrar com esmaecer + leve escala e voltar com o **voltar preditivo** do Android, que segue o lado do gesto |
| 16 | Título encaixa no topo na Início, mas não na ficha | O encaixe existe só em `heisuca_home_chrome.dart` | Mesmo encaixe na ficha |

## Perguntas do Caio
- **Dependência do Plezy:** ver resposta no chat de 25/10 e a seção abaixo.
- **Discord:** veio do Plezy (status do que você assiste no Discord, só no computador). Não usamos: remover tudo.
- **Testes:** temos testes de tela (com capturas) e o CI; falta uma **bancada Android** com emulador no GitHub Actions
  rodando o app de verdade, com capturas e vídeo dos fluxos. Proposta abaixo.

## Independência do Plezy (diagnóstico)
- O app é um fork: ~277 mil linhas em `lib/`, ~21,7 mil nossas (`lib/heisuca`, `lib/cgflix`, ~8%). Player (mpv),
  clientes Jellyfin/Plex, downloads e boa parte da navegação vêm do Plezy. Pacote Android interno ainda
  `com.edde746.plezy`; 150 arquivos citam "plezy".
- Licença GPL-3.0: enquanto houver código derivado, é **obrigatório** manter a licença e o aviso de direitos autorais, e
  mostrá-los no app (aviso legal em "Sobre › Licenças", como todo app de código aberto). Isso não é dedicatória; é lei.
  Livre de verdade só com reescrita completa das partes herdadas.
- Caminho proposto: **fork independente** — parar de seguir o upstream; remover o que não usamos (Discord, MAL/AniList,
  envio de logs, recursos sem uso); renomear pacote e canais (`com.edde746.plezy`, `com.plezy/*`) para `app.heisuca`;
  tirar "Plezy" de nomes e textos; trocar o texto de crédito do Sobre por uma página padrão de licenças. Reescrever
  módulos aos poucos, quando fizer sentido. Dedicatória de agradecimento só quando estivermos livres (decisão do Caio).

## Bancada Android (proposta)
- Job novo no Actions com emulador Android (o runner Linux do GitHub tem aceleração), rodando `integration_test` com o
  APK: abertura, login, Início, ficha, busca, player (vídeo de teste), troca de abas; salva capturas e um vídeo da tela
  como artifact. Login: servidor falso local (sem credencial) ou a conta de teste do CGSERVER guardada como segredo do
  repositório **[C] Caio autoriza**.
- Não substitui o celular para fluidez real, mas pega tela vazia, texto errado, fonte trocada e transição quebrada.
