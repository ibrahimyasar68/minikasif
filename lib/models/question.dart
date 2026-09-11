import 'answer_option.dart';
import 'game_section.dart';

/// Oyundaki TEK bir soru.
///
/// Modelin görevi veriyi taşımak VE o veriye ait basit kuralları bilmek.
/// "Bu cevap doğru mu?" sorusu buraya ait; UI'ın bunu bilmesi gerekmiyor.
class Question {
  /// Sorunun benzersiz kimliği. İleride ilerleme kaydı tutarsak lazım olur.
  final String id;

  /// Bu soru hangi bölüme ait?
  ///
  /// Bu alanı başlangıçta bilerek EKLEMEMİŞTİK: tek listeyle çalışırken
  /// kullanılmayan bir alan olurdu. İhtiyaç şimdi doğdu, şimdi ekliyoruz.
  final GameSection section;

  /// Ekranda yazacak metin: 'Kırmızı elmayı bul'
  final String questionText;

  /// Sesli okunacak metin. Ekrandakinden farklı olabilir
  /// (örn. daha uzun, daha sıcak bir cümle).
  /// Nullable (?) çünkü çoğu zaman ekrandakiyle aynı olacak.
  final String? audioText;

  /// Çocuğa gösterilecek 2-4 seçenek.
  final List<AnswerOption> options;

  /// Doğru seçeneğin id'si.
  ///
  /// Alternatif tasarım: AnswerOption'a `isCorrect` bool'u koymak.
  /// Onu SEÇMEDİK çünkü o zaman yanlışlıkla iki seçeneği birden doğru
  /// işaretleyebilir ya da hiçbirini işaretlemeyebilirdik.
  /// Doğruyu tek yerde tutmak bu hatayı imkansız kılar.
  final String correctOptionId;

  const Question({
    required this.id,
    required this.section,
    required this.questionText,
    required this.options,
    required this.correctOptionId,
    this.audioText, // required DEĞİL -> verilmezse null olur
  });

  /// Seslendirilecek metin. audioText yoksa questionText'e düşer.
  /// `??` operatörü: "soldaki null ise sağdakini kullan".
  String get spokenText => audioText ?? questionText;

  /// Verilen seçenek doğru mu?
  ///
  /// Bu metot NEDEN modelde, UI'da değil?
  /// Çünkü "doğruluk" sorunun bir özelliği. UI'ın işi göstermek,
  /// karar vermek değil. Aynı kontrolü ileride Provider da,
  /// test de çağırabilecek.
  bool isCorrect(AnswerOption option) => option.id == correctOptionId;
}
