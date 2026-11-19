import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heisuca/desktop/platform/desktop_connection_vault.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel=MethodChannel('heisuca/linux-vault-test');
  final messenger=TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(()=>messenger.setMockMethodCallHandler(channel,null));
  test('keyring ausente usa somente memória e sinaliza sessão temporária',() async {
    var writes=0;
    messenger.setMockMethodCallHandler(channel,(call)async{if(call.method=='read')throw PlatformException(code:'keyringUnavailable');writes++;return true;});
    final vault=PlatformLinuxVault(channel:channel);expect(await vault.read(),isEmpty);expect(vault.persistent,isFalse);
    await vault.write([{'fixture':'temporario'}]);expect(await vault.read(),[{'fixture':'temporario'}]);expect(writes,0);
  });
  test('keyring bloqueado não vira cofre vazio nem sobrescreve dado',() async {
    var writes=0;
    messenger.setMockMethodCallHandler(channel,(call)async{if(call.method=='read')throw PlatformException(code:'keyringFailed',message:'conteudo_privado');writes++;return true;});
    final vault=PlatformLinuxVault(channel:channel);
    await expectLater(vault.read(),throwsA(isA<DesktopVaultException>()));
    await expectLater(vault.write([]),throwsA(isA<DesktopVaultException>()));expect(writes,0);expect(vault.persistent,isTrue);
  });
  test('JSON inválido não é convertido em cofre vazio',() async {
    var writes=0;
    messenger.setMockMethodCallHandler(channel,(call)async{if(call.method=='read')return Uint8List.fromList(utf8.encode('invalido'));writes++;return true;});
    final vault=PlatformLinuxVault(channel:channel);await expectLater(vault.read(),throwsA(isA<DesktopVaultException>()));
    await expectLater(vault.write([]),throwsA(isA<DesktopVaultException>()));expect(writes,0);
  });
  test('cofre Linux restaura por nova instância e congela escrita enfileirada',()async{
    Uint8List? stored;
    messenger.setMockMethodCallHandler(channel,(call)async{if(call.method=='read')return stored==null?null:Uint8List.fromList(stored!);stored=Uint8List.fromList(call.arguments as Uint8List);return true;});
    final vault=PlatformLinuxVault(channel:channel);await vault.read();
    final entries=<Map<String,dynamic>>[{'fixture':'original'}];final write=vault.write(entries);entries.first['fixture']='alterado';await write;
    expect(await PlatformLinuxVault(channel:channel).read(),[{'fixture':'original'}]);expect(vault.persistent,isTrue);
  });
  test('serviço perdido depois de leitura válida não rebaixa para memória',()async{
    var reads=0;
    messenger.setMockMethodCallHandler(channel,(call)async{if(reads++==0)return null;throw PlatformException(code:'keyringUnavailable');});
    final vault=PlatformLinuxVault(channel:channel);await vault.read();await expectLater(vault.read(),throwsA(isA<DesktopVaultException>()));expect(vault.persistent,isTrue);
  });
  test('primeira leitura bloqueada seguida de ausência não rebaixa para memória',()async{
    var calls=0;
    messenger.setMockMethodCallHandler(channel,(call)async{throw PlatformException(code:calls++==0?'keyringFailed':'keyringUnavailable');});
    final vault=PlatformLinuxVault(channel:channel);
    await expectLater(vault.read(),throwsA(isA<DesktopVaultException>()));
    await expectLater(vault.read(),throwsA(isA<DesktopVaultException>()));
    expect(vault.persistent,isTrue);
  });

}
