import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_info.dart';
import 'pages/home_page.dart';
import 'providers/game_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'services/audio_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // runApp'ten önce eklenti kullanacağımız için Flutter'ı hazırla.
  WidgetsFlutterBinding.ensureInitialized();
  // Ayarları runApp'ten ÖNCE yükle. Yoksa uygulama bir an sistem temasıyla
  // açılıp sonra kayıtlı temaya geçer: ekran yanıp söner.
  final prefs = await SharedPreferences.getInstance();
  runApp(MiniKasifApp(prefs: prefs));
}

class MiniKasifApp extends StatelessWidget {
  const MiniKasifApp({super.key, this.audio, this.prefs});

  /// Ses servisi. Verilmezse gerçek TTS kullanılır (uygulamanın kendisi).
  ///
  /// Neden dışarıdan verilebiliyor? Testler için.
  /// Test ortamında TTS eklentisinin "konuşma bitti" haberi hiç gelmez;
  /// otomatik geçiş her seferinde 4 saniyelik güvenlik sınırına düşer.
  /// Testler buraya SilentAudioService geçerek gerçek eklentiye hiç
  /// dokunmuyor - AudioService arayüzünün var olma sebebi tam olarak bu.
  final AudioService? audio;

  /// Kalıcı ayar deposu. Verilmezse ayarlar sadece bellekte (testler).
  final SharedPreferences? prefs;

  @override
  Widget build(BuildContext context) {
    // MultiProvider: birden fazla provider'ı iç içe yazmak yerine liste.
    // Sıra önemli: GameProvider SettingsProvider'ı okuyor, o yüzden altta.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs: prefs)),
        ChangeNotifierProvider(create: (_) => ProgressProvider(prefs: prefs)),
        ChangeNotifierProvider(
          // Oyun "konuş" der; ToggleableAudioService ses ayarı kapalıysa
          // yutar. context.read çağrısı her konuşmada yapılır: ayar
          // değişince hemen etkili olur.
          create: (context) => GameProvider(
            audio: ToggleableAudioService(
              audio ?? TtsAudioService(),
              acikMi: () => context.read<SettingsProvider>().sesAcik,
            ),
          )..sesiKontrolEt(),
        ),
      ],
      // Selector: Consumer'ın seçici hâli. Provider'ın SADECE tema değerini
      // dinler; ses ayarı değişince MaterialApp boşuna yeniden kurulmaz.
      child: Selector<SettingsProvider, ThemeMode>(
        selector: (_, ayarlar) => ayarlar.temaModu,
        builder: (context, temaModu, _) => MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: acikTema,
          darkTheme: koyuTema,
          themeMode: temaModu,
          home: const HomePage(),
        ),
      ),
    );
  }
}
