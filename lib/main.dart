import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'providers/game_provider.dart';
import 'services/audio_service.dart';

void main() {
  runApp(const MiniKesifApp());
}

class MiniKesifApp extends StatelessWidget {
  const MiniKesifApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider, GameProvider'ı widget ağacına yerleştirir.
    //
    // MaterialApp'in ÜSTÜNE koyduk. Neden?
    // Provider'a sadece ALTINDAKİ widget'lar erişebilir.
    // Buraya koyunca tüm sayfalar (HomePage, GamePage ve ileride
    // ResultPage) aynı oyun durumuna ulaşabilir.
    return ChangeNotifierProvider(
      // create: provider'ı YALNIZCA BİR KEZ oluşturur.
      // Ekran her yeniden çizildiğinde yeni bir oyun başlamaz.
      // GERÇEK ses servisi SADECE burada bağlanıyor.
      // Uygulamanın geri kalanı sadece AudioService arayüzünü tanıyor.
      // Yarın TTS yerine .mp3 kullanmak istersek değişecek tek yer burası.
      create: (context) => GameProvider(audio: TtsAudioService()),
      child: MaterialApp(
        title: 'MiniKesif',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        home: const HomePage(),
      ),
    );
  }
}
