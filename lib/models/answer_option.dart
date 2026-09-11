/// Ekranda çocuğun dokunabileceği TEK bir seçenek.
///
/// Neden ayrı bir model?
/// Bir seçenek sadece "Elma" yazısı değil; kimliği, görseli ve adı olan
/// bir varlık. String listesi kullansaydık görseli nereye koyacaktık?
class AnswerOption {
  /// Bu seçeneği benzersiz tanımlar. Doğru cevabı bununla eşleştireceğiz.
  final String id;

  /// Seçeneğin adı: 'Elma'. Çocuk okuyamaz ama biz test ederken,
  /// ileride de sesli okurken işimize yarayacak.
  final String label;

  /// ŞİMDİLİK görsel yerine emoji kullanıyoruz.
  /// Böylece tek bir .png dosyası olmadan oyunu çalıştırabiliriz.
  /// Asset aşamasında buraya `imagePath` ekleyeceğiz.
  final String emoji;

  // const constructor: değerler derleme anında biliniyorsa Flutter bu nesneyi
  // tekrar tekrar oluşturmaz, aynısını kullanır. Performans için önemli.
  const AnswerOption({
    required this.id,
    required this.label,
    required this.emoji,
  });
}
