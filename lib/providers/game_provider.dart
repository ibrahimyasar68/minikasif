import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/feedback_phrases.dart';
import '../data/question_data.dart';
import '../models/answer_option.dart';
import '../models/game_section.dart';
import '../models/question.dart';
import '../services/audio_service.dart';

/// Oyunun durumunu ve kurallarını tutan sınıf.
///
/// Bu dosya hiçbir UI widget'ı import etmez.
/// Oyun mantığı ekranı tanımaz -> ekran açmadan test edilebilir.
class GameProvider extends ChangeNotifier {
  /// Bu bölümde oynanacak sorular.
  ///
  /// Artık final DEĞİL: bölüm seçilince değişiyor.
  /// Yine de dışarıya sadece okuma amaçlı açık (private + getter).
  List<Question> _questions;

  /// Şu an oynanan bölüm.
  GameSection _section;

  /// Sesli okuma servisi.
  ///
  /// Provider somut TtsAudioService'i DEĞİL, arayüzü tanıyor.
  /// Bu yüzden testlerde sessiz bir uygulama geçebiliyoruz ve
  /// oyun mantığı testleri platform kanalına hiç dokunmuyor.
  final AudioService _audio;

  /// Test edilebilirlik için: hazır soru listesi ve ses servisi verilebilir.
  /// Verilmezse gerçek veriden ilk bölüm ve SESSİZ servis kullanılır.
  ///
  /// Varsayılan neden sessiz?
  /// Ses istemek bilinçli bir tercih olmalı. Varsayılan gerçek TTS olsaydı,
  /// her test dosyası farkında olmadan platform kanalını çağırırdı.
  GameProvider({
    List<Question>? questions,
    GameSection? section,
    AudioService audio = const SilentAudioService(),
  }) : _section = section ?? GameSection.fruits,
       _questions = questions ?? questionsOf(section ?? GameSection.fruits),
       _audio = audio;

  List<Question> get questions => _questions;

  /// Şu an oynanan bölüm.
  GameSection get section => _section;

  /// Bir bölümü baştan başlatır.
  ///
  /// Bölüm değişince oyunun TAMAMI sıfırlanır: soru sırası, skor,
  /// mevcut sorunun durumu. restart() ile aynı işi yapıyor,
  /// tek farkı önce soru listesini değiştirmesi.
  void startSection(GameSection section) {
    _section = section;
    _questions = questionsOf(section);
    _resetProgress();
    notifyListeners();
    _speakCurrentQuestion();
  }

  // --- Durum ---
  //
  // İki farklı ömre sahip state var, karıştırmamak önemli:
  //
  // 1) TÜM OYUN boyunca yaşayanlar: _currentIndex, _isCompleted
  // 2) SADECE MEVCUT SORU boyunca yaşayanlar: _isAnswered, _wrongOptionIds
  //
  // Soru değişince ikinci grup sıfırlanmalı. Unutulursa yeni soruda
  // önceki sorunun soluk kartları görünür.
  int _currentIndex = 0;
  bool _isCompleted = false;
  int _correctCount = 0;
  int _firstTryCount = 0;

  /// Kaçıncı yanlış deneme olduğu. SKOR DEĞİL: sadece teşvik
  /// cümlelerinin sırayla dönmesi için. Bölüm boyunca birikiyor ki
  /// çocuk arka arkaya hep aynı cümleyi duymasın.
  int _retryCount = 0;
  bool _isAnswered = false;
  final Set<String> _wrongOptionIds = {};

  // --- Otomatik geçiş ---

  /// Doğru cevaptan sonra EN AZ bu kadar beklenir: çocuk yeşil kartı ve
  /// ✅ işaretini görsün. Övgü daha uzun sürerse onun bitmesi beklenir.
  static const minCelebration = Duration(milliseconds: 1200);

  /// Ses motoru "bitti" haberini hiç vermezse EN FAZLA bu kadar beklenir.
  /// Oyun asla donmamalı.
  static const maxCelebration = Duration(seconds: 4);

  Timer? _minTimer;
  Timer? _maxTimer;
  bool _minPassed = false;
  bool _praiseDone = false;

  /// Her beklemenin numarası. Bekleme iptal edilince artar.
  ///
  /// Neden gerekli? Timer'lar iptal edilebilir ama bir Future (övgü sesi)
  /// iptal edilemez. İptal edilmiş eski bir beklemenin övgüsü sonradan
  /// bitince haber gelir; numara uyuşmazsa o haber yok sayılır.
  int _advanceToken = 0;
  bool _disposed = false;

  // --- Okuma ---

  /// Şu an sorulan soru.
  Question get currentQuestion => _questions[_currentIndex];

  /// Ekranda göstermek için: kaçıncı sorudayız (1'den başlar).
  int get questionNumber => _currentIndex + 1;

  /// Toplam soru sayısı.
  int get totalQuestions => _questions.length;

  /// Son soruda mıyız?
  bool get isLastQuestion => _currentIndex == _questions.length - 1;

  /// Tüm sorular bitti mi?
  bool get isCompleted => _isCompleted;

  /// Doğru cevaplanan soru sayısı.
  int get correctCount => _correctCount;

  /// HİÇ YANLIŞ YAPMADAN bilinen soru sayısı.
  ///
  /// Neden bu ölçü?
  /// Çocuk yanlış cevapta tekrar deneyebildiği için her soru eninde
  /// sonunda doğru cevaplanıyor -> correctCount hep toplam sayıya eşit
  /// çıkar ve hiçbir şey ölçmez. Asıl başarı ilk denemede bilmek.
  int get firstTryCount => _firstTryCount;

  /// Bölüm sonunda kazanılan yıldız sayısı (0-3).
  ///
  /// Neden soru başına bir yıldız değil?
  /// Bölümde 4 soru varken 4, 10 soru varken 10 yıldız çıkardı.
  /// Sabit 3 yıldız her bölüm için aynı anlama gelir ve çocuk için
  /// tanıdık bir ölçüdür.
  ///
  /// Bölümü bitiren HER ÇOCUK en az 1 yıldız alır (CLAUDE.md md.18:
  /// başarısız hissettirme). Sıfır yıldız sadece hiç oynanmadıysa.
  int get starCount {
    if (totalQuestions == 0 || _correctCount == 0) return 0;
    final oran = _firstTryCount / totalQuestions;
    if (oran >= 1.0) return 3;
    if (oran >= 0.5) return 2;
    return 1;
  }

  /// Mevcut soru doğru cevaplandı mı?
  bool get isAnswered => _isAnswered;

  /// Mevcut soruda hiç yanlış denendi mi?
  bool get hasWrongAttempt => _wrongOptionIds.isNotEmpty;

  /// Bu seçenek mevcut soruda yanlış olarak denendi mi?
  bool wasTriedWrong(AnswerOption option) =>
      _wrongOptionIds.contains(option.id);

  // --- Değiştirme ---

  /// Çocuk bir seçeneğe dokundu.
  void answer(AnswerOption option) {
    if (_isAnswered) return;

    if (currentQuestion.isCorrect(option)) {
      _isAnswered = true;
      _correctCount++;
      // Bu soruda hiç yanlış denenmediyse "ilk denemede bildi" sayılır.
      // _wrongOptionIds soru başına sıfırlandığı için bu kontrol güvenli.
      if (_wrongOptionIds.isEmpty) _firstTryCount++;
    } else {
      _wrongOptionIds.add(option.id);
      _retryCount++;
    }

    notifyListeners();
    final konusma = _speakFeedback(option);
    if (_isAnswered) _scheduleAdvance(konusma);
  }

  /// Dokunulan seçenek için sesli geri bildirim.
  ///
  /// Nesnenin adı cümlenin BAŞINDA: "Elma! Aferin!", "Muz. Bir daha
  /// deneyelim!". İki faydası var:
  /// 1. Çocuk dokunduğu şeyin adını duyuyor - kelime öğretimi.
  /// 2. Adı küçük harfe çevirmek gerekmiyor. Dart'ın toLowerCase()'i
  ///    Türkçe bilmez: "İnek" -> "i̇nek" gibi bozuk sonuç verir.
  ///
  /// Yanlış cevapta SORUYU tekrar okumuyoruz (çocuk düşünürken sözünü
  /// kesmemek için); sadece kısa, olumlu bir teşvik.
  Future<void> _speakFeedback(AnswerOption option) {
    final cumle = _isAnswered
        ? '${option.label}! ${praisePhrases[(_correctCount - 1) % praisePhrases.length]}'
        : '${option.label}. ${retryPhrases[(_retryCount - 1) % retryPhrases.length]}';
    return _audio.speak(cumle);
  }

  /// Doğru cevaptan sonra sonraki soruya geçişi planlar.
  ///
  /// Kural: övgü bitene kadar bekle, ama en az [minCelebration],
  /// en fazla [maxCelebration]. Sabit bir süre iki yönden de yanlış olurdu:
  /// kısaysa "Elma! Aferin!" yarıda kesilir (yeni soru okunmaya başlayınca
  /// önceki konuşma durur), uzunsa çocuk boşuna bekler.
  void _scheduleAdvance(Future<void> ovgu) {
    _cancelPendingAdvance();
    final token = _advanceToken;

    _minTimer = Timer(minCelebration, () {
      _minPassed = true;
      _tryAdvance(token);
    });
    _maxTimer = Timer(maxCelebration, () {
      _minPassed = true;
      _praiseDone = true;
      _tryAdvance(token);
    });

    // Övgü hata verse de "bitti" sayıyoruz: oyun takılmamalı.
    ovgu.catchError((_) {}).whenComplete(() {
      if (token != _advanceToken) return; // iptal edilmiş eski bekleme
      _praiseDone = true;
      _tryAdvance(token);
    });
  }

  void _tryAdvance(int token) {
    if (_disposed || token != _advanceToken) return;
    if (!_minPassed || !_praiseDone) return;
    nextQuestion();
  }

  /// Bekleyen otomatik geçişi iptal eder.
  void _cancelPendingAdvance() {
    _advanceToken++;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _minTimer = null;
    _maxTimer = null;
    _minPassed = false;
    _praiseDone = false;
  }

  /// Sonraki soruya geç.
  ///
  /// Normalde otomatik geçiş çağırır; testler ve ileride eklenebilecek
  /// bir "geç" butonu da doğrudan çağırabilir.
  void nextQuestion() {
    // Cevaplanmamış sorudan atlanamaz; bitmiş bölüm ikinci kez bitmez.
    if (!_isAnswered || _isCompleted) return;

    // Elle geçildiyse bekleyen otomatik geçiş İKİNCİ bir geçiş yapmasın.
    // Özellikle son soruda: "bölüm bitti" iki kez tetiklenir ve ikincisi
    // sonuç ekranındaki kutlama sesini keserdi.
    _cancelPendingAdvance();

    if (isLastQuestion) {
      _isCompleted = true;
      notifyListeners();
      // Bölüm bitti: okunacak soru yok, sesi kes.
      _audio.stop();
      return;
    }

    _currentIndex++;
    _clearQuestionState();
    notifyListeners();
    _speakCurrentQuestion();
  }

  /// Oyunu baştan başlat.
  void restart() {
    _resetProgress();
    notifyListeners();
    _speakCurrentQuestion();
  }

  /// Bölüm sonunda kutlama cümlesini okur.
  ///
  /// Metin skora göre değişiyor ama HEPSİ olumlu.
  /// Az yıldız alan çocuğa da "bölümü bitirdin" diyoruz,
  /// "az bildin" demiyoruz (CLAUDE.md md.18).
  void speakCompletion({bool yeniRekor = false}) {
    final mesaj = switch (starCount) {
      3 => 'Harikasın! Hepsini bildin.',
      2 => 'Aferin! Çok güzel oynadın.',
      _ => 'Bölümü bitirdin, tebrikler!',
    };
    // Çocuk ekrandaki "Yeni rekor!" yazısını okuyamaz: sesli de söylüyoruz.
    _audio.speak(yeniRekor ? 'Yeni rekor! $mesaj' : mesaj);
  }

  // --- Ses hazırlığı ---

  /// Cihazda Türkçe konuşabilen bir ses motoru var mı?
  ///
  /// null: kontrol henüz bitmedi. Uyarı SADECE false iken gösterilir;
  /// böylece açılışta kontrol sürerken uyarı bir an görünüp kaybolmaz.
  bool? _turkceSesVar;
  bool? get turkceSesVar => _turkceSesVar;

  /// Ses motorunu hazırlar ve Türkçe desteğini öğrenir.
  ///
  /// Uygulama açılırken bir kez çağrılır; ebeveyn "Tekrar kontrol et"e
  /// basınca yeniden. Yan faydası: motor seçimi (1-2 sn) ilk sorudan
  /// önce, açılışta yapılıyor; ilk soru gecikmeden okunuyor.
  Future<void> sesiKontrolEt() async {
    final sonuc = await _audio.hazirla(yeniden: _turkceSesVar != null);
    if (_disposed) return;
    _turkceSesVar = sonuc;
    notifyListeners();
  }

  /// Oyun veya sonuç sayfasından ayrılırken çağrılır.
  ///
  /// İki iş yapar:
  /// 1. Sesi durdurur: çocuk soru okunurken geri tuşuna basarsa ses ana
  ///    sayfada devam etmemeli.
  /// 2. Bekleyen otomatik geçişi iptal eder: sayfa kapandıktan sonra oyun
  ///    arka planda kendi kendine ilerlememeli.
  ///
  /// (Eski adı stopAudio'ydu. Artık sesten fazlasını yaptığı için adı
  /// değişti; eski ad yanıltıcı olurdu.)
  /// notifyListeners YOK: ekranda değişen bir durum yok.
  void leave() {
    _cancelPendingAdvance();
    _audio.stop();
  }

  /// Soruyu tekrar okur. Çocuk kaçırırsa 🔊 butonuyla tetiklenir.
  void repeatQuestion() => _speakCurrentQuestion();

  /// Mevcut soruyu sesli okur.
  ///
  /// Question.spokenText getter'ı burada işini yapıyor:
  /// audioText varsa onu, yoksa questionText'i döndürüyor.
  /// Provider bu ayrımı bilmek zorunda değil.
  void _speakCurrentQuestion() {
    if (_isCompleted) return;
    _audio.speak(currentQuestion.spokenText);
  }

  /// Bölümün tamamını başa alır.
  ///
  /// Skor tüm bölüm boyunca yaşar -> burada sıfırlanır,
  /// soru geçişinde DEĞİL.
  void _resetProgress() {
    _currentIndex = 0;
    _isCompleted = false;
    _correctCount = 0;
    _firstTryCount = 0;
    _retryCount = 0;
    _clearQuestionState();
  }

  /// Sadece MEVCUT SORUYA ait durumu temizler.
  ///
  /// Ayrı bir metot olmasının sebebi: hem nextQuestion hem restart
  /// aynı işi yapıyor. Tek yerde tutunca birini güncelleyip
  /// diğerini unutma riski kalmıyor.
  void _clearQuestionState() {
    _cancelPendingAdvance();
    _isAnswered = false;
    _wrongOptionIds.clear();
  }

  /// Provider kapatılırken bekleyen Timer'lar da kapatılmalı.
  /// Yoksa kapanmış bir provider'da notifyListeners çağrılır ve hata verir.
  @override
  void dispose() {
    _disposed = true;
    _cancelPendingAdvance();
    super.dispose();
  }
}
