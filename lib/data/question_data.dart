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

// Hayvanlar
const _kedi = AnswerOption(id: 'kedi', label: 'Kedi', emoji: '🐱');
const _kopek = AnswerOption(id: 'kopek', label: 'Köpek', emoji: '🐶');
const _aslan = AnswerOption(id: 'aslan', label: 'Aslan', emoji: '🦁');
const _fil = AnswerOption(id: 'fil', label: 'Fil', emoji: '🐘');
const _tavsan = AnswerOption(id: 'tavsan', label: 'Tavşan', emoji: '🐰');

// Nesneler
const _top = AnswerOption(id: 'top', label: 'Top', emoji: '⚽');
const _araba = AnswerOption(id: 'araba', label: 'Araba', emoji: '🚗');
const _balon = AnswerOption(id: 'balon', label: 'Balon', emoji: '🎈');
const _kitap = AnswerOption(id: 'kitap', label: 'Kitap', emoji: '📕');

/// Oyunun tüm soruları - her bölümden 4 tane.
///
/// Hâlâ 30 değil. Sistem 12 soruyla da, 30 soruyla da aynı şekilde
/// çalışıyor; soru eklemek beş dakikalık iş. Önce bölüm yapısının
/// doğru oturduğundan emin olalım.
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
];

/// Belirli bir bölümün sorularını döndürür.
///
/// Filtreleme burada, provider'da değil: "hangi soru hangi bölüme ait"
/// verinin kendi bilgisi. Provider'ın işi oyunu yönetmek.
List<Question> questionsOf(GameSection section) =>
    allQuestions.where((q) => q.section == section).toList();
