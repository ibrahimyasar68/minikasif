import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/providers/game_provider.dart';
import 'package:mini_kesif/services/audio_service.dart';

/// Ne söylendiğini kaydeden sahte servis.
///
/// AudioService bir arayüz olduğu için bunu yazabiliyoruz.
/// GameProvider doğrudan FlutterTts kullansaydı bu test mümkün olmazdı.
class FakeAudioService implements AudioService {
  final List<String> spoken = [];
  int stopCount = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopCount++;
}

void main() {
  late FakeAudioService audio;
  late GameProvider game;

  setUp(() {
    audio = FakeAudioService();
    game = GameProvider(audio: audio);
  });

  test('bölüm başlayınca ilk soru okunur', () {
    game.startSection(GameSection.animals);

    expect(audio.spoken, hasLength(1));
    expect(audio.spoken.first, game.currentQuestion.spokenText);
  });

  // audioText'i olan soruda ekrandaki metin DEĞİL o okunmalı.
  test('audioText varsa o okunur', () {
    game.startSection(GameSection.animals);

    expect(game.currentQuestion.questionText, 'Kediyi bul');
    expect(audio.spoken.first, 'Miyav! Kediye dokun.');
  });

  test('sonraki soruya geçince yeni soru okunur', () {
    game.startSection(GameSection.fruits);
    audio.spoken.clear();

    final dogru = game.currentQuestion.options.firstWhere(
      (o) => game.currentQuestion.isCorrect(o),
    );
    game.answer(dogru);
    game.nextQuestion();

    expect(audio.spoken, hasLength(1));
    expect(audio.spoken.first, game.currentQuestion.spokenText);
  });

  // Cevaplamadan ilerlenemiyor; boşuna ses de çalmamalı.
  test('cevaplanmadan nextQuestion çağrılırsa ses çalmaz', () {
    game.startSection(GameSection.fruits);
    audio.spoken.clear();

    game.nextQuestion();

    expect(audio.spoken, isEmpty);
  });

  test('bölüm bitince okuma yapılmaz, ses durdurulur', () {
    game.startSection(GameSection.fruits);

    while (!game.isCompleted) {
      final dogru = game.currentQuestion.options.firstWhere(
        (o) => game.currentQuestion.isCorrect(o),
      );
      game.answer(dogru);
      game.nextQuestion();
    }
    final bitisteki = audio.spoken.length;

    expect(game.isCompleted, isTrue);
    expect(audio.stopCount, 1);

    // Tebrik ekranındayken tekrar-dinle basılsa bile okunacak soru yok.
    game.repeatQuestion();
    expect(audio.spoken, hasLength(bitisteki));
  });

  test('tekrar dinle mevcut soruyu yeniden okur', () {
    game.startSection(GameSection.fruits);
    audio.spoken.clear();

    game.repeatQuestion();
    game.repeatQuestion();

    expect(audio.spoken, hasLength(2));
    expect(audio.spoken.every((t) => t == game.currentQuestion.spokenText),
        isTrue);
  });

  test('yanlış cevap soruyu tekrar okumaz', () {
    game.startSection(GameSection.fruits);
    audio.spoken.clear();

    final yanlis = game.currentQuestion.options.firstWhere(
      (o) => !game.currentQuestion.isCorrect(o),
    );
    game.answer(yanlis);

    expect(audio.spoken, isEmpty, reason: 'çocuk düşünürken sözünü kesme');
  });
}
