import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/data/question_data.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/models/game_section.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/oyun.dart';

class KayitSes implements AudioService {
  final konusmalar = <String>[];

  @override
  Future<void> speak(String text) async => konusmalar.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<bool> hazirla({bool yeniden = false}) async => true;
}

void main() {
  const rekor = 'Yeni rekor! 🏆';
  final n = questionsOf(GameSection.fruits).length;

  /// Ana sayfada bir bölüm butonunun içindeki yıldız simgeleri.
  Finder yildizlar(String bolum, IconData ikon) => find.descendant(
    of: find.widgetWithText(ElevatedButton, bolum),
    matching: find.byIcon(ikon),
  );

  Future<void> meyveleriOyna(WidgetTester tester, {int hatali = 0}) async {
    await bolumeGir(tester, GameSection.fruits);
    await bolumuOyna(tester, GameSection.fruits, hataliSoruSayisi: hatali);
  }

  testWidgets('Oynanmamış bölümlerde boş yıldızlar görünür', (tester) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();

    for (final b in GameSection.values) {
      expect(yildizlar(b.title, Icons.star_border), findsNWidgets(3));
      expect(yildizlar(b.title, Icons.star), findsNothing);
    }
  });

  testWidgets('Bölüm bitince rekor mesajı çıkar, ana sayfada yıldızlar dolar', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await meyveleriOyna(tester);

    expect(find.text(rekor), findsOneWidget);

    await dokun(tester, find.text('Ana sayfa'));
    expect(yildizlar('Meyveler', Icons.star), findsNWidgets(3));
    expect(yildizlar('Hayvanlar', Icons.star_border), findsNWidgets(3));
  });

  // Çocuk kazandığı yıldızı kaybetmemeli.
  testWidgets('Daha kötü oyun rekoru bozmaz, rekor mesajı çıkmaz', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await meyveleriOyna(tester); // 3 yıldız
    await dokun(tester, find.text('Tekrar oyna'));
    await bolumuOyna(tester, GameSection.fruits, hataliSoruSayisi: n); // 1

    expect(find.text(rekor), findsNothing);
    await dokun(tester, find.text('Ana sayfa'));
    expect(yildizlar('Meyveler', Icons.star), findsNWidgets(3));
  });

  testWidgets('Rekor sesli okunur; rekor değilse okunmaz', (tester) async {
    final ses = KayitSes();
    await tester.pumpWidget(MiniKasifApp(audio: ses));
    await tester.pumpAndSettle();

    await meyveleriOyna(tester);
    expect(ses.konusmalar.last, startsWith('Yeni rekor!'));

    await dokun(tester, find.text('Tekrar oyna'));
    await bolumuOyna(tester, GameSection.fruits, hataliSoruSayisi: n);
    expect(ses.konusmalar.last, isNot(startsWith('Yeni rekor!')));
  });

  testWidgets('Uygulama kayıtlı ilerlemeyle açılır', (tester) async {
    SharedPreferences.setMockInitialValues({'en_iyi_yildiz_animals': 2});
    final prefs = await tester.runAsync(SharedPreferences.getInstance);

    await tester.pumpWidget(
      MiniKasifApp(audio: const SilentAudioService(), prefs: prefs),
    );
    await tester.pumpAndSettle();

    expect(yildizlar('Hayvanlar', Icons.star), findsNWidgets(2));
    expect(yildizlar('Hayvanlar', Icons.star_border), findsNWidgets(1));
  });

  group('Ayarlardan sıfırlama', () {
    Future<void> kayitliAc(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'en_iyi_yildiz_fruits': 3});
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      await tester.pumpWidget(
        MiniKasifApp(audio: const SilentAudioService(), prefs: prefs),
      );
      await tester.pumpAndSettle();
      await ayarlariAc(tester);
      await dokun(tester, find.text('İlerlemeyi sıfırla'));
    }

    testWidgets('onaylanınca ilerleme silinir', (tester) async {
      await kayitliAc(tester);
      await dokun(tester, find.text('Sıfırla'));

      expect(find.text('İlerleme sıfırlandı'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(yildizlar('Meyveler', Icons.star), findsNothing);
      expect(yildizlar('Meyveler', Icons.star_border), findsNWidgets(3));
    });

    testWidgets('Vazgeç denirse ilerleme silinmez', (tester) async {
      await kayitliAc(tester);
      await dokun(tester, find.text('Vazgeç'));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(yildizlar('Meyveler', Icons.star), findsNWidgets(3));
    });
  });
}
