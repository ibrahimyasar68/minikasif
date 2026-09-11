import 'package:flutter/material.dart';
import '../models/answer_option.dart';

/// Bir kartın ekrandaki görünüm durumu.
///
/// enum = sınırlı sayıda seçeneği olan bir tip.
/// bool kullanmak yetmezdi: iki bool (isCorrect, isWrong) olsaydı
/// "ikisi birden true" gibi ANLAMSIZ bir durum mümkün olurdu.
/// enum ile aynı anda sadece tek bir değer olabilir.
enum AnswerStatus { normal, correct, wrong }

/// Ekranda dokunulabilir TEK bir seçenek kartı.
///
/// ÖNEMLİ: Bu widget doğru cevabın ne olduğunu BİLMİYOR.
/// Sadece "sana normal/doğru/yanlış görün denildi" bilgisini alıyor.
/// Karar GamePage'e ait; burası sadece çiziyor.
class AnswerCard extends StatelessWidget {
  final AnswerOption option;

  /// Kartın nasıl görüneceği. Dışarıdan söyleniyor.
  final AnswerStatus status;

  /// Dokunulunca çağrılacak fonksiyon.
  /// null ise kart dokunulamaz olur (soru cevaplandıktan sonra).
  final VoidCallback? onTap;

  const AnswerCard({
    super.key,
    required this.option,
    required this.onTap,
    this.status = AnswerStatus.normal,
  });

  /// Duruma göre arka plan rengi.
  /// switch ifadesi enum'un TÜM değerlerini kapsamak zorunda,
  /// yoksa Dart derleme hatası verir. Yeni bir durum eklersek
  /// burayı güncellemeyi unutamayız.
  Color get _backgroundColor => switch (status) {
    AnswerStatus.normal => Colors.white,
    AnswerStatus.correct => const Color(0xFFC8E6C9), // yumuşak yeşil
    AnswerStatus.wrong => const Color(0xFFEEEEEE), // soluk gri
  };

  @override
  Widget build(BuildContext context) {
    // Yanlış kart soluklaşsın ama KAYBOLMASIN.
    // Çocuğu cezalandırmıyoruz, sadece "bu değil" diyoruz (CLAUDE.md md.18).
    final opacity = status == AnswerStatus.wrong ? 0.45 : 1.0;
    final isCorrect = status == AnswerStatus.correct;

    // AnimatedScale: doğru kart hafifçe büyür.
    //
    // "Implicit animation" denen yaklaşım: AnimationController yazmıyoruz,
    // sadece scale DEĞERİNİ değiştiriyoruz. Flutter aradaki geçişi
    // kendisi üretiyor. Basit durum geçişleri için doğru araç bu.
    return AnimatedScale(
      scale: isCorrect ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 260),
      // easeOutBack hafif bir "yaylanma" verir: başarı hissi.
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 220),
        child: SizedBox(
          width: 150,
          height: 150,
          child: Material(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(24),
            elevation: isCorrect ? 8 : 3,
            // Material renk ve yükseklik değişimini kendisi animasyonlar.
            // Ayrı bir AnimatedContainer'a gerek yok.
            animationDuration: const Duration(milliseconds: 260),
            child: InkWell(
              // onTap null ise InkWell dokunmayı yok sayar, dalga da çizmez.
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Center(
                    // FittedBox: içerik sığmazsa küçültür, taşmaz.
                    // Bu olmadan emoji + yazı bazı cihaz/font ayarlarında
                    // 150px'i aşıp "RenderFlex overflowed" hatası veriyordu.
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          // min: Column sadece içeriği kadar yer kaplasın.
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.emoji,
                              style: const TextStyle(fontSize: 72),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option.label,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Doğru kartın köşesinde onay rozeti.
                  // Stack çocukları üst üste bindirir; Positioned yerini belirler.
                  if (status == AnswerStatus.correct)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
