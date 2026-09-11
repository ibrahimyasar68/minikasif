import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

/// Yatay ortalama testleri.
///
/// Neden gerekli?
/// Scaffold gövdeye GEVŞEK genişlik kısıtı verir (minWidth = 0).
/// Bu yüzden Column en geniş çocuğu kadar büzülüp sola yapışabilir.
/// Ekranda "içerik sola kaymış" gibi görünür ama hiçbir hata çıkmaz.
/// Sessiz bir hata olduğu için test ile korunması şart.
void main() {
  /// GENİŞ bir ekran kuruyoruz (1200x1200 logical).
  ///
  /// Neden telefon boyutu değil?
  /// Test ortamının varsayılan fontu her karakteri kare kutu olarak çizer,
  /// bu yüzden soru metni telefon genişliğinde ekranı zaten doldurur ve
  /// Column'un büzülmesi GÖRÜNMEZ - hata maskelenir.
  /// Geniş ekranda metin ekranı dolduramaz, büzülme açığa çıkar.
  void ekranAyarla(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  double ekranMerkezi(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

  /// Verilen widget'ların oluşturduğu grubun yatay merkezi.
  double grupMerkezi(WidgetTester tester, Finder finder) {
    final rects = finder.evaluate().map((e) => tester.getRect(find.byWidget(
          e.widget,
        )));
    final sol = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
    final sag = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
    return (sol + sag) / 2;
  }

  testWidgets('Soru ekranındaki kartlar yatayda ortalı', (tester) async {
    ekranAyarla(tester);
    await tester.pumpWidget(const MiniKesifApp());
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();

    expect(
      grupMerkezi(tester, find.byType(AnswerCard)),
      moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
      reason: 'kart grubu ekran merkezinde olmalı',
    );
  });

  testWidgets('Tebrik ekranındaki içerik yatayda ortalı', (tester) async {
    ekranAyarla(tester);
    await tester.pumpWidget(const MiniKesifApp());
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();

    // Bölümü bitir.
    for (final dogru in ['Elma', 'Muz', 'Portakal', 'Çilek']) {
      await tester.tap(find.text(dogru));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
    }

    // Yıldız satırı dar bir içerik: Column büzülürse en net buradan belli olur.
    expect(
      grupMerkezi(tester, find.byIcon(Icons.star)),
      moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
      reason: 'yıldızlar ekran merkezinde olmalı',
    );

    expect(
      tester.getCenter(find.text('Tekrar oyna')).dx,
      moreOrLessEquals(ekranMerkezi(tester), epsilon: 1.0),
      reason: 'buton ekran merkezinde olmalı',
    );
  });
}
