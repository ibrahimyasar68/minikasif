# MiniKesif — Devam Notu

> Son güncelleme: 2026-09-21 · Son commit: `29abde7` (PHASE 25.3)
> Bu not, projeye ara verdikten sonra kaldığın yerden devam edebilmen için
> hazırlandı. Yeni bir oturumda önce bu dosyayı ve `CLAUDE.md`'yi oku.

---

## 1. Proje özeti

**Mini Kesif**: 0–4 yaş çocuklar için sesli, görsel ve dokunmatik eğitici oyun.
Çocuk sesli komutu dinler ("Kırmızı elmayı bul") ve doğru karta dokunur.

| Bilgi | Değer |
|---|---|
| Uygulama kimliği | `com.iylabs.minikesif` (yayından sonra değiştirilemez) |
| Ad | `Mini Kesif` (her yerde; ş'siz yazım bilinçli) |
| Sürüm | `1.0.0+1` (`pubspec.yaml`) |
| Dart paket adı | `mini_kesif` (sadece iç import adı, değişmedi) |
| Platform | Android (iOS hedeflenmiyor; bu makinede Xcode yok) |
| Flutter | 3.35.6 stable, Dart SDK ^3.9.2 |
| Paketler | `provider`, `flutter_tts`, `shared_preferences` (+ `cupertino_icons`) |
| İçerik | 3 bölüm × 10 soru = 30 soru |
| Testler | 27 test dosyası, **196 test** (hepsi geçiyor) |
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
| `design/ikon/` | 1024 px ana ikon, 512 px Play Store ikonu |
| `docs/play_store_hazirlik.md` | Play Store yayın kontrol listesi |
| `docs/gizlilik_politikasi.md` | Gizlilik politikası taslağı |
| `android/key.properties.example` | İmza bilgisi şablonu (parolasız) |
| `test/yatay_ekran_test.dart` | Pixel 6 yatayda her ekran kaydırmadan görünür mü |
| `test/app_adi_test.dart` | Launcher adı ile uygulama içi ad eşit mi |
| `test/helpers/oyun.dart` | Cevapları veriden okuyan ortak test adımları |
| `test/helpers/gercek_font.dart` | Yerleşim testleri için gerçek Roboto fontu |
| `test/fixtures/android8_emoji_kapsami.txt` | Android 8 emoji fontunun karakter listesi |

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
| 25.1 | Ad tutarsızlığı: her yerde `Mini Kesif`, sabit + manifest testi | `0353f7a` |
| 25.2 | Ayarlar › Hakkında: açıklama, gizlilik özeti, e-posta, IY Labs | `a9b3b14` |
| 25.3 | Yatay ekran: ana sayfa, oyun, sonuç iki sütun; ayarlar ortalı | `29abde7` |

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
- Emülatörü yan çevirmek: `adb shell wm user-rotation lock 1`
  (geri almak: `lock 0`, ardından `free`; bu otomatik döndürmeyi açar,
  gerekirse `settings put system accelerometer_rotation 0`).
- Flutter, Gradle uyarılarını ekranda göstermez. Önemli durumlar hata
  olarak verilmeli.

**Ad**
- Uygulama adı her yerde **`Mini Kesif`** (ş'siz; kullanıcı tercihi).
  Dart tarafı `lib/app_info.dart` içindeki `appName`'i kullanır;
  AndroidManifest bu sabiti okuyamadığı için elle yazılı, eşitliği
  `test/app_adi_test.dart` koruyor.

**Testler**
- Test ortamının fontu her harfi kare çizer ve metni çok uzun ölçer.
  Yerleşim testleri `gercekFontuYukle()` kullanmalı.
- `AnimationController` saymaya bir sonraki karede başlar; testte önce
  `tester.pump()` gerekir.
- Testlerde uygulama `MiniKesifApp(audio: SilentAudioService())` ile
  açılmalı. Gerçek TTS'in test ortamında "bitti" haberi hiç gelmez.
- Yeni emoji eklerken Android 8 kapsam testi eski cihazlarda görünmeyen
  emojiyi yakalar.

---

## 6. Yapılması planlananlar

### 6.1 PHASE 25'in kalanı — yayına hazırlık 🔄

Benim (AI) tarafım bitti. Sıradaki adım **senin**:

1. **İmza anahtarını oluştur** (parolaları kendin gir, yedekle, AI'a yazma):
   ```bash
   mkdir -p ~/iylabs-keys
   ```
   ```bash
   keytool -genkey -v -keystore ~/iylabs-keys/minikesif-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Şablonu kopyala, parolaları ve `storeFile` yolunu doldur:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
3. `.jks` dosyasını ve parolaları güvenli bir yere yedekle. Bu bir
   yükleme anahtarı: kaybolursa Play Console'dan sıfırlama istenebilir,
   ama süreç zahmetli.
4. AI'a **"anahtar hazır"** de.

Sonra AI'ın yapacakları:
- İmzalı `.aab` derlemek ve imzanın debug olmadığını doğrulamak
  (anahtar yokken `.aab` derlemesi bilerek hata veriyor).
- Ekran görüntüleri: Pixel 6 görüntüleri (1080×2400) Play'in 2:1
  sınırını aşıyor, 1080×2160'a kırpılacak.
- 1024×500 tanıtım görseli.

Senin yapacakların (ayrıntı: `docs/play_store_hazirlik.md`):
- Gizlilik politikasına iletişim e-postasını ve tarihi yazıp herkese açık
  bir adreste yayınlamak.
- Play Console geliştirici hesabı.
- Yeni kişisel hesaplarda yayından önce kapalı test (bilinen kural:
  12 test kullanıcısı, 14 gün; güncel şartı Play Console'da kontrol et).
- Mağaza formları: hedef kitle 0–5 (Aileler Politikası), veri güvenliği
  ("veri toplanmıyor"), içerik derecelendirmesi.

### 6.2 PHASE 26 — Gerçek görseller ⬜

Kartlarda emoji yerine resim.
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
      kimlikli (`com.minikesif.mini_kesif`) sürüm var. Yeni sürümü kurduktan
      sonra eski uygulamayı telefondan elle sil.
- [ ] **Telaffuz kontrolü:** "İneği", "Şemsiyeyi" gibi kelimelerin TTS
      telaffuzu kulakla dinlenmedi.
- [ ] Soru geçişinde çapraz solumada iki soru metni ~320 ms üst üste
      biniyor. İstenirse "önce sön, sonra belir" tarzına çevrilebilir.
- [ ] Samsung emoji tasarımında üzüm morumsu pembe görünüyor
      ("Mor üzümü bul" sorusu).

### 6.4 MVP sonrası fikir havuzu

`CLAUDE.md` md.34'ten kalanlar: rozetler, zorluk seviyeleri,
Türkçe/İngilizce dil desteği, çocuk profilleri, ebeveyn için istatistik
ekranı, arka plan müziği ve müzik ayarı.

---

## 7. Kaldığın yerden devam etmek için

1. Bu dosyayı ve `CLAUDE.md`'yi oku.
2. `flutter test` ile 196 testin geçtiğini doğrula.
3. Sıradaki iş: **6.1** (imza anahtarı). Anahtar oluşturulmadan
   Play Store dosyası derlenemez. Görsellerle ilerlemek istersen önce
   **6.2**'deki görsel kaynağı kararını ver.
4. Bu notu her safha sonunda güncelle (tamamlananlar tablosu ve plan).
