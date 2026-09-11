import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/models/game_section.dart';

void main() {
  test('soru listesi boş değil', () {
    expect(allQuestions, isNotEmpty);
  });

  test('her sorunun id\'si benzersiz', () {
    final ids = allQuestions.map((q) => q.id).toList();
    // Set aynı değeri iki kez tutmaz. Uzunluklar farklıysa tekrar var demektir.
    expect(ids.toSet().length, ids.length);
  });

  // EN ÖNEMLİ TEST:
  // correctOptionId'yi elle yazıyoruz. 'elma' yerine 'elmaa' yazsak
  // derleyici uyarmaz, hiçbir cevap doğru sayılmazdı.
  // Bu test o yazım hatasını anında yakalar.
  test('her sorunun doğru cevabı kendi seçenekleri arasında var', () {
    for (final q in allQuestions) {
      final optionIds = q.options.map((o) => o.id);
      expect(
        optionIds,
        contains(q.correctOptionId),
        reason: '${q.id}: "${q.correctOptionId}" seçenekler arasında yok',
      );
    }
  });

  test('her soruda 2-4 seçenek var', () {
    for (final q in allQuestions) {
      expect(q.options.length, inInclusiveRange(2, 4), reason: q.id);
    }
  });

  test('bir soru içinde aynı seçenek iki kez geçmiyor', () {
    for (final q in allQuestions) {
      final ids = q.options.map((o) => o.id).toList();
      expect(ids.toSet().length, ids.length, reason: q.id);
    }
  });

  group('bölümler', () {
    test('her bölümde en az 3 soru var', () {
      for (final section in GameSection.values) {
        expect(
          questionsOf(section).length,
          greaterThanOrEqualTo(3),
          reason: section.title,
        );
      }
    });

    test('questionsOf sadece o bölümün sorularını döndürür', () {
      for (final section in GameSection.values) {
        for (final q in questionsOf(section)) {
          expect(q.section, section);
        }
      }
    });

    // Hiçbir soru bölümsüz kalmamalı; bölüm bazlı oynanınca
    // dışarıda kalan soru olmamalı.
    test('tüm sorular bir bölüme dağıtılmış', () {
      final toplam = GameSection.values
          .map((s) => questionsOf(s).length)
          .reduce((a, b) => a + b);
      expect(toplam, allQuestions.length);
    });

    test('her bölümün adı ve simgesi dolu', () {
      for (final section in GameSection.values) {
        expect(section.title, isNotEmpty);
        expect(section.emoji, isNotEmpty);
      }
    });
  });
}
