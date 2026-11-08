# Respostas Plex fictícias

Campos e envelopes copiados do formato lido no Android, sem dados reais.
Referência: master 9a224276a2800ca52ad4ddaf24a69c3e27e8e83c.
- services/plex_client.dart:879-920, 1100-1140: MediaContainer/Directory/Metadata e paginação.
- services/plex_client.dart:1627-1668, 4884-4909: hubs de continuar e busca.
- services/plex_auth_service.dart:231-265: resources e tokens de servidor.
- services/plex_mappers.dart:110-140, 568-681, 762-783, 1490-1506: streams, campos de metadados, imagens e capítulos.
Os três serviços pedidos foram lidos; plex_mappers.dart complementa os campos delegados pelo cliente.
Todos os nomes, IDs, endereços e tokens destes JSONs são inventados.
