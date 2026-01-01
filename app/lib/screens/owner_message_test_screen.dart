import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/message_service.dart';

class OwnerMessageTestScreen extends StatelessWidget {
  const OwnerMessageTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            const token = '1|Vpkch32fWntKpBnic0AKWjZuq62HppxpIQtPOY0pbbfd5327';

            try {
              final messages =
                  await MessageService().fetchMessages(token: token);

              debugPrint('Messages fetched: ${messages.length}');

              if (messages.isNotEmpty) {
                final first = messages.first;
                debugPrint(
                    'First: #${first.id} | ${first.content} | ${first.vehicleUuid}');
              }
            } catch (e) {
              debugPrint('ERROR: $e');
            }
          },
          child: const Text('TEST FETCH MESSAGES'),
        ),
      ),
    );
  }
}
