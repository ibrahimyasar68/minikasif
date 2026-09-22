import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:mini_kasif/widgets/parent_gate_button.dart';

import '../helpers/oyun.dart';

/// Ebeveyn kilidi testleri.
///
/// DİKKAT (zamanlama): AnimationController saymaya forward() anında değil,
/// SONRAKİ İLK KAREDE başlar. Parmağı indirdikten sonra önce pump() ile o
/// kareyi çizmezsek, pump(2 sn)'nin sonunda animasyon "şimdi başladım"
/// sanır ve halka dolmaz.
void main() {
  late int acilma;

  Future<void> kur(WidgetTester tester) async {
    acilma = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ParentGateButton(onOpen: () => acilma++)),
        ),
      ),
    );
  }

  Offset merkez(WidgetTester t) => t.getCenter(find.byType(ParentGateButton));
  double dolum(WidgetTester t) => t
      .widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator))
      .value!;

  testWidgets('kısa dokunuş açmaz, ipucu gösterir', (tester) async {
    await kur(tester);
    await tester.tap(find.byType(ParentGateButton));
    await tester.pump();

    expect(acilma, 0);
    expect(find.textContaining('basılı tutun'), findsOneWidget);
  });

  // Bulunan hata: çok hızlı dokunuşta (animasyon ilk karesini çizmeden
  // parmak kalkınca) halka geri boşaltılmıyor, kendi başına dolup 2 sn
  // sonra ayarları AÇIYORDU. tester.tap tam da bu kadar hızlı.
  testWidgets('çok hızlı dokunuş 2 sn sonra da açmaz', (tester) async {
    await kur(tester);
    await tester.tap(find.byType(ParentGateButton));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(acilma, 0);
  });

  testWidgets('2 saniye basılı tutunca açılır', (tester) async {
    await kur(tester);
    final parmak = await tester.startGesture(merkez(tester));
    await tester.pump(); // animasyonun ilk karesi
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 50));

    expect(acilma, 1);
    await parmak.up();
    await tester.pumpAndSettle();
    expect(acilma, 1, reason: 'parmak kalkınca ikinci kez açılmamalı');
    expect(find.textContaining('basılı tutun'), findsNothing);
  });

  testWidgets('yarıda bırakılırsa açılmaz, halka geri boşalır', (tester) async {
    await kur(tester);
    final parmak = await tester.startGesture(merkez(tester));
    await tester.pump(); // animasyonun ilk karesi
    await tester.pump(const Duration(seconds: 1));
    expect(dolum(tester), closeTo(0.5, 0.05), reason: 'yarıya dolmuş olmalı');

    await parmak.up();
    await tester.pumpAndSettle();

    expect(acilma, 0);
    expect(dolum(tester), 0);
  });

  // TalkBack: "çift dokun ve basılı tut" -> semantik uzun basma eylemi.
  testWidgets('ekran okuyucu uzun basma eylemi açar', (tester) async {
    await kur(tester);
    // Etiketinden buluyoruz: sayfada (MaterialApp, Scaffold) başka
    // Listener ve Semantics widget'ları da var.
    final semantik = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Ayarlar',
      ),
    );
    semantik.properties.onLongPress!();
    expect(acilma, 1);
  });

  group('ana sayfada', () {
    testWidgets('ayar simgesine dokunmak ayarları AÇMAZ', (tester) async {
      await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Sesli okuma'), findsNothing);
      expect(find.text('MiniKasif'), findsOneWidget);
    });

    testWidgets('basılı tutunca ayarlar açılır', (tester) async {
      await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
      await tester.pumpAndSettle();

      await ayarlariAc(tester);

      expect(find.text('Sesli okuma'), findsOneWidget);
    });
  });
}
