/// Uygulamanın kullanıcıya görünen adı.
///
/// Tek kaynak: hem açılış ekranındaki başlık hem de MaterialApp'in başlığı
/// buradan okur. Android launcher adı (AndroidManifest.xml'deki
/// `android:label`) bu dosyayı okuyamadığı için elle yazılmak zorunda;
/// ikisinin aynı kaldığını `test/app_adi_test.dart` doğruluyor.
///
/// Not: "Keşif" değil "Kesif" — ş'siz yazım bilinçli bir tercih.
const appName = 'Mini Kesif';
