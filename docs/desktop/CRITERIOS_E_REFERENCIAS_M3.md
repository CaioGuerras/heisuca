# Critérios de qualidade e reaproveitamento — Windows

A ambição é entregar uma experiência de referência. “Melhor que todos” não é um resultado mensurável de uma lista de features: a entrega precisa de navegação consistente, estabilidade, acessibilidade e provas em uso real. A marca/tokens de09/11 e15/11 prevalecem sobre documentos antigos que ainda citam títulos Sora ou selo roxo.

## Fonte e decisão

| Fonte primária consultada em18/11 | Uso neste trabalho |
|---|---|
| [Inno: PrivilegesRequired](https://jrsoftware.org/inno-setup/documentation/topic_setup_privilegesrequired.htm) | Reaproveitar o fluxo por usuário (`lowest`), preservando detecção HKCU/HKLM já resolvida no CGFLIX. |
| [Inno: AppId](https://jrsoftware.org/inno-setup/documentation/topic_setup_appid.htm) | Identidade Heisuca fixa e diferente; teste não deixa o novo instalador assumir o GUID CGFLIX. |
| [mpv.net manual](https://github.com/mpvnet-player/mpv.net/blob/main/docs/manual.md) | Comparar uso sem instalação, configuração, abertura pelo Explorer e comportamento desktop. A referência orienta requisitos; não foi copiado código. |
| [Jellyfin Desktop: mapa de teclado](https://github.com/jellyfin/jellyfin-desktop/blob/master/resources/inputmaps/keyboard.json) | Teclado é parte da experiência principal. Atalhos não podem capturar edição nem impedir foco dos controles. |
| [Jellyfin: regressão de teclado](https://github.com/jellyfin/jellyfin-web/issues/7936) | Caso concreto para testar retorno de foco após navegação; uma issue não representa toda a opinião dos usuários. |
| [Microsoft: acessibilidade](https://learn.microsoft.com/en-us/windows/apps/design/accessibility/accessibility-overview) | Foco, escala, semântica, teclado e redução de movimento como critérios verificáveis. |
| docs/marca_2026-11-09/LEIA.md + pilares + apps/site Heisuca | Reusar TemaHeisuca, CgflixPalette derivada dos mesmos tokens, HeisucaLogo/ColorMapper e Toque. Inter, selo vermelho, botões neutros; player Sumi. |

As oito frentes de pesquisa anteriores permanecem em desktop/pesquisas/2026-11-18 e nos documentos do M1. Não repetir volume de pesquisa sem uma lacuna concreta a resolver.

## CGFLIX como base

Mantidos os clientes de mídia, libmpv, runtime nativo/engine DComp fixados e mecanismo de criação do instalador. O gerador conserva defaults CGFLIX e inclui seleção explícita de produto Heisuca. UI nova reutiliza componentes e paletas aprovados, sem reaproveitar marca antiga. Nada de transformar o ZIP em substituto silencioso do instalador que já existia.

## Critérios de aceite observáveis

- Mesmas cores/papéis nos três temas; botão principal neutro; texto pequeno com contraste4,5; arte preserva proporção.
- Teclado e texto200% sem overflow; reduzir movimento; campos/modais mantêm edição; marca SVG com mapper oficial.
- Abrir sem conta; conectar bibliotecas; escolher fonte/versão/episódio; posição/áudio/legendas reais.
- Histórico aceita só arquivo local e pode ser limpo sem remover vídeo; conexão remota nunca vai para esse JSON.
- Arrastar um vídeo abre a mídia; arrastar SRT/ASS/VTT atua na legenda do vídeo, não troca a fonte.
- Abrir novo arquivo com app já aberto mantém uma instância. Janela ainda oculta não pode causar descarte silencioso.
- Instalar/atualizar/desinstalar testados; aplicativos CGFLIX e dados de usuário preservados. Link/atalho não toma associação padrão.
- Captura do executável mostra vídeo em movimento; captura de tela vazia não prova reprodução. Medidas do runner não certificam outro PC nem comparam desempenho de concorrentes.

## Resposta à auditoria independente

Gemini09/Flash revisou preferências, root/encerramento, IPC e trecho do instalador (pesquisa03-audit.log). Confirmou guardas do histórico e serialização. Apontou corrida da janela oculta: o sender agora repete a procura enquanto aguarda o mutex, e o CI esconde a janela por700ms antes de repassar outro arquivo. Suspeita sobre GUID foi resolvida pela leitura do código completo (`AppGuid` condicional) e pelos contratos/coexistência aprovados no CI751bfaed. O parecer não recebeu o template integral, então não é prova de GUID incorreto. Encerramento forçado pode impedir flush: é limite de processo, não garantia de retenção após perda de energia. Múltiplos arquivos não são apresentados como fila nesta etapa.

Os primeiros pedidos de geração Gemini06/07 expiraram sem resultado; não foram contabilizados como implementação ou aprovação. Código integrado e testes foram auditados pela Jocasta. A prova final é o CI da ponta, e homologação física permanece separada.
