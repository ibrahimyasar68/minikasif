import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama ayarları: ses açık/kapalı ve tema (açık/koyu/sistem).
///
/// Neden GameProvider'da değil?
/// Oyun durumu bir bölüm boyunca yaşar ve sık değişir. Ayarlar ise
/// uygulama genelinde geçerli, nadiren değişir ve KALICIDIR. Farklı
/// sorumluluk, farklı ömür -> ayrı provider.
///
/// (Burada material.dart'ı sadece ThemeMode enum'u için alıyoruz;
/// hiçbir widget kullanmıyoruz.)
class SettingsProvider extends ChangeNotifier {
  /// [prefs] verilmezse ayarlar sadece bellekte tutulur (testler).
  SettingsProvider({SharedPreferences? prefs})
    : _prefs = prefs,
      _sesAcik = prefs?.getBool(_sesAnahtari) ?? true,
      _temaModu = _temaCoz(prefs?.getString(_temaAnahtari));

  static const _sesAnahtari = 'ses_acik';
  static const _temaAnahtari = 'tema_modu';

  final SharedPreferences? _prefs;
  bool _sesAcik;
  ThemeMode _temaModu;

  /// Sesli okuma açık mı? Varsayılan: açık.
  bool get sesAcik => _sesAcik;

  /// Tema. Varsayılan: sistem (telefonun kendi ayarı).
  ThemeMode get temaModu => _temaModu;

  void sesiAyarla(bool acik) {
    if (acik == _sesAcik) return; // değişmediyse boşuna rebuild yok
    _sesAcik = acik;
    notifyListeners();
    // Kaydetmeyi beklemiyoruz: ekran hemen güncellensin, kayıt arkada.
    _prefs?.setBool(_sesAnahtari, acik);
  }

  void temayiAyarla(ThemeMode mod) {
    if (mod == _temaModu) return;
    _temaModu = mod;
    notifyListeners();
    _prefs?.setString(_temaAnahtari, mod.name);
  }

  /// Kayıtlı metni ThemeMode'a çevirir. Bilinmeyen/bozuk değer -> sistem.
  static ThemeMode _temaCoz(String? ad) => ThemeMode.values.firstWhere(
    (m) => m.name == ad,
    orElse: () => ThemeMode.system,
  );
}
