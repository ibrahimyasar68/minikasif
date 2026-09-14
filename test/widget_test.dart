import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';
import 'package:mini_kesif/services/audio_service.dart';
import 'package:mini_kesif/models/game_section.dart';

void main() {
  testWidgets('Karşılama ekranında başlık ve 3 bölüm görünür', (tester) async {
    await tester.pumpWidget(const MiniKesifApp(audio: SilentAudioService()));

    expect(find.text('Mini Kesif'), findsOneWidget);

    // Bölümleri elle yazmıyoruz: enum'dan geliyorlar.
    // Yeni bölüm eklenirse bu test kendiliğinden onu da kontrol eder.
    for (final section in GameSection.values) {
      expect(find.text(section.title), findsOneWidget, reason: section.title);
    }
  });
}
