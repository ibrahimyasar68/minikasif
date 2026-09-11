import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/services/audio_service.dart';
import 'package:mini_kesif/models/game_section.dart';

import 'helpers/oyun.dart';

void main() {
  /// Uygulamayı açar, bölüme girer ve sonuna kadar doğru oynar.
  Future<void> bolumuBitir(WidgetTester tester, GameSection bolum) async {
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await bolumeGir(tester, bolum);
    await bolumuOyna(tester, bolum);
  }

  testWidgets('Bölüm bitince sonuç sayfası açılır', (tester) async {
    await bolumuBitir(tester, GameSection.fruits);
    final n = questionsOf(GameSection.fruits).length;

    expect(find.text('Tebrikler!'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(
      find.text('$n sorudan $n tanesini ilk denemede bildin'),
      findsOneWidget,
    );

    // Artık soru ekranında değiliz.
    expect(find.text('Kırmızı elmayı bul'), findsNothing);
  });

  testWidgets('Son bölüm değilse sonraki bölüm butonu görünür', (tester) async {
    await bolumuBitir(tester, GameSection.fruits);

    expect(
      find.widgetWithText(ElevatedButton, GameSection.animals.title),
      findsOneWidget,
    );
    expect(find.text('Ana sayfa'), findsOneWidget);
  });

  // Son bölümde "sonraki" diye bir şey yok; buton hiç oluşturulmamalı.
  testWidgets('Son bölümde sonraki bölüm butonu yok', (tester) async {
    await bolumuBitir(tester, GameSection.objects);

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
    await bolumuBitir(tester, GameSection.fruits);

    await dokun(
      tester,
      find.widgetWithText(ElevatedButton, GameSection.animals.title),
    );

    final m = questionsOf(GameSection.animals).length;
    expect(find.text('Soru 1 / $m'), findsOneWidget);
    expect(find.text('Kediyi bul'), findsOneWidget);
  });

  testWidgets('Tekrar oyna aynı bölümü baştan başlatır', (tester) async {
    await bolumuBitir(tester, GameSection.fruits);

    await dokun(tester, find.text('Tekrar oyna'));

    final n = questionsOf(GameSection.fruits).length;
    expect(find.text('Soru 1 / $n'), findsOneWidget);
    expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
  });

  testWidgets('Ana sayfa butonu bölüm seçimine döner', (tester) async {
    await bolumuBitir(tester, GameSection.fruits);

    await dokun(tester, find.text('Ana sayfa'));

    expect(find.text('Mini Keşif'), findsOneWidget);
    for (final s in GameSection.values) {
      expect(find.text(s.title), findsOneWidget, reason: s.title);
    }
  });

  // pushReplacement kullandık: sonuç sayfasından geri tuşu bitmiş
  // bir soruya dönmemeli.
  testWidgets('Sonuç sayfasında geri oku yok', (tester) async {
    await bolumuBitir(tester, GameSection.fruits);

    expect(find.byType(BackButton), findsNothing);
  });
}
