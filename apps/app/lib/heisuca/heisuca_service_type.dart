import 'package:flutter/material.dart';

/// Tipos de fontes de mídia suportadas pelo Heisuca
enum HeisucaServiceType {
  jellyfin(
    nome: 'Jellyfin / Emby',
    descricao: 'Servidor completo com suporte a múltiplos usuários, pedidos e syncplay.',
    icone: Icons.dns_rounded,
    badge: 'Recomendado',
  ),
  plex(
    nome: 'Plex Media Server',
    descricao: 'Conexão direta ou via conta Plex com catálogo e bibliotecas.',
    icone: Icons.play_circle_outline_rounded,
    badge: 'Popular',
  ),
  webdav(
    nome: 'WebDAV / Nuvem',
    descricao: 'Teste de acesso ao servidor; catálogo e reprodução ainda indisponíveis.',
    icone: Icons.cloud_outlined,
    badge: 'Em desenvolvimento',
  ),
  smb(
    nome: 'Rede Local / SMB',
    descricao: 'Acesso direto a pastas de rede ainda indisponível nesta versão.',
    icone: Icons.folder_shared_outlined,
    badge: 'Em desenvolvimento',
  ),
  local(
    nome: 'Arquivos Locais',
    descricao: 'Vídeos na memória interna, cartão SD ou pen drive USB OTG.',
    icone: Icons.smartphone_rounded,
    badge: 'Offline',
  );

  final String nome;
  final String descricao;
  final IconData icone;
  final String badge;

  const HeisucaServiceType({
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.badge,
  });
}

