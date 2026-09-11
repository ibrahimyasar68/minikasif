import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
///
/// Neden tek dosyada?
/// Renkler 4 ayrı dosyaya dağılmıştı. Turuncuyu değiştirmek istesek
/// 4 dosyada arama yapmamız gerekirdi; birini atlamak da kolaydı.
///
/// Neden bir sınıf ama nesnesi yok?
/// abstract final = "bu sınıftan nesne üretilemez, sadece isim alanı".
/// AppColors.primary şeklinde kullanılıyor.
abstract final class AppColors {
  /// Ekran arka planı - sıcak krem.
  static const background = Color(0xFFFFF3E0);

  /// Ana vurgu rengi - AppBar, butonlar.
  static const primary = Color(0xFFFF9800);

  /// Koyu turuncu - başlıklar.
  static const primaryDark = Color(0xFFE65100);

  /// Doğru cevap yeşili - metin ve rozet.
  static const success = Color(0xFF2E7D32);

  /// Doğru cevap butonu - biraz daha açık yeşil.
  static const successLight = Color(0xFF43A047);

  /// Doğru cevap kartının arka planı.
  static const successSurface = Color(0xFFC8E6C9);

  /// Yanlış denenen kartın arka planı - nötr gri.
  /// Kırmızı KULLANMIYORUZ: çocuğu cezalandırmıyoruz (CLAUDE.md md.18).
  static const wrongSurface = Color(0xFFEEEEEE);

  /// Kart yüzeyi.
  static const surface = Colors.white;

  /// Yıldız rengi.
  static const star = Color(0xFFFFB300);

  /// Nötr buton - ana sayfaya dön.
  static const neutral = Color(0xFF8D6E63);

  /// Ebeveyn uyarısı (ör. Türkçe ses yok) - kehribar, kırmızı değil:
  /// bir arıza değil, yapılacak bir ayar var.
  static const warning = Color(0xFFB26A00);
  static const warningSurface = Color(0xFFFFF8E1);
}
