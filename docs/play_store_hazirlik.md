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

```bash
flutter build appbundle --release
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`. İmzanın debug değil
senin anahtarın olduğu doğrulanmalı.

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
| Tanıtım görseli | 1024×500 | ⬜ 🤖 ikon betiğinden üretilebilir |
| Telefon ekran görüntüleri | en az 2; uzun kenar kısa kenarın en fazla 2 katı | ⬜ Emülatör görüntüleri 1080×2400 (2,22 kat) — **sınırı aşıyor**, 1080×2160'a kırpılmalı 🤖 |

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
