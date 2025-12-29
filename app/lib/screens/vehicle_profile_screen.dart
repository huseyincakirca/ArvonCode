import 'package:flutter/material.dart';
import '../services/public_service.dart';
import '../config/api_config.dart';
import '../services/quick_message_service.dart';
import '../services/location_service.dart';
import '../services/device_location_service.dart';
import 'send_custom_message_screen.dart';

class VehicleProfileScreen extends StatefulWidget {
  final String vehicleUuid;

  const VehicleProfileScreen({super.key, required this.vehicleUuid});

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen> {
  late Future<Map<String, dynamic>> future;
  final Set<int> _sendingMessageIds = {};
  final Map<int, DateTime> _lastSentAt = {};
  static const Duration _cooldown = Duration(seconds: 2);
  DateTime? _lastLocationSentAt;

  // 2. State içine eklenecek değişkenler
  bool _isLocationSending = false;

  @override
  void initState() {
    super.initState();
    future = PublicService(baseUrl: ApiConfig.baseUrl)
        .fetchVehicleProfile(widget.vehicleUuid);
  }

  // 3. Konum Gönderme Fonksiyonu
  Future<void> _sendCurrentLocation() async {
    setState(() => _isLocationSending = true);

    try {
      final position = await DeviceLocationService.getCurrentLocation();

      final result = await LocationService.saveLocation(
        vehicleUuid: widget.vehicleUuid,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
        source: 'guest_qr',
      );

      if (!mounted) return;

      if (result['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konumunuz araç sahibine iletildi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();
      String uiMessage = 'Konum gönderilemedi.';

      if (msg.contains('permission')) {
        uiMessage = 'Konum izni yok. İzin verip tekrar dene.';
      } else if (msg.contains('disabled') || msg.contains('location service')) {
        uiMessage = 'Konum kapalı. Telefonun konumunu açıp tekrar dene.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocationSending = false);
      }
    }
  }

  // ----------
  Future<void> _sendQuickMessage(Map qm) async {
    final int quickMessageId =
        qm['id'] is int ? qm['id'] : int.parse(qm['id'].toString());

    // 1) Concurrent kilit
    if (_sendingMessageIds.contains(quickMessageId)) return;

    // 2) Cooldown kilit
    final last = _lastSentAt[quickMessageId];
    if (last != null && DateTime.now().difference(last) < _cooldown) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yavaş! 2 saniye bekle.')),
      );
      return;
    }

    setState(() {
      _sendingMessageIds.add(quickMessageId);
      _lastSentAt[quickMessageId] = DateTime.now();
    });

    try {
      final ok = await QuickMessageService.sendQuickMessage(
        vehicleUuid: widget.vehicleUuid,
        quickMessageId: quickMessageId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Mesaj gönderildi ✅' : 'Gönderim başarısız ❌'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (!mounted) return;

      // Spinner hemen gitmesin diye min 400ms tut (gözle görünür)
      await Future.delayed(const Duration(milliseconds: 400));

      setState(() {
        _sendingMessageIds.remove(quickMessageId);
      });
    }
  }

  Future<void> _onSendLocationPressed() async {
    if (_isLocationSending) return;

    final now = DateTime.now();
    if (_lastLocationSentAt != null &&
        now.difference(_lastLocationSentAt!) < const Duration(seconds: 10)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum zaten gönderildi. 10 sn bekle.')),
      );
      return;
    }

    _lastLocationSentAt = now;
    await _sendCurrentLocation();
  }

  // ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Profile')),
      // SingleChildScrollView ekledik ki kart en altta düzgün dursun ve taşma yapmasın
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(50.0),
                child: CircularProgressIndicator(),
              ));
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Bu ArvonCode geçersiz veya sisteme kayıtlı değil.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final String plate = data['plate'] ?? '-';
            final String brand = data['brand'] ?? '-';
            final String model = data['model'] ?? '-';
            final String color = data['color'] ?? '-';
            final List quickMessages = data['quick_messages'] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Butonları yayar
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plate,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$brand $model • $color'),
                      const SizedBox(height: 24),
                      const Text('Hızlı Mesajlar',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...quickMessages.map((qm) {
                        final int qmId = qm['id'] is int
                            ? qm['id']
                            : int.parse(qm['id'].toString());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            onPressed: _sendingMessageIds.contains(qmId)
                                ? null
                                : () => _sendQuickMessage(qm),
                            child: _sendingMessageIds.contains(qmId)
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(qm['text']),
                          ),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            final sent = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SendCustomMessageScreen(
                                  vehicleUuid: widget.vehicleUuid,
                                ),
                              ),
                            );
                            if (sent == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Mesajınız araç sahibine iletildi.')),
                              );
                            }

                            // İstersen burada sent==true olunca UI’da küçük feedback yaparsın.
                            // Şart değil.
                          },
                          child: const Text('Mesaj Yaz'),
                        ),
                      ),
                    ],
                  ),
                ),
                // KRİTİK DÜZELTME: Kartı burada çağırıyoruz!
                const SizedBox(height: 20),
                _buildLocationCard(),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  // 4. UI Altına eklenecek Widget (ListView sonuna veya Column içine)
  Widget _buildLocationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            const Text(
              "Aracın Yanında mısınız?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "Konumunuzu göndererek araç sahibinin aracı daha kolay bulmasını sağlayabilirsiniz.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _isLocationSending ? null : _onSendLocationPressed,
              child: _isLocationSending
                  ? const CircularProgressIndicator()
                  : const Text("Konumumu Bildir"),
            ),
          ],
        ),
      ),
    );
  }
}
