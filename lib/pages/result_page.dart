import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/game_section.dart';
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
  const ResultPage({super.key, this.yeniRekor = false});

  /// Bu bölüm sonucu önceki en iyi skoru geçti mi?
  /// Kayıt GamePage'de yapılıyor (bkz. oradaki açıklama); sonuç buraya
  /// parametre olarak geliyor.
  final bool yeniRekor;

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
    context.read<GameProvider>().speakCompletion(yeniRekor: widget.yeniRekor);
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
    final renk = AppColors.of(context);

    // PopScope hem sistem geri tuşunu hem de "Ana sayfa" butonunun
    // popUntil'ini yakalar: ikisinde de kutlama sesi kesilmeli.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<GameProvider>().leave();
      },
      child: Scaffold(
        backgroundColor: renk.background,
        appBar: AppBar(
          backgroundColor: renk.primary,
          foregroundColor: renk.onPrimary,
          title: Text(game.section.title),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, kisit) {
              final bilgi = _bilgi(
                renk,
                game.starCount,
                game.firstTryCount,
                game.totalQuestions,
              );
              final butonlar = _butonlar(context, renk, sonrakiBolum);

              // Yatay: kutlama solda, butonlar sağda. Alt alta dizilince
              // butonlar ekranın altında kalıyordu (bkz. GamePage).
              if (kisit.maxWidth > kisit.maxHeight) {
                return Row(
                  children: [
                    Expanded(
                      // FittedBox: yer darsa kutlama bilgisi taşmak veya
                      // kaydırılmak yerine biraz küçülür. Burada dokunulacak
                      // bir şey yok; küçülmesi sorun değil.
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: 340, child: bilgi),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: butonlar,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Center şart: Scaffold gövdeye gevşek genişlik kısıtı verir,
              // Column büzülüp sola yapışır (bkz. test/layout_test.dart).
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [bilgi, const SizedBox(height: 36), butonlar],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Kutlama, yıldızlar, rekor ve ebeveyn için özet.
  Widget _bilgi(AppColors renk, int yildiz, int ilkDenemede, int toplam) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 88)),
        const SizedBox(height: 12),
        Text(
          'Tebrikler!',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: renk.success,
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
                i < yildiz ? Icons.star : Icons.star_border,
                size: 56,
                color: renk.star,
              ),
          ],
        ),

        if (widget.yeniRekor) ...[
          const SizedBox(height: 12),
          Text(
            'Yeni rekor! 🏆',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: renk.primaryDark,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Bu satır ÇOCUK için değil, ebeveyn için.
        // Küçük ve sade tutuyoruz ki ekranı kalabalıklaştırmasın.
        Text(
          '$toplam sorudan $ilkDenemede tanesini ilk denemede bildin',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: renk.textMuted),
        ),
      ],
    );
  }

  /// Tekrar oyna, (varsa) sonraki bölüm, ana sayfa.
  Widget _butonlar(
    BuildContext context,
    AppColors renk,
    GameSection? sonrakiBolum,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SonucButonu(
          etiket: 'Tekrar oyna',
          emoji: '🔁',
          renk: renk.primary,
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
            renk: renk.successLight,
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
          renk: renk.neutral,
          // popUntil: ilk sayfaya kadar tüm sayfaları kapatır.
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ],
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
          foregroundColor: AppColors.of(context).onPrimary,
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
