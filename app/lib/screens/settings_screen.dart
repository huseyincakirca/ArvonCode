import 'package:flutter/material.dart';
import 'quick_message_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF0F1A2C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Logo ve başlık
                    SizedBox(
                      width: 120,
                      child: Image.asset(
                        'assets/logos/arvoncode_blue.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Ayarlar & Profil",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0AEFFF),
                        shadows: [
                          Shadow(
                            color: const Color(0xFF0AEFFF).withOpacity(0.4),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Kullanıcı kartı (Glass)
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Kullanıcı Bilgileri",
                            style: TextStyle(
                              color: Color(0xFF0AEFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Ad: Hüseyin Çakırca",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Araç: Fiat Doblo 2005",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Plaka: 41 ABC 123",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Kart Yönetimi Paneli
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ArvonCode Kart Yönetimi",
                            style: TextStyle(
                              color: Color(0xFF0AEFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _settingsButton("Kayıtlı Kartlarım", () {}),
                          _settingsButton("Yeni Kart Ekle", () {}),
                          _settingsButton("Kartı Devre Dışı Bırak", () {}),
                          _settingsButton("QR / NFC Yenile", () {}),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Uygulama Ayarları Paneli
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Uygulama Ayarları",
                            style: TextStyle(
                              color: Color(0xFF0AEFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _settingsButton("Bildirim Ayarları", () {}),
                          _settingsButton("Konum Paylaşım Ayarları", () {}),
                          _settingsButton("Hızlı Mesaj Ayarları", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const QuickMessageSettings()),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Hesap Paneli
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hesap",
                            style: TextStyle(
                              color: Color(0xFF0AEFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _settingsButton("Destek", () {}),
                          _settingsButton("Hakkında", () {}),
                          _settingsButton("Çıkış Yap", () {}),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphism panel
  static Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: const Color(0xFF0AEFFF).withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0AEFFF).withOpacity(0.12),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  // Ayar buton stili
  Widget _settingsButton(String title, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
            color: const Color(0xFF0AEFFF).withOpacity(0.25),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
