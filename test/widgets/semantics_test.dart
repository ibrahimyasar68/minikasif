import 'package:flutter_test/flutter_test.dart';
import 'package:mini_kesif/main.dart';

/// Ekran okuyucu (TalkBack) testleri.
///
/// find.text widget ağacında arar; find.bySemanticsLabel ise ekran
/// okuyucunun GÖRDÜĞÜ ağaçta. İkisi farklı: bir emoji widget ağacında
/// var ama ekran okuyucuya anlamlı bir şey söylemeyebilir.
void main() {
  Future<void> bolumeGir(WidgetTester tester) async {
    await tester.pumpWidget(const MiniKesifApp());
    await tester.tap(find.text('Meyveler'));
    await tester.pumpAndSettle();
  }

  testWidgets('Kartlar ekran okuyucuya adıyla bildirilir', (tester) async {
    final handle = tester.ensureSemantics();
    await bolumeGir(tester);

    for (final ad in ['Elma', 'Muz', 'Üzüm']) {
      expect(find.bySemanticsLabel(ad), findsOneWidget, reason: ad);
    }
    handle.dispose();
  });

  testWidgets('Doğru kart "doğru" olarak okunur', (tester) async {
    final handle = tester.ensureSemantics();
    await bolumeGir(tester);

    await tester.tap(find.text('Elma'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Elma, doğru'), findsOneWidget);
    handle.dispose();
  });

  // Yanlış kart "yanlış" diye DEĞİL "denendi" diye okunur:
  // ekran okuyucuda da cezalandırıcı dil kullanmıyoruz.
  testWidgets('Yanlış kart nazikçe "denendi" olarak okunur', (tester) async {
    final handle = tester.ensureSemantics();
    await bolumeGir(tester);

    await tester.tap(find.text('Muz'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Muz, denendi'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('yanlış')), findsNothing);
    handle.dispose();
  });
}
