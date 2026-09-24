import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ekrana çizilen her emoji, uygulamaya GÖMÜLÜ emoji fontunda olmalı.
///
/// Emojiler artık telefonun fontundan değil, uygulamayla birlikte gelen
/// Noto Color Emoji altkümesinden çiziliyor (bkz. tool/emoji_fontu_uret.py).
/// Font yalnızca o an kullanılan emojileri içerdiği için, yeni bir emoji
/// eklenip font yeniden üretilmezse o emoji BOŞ KUTU olarak çıkar.
/// Bu test tam olarak onu yakalar.
///
/// Kapsam listesi fontun kendisinden üretiliyor
/// (test/fixtures/emoji_fontu_kapsami.txt).
void main() {
  /// Emoji sayılan karakterler. Türkçe harfler ve noktalama değil.
  /// FE0F (biçim seçici) ve 200D (birleştirici) görünmez yardımcılar.
  bool emojiMi(int k) => k >= 0x2190 && k != 0xFE0F && k != 0x200D;

  /// Fontun kapsadığı kod noktaları.
  Set<int> kapsam() {
    final dosya = File('test/fixtures/emoji_fontu_kapsami.txt');
    return dosya
        .readAsLinesSync()
        .where((s) => s.isNotEmpty && !s.startsWith('#'))
        .map((s) => int.parse(s.trim(), radix: 16))
        .toSet();
  }

  /// lib/ altında EKRANA ÇİZİLEN emojiler: dosya, satır ve karakter.
  ///
  /// Yorumlar sayılmaz. Yorumdaki emoji kullanıcıya gösterilmiyor; fontta
  /// yer kaplaması gereksiz (ör. kodu anlatan bir yorumdaki 🔊).
  List<(String, int, int)> cizilenEmojiler() {
    final bulunan = <(String, int, int)>[];
    final dosyalar = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final dosya in dosyalar) {
      final satirlar = dosya.readAsLinesSync();
      for (var i = 0; i < satirlar.length; i++) {
        final satir = satirlar[i];
        if (satir.trimLeft().startsWith('//')) continue;
        // Satır sonundaki yorumu at: "Text('🍎'), // elma" -> "Text('🍎'),"
        final kod = satir.split(RegExp(r'\s//\s')).first;
        for (final k in kod.runes.where(emojiMi)) {
          bulunan.add((dosya.path, i + 1, k));
        }
      }
    }
    return bulunan;
  }

  test('Çizilen her emoji gömülü fontta var', () {
    final fontta = kapsam();
    expect(fontta, isNotEmpty, reason: 'kapsam dosyası okunamadı');

    final eksikler = <String>{};
    for (final (yol, satir, kod) in cizilenEmojiler()) {
      if (!fontta.contains(kod)) {
        eksikler.add(
          '${String.fromCharCode(kod)} '
          '(U+${kod.toRadixString(16).toUpperCase()}) $yol:$satir',
        );
      }
    }

    expect(
      eksikler,
      isEmpty,
      reason:
          'Bu emojiler gömülü fontta yok; telefonda boş kutu görünürler.\n'
          'Fontu yeniden üretin:\n'
          '  python3 tool/emoji_fontu_uret.py <NotoColorEmoji.ttf>\n'
          '(kaynak fontun nasıl indirileceği betiğin başında yazılı)',
    );
  });

  test('Font ve lisansı pubspec.yaml ile birlikte geliyor', () {
    final font = File('assets/fonts/NotoColorEmoji-subset.ttf');
    final lisans = File('assets/fonts/NotoColorEmoji-OFL.txt');
    expect(font.existsSync(), isTrue, reason: font.path);
    expect(lisans.existsSync(), isTrue, reason: lisans.path);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: NotoColorEmoji'));
    expect(pubspec, contains('asset: ${font.path}'));
    // OFL, lisans metninin fontla BİRLİKTE dağıtılmasını şart koşuyor.
    expect(pubspec, contains('- ${lisans.path}'));
  });
}
