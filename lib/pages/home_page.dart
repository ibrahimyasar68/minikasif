import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_section.dart';
import '../providers/game_provider.dart';
import 'game_page.dart';

/// Karşılama + bölüm seçim ekranı.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Küçük ekranlarda 3 bölüm kartı sığmayabilir.
            // Taşma hatası yerine kaydırma.
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 8),
                const Text(
                  'Mini Keşif',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
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
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFE65100),
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
