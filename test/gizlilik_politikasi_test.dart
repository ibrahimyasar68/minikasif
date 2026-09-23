import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/app_info.dart';

/// Gizlilik politikası Play Store'da yayınlanacak bir belge. Uygulamanın
/// Ayarlar > Hakkında bölümündeki bilgilerle çelişmemeli.
void main() {
  final politika = File('gizlilik_politikasi.md').readAsStringSync();

  test('İletişim adresi uygulamadakiyle aynı', () {
    expect(politika, contains(contactEmail));

    // Belgede başka bir e-posta adresi kalmamalı (eski/yanlış adres).
    final adresler = RegExp(
      r'[\w.+-]+@[\w-]+\.[\w.]+',
    ).allMatches(politika).map((m) => m.group(0)).toSet();
    expect(adresler, {contactEmail});
  });

  test('Doldurulmamış yer tutucu kalmadı', () {
    // [TARİH], [İLETİŞİM E-POSTASI] gibi büyük harfli köşeli parantezler.
    final kalan = RegExp(
      r'\[[A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ \-]*\]',
    ).allMatches(politika).map((m) => m.group(0)).toList();
    expect(kalan, isEmpty);
  });

  test('Uygulama ve geliştirici adı doğru', () {
    expect(politika, contains(appName));
    expect(politika, contains(developerName));
  });
}
