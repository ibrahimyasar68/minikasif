import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';

void main() {
  /// Verilen bölümü açıp sonuna kadar doğru oynar.
  Future<void> bolumuBitir(
    WidgetTester tester,
    String bolumAdi,
    List<String> dogrular,
  ) async {
    await tester.tap(find.text(bolumAdi));
    await tester.pumpAndSettle();
    for (final d in dogrular) {
      await tester.tap(find.text(d));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> meyveleriBitir(WidgetTester tester) => bolumuBitir(
    tester,
    'Meyveler',
    const ['Elma', 'Muz', 'Portakal', 'Çilek'],
  );

  testWidgets('Bölüm bitince sonuç sayfası açılır', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    expect(find.text('Tebrikler!'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.textContaining('ilk denemede bildin'), findsOneWidget);

    // Artık soru ekranında değiliz.
    expect(find.text('Kırmızı elmayı bul'), findsNothing);
  });

  testWidgets('Son bölüm değilse sonraki bölüm butonu görünür', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    expect(find.text(GameSection.animals.title), findsOneWidget);
    expect(find.text('Ana sayfa'), findsOneWidget);
  });

  // Son bölümde "sonraki" diye bir şey yok; buton hiç oluşturulmamalı.
  testWidgets('Son bölümde sonraki bölüm butonu yok', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await bolumuBitir(tester, 'Nesneler', const [
      'Top',
      'Araba',
      'Balon',
      'Kitap',
    ]);

    expect(find.text('Tebrikler!'), findsOneWidget);

    // DİKKAT: find.text(s.title) kullanılamaz - AppBar başlığında
    // mevcut bölümün adı yazıyor ve bu doğru davranış.
    // Bölüm adı taşıyan bir BUTON olmadığını kontrol ediyoruz.
    for (final s in GameSection.values) {
      expect(
        find.widgetWithText(ElevatedButton, s.title),
        findsNothing,
        reason: s.title,
      );
    }
  });

  testWidgets('Sonraki bölüm butonu o bölümü başlatır', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    await tester.tap(find.text(GameSection.animals.title));
    await tester.pumpAndSettle();

    expect(find.text('Soru 1 / 4'), findsOneWidget);
    expect(find.text('Kediyi bul'), findsOneWidget);
  });

  testWidgets('Tekrar oyna aynı bölümü baştan başlatır', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    await tester.tap(find.text('Tekrar oyna'));
    await tester.pumpAndSettle();

    expect(find.text('Soru 1 / 4'), findsOneWidget);
    expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
  });

  testWidgets('Ana sayfa butonu bölüm seçimine döner', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    // Test penceresi (800x600) küçük; buton kaydırma alanının altında
    // kalabiliyor. ensureVisible önce görünür hale getirir.
    await tester.ensureVisible(find.text('Ana sayfa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana sayfa'));
    await tester.pumpAndSettle();

    expect(find.text('Mini Keşif'), findsOneWidget);
    for (final s in GameSection.values) {
      expect(find.text(s.title), findsOneWidget, reason: s.title);
    }
  });

  // pushReplacement kullandık: sonuç sayfasından geri tuşu bitmiş
  // bir soruya dönmemeli.
  testWidgets('Sonuç sayfasında geri oku yok', (tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await meyveleriBitir(tester);

    expect(find.byType(BackButton), findsNothing);
  });
}
