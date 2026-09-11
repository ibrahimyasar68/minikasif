import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/answer_option.dart';
import '../providers/game_provider.dart';
import '../widgets/answer_card.dart';
import 'result_page.dart';

/// Oyun ekranı. Kendi state'i yok; her şeyi GameProvider'dan okur.
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        title: Text('Soru ${game.questionNumber} / ${game.totalQuestions}'),
      ),
      body: SafeArea(
        // Center ŞART.
        //
        // Scaffold gövdeye GEVŞEK genişlik kısıtı verir (minWidth=0).
        // Bu durumda Column en geniş çocuğu kadar büzülür ve sol kenara
        // yapışır; içerik ekranda sola kaymış görünür.
        // Center, büzülen Column'u yatayda ortalar.
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: const _QuestionView(),
          ),
        ),
      ),
    );
  }
}

/// Soru + seçenekler + geri bildirim.
///
/// Ayrı bir widget'a aldım çünkü GamePage.build'i uzuyordu.
/// Alt çizgi ile başlıyor: sadece bu dosyada kullanılıyor.
class _QuestionView extends StatelessWidget {
  const _QuestionView();

  /// Bir seçeneğin kartı hangi durumda görünmeli?
  /// Bu bir GÖRÜNÜM kararı, o yüzden provider'da değil burada.
  AnswerStatus _statusFor(GameProvider game, AnswerOption option) {
    if (game.isAnswered && game.currentQuestion.isCorrect(option)) {
      return AnswerStatus.correct;
    }
    if (game.wasTriedWrong(option)) return AnswerStatus.wrong;
    return AnswerStatus.normal;
  }

  String _feedbackText(GameProvider game) {
    if (game.isAnswered) return 'Aferin! 🎉';
    if (game.hasWrongAttempt) return 'Tekrar dene 🙂';
    return 'Bir seçeneğe dokun';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final question = game.currentQuestion;

    // AnimatedSwitcher: child'ın KEY'i değişince eskiyi soldurup
    // yeniyi belirtir. Anahtar soru id'si olduğu için:
    //   - soru değişince  -> geçiş animasyonu
    //   - aynı soru içinde (cevap verilince) -> animasyon YOK, normal rebuild
    // Böylece her dokunuşta ekran titremiyor.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Column(
        key: ValueKey(question.id),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),

          const SizedBox(height: 12),

          // Soruyu tekrar dinle.
          // Çocuk sesi kaçırabilir veya tekrar duymak isteyebilir.
          // Okuma yazma gerektirmeyen tek erişim yolu bu.
          IconButton(
            onPressed: () => context.read<GameProvider>().repeatQuestion(),
            icon: const Icon(Icons.volume_up_rounded),
            iconSize: 48,
            color: const Color(0xFFFF9800),
            tooltip: 'Tekrar dinle',
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final option in question.options)
                AnswerCard(
                  option: option,
                  status: _statusFor(game, option),
                  onTap: game.isAnswered
                      ? null
                      : () => context.read<GameProvider>().answer(option),
                ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            _feedbackText(game),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: game.isAnswered ? const Color(0xFF2E7D32) : Colors.black54,
            ),
          ),

          const SizedBox(height: 24),

          // Devam butonu SADECE doğru cevaptan sonra görünür.
          //
          // Görünmez bir buton yerine hiç oluşturmuyoruz.
          // SizedBox.shrink() = yer kaplamayan boş widget.
          // Çocuk yanlış yerlere dokunup kazara ilerleyemesin.
          //
          // AnimatedSwitcher buton aniden belirmesin diye:
          // yumuşak bir geçiş dikkati doğru yere çeker.
          // Butona HER ZAMAN yer ayırıyoruz.
          //
          // İki faydası var:
          // 1. Cevap verilince layout zıplamıyor.
          // 2. Soru geçişinde eski ve yeni içerik aynı yükseklikte olduğu
          //    için çapraz geçiş kayarak değil, düzgün soluyor.
          SizedBox(
            height: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: game.isAnswered
                  ? SizedBox(
                      // ANAHTAR ŞART.
                      // AnimatedSwitcher eski/yeni çocuğu runtimeType + key ile
                      // karşılaştırır. İkisi de anahtarsız SizedBox olunca
                      // Flutter onları AYNI widget sayıp geçişi atlıyordu.
                      key: const ValueKey('devam-butonu'),
                      width: 260,
                      height: 80,
                      child: ElevatedButton(
                        // Son soruda bu buton bölümü bitirir ve sonuç
                        // sayfasına geçer.
                        //
                        // Yönlendirme neden BURADA, build içinde değil?
                        // build'in tek işi ekranı tarif etmektir; sayfa
                        // açmak bir YAN ETKİdir ve build'e ait değildir.
                        // Bir olayın (dokunma) içindeyiz, doğru yer burası.
                        onPressed: () {
                          final oyun = context.read<GameProvider>();
                          oyun.nextQuestion();
                          if (!oyun.isCompleted) return;

                          // pushReplacement: geri tuşuyla bitmiş soruya
                          // dönülmesin.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResultPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          game.isLastQuestion ? 'Bitir 🏁' : 'Devam →',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('buton-yok')),
            ),
          ),
        ],
      ),
    );
  }
}
