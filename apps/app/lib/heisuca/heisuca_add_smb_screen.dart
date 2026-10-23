import 'package:flutter/material.dart';
import 'heisuca_theme.dart';

/// Não solicita credenciais enquanto não existir transporte e catálogo SMB.
class HeisucaAddSmbScreen extends StatelessWidget {
  const HeisucaAddSmbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rede Local (SMB)', style: TextStyle(fontFamily: HeisucaTheme.fonteTitulo)),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.folder_shared_outlined, size: 48),
              SizedBox(height: 20),
              Text('SMB ainda não está disponível nesta versão.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text('Por enquanto, adicione a pasta de rede à biblioteca do seu servidor Jellyfin, Plex ou Emby e conecte esse servidor ao Heisuca.'),
            ],
          ),
        ),
      ),
    );
  }
}
