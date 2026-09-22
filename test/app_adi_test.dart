import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/app_info.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/services/audio_service.dart';

/// Uygulama adı iki ayrı dünyada yaşıyor: Dart tarafında [appName], Android
/// tarafında AndroidManifest.xml'deki `android:label`. Manifest Dart sabitini
/// okuyamadığı için ikisi elle eşit tutulmak zorunda. Bir zamanlar ayrışmıştı
/// (launcher "MiniKasif", ekran "MiniKasif"); bu testler tekrarını önlüyor.
void main() {
  test('Android launcher adı appName ile aynı', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    final etiket = RegExp(r'android:label="([^"]*)"').firstMatch(manifest);
    expect(etiket, isNotNull, reason: 'Manifest içinde android:label yok');

    expect(
      etiket!.group(1),
      appName,
      reason:
          'Launcher adı ile uygulama içi ad ayrıştı. '
          'AndroidManifest.xml içindeki android:label değerini "$appName" yap.',
    );
  });

  testWidgets('Açılış ekranındaki başlık appName', (tester) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));

    expect(find.text(appName), findsOneWidget);
  });
}
