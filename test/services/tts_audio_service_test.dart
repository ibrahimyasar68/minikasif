import 'package:flutter_test/flutter_test.dart';
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
}
