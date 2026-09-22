import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kasif/models/game_section.dart';
import 'package:mini_kasif/providers/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const meyveler = GameSection.fruits;
  const hayvanlar = GameSection.animals;

  test('başlangıçta her bölüm 0 yıldız, ilerleme boş', () {
    final p = ProgressProvider();
    for (final b in GameSection.values) {
      expect(p.enIyi(b), 0);
    }
    expect(p.bosMu, isTrue);
  });

  test('ilk sonuç yeni rekordur, kaydedilir ve haber verilir', () {
    final p = ProgressProvider();
    var bildirim = 0;
    p.addListener(() => bildirim++);

    expect(p.kaydet(meyveler, 2), isTrue);
    expect(p.enIyi(meyveler), 2);
    expect(p.bosMu, isFalse);
    expect(bildirim, 1);
  });

  test('daha iyi sonuç rekoru günceller', () {
    final p = ProgressProvider()..kaydet(meyveler, 2);
    expect(p.kaydet(meyveler, 3), isTrue);
    expect(p.enIyi(meyveler), 3);
  });

  // Çocuk kazandığı yıldızı kaybetmemeli.
  test('eşit ya da daha kötü sonuç rekoru bozmaz, boşuna haber yok', () {
    final p = ProgressProvider()..kaydet(meyveler, 3);
    var bildirim = 0;
    p.addListener(() => bildirim++);

    expect(p.kaydet(meyveler, 3), isFalse);
    expect(p.kaydet(meyveler, 1), isFalse);
    expect(p.enIyi(meyveler), 3);
    expect(bildirim, 0);
  });

  test('bölümler birbirinden bağımsız', () {
    final p = ProgressProvider()..kaydet(meyveler, 3);
    expect(p.enIyi(hayvanlar), 0);
    expect(p.kaydet(hayvanlar, 1), isTrue);
    expect(p.enIyi(meyveler), 3);
  });

  test('ilerleme kaydedilir, yeniden açılınca hatırlanır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProgressProvider(prefs: prefs).kaydet(hayvanlar, 2);

    expect(ProgressProvider(prefs: prefs).enIyi(hayvanlar), 2);
  });

  test('bozuk kayıt 0-3 aralığına sıkıştırılır', () async {
    SharedPreferences.setMockInitialValues({
      'en_iyi_yildiz_fruits': 7,
      'en_iyi_yildiz_animals': -2,
    });
    final p = ProgressProvider(prefs: await SharedPreferences.getInstance());
    expect(p.enIyi(meyveler), 3);
    expect(p.enIyi(hayvanlar), 0);
  });

  test('sıfırla her şeyi siler, kalıcıdır ve haber verir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = ProgressProvider(prefs: prefs)
      ..kaydet(meyveler, 3)
      ..kaydet(hayvanlar, 1);
    var bildirim = 0;
    p.addListener(() => bildirim++);

    p.sifirla();

    expect(p.bosMu, isTrue);
    expect(bildirim, 1);
    expect(ProgressProvider(prefs: prefs).bosMu, isTrue, reason: 'kalıcı');
  });

  test('zaten boşken sıfırla boşuna haber vermez', () {
    final p = ProgressProvider();
    var bildirim = 0;
    p.addListener(() => bildirim++);
    p.sifirla();
    expect(bildirim, 0);
  });
}
