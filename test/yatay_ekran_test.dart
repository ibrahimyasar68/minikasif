import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/services/audio_service.dart';
import 'package:mini_kesif/widgets/answer_card.dart';

import 'helpers/gercek_font.dart';
import 'helpers/oyun.dart';

/// Türkçe ses motoru olmayan cihaz: ana sayfada ebeveyn uyarısı çıkar.
class _TurkcesizSes implements AudioService {
  const _TurkcesizSes();
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<bool> hazirla({bool yeniden = false}) async => false;
}

/// Telefon yan çevrildiğinde de oyun KAYDIRMADAN oynanabilmeli.
///
/// Ölçüler Pixel 6 emülatöründen (yatay, Android 14):
///   2400x1080 px, 2.625 dpr -> 914x411 dp
///   solda kamera çentiği 128 px, üstte durum çubuğu 63 px,
///   altta hareket çubuğu 63 px -> kullanılabilir alan 866x363 dp.
///
/// Gerçek font şart: test fontu metni çok geniş ölçer, sonuç cihazı değil
/// test fontunu yansıtırdı (bkz. helpers/gercek_font.dart).
void main() {
  const dpr = 2.625;
  const boyut = Size(2400, 1080);
  const bosluk = FakeViewPadding(left: 128, top: 63, bottom: 63);

  /// Ekranın, sistem çubukları ve çentik dışında kalan görünür bölgesi.
  const gorunur = Rect.fromLTRB(128 / dpr, 63 / dpr, 2400 / dpr, 1017 / dpr);

  Future<void> yatayPixel6(WidgetTester tester) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = bosluk;
    addTearDown(tester.view.reset);
    expect(await tester.runAsync(gercekFontuYukle), isTrue);
  }

  /// Hedef ekranda görünür bölgenin içinde mi? (Kaydırma gerekmez.)
  ///
  /// DİKKAT: ensureVisible KULLANMIYORUZ; kaydırma gerekirse sessizce
  /// kaydırıp sorunu gizlerdi.
  void kaydirmadanGorunur(WidgetTester tester, Finder hedef, String neden) {
    expect(hedef, findsOneWidget, reason: neden);
    final r = tester.getRect(hedef);
    expect(r.top, greaterThanOrEqualTo(gorunur.top - 0.5), reason: neden);
    expect(r.bottom, lessThanOrEqualTo(gorunur.bottom + 0.5), reason: neden);
    expect(r.left, greaterThanOrEqualTo(gorunur.left - 0.5), reason: neden);
    expect(r.right, lessThanOrEqualTo(gorunur.right + 0.5), reason: neden);
  }

  testWidgets('Ana sayfa: 3 bölüm de kaydırmadan görünür', (tester) async {
    await yatayPixel6(tester);
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    kaydirmadanGorunur(tester, find.text('Mini Kesif'), 'başlık');
    for (final bolum in GameSection.values) {
      kaydirmadanGorunur(tester, find.text(bolum.title), bolum.title);
    }

    // Bölüm butonları ayar simgesinin altına girmemeli: çocuk bölüme
    // dokunmak isterken ebeveyn kilidine basmasın.
    final ayar = tester.getRect(find.byIcon(Icons.settings_rounded));
    for (final bolum in GameSection.values) {
      final buton = tester.getRect(
        find.ancestor(
          of: find.text(bolum.title),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buton.overlaps(ayar), isFalse, reason: bolum.title);
    }
  });

  testWidgets('Ana sayfa: Türkçe ses uyarısı varken de bölümler görünür', (
    tester,
  ) async {
    await yatayPixel6(tester);
    await tester.pumpWidget(const MiniKesifApp(audio: _TurkcesizSes()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Türkçe ses bulunamadı'), findsOneWidget);
    for (final bolum in GameSection.values) {
      kaydirmadanGorunur(tester, find.text(bolum.title), bolum.title);
    }
  });

  testWidgets('Oyun: 30 sorunun hepsinde soru, kartlar ve geri bildirim '
      'kaydırmadan görünür', (tester) async {
    await yatayPixel6(tester);
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();

    for (final bolum in GameSection.values) {
      await tester.tap(find.text(bolum.title));
      await tester.pumpAndSettle();

      for (final soru in questionsOf(bolum)) {
        expect(tester.takeException(), isNull, reason: soru.id);
        kaydirmadanGorunur(
          tester,
          find.text(soru.questionText),
          '${soru.id}: soru',
        );
        for (final e in find.byType(AnswerCard).evaluate()) {
          final kart = find.byWidget(e.widget);
          kaydirmadanGorunur(tester, kart, '${soru.id}: kart');
          // 0-4 yaş için büyük dokunma alanı (AnswerGrid._enKucuk).
          expect(
            tester.getSize(kart).shortestSide,
            greaterThanOrEqualTo(96),
            reason: '${soru.id}: kart küçük',
          );
        }

        await tester.tap(find.text(dogruEtiket(soru)));
        await tester.pumpAndSettle();
        kaydirmadanGorunur(
          tester,
          find.text('Aferin! 🎉'),
          '${soru.id}: geri bildirim',
        );
        await otomatikGecisiBekle(tester);
      }

      // Sonuç ekranı: bütün butonlar kaydırmadan görünür.
      expect(tester.takeException(), isNull, reason: '${bolum.title} sonuç');
      kaydirmadanGorunur(tester, find.text('Tebrikler!'), 'Tebrikler');
      kaydirmadanGorunur(tester, find.text('Tekrar oyna'), 'Tekrar oyna');
      final sonraki = bolum.next;
      if (sonraki != null) {
        kaydirmadanGorunur(tester, find.text(sonraki.title), sonraki.title);
      }
      kaydirmadanGorunur(tester, find.text('Ana sayfa'), 'Ana sayfa');

      await tester.tap(find.text('Ana sayfa'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Oyun ortasında ekran dönünce aynı sorudan devam edilir', (
    tester,
  ) async {
    // Dikey Pixel 6 ile başla.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = dpr;
    tester.view.padding = const FakeViewPadding(top: 128, bottom: 63);
    addTearDown(tester.view.reset);
    expect(await tester.runAsync(gercekFontuYukle), isTrue);

    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await bolumeGir(tester, GameSection.fruits);

    final sorular = questionsOf(GameSection.fruits);
    await dokun(tester, find.text(dogruEtiket(sorular[0])));
    await otomatikGecisiBekle(tester);
    // İkinci soruda bir yanlış dene: "denendi" durumu da korunmalı.
    await dokun(tester, find.text(yanlisEtiket(sorular[1])));

    // Yan çevir.
    tester.view.physicalSize = boyut;
    tester.view.padding = bosluk;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Soru 2 / ${sorular.length}'), findsOneWidget);
    kaydirmadanGorunur(tester, find.text(sorular[1].questionText), 'soru');
    expect(find.text('Tekrar dene 🙂'), findsOneWidget);

    // Oyun yatayda sürer.
    await tester.tap(find.text(dogruEtiket(sorular[1])));
    await tester.pumpAndSettle();
    expect(find.text('Aferin! 🎉'), findsOneWidget);
  });

  // Küçük telefon yan çevrilince (480x320 dp) yer çok dar. Burada
  // kaydırma yedek çözüm olarak kabul; ama taşma (sarı-siyah şerit) olmamalı.
  testWidgets('Küçük telefon yatayda hiçbir ekranda taşma yok', (tester) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'ana sayfa');

    for (final bolum in GameSection.values) {
      await bolumeGir(tester, bolum);
      await bolumuOyna(
        tester,
        bolum,
        sorudaIken: (soru) async {
          expect(tester.takeException(), isNull, reason: soru.id);
        },
      );
      expect(tester.takeException(), isNull, reason: '${bolum.title} sonuç');
      await dokun(tester, find.text('Ana sayfa'));
    }
  });

  testWidgets('Yatayda yazı boyutu 2 katına çıkınca taşma yok', (tester) async {
    await yatayPixel6(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'ana sayfa');

    await bolumeGir(tester, GameSection.fruits);
    expect(tester.takeException(), isNull, reason: 'soru ekranı');
  });
}
