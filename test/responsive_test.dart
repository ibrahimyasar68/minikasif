import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

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

  Future<void> bolumeGir(WidgetTester tester, String bolum) async {
    await tester.pumpWidget(const MiniKesifApp());
    await tester.tap(find.text(bolum));
    await tester.pumpAndSettle();
  }

  testWidgets('Küçük telefonda soru ekranı taşmıyor', (tester) async {
    // 320x480 dp - çok küçük ama gerçek bir cihaz sınıfı.
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await bolumeGir(tester, 'Meyveler');

    expect(tester.takeException(), isNull);
    expect(find.byType(AnswerCard), findsNWidgets(3));
  });

  testWidgets('Ana sayfa küçük telefonda taşmıyor', (tester) async {
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await tester.pumpWidget(const MiniKesifApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Sonuç ekranı küçük telefonda taşmıyor', (tester) async {
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await bolumeGir(tester, 'Meyveler');
    for (final d in ['Elma', 'Muz', 'Portakal', 'Çilek']) {
      await tester.ensureVisible(find.text(d));
      await tester.tap(find.text(d));
      await tester.pumpAndSettle();
      // Bu kadar küçük ekranda buton ekranın altında kalıyor;
      // kaydırma gerekiyor. Normal telefonda gerekmediğini
      // aşağıdaki test doğruluyor.
      await tester.ensureVisible(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Tebrikler!'), findsOneWidget);
  });

  testWidgets('Kartlar mevcut genişliğe sığar', (tester) async {
    ekran(tester, const Size(960, 1440), dpr: 3.0);
    await bolumeGir(tester, 'Meyveler');

    final ekranGenislik =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    for (final e in find.byType(AnswerCard).evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(r.left, greaterThanOrEqualTo(0.0));
      expect(r.right, lessThanOrEqualTo(ekranGenislik));
    }
  });

  // Hedef cihazda kaydırma GEREKMEMELİ: çocuğun devam etmek için
  // ekranı kaydırması beklenmemeli.
  testWidgets('Normal telefonda her şey kaydırmadan görünür', (tester) async {
    ekran(tester, const Size(1080, 2400));
    await bolumeGir(tester, 'Meyveler');

    final ekranYukseklik =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await tester.tap(find.text('Elma'));
    await tester.pumpAndSettle();

    final buton = tester.getRect(find.text('Devam →'));
    expect(
      buton.bottom,
      lessThan(ekranYukseklik),
      reason: 'Devam butonu kaydırmadan görünmeli',
    );
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
