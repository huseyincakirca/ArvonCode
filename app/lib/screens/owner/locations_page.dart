import 'package:flutter/material.dart';

import '../../services/location_service.dart';

class LocationsPage extends StatefulWidget {
  final String token;

  const LocationsPage({super.key, required this.token});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  bool _loading = true;
  String? _error;
  List<_LocationItem> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final raw = await LocationService.fetchOwnerLocations(
        token: widget.token,
      );
      final locations = raw
          .map<_LocationItem>((json) => _LocationItem.fromJson(json))
          .toList();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konumlarım'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_locations.isEmpty) {
      return const Center(child: Text('Henüz konum yok'));
    }

    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        final createdAtText =
            loc.createdAt != null ? loc.createdAt!.toLocal().toString() : '';

        return ListTile(
          title: Text(
            loc.plate ?? 'Plaka yok',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                createdAtText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${loc.lat}, ${loc.lng}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                loc.source ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationItem {
  final String lat;
  final String lng;
  final String? plate;
  final String? source;
  final DateTime? createdAt;

  _LocationItem({
    required this.lat,
    required this.lng,
    this.plate,
    this.source,
    this.createdAt,
  });

  factory _LocationItem.fromJson(Map<String, dynamic> json) {
    String? plate;
    final vehicle = json['vehicle'];
    if (vehicle is Map && vehicle['plate'] != null) {
      plate = vehicle['plate'].toString();
    }

    return _LocationItem(
      lat: json['lat']?.toString() ?? '',
      lng: json['lng']?.toString() ?? '',
      plate: plate,
      source: json['source']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str);
  }
}
