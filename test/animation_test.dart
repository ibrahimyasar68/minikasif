import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:mini_kasif/providers/game_provider.dart';

/// Animasyon testleri.
///
/// Animasyonu "görmek" için pumpAndSettle KULLANILMAZ - o, animasyon
/// bitene kadar bekler. Bunun yerine pump(süre) ile geçişin ORTASINA
/// gidip o andaki duruma bakıyoruz.
void main() {
  Future<void> bolumuAc(WidgetTester tester) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();
  }

  testWidgets('Doğru kart büyüyerek vurgulanır', (tester) async {
    await bolumuAc(tester);

    AnimatedScale elmaKarti() => tester.widget<AnimatedScale>(
      find.ancestor(
        of: find.text('Elma'),
        matching: find.byType(AnimatedScale),
      ),
    );

    expect(elmaKarti().scale, 1.0, reason: 'başlangıçta normal boyut');

    await tester.tap(find.text('Elma'));
    await tester.pumpAndSettle();

    expect(
      elmaKarti().scale,
      greaterThan(1.0),
      reason: 'doğru cevapta kart büyümeli',
    );
  });

  testWidgets('Yanlış kart yumuşak şekilde solar', (tester) async {
    await bolumuAc(tester);

    AnimatedOpacity muzKarti() => tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Muz'),
        matching: find.byType(AnimatedOpacity),
      ),
    );

    expect(muzKarti().opacity, 1.0);

    await tester.tap(find.text('Muz')); // yanlış
    await tester.pumpAndSettle();

    expect(muzKarti().opacity, lessThan(1.0));
  });

  testWidgets('Soru geçişi ani değil, iki soru bir an birlikte görünür', (
    tester,
  ) async {
    await bolumuAc(tester);
    await tester.tap(find.text('Elma'));
    await tester.pumpAndSettle();

    // Buton yok: otomatik geçişin gerçekleşmesi için yeterince bekle.
    // pump(süre) saati ileri sarar ve SONUNDA tek bir kare çizer; geçiş
    // animasyonu o karede başlar.
    await tester.pump(GameProvider.maxCelebration);
    // Geçişin ortası: 320ms'lik animasyonun ~yarısı.
    await tester.pump(const Duration(milliseconds: 150));

    // Eski soru henüz kaybolmamış, yeni soru belirmiş.
    // Bu ikisinin aynı anda bulunması geçişin çalıştığının kanıtı.
    expect(find.text('Kırmızı elmayı bul'), findsOneWidget);
    expect(find.text('Sarı muzu bul'), findsOneWidget);

    await tester.pumpAndSettle();

    // Geçiş bitince sadece yeni soru kalır.
    expect(find.text('Kırmızı elmayı bul'), findsNothing);
    expect(find.text('Sarı muzu bul'), findsOneWidget);
  });

  // Aynı soru içinde cevap verince geçiş animasyonu TETİKLENMEMELİ,
  // yoksa her dokunuşta ekran titrerdi.
  testWidgets('Aynı soru içinde cevap vermek geçiş başlatmaz', (tester) async {
    await bolumuAc(tester);

    await tester.tap(find.text('Muz')); // yanlış, soru değişmiyor
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.text('Kırmızı elmayı bul'),
      findsOneWidget,
      reason: 'soru metni kopyalanmamalı',
    );
  });
}
