class ReviewConfig {
  /// Backend base URL (proxy upload imgBB)
  static const String backendBaseUrl =
      'https://smarttravelbackend-production.up.railway.app';

  static String get uploadImageEndpoint =>
      '$backendBaseUrl/reviews/uploadImage';
}

