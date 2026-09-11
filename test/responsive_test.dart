import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

import 'helpers/oyun.dart';

/// Farklı ekran ve yazı boyutlarında taşma olmamalı.
///
/// "RenderFlex overflowed" hatası kullanıcıda sarı-siyah çizgili bir
/// şerit olarak görünür. Testte ise exception olarak yakalanır.
void main() {
  void ekran(WidgetTester tester, Size boyut, {double dpr = 2.625}) {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }

  double genislik(WidgetTester t) =>
      t.view.physicalSize.width / t.view.devicePixelRatio;

  /// Ekrandaki tüm kartlar yatayda ekrana sığıyor mu?
  void kartlarSigiyor(WidgetTester tester, String neden) {
    final w = genislik(tester);
    for (final e in find.byType(AnswerCard).evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(r.left, greaterThanOrEqualTo(0.0), reason: neden);
      expect(r.right, lessThanOrEqualTo(w), reason: neden);
    }
  }

  testWidgets('Küçük telefonda soru ekranı taşmıyor', (tester) async {
    // 320x480 dp - çok küçük ama gerçek bir cihaz sınıfı.
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await tester.pumpWidget(const MiniKesifApp());
    await bolumeGir(tester, GameSection.fruits);

    expect(tester.takeException(), isNull);
    expect(find.byType(AnswerCard), findsNWidgets(3));
  });

  testWidgets('Ana sayfa küçük telefonda taşmıyor', (tester) async {
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await tester.pumpWidget(const MiniKesifApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // 30 sorunun HEPSİ (2, 3 ve 4 seçenekli) ve üç sonuç ekranı
  // küçük telefonda denenir.
  testWidgets('Küçük telefonda hiçbir soru ve sonuç ekranı taşmıyor', (
    tester,
  ) async {
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await tester.pumpWidget(const MiniKesifApp());

    for (final bolum in GameSection.values) {
      await bolumeGir(tester, bolum);
      await bolumuOyna(
        tester,
        bolum,
        sorudaIken: (soru) async {
          expect(tester.takeException(), isNull, reason: soru.id);
          kartlarSigiyor(tester, soru.id);
        },
      );
      expect(tester.takeException(), isNull, reason: '${bolum.title} sonuç');
      expect(find.text('Tebrikler!'), findsOneWidget);
      await dokun(tester, find.text('Ana sayfa'));
    }
  });

  // Hedef cihazda HİÇBİR soruda kaydırma gerekmemeli: çocuğun devam
  // etmek için ekranı kaydırması beklenmemeli.
  testWidgets('Hedef telefonda hiçbir soru kaydırma gerektirmiyor', (
    tester,
  ) async {
    ekran(tester, const Size(1080, 2400)); // Pixel 6
    // Gerçek cihazdaki durum çubuğu ve alt hareket çubuğu (~24 dp).
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    final sinir = (2400 - 63) / 2.625; // alt çubuğun üst kenarı

    await tester.pumpWidget(const MiniKesifApp());
    await tester.pumpAndSettle();

    for (final bolum in GameSection.values) {
      await tester.tap(find.text(bolum.title));
      await tester.pumpAndSettle();

      for (final soru in questionsOf(bolum)) {
        // DİKKAT: burada ensureVisible KULLANMIYORUZ. Kaydırma gerekirse
        // ensureVisible bunu sessizce yapar ve sorunu gizlerdi.
        await tester.tap(find.text(dogruEtiket(soru)));
        await tester.pumpAndSettle();

        for (final e in find.byType(AnswerCard).evaluate()) {
          expect(
            tester.getRect(find.byWidget(e.widget)).bottom,
            lessThan(sinir),
            reason: '${soru.id}: kart kaydırmadan görünmeli',
          );
        }
        final buton = find.textContaining(RegExp('Devam|Bitir'));
        expect(
          tester.getRect(buton).bottom,
          lessThan(sinir),
          reason: '${soru.id}: buton kaydırmadan görünmeli',
        );

        await tester.tap(buton);
        await tester.pumpAndSettle();
      }
      await dokun(tester, find.text('Ana sayfa'));
    }
    expect(tester.takeException(), isNull);
  });

  // Cihazda "büyük yazı" erişilebilirlik ayarı açık olabilir.
  testWidgets('Yazı boyutu 2 katına çıkınca taşma yok', (tester) async {
    ekran(tester, const Size(1080, 2400));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MiniKesifApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'ana sayfa');

    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'soru ekranı');
  });
}
