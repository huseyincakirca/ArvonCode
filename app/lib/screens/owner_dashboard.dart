import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/location_service.dart';
import '../services/message_service.dart';
import 'owner/messages_page.dart';
import 'owner/locations_page.dart';
import 'settings_screen.dart';

class OwnerDashboard extends StatefulWidget {
  final String? ownerToken;

  const OwnerDashboard({super.key, this.ownerToken});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  bool _loadingLocation = true;
  Map<String, dynamic>? _latestLocation;
  String? _locationMessage;
  bool _loadingMessage = true;
  Message? _latestMessage;
  String? _messageStatus;

  @override
  void initState() {
    super.initState();
    _fetchLatestMessage();
    _fetchLatestLocation();
  }

  Future<void> _fetchLatestMessage() async {
    final token = widget.ownerToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _messageStatus = 'Token bulunamadı';
        _loadingMessage = false;
      });
      return;
    }

    try {
      final latest = await MessageService().fetchLatestMessage(token: token);

      if (!mounted) return;

      setState(() {
        _latestMessage = latest;
        _messageStatus = latest == null ? 'Henüz mesaj yok' : null;
        _loadingMessage = false;
      });
    } catch (e) {
      debugPrint('LAST MESSAGE ERROR: $e');
      if (!mounted) return;

      setState(() {
        _messageStatus = 'Mesajlar alınamadı';
        _loadingMessage = false;
      });
    }
  }

  Future<void> _fetchLatestLocation() async {
    final token = widget.ownerToken?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _locationMessage = 'Token bulunamadı';
        _loadingLocation = false;
      });
      return;
    }

    try {
      final locations = await LocationService.fetchOwnerLocations(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _latestLocation = locations.isNotEmpty ? locations.first : null;
        _locationMessage =
            locations.isEmpty ? 'Henüz konum kaydı yok' : null;
        _loadingLocation = false;
      });
    } catch (e) {
      debugPrint('LAST LOCATION ERROR: $e');
      if (!mounted) return;

      setState(() {
        _locationMessage = 'Konumlar alınamadı';
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan gradient
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  // Logo ve başlık
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Image.asset(
                            'assets/logos/arvoncode_blue.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Araç Kontrol Paneli",
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // En Son Mesaj Paneli (Glass Card)
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Son Mesaj",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0AEFFF),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLastMessageContent(),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _blueButton("Cevapla"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Alt Kartlar
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Son Konum",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0AEFFF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildLastLocationContent(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                if (widget.ownerToken == null ||
                                    widget.ownerToken!.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Token bulunamadı')),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesPage(
                                      token: widget.ownerToken!.trim(),
                                    ),
                                  ),
                                );
                              },
                              child: _blueButton("Mesajlarım", small: true),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                if (widget.ownerToken == null ||
                                    widget.ownerToken!.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Token bulunamadı')),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationsPage(
                                      token: widget.ownerToken!.trim(),
                                    ),
                                  ),
                                );
                              },
                              child: _blueButton("Konumlarım", small: true),
                            ),
                          ),

                          const SizedBox(height: 12),

                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ArvonCode Kartım",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0AEFFF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Image.asset(
                                    'assets/logos/arvoncode_blue.png',
                                    width: 120,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    "Kart ID: ACX-4921",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _blueButton("Paylaş", small: true),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _blueButton("Yeni Kart Ekle",
                                          small: true),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // AYARLAR BUTONU (BURASI YENİ)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                              child: _blueButton("Ayarlar", small: true),
                            ),
                          ),
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

  Widget _buildLastMessageContent() {
    if (_loadingMessage) {
      return const Center(child: CircularProgressIndicator());
    }

    final status = _messageStatus;
    if (status != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    final content = _latestMessage?.content ?? '';
    final createdAt = _latestMessage?.createdAt?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Mesaj', content),
        const SizedBox(height: 6),
        _infoRow('created_at', createdAt),
      ],
    );
  }

  Widget _buildLastLocationContent() {
    if (_loadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    final message = _locationMessage;
    if (message != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    final latitude = _latestLocation?['lat']?.toString() ?? '';
    final longitude = _latestLocation?['lng']?.toString() ?? '';
    final createdAt = _latestLocation?['created_at']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Latitude', latitude),
        const SizedBox(height: 6),
        _infoRow('Longitude', longitude),
        const SizedBox(height: 6),
        _infoRow('created_at', createdAt),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Glassmorphism panel widget
  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: const Color(0xFF0AEFFF).withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0AEFFF).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  // Neon Blue Button
  Widget _blueButton(String text, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 20,
        vertical: small ? 10 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0AEFFF),
            Color(0xFF0072FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0AEFFF).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: small ? 14 : 16,
        ),
      ),
    );
  }
}
