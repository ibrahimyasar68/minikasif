import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../models/game_section.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'game_page.dart';
import '../widgets/parent_gate_button.dart';
import 'settings_page.dart';

/// Karşılama + bölüm seçim ekranı.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.select: provider'ın SADECE bu tek değerini dinle.
    // context.watch tüm provider'ı dinlerdi. Oyun sırasında ana sayfa
    // arkada (sayfa yığınında) duruyor; her notifyListeners() onu da
    // boşuna yeniden çizerdi. select, değer değişmedikçe rebuild etmez.
    final turkceSesVar = context.select<GameProvider, bool?>(
      (oyun) => oyun.turkceSesVar,
    );
    final sesAcik = context.select<SettingsProvider, bool>((a) => a.sesAcik);
    final renk = AppColors.of(context);

    return Scaffold(
      backgroundColor: renk.background,
      body: SafeArea(
        // Stack: ayar simgesini içeriğin ÜSTÜNE bindiriyoruz; içerik
        // yerinden oynamasın (bölüm butonları kaydırmadan görünmeli).
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                // Küçük ekranlarda 3 bölüm kartı sığmayabilir.
                // Taşma hatası yerine kaydırma.
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sadece Türkçe ses KESİN yoksa (false). null = kontrol sürüyor.
                    // Ses kapalıysa uyarı anlamsız: ebeveyn sessizliği seçmiş.
                    if (sesAcik && turkceSesVar == false)
                      const _TurkceSesUyarisi(),
                    const Text('🔍', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 8),
                    Text(
                      'Mini Keşif',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: renk.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // GameSection.values enum'un tüm değerlerini verir.
                    // Yeni bir bölüm eklersek bu ekran kendiliğinden günceller;
                    // burada elle liste tutmuyoruz.
                    for (final section in GameSection.values) ...[
                      _SectionButton(section: section),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            // Ayarlar: ebeveyn için, köşede. 2 saniye basılı tutarak açılır;
            // çocuğun yanlışlıkla girmesini önler (ebeveyn kilidi).
            Positioned(
              top: 4,
              right: 4,
              child: ParentGateButton(
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Türkçe ses motoru bulunamadığında ebeveyne gösterilen uyarı.
///
/// Bu bant ÇOCUK için değil, ebeveyn için: ne olduğunu ve ne yapması
/// gerektiğini söylüyor. Kehribar renk: bir arıza değil, bir ayar eksik.
class _TurkceSesUyarisi extends StatelessWidget {
  const _TurkceSesUyarisi();

  @override
  Widget build(BuildContext context) {
    final renk = AppColors.of(context);
    return Container(
      width: 300, // sağ üstteki ayar simgesiyle çakışmasın
      // SIKI tutuluyor: bant uzunken "Nesneler" butonu ekranın altına
      // taşıyordu ve çocuğun kaydırması gerekiyordu (emülatörde görüldü).
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        color: renk.warningSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_off_rounded, color: renk.warning, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Türkçe ses bulunamadı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: renk.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sorular sesli okunmuyor. Ayarlar\'da "Metin okuma" bölümünden '
            'Google motorunu seçip Türkçe sesi indirin.',
            style: TextStyle(fontSize: 15, color: renk.text),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              // Ses paketi yüklendikten sonra uygulamayı kapatmadan
              // yeniden kontrol. Türkçe bulunursa bant kendiliğinden kalkar.
              onPressed: () => context.read<GameProvider>().sesiKontrolEt(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar kontrol et'),
              style: TextButton.styleFrom(foregroundColor: renk.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir bölüm butonu.
class _SectionButton extends StatelessWidget {
  final GameSection section;

  const _SectionButton({required this.section});

  @override
  Widget build(BuildContext context) {
    final renk = AppColors.of(context);
    return SizedBox(
      width: 300,
      height: 110,
      child: ElevatedButton(
        onPressed: () {
          // Önce bölümü başlat (durumu sıfırlar), sonra ekranı aç.
          context.read<GameProvider>().startSection(section);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GamePage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: renk.surface,
          foregroundColor: renk.primaryDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(section.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(width: 20),
            Flexible(
              child: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
