import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/data/question_data.dart';
import 'package:mini_kasif/models/game_section.dart';

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

  group('MVP kapsamı', () {
    // CLAUDE.md md.3: "3 bölüm, toplam 30 soru".
    test('toplam 30 soru var', () {
      expect(allQuestions.length, 30);
    });

    test('her bölümde 10 soru var', () {
      for (final s in GameSection.values) {
        expect(questionsOf(s).length, 10, reason: s.title);
      }
    });

    // Karışık zorluk: 2, 3 ve 4 seçenekli soruların hepsi bulunmalı.
    test('2, 3 ve 4 seçenekli soruların hepsi var', () {
      final sayilar = allQuestions.map((q) => q.options.length).toSet();
      expect(sayilar, containsAll([2, 3, 4]));
    });

    // Çocuk okuyamıyor; seçenekleri SADECE görselden ayırt ediyor.
    // Aynı emoji bir soruda iki kez olursa soru çözülemez.
    test('bir soru içinde emojiler benzersiz', () {
      for (final q in allQuestions) {
        final emojiler = q.options.map((o) => o.emoji).toList();
        expect(emojiler.toSet().length, emojiler.length, reason: q.id);
      }
    });

    // Testler seçeneği etiketiyle buluyor (find.text). Aynı etiketten
    // iki tane olursa hangisine dokunulacağı belirsizleşir; ekran
    // okuyucu da ikisini aynı okur.
    test('bir soru içinde etiketler benzersiz', () {
      for (final q in allQuestions) {
        final etiketler = q.options.map((o) => o.label).toList();
        expect(etiketler.toSet().length, etiketler.length, reason: q.id);
      }
    });
  });
}
