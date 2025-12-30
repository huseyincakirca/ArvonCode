class DateFormatter {
  DateFormatter._();

  static String format(String isoDate) {
    final value = isoDate.trim();
    if (value.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(value).toLocal();

      String two(int v) => v.toString().padLeft(2, '0');
      final day = two(dateTime.day);
      final month = two(dateTime.month);
      final year = dateTime.year.toString();
      final hour = two(dateTime.hour);
      final minute = two(dateTime.minute);

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return '-';
    }
  }
}
