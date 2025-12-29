import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../services/message_service.dart';

class MessagesPage extends StatefulWidget {
  final String token;

  const MessagesPage({super.key, required this.token});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _loading = true;
  String? _error;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages =
          await MessageService().fetchMessages(token: widget.token);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _mapErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchMessages,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('Henüz mesaj yok'));
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final createdAtText = message.createdAt != null
            ? _formatDateTime(message.createdAt!)
            : '';

        return ListTile(
          title: Text(
            message.content,
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
                message.vehicleUuid,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String _mapErrorMessage(Object error) {
    if (error is SocketException || error is TimeoutException) {
      return 'Bağlantı hatası. İnternetinizi kontrol edin.';
    }

    final msg = error.toString();
    if (msg.contains('HTTP 401')) {
      return 'Oturum süresi doldu. Tekrar giriş yapın.';
    }

    return 'Mesajlar yüklenemedi.';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final day = two(local.day);
    final month = two(local.month);
    final year = local.year.toString();
    final hour = two(local.hour);
    final minute = two(local.minute);
    return '$day.$month.$year $hour:$minute';
  }
}
