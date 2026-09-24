# MiniKasif — Devam Notu

> Son güncelleme: 2026-09-24 · Son commit: `851b2cf` (PHASE 26 - emoji fontu)
> Bu not, projeye ara verdikten sonra kaldığın yerden devam edebilmen için
> hazırlandı. Yeni bir oturumda önce bu dosyayı ve `CLAUDE.md`'yi oku.

---

## 1. Proje özeti

**MiniKasif**: 0–4 yaş çocuklar için sesli, görsel ve dokunmatik eğitici oyun.
Çocuk sesli komutu dinler ("Kırmızı elmayı bul") ve doğru karta dokunur.

| Bilgi | Değer |
|---|---|
| Uygulama kimliği | `com.iylabs.minikasif` — **Play'e yüklendi, ARTIK DEĞİŞTİRİLEMEZ** |
| Ad | `MiniKasif` (her yerde; bitişik ve şapkasız yazım bilinçli) |
| Sürüm | `1.0.0+1` (`pubspec.yaml`) |
| Dart paket adı | `mini_kasif` (sadece iç import adı, değişmedi) |
| Platform | Android (iOS hedeflenmiyor; bu makinede Xcode yok) |
| Flutter | 3.35.6 stable, Dart SDK ^3.9.2 |
| Paketler | `provider`, `flutter_tts`, `shared_preferences` (+ `cupertino_icons`) |
| İçerik | 3 bölüm × 10 soru = 30 soru |
| Testler | 30 test dosyası, **203 test** (hepsi geçiyor) |
| Depo | https://github.com/ibrahimyasar68/minikasif (herkese açık) |
| Gizlilik politikası | https://ibrahimyasar68.github.io/minikasif/gizlilik_politikasi.html (GitHub Pages, kökteki `gizlilik_politikasi.md`) |
| Hedef | Play Store'da yayınlamak |

**Çalışma şekli** (`CLAUDE.md`): Kodu AI yazar. Proje safha safha ilerler;
her safha açıklanır, test edilir, commit edilir ve **onay gelmeden sonraki
safhaya geçilmez.**

## 2. Hızlı başlangıç

Durumu doğrula (hepsi geçmeli):
```bash
flutter test
```
```bash
flutter analyze
```

Emülatörü aç ve uygulamayı çalıştır:
```bash
flutter emulators --launch Pixel_6
```
```bash
flutter run -d emulator-5554
```

Test cihazları: Pixel_6 emülatörü (Android 14) ve Samsung Galaxy A7
SM-A720F (Android 8.0, USB ile bağlanıyor).

---

## 3. Mimari

```text
UI (pages, widgets)
   ↓ context.watch / select / read
Provider (ChangeNotifier)
   ↓
Service (AudioService) + Data (question_data)
```

| Dosya | Görevi |
|---|---|
| `lib/app_info.dart` | Ad, geliştirici (`IY Labs`), iletişim e-postası sabitleri |
| `lib/main.dart` | Açılışta ayarları yükler, 3 provider'ı kurar, temayı bağlar |
| `lib/models/question.dart` | Soru: metin, sesli metin, seçenekler, doğru cevap |
| `lib/models/answer_option.dart` | Seçenek: id, etiket, emoji |
| `lib/models/game_section.dart` | Bölüm enum'u (ad, emoji, sonraki bölüm) |
| `lib/data/question_data.dart` | 30 soru |
| `lib/data/feedback_phrases.dart` | Övgü ve teşvik cümleleri |
| `lib/providers/game_provider.dart` | Oyun durumu: cevap, skor, yıldız, otomatik geçiş, ses |
| `lib/providers/settings_provider.dart` | Ses açık/kapalı, tema (kalıcı) |
| `lib/providers/progress_provider.dart` | Bölüm başına en iyi yıldız (kalıcı) |
| `lib/services/audio_service.dart` | Ses arayüzü; TTS, sessiz ve ayara uyan uygulamaları |
| `lib/pages/home_page.dart` | Bölüm seçimi, yıldızlar, Türkçe ses uyarısı, ⚙️ |
| `lib/pages/game_page.dart` | Soru ekranı |
| `lib/pages/result_page.dart` | Sonuç, yıldızlar, rekor |
| `lib/pages/settings_page.dart` | Ses, tema, ilerlemeyi sıfırlama, Hakkında |
| `lib/widgets/answer_card.dart` | Tek seçenek kartı (animasyon, erişilebilirlik) |
| `lib/widgets/answer_grid.dart` | 2–3 seçenek tek sıra, 4 seçenek 2×2, sabit yükseklik |
| `lib/widgets/parent_gate_button.dart` | 2 sn basılı tutarak açılan ebeveyn kilidi |
| `lib/theme/app_colors.dart` | Açık/koyu renk paleti (`ThemeExtension`) |
| `lib/theme/app_theme.dart` | Açık ve koyu tema |

Diğer klasörler:

| Yol | İçerik |
|---|---|
| `tool/ikon_uret.py` | Uygulama ikonunu koddan üretir (Pillow) |
| `tool/emoji_fontu_uret.py` | Gömülü emoji fontunu üretir (altküme) |
| `assets/fonts/` | Gömülü emoji fontu ve OFL lisansı |
| `design/ikon/` | 1024 px ana ikon, 512 px Play Store ikonu |
| `design/magaza/` | Mağaza ekran görüntüleri ve 1024×500 tanıtım görseli |
| `tool/tanitim_gorseli.py` | Tanıtım görselini koddan üretir |
| `docs/play_store_hazirlik.md` | Play Store yayın kontrol listesi |
| `gizlilik_politikasi.md` | Gizlilik politikası (e-posta ve tarih dolu; yayınlanmayı bekliyor) |
| `android/key.properties.example` | İmza bilgisi şablonu (parolasız) |
| `test/yatay_ekran_test.dart` | Pixel 6 yatayda her ekran kaydırmadan görünür mü |
| `test/ekran_yonu_test.dart` | Manifest'te screenOrientation="sensor" mı |
| `test/data/emoji_fontu_test.dart` | Çizilen her emoji gömülü fontta var mı |
| `test/gizlilik_politikasi_test.dart` | Politikadaki e-posta uygulamadakiyle aynı mı, yer tutucu kaldı mı |
| `test/soru_gecisi_test.dart` | Soru geçişinde iki metin üst üste binmiyor mu |
| `test/app_adi_test.dart` | Launcher adı ile uygulama içi ad eşit mi |
| `test/helpers/oyun.dart` | Cevapları veriden okuyan ortak test adımları |
| `test/helpers/gercek_font.dart` | Yerleşim testleri için gerçek Roboto fontu |
| `test/fixtures/emoji_fontu_kapsami.txt` | Gömülü fontun kapsadığı kod noktaları (betik üretir) |

---

## 4. Tamamlanan safhalar

| Safha | Ne yapıldı | Commit |
|---|---|---|
| 0–11 | Kurulum, model, veri, oyun ekranı, cevap kontrolü, Provider, soru geçişi, skor, bölümler, TTS | `ad8ae86` |
| düzeltme | Oyun ekranı içeriğinin sola kayması | `20f061a` |
| 12 | Basit animasyonlar (paketsiz) | `afc5fe0` |
| 13 | Sonuç ekranı ayrı sayfa | `2b443cc` |
| 14 | UI polish: kart dizilimi, taşma, erişilebilirlik, renkler | `39815c7` |
| 15 | Test gözden geçirme; geri dönüşte ses durmuyordu | `378fadb` |
| içerik | 30 soru; testler cevapları veriden okuyor | `7b4e262` |
| 16 | Doğru/yanlış cevapta sesli geri bildirim | `5f08e01` |
| 17 | Doğru cevaptan sonra otomatik soru geçişi | `47e4e8a` |
| 18 | Gerçek cihaz: Türkçe ses motoru seçimi, konuşma sırası | `2c618b5` |
| 19 | Türkçe ses yoksa sessizlik ve ebeveyn uyarısı | `dfbe265` |
| 19.1 | Android 8'de görünmeyen 🧸 → 🥁 Davul | `9889d5e` |
| 20 | Soru başlığı her soruda aynı yerde | `35a2eb7` |
| 21 | Ayarlar: ses açma/kapama, açık/koyu/sistem tema | `837e0d2` |
| 22 | Ebeveyn kilidi (2 sn basılı tut) | `e29db67` |
| 23 | İlerleme takibi: en iyi yıldızlar, rekor, sıfırlama | `8bd4e48` |
| 24 | Uygulama ikonu: büyüteç, içinde elma, parıltı | `328beb5` |
| 24.1 | İkona "IY Labs" etiketi | `a0e89b7` |
| 25 | Yayına hazırlık: ad, kimlik, imza altyapısı, belgeler (**kısmen**) | `f1fb5b6` |
| 25.1 | Ad tutarsızlığı: tek sabit + manifest testi (ad o zaman `Mini Kesif`) | `0353f7a` |
| 25.2 | Ayarlar › Hakkında: açıklama, gizlilik özeti, e-posta, IY Labs | `a9b3b14` |
| 25.3 | Yatay ekran: ana sayfa, oyun, sonuç iki sütun; ayarlar ortalı | `29abde7` |
| 25.4 | Döndürme kilidinden bağımsız otomatik döndürme (`sensor`) | `0a5c2c8` |
| 25.5 | Gizlilik politikası: e-posta ve tarih dolduruldu | `bb7221c` |
| 25.6 | Soru geçişi: önce sön, sonra belir; geçişte dokunma kilidi | `43d645a` |
| 25.7 | Mağaza görselleri, tanıtım görseli, derleme güvencesi | `85a0586` |
| 25 (kalan) | İmza anahtarı, imzalı `.aab`, imza doğrulaması | `93f0b25` |
| 25.8 | Ad ve kimlik: MiniKasif / com.iylabs.minikasif | `e4250cc` |
| 26 | Emoji fontu gömüldü (Noto altkümesi, 53 KB); Android 8 kapsam testi kalktı | `851b2cf` |

Her commit mesajında o safhanın ayrıntılı açıklaması var:
`git log` ile okunabilir.

---

## 5. Önemli kararlar ve tuzaklar

Tekrar düşmemek için bilinmesi gerekenler.

**Oyun ve ürün kararları**
- Skor, **ilk denemede bilinen** soru sayısına göre. Bölümü bitiren her
  çocuk en az 1 yıldız alır. Yanlış cevapta ceza, kırmızı renk ya da
  olumsuz kelime yok (testle korunuyor).
- Doğru cevaptan sonra övgü bitince otomatik geçiş: en az 1,2 sn,
  en fazla 4 sn.
- Daha kötü bir oyun rekoru bozmaz. Oynanmamış bölümde boş yıldızlar
  (☆☆☆) görünür; rekor sesli de okunur.

**Ses (TTS)**
- Samsung'un varsayılan ses motoru Türkçe bilmiyor. Uygulama Türkçe bilen
  motoru (Google) kendisi seçiyor. Hiçbiri yoksa sessiz kalıp uyarı
  gösteriyor.
- Aynı anda gelen konuşma isteklerinde **en son istek kazanır**
  (Android eklentisi araya giren konuşmayı sessizce reddediyor).
- **Release derlemede** eklentinin "Utterance ID has started" log satırı
  yazılmıyor. Sesin çalıştığını ölçmek için `adb shell dumpsys audio`
  çıktısında TTS oynatıcısına bakılmalı.

**Flutter**
- `Scaffold` gövdeye gevşek genişlik verir; `Column` sola yapışır.
  Ekran içeriği `Center` ile sarılmalı.
- `AnimatedSwitcher`'da iki çocuk aynı tipteyse farklı `key` şart,
  yoksa geçiş hiç olmuyor.
- Ekran çizilirken (`initState`) `notifyListeners()` tetiklemek
  "setState() or markNeedsBuild() called during build" hatası verir.
  Rekor bu yüzden `GamePage`'in dinleyicisinde kaydediliyor.
- **Yatay ekran:** sayfalar `maxWidth > maxHeight` ise iki sütuna geçer
  (karar `LayoutBuilder` kısıtlarıyla, telefon yönüyle değil). Kare ya da
  geniş bir test ekranı da yatay sayılır; dikey düzeni ölçen testler
  dikey bir ekran kurmalı.
- Ekran yönü manifest'te `screenOrientation="sensor"`: telefonun
  otomatik döndürme ayarı kapalı olsa da döner, ters dikeye dönmez
  (`fullSensor` bu yüzden seçilmedi).
- Emülatörde döndürmeyi denemek için ivme sensörünü ayarla:
  `adb emu sensor set acceleration 9.81:0:0` (yatay),
  `0:9.81:0` (dik). `adb emu rotate` KULLANMA: sistemin otomatik
  döndürme ayarını da açıyor, deneyi bozuyor.
- Flutter, Gradle uyarılarını ekranda göstermez. Önemli durumlar hata
  olarak verilmeli.
- `android/key.properties` git'e girmiyor; bir kez şablon değerlerine
  DÖNMÜŞ ve derleme "Keystore file ... not found" hatası vermişti. Yeni
  sürüm yüklemeden önce `flutter build appbundle --release` ile dene.
- `android/key.properties` yoksa `.aab` derlemesi hata verir ve önceki
  derlemeden kalan `app-release.aab` varsa siler. (Bir kez, güvence
  eklenmeden önce derlenmiş debug imzalı bir paket klasörde kalmıştı;
  öylesi yanlışlıkla Play'e yüklenebilir.)

**Ad ve kimlik**
- Uygulama adı her yerde **`MiniKasif`** (bitişik, şapkasız; kullanıcı
  tercihi). Dart tarafı `lib/app_info.dart` içindeki `appName`'i kullanır;
  AndroidManifest bu sabiti okuyamadığı için elle yazılı, eşitliği
  `test/app_adi_test.dart` koruyor.
- Ad ve kimlik PHASE 25.8'de `Mini Kesif` / `com.iylabs.minikesif`'ten
  değişti. Kimlik yalnızca Play'de YAYINLANDIKTAN sonra kilitlenir; bir
  daha değiştirilemez. İmza anahtarı kimliğe bağlı değil, ad değişince
  yeniden oluşturmak gerekmedi.

**Testler**
- Test ortamının fontu her harfi kare çizer ve metni çok uzun ölçer.
  Yerleşim testleri `gercekFontuYukle()` kullanmalı.
- `AnimationController` saymaya bir sonraki karede başlar; testte önce
  `tester.pump()` gerekir.
- Testlerde uygulama `MiniKasifApp(audio: SilentAudioService())` ile
  açılmalı. Gerçek TTS'in test ortamında "bitti" haberi hiç gelmez.
- **Emoji fontu gömülü.** Yeni emoji eklenince
  `python3 tool/emoji_fontu_uret.py <NotoColorEmoji.ttf>` çalıştırılmalı;
  yoksa emoji telefonda BOŞ KUTU çıkar (test yakalar). Kaynak fontun
  indirme komutu betiğin başında: Google Fonts modern tarayıcıya woff2
  veriyor, TTF için eski bir tarayıcı kimliği gerekiyor.
- Emojinin gerçekten gömülü fonttan çizildiğini görmek için fontta bir
  emojiyi başka bir glife bağlayıp ekrana bakmak yeterli (PHASE 26'da
  elma -> muz ile doğrulandı). Pixel emülatörü de Noto kullandığı için
  çıplak gözle ayırt edilemez.

---

## 6. Yapılması planlananlar

### 6.1 PHASE 25 — yayına hazırlık ✅ (AI tarafı bitti)

İmza anahtarı hazır (`~/iylabs-keys/minikesif-upload.jks` — dosya adı eski
adla kaldı, anahtarın uygulama kimliğiyle ilgisi yok; takma ad `upload`),
`android/key.properties` dolu (git'e girmez), imzalı paket derlendi ve
doğrulandı:
`build/app/outputs/bundle/release/app-release.aab` (41,1 MB, sertifika
sahibi `CN=Ibrahim YASAR`). Grafikler `design/magaza/` altında.

Yeni paket gerektiğinde: `flutter build appbundle --release`, ardından
`keytool -printcert -jarfile ...` ile imza kontrolü. Her yüklemede
`pubspec.yaml` içindeki sürümün `+` sonrası artmalı.

**Yayın durumu (24 Eylül 2026):** **Kapalı test yayını başladı.** Kapalı
test kanalının herkese açık mağaza sayfası olmaz; bu yüzden
`play.google.com/store/apps/details?id=com.iylabs.minikasif` 404 veriyor,
bu beklenen durum. Üretime çıkınca o adres açılacak.

Bundan sonra her yeni yüklemede `pubspec.yaml` içindeki sürümün `+`
sonrası (versionCode) artmalı: Play aynı versionCode'u ikinci kez kabul
etmez.

**Kalanlar senin (ayrıntı: `docs/play_store_hazirlik.md`):**
- Play Console geliştirici hesabı.
- Yeni kişisel hesaplarda yayından önce kapalı test (bilinen kural:
  12 test kullanıcısı, 14 gün; güncel şartı Play Console'da kontrol et).
- Mağaza formları: hedef kitle 0–5 (Aileler Politikası), veri güvenliği
  ("veri toplanmıyor"), içerik derecelendirmesi.
- `.jks` dosyasını ve parolaları yedeklemek.

### 6.2 PHASE 27 — Gerçek görseller ⬜ (isteğe bağlı)

PHASE 26'da emoji fontu gömüldü: emojiler artık her cihazda aynı ve
eksiksiz. Özgün çizimler istenirse:
- `AnswerOption`'a `imagePath`; görsel yoksa ya da yüklenemezse emojiye
  düşülecek (kart asla boş kalmayacak).
- Görseller `assets/images/` altına, `pubspec.yaml`'a tanım.
- Test: her görsel dosyası gerçekten var mı, APK boyutu.

**Başlamadan önce karar gerekiyor: görsel kaynağı.**
- Kendin sağlarsın.
- Açık lisanslı set (OpenMoji, Twemoji): indirmek için açık onay ve
  uygulamada kaynak belirtme gerekir.
- Alternatif (daha ucuz, ayrı bir safha): emoji kalır, emoji fontu
  (~10 MB) uygulamaya gömülür. Emojiler her telefonda aynı görünür ve
  eski cihaz sorunu biter, ama görünüm özgünleşmez.

### 6.3 Bekleyen küçük işler ve açık kararlar

- [ ] **Telefona güncel sürüm:** telefonda hâlâ PHASE 20 civarı, eski
      kimlikli (`com.minikesif.mini_kesif`) sürüm var. Kimlik o zamandan beri
      iki kez değişti (`com.iylabs.minikesif` → `com.iylabs.minikasif`), yani
      eski sürümler ayrı uygulama olarak durur: yenisini kurduktan sonra
      eskileri telefondan elle sil.
- [ ] **Telaffuz kontrolü:** "İneği", "Şemsiyeyi" gibi kelimelerin TTS
      telaffuzu kulakla dinlenmedi.
- [ ] **İsteğe bağlı:** PHASE 19.1'de Android 8'de görünmediği için
      🧸 yerine 🥁 konmuştu. Font gömüldüğü için bu kısıt kalktı;
      istenirse oyuncak ayı geri gelebilir.

### 6.4 MVP sonrası fikir havuzu

`CLAUDE.md` md.34'ten kalanlar: rozetler, zorluk seviyeleri,
Türkçe/İngilizce dil desteği, çocuk profilleri, ebeveyn için istatistik
ekranı, arka plan müziği ve müzik ayarı.

---

## 7. Kaldığın yerden devam etmek için

1. Bu dosyayı ve `CLAUDE.md`'yi oku.
2. `flutter test` ile 203 testin geçtiğini doğrula.
3. Sıradaki iş: kod tarafında **6.2** (gerçek görseller) — başlamadan
   önce görsel kaynağı kararını ver. Yayın tarafında iş AI'da değil:
   **6.1**'deki "Kalanlar senin" listesi (Play Console hesabı, gizlilik
   politikasının yayınlanması, kapalı test, mağaza formları).
4. Bu notu her safha sonunda güncelle (tamamlananlar tablosu ve plan).
