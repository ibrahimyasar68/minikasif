import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

/// Ayarlar: ses, tema, ilerleme ve uygulama hakkında bilgi.
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
            const SizedBox(height: 24),
            const _Baslik('Hakkında'),
            const _Hakkinda(),
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

/// Ebeveyn için: oyun ne, veriler nerede, kime ulaşılır.
class _Hakkinda extends StatelessWidget {
  const _Hakkinda();

  @override
  Widget build(BuildContext context) {
    final renk = AppColors.of(context);
    final aciklama = TextStyle(fontSize: 16, height: 1.4, color: renk.text);

    return Card(
      color: renk.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔍', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: renk.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '0–4 yaş çocuklar için dinle, bak ve dokun oyunu. Çocuk sesli '
              'komutu dinler, doğru resme dokunur; renkleri, meyveleri, '
              'hayvanları ve nesneleri oynayarak tanır.',
              style: aciklama,
            ),
            const SizedBox(height: 12),
            // Gizlilik politikasıyla (docs/gizlilik_politikasi.md) aynı
            // şeyleri söylemeli. Politika değişirse burası da değişir.
            Text(
              'İnternet gerekmez, reklam yoktur, hiçbir kişisel veri '
              'toplanmaz. Ayarlar ve yıldızlar yalnızca bu cihazda saklanır.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: renk.textMuted,
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.mail_outline_rounded, color: renk.primary),
                const SizedBox(width: 12),
                // SelectableText: basılı tutunca kopyalanabilir. Dokununca
                // e-posta uygulamasını açmak için url_launcher paketi
                // gerekirdi; şimdilik kopyalamak yeterli.
                Expanded(
                  child: SelectableText(
                    contactEmail,
                    style: TextStyle(fontSize: 16, color: renk.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _EtiketRozeti(developerName)),
          ],
        ),
      ),
    );
  }
}

/// İkondaki "IY Labs" etiketinin uygulama içi karşılığı: yuvarlak köşeli
/// küçük bir rozet.
class _EtiketRozeti extends StatelessWidget {
  const _EtiketRozeti(this.metin);
  final String metin;

  @override
  Widget build(BuildContext context) {
    final renk = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: renk.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: renk.onPrimary,
        ),
      ),
    );
  }
}
