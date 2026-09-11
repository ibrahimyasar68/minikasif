import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/answer_option.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/models/question.dart';
import 'package:mini_kesif/providers/game_provider.dart';

/// Bu dosyada hiç widget yok, ekran çizilmiyor.
/// GameProvider hiçbir UI import etmediği için oyun mantığını
/// düz Dart kodu gibi test edebiliyoruz.
void main() {
  const kedi = AnswerOption(id: 'kedi', label: 'Kedi', emoji: '🐱');
  const kopek = AnswerOption(id: 'kopek', label: 'Köpek', emoji: '🐶');
  const top = AnswerOption(id: 'top', label: 'Top', emoji: '⚽');

  const soru1 = Question(
    id: 't1',
    section: GameSection.fruits,
    questionText: 'Kediyi bul',
    options: [kedi, kopek],
    correctOptionId: 'kedi',
  );
  const soru2 = Question(
    id: 't2',
    section: GameSection.fruits,
    questionText: 'Topu bul',
    options: [top, kopek],
    correctOptionId: 'top',
  );

  GameProvider tekSoruluOyun() {
    final oyun = GameProvider(questions: [soru1]);
    // Doğru cevap bir Timer başlatıyor; test bitince kapat.
    addTearDown(oyun.dispose);
    return oyun;
  }

  GameProvider ikiSoruluOyun() {
    final oyun = GameProvider(questions: [soru1, soru2]);
    // Doğru cevap bir Timer başlatıyor; test bitince kapat.
    addTearDown(oyun.dispose);
    return oyun;
  }

  group('cevaplama', () {
    test('başlangıçta cevaplanmamış ve yanlış denemesi yok', () {
      final game = tekSoruluOyun();
      expect(game.isAnswered, isFalse);
      expect(game.hasWrongAttempt, isFalse);
    });

    test('doğru cevap isAnswered yapar', () {
      final game = tekSoruluOyun();
      game.answer(kedi);
      expect(game.isAnswered, isTrue);
    });

    test('yanlış cevap oyunu bitirmez, deneme kaydedilir', () {
      final game = tekSoruluOyun();
      game.answer(kopek);
      expect(game.isAnswered, isFalse);
      expect(game.wasTriedWrong(kopek), isTrue);
      expect(game.wasTriedWrong(kedi), isFalse);
    });

    test('cevaplandıktan sonra yeni dokunuşlar yok sayılır', () {
      final game = tekSoruluOyun();
      game.answer(kedi);
      game.answer(kopek);
      expect(game.hasWrongAttempt, isFalse);
    });

    test('notifyListeners dinleyiciyi uyarır', () {
      final game = tekSoruluOyun();
      var bildirimSayisi = 0;
      game.addListener(() => bildirimSayisi++);

      game.answer(kopek); // yanlış -> 1
      expect(bildirimSayisi, 1);

      game.answer(kedi); // doğru -> 2
      expect(bildirimSayisi, 2);

      game.answer(kopek); // erken çıkış -> bildirim yok
      expect(bildirimSayisi, 2, reason: 'gereksiz rebuild tetiklenmemeli');
    });
  });

  group('soru geçişi', () {
    test('ilerleme bilgisi doğru başlar', () {
      final game = ikiSoruluOyun();
      expect(game.questionNumber, 1);
      expect(game.totalQuestions, 2);
      expect(game.isLastQuestion, isFalse);
    });

    test('cevaplanmadan sonraki soruya geçilemez', () {
      final game = ikiSoruluOyun();
      game.nextQuestion();
      expect(game.questionNumber, 1, reason: 'hâlâ ilk soruda olmalı');
    });

    test('cevaplandıktan sonra sonraki soruya geçer', () {
      final game = ikiSoruluOyun();
      game.answer(kedi);
      game.nextQuestion();
      expect(game.questionNumber, 2);
      expect(game.currentQuestion.id, 't2');
      expect(game.isLastQuestion, isTrue);
    });

    // BU TEST KRİTİK:
    // Soru değişince önceki sorunun yanlış denemeleri silinmezse
    // yeni soruda alakasız kartlar soluk görünür.
    test('yeni soruda önceki sorunun durumu temizlenir', () {
      final game = ikiSoruluOyun();
      game.answer(kopek); // yanlış
      game.answer(kedi); // doğru
      game.nextQuestion();

      expect(game.isAnswered, isFalse);
      expect(game.hasWrongAttempt, isFalse);
      expect(game.wasTriedWrong(kopek), isFalse);
    });

    test('son sorudan sonra oyun tamamlanır', () {
      final game = ikiSoruluOyun();
      game.answer(kedi);
      game.nextQuestion(); // 2. soru
      expect(game.isCompleted, isFalse);

      game.answer(top);
      game.nextQuestion(); // bitti
      expect(game.isCompleted, isTrue);
    });
  });

  group('skor', () {
    test('başlangıçta skor sıfır', () {
      final game = ikiSoruluOyun();
      expect(game.correctCount, 0);
      expect(game.firstTryCount, 0);
    });

    test('ilk denemede bilinen soru her iki sayacı da artırır', () {
      final game = ikiSoruluOyun();
      game.answer(kedi);
      expect(game.correctCount, 1);
      expect(game.firstTryCount, 1);
    });

    // AYIRT EDİCİ TEST:
    // Yanlış denedikten sonra doğruyu bulmak "doğru" sayılır
    // ama "ilk denemede bildi" sayılmaz.
    test('yanlıştan sonra bulunan soru firstTry sayılmaz', () {
      final game = ikiSoruluOyun();
      game.answer(kopek); // yanlış
      game.answer(kedi); // doğru
      expect(game.correctCount, 1);
      expect(game.firstTryCount, 0);
    });

    test('yanlış deneme sadece kendi sorusunu etkiler', () {
      final game = ikiSoruluOyun();
      game.answer(kopek); // 1. soruda yanlış
      game.answer(kedi);
      game.nextQuestion();
      game.answer(top); // 2. soruyu ilk denemede bildi

      expect(game.correctCount, 2);
      expect(game.firstTryCount, 1, reason: 'sadece 2. soru ilk denemede');
    });

    test('skor soru geçişinde sıfırlanmaz', () {
      final game = ikiSoruluOyun();
      game.answer(kedi);
      game.nextQuestion();
      expect(game.correctCount, 1, reason: 'skor tüm oyun boyunca yaşar');
    });
  });

  group('restart', () {
    test('oyunu tamamen başa döndürür', () {
      final game = ikiSoruluOyun();
      game.answer(kopek);
      game.answer(kedi);
      game.nextQuestion();
      game.answer(top);
      game.nextQuestion(); // tamamlandı

      game.restart();

      expect(game.isCompleted, isFalse);
      expect(game.questionNumber, 1);
      expect(game.isAnswered, isFalse);
      expect(game.hasWrongAttempt, isFalse);
      expect(game.correctCount, 0);
      expect(game.firstTryCount, 0);
    });
  });

  group('yıldız', () {
    test('hiç oynanmadıysa 0 yıldız', () {
      expect(ikiSoruluOyun().starCount, 0);
    });

    test('hepsi ilk denemede -> 3 yıldız', () {
      final game = ikiSoruluOyun();
      game.answer(kedi);
      game.nextQuestion();
      game.answer(top);
      expect(game.starCount, 3);
    });

    test('yarısı ilk denemede -> 2 yıldız', () {
      final game = ikiSoruluOyun();
      game.answer(kedi); // ilk denemede
      game.nextQuestion();
      game.answer(kopek); // yanlış
      game.answer(top);
      expect(game.starCount, 2);
    });

    // Bölümü bitiren çocuk her hâlükârda en az 1 yıldız alır.
    test('hiçbiri ilk denemede değil -> yine de 1 yıldız', () {
      final game = ikiSoruluOyun();
      game.answer(kopek);
      game.answer(kedi);
      game.nextQuestion();
      game.answer(kopek);
      game.answer(top);
      expect(game.starCount, 1);
    });
  });

  group('bölüm', () {
    test('varsayılan bölüm meyveler ve soruları yüklü', () {
      final game = GameProvider();
      expect(game.section, GameSection.fruits);
      expect(game.totalQuestions, greaterThan(0));
      expect(game.currentQuestion.section, GameSection.fruits);
    });

    test('startSection soruları o bölümle değiştirir', () {
      final game = GameProvider();
      game.startSection(GameSection.animals);

      expect(game.section, GameSection.animals);
      for (final q in game.questions) {
        expect(q.section, GameSection.animals);
      }
    });

    // Bölüm değiştirmek yarım kalmış ilerlemeyi taşımamalı.
    test('startSection ilerlemeyi ve skoru sıfırlar', () {
      final game = GameProvider();
      game.answer(
        game.currentQuestion.options.firstWhere(
          (o) => game.currentQuestion.isCorrect(o),
        ),
      );
      game.nextQuestion();
      expect(game.questionNumber, 2);

      game.startSection(GameSection.objects);

      expect(game.questionNumber, 1);
      expect(game.correctCount, 0);
      expect(game.firstTryCount, 0);
      expect(game.isCompleted, isFalse);
    });

    test('startSection dinleyicileri uyarır', () {
      final game = GameProvider();
      var bildirim = 0;
      game.addListener(() => bildirim++);
      game.startSection(GameSection.animals);
      expect(bildirim, 1);
    });
  });
}
