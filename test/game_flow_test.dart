import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

import 'helpers/oyun.dart';

void main() {
  const bolum = GameSection.fruits;
  // Soru sayısını ve cevapları veriden okuyoruz; sabit yazmıyoruz.
  final sorular = questionsOf(bolum);
  final n = sorular.length;

  Future<void> bolumuAc(WidgetTester tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await bolumeGir(tester, bolum);
  }

  group('temel akış', () {
    testWidgets('Bölüme girince ilk soru görünür', (tester) async {
      await bolumuAc(tester);

      expect(find.text('Soru 1 / $n'), findsOneWidget);
      expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
      expect(find.text('Bir seçeneğe dokun'), findsOneWidget);
    });

    testWidgets('Doğru cevap: Aferin mesajı ve onay rozeti', (tester) async {
      await bolumuAc(tester);
      await dokun(tester, find.text('Elma'));

      expect(find.text('Aferin! 🎉'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Yanlış cevap: nazik mesaj, oyun devam eder', (tester) async {
      await bolumuAc(tester);
      await dokun(tester, find.text('Muz'));

      expect(find.text('Tekrar dene 🙂'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('Yanlıştan sonra doğruyu bulabilir', (tester) async {
      await bolumuAc(tester);
      await dokun(tester, find.text('Muz'));
      await dokun(tester, find.text('Üzüm'));
      await dokun(tester, find.text('Elma'));

      expect(find.text('Aferin! 🎉'), findsOneWidget);
    });

    testWidgets('Doğru cevaptan sonra kartlar kilitlenir', (tester) async {
      await bolumuAc(tester);
      await dokun(tester, find.text('Elma'));
      await dokun(tester, find.text('Muz'));

      expect(find.text('Aferin! 🎉'), findsOneWidget);
      expect(find.text('Tekrar dene 🙂'), findsNothing);
    });

    testWidgets('Devam butonu cevap verilmeden görünmez', (tester) async {
      await bolumuAc(tester);
      expect(find.text('Devam →'), findsNothing);

      await dokun(tester, find.text('Muz'));
      expect(find.text('Devam →'), findsNothing, reason: 'yanlışta ilerleme');

      await dokun(tester, find.text('Elma'));
      expect(find.text('Devam →'), findsOneWidget);
    });
  });

  group('soru geçişi', () {
    testWidgets('Bölüm baştan sona oynanır', (tester) async {
      await bolumuAc(tester);

      for (var i = 0; i < n; i++) {
        final soru = sorular[i];
        expect(find.text('Soru ${i + 1} / $n'), findsOneWidget);
        expect(find.text(soru.questionText), findsOneWidget);

        await dokun(tester, find.text(dogruEtiket(soru)));

        // Son soruda buton metni değişir.
        final buton = i == n - 1 ? 'Bitir 🏁' : 'Devam →';
        expect(find.text(buton), findsOneWidget, reason: soru.id);
        await dokun(tester, find.text(buton));
      }

      expect(find.text('Tebrikler!'), findsOneWidget);
    });

    testWidgets('Yeni soruda önceki sorunun soluk kartı kalmaz', (
      tester,
    ) async {
      await bolumuAc(tester);

      await dokun(tester, find.text('Muz')); // 1. soruda yanlış
      await dokun(tester, find.text('Elma'));
      await dokun(tester, find.text('Devam →'));

      // 2. soruda Muz doğru cevap; soluk değil normal görünmeli.
      final muzKarti = tester.widget<AnswerCard>(
        find.ancestor(of: find.text('Muz'), matching: find.byType(AnswerCard)),
      );
      expect(muzKarti.status, AnswerStatus.normal);
    });
  });

  group('yıldızlar', () {
    testWidgets('Hepsi ilk denemede: 3 dolu yıldız', (tester) async {
      await bolumuAc(tester);
      await bolumuOyna(tester, bolum);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('Yarısında hata: 2 dolu yıldız', (tester) async {
      await bolumuAc(tester);
      await bolumuOyna(tester, bolum, hataliSoruSayisi: n ~/ 2);

      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });

    // Çocuk hiçbirini ilk denemede bilmese bile bölümü bitirdiği için
    // 1 yıldız alır - başarısız hissettirmiyoruz (CLAUDE.md md.18).
    testWidgets('Hepsinde hata: yine de 1 yıldız', (tester) async {
      await bolumuAc(tester);
      await bolumuOyna(tester, bolum, hataliSoruSayisi: n);

      expect(find.byIcon(Icons.star), findsNWidgets(1));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('Tekrar oynayınca skor sıfırlanır', (tester) async {
      await bolumuAc(tester);
      await bolumuOyna(tester, bolum); // 3 yıldız
      await dokun(tester, find.text('Tekrar oyna'));
      await bolumuOyna(tester, bolum, hataliSoruSayisi: n);

      expect(
        find.byIcon(Icons.star),
        findsNWidgets(1),
        reason: 'önceki turun skoru taşınmamalı',
      );
    });
  });

  group('bölümler', () {
    testWidgets('Hayvanlar bölümü kendi sorularını gösterir', (tester) async {
      await tester.pumpWidget(const MiniKesifApp());
      await bolumeGir(tester, GameSection.animals);

      expect(find.text('Kediyi bul'), findsOneWidget);
      expect(find.text('Kırmızı elmayı bul'), findsNothing);
    });

    // Bir bölümü oynayıp geri dönünce başka bölüm temiz başlamalı.
    testWidgets('Bölüm değişince ilerleme sıfırlanır', (tester) async {
      await bolumuAc(tester);
      await dokun(tester, find.text('Elma'));
      await dokun(tester, find.text('Devam →'));
      expect(find.text('Soru 2 / $n'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await bolumeGir(tester, GameSection.objects);

      final m = questionsOf(GameSection.objects).length;
      expect(find.text('Soru 1 / $m'), findsOneWidget);
      expect(find.text('Topu bul'), findsOneWidget);
    });
  });
}
