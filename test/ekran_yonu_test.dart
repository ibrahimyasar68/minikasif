import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ekran yönü, Android manifest'inde bilerek seçilmiş bir ayar.
///
/// Uygulama telefonun "otomatik döndür" ayarına bakmadan, yalnızca
/// telefonun tutuluş şekline göre dönmeli (dikey ve iki yatay yön).
/// Manifest'i Dart kodu okuyamadığı için bu kararı test koruyor.
void main() {
  test('Uygulama döndürme kilidine bakmadan sensörle döner', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    final yon = RegExp(
      r'android:screenOrientation="([^"]*)"',
    ).allMatches(manifest).map((m) => m.group(1)).toList();

    expect(
      yon,
      ['sensor'],
      reason:
          'MainActivity\'de tek bir screenOrientation="sensor" olmalı. '
          '"fullSensor" ters dikeye de döner; "user"/"fullUser" ise '
          'telefonun döndürme kilidine uyar.',
    );
  });
}
