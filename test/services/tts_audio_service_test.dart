import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mini_kesif/services/audio_service.dart';

/// Gerçek TtsAudioService'in hata toleransı.
///
/// Test ortamında flutter_tts'in yerel (Android) tarafı yok; her çağrı
/// MissingPluginException fırlatır. Bu, gerçek hayatta "cihazda Türkçe
/// TTS motoru yok" durumunun iyi bir benzeri.
///
/// Beklenen: servis hatayı YUTAR, oyun durmaz.
///
/// NOT: Ayarların (tr-TR, hız 0.40) doğru uygulandığını burada test
/// etmiyoruz. Bu, eklentinin iç kanal adlarına bağımlı kırılgan bir test
/// olurdu. O kısım emülatörde doğrulandı (TTS gerçekten konuştu).
/// Platform kanalı olmadan çalışan sahte TTS motoru.
///
/// Fake: flutter_test'in sınıfı. Burada yazmadığımız bir metot çağrılırsa
/// test "uygulanmadı" hatasıyla durur; beklenmedik bir çağrı fark edilir.
class SahteTts extends Fake implements FlutterTts {
  SahteTts({
    this.varsayilan = 'com.google.android.tts',
    this.turkceBilenler = const {'com.google.android.tts'},
    this.motorlar = const ['com.google.android.tts'],
  }) : motor = varsayilan;

  final String varsayilan;
  final Set<String> turkceBilenler;
  final List<String> motorlar;
  String motor;
  final konusmalar = <String>[];
  int setLanguageSayisi = 0;

  @override
  Future<dynamic> isLanguageAvailable(String language) async =>
      language == 'tr-TR' && turkceBilenler.contains(motor);
  @override
  Future<dynamic> get getDefaultEngine async => varsayilan;
  @override
  Future<dynamic> get getEngines async => motorlar;
  @override
  Future<dynamic> setEngine(String engine) async => motor = engine;
  @override
  Future<dynamic> setLanguage(String language) async => ++setLanguageSayisi;
  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setPitch(double pitch) async => 1;
  @override
  Future<dynamic> setVolume(double volume) async => 1;
  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;
  @override
  Future<dynamic> stop() async => 1;
  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    konusmalar.add(text);
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('eklenti yokken speak hata fırlatmaz', () async {
    await expectLater(TtsAudioService().speak('Merhaba'), completes);
  });

  test('eklenti yokken stop hata fırlatmaz', () async {
    await expectLater(TtsAudioService().stop(), completes);
  });

  test('art arda çağrılar da güvenli', () async {
    final servis = TtsAudioService();
    await expectLater(
      Future.wait([
        servis.speak('bir'),
        servis.speak('iki'),
        servis.stop(),
        servis.speak('üç'),
      ]),
      completes,
    );
  });

  group('turkceMotorSec', () {
    // Gerçek cihazdaki durum: Samsung A7 (varsayılan Samsung, Google yüklü).
    const samsung = 'com.samsung.SMT';
    const google = 'com.google.android.tts';

    test('Türkçe bilen motor seçilir', () async {
      final denenen = <String>[];
      final secilen = await turkceMotorSec([samsung, google], (m) async {
        denenen.add(m);
        return m == google;
      });
      expect(secilen, google);
    });

    test('Google önce denenir (listede sonra olsa bile)', () async {
      final denenen = <String>[];
      await turkceMotorSec([samsung, google], (m) async {
        denenen.add(m);
        return true; // ikisi de Türkçe bilse
      });
      expect(denenen.first, google);
    });

    test('Türkçe bilen bulununca aramayı keser', () async {
      final denenen = <String>[];
      await turkceMotorSec([google, samsung], (m) async {
        denenen.add(m);
        return true;
      });
      expect(denenen, [google]);
    });

    test('Hiçbiri Türkçe bilmiyorsa null döner, hepsi denenir', () async {
      final denenen = <String>[];
      final secilen = await turkceMotorSec([samsung, 'com.baska.tts'], (
        m,
      ) async {
        denenen.add(m);
        return false;
      });
      expect(secilen, isNull);
      expect(denenen, hasLength(2));
    });

    test('Motor listesi boşsa null döner', () async {
      expect(await turkceMotorSec([], (_) async => true), isNull);
    });
  });

  group('konuşma sırası (gerçek telefonda bulunan hata)', () {
    // Soru okunacakken çocuk hemen bir karta dokunuyor: iki istek aynı
    // anda ayarlamayı bekliyor. Eskiden ikincisi sessizce kayboluyordu.
    test('aynı anda iki istek: en son istek konuşur', () async {
      final tts = SahteTts();
      final servis = TtsAudioService(tts: tts);

      final soru = servis.speak('Kırmızı elmayı bul');
      final tesvik = servis.speak('Muz. Bir daha deneyelim!');
      await Future.wait([soru, tesvik]);

      expect(tts.konusmalar, ['Muz. Bir daha deneyelim!']);
    });

    test('ardışık istekler sırayla konuşur, hiçbiri kaybolmaz', () async {
      final tts = SahteTts();
      final servis = TtsAudioService(tts: tts);

      await servis.speak('bir');
      await servis.speak('iki');

      expect(tts.konusmalar, ['bir', 'iki']);
    });

    test('ayarlama aynı anda gelen isteklerde bile bir kez yapılır', () async {
      final tts = SahteTts();
      final servis = TtsAudioService(tts: tts);

      await Future.wait([
        servis.speak('a'),
        servis.speak('b'),
        servis.speak('c'),
      ]);

      expect(tts.setLanguageSayisi, 1);
    });

    // Sayfadan çıkıldıktan sonra gecikmiş bir ses başlamamalı.
    test('stop, ayarlamayı bekleyen isteği iptal eder', () async {
      final tts = SahteTts();
      final servis = TtsAudioService(tts: tts);

      final gecKalan = servis.speak('geç kalan ses');
      await servis.stop();
      await gecKalan;

      expect(tts.konusmalar, isEmpty);
    });
  });

  group('motor seçimi (Samsung A7 durumu)', () {
    test('varsayılan motor Türkçe bilmiyorsa Google motoruna geçer', () async {
      final tts = SahteTts(
        varsayilan: 'com.samsung.SMT',
        motorlar: ['com.samsung.SMT', 'com.google.android.tts'],
      );
      await TtsAudioService(tts: tts).speak('Kediyi bul');

      expect(tts.motor, 'com.google.android.tts');
      expect(tts.konusmalar, ['Kediyi bul']);
    });

    test('hiçbir motor Türkçe bilmiyorsa varsayılana geri döner', () async {
      final tts = SahteTts(
        varsayilan: 'com.samsung.SMT',
        turkceBilenler: const {},
        motorlar: ['com.samsung.SMT', 'com.google.android.tts'],
      );
      await TtsAudioService(tts: tts).speak('Kediyi bul');

      expect(tts.motor, 'com.samsung.SMT');
    });

    test('varsayılan motor Türkçe biliyorsa hiç motor değiştirilmez', () async {
      final tts = SahteTts(
        varsayilan: 'com.samsung.SMT',
        turkceBilenler: const {'com.samsung.SMT', 'com.google.android.tts'},
        motorlar: ['com.samsung.SMT', 'com.google.android.tts'],
      );
      await TtsAudioService(tts: tts).speak('Kediyi bul');

      expect(tts.motor, 'com.samsung.SMT');
    });
  });

  group('Türkçe ses yoksa (hazirla ve sessizlik)', () {
    const samsung = 'com.samsung.SMT';
    const google = 'com.google.android.tts';

    test('Türkçe bilen motor varsa hazirla true döner', () async {
      final tts = SahteTts(varsayilan: samsung, motorlar: [samsung, google]);
      expect(await TtsAudioService(tts: tts).hazirla(), isTrue);
    });

    test('hiçbir motor Türkçe bilmiyorsa hazirla false döner', () async {
      final tts = SahteTts(
        varsayilan: samsung,
        turkceBilenler: const {},
        motorlar: [samsung, google],
      );
      expect(await TtsAudioService(tts: tts).hazirla(), isFalse);
    });

    // Bozuk telaffuzla konuşmak yerine sessiz kal.
    test('Türkçe yoksa speak hiç konuşmaz ama takılmadan biter', () async {
      final tts = SahteTts(
        varsayilan: samsung,
        turkceBilenler: const {},
        motorlar: [samsung],
      );
      await TtsAudioService(tts: tts).speak('Kediyi bul');

      expect(tts.konusmalar, isEmpty);
    });

    test('ses paketi sonradan yüklenince yeniden kontrol onu bulur', () async {
      final turkceBilenler = <String>{}; // başta hiçbiri
      final tts = SahteTts(
        varsayilan: samsung,
        turkceBilenler: turkceBilenler,
        motorlar: [samsung, google],
      );
      final servis = TtsAudioService(tts: tts);
      expect(await servis.hazirla(), isFalse);

      turkceBilenler.add(google); // ebeveyn Google Türkçe paketini indirdi
      expect(await servis.hazirla(yeniden: true), isTrue);

      await servis.speak('Kediyi bul');
      expect(tts.konusmalar, ['Kediyi bul']);
      expect(tts.motor, google);
    });
  });
}
