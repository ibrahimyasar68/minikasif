/// Oyundaki bölümler.
///
/// Neden String değil enum?
/// section: 'hayvanlar' yazsaydık, bir yerde 'hayvanlar', başka yerde
/// 'Hayvanlar' yazma riski olurdu ve derleyici uyarmazdı.
/// enum ile sadece tanımlı üç değer mümkün; yazım hatası imkansız.
///
/// Bu bir "enhanced enum": enum'a alan ve constructor ekleyebiliyoruz.
/// Bölümün adı ve simgesi bölümün kendi bilgisi, ayrı bir map'te
/// tutmaya gerek yok.
enum GameSection {
  fruits(title: 'Meyveler', emoji: '🍎'),
  animals(title: 'Hayvanlar', emoji: '🐱'),
  objects(title: 'Nesneler', emoji: '⚽');

  const GameSection({required this.title, required this.emoji});

  /// Ekranda gösterilecek bölüm adı.
  final String title;

  /// Bölümü temsil eden simge. Çocuk okuyamadığı için asıl ipucu bu.
  final String emoji;
}
