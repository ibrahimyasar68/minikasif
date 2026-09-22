import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/data/question_data.dart';
import 'package:mini_kasif/models/game_section.dart';
import 'package:mini_kasif/models/question.dart';
import 'package:mini_kasif/providers/game_provider.dart';

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

/// Doğru cevaptan sonraki otomatik geçişin gerçekleşmesini bekler.
///
/// Testler sessiz ses servisi kullanıyor; övgü anında "biter", bu yüzden
/// geçiş en az bekleme süresinden sonra olur. pump(süre) sahte saati
/// ileri sarar; pumpAndSettle ardından geçiş animasyonunu bitirir.
///
/// DİKKAT: MiniKasifApp'e SilentAudioService geçilmezse gerçek TTS
/// kullanılır; test ortamında "bitti" haberi hiç gelmez ve bu bekleme
/// yetmez (geçiş ancak 4 sn'lik güvenlik sınırında olur).
Future<void> otomatikGecisiBekle(WidgetTester tester) async {
  await tester.pump(GameProvider.minCelebration);
  await tester.pumpAndSettle();
}

/// Ana sayfadaki ayar simgesini basılı tutarak Ayarlar'ı açar.
///
/// Ebeveyn kilidi: simge dokunmayla değil, basılı tutarak açılıyor.
/// startGesture parmağı indirir; pump(süre) sahte saati ileri sarar
/// (halka dolar); up() parmağı kaldırır.
///
/// DİKKAT: AnimationController saymaya forward() anında değil, SONRAKİ
/// İLK KAREDE başlar. Önce pump() ile o kareyi çizmezsek pump(2 sn)'nin
/// sonunda animasyon "şimdi başladım" sanır ve halka dolmaz.
Future<void> ayarlariAc(WidgetTester tester) async {
  final parmak = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.settings_rounded)),
  );
  await tester.pump(); // animasyonun ilk karesi
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 50));
  await parmak.up();
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
    await otomatikGecisiBekle(tester);
  }
}
