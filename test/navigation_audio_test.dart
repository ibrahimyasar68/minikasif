import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mini_kesif/pages/home_page.dart';
import 'package:mini_kesif/providers/game_provider.dart';
import 'package:mini_kesif/services/audio_service.dart';

/// Ekranlar arası geçişte ses davranışı.
///
/// Neden MiniKesifApp değil de ağacı elle kuruyoruz?
/// MiniKesifApp gerçek TtsAudioService kullanıyor. Ne söylendiğini ve
/// sesin durdurulup durdurulmadığını görmek için sahte servis lazım.
class FakeAudio implements AudioService {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}

void main() {
  late FakeAudio audio;

  Future<void> uygulamayiKur(WidgetTester tester) async {
    audio = FakeAudio();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(audio: audio),
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();
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
    for (final d in ['Elma', 'Muz', 'Portakal', 'Çilek']) {
      await tester.tap(find.text(d));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(RegExp('Devam|Bitir')));
      await tester.pumpAndSettle();
    }
    // Bölüm bitince nextQuestion bir kez stop çağırıyor; onu sıfırla.
    audio.stops = 0;

    await tester.ensureVisible(find.text('Ana sayfa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana sayfa'));
    await tester.pumpAndSettle();

    expect(
      audio.stops,
      greaterThanOrEqualTo(1),
      reason: 'kutlama sesi ana sayfada sürmemeli',
    );
  });
}
