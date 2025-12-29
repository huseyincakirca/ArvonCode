class SendMessageRequest {
  final String cardId;
  final String message;
  final String timestamp;
  final String location;

  SendMessageRequest({
    required this.cardId,
    required this.message,
    required this.timestamp,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      "card_id": cardId,
      "message": message,
      "timestamp": timestamp,
      "location": location,
    };
  }
}
