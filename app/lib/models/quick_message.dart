class QuickMessage {
  final String id;
  final String message;
  final bool isDefault;
  bool isActive;

  QuickMessage({
    required this.id,
    required this.message,
    this.isDefault = false,
    this.isActive = true,
  });
}
