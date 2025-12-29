import 'package:flutter/material.dart';
import '../models/quick_message.dart';

class QuickMessageSettings extends StatefulWidget {
  const QuickMessageSettings({super.key});

  @override
  State<QuickMessageSettings> createState() => _QuickMessageSettingsState();
}

class _QuickMessageSettingsState extends State<QuickMessageSettings> {
  // Varsayılan mesaj listesi
  List<QuickMessage> messages = [
    QuickMessage(
      id: "1",
      message: "5 Dakika Geliyorum",
      isDefault: true,
    ),
    QuickMessage(
      id: "2",
      message: "Aracın Yanındayım",
      isDefault: true,
    ),
    QuickMessage(
      id: "3",
      message: "Acil Durum - Aşağıdan Ulaşın",
      isDefault: true,
    ),
    QuickMessage(
      id: "4",
      message: "Aracı Çekiyorum",
      isDefault: true,
    ),
  ];

  final TextEditingController customMessageController = TextEditingController();

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
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Başlık
                  Text(
                    "Hızlı Mesaj Ayarları",
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

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var msg in messages) _buildMessageTile(msg),
                          const SizedBox(height: 20),

                          // Yeni mesaj ekleme alanı
                          _buildAddNewMessage(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Glass Tile - Mesaj Elemanı
  Widget _buildMessageTile(QuickMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0AEFFF).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              msg.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),

          // Aktif/Pasif Switch
          Switch(
            value: msg.isActive,
            activeColor: const Color(0xFF0AEFFF),
            onChanged: (val) {
              setState(() {
                msg.isActive = val;
              });
            },
          ),

          if (!msg.isDefault)
            GestureDetector(
              onTap: () {
                setState(() {
                  messages.remove(msg);
                });
              },
              child: const Icon(
                Icons.delete,
                color: Colors.redAccent,
                size: 26,
              ),
            )
        ],
      ),
    );
  }

  // Yeni mesaj ekleme kutusu
  Widget _buildAddNewMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0AEFFF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: customMessageController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Yeni Hızlı Mesaj",
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0AEFFF)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF0072FF)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (customMessageController.text.isEmpty) return;

              setState(() {
                messages.add(
                  QuickMessage(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    message: customMessageController.text,
                    isDefault: false,
                  ),
                );
              });

              customMessageController.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0AEFFF),
                    Color(0xFF0072FF),
                  ],
                ),
              ),
              child: const Text(
                "Mesaj Ekle",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
