class Message {
  final String id;
  final String vehicleUuid;
  final String content;
  final String? phone;
  final String? senderIp;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.vehicleUuid,
    required this.content,
    this.phone,
    this.senderIp,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final content = json['message']?.toString();

    String? vehicleUuid;
    final vehicle = json['vehicle'];
    if (vehicle is Map && vehicle['vehicle_id'] != null) {
      vehicleUuid = vehicle['vehicle_id'].toString();
    } else if (json['vehicle_id'] != null) {
      vehicleUuid = json['vehicle_id'].toString();
    } else if (json['vehicle_uuid'] != null) {
      vehicleUuid = json['vehicle_uuid'].toString();
    }

    if (id == null || id.isEmpty) {
      throw Exception('Message id is missing');
    }

    if (vehicleUuid == null || vehicleUuid.isEmpty) {
      throw Exception('Message vehicle_uuid is missing');
    }

    if (content == null || content.isEmpty) {
      throw Exception('Message body is missing');
    }

    return Message(
      id: id,
      vehicleUuid: vehicleUuid,
      content: content,
      phone: _readOptional(json['phone']),
      senderIp: _readOptional(json['sender_ip']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static String? _readOptional(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
