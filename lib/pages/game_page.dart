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
          child: LayoutBuilder(
            builder: (context, kisit) {
              // Yatay ekran: alt alta dizilince kartlar ekranın altında
              // kalıyordu. Soru solda, kartlar sağda.
              //
              // Neden MediaQuery.orientationOf değil de kısıtlar?
              // Bölünmüş ekranda telefon dik dururken bile uygulamaya ayrılan
              // alan yatay olabilir. Belirleyici olan telefonun yönü değil,
              // bu sayfaya kalan alanın şekli.
              if (kisit.maxWidth > kisit.maxHeight) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: _QuestionView(yatay: true),
                );
              }

              // Küçük ekranda veya büyük yazı tipi ayarında içerik
              // sığmayabilir. Taşma yerine kaydırma istiyoruz.
              //
              // Kalıp şu: SingleChildScrollView içeriği serbest bırakır,
              // ConstrainedBox ise "en az ekran kadar uzun ol" der.
              // Böylece içerik kısaysa Center ortalar, uzunsa kaydırılır.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: kisit.maxHeight - 40),
                  // Center yatay ortalama için de şart
                  // (bkz. test/layout_test.dart).
                  child: const Center(child: _QuestionView(yatay: false)),
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
  const _QuestionView({required this.yatay});

  /// true: soru solda, kartlar sağda. false: hepsi alt alta.
  final bool yatay;

  /// Bir seçeneğin kartı hangi durumda görünmeli?
  /// Bu bir GÖRÜNÜM kararı, o yüzden provider'da değil burada.
  AnswerStatus _statusFor(GameProvider game, AnswerOption option) {
    if (game.isAnswered && game.currentQuestion.isCorrect(option)) {
      return AnswerStatus.correct;
    }
    if (game.wasTriedWrong(option)) return AnswerStatus.wrong;
    return AnswerStatus.normal;
  }

  /// Soru geçişi: önce eski söner, SONRA yeni belirir.
  ///
  /// Varsayılan geçiş çapraz solmaydı: eski solarken yeni aynı anda
  /// beliriyordu ve iki soru metni bir an iç içe görünüyordu.
  ///
  /// AnimatedSwitcher her çocuğa kendi animasyonunu verir:
  ///   yeni gelen: 0 -> 1 (320 ms)
  ///   giden     : 1 -> 0 (aynı süre, tersine)
  /// Interval(0.5, 1.0) ikisinde de görünürlüğü animasyonun üst yarısına
  /// sıkıştırır. Giden ilk 160 ms'de tamamen söner; gelen son 160 ms'de
  /// belirir. Aynı anda ikisinin de görünür olduğu bir an yok.
  ///
  /// IgnorePointer: geçiş sürerken kartlar dokunmaya kapalı. Yoksa çocuk
  /// henüz görünmeyen yeni karta (ya da sönen eski karta) dokunabilirdi.
  static Widget _onceSonSonraBelir(Widget child, Animation<double> animasyon) {
    return AnimatedBuilder(
      animation: animasyon,
      // child parametresi: FadeTransition her karede yeniden KURULMAZ;
      // yalnızca IgnorePointer'ın değeri güncellenir.
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animasyon,
          curve: const Interval(0.5, 1.0),
        ),
        child: child,
      ),
      builder: (context, solma) => IgnorePointer(
        ignoring: animasyon.status != AnimationStatus.completed,
        child: solma,
      ),
    );
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

    final soruMetni = Text(
      question.questionText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: renk.primaryDark,
      ),
    );

    // Soruyu tekrar dinle.
    // Çocuk sesi kaçırabilir veya tekrar duymak isteyebilir.
    // Okuma yazma gerektirmeyen tek erişim yolu bu.
    // Türkçe ses yoksa bu buton hiçbir şey yapmaz; hiç göstermiyoruz.
    // İşe yaramayan bir buton çocuğun kafasını karıştırır.
    final tekrarDinle = sesAcik && game.turkceSesVar != false
        ? IconButton(
            onPressed: () => context.read<GameProvider>().repeatQuestion(),
            icon: const Icon(Icons.volume_up_rounded),
            iconSize: 48,
            color: renk.primary,
            tooltip: 'Tekrar dinle',
          )
        : null;

    final kartlar = AnswerGrid(
      options: question.options,
      statusOf: (option) => _statusFor(game, option),
      onTap: game.isAnswered
          ? null
          : (option) => context.read<GameProvider>().answer(option),
    );

    // Doğru cevaptan sonra buton YOK: övgü bitince sonraki soruya
    // kendiliğinden geçiliyor (GameProvider._scheduleAdvance).
    final geriBildirim = Text(
      _feedbackText(game),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: game.isAnswered ? renk.success : renk.textMuted,
      ),
    );

    // AnimatedSwitcher: child'ın KEY'i değişince eskiyi soldurup
    // yeniyi belirtir. Anahtar soru id'si olduğu için:
    //   - soru değişince  -> geçiş animasyonu
    //   - aynı soru içinde (cevap verilince) -> animasyon YOK, normal rebuild
    // Böylece her dokunuşta ekran titremiyor.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: _onceSonSonraBelir,
      child: yatay
          ? Row(
              key: ValueKey(question.id),
              children: [
                // Sol: soru, tekrar dinle, geri bildirim.
                // Normalde rahatça sığıyor; kaydırma yalnızca telefonda
                // "büyük yazı" ayarı açıkken devreye giren bir yedek.
                Expanded(
                  flex: 2,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          soruMetni,
                          const SizedBox(height: 8),
                          ?tekrarDinle,
                          const SizedBox(height: 16),
                          geriBildirim,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ: kartlar. Yükseklik burada SINIRLI; AnswerGrid kart
                // boyutunu ekrana sığacak şekilde küçültür.
                Expanded(flex: 3, child: Center(child: kartlar)),
              ],
            )
          : Column(
              key: ValueKey(question.id),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                soruMetni,
                const SizedBox(height: 12),
                ?tekrarDinle,
                const SizedBox(height: 20),
                kartlar,
                const SizedBox(height: 32),
                geriBildirim,
              ],
            ),
    );
  }
}
