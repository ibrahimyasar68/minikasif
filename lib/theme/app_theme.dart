import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Açık ve koyu tema. İkisi de aynı turuncu tohum rengini kullanır;
/// farkı parlaklık (Brightness) ve bizim renk setimiz (AppColors).
ThemeData _tema(Brightness parlaklik, AppColors renk) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: parlaklik,
  ),
  scaffoldBackgroundColor: renk.background,
  extensions: [renk],
);

final acikTema = _tema(Brightness.light, AppColors.light);
final koyuTema = _tema(Brightness.dark, AppColors.dark);
