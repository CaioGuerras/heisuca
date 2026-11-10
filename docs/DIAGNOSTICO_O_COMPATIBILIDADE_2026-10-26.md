# O: contratos da base e ports — revisão para o Claude

**O não entregue.** Pausa a pedido do Caio: se uma parte travar ou o código real
não encaixar no desenho, parar e apresentar o diagnóstico. Não houve adaptação
parcial publicada no app. Último código entregue: N, `c1d466e`, **2.0.32+33**.
Próxima versão para uma implementação da O continua **2.0.33+34**.

## Base conferida, sem confiar nos redirecionamentos do Gemini

Comparei o primeiro snapshot `apps/app` (`612b0a6a8fef6a7822f1ceca4eb08a96a0608f86`)
com **34 tags** do Plezy, de 2.0.0 até 2.24.0. Normalização: retirar apenas o
prefixo `apps/app/`; comparar blobs de arquivos de texto de código/testes e
plataformas. Não foram apagados imports, marca ou whitespace para aumentar a
semelhança. Matriz completa:
`pesquisa_rodada2/BASE_PLEZY_COMPARADA_2026-10-26.json`.

| Tag | Idênticos | Alterados | Adicionados no fork | Ausentes no fork | Diferença total |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2.22.0 | 1812 | 205 | 123 | 6 | **334** |
| 2.23.0 | 1744 | 277 | 119 | 18 | 414 |
| 2.21.0 | 1539 | 456 | 145 | 8 | 609 |
| 2.24.0 | 1461 | 499 | 180 | 130 | 809 |

**Base mais próxima: Plezy 2.22.0**, tag
`1c2381f0da4a75d0e16b2dd8745551bb816de9fb`. Isso não prova que o snapshot seja
uma cópia exata dessa tag; ele já tem alterações próprias. Não confundir a
versão Heisuca 2.0.x com a versão do upstream.

Notas oficiais conferidas pela API de releases e código:

- [2.23.0](https://github.com/edde746/plezy/releases/tag/2.23.0): coleções offline,
  repetição em lote, File Info no player e opções de Dolby Vision.
- [2.24.0](https://github.com/edde746/plezy/releases/tag/2.24.0), publicada em
  **21/10**: correção de legendas após seek/troca, memória das miniaturas e outras
  correções. O relatório do Gemini trocou a versão de várias dessas novidades.
- A folha File Info existe no Heisuca, mas seu modelo descreve o **arquivo**;
  isso não fornece, por si só, o motivo da conversão da sessão ativa.

## Onde o port direto não encaixa

### 1. Prévia, fonte de mídia e primeiro quadro

Origens: `11c4cc7e` (identidade da prévia Jellyfin/Emby), `07f2b773` (carregar
depois do primeiro quadro) e `2b86697e` (limitar leitura do BIF).

- Nosso `MediaSourceInfo` (`lib/media/media_source_info.dart`) **não tem
  `partTimeline`**. O helper `scrubPreviewServes` usado pelo patch considera
  partes de arquivos empilhados e esse campo. Nosso caminho compara `partId`
  diretamente, inclusive quando os dois lados são nulos.
- Nosso `_queueScrubPreviewLoad`, em
  `lib/screens/video_player/parts/playback_services.dart`, difere do contexto
  que o patch pressupõe. O patch não foi aplicado à força. É necessário
  definir como a identidade da prévia funciona no nosso contrato, ou trazer
  também o suporte anterior a múltiplas partes.
- Não trocar o controle de primeiro quadro inteiro pelo do upstream: a M
  ainda tem imagem preta depois do áudio, com diagnóstico separado. Não há
  evidência de que isso seja causado pela carga das miniaturas.

**Prova independente já obtida:** nosso BIF atual passa o arquivo pelo isolate,
criando outra cópia. Teste com um BIF de um quadro, alteração do byte original
depois do load e leitura da miniatura: esperado 254, obtido 16. Log preservado em
`evidencias/o_bif_antes_2026-10-26.txt`. Esse teste negativo não ficou no portão.
Otimização de buffer HTTP vem de `5473b4ca`; ficou apenas como estudo, sem código
ativo alterado. Não foi feita uma medição física do pico de memória.

### 2. Coleções offline e migração do banco

Origem: `41ff7f63` (coleções offline); repetição em lote: `2f4b72f7`.

- Nosso banco está no **esquema 23**, em `lib/database/app_database.dart`.
- O patch de coleções pressupõe **24 → 25**. O gerado do upstream também
  contém mudanças anteriores, como `DownloadedMedia.additionalPartPaths`.
  Copiar esse gerado não é uma migração válida do nosso esquema.
- Isso **não demonstra que coleções precisem de multipart**. Há duas rotas
  que precisam ser avaliadas e testadas: separar as tabelas de coleções e
  gerar uma migração própria a partir do 23, ou portar a cadeia anterior de
  modelos/downloads/migrações antes das coleções. Não escolher só um número
  novo e copiar o arquivo gerado.
- O teste de aplicação, após normalizar `package:plezy/` para `package:heisuca/`,
  localizou o desencontro nos arquivos do banco. Nada foi aplicado por partes.
  A repetição em lote e a regra por temporada ainda não foram entregues na O.

### 3. Atualização nativa para a correção das legendas

Origem Plezy: `564937094c8fae490c042c26f927616fe79695c0`.
Correção no mpv-build: `d7e9802` (linha de legenda perdida após cache/track switch).

- Nosso lock usa TARs por ABI, chave `046978adf55a`, mpv-build
  `0a76578445a0908c100ea985f4bd4cf0b21f9ca9`. O Gradle extrai bibliotecas e
  headers desses TARs; nosso JNI é compilado dentro do projeto, com namespace
  `app.heisuca.libmpv`.
- Plezy 2.24.0 usa `mpv-android-5e70f9120a14.aar`, mpv-build
  `582f6d6e748a87a1536bf5cdad0af97b75725ffb`. O AAR foi baixado e o SHA-256
  completo conferiu:
  `cc1d41945496eb1f93abba7955a766c134c748b804ea67225ac24802db612b8b`.
- O AAR contém `.so`, `classes.jar` e o `libplayer.so` do upstream; não traz
  os headers no formato esperado pelo extrator atual. Não basta trocar o lock.
  Não empacotar o JNI/Java do Plezy no lugar do nosso por conveniência.
- **Não foi constatada incompatibilidade de ABI.** Evidência favorável:
  FFmpeg continua n8.0.1, mpv v0.41.0; os três símbolos `av_jni_set_java_vm`,
  `av_jni_set_android_app_ctx`, `av_jni_set_mediacodec_callback_class` estão no
  novo libavcodec (ELF inspecionado). A classe de callback é idêntica após
  normalizar pacote/espaços. Ainda falta implementar e validar o empacotamento
  e os headers da versão correta, preservando nosso JNI e as regras R8 da L.

## Recursos existentes que não devem ser recriados

- `track_selection_service.dart` já casa faixas por idioma/título/tipo e outros
  atributos. Auditar a persistência e os casos de troca de episódio; não começar
  outra seleção por índice.
- `sync_rule_executor.dart` já mantém N episódios não assistidos. O diálogo de
  download oferece sincronização para séries; conferir/estender temporadas e
  adicionar a estimativa, preservando posse por perfil e a fila real.
- Há políticas DV7 em `GpuVoPolicy` e bridge de conversão do Media3. Isso não
  equivale a teste físico de cada decodificador ou arquivo DV7.
- O prompt “Ainda está assistindo?” existe ligado ao temporizador. Falta a
  condição por N episódios sem interação; não substituir o prompt nem quebrar
  o comportamento do temporizador existente.

## Limite desta parada

Há tarefas independentes que podem ser feitas, como a tela de Novidades. Não
foram iniciadas após encontrar os contratos acima, porque o Caio pediu para
parar e encaminhar o diagnóstico quando uma parte travasse, em vez de improvisar.
Ainda faltam os ports, motivo da conversão, limite de episódios sem interação,
estimativa/automação de temporada, conferência física de DV7, completar/auditar
as ideias de legenda e recapitulação e Novidades escritas à mão. A existência
parcial citada acima não foi marcada como entrega integral da O.

O app foi devolvido exatamente ao código aprovado da N. Nenhum novo APK da O,
nenhum banco migrado, nenhum pacote nativo trocado. Artefatos/limites da N e da M
estão em `HANDOFF_GPT_ENTREGA_2026-10-24.md`; diagnóstico da M em
`DIAGNOSTICO_M_PIP_2026-10-26.md`.
