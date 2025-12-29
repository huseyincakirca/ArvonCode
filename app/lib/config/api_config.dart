class ApiConfig {
  static const bool isProd = false;

  static const String devBaseUrl = 'http://192.168.1.115:8000/api';
  static const String prodBaseUrl = 'https://domain.com/api';

  static String get baseUrl => isProd ? prodBaseUrl : devBaseUrl;
}
