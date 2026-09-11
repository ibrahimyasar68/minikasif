import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/answer_option.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/answer_card.dart';
import '../widgets/answer_grid.dart';
import 'result_page.dart';

/// Oyun ekranı.
///
/// Neden StatefulWidget oldu?
/// Ekranda gösterdiği her şeyi hâlâ GameProvider'dan okuyor; kendi OYUN
/// durumu yok. Ama artık bir işi daha var: bölüm kendiliğinden
/// (otomatik geçişle) bittiğinde sonuç sayfasını açmak. Bunun için
/// provider'ı dinlemesi (addListener) ve sayfa kapanınca dinlemeyi
/// bırakması (removeListener) gerekiyor. İkisi de State'in yaşam
/// döngüsüne ait: initState ve dispose.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameProvider _game;

  /// Sonuç sayfası bir kez açılsın.
  bool _sonucaGecildi = false;

  @override
  void initState() {
    super.initState();
    // context.read initState'te serbest; yasak olan build içinde çağırmak.
    _game = context.read<GameProvider>();
    _game.addListener(_bolumBittiyseSonucaGec);
  }

  @override
  void dispose() {
    // Dinleyiciyi kaldırmazsak sayfa kapandıktan sonra da çağrılmaya
    // devam eder ve artık var olmayan bir context ile Navigator açmaya
    // çalışır.
    _game.removeListener(_bolumBittiyseSonucaGec);
    super.dispose();
  }

  /// Bölüm bittiyse sonuç sayfasını açar.
  ///
  /// Neden build içinde değil?
  /// build ekranı TARİF eder; sayfa açmak bir yan etkidir. build içinde
  /// Navigator çağırmak "setState() or markNeedsBuild() called during
  /// build" hatasına yol açar. Dinleyici ise build dışında, provider
  /// notifyListeners() çağırdığında çalışır.
  ///
  /// mounted: bu State hâlâ ekrana bağlı mı? Kapanmış bir sayfanın
  /// context'iyle Navigator kullanılamaz.
  void _bolumBittiyseSonucaGec() {
    if (!_game.isCompleted || _sonucaGecildi || !mounted) return;
    _sonucaGecildi = true;

    // Skoru kaydet; en iyi skoru geçtiyse yeni rekor.
    //
    // Neden BURADA, ResultPage.initState'te değil?
    // kaydet() notifyListeners() çağırıyor; bu da arkadaki ana sayfaya
    // "yeniden çizil" diyor. initState ise ResultPage ÇİZİLİRKEN çalışır.
    // Çizim sırasında başka bir widget'ı "yeniden çizilecek" diye
    // işaretlemek "setState() or markNeedsBuild() called during build"
    // hatasıdır. Bu metot ise bir dinleyici: çizimin dışında, güvenli.
    final yeniRekor = context.read<ProgressProvider>().kaydet(
      _game.section,
      _game.starCount,
    );

    // pushReplacement: geri tuşuyla bitmiş soruya dönülmesin.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ResultPage(yeniRekor: yeniRekor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final renk = AppColors.of(context);

    // PopScope: bu sayfadan GERİ çıkılınca haber verir.
    //
    // Soru okunurken geri tuşuna basılırsa ses ana sayfada da
    // sürüyordu. Sayfa kapanırken sesi durduruyoruz.
    //
    // leave() hem sesi durdurur hem de bekleyen otomatik geçişi
    // iptal eder: sayfa kapandıktan sonra oyun arka planda ilerlemesin.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _game.leave();
      },
      child: Scaffold(
        backgroundColor: renk.background,
        appBar: AppBar(
          backgroundColor: renk.primary,
          foregroundColor: renk.onPrimary,
          title: Text('Soru ${game.questionNumber} / ${game.totalQuestions}'),
        ),
        body: SafeArea(
          // Küçük ekranda veya büyük yazı tipi ayarında içerik sığmayabilir.
          // Taşma yerine kaydırma istiyoruz.
          //
          // Kalıp şu: SingleChildScrollView içeriği serbest bırakır,
          // ConstrainedBox ise "en az ekran kadar uzun ol" der.
          // Böylece içerik kısaysa Center ortalar, uzunsa kaydırılır.
          child: LayoutBuilder(
            builder: (context, kisit) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: kisit.maxHeight - 40),
                  // Center yatay ortalama için de şart
                  // (bkz. test/layout_test.dart).
                  child: const Center(child: _QuestionView()),
                ),
              );
            },
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
    final renk = AppColors.of(context);
    final question = game.currentQuestion;
    final sesAcik = context.select<SettingsProvider, bool>((a) => a.sesAcik);

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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: renk.primaryDark,
            ),
          ),

          const SizedBox(height: 12),

          // Soruyu tekrar dinle.
          // Çocuk sesi kaçırabilir veya tekrar duymak isteyebilir.
          // Okuma yazma gerektirmeyen tek erişim yolu bu.
          // Türkçe ses yoksa bu buton hiçbir şey yapmaz; hiç göstermiyoruz.
          // İşe yaramayan bir buton çocuğun kafasını karıştırır.
          if (sesAcik && game.turkceSesVar != false)
            IconButton(
              onPressed: () => context.read<GameProvider>().repeatQuestion(),
              icon: const Icon(Icons.volume_up_rounded),
              iconSize: 48,
              color: renk.primary,
              tooltip: 'Tekrar dinle',
            ),

          const SizedBox(height: 20),

          AnswerGrid(
            options: question.options,
            statusOf: (option) => _statusFor(game, option),
            onTap: game.isAnswered
                ? null
                : (option) => context.read<GameProvider>().answer(option),
          ),

          const SizedBox(height: 32),

          // Doğru cevaptan sonra buton YOK: övgü bitince sonraki soruya
          // kendiliğinden geçiliyor (GameProvider._scheduleAdvance).
          Text(
            _feedbackText(game),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: game.isAnswered ? renk.success : renk.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
