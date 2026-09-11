import 'package:flutter/foundation.dart';
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

/// Türkçe konuşabilen bir ses motoru seçer.
///
/// [motorlar] cihazda yüklü motorların adları. [motoraGecVeDene] verilen
/// motora geçer ve o motorun Türkçe bilip bilmediğini döndürür.
/// Google motoru önce denenir: Türkçe desteği en yaygın olan o.
/// Hiçbiri Türkçe bilmiyorsa null döner.
///
/// Neden ayrı bir fonksiyon? Karar mantığı platform kanalından bağımsız
/// olsun ve testte sahte motorlarla sınanabilsin.
Future<String?> turkceMotorSec(
  List<String> motorlar,
  Future<bool> Function(String motor) motoraGecVeDene,
) async {
  final sirali = [
    ...motorlar.where((m) => m.contains('google')),
    ...motorlar.where((m) => !m.contains('google')),
  ];
  for (final motor in sirali) {
    if (await motoraGecVeDene(motor)) return motor;
  }
  return null;
}

/// Cihazın kendi metin okuma motorunu kullanan gerçek uygulama.
class TtsAudioService implements AudioService {
  /// [tts] sadece testler için: sahte bir motor verilebilsin.
  TtsAudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// Her konuşma isteğinin sıra numarası. EN SON İSTEK KAZANIR.
  ///
  /// Gerçek telefonda görüldü: iki istek aynı anda gelince (ör. soru
  /// okunacakken çocuk hemen bir karta dokununca) ikisi de ayarlamayı
  /// bekledi, sonra "dur, dur, konuş, konuş" sırasıyla çalıştı. Android
  /// eklentisi bir konuşma sürerken araya stop() girmeden gelen yeni
  /// speak()'i SESSİZCE REDDEDİYOR; çocuğun dokunuşuna verilen cevap
  /// kayboluyordu. Artık eskiyen istek hiç konuşmuyor.
  int _sonIstek = 0;

  /// Ayarlama işi. Bir kez başlatılır; aynı anda gelen bütün konuşma
  /// istekleri AYNI işi bekler.
  ///
  /// Gerçek telefonda görüldü: motor değiştirmek 1-2 sn sürüyor. Eskiden
  /// bu sırada gelen ikinci/üçüncü speak() çağrıları "henüz ayarlanmadı"
  /// görüp ayarlamayı baştan başlatıyordu; motor seçimi aynı anda birkaç
  /// kez çalışıyordu. Bool bayrak bunu engelleyemez, çünkü bayrak ancak
  /// iş BİTİNCE true olur. Future'ı saklamak iş BAŞLARKEN kapıyı kapatır.
  Future<void>? _ayarlama;

  Future<bool> _turkceVar() async =>
      (await _tts.isLanguageAvailable('tr-TR')) == true;

  /// Varsayılan motor Türkçe bilmiyorsa Türkçe bilen bir motora geçer.
  ///
  /// Gerçek cihazda görüldü: Samsung telefonların varsayılan motoru
  /// (com.samsung.SMT) Türkçe bilmiyor; setLanguage('tr-TR') sessizce
  /// başarısız oluyor ve sorular Türkçe olmayan bir sesle, bozuk
  /// telaffuzla okunuyordu. Aynı telefonda Google motoru Türkçeyi
  /// internetsiz bile konuşabiliyor.
  ///
  /// Hiçbir motor Türkçe bilmiyorsa varsayılan motora geri dönülür.
  Future<void> _turkceMotoruAyarla() async {
    try {
      if (await _turkceVar()) return;
      final varsayilan = await _tts.getDefaultEngine;
      final motorlar = await _tts.getEngines;
      if (motorlar is! List) return;

      final secilen = await turkceMotorSec(motorlar.map((m) => '$m').toList(), (
        motor,
      ) async {
        await _tts.setEngine(motor);
        return _turkceVar();
      });
      if (secilen == null && varsayilan != null) {
        await _tts.setEngine('$varsayilan');
      }
      if (kDebugMode) {
        debugPrint('TtsAudioService: varsayilan=$varsayilan secilen=$secilen');
      }
    } catch (_) {
      // Motor listesi/değiştirme bu platformda desteklenmiyor olabilir
      // (ör. iOS). O zaman mevcut motorla devam.
    }
  }

  Future<void> _configure() =>
      _ayarlama ??= _ayarla().catchError((Object hata) {
        // Ayarlama başarısız olduysa bir dahaki konuşmada yeniden denensin.
        _ayarlama = null;
        throw hata;
      });

  Future<void> _ayarla() async {
    await _turkceMotoruAyarla();
    final dil = await _tts.setLanguage('tr-TR');
    if (kDebugMode) debugPrint('TtsAudioService: setLanguage(tr-TR)=$dil');
    // Çocuklar için yavaş konuşma. 1.0 yetişkin hızı, bu fazla hızlı olur.
    await _tts.setSpeechRate(0.40);
    // Hafif tiz: çocuklara daha sıcak geliyor.
    await _tts.setPitch(1.1);
    await _tts.setVolume(1.0);
    // speak() konuşma BİTİNCE tamamlansın. Varsayılanda hemen döner.
    // Otomatik geçiş övgünün bitmesini bu sayede bekleyebiliyor;
    // yoksa yeni soru okunmaya başlayınca "Elma! Aferin!" yarıda kesilirdi.
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> speak(String text) async {
    final benim = ++_sonIstek;
    try {
      await _configure();
      // Ayarlama beklenirken daha yeni bir istek geldiyse bu istek eskidi:
      // söylemenin anlamı yok, zaten hemen kesilecekti.
      if (benim != _sonIstek) return;
      // Önceki okumayı kes: çocuk hızlı ilerlerse sesler üst üste binmesin.
      await _tts.stop();
      if (benim != _sonIstek) return;
      if (kDebugMode) debugPrint('TtsAudioService: konus "$text"');
      await _tts.speak(text);
    } catch (_) {
      // Ses çalışmazsa oyun DURMAMALI.
      // Cihazda Türkçe TTS motoru olmayabilir; bu oyunu oynanamaz
      // yapmamalı. Sessizce devam ediyoruz.
    }
  }

  @override
  Future<void> stop() async {
    // Ayarlamayı bekleyen istekler de iptal: sayfadan çıkıldıktan sonra
    // gecikmiş bir ses başlamasın.
    _sonIstek++;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
