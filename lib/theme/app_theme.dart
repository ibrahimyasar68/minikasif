import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Açık ve koyu tema. İkisi de aynı turuncu tohum rengini kullanır;
/// farkı parlaklık (Brightness) ve bizim renk setimiz (AppColors).
///
/// fontFamilyFallback: harf fontunda BULUNMAYAN karakterler için sırayla
/// denenecek fontlar. Emojiler böylece telefonun kendi emoji fontundan
/// değil, uygulamaya gömülü fonttan çizilir: her cihazda aynı görünürler
/// ve eski Android sürümlerindeki eksik emoji sorunu ortadan kalkar.
/// Yedek listede olduğu için harfler ve rakamlar etkilenmez.
ThemeData _tema(Brightness parlaklik, AppColors renk) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: parlaklik,
  ),
  scaffoldBackgroundColor: renk.background,
  fontFamilyFallback: const [emojiFontu],
  extensions: [renk],
);

/// Gömülü emoji fontunun pubspec.yaml'daki aile adı.
const emojiFontu = 'NotoColorEmoji';

final acikTema = _tema(Brightness.light, AppColors.light);
final koyuTema = _tema(Brightness.dark, AppColors.dark);
