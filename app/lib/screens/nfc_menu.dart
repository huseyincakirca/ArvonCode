import 'package:flutter/material.dart';
import 'owner_dashboard.dart';
// import 'package:arvoncode_app/models/send_message.dart';
// import 'package:arvoncode_app/services/message_service.dart';
import 'package:arvoncode_app/services/quick_message_service.dart';

class NfcMenuScreen extends StatelessWidget {
  const NfcMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan premium gradient
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

          // Sayfa içeriği
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Küçük logo
                  SizedBox(
                    width: 120,
                    child: Image.asset(
                      'assets/logos/arvoncode_blue.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    "Araç Sahibine Mesaj Gönder",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0AEFFF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF0AEFFF).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Butonlar
                  _buildMenuButton(
                    title: "Konum Gönder",
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    title: "5 Dakika Geliyorum",
                    onTap: () async {
                      const String vehicleUuid = "TEST123456";
                      // Şimdilik sabit, sonra QR/NFC’den gelecek

                      final messenger = ScaffoldMessenger.of(context);

                      bool ok = await QuickMessageService.sendQuickMessage(
                        vehicleUuid: vehicleUuid,
                        quickMessageId: 1, // "5 Dakika Geliyorum"
                      );

                      if (!context.mounted) return;

                      if (ok) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Mesaj Gönderildi")),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Mesaj Gönderilemedi")),
                        );
                      }
                    },
                  ),
                  _buildMenuButton(
                    title: "Aracın Yanındayım",
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    title: "Acil Durum – İrtibat",
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    title: "Aracı Çektim / Bıraktım",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const OwnerDashboard()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Neon Mavi Buton Tasarımı
  Widget _buildMenuButton({required String title, required Function onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0AEFFF),
                Color(0xFF0072FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0AEFFF).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
