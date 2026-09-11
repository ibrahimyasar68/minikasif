import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/providers/game_provider.dart';
import 'package:mini_kesif/services/audio_service.dart';

/// Konuşmaların ne zaman BİTECEĞİNİ testin kontrol ettiği sahte servis.
///
/// Gerçek TTS'te "Elma! Aferin!" bir iki saniye sürer. Burada her
/// konuşmayı testin istediği anda bitirebiliyoruz; böylece "övgü uzun
/// sürdü" ve "övgü hiç bitmedi" durumlarını deneyebiliyoruz.
class KontrolluSes implements AudioService {
  KontrolluSes({this.hemenBitir = true});

  /// true: her konuşma anında biter. false: bitir(i) çağrılana kadar sürer.
  final bool hemenBitir;
  final konusmalar = <String>[];
  final _bitisler = <Completer<void>>[];

  @override
  Future<void> speak(String text) {
    konusmalar.add(text);
    final c = Completer<void>();
    _bitisler.add(c);
    if (hemenBitir) c.complete();
    return c.future;
  }

  /// [sira]. konuşmayı bitirir (0'dan başlar).
  void bitir(int sira) {
    if (!_bitisler[sira].isCompleted) _bitisler[sira].complete();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> hazirla({bool yeniden = false}) async => true;
}

/// NEDEN testWidgets? Buradaki testlerde hiç widget yok.
/// testWidgets SAHTE bir saatte çalışır: tester.pump(süre) zamanı anında
/// ileri sarar. Böylece 4 saniyelik beklemeyi gerçekten beklemiyoruz.
void main() {
  const enAz = GameProvider.minCelebration;
  const enFazla = GameProvider.maxCelebration;
  const kil = Duration(milliseconds: 10);

  late KontrolluSes ses;
  late GameProvider oyun;

  void kur({bool hemenBitir = true}) {
    ses = KontrolluSes(hemenBitir: hemenBitir);
    oyun = GameProvider(audio: ses)..startSection(GameSection.fruits);
    addTearDown(oyun.dispose);
  }

  void dogruCevapla() => oyun.answer(
    oyun.currentQuestion.options.firstWhere(oyun.currentQuestion.isCorrect),
  );
  void yanlisCevapla() => oyun.answer(
    oyun.currentQuestion.options.firstWhere(
      (o) => !oyun.currentQuestion.isCorrect(o),
    ),
  );

  testWidgets('övgü kısaysa en az süre kadar beklenir, sonra geçilir', (
    tester,
  ) async {
    kur();
    dogruCevapla();

    await tester.pump(enAz - kil);
    expect(oyun.questionNumber, 1, reason: 'yeşil kart görünsün');

    await tester.pump(kil * 2);
    expect(oyun.questionNumber, 2);
  });

  testWidgets('övgü uzun sürerse bitmesi beklenir', (tester) async {
    kur(hemenBitir: false);
    dogruCevapla(); // konuşma 0: soru, konuşma 1: övgü

    await tester.pump(enAz + const Duration(milliseconds: 800));
    expect(oyun.questionNumber, 1, reason: 'övgü yarıda kesilmemeli');

    ses.bitir(1);
    await tester.pump();
    expect(oyun.questionNumber, 2);
  });

  testWidgets('övgü hiç bitmezse en fazla süre sonunda geçilir', (
    tester,
  ) async {
    kur(hemenBitir: false);
    dogruCevapla();

    await tester.pump(enFazla - kil);
    expect(oyun.questionNumber, 1);

    await tester.pump(kil * 2);
    expect(
      oyun.questionNumber,
      2,
      reason: 'ses motoru takılsa da oyun donmamalı',
    );
  });

  testWidgets('yanlış cevap geçiş başlatmaz', (tester) async {
    kur();
    yanlisCevapla();

    await tester.pump(enFazla * 2);
    expect(oyun.questionNumber, 1);
  });

  testWidgets('beklerken sayfadan çıkılırsa geçiş iptal olur', (tester) async {
    kur();
    dogruCevapla();
    oyun.leave();

    await tester.pump(enFazla * 2);
    expect(oyun.questionNumber, 1, reason: 'arka planda ilerlememeli');
  });

  // İptal edilen eski beklemenin övgüsü SONRADAN bitince gelen haber,
  // yeni beklemeyi erken bitirmemeli. _advanceToken bunun için var.
  testWidgets('iptal edilen eski övgünün haberi yeni beklemeyi etkilemez', (
    tester,
  ) async {
    kur(hemenBitir: false);
    dogruCevapla(); // konuşma 1: eski övgü
    oyun.restart(); // konuşma 2: soru (bekleme iptal)
    dogruCevapla(); // konuşma 3: yeni övgü

    await tester.pump(enAz + kil); // yeni beklemenin en az süresi doldu
    ses.bitir(1); // ESKİ övgü şimdi bitti
    await tester.pump();
    expect(oyun.questionNumber, 1, reason: 'eski haber yok sayılmalı');

    ses.bitir(3); // yeni övgü bitti
    await tester.pump();
    expect(oyun.questionNumber, 2);
  });

  testWidgets('elle geçilirse otomatik geçiş ikinci kez tetiklenmez', (
    tester,
  ) async {
    kur();
    dogruCevapla();
    oyun.nextQuestion();
    expect(oyun.questionNumber, 2);

    await tester.pump(enFazla * 2);
    expect(oyun.questionNumber, 2, reason: 'soru atlanmamalı');
  });

  testWidgets('son soruda beklemeden sonra bölüm bir kez tamamlanır', (
    tester,
  ) async {
    kur();
    var tamamlanmaHaberi = 0;
    var oncekiDurum = false;
    oyun.addListener(() {
      if (oyun.isCompleted && !oncekiDurum) tamamlanmaHaberi++;
      oncekiDurum = oyun.isCompleted;
    });

    for (var i = 0; i < oyun.totalQuestions; i++) {
      dogruCevapla();
      await tester.pump(enAz + kil);
    }
    await tester.pump(enFazla * 2);

    expect(oyun.isCompleted, isTrue);
    expect(tamamlanmaHaberi, 1);
  });

  testWidgets('beklerken provider kapatılırsa hata olmaz', (tester) async {
    final o = GameProvider(audio: KontrolluSes())
      ..startSection(GameSection.fruits);
    o.answer(o.currentQuestion.options.firstWhere(o.currentQuestion.isCorrect));
    o.dispose();

    await tester.pump(enFazla * 2);
    // Kapanmış provider'da notifyListeners çağrılsaydı burada hata olurdu.
  });
}
