import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/services/audio_service.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

import 'helpers/oyun.dart';

/// Yatay ortalama testleri.
///
/// Neden gerekli?
/// Scaffold gövdeye GEVŞEK genişlik kısıtı verir (minWidth = 0).
/// Bu yüzden Column en geniş çocuğu kadar büzülüp sola yapışabilir.
/// Ekranda "içerik sola kaymış" gibi görünür ama hiçbir hata çıkmaz.
/// Sessiz bir hata olduğu için test ile korunması şart.
void main() {
  /// GENİŞ bir ekran kuruyoruz (1200x1600 logical).
  ///
  /// Neden telefon boyutu değil?
  /// Test ortamının varsayılan fontu her karakteri kare kutu olarak çizer,
  /// bu yüzden soru metni telefon genişliğinde ekranı zaten doldurur ve
  /// Column'un büzülmesi GÖRÜNMEZ - hata maskelenir.
  /// Geniş ekranda metin ekranı dolduramaz, büzülme açığa çıkar.
  ///
  /// Neden kare değil? Genişliği yüksekliğinden büyük alan YATAY düzene
  /// geçer (bkz. test/yatay_ekran_test.dart). Burada dikey düzen ölçülüyor.
  void ekranAyarla(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  double ekranMerkezi(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

  /// Verilen widget'ların oluşturduğu grubun yatay merkezi.
  double grupMerkezi(WidgetTester tester, Finder finder) {
    final rects = finder.evaluate().map(
      (e) => tester.getRect(find.byWidget(e.widget)),
    );
    final sol = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
    final sag = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
    return (sol + sag) / 2;
  }

  // 2, 3 ve 4 seçenekli düzenlerin HEPSİ ortalı olmalı.
  testWidgets('Her soruda kartlar yatayda ortalı', (tester) async {
    ekranAyarla(tester);
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));

    for (final bolum in GameSection.values) {
      await bolumeGir(tester, bolum);
      await bolumuOyna(
        tester,
        bolum,
        sorudaIken: (soru) async {
          expect(
            grupMerkezi(tester, find.byType(AnswerCard)),
            moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
            reason: '${soru.id}: kart grubu ekran merkezinde olmalı',
          );
        },
      );
      await dokun(tester, find.text('Ana sayfa'));
    }
  });

  testWidgets('Tebrik ekranındaki içerik yatayda ortalı', (tester) async {
    ekranAyarla(tester);
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await bolumeGir(tester, GameSection.fruits);
    await bolumuOyna(tester, GameSection.fruits);

    // Yıldız satırı dar bir içerik: Column büzülürse en net buradan belli olur.
    expect(
      grupMerkezi(tester, find.byIcon(Icons.star)),
      moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
      reason: 'yıldızlar ekran merkezinde olmalı',
    );

    // Butonun KENDİSİNİ ölçüyoruz, içindeki yazıyı değil.
    // Buton içinde emoji solda + yazı sağda olduğu için yazının merkezi
    // doğal olarak butonun merkezinden farklı.
    expect(
      tester
          .getRect(
            find
                .ancestor(
                  of: find.text('Tekrar oyna'),
                  matching: find.byType(ElevatedButton),
                )
                .first,
          )
          .center
          .dx,
      moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
      reason: 'buton ekran merkezinde olmalı',
    );
  });
}
