import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../utils/vehicle_uuid_parser.dart';
import 'vehicle_profile_screen.dart';

class ScanScreen extends StatefulWidget {
  final bool enableCamera;
  final bool enableNfc;
  final String title;

  const ScanScreen({
    super.key,
    this.enableCamera = true,
    this.enableNfc = true,
    this.title = 'QR / NFC Tara',
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // bool _detected = false;
  bool _handled = false;
  bool _nfcSessionStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableNfc) {
      _startNfcSession();
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    if (_nfcSessionStarted) return;
    _nfcSessionStarted = true;
    await NfcManager.instance.startSession(onDiscovered: (tag) async {
      if (_handled) return;

      final ndef = Ndef.from(tag);
      final records = ndef?.cachedMessage?.records ?? const <NdefRecord>[];
      final uri = _decodeUri(records);

      if (uri == null) {
        // Unsupported tag; keep session alive for another try.
        return;
      }

      final uuid = VehicleUuidParser.extract(uri);
      if (uuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçersiz ArvonCode')),
        );
        _handled = true;
        await NfcManager.instance.stopSession();
        return;
      }

      _handled = true;
      await NfcManager.instance.stopSession();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleProfileScreen(vehicleUuid: uuid),
        ),
      );
    });
  }

  String? _decodeUri(List<NdefRecord> records) {
    for (final record in records) {
      final isUri = record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          String.fromCharCodes(record.type) == 'U';
      if (!isUri || record.payload.isEmpty) continue;

      final prefixCode = record.payload.first;
      final uriBody = String.fromCharCodes(record.payload.sublist(1));
      final prefix = _uriPrefixes[prefixCode] ?? '';
      return '$prefix$uriBody';
    }
    return null;
  }

  static const Map<int, String> _uriPrefixes = {
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.enableCamera
          ? MobileScanner(
              onDetect: (capture) {
                if (_handled) return;

                final barcode = capture.barcodes.first;
                final raw = barcode.rawValue;
                if (raw == null) return;

                final uuid = VehicleUuidParser.extract(raw);
                if (uuid == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Geçersiz ArvonCode')),
                  );
                  _handled = true;
                  return;
                }

                _handled = true;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleProfileScreen(vehicleUuid: uuid),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'NFC kartını telefonun arkasına yaklaştırın.',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
