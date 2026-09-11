import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_section.dart';

/// Her bölümün EN İYİ yıldız skoru (0-3). Kalıcı.
///
/// Neden SettingsProvider'da değil? İlerleme bir ayar değil, oyun geçmişi.
/// Neden GameProvider'da değil? GameProvider bir bölümün O ANKİ oyununu
/// yönetir; bu ise bütün oyunların özetini tutar ve uygulama kapansa da yaşar.
class ProgressProvider extends ChangeNotifier {
  /// [prefs] verilmezse ilerleme sadece bellekte tutulur (testler).
  ProgressProvider({SharedPreferences? prefs}) : _prefs = prefs {
    for (final bolum in GameSection.values) {
      // clamp: bozuk bir kayıt (ör. 7 ya da -1) ekranı bozmasın.
      _enIyi[bolum] = (prefs?.getInt(_anahtar(bolum)) ?? 0).clamp(0, 3);
    }
  }

  final SharedPreferences? _prefs;
  final Map<GameSection, int> _enIyi = {};

  static String _anahtar(GameSection bolum) => 'en_iyi_yildiz_${bolum.name}';

  /// Bu bölümün en iyi yıldız sayısı. Hiç oynanmadıysa 0.
  int enIyi(GameSection bolum) => _enIyi[bolum] ?? 0;

  /// Hiç kayıtlı ilerleme var mı? (Sıfırlama butonu için.)
  bool get bosMu => _enIyi.values.every((y) => y == 0);

  /// Bölüm sonucunu kaydeder. YENİ REKOR ise true döner.
  ///
  /// Sadece İYİLEŞİRSE günceller: daha kötü bir oyun rekoru bozmaz,
  /// çocuk kazandığı yıldızı kaybetmez.
  bool kaydet(GameSection bolum, int yildiz) {
    if (yildiz <= enIyi(bolum)) return false;
    _enIyi[bolum] = yildiz;
    notifyListeners();
    _prefs?.setInt(_anahtar(bolum), yildiz);
    return true;
  }

  /// Bütün ilerlemeyi siler (Ayarlar > İlerlemeyi sıfırla).
  void sifirla() {
    if (bosMu) return;
    for (final bolum in GameSection.values) {
      _enIyi[bolum] = 0;
      _prefs?.remove(_anahtar(bolum));
    }
    notifyListeners();
  }
}
