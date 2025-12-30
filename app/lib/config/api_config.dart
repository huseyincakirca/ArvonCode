enum Environment { dev, staging, prod }

class ApiConfig {
  static const Environment environment = Environment.staging;

  static const String _devBaseUrl = 'http://localhost:8000/api';
  static const String _stagingBaseUrl = 'http://staging.localhost/api';
  static const String _prodBaseUrl = 'https://domain.com/api';

  static String get baseUrl {
    switch (environment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.staging:
        return _stagingBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
    }
  }
}
