import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/answer_option.dart';
import 'package:mini_kesif/data/feedback_phrases.dart';
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

  /// hazirla() ne dönsün: cihazda Türkçe ses var mı?
  bool turkceVar = true;
  final hazirlaCagrilari = <bool>[]; // her çağrının "yeniden" değeri

  @override
  Future<bool> hazirla({bool yeniden = false}) async {
    hazirlaCagrilari.add(yeniden);
    return turkceVar;
  }
}

void main() {
  late FakeAudioService audio;
  late GameProvider game;

  setUp(() {
    audio = FakeAudioService();
    game = GameProvider(audio: audio);
  });

  // Doğru cevap artık bir Timer başlatıyor (otomatik geçiş).
  // Test bitince provider'ı kapatıp Timer'ları da kapatıyoruz.
  tearDown(() => game.dispose());

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
    final dogru = game.currentQuestion.options.firstWhere(
      (o) => game.currentQuestion.isCorrect(o),
    );
    game.answer(dogru);
    // Cevabın kendi övgü sesi var; ondan SONRAKİ konuşmaya bakıyoruz.
    audio.spoken.clear();

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
    expect(
      audio.spoken.every((t) => t == game.currentQuestion.spokenText),
      isTrue,
    );
  });

  // Yanlış cevapta kısa bir teşvik okunur ama SORU tekrar okunmaz:
  // çocuk düşünürken sözünü kesmiyoruz.
  test('yanlış cevap soruyu tekrar okumaz', () {
    game.startSection(GameSection.fruits);
    audio.spoken.clear();

    final yanlis = game.currentQuestion.options.firstWhere(
      (o) => !game.currentQuestion.isCorrect(o),
    );
    game.answer(yanlis);

    expect(audio.spoken, hasLength(1));
    expect(
      audio.spoken.first,
      isNot(game.currentQuestion.spokenText),
      reason: 'çocuk düşünürken sözünü kesme',
    );
  });

  group('sesli geri bildirim', () {
    AnswerOption dogruSecenek() => game.currentQuestion.options.firstWhere(
      (o) => game.currentQuestion.isCorrect(o),
    );
    AnswerOption yanlisSecenek() => game.currentQuestion.options.firstWhere(
      (o) => !game.currentQuestion.isCorrect(o),
    );

    test('doğru cevapta nesnenin adı ve övgü okunur', () {
      game.startSection(GameSection.fruits);
      audio.spoken.clear();

      final dogru = dogruSecenek();
      game.answer(dogru);

      expect(audio.spoken, ['${dogru.label}! ${praisePhrases.first}']);
    });

    test('yanlış cevapta dokunulan nesnenin adı ve teşvik okunur', () {
      game.startSection(GameSection.fruits);
      audio.spoken.clear();

      final yanlis = yanlisSecenek();
      game.answer(yanlis);

      expect(audio.spoken, ['${yanlis.label}. ${retryPhrases.first}']);
    });

    // Hep aynı "Aferin!" birkaç sorudan sonra anlamını yitirir.
    test('övgüler sırayla döner', () {
      game.startSection(GameSection.fruits);
      final ovguler = <String>[];
      for (var i = 0; i < 3; i++) {
        audio.spoken.clear();
        final dogru = dogruSecenek();
        game.answer(dogru);
        ovguler.add(audio.spoken.single.substring(dogru.label.length + 2));
        game.nextQuestion();
      }
      expect(ovguler, praisePhrases.take(3).toList());
    });

    test('teşvikler de döner: aynı cümle üst üste gelmez', () {
      game.startSection(GameSection.fruits);
      audio.spoken.clear();

      // İlk soruda iki farklı yanlış seçenek var (Muz, Üzüm).
      final yanlislar = game.currentQuestion.options
          .where((o) => !game.currentQuestion.isCorrect(o))
          .take(2);
      for (final y in yanlislar) {
        game.answer(y);
      }

      expect(audio.spoken, hasLength(2));
      expect(audio.spoken[0].endsWith(retryPhrases[0]), isTrue);
      expect(audio.spoken[1].endsWith(retryPhrases[1]), isTrue);
    });

    test('cevaplandıktan sonra dokunmak ses çıkarmaz', () {
      game.startSection(GameSection.fruits);
      game.answer(dogruSecenek());
      audio.spoken.clear();

      game.answer(yanlisSecenek());

      expect(audio.spoken, isEmpty);
    });
  });

  group('Türkçe ses kontrolü', () {
    test('açılışta kontrol bitene kadar bilinmiyor (null)', () {
      expect(game.turkceSesVar, isNull);
    });

    test('Türkçe varsa true olur ve dinleyici uyarılır', () async {
      var bildirim = 0;
      game.addListener(() => bildirim++);

      await game.sesiKontrolEt();

      expect(game.turkceSesVar, isTrue);
      expect(bildirim, 1);
    });

    test('Türkçe yoksa false olur', () async {
      audio.turkceVar = false;
      await game.sesiKontrolEt();
      expect(game.turkceSesVar, isFalse);
    });

    // İlk kontrol normal, sonrakiler "yeniden": ebeveyn ses paketini
    // yüklemiş olabilir, servis saklı sonucu atıp baştan bakmalı.
    test('ikinci kontrol yeniden yapılır ve sonuç güncellenir', () async {
      audio.turkceVar = false;
      await game.sesiKontrolEt();
      audio.turkceVar = true; // ebeveyn ses paketini yükledi
      await game.sesiKontrolEt();

      expect(audio.hazirlaCagrilari, [false, true]);
      expect(game.turkceSesVar, isTrue);
    });
  });
}
