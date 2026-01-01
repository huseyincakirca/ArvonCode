import 'package:flutter/material.dart';

import '../../services/device_location_service.dart';
import '../../services/parking_service.dart';
import '../../utils/date_formatter.dart';

class ParkingPage extends StatefulWidget {
  final String token;
  final String vehicleId;

  const ParkingPage({
    super.key,
    required this.token,
    required this.vehicleId,
  });

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  bool _loadingLatest = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  Map<String, dynamic>? _latestParking;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loadingLatest = true;
      _error = null;
    });

    try {
      final parking = await ParkingService.fetchLatestParking(
        token: widget.token,
        vehicleId: widget.vehicleId,
      );
      if (!mounted) return;
      setState(() {
        _latestParking = parking;
      });
    } on ParkingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLatest = false;
        });
      }
    }
  }

  Future<void> _saveParking() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final position = await DeviceLocationService.getCurrentLocation();
      await ParkingService.setParking(
        token: widget.token,
        vehicleId: widget.vehicleId,
        lat: position.latitude,
        lng: position.longitude,
      );
      await _loadLatest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Park konumu kaydedildi.')),
      );
    } on ParkingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyLocationError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteParking() async {
    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await ParkingService.deleteParking(
        token: widget.token,
        vehicleId: widget.vehicleId,
      );
      if (!mounted) return;
      setState(() {
        _latestParking = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Park kaydı silindi.')),
      );
    } on ParkingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  String _friendlyLocationError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('permission')) {
      return 'Konum izni verilmedi. İzin verip tekrar dene.';
    }
    if (msg.contains('disabled') || msg.contains('service')) {
      return 'Konum servisi kapalı. Açıp tekrar dene.';
    }
    return 'Konum alınamadı: $e';
  }

  String _friendlyError(ParkingApiException e) {
    if (e.statusCode == 403) {
      return 'Bu araç için yetkin yok (403).';
    }
    if (e.statusCode == 401) {
      return 'Oturum geçersiz (401). Tekrar giriş yap.';
    }
    if (e.statusCode == 422) {
      return 'Gönderilen bilgiler hatalı (422).';
    }
    return 'API hatası: ${e.message}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _loadingLatest ? null : _loadLatest,
                  child: _loadingLatest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Son Park'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _saveParking,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Konumu Kaydet'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _deleting ? null : _deleteParking,
                  child: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Parkı Sil'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loadingLatest
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLatestCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestCard() {
    if (_latestParking == null) {
      return const Center(child: Text('Kayıtlı park bilgisi yok'));
    }

    final lat = _latestParking?['lat']?.toString() ?? '-';
    final lng = _latestParking?['lng']?.toString() ?? '-';
    final parkedAtRaw = _latestParking?['parked_at']?.toString() ?? '';
    final createdAtRaw = _latestParking?['created_at']?.toString() ?? '';
    final latDouble = double.tryParse(lat);
    final lngDouble = double.tryParse(lng);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Park',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (latDouble != null && lngDouble != null)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 32),
                      Text('Lat: $latDouble, Lng: $lngDouble'),
                    ],
                  ),
                ),
              )
            else ...[
              Text('Lat: $lat'),
              Text('Lng: $lng'),
            ],
            Text('parked_at: ${DateFormatter.format(parkedAtRaw)}'),
            Text('created_at: ${DateFormatter.format(createdAtRaw)}'),
          ],
        ),
      ),
    );
  }
}
