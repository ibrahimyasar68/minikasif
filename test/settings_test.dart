import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/services/audio_service.dart';
import 'package:mini_kesif/theme/app_colors.dart';
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
  Future<void> geriDon(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  ThemeMode temaModu(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  /// Ekranda en üstteki sayfanın arka plan rengi.
  Color? arkaPlan(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor;

  testWidgets('Ana sayfadaki ayar simgesi ayarlar sayfasını açar', (
    tester,
  ) async {
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await ayarlariAc(tester);

    expect(find.text('Sesli okuma'), findsOneWidget);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
    expect(find.text('Sistem'), findsOneWidget);
  });

  testWidgets('Ses açıkken bölüme girince soru okunur', (tester) async {
    final ses = KayitSes();
    await tester.pumpWidget(MiniKesifApp(audio: ses));
    await tester.pumpAndSettle();
    await bolumeGir(tester, GameSection.fruits);

    expect(ses.konusmalar, isNotEmpty);
    expect(find.byTooltip('Tekrar dinle'), findsOneWidget);
  });

  testWidgets('Ses kapatılınca oyunda hiçbir şey okunmaz, 🔊 gizlenir', (
    tester,
  ) async {
    final ses = KayitSes();
    await tester.pumpWidget(MiniKesifApp(audio: ses));
    await tester.pumpAndSettle();
    await ayarlariAc(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await geriDon(tester);

    await bolumeGir(tester, GameSection.fruits);
    await dokun(tester, find.text('Muz')); // yanlış -> normalde teşvik okunur
    await dokun(tester, find.text('Elma')); // doğru -> normalde övgü okunur

    expect(ses.konusmalar, isEmpty);
    expect(find.byTooltip('Tekrar dinle'), findsNothing);
    // Oyun sessiz de ilerler: otomatik geçiş çalışıyor.
    await otomatikGecisiBekle(tester);
    expect(find.text('Sarı muzu bul'), findsOneWidget);
  });

  testWidgets('Koyu tema seçilince koyu renkler uygulanır', (tester) async {
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await ayarlariAc(tester);
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();

    expect(temaModu(tester), ThemeMode.dark);
    expect(arkaPlan(tester), AppColors.dark.background);

    await geriDon(tester);
    expect(arkaPlan(tester), AppColors.dark.background, reason: 'ana sayfa');
  });

  testWidgets('Açık tema seçilince açık renkler uygulanır', (tester) async {
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();
    await ayarlariAc(tester);
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Açık'));
    await tester.pumpAndSettle();

    expect(temaModu(tester), ThemeMode.light);
    expect(arkaPlan(tester), AppColors.light.background);
  });

  // "Sistem": telefonun açık/koyu ayarına uyulur.
  testWidgets('Sistem teması telefonun koyu ayarına uyar', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));
    await tester.pumpAndSettle();

    expect(temaModu(tester), ThemeMode.system);
    expect(arkaPlan(tester), AppColors.dark.background);
  });

  testWidgets('Uygulama kayıtlı ayarlarla açılır', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ses_acik': false,
      'tema_modu': 'dark',
    });
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final ses = KayitSes();

    await tester.pumpWidget(MiniKesifApp(audio: ses, prefs: prefs));
    await tester.pumpAndSettle();

    expect(temaModu(tester), ThemeMode.dark);
    await bolumeGir(tester, GameSection.fruits);
    expect(ses.konusmalar, isEmpty, reason: 'ses kapalı kaydedilmişti');
  });
}
