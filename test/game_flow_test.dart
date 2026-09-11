import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

void main() {
  // Meyveler bölümünün 4 sorusu, sırayla.
  const dogrular = ['Elma', 'Muz', 'Portakal', 'Çilek'];
  const yanlislar = ['Muz', 'Çilek', 'Üzüm', 'Muz'];

  /// Uygulamayı açar ve Meyveler bölümüne girer.
  Future<void> bolumuAc(WidgetTester tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();
  }

  /// Bölümü sonuna kadar oynar.
  /// [hataliSayisi] kadar soruda önce yanlış bir seçeneğe dokunur.
  Future<void> bolumuBitir(WidgetTester tester, {int hataliSayisi = 0}) async {
    for (var i = 0; i < dogrular.length; i++) {
      if (i < hataliSayisi) {
        await tester.tap(find.text(yanlislar[i]));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(dogrular[i]));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
    }
  }

  group('temel akış', () {
    testWidgets('Bölüme girince ilk soru görünür', (tester) async {
      await bolumuAc(tester);

      expect(find.text('Soru 1 / 4'), findsOneWidget);
      expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
      expect(find.text('Bir seçeneğe dokun'), findsOneWidget);
    });

    testWidgets('Doğru cevap: Aferin mesajı ve onay rozeti', (tester) async {
      await bolumuAc(tester);
      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();

      expect(find.text('Aferin! 🎉'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Yanlış cevap: nazik mesaj, oyun devam eder', (tester) async {
      await bolumuAc(tester);
      await tester.tap(find.text('Muz'));
      await tester.pumpAndSettle();

      expect(find.text('Tekrar dene 🙂'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('Yanlıştan sonra doğruyu bulabilir', (tester) async {
      await bolumuAc(tester);
      await tester.tap(find.text('Muz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Üzüm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();

      expect(find.text('Aferin! 🎉'), findsOneWidget);
    });

    testWidgets('Doğru cevaptan sonra kartlar kilitlenir', (tester) async {
      await bolumuAc(tester);
      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muz'));
      await tester.pumpAndSettle();

      expect(find.text('Aferin! 🎉'), findsOneWidget);
      expect(find.text('Tekrar dene 🙂'), findsNothing);
    });

    testWidgets('Devam butonu cevap verilmeden görünmez', (tester) async {
      await bolumuAc(tester);
      expect(find.text('Devam →'), findsNothing);

      await tester.tap(find.text('Muz'));
      await tester.pumpAndSettle();
      expect(find.text('Devam →'), findsNothing, reason: 'yanlışta ilerleme');

      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();
      expect(find.text('Devam →'), findsOneWidget);
    });
  });

  group('soru geçişi', () {
    testWidgets('4 soru baştan sona oynanır', (tester) async {
      await bolumuAc(tester);

      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam →'));
      await tester.pumpAndSettle();

      expect(find.text('Soru 2 / 4'), findsOneWidget);
      expect(find.text('Sarı muzu bul'), findsOneWidget);

      await tester.tap(find.text('Muz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portakal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam →'));
      await tester.pumpAndSettle();

      // Son soruda buton metni değişir.
      expect(find.text('Soru 4 / 4'), findsOneWidget);
      await tester.tap(find.text('Çilek'));
      await tester.pumpAndSettle();
      expect(find.text('Bitir 🏁'), findsOneWidget);

      await tester.tap(find.text('Bitir 🏁'));
      await tester.pumpAndSettle();
      expect(find.text('Tebrikler!'), findsOneWidget);
    });

    testWidgets('Yeni soruda önceki sorunun soluk kartı kalmaz', (
      tester,
    ) async {
      await bolumuAc(tester);

      await tester.tap(find.text('Muz')); // 1. soruda yanlış
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam →'));
      await tester.pumpAndSettle();

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
      await bolumuBitir(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('Yarısı ilk denemede: 2 dolu yıldız', (tester) async {
      await bolumuAc(tester);
      await bolumuBitir(tester, hataliSayisi: 2); // 4 sorudan 2'si hatalı

      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });

    // Çocuk hiçbirini ilk denemede bilmese bile bölümü bitirdiği için
    // 1 yıldız alır - başarısız hissettirmiyoruz (CLAUDE.md md.18).
    testWidgets('Hepsinde hata: yine de 1 yıldız', (tester) async {
      await bolumuAc(tester);
      await bolumuBitir(tester, hataliSayisi: 4);

      expect(find.byIcon(Icons.star), findsNWidgets(1));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('Tekrar oynayınca skor sıfırlanır', (tester) async {
      await bolumuAc(tester);
      await bolumuBitir(tester); // 3 yıldız
      await tester.tap(find.text('Tekrar oyna'));
      await tester.pumpAndSettle();
      await bolumuBitir(tester, hataliSayisi: 4);

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
      await tester.tap(find.text('Hayvanlar'));
      await tester.pumpAndSettle();

      expect(find.text('Kediyi bul'), findsOneWidget);
      expect(find.text('Kırmızı elmayı bul'), findsNothing);
    });

    // Bir bölümü oynayıp geri dönünce başka bölüm temiz başlamalı.
    testWidgets('Bölüm değişince ilerleme sıfırlanır', (tester) async {
      await bolumuAc(tester);
      await tester.tap(find.text('Elma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam →'));
      await tester.pumpAndSettle();
      expect(find.text('Soru 2 / 4'), findsOneWidget);

      // Geri dön, başka bölüme gir.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nesneler'));
      await tester.pumpAndSettle();

      expect(find.text('Soru 1 / 4'), findsOneWidget);
      expect(find.text('Topu bul'), findsOneWidget);
    });
  });
}
