import 'package:flutter/material.dart';
import '../services/message_service.dart';

class SendCustomMessageScreen extends StatefulWidget {
  final String vehicleUuid;

  const SendCustomMessageScreen({
    super.key,
    required this.vehicleUuid,
  });

  @override
  State<SendCustomMessageScreen> createState() =>
      _SendCustomMessageScreenState();
}

class _SendCustomMessageScreenState extends State<SendCustomMessageScreen> {
  final _messageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _service = MessageService();

  bool _isSending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _messageCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    // 1) Boş mesajı daha burada kes
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj boş olamaz.')),
      );
      return;
    }

    // 2) Double tap / spam engeli
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final result = await _service.sendCustomMessage(
        vehicleUuid: widget.vehicleUuid,
        message: msg,
        phone: phone.isEmpty ? null : phone,
      );

      final body = result['body'] as Map<String, dynamic>;
      final ok = body['ok'] == true;

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj gönderildi.')),
        );
        Navigator.pop(context, true); // true = gönderildi
      } else {
        // Backend standart hata döndü: message göster
        final message = (body['message'] ?? 'Gönderilemedi').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaj Yaz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Mesajın',
                hintText: 'Örn: Aracınız yolu kapatıyor...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
