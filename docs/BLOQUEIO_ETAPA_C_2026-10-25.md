# Etapa C — contrato de dados a esclarecer antes de alterar o app

Estado: A, A2 e B concluídas no Actions. Último APK: **2.0.20+21**, código
`383f59ef4a3ac36b853f79e92968d7b51e3e4b37`, run
[40159071302](https://github.com/CaioGuerras/heisuca/actions/runs/40159071302),
[APK](https://github.com/CaioGuerras/heisuca/actions/runs/40159071302/artifacts/12586550852).

## Diferença encontrada

O item 9 pede Em alta e Em breve quando a fonte ativa é o Plex CGFLIX
(`056b61fd61d67e9656ec915d38e21294a99dbbba`). Não condiciona isso a ter o
Jellyfin do CGSERVER conectado. Já o item 8 explicita essa condição para o logo.
O contrato atual no repositório só permite obter os dados completos pela
conexão Jellyfin. Não há no desenho um contrato para a instalação que só tem Plex.

Evidência no código, no commit acima:

- `apps/app/lib/cgflix/home/cgflix_home_repository.dart:174`: Em breve combina
  `/cgflix/embreve.json` com `/HomeScreen/Section/UpcomingShows` e
  `/HomeScreen/Section/UpcomingMovies`, incluindo `cgflixUserId` da sessão Jellyfin.
- `apps/app/lib/cgflix/home/cgflix_jellyfin_queries.dart:88`: os caminhos são
  relativos ao cliente Jellyfin autenticado; não são uma API comum do Plex.
- `apps/app/lib/heisuca/heisuca_upcoming.dart:14`: o mapa sozinho não é o
  calendário. Datas/episódios/pôsteres vêm das seções HomeScreen; o mapa relaciona
  IDs Sonarr/Radarr ao item Jellyfin ou TMDB. Sem seção o parser retorna vazio.
- `apps/app/lib/cgflix/home/cgflix_home_logic.dart:144`: o modelo atual de Em alta
  carrega ID Jellyfin, nome, tipo e biblioteca. A implementação atual busca os
  itens Jellyfin para obter metadados; o contrato não garante TMDB/TVDB no feed.
  Isso descreve o leitor atual, **não prova o conteúdo atual do arquivo no servidor**.
- `apps/web/src/api/jellyfin.ts:253`: o site usa a mesma combinação mapa + plugin.
- `apps/app/test/heisuca/heisuca_neutral_server_test.dart`: o app deve continuar
  neutro, sem endereço de mídia embutido. O identificador Plex reconhece o
  servidor, mas não informa URL, usuário ou token do Jellyfin correspondente.

A busca Plex por IDs externos já existe (`PlexClient.findByExternalIds`), portanto
não é o problema. O ponto anterior a ela é obter o ranking/calendário e seus IDs
com uma origem/autenticação definida quando só o Plex está conectado.

## O que precisa ser definido

Uma destas condições precisa constar no desenho:

1. As duas fileiras do Plex dependem de uma conexão Jellyfin CGSERVER já salva no
   app. Nesse caso, especificar a identificação/vinculação desse Jellyfin e o
   comportamento quando ele não está conectado ou está fora do ar.
2. Os dados ficam disponíveis a quem só conecta Plex por uma API própria do
   CGSERVER. Nesse caso, fornecer o contrato de descoberta/endereço, autenticação,
   ranking e calendário com TMDB/TVDB e datas, sem segredo nem endereço de mídia
   embutido no aplicativo.

Não foi escolhido nenhum desses caminhos pelo Codex. Exigir silenciosamente
Jellyfin, inventar um endereço ou usar token Plex no Jellyfin acrescentaria uma
regra que não foi aprovada. Não houve acesso a servidor real nesta investigação;
nenhum endpoint foi declarado inexistente com base apenas no leitor do app.

## Limites e continuidade

Pausa conforme a instrução de Caio: “Se algo não bater, pare e documente.”
Nenhuma implementação parcial da C foi enviada, nenhuma versão nova foi criada
para esta documentação e a Início Jellyfin permaneceu intacta. C–M pendentes;
retomar pela C depois de esclarecer o contrato. Não pular para D.
