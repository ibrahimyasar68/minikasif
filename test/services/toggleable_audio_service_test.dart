import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/services/audio_service.dart';

class KayitSes implements AudioService {
  final konusmalar = <String>[];
  int durdurma = 0;
  final hazirlaCagrilari = <bool>[];

  @override
  Future<void> speak(String text) async => konusmalar.add(text);

  @override
  Future<void> stop() async => durdurma++;

  @override
  Future<bool> hazirla({bool yeniden = false}) async {
    hazirlaCagrilari.add(yeniden);
    return true;
  }
}

void main() {
  test('ses açıkken konuşma asıl servise iletilir', () async {
    final ic = KayitSes();
    await ToggleableAudioService(ic, acikMi: () => true).speak('Kediyi bul');
    expect(ic.konusmalar, ['Kediyi bul']);
  });

  test('ses kapalıyken konuşma yutulur ama takılmadan biter', () async {
    final ic = KayitSes();
    await ToggleableAudioService(ic, acikMi: () => false).speak('Kediyi bul');
    expect(ic.konusmalar, isEmpty);
  });

  // Ayar her konuşmada yeniden sorulur: değişiklik hemen etkili.
  test('ayar sonradan değişince bir sonraki konuşmada geçerli olur', () async {
    final ic = KayitSes();
    var acik = true;
    final servis = ToggleableAudioService(ic, acikMi: () => acik);

    await servis.speak('bir');
    acik = false;
    await servis.speak('iki');
    acik = true;
    await servis.speak('üç');

    expect(ic.konusmalar, ['bir', 'üç']);
  });

  test('stop ve hazirla ses kapalıyken de iletilir', () async {
    final ic = KayitSes();
    final servis = ToggleableAudioService(ic, acikMi: () => false);

    await servis.stop();
    await servis.hazirla(yeniden: true);

    expect(ic.durdurma, 1);
    expect(ic.hazirlaCagrilari, [true]);
  });
}
