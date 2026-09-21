import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Basılı tutarak açılan buton: ebeveyn kilidi.
///
/// Çocuk ekrandaki her şeye dokunur ama iki saniye BİLEREK basılı tutmak
/// bir yetişkin davranışıdır. Basılı tutarken simgenin etrafında bir halka
/// dolar; dolunca [onOpen] çağrılır. Kısa dokunuşta ipucu gösterilir.
///
/// Neden StatefulWidget ve AnimationController?
/// Şimdiye kadarki animasyonlar "implicit"ti: değeri değiştir, Flutter
/// geçişi üretsin. Burada halkanın dolmasını PARMAĞIN ekranda kalma süresi
/// yönetiyor: basınca ileri, bırakınca geri. Bunu elle kontrol etmek için
/// bir AnimationController gerekiyor; o da bir State'e ait olmalı.
class ParentGateButton extends StatefulWidget {
  const ParentGateButton({
    super.key,
    required this.onOpen,
    this.holdDuration = const Duration(seconds: 2),
  });

  /// Halka dolunca çağrılır.
  final VoidCallback onOpen;

  /// Ne kadar basılı tutulmalı.
  final Duration holdDuration;

  /// Butonun kenar uzunluğu.
  static const boyut = 56.0;

  /// Ekran köşesinden ne kadar içeride duruyor (bkz. HomePage).
  static const kenarBoslugu = 4.0;

  /// Köşede kapladığı toplam alan. Yanına gelecek içerik bu kadar
  /// boşluk bırakmalı ki simgenin altına girmesin.
  static const alan = boyut + 2 * kenarBoslugu;

  @override
  State<ParentGateButton> createState() => _ParentGateButtonState();
}

// SingleTickerProviderStateMixin: AnimationController'a ekran yenilemesine
// bağlı bir "tik" kaynağı (vsync) verir. Sayfa görünmezken animasyon boşuna
// çalışmaz, pil harcamaz.
class _ParentGateButtonState extends State<ParentGateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dolum = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_durumDegisti);

  /// Parmak şu an basılı mı (ve kilit henüz açılmadı mı)?
  ///
  /// Neden ayrı bir değişken? İlk hâlinde "dolum değeri 0 ise açılmıştır"
  /// diye tahmin ediyorduk. Ama çok hızlı bir dokunuşta animasyon daha ilk
  /// karesini çizmemiş olabiliyor: değer yine 0. O zaman halka geri
  /// boşaltılmıyor, kendi başına dolup 2 sn sonra ayarları AÇIYORDU.
  /// Durumu açıkça tutmak bu belirsizliği ortadan kaldırıyor.
  bool _basili = false;

  void _durumDegisti(AnimationStatus durum) {
    if (durum != AnimationStatus.completed) return;
    _basili = false;
    // Halkayı sıfırla: sayfadan geri dönülünce boş halka görünsün.
    _dolum.value = 0;
    widget.onOpen();
  }

  void _basildi() {
    _basili = true;
    _dolum.forward();
  }

  void _birakildi() {
    // Kilit zaten açıldıysa parmağın kalkması bir şey ifade etmez.
    if (!_basili) return;
    _basili = false;
    _dolum.reverse(); // halka geri boşalsın
    _ipucuGoster();
  }

  void _iptal() {
    _basili = false;
    _dolum.reverse();
  }

  void _ipucuGoster() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Ayarlar için simgeyi 2 saniye basılı tutun'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    // Controller'ı kapatmazsak "Ticker kapatılmadı" hatası ve bellek sızıntısı.
    _dolum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renk = AppColors.of(context);

    // Semantics: ekran okuyucu (TalkBack) kullanan bir ebeveyn de açabilsin.
    // TalkBack'in "çift dokun ve basılı tut" hareketi onLongPress'i çağırır.
    return Semantics(
      button: true,
      label: 'Ayarlar',
      hint: 'Açmak için basılı tutun',
      onLongPress: widget.onOpen,
      excludeSemantics: true,
      // Listener: ham parmak olayları. GestureDetector'ın "dokunma" tanıyıcısı
      // ~100 ms bekleyip karar verir; burada basıldığı AN halka dolmaya
      // başlamalı.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _basildi(),
        onPointerUp: (_) => _birakildi(),
        onPointerCancel: (_) => _iptal(),
        child: SizedBox(
          width: ParentGateButton.boyut,
          height: ParentGateButton.boyut,
          // AnimatedBuilder: controller her tik attığında SADECE bu kısmı
          // yeniden çizer; ana sayfanın geri kalanı etkilenmez.
          child: AnimatedBuilder(
            animation: _dolum,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _dolum.value,
                    strokeWidth: 4,
                    color: renk.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Icon(Icons.settings_rounded, size: 30, color: renk.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
