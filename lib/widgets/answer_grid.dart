import 'package:flutter/material.dart';
import '../models/answer_option.dart';
import 'answer_card.dart';

/// Seçenek kartlarını ekrana yerleştirir.
///
/// Neden Wrap değil?
/// Wrap "sığdığı kadar yan yana koy, kalanı alta at" der. 3 seçenekte
/// 2+1 gibi dengesiz bir dizilim çıkıyordu: üçüncü kart tek başına altta
/// kalıyor ve diğer ikisinden daha az önemliymiş gibi duruyordu.
///
/// Kural:
///   2-3 seçenek -> tek sıra (hepsi eşit görünür)
///   4 seçenek   -> 2x2 kare
///
/// Kart boyutu sabit değil: mevcut genişliğe sığacak şekilde hesaplanıyor.
/// Böylece dar ekranda taşma olmuyor, geniş ekranda gereksiz küçülmüyor.
class AnswerGrid extends StatelessWidget {
  final List<AnswerOption> options;

  /// Bir seçeneğin kartı hangi durumda görünmeli?
  final AnswerStatus Function(AnswerOption) statusOf;

  /// Dokunulunca ne olacak? null ise kartlar kilitli.
  final void Function(AnswerOption)? onTap;

  const AnswerGrid({
    super.key,
    required this.options,
    required this.statusOf,
    required this.onTap,
  });

  /// Kartlar arası boşluk.
  static const _bosluk = 16.0;

  /// En büyük kart boyutu. Bundan büyük olursa ekranda kaba durur.
  static const _enBuyuk = 150.0;

  /// 0-4 yaş için en küçük kabul edilebilir dokunma alanı.
  /// Material'ın 48px minimumunun çok üstünde tutuyoruz.
  static const _enKucuk = 96.0;

  @override
  Widget build(BuildContext context) {
    // 4 seçenek 2x2; diğerleri tek sıra.
    final sutun = options.length == 4 ? 2 : options.length;

    // LayoutBuilder mevcut genişliği verir; kart boyutunu ona göre
    // hesaplıyoruz. Sabit boyut yazsaydık dar ekranda taşardı.
    return LayoutBuilder(
      builder: (context, kisit) {
        final kullanilabilir = kisit.maxWidth - _bosluk * (sutun - 1);
        // floorToDouble: küsurat yüzünden toplam genişlik maxWidth'i
        // bir kıl payı aşıp kartlardan biri alt satıra düşmesin.
        final boyut = (kullanilabilir / sutun)
            .clamp(_enKucuk, _enBuyuk)
            .floorToDouble();

        // Genişliği sütun sayısına göre SABİTLİYORUZ.
        //
        // Wrap "sığdığı kadar yan yana koy" der. Geniş ekranda (tablet)
        // 4 kart tek sıraya sığıyor ve "4 seçenek -> 2x2" kuralı
        // bozuluyordu. Genişliği tam sutun kadar kart alacak şekilde
        // verince her ekranda aynı düzen çıkıyor.
        //
        // Çok dar ekranda bu genişlik maxWidth'i aşarsa SizedBox otomatik
        // olarak maxWidth'e kırpılır; Wrap o zaman alt satıra geçer.
        // Center şart: üst widget SIKI genişlik kısıtı verirse (örn. sabit
        // genişlikli bir kutu) SizedBox'ın genişliği yok sayılır ve zorla
        // üst genişliğe büyütülür. "Kısıtlar yukarıdan aşağı iner": bir
        // çocuk sıkı kısıttan küçük olamaz. Center çocuğuna GEVŞEK kısıt
        // verir, böylece SizedBox istediği genişlikte kalabilir.
        // heightFactor 1.0: yükseklik tam içerik kadar olsun, uzamasın.
        return Center(
          heightFactor: 1.0,
          child: SizedBox(
            width: sutun * boyut + (sutun - 1) * _bosluk,
            child: Wrap(
              spacing: _bosluk,
              runSpacing: _bosluk,
              alignment: WrapAlignment.center,
              children: [
                for (final option in options)
                  AnswerCard(
                    option: option,
                    size: boyut,
                    status: statusOf(option),
                    onTap: onTap == null ? null : () => onTap!(option),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
