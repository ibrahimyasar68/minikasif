import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/data/feedback_phrases.dart';

void main() {
  test('övgü ve teşvik listeleri boş değil', () {
    expect(praisePhrases, isNotEmpty);
    expect(retryPhrases, isNotEmpty);
  });

  // CLAUDE.md md.24: çocuğu cezalandıran veya başarısız hissettiren
  // mesaj yok. Birisi ileride "Yanlış! Tekrar dene" eklerse bu test kırılır.
  test('teşvik cümlelerinde olumsuz kelime yok', () {
    const yasak = ['yanlış', 'hayır', 'hata', 'olmadı', 'kötü'];
    for (final cumle in retryPhrases) {
      for (final kelime in yasak) {
        expect(cumle.toLowerCase(), isNot(contains(kelime)), reason: cumle);
      }
    }
  });

  test('cümleler tekrarsız', () {
    expect(praisePhrases.toSet().length, praisePhrases.length);
    expect(retryPhrases.toSet().length, retryPhrases.length);
  });
}
