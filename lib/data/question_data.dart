import '../models/answer_option.dart';
import '../models/game_section.dart';
import '../models/question.dart';

// --- Ortak seçenekler ---
// Aynı nesne birden fazla soruda geçiyor. Tek yerde tanımlayıp
// tekrar kullanıyoruz; emoji veya isim değişirse tek satır.

// Meyveler
const _elma = AnswerOption(id: 'elma', label: 'Elma', emoji: '🍎');
const _muz = AnswerOption(id: 'muz', label: 'Muz', emoji: '🍌');
const _portakal = AnswerOption(id: 'portakal', label: 'Portakal', emoji: '🍊');
const _uzum = AnswerOption(id: 'uzum', label: 'Üzüm', emoji: '🍇');
const _cilek = AnswerOption(id: 'cilek', label: 'Çilek', emoji: '🍓');
const _karpuz = AnswerOption(id: 'karpuz', label: 'Karpuz', emoji: '🍉');
const _armut = AnswerOption(id: 'armut', label: 'Armut', emoji: '🍐');
const _kiraz = AnswerOption(id: 'kiraz', label: 'Kiraz', emoji: '🍒');
const _limon = AnswerOption(id: 'limon', label: 'Limon', emoji: '🍋');
const _ananas = AnswerOption(id: 'ananas', label: 'Ananas', emoji: '🍍');

// Hayvanlar
const _kedi = AnswerOption(id: 'kedi', label: 'Kedi', emoji: '🐱');
const _kopek = AnswerOption(id: 'kopek', label: 'Köpek', emoji: '🐶');
const _aslan = AnswerOption(id: 'aslan', label: 'Aslan', emoji: '🦁');
const _fil = AnswerOption(id: 'fil', label: 'Fil', emoji: '🐘');
const _tavsan = AnswerOption(id: 'tavsan', label: 'Tavşan', emoji: '🐰');
const _inek = AnswerOption(id: 'inek', label: 'İnek', emoji: '🐄');
const _at = AnswerOption(id: 'at', label: 'At', emoji: '🐴');
const _ordek = AnswerOption(id: 'ordek', label: 'Ördek', emoji: '🦆');
const _balik = AnswerOption(id: 'balik', label: 'Balık', emoji: '🐟');
const _maymun = AnswerOption(id: 'maymun', label: 'Maymun', emoji: '🐵');

// Nesneler
const _top = AnswerOption(id: 'top', label: 'Top', emoji: '⚽');
const _araba = AnswerOption(id: 'araba', label: 'Araba', emoji: '🚗');
const _balon = AnswerOption(id: 'balon', label: 'Balon', emoji: '🎈');
const _kitap = AnswerOption(id: 'kitap', label: 'Kitap', emoji: '📕');
const _ucak = AnswerOption(id: 'ucak', label: 'Uçak', emoji: '✈️');
const _semsiye = AnswerOption(id: 'semsiye', label: 'Şemsiye', emoji: '☂️');
const _ayicik = AnswerOption(id: 'ayicik', label: 'Ayıcık', emoji: '🧸');
const _bisiklet = AnswerOption(id: 'bisiklet', label: 'Bisiklet', emoji: '🚲');
const _saat = AnswerOption(id: 'saat', label: 'Saat', emoji: '⏰');
const _kalem = AnswerOption(id: 'kalem', label: 'Kalem', emoji: '✏️');
const _tren = AnswerOption(id: 'tren', label: 'Tren', emoji: '🚂');

/// Oyunun tüm soruları: 3 bölüm x 10 soru = 30 (CLAUDE.md md.3).
///
/// Seçenek sayısı bilerek karışık (2, 3 veya 4):
/// - 2 seçenek en kolayı, küçük yaş için nefes aldırır.
/// - 4 seçenek en zoru.
///
/// RENK SORULARINDA KURAL: aynı renkte çeldirici YOK.
/// "Sarı limonu bul" sorusunda muz yok; "Kırmızı kirazı bul" sorusunda
/// elma ve çilek yok. Okuyamayan çocuk renkten gidiyor; aynı renkte iki
/// seçenek soruyu adil olmaktan çıkarır.
const List<Question> allQuestions = [
  // --- Bölüm 1: Meyveler ve renkler ---
  Question(
    id: 'f1',
    section: GameSection.fruits,
    questionText: 'Kırmızı elmayı bul',
    audioText: 'Haydi bakalım, kırmızı elmaya dokun!',
    options: [_elma, _muz, _uzum],
    correctOptionId: 'elma',
  ),
  Question(
    id: 'f2',
    section: GameSection.fruits,
    questionText: 'Sarı muzu bul',
    options: [_cilek, _muz, _portakal],
    correctOptionId: 'muz',
  ),
  Question(
    id: 'f3',
    section: GameSection.fruits,
    questionText: 'Turuncu portakalı bul',
    options: [_uzum, _cilek, _portakal],
    correctOptionId: 'portakal',
  ),
  Question(
    id: 'f4',
    section: GameSection.fruits,
    questionText: 'Kırmızı çileği bul',
    options: [_cilek, _muz, _uzum],
    correctOptionId: 'cilek',
  ),
  Question(
    id: 'f5',
    section: GameSection.fruits,
    questionText: 'Mor üzümü bul',
    options: [_cilek, _uzum],
    correctOptionId: 'uzum',
  ),
  Question(
    id: 'f6',
    section: GameSection.fruits,
    questionText: 'Sarı limonu bul',
    // Muz bilerek yok: o da sarı.
    options: [_elma, _limon, _uzum, _kiraz],
    correctOptionId: 'limon',
  ),
  Question(
    id: 'f7',
    section: GameSection.fruits,
    questionText: 'Yeşil armudu bul',
    options: [_armut, _kiraz, _portakal],
    correctOptionId: 'armut',
  ),
  Question(
    id: 'f8',
    section: GameSection.fruits,
    questionText: 'Kırmızı kirazı bul',
    // Elma ve çilek bilerek yok: onlar da kırmızı.
    options: [_muz, _kiraz, _uzum, _limon],
    correctOptionId: 'kiraz',
  ),
  Question(
    id: 'f9',
    section: GameSection.fruits,
    questionText: 'Karpuzu bul',
    options: [_karpuz, _ananas],
    correctOptionId: 'karpuz',
  ),
  Question(
    id: 'f10',
    section: GameSection.fruits,
    questionText: 'Ananası bul',
    options: [_portakal, _ananas, _uzum],
    correctOptionId: 'ananas',
  ),

  // --- Bölüm 2: Hayvanlar ---
  Question(
    id: 'a1',
    section: GameSection.animals,
    questionText: 'Kediyi bul',
    audioText: 'Miyav! Kediye dokun.',
    options: [_kedi, _kopek, _fil],
    correctOptionId: 'kedi',
  ),
  Question(
    id: 'a2',
    section: GameSection.animals,
    questionText: 'Köpeği bul',
    options: [_tavsan, _kopek, _aslan],
    correctOptionId: 'kopek',
  ),
  Question(
    id: 'a3',
    section: GameSection.animals,
    questionText: 'Aslanı bul',
    options: [_aslan, _kedi, _tavsan],
    correctOptionId: 'aslan',
  ),
  Question(
    id: 'a4',
    section: GameSection.animals,
    questionText: 'Fili bul',
    options: [_kopek, _fil, _aslan],
    correctOptionId: 'fil',
  ),
  Question(
    id: 'a5',
    section: GameSection.animals,
    questionText: 'Tavşanı bul',
    options: [_tavsan, _kedi],
    correctOptionId: 'tavsan',
  ),
  Question(
    id: 'a6',
    section: GameSection.animals,
    questionText: 'İneği bul',
    audioText: 'Möö! İneğe dokun.',
    options: [_at, _inek, _ordek],
    correctOptionId: 'inek',
  ),
  Question(
    id: 'a7',
    section: GameSection.animals,
    questionText: 'Ördeği bul',
    audioText: 'Vak vak! Ördeğe dokun.',
    options: [_balik, _kedi, _ordek, _maymun],
    correctOptionId: 'ordek',
  ),
  Question(
    id: 'a8',
    section: GameSection.animals,
    questionText: 'Balığı bul',
    options: [_fil, _balik],
    correctOptionId: 'balik',
  ),
  Question(
    id: 'a9',
    section: GameSection.animals,
    questionText: 'Maymunu bul',
    options: [_maymun, _aslan, _tavsan],
    correctOptionId: 'maymun',
  ),
  Question(
    id: 'a10',
    section: GameSection.animals,
    questionText: 'Atı bul',
    options: [_inek, _kopek, _ordek, _at],
    correctOptionId: 'at',
  ),

  // --- Bölüm 3: Basit nesneler ---
  Question(
    id: 'o1',
    section: GameSection.objects,
    questionText: 'Topu bul',
    options: [_top, _araba, _kitap],
    correctOptionId: 'top',
  ),
  Question(
    id: 'o2',
    section: GameSection.objects,
    questionText: 'Arabayı bul',
    options: [_balon, _araba, _top],
    correctOptionId: 'araba',
  ),
  Question(
    id: 'o3',
    section: GameSection.objects,
    questionText: 'Balonu bul',
    options: [_kitap, _top, _balon],
    correctOptionId: 'balon',
  ),
  Question(
    id: 'o4',
    section: GameSection.objects,
    questionText: 'Kitabı bul',
    options: [_araba, _kitap, _balon],
    correctOptionId: 'kitap',
  ),
  Question(
    id: 'o5',
    section: GameSection.objects,
    questionText: 'Uçağı bul',
    options: [_top, _ucak],
    correctOptionId: 'ucak',
  ),
  Question(
    id: 'o6',
    section: GameSection.objects,
    questionText: 'Şemsiyeyi bul',
    options: [_kitap, _semsiye, _araba],
    correctOptionId: 'semsiye',
  ),
  Question(
    id: 'o7',
    section: GameSection.objects,
    questionText: 'Oyuncak ayıyı bul',
    options: [_balon, _top, _ayicik, _saat],
    correctOptionId: 'ayicik',
  ),
  Question(
    id: 'o8',
    section: GameSection.objects,
    questionText: 'Bisikleti bul',
    options: [_bisiklet, _kalem],
    correctOptionId: 'bisiklet',
  ),
  Question(
    id: 'o9',
    section: GameSection.objects,
    questionText: 'Saati bul',
    options: [_kalem, _saat, _semsiye],
    correctOptionId: 'saat',
  ),
  Question(
    id: 'o10',
    section: GameSection.objects,
    // Bölümün son ve en zor sorusu: dört taşıt arasından seçmek.
    questionText: 'Treni bul',
    options: [_araba, _ucak, _tren, _bisiklet],
    correctOptionId: 'tren',
  ),
];

/// Belirli bir bölümün sorularını döndürür.
///
/// Filtreleme burada, provider'da değil: "hangi soru hangi bölüme ait"
/// verinin kendi bilgisi. Provider'ın işi oyunu yönetmek.
List<Question> questionsOf(GameSection section) =>
    allQuestions.where((q) => q.section == section).toList();
