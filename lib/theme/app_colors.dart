import 'package:flutter/material.dart';

/// Uygulamanın renk paleti: açık ve koyu tema için iki ayrı set.
///
/// Neden ThemeExtension?
/// Eskiden renkler SABİTTİ (static const). Koyu temada krem arka plan,
/// beyaz kart ve siyah yazı yanlış olur. ThemeExtension kendi renk setimizi
/// Flutter'ın tema sistemine ekler: MaterialApp o anki temaya (açık/koyu)
/// göre doğru seti verir, ekranlar `AppColors.of(context)` ile okur.
///
/// Renkler ANLAMA göre adlandırıldı (background, text...), değere göre
/// değil (krem, siyah...): koyu temada "text" açık renkli oluyor.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.primaryDark,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.successLight,
    required this.successSurface,
    required this.wrongSurface,
    required this.star,
    required this.neutral,
    required this.warning,
    required this.warningSurface,
  });

  /// Ekran arka planı.
  final Color background;

  /// Kart ve buton yüzeyi.
  final Color surface;

  /// Ana vurgu rengi - AppBar, butonlar.
  final Color primary;

  /// Ana renk üstündeki yazı/simge.
  final Color onPrimary;

  /// Başlıklar.
  final Color primaryDark;

  /// Normal metin.
  final Color text;

  /// İkincil, soluk metin.
  final Color textMuted;

  /// Doğru cevap yeşili - metin ve rozet.
  final Color success;

  /// Doğru/ilerleme butonu.
  final Color successLight;

  /// Doğru cevap kartının arka planı.
  final Color successSurface;

  /// Yanlış denenen kart - nötr. Kırmızı KULLANMIYORUZ: çocuğu
  /// cezalandırmıyoruz (CLAUDE.md md.24).
  final Color wrongSurface;

  /// Yıldız.
  final Color star;

  /// Nötr buton - ana sayfaya dön.
  final Color neutral;

  /// Ebeveyn uyarısı - kehribar, kırmızı değil: arıza değil, eksik ayar.
  final Color warning;
  final Color warningSurface;

  static const light = AppColors(
    background: Color(0xFFFFF3E0), // sıcak krem
    surface: Colors.white,
    primary: Color(0xFFFF9800),
    onPrimary: Colors.white,
    primaryDark: Color(0xFFE65100),
    text: Color(0xDD000000),
    textMuted: Color(0x8A000000),
    success: Color(0xFF2E7D32),
    successLight: Color(0xFF43A047),
    successSurface: Color(0xFFC8E6C9),
    wrongSurface: Color(0xFFEEEEEE),
    star: Color(0xFFFFB300),
    neutral: Color(0xFF8D6E63),
    warning: Color(0xFFB26A00),
    warningSurface: Color(0xFFFFF8E1),
  );

  /// Koyu tema: saf siyah değil, sıcak koyu kahve. Çocuk uygulamasında
  /// sert siyah soğuk durur; turuncu vurgu aynı kalıyor.
  static const dark = AppColors(
    background: Color(0xFF1F1A16),
    surface: Color(0xFF2E2722),
    primary: Color(0xFFFF9800),
    onPrimary: Colors.white,
    primaryDark: Color(0xFFFFB74D), // koyu zeminde okunsun diye açık turuncu
    text: Color(0xDEFFFFFF),
    textMuted: Color(0x99FFFFFF),
    success: Color(0xFF81C784),
    successLight: Color(0xFF43A047),
    successSurface: Color(0xFF2E4A30),
    wrongSurface: Color(0xFF3A3430),
    star: Color(0xFFFFC107),
    neutral: Color(0xFF8D6E63),
    warning: Color(0xFFFFB74D),
    warningSurface: Color(0xFF3E2F14),
  );

  /// O anki temanın renkleri.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  // ThemeExtension'ın zorunlu iki metodu. copyWith: bazı renkleri
  // değiştirip kopya üretir. lerp: tema değişiminde iki palet arasında
  // yumuşak geçiş (MaterialApp temayı animasyonla değiştirir).
  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? onPrimary,
    Color? primaryDark,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? successLight,
    Color? successSurface,
    Color? wrongSurface,
    Color? star,
    Color? neutral,
    Color? warning,
    Color? warningSurface,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryDark: primaryDark ?? this.primaryDark,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successSurface: successSurface ?? this.successSurface,
      wrongSurface: wrongSurface ?? this.wrongSurface,
      star: star ?? this.star,
      neutral: neutral ?? this.neutral,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryDark: l(primaryDark, other.primaryDark),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      successLight: l(successLight, other.successLight),
      successSurface: l(successSurface, other.successSurface),
      wrongSurface: l(wrongSurface, other.wrongSurface),
      star: l(star, other.star),
      neutral: l(neutral, other.neutral),
      warning: l(warning, other.warning),
      warningSurface: l(warningSurface, other.warningSurface),
    );
  }
}
