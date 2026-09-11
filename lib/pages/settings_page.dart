import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

/// Ayarlar: ses, tema ve ilerleme.
///
/// Bu sayfa ebeveyn için. Çocuk için ekran büyük emoji ve az yazı ile
/// kurulu; burada ise açıklayıcı metinler var.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// Silme geri alınamaz: önce sor.
  Future<void> _sifirlamayiSor(BuildContext context) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlerleme sıfırlansın mı?'),
        content: const Text('Bütün bölümlerin yıldızları silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    // await sonrası: bu sayfa bu arada kapanmış olabilir.
    if (onay != true || !context.mounted) return;
    context.read<ProgressProvider>().sifirla();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('İlerleme sıfırlandı')));
  }

  @override
  Widget build(BuildContext context) {
    final ayarlar = context.watch<SettingsProvider>();
    final ilerlemeBos = context.select<ProgressProvider, bool>((p) => p.bosMu);
    final renk = AppColors.of(context);

    return Scaffold(
      backgroundColor: renk.background,
      appBar: AppBar(
        backgroundColor: renk.primary,
        foregroundColor: renk.onPrimary,
        title: const Text('Ayarlar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Baslik('Ses'),
            Card(
              color: renk.surface,
              child: SwitchListTile(
                secondary: Icon(
                  ayarlar.sesAcik
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: renk.primary,
                  size: 32,
                ),
                title: Text(
                  'Sesli okuma',
                  style: TextStyle(fontSize: 20, color: renk.text),
                ),
                subtitle: Text(
                  ayarlar.sesAcik
                      ? 'Sorular ve geri bildirimler sesli okunur'
                      : 'Uygulama sessiz çalışır',
                  style: TextStyle(color: renk.textMuted),
                ),
                value: ayarlar.sesAcik,
                onChanged: (acik) {
                  context.read<SettingsProvider>().sesiAyarla(acik);
                  // Kapatınca o an süren bir konuşma varsa hemen kes.
                  if (!acik) context.read<GameProvider>().leave();
                },
              ),
            ),
            const SizedBox(height: 24),
            const _Baslik('Tema'),
            Card(
              color: renk.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                // SegmentedButton: birden fazla seçenekten tam olarak BİRİ
                // seçili. Üç tema için ideal; radyo düğmelerinden daha kompakt.
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Açık'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Koyu'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Sistem'),
                      icon: Icon(Icons.brightness_auto_rounded),
                    ),
                  ],
                  selected: {ayarlar.temaModu},
                  onSelectionChanged: (secim) => context
                      .read<SettingsProvider>()
                      .temayiAyarla(secim.first),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                '"Sistem" seçiliyken telefonun açık/koyu ayarına uyulur.',
                style: TextStyle(color: renk.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            const _Baslik('İlerleme'),
            Card(
              color: renk.surface,
              child: ListTile(
                leading: Icon(
                  Icons.restart_alt_rounded,
                  color: ilerlemeBos ? renk.textMuted : renk.primary,
                  size: 32,
                ),
                title: Text(
                  'İlerlemeyi sıfırla',
                  style: TextStyle(fontSize: 20, color: renk.text),
                ),
                subtitle: Text(
                  ilerlemeBos
                      ? 'Henüz kazanılmış yıldız yok'
                      : 'Bütün bölümlerin yıldızları silinir',
                  style: TextStyle(color: renk.textMuted),
                ),
                // Silinecek bir şey yoksa buton pasif.
                enabled: !ilerlemeBos,
                onTap: () => _sifirlamayiSor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  const _Baslik(this.metin);
  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Text(
      metin,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.of(context).primaryDark,
      ),
    ),
  );
}
