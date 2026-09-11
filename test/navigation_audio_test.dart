import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/providers/game_provider.dart';
import 'package:mini_kesif/services/audio_service.dart';

import 'helpers/oyun.dart';

/// Ekranlar arası geçişte ses davranışı.
///
/// Sahte ses servisiyle gerçek uygulamayı (MiniKesifApp) açıyoruz: ne
/// söylendiğini ve sesin durdurulup durdurulmadığını görebiliyoruz. Gerçek
/// bağlantı (ayar sarmalayıcısı dahil) da böylece sınanmış oluyor.
class FakeAudio implements AudioService {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;

  @override
  Future<bool> hazirla({bool yeniden = false}) async => true;
}

void main() {
  late FakeAudio audio;

  Future<void> uygulamayiKur(WidgetTester tester) async {
    audio = FakeAudio();
    await tester.pumpWidget(MiniKesifApp(audio: audio));
    await bolumeGir(tester, GameSection.fruits);
  }

  // Satır kapsamı raporunda 🔊 butonunun onPressed'i hiç çalışmamıştı.
  // repeatQuestion() provider'da test edilmişti ama BUTONUN ona bağlı
  // olduğu değil.
  testWidgets('Tekrar dinle butonu soruyu yeniden okur', (tester) async {
    await uygulamayiKur(tester);
    final once = audio.spoken.length;

    await tester.tap(find.byTooltip('Tekrar dinle'));
    await tester.pump();

    expect(audio.spoken.length, once + 1);
    expect(audio.spoken.last, 'Haydi bakalım, kırmızı elmaya dokun!');
  });

  // HATA: soru okunurken geri tuşuna basılırsa ses ana sayfada da
  // devam ediyordu.
  testWidgets('Soru ekranından geri dönünce ses durur', (tester) async {
    await uygulamayiKur(tester);
    expect(audio.stops, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(audio.stops, greaterThanOrEqualTo(1));
  });

  testWidgets('Sonuç ekranından ana sayfaya dönünce ses durur', (tester) async {
    await uygulamayiKur(tester);
    await bolumuOyna(tester, GameSection.fruits);
    // Bölüm bitince nextQuestion bir kez stop çağırıyor; onu sıfırla.
    audio.stops = 0;

    await dokun(tester, find.text('Ana sayfa'));

    expect(
      audio.stops,
      greaterThanOrEqualTo(1),
      reason: 'kutlama sesi ana sayfada sürmemeli',
    );
  });

  // Doğru cevaptan sonra otomatik geçiş beklenirken geri tuşuna basılırsa
  // oyun arka planda kendi kendine ilerlememeli.
  // Zincir: PopScope -> leave() -> bekleyen geçiş iptal.
  testWidgets('Beklerken geri dönülürse oyun arka planda ilerlemez', (
    tester,
  ) async {
    await uygulamayiKur(tester);
    final oyun = Provider.of<GameProvider>(
      tester.element(find.text('Kırmızı elmayı bul')),
      listen: false,
    );

    await tester.tap(find.text('Elma'));
    await tester.pump(); // cevap işlendi, otomatik geçiş beklemesi başladı
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.pump(GameProvider.maxCelebration * 2);

    expect(oyun.questionNumber, 1, reason: 'arka planda soru ilerlememeli');
    expect(oyun.isCompleted, isFalse);
  });
}
