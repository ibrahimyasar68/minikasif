// Doğru ve yanlış cevapta sesli okunan geri bildirim cümleleri.
//
// Neden ayrı bir dosya?
// Bunlar İÇERİK, oyun mantığı değil. Soru verisi gibi burada duruyor;
// cümle eklemek/değiştirmek GameProvider'a dokunmayı gerektirmiyor.
//
// Neden birden fazla cümle?
// Hep aynı "Aferin!" birkaç sorudan sonra anlamını yitirir.
// Cümleler sırayla dönüyor (rastgele değil): davranış öngörülebilir
// kalıyor ve test edilebiliyor.

/// Doğru cevapta, nesnenin adından SONRA okunur: "Elma! Aferin!"
const praisePhrases = [
  'Aferin!',
  'Harika!',
  'Çok güzel!',
  'Süpersin!',
  'Bravo!',
];

/// Yanlış cevapta, dokunulan nesnenin adından SONRA okunur:
/// "Muz. Bir daha deneyelim!"
///
/// KURAL (CLAUDE.md md.24): "yanlış", "hayır", "hata" gibi çocuğu
/// başarısız hissettiren kelimeler YOK. Bu kural test ile korunuyor.
const retryPhrases = [
  'Bir daha deneyelim!',
  'Hadi bir daha bak!',
  'Neredeyse! Tekrar dene.',
];
