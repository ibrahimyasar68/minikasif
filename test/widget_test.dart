import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/main.dart';
import 'package:mini_kasif/services/audio_service.dart';
import 'package:mini_kasif/models/game_section.dart';

void main() {
  testWidgets('Karşılama ekranında başlık ve 3 bölüm görünür', (tester) async {
    await tester.pumpWidget(const MiniKasifApp(audio: SilentAudioService()));

    expect(find.text('MiniKasif'), findsOneWidget);

    // Bölümleri elle yazmıyoruz: enum'dan geliyorlar.
    // Yeni bölüm eklenirse bu test kendiliğinden onu da kontrol eder.
    for (final section in GameSection.values) {
      expect(find.text(section.title), findsOneWidget, reason: section.title);
    }
  });
}
