import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/answer_option.dart';
import '../providers/game_provider.dart';
import '../widgets/answer_card.dart';

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
        // Oyun bitince ilerleme yazmanın anlamı yok.
        title: Text(
          game.isCompleted
              ? game.section.title
              : 'Soru ${game.questionNumber} / ${game.totalQuestions}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          // Oyun bittiyse tamamen farklı bir ekran gösteriyoruz.
          child: game.isCompleted
              ? const _CompletedView()
              : const _QuestionView(),
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

    return Column(
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
        if (game.isAnswered)
          SizedBox(
            width: 260,
            height: 80,
            child: ElevatedButton(
              onPressed: () => context.read<GameProvider>().nextQuestion(),
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
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

/// Tüm sorular bitince görünen ekran.
///
/// GEÇİCİ: Sonuç ekranı (skor, doğru sayısı) ayrı bir sayfa olarak
/// ilerideki aşamada gelecek. Şimdilik akışın kapandığını görelim.
class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 96)),
        const SizedBox(height: 16),
        const Text(
          'Tebrikler!',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 24),

        // Skoru rakamla değil YILDIZLA gösteriyoruz.
        // Hedef kitle okuyamıyor; "2/3" hiçbir şey ifade etmez.
        // Dolu yıldız = ilk denemede bilinen soru.
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                i < game.starCount ? Icons.star : Icons.star_border,
                size: 52,
                color: const Color(0xFFFFB300),
              ),
          ],
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: 260,
          height: 80,
          child: ElevatedButton(
            onPressed: () => context.read<GameProvider>().restart(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Tekrar oyna',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
