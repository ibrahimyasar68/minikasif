import 'dart:io';

import 'package:flutter/services.dart';

/// Testlerde gerçek Roboto fontunu yükler.
///
/// Neden? Test ortamının varsayılan fontu her karakteri kare bir kutu
/// olarak çizer; metin cihazdakinden çok daha geniş ölçülür ve daha çok
/// satıra bölünür. Yerleşimi (bir şey ekrana sığıyor mu?) ölçen testler
/// bu yüzden cihazdakinden farklı sonuç verir.
///
/// Font dosyaları Flutter SDK'nın içinde duruyor; `flutter test`
/// FLUTTER_ROOT ortam değişkenini tanımlıyor.
///
/// Gerçek bir motor çağrısı yaptığı için testWidgets içinde
/// `tester.runAsync(gercekFontuYukle)` ile çağrılmalı.
/// Font bulunamazsa false döner.
Future<bool> gercekFontuYukle() async {
  final kok = Platform.environment['FLUTTER_ROOT'];
  if (kok == null) return false;
  final klasor = Directory('$kok/bin/cache/artifacts/material_fonts');
  if (!klasor.existsSync()) return false;

  final roboto = FontLoader('Roboto');
  var sayi = 0;
  for (final dosya in klasor.listSync().whereType<File>()) {
    final ad = dosya.uri.pathSegments.last;
    if (ad.startsWith('Roboto-') &&
        ad.endsWith('.ttf') &&
        !ad.contains('Italic')) {
      final bytes = dosya.readAsBytesSync();
      roboto.addFont(Future.value(ByteData.view(bytes.buffer)));
      sayi++;
    }
  }
  if (sayi == 0) return false;
  await roboto.load();
  return true;
}
