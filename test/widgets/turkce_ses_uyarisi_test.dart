import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/services/audio_service.dart';

import '../helpers/gercek_font.dart';
import '../helpers/oyun.dart';

/// Cihazda Türkçe ses olup olmadığı ayarlanabilen sahte servis.
class AyarliSes implements AudioService {
  AyarliSes({required this.turkceVar});

  bool turkceVar;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> hazirla({bool yeniden = false}) async => turkceVar;
}

void main() {
  const baslik = 'Türkçe ses bulunamadı';

  testWidgets('Türkçe ses yoksa ana ekranda uyarı görünür', (tester) async {
    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: false)));
    await tester.pumpAndSettle();

    expect(find.text(baslik), findsOneWidget);
    expect(find.text('Tekrar kontrol et'), findsOneWidget);
  });

  testWidgets('Türkçe ses varsa uyarı görünmez', (tester) async {
    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: true)));
    await tester.pumpAndSettle();

    expect(find.text(baslik), findsNothing);
  });

  testWidgets('Ses paketi yüklenip tekrar kontrol edilince uyarı kalkar', (
    tester,
  ) async {
    final ses = AyarliSes(turkceVar: false);
    await tester.pumpWidget(MiniKesifApp(audio: ses));
    await tester.pumpAndSettle();
    expect(find.text(baslik), findsOneWidget);

    ses.turkceVar = true; // ebeveyn ses paketini yükledi
    await tester.tap(find.text('Tekrar kontrol et'));
    await tester.pumpAndSettle();

    expect(find.text(baslik), findsNothing);
  });

  // Türkçe ses yokken 🔊 hiçbir şey yapmaz; çocuğun kafası karışmasın.
  testWidgets('Türkçe ses yoksa oyunda tekrar-dinle butonu gizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: false)));
    await tester.pumpAndSettle();
    // dokun = önce görünür yap, sonra dokun. Uyarı bandı bölüm butonlarını
    // aşağı itiyor; küçük test penceresinde düz tap() ıskalıyordu.
    await dokun(tester, find.text('Meyveler'));

    // ÖNCE gerçekten oyun ekranında olduğumuzu doğrula. Yoksa buton
    // "gizli" görünür ama sebebi sayfanın hiç açılmamış olmasıdır.
    expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
    expect(find.byTooltip('Tekrar dinle'), findsNothing);
  });

  testWidgets('Türkçe ses varsa tekrar-dinle butonu görünür', (tester) async {
    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: true)));
    await tester.pumpAndSettle();
    await dokun(tester, find.text('Meyveler'));

    expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
    expect(find.byTooltip('Tekrar dinle'), findsOneWidget);
  });

  testWidgets('Uyarıyla birlikte ana sayfa küçük telefonda taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1440); // 320x480 dp
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: false)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(baslik), findsOneWidget);
  });

  // Emülatörde görüldü: bant uzunken "Nesneler" butonu ekranın altına
  // taşıyordu. 0-4 yaş çocuktan kaydırma beklemiyoruz.
  testWidgets('Uyarı varken hedef telefonda bölümler kaydırmadan görünür', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400); // Pixel 6
    tester.view.devicePixelRatio = 2.625;
    // Durum çubuğu ve alt hareket çubuğu (~24 dp).
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.reset);
    final sinir = (2400 - 63) / 2.625;

    // Gerçek font: test fontu metni cihazdakinden çok daha uzun ölçüyor
    // ("Mini Keşif" bile iki satıra bölünüyordu). O zaman bu test cihazı
    // değil, test fontunu ölçerdi.
    final fontVar = await tester.runAsync(gercekFontuYukle);
    expect(fontVar, isTrue, reason: "Roboto yüklenemedi (FLUTTER_ROOT?)");

    await tester.pumpWidget(MiniKesifApp(audio: AyarliSes(turkceVar: false)));
    await tester.pumpAndSettle();

    expect(find.text(baslik), findsOneWidget);
    for (final bolum in ['Meyveler', 'Hayvanlar', 'Nesneler']) {
      final buton = find.ancestor(
        of: find.text(bolum),
        matching: find.byType(ElevatedButton),
      );
      expect(
        tester.getRect(buton).bottom,
        lessThan(sinir),
        reason: '$bolum kaydırmadan görünmeli',
      );
    }
  });
}
