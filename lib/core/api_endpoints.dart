class ApiEndpoints {
  static const String local = 'http://localhost:3000/api';

  // Replace the placeholder with your Firebase project function URL:
  // https://<region>-<project>.cloudfunctions.net/api
  static const String production = 'https://<your-region>-<your-project>.cloudfunctions.net/api';

  static String get baseUrl {
    // Flutter sets this boolean in release builds.
    return bool.fromEnvironment('dart.vm.product') ? production : local;
  }
}
