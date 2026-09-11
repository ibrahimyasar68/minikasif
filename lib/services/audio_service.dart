import 'package:flutter_tts/flutter_tts.dart';

/// Sesli okuma sorumluluğunu tanımlayan ARAYÜZ.
///
/// Neden doğrudan FlutterTts kullanmıyoruz?
///
/// 1) DEĞİŞTİRİLEBİLİRLİK: İleride TTS yerine önceden kaydedilmiş
///    insan sesi (.mp3) kullanmak istersek, sadece bu arayüzün yeni bir
///    uygulamasını yazarız. GameProvider ve GamePage hiçbir şey bilmez.
///
/// 2) TEST EDİLEBİLİRLİK: FlutterTts platform kanalı kullanır, yani
///    gerçek cihaz/emülatör ister. Testte çalışmaz. Arayüz sayesinde
///    testlerde sessiz bir uygulama geçebiliyoruz.
///
/// abstract = bu sınıftan nesne üretilemez, sadece "sözleşme" tanımlar.
abstract class AudioService {
  /// Verilen metni sesli okur.
  Future<void> speak(String text);

  /// Devam eden okumayı durdurur.
  Future<void> stop();
}

/// Hiçbir şey yapmayan uygulama.
///
/// Testlerde ve sesin kapalı olduğu durumlarda kullanılır.
/// "Null Object" denen desen: null kontrolü yapmak yerine
/// hiçbir şey yapmayan bir nesne veriyoruz.
class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

/// Cihazın kendi metin okuma motorunu kullanan gerçek uygulama.
class TtsAudioService implements AudioService {
  final FlutterTts _tts = FlutterTts();

  /// Ayarlar sadece bir kez yapılsın.
  bool _isConfigured = false;

  Future<void> _configure() async {
    if (_isConfigured) return;
    await _tts.setLanguage('tr-TR');
    // Çocuklar için yavaş konuşma. 1.0 yetişkin hızı, bu fazla hızlı olur.
    await _tts.setSpeechRate(0.40);
    // Hafif tiz: çocuklara daha sıcak geliyor.
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    // speak() konuşma BİTİNCE tamamlansın. Varsayılanda hemen döner.
    // Otomatik geçiş övgünün bitmesini bu sayede bekleyebiliyor;
    // yoksa yeni soru okunmaya başlayınca "Elma! Aferin!" yarıda kesilirdi.
    await _tts.awaitSpeakCompletion(true);
    _isConfigured = true;
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _configure();
      // Önceki okumayı kes: çocuk hızlı ilerlerse sesler üst üste binmesin.
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Ses çalışmazsa oyun DURMAMALI.
      // Cihazda Türkçe TTS motoru olmayabilir; bu oyunu oynanamaz
      // yapmamalı. Sessizce devam ediyoruz.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
