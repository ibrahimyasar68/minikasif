import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/data/question_data.dart';
import 'package:mini_kesif/models/game_section.dart';
import 'package:mini_kesif/models/question.dart';

/// Testler arasında paylaşılan oyun adımları.
///
/// Neden var?
/// Önceden her test dosyası doğru cevapları elle listeliyordu:
/// ['Elma', 'Muz', 'Portakal', 'Çilek']. Soru sayısı değişince bu
/// listelerin hepsi aynı anda bozuluyordu. Artık cevaplar VERİDEN
/// okunuyor: soru eklemek testleri kırmıyor.
///
/// Dosya adı _test.dart ile bitmiyor: flutter test bunu kendi başına
/// test olarak çalıştırmıyor, sadece diğer testler içe aktarıyor.

/// Görünür yapar, dokunur ve animasyonların bitmesini bekler.
///
/// ensureVisible: küçük ekranda veya küçük test penceresinde hedef
/// kaydırma alanının dışında kalabilir; o zaman dokunma ıskalar.
Future<void> dokun(WidgetTester tester, Finder hedef) async {
  await tester.ensureVisible(hedef);
  await tester.pumpAndSettle();
  await tester.tap(hedef);
  await tester.pumpAndSettle();
}

/// Bölüm seçim ekranından bir bölüme girer.
Future<void> bolumeGir(WidgetTester tester, GameSection bolum) =>
    dokun(tester, find.text(bolum.title));

/// Bir sorunun doğru seçeneğinin etiketi.
String dogruEtiket(Question soru) =>
    soru.options.firstWhere(soru.isCorrect).label;

/// Bir sorunun ilk yanlış seçeneğinin etiketi.
String yanlisEtiket(Question soru) =>
    soru.options.firstWhere((o) => !soru.isCorrect(o)).label;

/// İçinde bulunulan bölümü sonuna kadar oynar; sonuç ekranında bırakır.
///
/// [hataliSoruSayisi]: ilk bu kadar soruda önce yanlış seçeneğe dokunur.
/// [sorudaIken]: her soru ekrana gelince, cevaplamadan ÖNCE çağrılır.
/// Her soruda bir şey kontrol etmek isteyen testler için.
Future<void> bolumuOyna(
  WidgetTester tester,
  GameSection bolum, {
  int hataliSoruSayisi = 0,
  Future<void> Function(Question soru)? sorudaIken,
}) async {
  final sorular = questionsOf(bolum);
  for (var i = 0; i < sorular.length; i++) {
    final soru = sorular[i];
    if (sorudaIken != null) await sorudaIken(soru);
    if (i < hataliSoruSayisi) {
      await dokun(tester, find.text(yanlisEtiket(soru)));
    }
    await dokun(tester, find.text(dogruEtiket(soru)));
    await dokun(tester, find.textContaining(RegExp('Devam|Bitir')));
  }
}
