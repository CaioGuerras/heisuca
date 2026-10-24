import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais; a confirmação vem exclusivamente da interface protegida do Android.
class HeisucaSecurity extends ChangeNotifier {
  HeisucaSecurity._();
  static final instance = HeisucaSecurity._();
  static const channel = MethodChannel('app.heisuca/security');
  SharedPreferences? _prefs;
  bool get appLocked => _prefs?.getBool('heisuca.security.app') ?? false;
  bool kidsEnabled(String parent) => _prefs?.getBool('heisuca.security.kids.$parent') ?? false;
  Future<void> load() async { _prefs = await SharedPreferences.getInstance(); }
  Future<bool> available({bool deviceCredential = false}) async {
    try { return await channel.invokeMethod<bool>('available', {'deviceCredential': deviceCredential}) ?? false; } on PlatformException { return false; } on MissingPluginException { return false; }
  }
  Future<bool> authenticate(String reason, {bool deviceCredential = false}) async {
    try { return await channel.invokeMethod<bool>('authenticate', {'reason': reason, 'deviceCredential': deviceCredential}) ?? false; }
    on PlatformException { return false; } on MissingPluginException { return false; }
  }
  Future<void> setAppLock(bool value) async { _prefs ??= await SharedPreferences.getInstance(); await _prefs!.setBool('heisuca.security.app', value); notifyListeners(); }
  Future<void> setKids(String parent, bool value) async { _prefs ??= await SharedPreferences.getInstance(); await _prefs!.setBool('heisuca.security.kids.$parent', value); notifyListeners(); }
}

class HeisucaAppLock extends StatefulWidget {
  const HeisucaAppLock({super.key, required this.child});
  final Widget child;
  @override State<HeisucaAppLock> createState() => _HeisucaAppLockState();
}
class _HeisucaAppLockState extends State<HeisucaAppLock> with WidgetsBindingObserver {
  final _security = HeisucaSecurity.instance;
  late bool _locked = _security.appLocked;
  bool _busy = false;
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _security.addListener(_changed);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock()); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _security.removeListener(_changed); super.dispose(); }
  void _changed() { if (!_security.appLocked && mounted) setState(() => _locked = false); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_busy && _security.appLocked) setState(() => _locked = true);
  }
  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final ok = await _security.authenticate('Desbloquear o Heisuca', deviceCredential: true);
    if (mounted) setState(() { _busy = false; if (ok) _locked = false; });
  }
  @override Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    Offstage(offstage: _locked, child: TickerMode(enabled: !_locked, child: widget.child)),
    if (_locked) Material(color: Theme.of(context).colorScheme.surface, child: SafeArea(child: Center(child: Column(
      mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.lock_outline, size: 48), const SizedBox(height: 16),
      const Text('Heisuca bloqueado'), const SizedBox(height: 16),
      FilledButton.icon(onPressed: _busy ? null : _unlock, icon: const Icon(Icons.fingerprint), label: const Text('Desbloquear')),
      const Padding(padding: EdgeInsets.all(24), child: Text('Use a biometria ou a credencial do aparelho.', textAlign: TextAlign.center)),
    ])))),
  ]);
}

class HeisucaSecurityScreen extends StatefulWidget {
  const HeisucaSecurityScreen({super.key, required this.parentId});
  final String parentId;
  @override State<HeisucaSecurityScreen> createState() => _HeisucaSecurityScreenState();
}
class _HeisucaSecurityScreenState extends State<HeisucaSecurityScreen> {
  final _security = HeisucaSecurity.instance;
  bool _available = false, _appAvailable = false, _busy = false;
  @override void initState() { super.initState(); _security.available().then((v) { if (mounted) setState(() => _available = v); }); _security.available(deviceCredential: true).then((v) { if (mounted) setState(() => _appAvailable = v); }); }
  Future<void> _change(bool value, bool app) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _security.authenticate('Confirmar alteração da proteção', deviceCredential: app);
    if (ok) { if (app) await _security.setAppLock(value); else await _security.setKids(widget.parentId, value); }
    if (mounted) setState(() => _busy = false);
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Segurança e biometria')),
    body: ListView(children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Usa as biometrias cadastradas no Android. Ative a saída infantil por biometria apenas se as biometrias cadastradas forem dos responsáveis. O PIN infantil continua disponível.')),
      if (!_available) const ListTile(title: Text('Cadastre uma biometria compatível nas configurações do Android.')),
      SwitchListTile(title: const Text('Bloquear o app'), subtitle: const Text('Ao abrir e ao voltar do segundo plano. Requer Android 10+; permite a credencial do aparelho como alternativa.'),
        value: _security.appLocked, onChanged: _busy || (!_appAvailable && !_security.appLocked) ? null : (v) => _change(v, true)),
      SwitchListTile(title: const Text('Biometria para sair do modo infantil'), value: _security.kidsEnabled(widget.parentId),
        onChanged: _busy || !_available ? null : (v) => _change(v, false)),
    ]));
}
