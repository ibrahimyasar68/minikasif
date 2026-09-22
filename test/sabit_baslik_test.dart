import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/models/game_section.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:mini_kasif/widgets/answer_grid.dart';

import 'helpers/gercek_font.dart';
import 'helpers/oyun.dart';

/// Soru başlığı ve kart alanı her soruda ekranın AYNI yerinde durmalı.
///
/// Eskiden kart alanı seçenek sayısına göre (1 veya 2 sıra) değişiyordu;
/// içerik dikey ortalandığı için başlık sorudan soruya kayıyordu.
///
/// Gerçek font şart: test fontu başlıkları yanlışlıkla iki satıra bölüyor
/// ve ölçümü bozuyordu (bkz. helpers/gercek_font.dart).
void main() {
  testWidgets('Başlık ve kart alanı 30 sorunun hepsinde aynı yükseklikte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400); // Pixel 6
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.reset);
    expect(await tester.runAsync(gercekFontuYukle), isTrue);

    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();

    final baslikTepe = <String, double>{};
    final alanTepe = <String, double>{};
    for (final bolum in GameSection.values) {
      await bolumeGir(tester, bolum);
      await bolumuOyna(
        tester,
        bolum,
        sorudaIken: (soru) async {
          baslikTepe[soru.id] = tester
              .getRect(find.text(soru.questionText))
              .top;
          alanTepe[soru.id] = tester.getRect(find.byType(AnswerGrid)).top;
        },
      );
      await dokun(tester, find.text('Ana sayfa'));
    }

    expect(baslikTepe, hasLength(30));
    final ilkBaslik = baslikTepe.values.first;
    final ilkAlan = alanTepe.values.first;
    for (final id in baslikTepe.keys) {
      expect(
        baslikTepe[id],
        moreOrLessEquals(ilkBaslik, epsilon: 0.5),
        reason: '$id: başlık kaymamalı',
      );
      expect(
        alanTepe[id],
        moreOrLessEquals(ilkAlan, epsilon: 0.5),
        reason: '$id: kart alanı kaymamalı',
      );
    }
  });
}
