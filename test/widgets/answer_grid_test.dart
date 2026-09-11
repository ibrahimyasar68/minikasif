import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/answer_option.dart';
import 'package:mini_kesif/widgets/answer_card.dart';
import 'package:mini_kesif/widgets/answer_grid.dart';

/// AnswerGrid'i doğrudan test ediyoruz.
///
/// Neden gerçek oyun üzerinden değil?
/// Soru verisinde şu an sadece 3 seçenekli sorular var. 2 ve 4 seçenekli
/// düzenleri oyun üzerinden deneyemeyiz. Widget'ı tek başına kurunca
/// istediğimiz sayıda seçenek verebiliyoruz.
void main() {
  List<AnswerOption> secenekler(int adet) => [
    for (var i = 0; i < adet; i++)
      AnswerOption(id: 's$i', label: 'S$i', emoji: '⭐'),
  ];

  /// Grid'i telefon genişliğinde (371 dp - Pixel 6 eksi kenar boşluğu) kurar.
  Future<void> kur(WidgetTester tester, int adet) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 371,
              child: AnswerGrid(
                options: secenekler(adet),
                statusOf: (_) => AnswerStatus.normal,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kartların kaç farklı satıra dağıldığını sayar.
  int satirSayisi(WidgetTester tester) => find
      .byType(AnswerCard)
      .evaluate()
      .map((e) => tester.getRect(find.byWidget(e.widget)).top.round())
      .toSet()
      .length;

  testWidgets('2 seçenek tek sırada', (tester) async {
    await kur(tester, 2);
    expect(satirSayisi(tester), 1);
  });

  // Asıl düzeltme bu: eskiden Wrap 3 kartı 2+1 diziyordu.
  testWidgets('3 seçenek tek sırada (2+1 değil)', (tester) async {
    await kur(tester, 3);
    expect(satirSayisi(tester), 1);
  });

  testWidgets('4 seçenek 2x2', (tester) async {
    await kur(tester, 4);
    expect(satirSayisi(tester), 2);
  });

  testWidgets('kartlar 0-4 yaş için yeterince büyük', (tester) async {
    for (final adet in [2, 3, 4]) {
      await kur(tester, adet);
      final boyut = tester.getSize(find.byType(AnswerCard).first);
      expect(boyut.width, greaterThanOrEqualTo(96.0), reason: '$adet seçenek');
    }
  });

  testWidgets('onTap null ise kartlar kilitli', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerGrid(
            options: secenekler(2),
            statusOf: (_) => AnswerStatus.normal,
            onTap: null,
          ),
        ),
      ),
    );
    for (final e in find.byType(AnswerCard).evaluate()) {
      expect((e.widget as AnswerCard).onTap, isNull);
    }
  });

  // Tablet gibi geniş ekranda Wrap 4 kartı tek sıraya dizmemeli:
  // "4 seçenek -> 2x2" kuralı her genişlikte geçerli olmalı.
  testWidgets('geniş ekranda da 4 seçenek 2x2', (tester) async {
    tester.view.physicalSize = const Size(2400, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1100,
              child: AnswerGrid(
                options: secenekler(4),
                statusOf: (_) => AnswerStatus.normal,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(satirSayisi(tester), 2);
  });
}
