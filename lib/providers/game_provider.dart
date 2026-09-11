import 'package:flutter/foundation.dart';
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
  bool _isAnswered = false;
  final Set<String> _wrongOptionIds = {};

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
    }

    notifyListeners();
  }

  /// Sonraki soruya geç.
  void nextQuestion() {
    // Cevaplanmamış sorudan atlanamaz.
    if (!_isAnswered) return;

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
  void speakCompletion() {
    final mesaj = switch (starCount) {
      3 => 'Harikasın! Hepsini bildin.',
      2 => 'Aferin! Çok güzel oynadın.',
      _ => 'Bölümü bitirdin, tebrikler!',
    };
    _audio.speak(mesaj);
  }

  /// Devam eden okumayı durdurur.
  ///
  /// Sayfadan çıkılınca çağrılır: çocuk soru okunurken geri tuşuna
  /// basarsa ses ana sayfada devam etmemeli.
  /// notifyListeners YOK: ekranda değişen bir durum yok.
  void stopAudio() => _audio.stop();

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
    _clearQuestionState();
  }

  /// Sadece MEVCUT SORUYA ait durumu temizler.
  ///
  /// Ayrı bir metot olmasının sebebi: hem nextQuestion hem restart
  /// aynı işi yapıyor. Tek yerde tutunca birini güncelleyip
  /// diğerini unutma riski kalmıyor.
  void _clearQuestionState() {
    _isAnswered = false;
    _wrongOptionIds.clear();
  }
}
