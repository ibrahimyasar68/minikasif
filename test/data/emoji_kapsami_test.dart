import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Uygulamadaki her emoji eski cihazda (Android 8) görünmeli.
///
/// Neden? Gerçek cihazda görüldü: 🧸 (Unicode 11, 2018) Samsung Galaxy A7
/// (Android 8) fontunda YOK; çocuk boş bir kart görüyordu. Emülatör
/// (Android 14) bunu gösteremez, testler de gösteremezdi.
///
/// test/fixtures/android8_emoji_kapsami.txt o telefonun emoji fontundan
/// üretildi. Bu test lib/ altındaki TÜM kaynak kodu tarar (soru verisi
/// ve ekranlardaki emojiler) ve her birinin o fontta olduğunu doğrular.
/// Yeni bir emoji eklenirse ve eski cihazda yoksa bu test kırılır.
void main() {
  Set<int> kapsam() {
    final kodlar = <int>{};
    for (final satir in File(
      'test/fixtures/android8_emoji_kapsami.txt',
    ).readAsLinesSync()) {
      if (satir.startsWith('#') || satir.trim().isEmpty) continue;
      final parca = satir.split('-');
      final bas = int.parse(parca.first, radix: 16);
      final son = int.parse(parca.last, radix: 16);
      for (var k = bas; k <= son; k++) {
        kodlar.add(k);
      }
    }
    return kodlar;
  }

  /// Emoji aralığındaki karakter mi? (Türkçe harfler, noktalama değil.)
  /// FE0F (emoji biçimi seçici) ve 200D (birleştirici) görünmez
  /// yardımcı karakterler; fontta aranmazlar.
  bool emojiMi(int k) => k >= 0x2190 && k != 0xFE0F && k != 0x200D;

  test('lib/ altındaki her emoji Android 8 emoji fontunda var', () {
    final destekli = kapsam();
    expect(destekli.length, greaterThan(1000), reason: 'fixture okunamadı');

    final eksikler = <String>[];
    final dosyalar = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final dosya in dosyalar) {
      final satirlar = dosya.readAsLinesSync();
      for (var i = 0; i < satirlar.length; i++) {
        final satir = satirlar[i];
        if (satir.trimLeft().startsWith('//')) continue; // yorumlar hariç
        for (final k in satir.runes.where(emojiMi)) {
          if (!destekli.contains(k)) {
            eksikler.add(
              '${String.fromCharCode(k)} '
              '(U+${k.toRadixString(16).toUpperCase()}) '
              '${dosya.path}:${i + 1}',
            );
          }
        }
      }
    }

    expect(
      eksikler,
      isEmpty,
      reason:
          'Bu emojiler eski cihazda görünmez (boş kart). Daha eski bir '
          'emoji seçin.',
    );
  });
}
