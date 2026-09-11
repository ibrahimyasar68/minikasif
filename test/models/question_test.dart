import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/models/answer_option.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/models/question.dart';

void main() {
  // Testlerde tekrar tekrar kullanacağımız örnek soru.
  const elma = AnswerOption(id: 'elma', label: 'Elma', emoji: '🍎');
  const muz = AnswerOption(id: 'muz', label: 'Muz', emoji: '🍌');

  const soru = Question(
    id: 'q1',
    section: GameSection.fruits,
    questionText: 'Kırmızı elmayı bul',
    options: [elma, muz],
    correctOptionId: 'elma',
  );

  test('doğru seçenek true döner', () {
    expect(soru.isCorrect(elma), isTrue);
  });

  test('yanlış seçenek false döner', () {
    expect(soru.isCorrect(muz), isFalse);
  });

  test('audioText verilmezse spokenText questionText olur', () {
    expect(soru.spokenText, 'Kırmızı elmayı bul');
  });

  test('audioText verilirse spokenText onu kullanır', () {
    const sesli = Question(
      id: 'q2',
      section: GameSection.fruits,
      questionText: 'Kırmızı elmayı bul',
      audioText: 'Haydi bakalım, kırmızı elmaya dokun!',
      options: [elma, muz],
      correctOptionId: 'elma',
    );
    expect(sesli.spokenText, 'Haydi bakalım, kırmızı elmaya dokun!');
  });
}
