import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('varsayılan: ses açık, tema sistem', () {
    final ayarlar = SettingsProvider();
    expect(ayarlar.sesAcik, isTrue);
    expect(ayarlar.temaModu, ThemeMode.system);
  });

  test('ayar değişince dinleyici uyarılır', () {
    final ayarlar = SettingsProvider();
    var bildirim = 0;
    ayarlar.addListener(() => bildirim++);

    ayarlar.sesiAyarla(false);
    ayarlar.temayiAyarla(ThemeMode.dark);

    expect(ayarlar.sesAcik, isFalse);
    expect(ayarlar.temaModu, ThemeMode.dark);
    expect(bildirim, 2);
  });

  test('aynı değer tekrar verilince boşuna bildirim yok', () {
    final ayarlar = SettingsProvider();
    var bildirim = 0;
    ayarlar.addListener(() => bildirim++);

    ayarlar.sesiAyarla(true); // zaten açık
    ayarlar.temayiAyarla(ThemeMode.system); // zaten sistem

    expect(bildirim, 0);
  });

  // Asıl mesele: uygulama kapanıp açılınca ayarlar hatırlanmalı.
  test('ayarlar kaydedilir, yeniden açılınca hatırlanır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    SettingsProvider(prefs: prefs)
      ..sesiAyarla(false)
      ..temayiAyarla(ThemeMode.dark);

    // "Uygulama yeniden açıldı": aynı depodan yeni bir provider.
    final yeniden = SettingsProvider(prefs: prefs);
    expect(yeniden.sesAcik, isFalse);
    expect(yeniden.temaModu, ThemeMode.dark);
  });

  test('bozuk kayıtlı tema değeri sistem temasına düşer', () async {
    SharedPreferences.setMockInitialValues({'tema_modu': 'mor'});
    final prefs = await SharedPreferences.getInstance();

    expect(SettingsProvider(prefs: prefs).temaModu, ThemeMode.system);
  });
}
