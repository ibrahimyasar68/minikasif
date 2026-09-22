# Play Store Yayın Kontrol Listesi — Mini Kesif

Kimlik: `com.iylabs.minikesif` · Sürüm: `1.0.0` (versionCode 1)

İşaretler: 🧑 senin yapman gereken · 🤖 benim hazırladığım/hazırlayabileceğim

## 1. İmza anahtarı 🧑

Anahtar yoksa `.aab` derlemesi bilerek hata verir.

1. Anahtarı oluştur (parolaları kendin gir, bir yere yaz):
   ```bash
   mkdir -p ~/iylabs-keys
   ```
   ```bash
   keytool -genkey -v -keystore ~/iylabs-keys/minikesif-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. `android/key.properties.example` dosyasını `android/key.properties` olarak
   kopyala, parolaları ve `storeFile` yolunu doldur. (Git'e girmez.)
3. `.jks` dosyasını ve parolaları **yedekle** (parola yöneticisi + ikinci bir
   konum). Play App Signing sayesinde bu bir "yükleme anahtarı"dır: kaybolursa
   Play Console'dan sıfırlama istenebilir, ama süreç zahmetlidir.

## 2. Derleme 🤖

Anahtar hazır olduğunda (1. adım), proje kökünde:

```bash
flutter test
```

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`. Play Console'a
yüklenecek dosya budur (`.apk` değil).

**İmzayı doğrula.** Çıktıda `CN=Android Debug` YAZMAMALI; kendi adın/kurumun
görünmeli:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Notlar:
- `key.properties` yoksa `.aab` derlemesi bilerek hata verir ve önceki
  derlemeden kalan `app-release.aab` varsa siler. (Bir kez, güvence eklenmeden
  önce derlenmiş debug imzalı bir paket klasörde kalmıştı; böyle bir dosya
  yanlışlıkla yüklenebilir.)
- Telefonda denemek için `.apk` yeterli ve anahtar gerektirmez:
  `flutter build apk --release`.
- Her yeni yüklemede `pubspec.yaml` içindeki sürümün `+` sonrası artmalı.

## 3. Play Console hesabı 🧑

- Geliştirici hesabı (tek seferlik ücret).
- **Yeni kişisel hesaplarda** üretime çıkmadan önce **kapalı test** zorunlu
  (bilinen kural: en az 12 test kullanıcısı, 14 gün). Güncel şartı Play
  Console'da kontrol et. Kuruluş hesaplarında bu şart yok.

## 4. Mağaza girişi 🤖 taslak / 🧑 onay

- **Uygulama adı** (≤30): `Mini Kesif`
- **Kısa açıklama** (≤80, şu an 76): 0-4 yaş için sesli ve dokunmatik eğitici oyun: meyveler, hayvanlar, nesneler
- **Uzun açıklama** (≤4000, şu an 634):

```text
Mini Kesif, 0-4 yaş çocuklar için dinle, bak ve dokun temelli bir eğitici oyundur.

Çocuk sesli komutu dinler ("Kırmızı elmayı bul") ve doğru resme dokunur. Okuma bilmeyen küçük çocuklar için tasarlandı: büyük kartlar, sesli yönlendirme ve az yazı.

• 3 bölüm, 30 soru: Meyveler ve renkler, Hayvanlar, Nesneler
• Sesli sorular ve sesli övgü
• Yanlış cevapta ceza yok: nazik bir teşvikle tekrar deneme
• Her bölümde 3 yıldız ve rekor takibi
• Açık, koyu ve sistem teması
• Ebeveyn kilidi: ayarlar basılı tutarak açılır

Güvenli ve sade:
• Reklam yok
• Uygulama içi satın alma yok
• İnternet bağlantısı gerekmez
• Kişisel veri toplanmaz
```

## 5. Grafikler

| Öğe | Şart | Durum |
|---|---|---|
| Uygulama ikonu | 512×512 PNG | ✅ `design/ikon/play_store_512.png` |
| Tanıtım görseli | 1024×500 | ✅ `design/magaza/tanitim_1024x500.png` (`python3 tool/tanitim_gorseli.py`) |
| Telefon ekran görüntüleri | en az 2; uzun kenar kısa kenarın en fazla 2 katı | ✅ `design/magaza/telefon_*.png` — 5 dikey (1080×2160) + 2 yatay (2160×1080), hepsi tam 2:1 |

Ekran görüntüleri Pixel 6 emülatöründen alındı (1080×2400 = 2,22 kat; sınırı
aşıyordu). Dikeylerde üstten ve alttan 120'şer piksel kırpıldı: hem oran 2:1
oldu hem de durum çubuğu ile hareket çubuğu çıktı. Yataylarda soldaki kamera
çentiği bandı kırpıldı.

| Dosya | Ekran |
|---|---|
| `telefon_ana_sayfa.png` | Bölüm seçimi, kazanılan yıldızlar |
| `telefon_soru_3secenek.png` | Soru ekranı, 3 seçenek |
| `telefon_dogru_cevap.png` | Doğru cevap ve "Aferin!" |
| `telefon_soru_4secenek.png` | 4 seçenekli soru (2×2) |
| `telefon_sonuc.png` | Bölüm sonu, 3 yıldız |
| `telefon_yatay_ana_sayfa.png` | Yatay ekranda bölüm seçimi |
| `telefon_yatay_soru.png` | Yatay ekranda soru |

## 6. Uygulama içeriği (Play Console) 🧑

- **Gizlilik politikası:** `docs/gizlilik_politikasi.md` hazır (e-posta ve
  tarih dolu). Herkese açık bir adreste yayınla; adresi gir.
- **Reklamlar:** Hayır.
- **Uygulama erişimi:** Kısıtlama yok (giriş yok). Not: Ayarlar, simgeyi 2 sn
  basılı tutarak açılır.
- **İçerik derecelendirmesi:** anketi doldur (eğitici, uygunsuz içerik yok).
- **Hedef kitle:** 0-5 yaş → **Aileler Politikası** geçerli. Uygulama reklam,
  veri toplama ve harici bağlantı içermediği için uyumlu.
- **Veri güvenliği:** "Kullanıcı verisi toplanmıyor veya paylaşılmıyor".
  (Ayarlar ve ilerleme sadece cihazda kalıyor; cihazdan çıkmayan veri
  "toplama" sayılmaz.)
- Haber / sağlık / finans / devlet uygulaması değil.

## 7. Yayın akışı

1. Dahili test → 2. Kapalı test (kişisel hesapta zorunlu süre) → 3. Üretim.
Her yeni yüklemede `pubspec.yaml` içindeki `version: 1.0.0+1` değerinin `+`
sonrası artırılmalı (ör. `1.0.1+2`).
