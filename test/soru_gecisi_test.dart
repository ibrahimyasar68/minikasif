import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/data/question_data.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/models/game_section.dart';
import 'package:mini_kasif/providers/game_provider.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:provider/provider.dart';

import 'helpers/oyun.dart';

/// Soru değişirken eski ve yeni soru üst üste görünmemeli.
///
/// Eskiden ikisi aynı anda soluyor/beliriyordu (çapraz solma): ~320 ms
/// boyunca iki soru metni iç içe görünüyordu. Şimdi önce eski söner,
/// sonra yeni belirir.
void main() {
  /// Bir widget'ın ekrandaki toplam görünürlüğü: üstündeki bütün
  /// FadeTransition ve Opacity değerlerinin çarpımı.
  double gorunurluk(WidgetTester tester, Finder hedef) {
    var sonuc = 1.0;
    for (final e
        in find
            .ancestor(of: hedef, matching: find.byType(FadeTransition))
            .evaluate()) {
      sonuc *= (e.widget as FadeTransition).opacity.value;
    }
    for (final e
        in find
            .ancestor(of: hedef, matching: find.byType(Opacity))
            .evaluate()) {
      sonuc *= (e.widget as Opacity).opacity;
    }
    return sonuc;
  }

  /// İlk soruyu doğru cevaplar ve otomatik geçişi BAŞLATIR (bitirmez).
  Future<void> gecisiBaslat(WidgetTester tester) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await bolumeGir(tester, GameSection.fruits);
    final ilk = questionsOf(GameSection.fruits).first;
    await dokun(tester, find.text(dogruEtiket(ilk)));
    // Övgü süresi dolunca sonraki soruya geçilir. pumpAndSettle değil:
    // geçişin ORTASINDA durmak istiyoruz.
    await tester.pump(GameProvider.minCelebration);
    // AnimationController saymaya bir sonraki karede başlar.
    await tester.pump();
  }

  testWidgets('Geçiş boyunca iki soru metni aynı anda görünmez', (
    tester,
  ) async {
    final sorular = questionsOf(GameSection.fruits);
    await gecisiBaslat(tester);

    final eski = find.text(sorular[0].questionText);
    final yeni = find.text(sorular[1].questionText);
    expect(eski, findsOneWidget, reason: 'geçiş başladı, eski hâlâ ağaçta');
    expect(yeni, findsOneWidget);

    var ikisiBirden = <String>[];
    var eskiSondu = false;
    var yeniGorundu = false;
    for (var ms = 0; ms <= 400; ms += 16) {
      final e = eski.evaluate().isEmpty ? 0.0 : gorunurluk(tester, eski);
      final y = yeni.evaluate().isEmpty ? 0.0 : gorunurluk(tester, yeni);
      if (e > 0.01 && y > 0.01) {
        ikisiBirden.add(
          '$ms ms: eski ${e.toStringAsFixed(2)}, '
          'yeni ${y.toStringAsFixed(2)}',
        );
      }
      if (e <= 0.01) eskiSondu = true;
      if (y > 0.99) yeniGorundu = true;
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(ikisiBirden, isEmpty, reason: 'üst üste binen kareler');
    expect(eskiSondu, isTrue);
    expect(yeniGorundu, isTrue, reason: 'yeni soru sonunda tam görünmeli');
    await tester.pumpAndSettle();
    expect(eski, findsNothing);
  });

  testWidgets('Geçiş sürerken yeni kartlara dokunulamaz', (tester) async {
    final sorular = questionsOf(GameSection.fruits);
    await gecisiBaslat(tester);

    // Yeni soru henüz görünmüyor: doğru kartına dokunmak hiçbir şey
    // yapmamalı. warnIfMissed: false, çünkü dokunuşun hedefe ULAŞMAMASI
    // tam da beklediğimiz şey.
    //
    // Aynı etiket (ör. "Muz") eski soruda da olabilir; geçiş sırasında
    // ikisi de ağaçta. Yeni sorunun kartını, sorunun anahtarıyla seçiyoruz.
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey(sorular[1].id)),
        matching: find.text(dogruEtiket(sorular[1])),
      ),
      warnIfMissed: false,
    );
    await tester.pump();
    // Ekrandaki "Aferin" yazısına bakamayız: sönmekte olan ESKİ soru hâlâ
    // ağaçta ve onun geri bildirimi "Aferin". Oyunun durumuna bakıyoruz.
    final oyun = tester
        .element(find.byKey(ValueKey(sorular[1].id)))
        .read<GameProvider>();
    expect(oyun.currentQuestion.id, sorular[1].id);
    expect(oyun.isAnswered, isFalse, reason: 'görünmeyen karta dokunuldu');
    expect(oyun.hasWrongAttempt, isFalse);

    // Geçiş bitince kartlar yine dokunulabilir.
    await tester.pumpAndSettle();
    await dokun(tester, find.text(dogruEtiket(sorular[1])));
    expect(find.text('Aferin! 🎉'), findsOneWidget);
  });
}
