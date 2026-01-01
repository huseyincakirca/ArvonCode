import 'package:flutter/material.dart';

import '../../services/parking_service.dart';
import '../../utils/date_formatter.dart';

class ParkingPage extends StatefulWidget {
  final String token;
  final String? initialVehicleId;

  const ParkingPage({
    super.key,
    required this.token,
    this.initialVehicleId,
  });

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  bool _loadingLatest = false;
  bool _submitting = false;
  bool _deleting = false;
  String? _error;
  Map<String, dynamic>? _latestParking;

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicleId != null &&
        widget.initialVehicleId!.trim().isNotEmpty) {
      _vehicleIdController.text = widget.initialVehicleId!.trim();
      _loadLatest();
    }
  }

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    final vehicleId = _vehicleIdController.text.trim();
    if (vehicleId.isEmpty) {
      setState(() {
        _error = 'Vehicle ID gerekli';
      });
      return;
    }

    setState(() {
      _loadingLatest = true;
      _error = null;
    });

    try {
      final parking = await ParkingService.fetchLatestParking(
        token: widget.token,
        vehicleId: vehicleId,
      );
      if (!mounted) return;
      setState(() {
        _latestParking = parking;
        _loadingLatest = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingLatest = false;
      });
    }
  }

  Future<void> _setParking() async {
    final vehicleId = _vehicleIdController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (vehicleId.isEmpty || lat == null || lng == null) {
      setState(() {
        _error = 'Vehicle ID, lat ve lng gerekli';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ParkingService.setParking(
        token: widget.token,
        vehicleId: vehicleId,
        lat: lat,
        lng: lng,
      );
      await _loadLatest();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _deleteParking() async {
    final vehicleId = _vehicleIdController.text.trim();

    if (vehicleId.isEmpty) {
      setState(() {
        _error = 'Vehicle ID gerekli';
      });
      return;
    }

    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await ParkingService.deleteParking(
        token: widget.token,
        vehicleId: vehicleId,
      );
      if (!mounted) return;
      setState(() {
        _latestParking = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _vehicleIdController,
              decoration: const InputDecoration(
                labelText: 'Vehicle ID (vehicle_uuid)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loadLatest(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Lat',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Lng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _loadingLatest ? null : _loadLatest,
                  child: _loadingLatest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Son Parkı Getir'),
                ),
                ElevatedButton(
                  onPressed: _submitting ? null : _setParking,
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Park Kaydet'),
                ),
                ElevatedButton(
                  onPressed: _deleting ? null : _deleteParking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Parkı Sil'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _buildLatestCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestCard() {
    if (_loadingLatest) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_latestParking == null) {
      return const Text('Kayıtlı park bilgisi yok');
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
