class VehicleUuidParser {
  /// Kabul ettiğimiz formatlar:
  /// 1) arvoncode://v/<UUID>
  /// 2) https://domain/v/<UUID>
  /// 2b) http(s)://<ip or domain>/api/public/vehicle/<UUID>
  /// 3) Sadece UUID (ACX4921 gibi)
  static String? extract(String raw) {
    final s = raw.trim();

    if (s.isEmpty) return null;

    // 3) Direkt UUID gibi gelmişse (boşluk yok, slash yok) kabul et
    final looksLikePlainId =
        !s.contains('/') && !s.contains(' ') && s.length >= 4;
    if (looksLikePlainId) return s;

    Uri? uri;
    try {
      uri = Uri.parse(s);
    } catch (_) {
      return null;
    }

    // arvoncode://v/ACX4921 => scheme=arvoncode host=v pathSegments=[ACX4921]
    // https://site.com/v/ACX4921 => pathSegments=[v, ACX4921]
    final seg = uri.pathSegments;

    // case: /v/<uuid>
    if (seg.length >= 2 && seg[0] == 'v' && seg[1].isNotEmpty) {
      return seg[1];
    }

    // case: arvoncode://v/<uuid> (host=v)
    if ((uri.scheme == 'arvoncode') && uri.host == 'v' && seg.isNotEmpty) {
      return seg[0];
    }

    // case: /api/public/vehicle/<uuid>
    final apiIndex = seg.indexOf('api');
    if (apiIndex != -1 &&
        seg.length > apiIndex + 3 &&
        seg[apiIndex + 1] == 'public' &&
        seg[apiIndex + 2] == 'vehicle' &&
        seg[apiIndex + 3].isNotEmpty) {
      return seg[apiIndex + 3];
    }

    return null;
  }
}
