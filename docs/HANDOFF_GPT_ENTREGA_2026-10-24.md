# Heisuca — entrega da rodada de 24/10/2026

Branch de trabalho: `codex/heisuca-rodada-2410`, criada a partir de
`381295b5e1e7951fa02cbb58a0c29c04772b93d0` da `codex/heisuca-home-site`.

## Regra atual de validação
Caio autorizou em 24/10 usar GitHub Actions como validação: commit e push de um item,
corrigir runs vermelhos e só avançar após run verde. Não preparar SDK local.
O workflow executa `scripts/heisuca-checar.sh` antes do APK.

## Item 1 — ficha da pessoa — 2.0.14+15
Implementação enviada para validação; **ainda não aprovada** até o registro de run verde abaixo.

- `lib/cgflix/search/cgflix_sources.dart`: fontes autorizadas do adulto, escopo restrito kids,
  procura por nome nas fontes e paginação completa, agrupamento e melhor fonte da busca.
- `lib/cgflix/search/cgflix_person_plex.dart` e um gancho em `services/plex_client.dart`:
  lê GUID de metadado confirmado como pessoa; rejeita colisão entre tag id e ratingKey de filme.
- `lib/heisuca/heisuca_person_credits.dart`: resolve identidade ao abrir a ficha.
  Jellyfin consulta `/Items/{personId}` e ProviderIds.Tmdb; Plex consulta metadado de pessoa
  e GUID TMDB. Sem identidade confirmada, mostra apenas No acervo.
- `lib/cgflix/requests/cgflix_seerr.dart`: contrato separado de créditos pessoais e
  consulta `/person/{id}/combined_credits`; somente cast, sem incluir crew.
- `lib/cgflix/requests/cgflix_requests_ui.dart`: reaproveita a escolha de temporadas,
  pedido e estados existentes; permite título/consulta de créditos e exclusão do acervo.
- `lib/screens/actor_media_screen.dart`: ganchos mínimos para as duas seções.
- `test/heisuca/heisuca_person_credits_test.dart`: identidade, formatos de créditos,
  deduplicação filme/série, exclusão com conflito de IDs e paginação.
- `pubspec.yaml`: 2.0.14+15.

### Limites
Não testado em aparelho. Não foi realizado teste ao vivo com a conta de Caio,
Sadie Sink ou Stranger Things. Servidores Plex que só fornecem tag id local e não
metadado de pessoa com GUID TMDB continuam exibindo apenas No acervo; nenhum ID é
adivinhado por nome. No kids não há consulta de catálogo nem botão Pedir.
Nenhuma configuração de servidor/VPS/Sonarr/Jellyfin foi alterada.

### Evidências
Commit: registrar após publicação.
Run verde: pendente. APK: pendente.
Comandos no portão: `flutter analyze --no-fatal-infos --no-fatal-warnings lib` e
`flutter test` com a lista de `scripts/heisuca-checar.sh`, incluindo `test/heisuca`.
Não declarar ausência de falhas novas antes do resultado real.

## Itens 2 a 7
Aguardam aprovação do item 1 no Actions. Não iniciados. Não foi acrescentada transmissão,
o ícone instalado não foi trocado e não houve merge ou release.
