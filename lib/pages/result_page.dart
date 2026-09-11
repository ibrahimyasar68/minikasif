import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_page.dart';

/// Bölüm sonu ekranı.
///
/// Neden ayrı bir SAYFA?
/// Önce GamePage'in içinde bir görünümdü. Ayırmanın faydası:
/// - GamePage'in tek işi kaldı: soru göster.
/// - Sonuç ekranı kendi durumuna (initState) sahip olabiliyor.
///
/// Skoru nasıl görüyor?
/// GameProvider MaterialApp'in ÜSTÜNDE yaşadığı için bu sayfa da
/// aynı provider'a ulaşabiliyor. Skoru parametre olarak taşımaya
/// gerek yok - Provider'ı en başta bu yüzden oraya koymuştuk.
///
/// Neden StatefulWidget?
/// Ekranda değişen veri yok; ama sayfa AÇILDIĞINDA bir kez kutlama
/// sesi çalmamız gerekiyor. Bu "bir kez" işi initState'e ait.
class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    // initState build'den ÖNCE, sayfa ömründe BİR KEZ çalışır.
    // Kutlamayı build içine koysaydık her yeniden çizimde tekrar çalardı.
    //
    // context.read kullanıyoruz (watch değil): burada dinlemiyoruz,
    // sadece bir metot çağırıyoruz.
    context.read<GameProvider>().speakCompletion();
  }

  /// Oyun ekranını mevcut sayfanın YERİNE açar.
  ///
  /// pushReplacement kullanıyoruz: geri tuşuna basınca bitmiş bir
  /// sonuç ekranına dönmek istemiyoruz.
  void _oyunaGit() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GamePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final sonrakiBolum = game.section.next;

    // PopScope hem sistem geri tuşunu hem de "Ana sayfa" butonunun
    // popUntil'ini yakalar: ikisinde de kutlama sesi kesilmeli.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<GameProvider>().stopAudio();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(game.section.title),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          // Center şart: Scaffold gövdeye gevşek genişlik kısıtı verir,
          // Column büzülüp sola yapışır (bkz. test/layout_test.dart).
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 88)),
                  const SizedBox(height: 12),
                  const Text(
                    'Tebrikler!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Skoru rakamla değil yıldızla gösteriyoruz:
                  // hedef kitle okuyamıyor.
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < game.starCount ? Icons.star : Icons.star_border,
                          size: 56,
                          color: AppColors.star,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Bu satır ÇOCUK için değil, ebeveyn için.
                  // Küçük ve sade tutuyoruz ki ekranı kalabalıklaştırmasın.
                  Text(
                    '${game.totalQuestions} sorudan ${game.firstTryCount} tanesini '
                    'ilk denemede bildin',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),

                  const SizedBox(height: 36),

                  _SonucButonu(
                    etiket: 'Tekrar oyna',
                    emoji: '🔁',
                    renk: AppColors.primary,
                    onTap: () {
                      context.read<GameProvider>().restart();
                      _oyunaGit();
                    },
                  ),

                  // Sonraki bölüm SADECE varsa gösterilir.
                  // Son bölümdeysek bu buton hiç oluşturulmaz.
                  if (sonrakiBolum != null) ...[
                    const SizedBox(height: 16),
                    _SonucButonu(
                      etiket: sonrakiBolum.title,
                      emoji: sonrakiBolum.emoji,
                      renk: AppColors.successLight,
                      onTap: () {
                        context.read<GameProvider>().startSection(sonrakiBolum);
                        _oyunaGit();
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  _SonucButonu(
                    etiket: 'Ana sayfa',
                    emoji: '🏠',
                    renk: AppColors.neutral,
                    // popUntil: ilk sayfaya kadar tüm sayfaları kapatır.
                    onTap: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sonuç ekranındaki büyük butonlar.
/// Üçü de aynı şekle sahip; tekrar yazmamak için tek widget.
class _SonucButonu extends StatelessWidget {
  final String etiket;
  final String emoji;
  final Color renk;
  final VoidCallback onTap;

  const _SonucButonu({
    required this.etiket,
    required this.emoji,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 78,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: renk,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                etiket,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
