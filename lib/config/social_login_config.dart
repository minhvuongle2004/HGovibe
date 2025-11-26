/// Cấu hình cho các provider đăng nhập mạng xã hội.
/// TODO: Thay thế các giá trị placeholder bằng App ID / Client ID thực tế.
class SocialLoginConfig {
  /// Google Web Client ID (dùng cho iOS/Web nếu cần).
  static const String googleWebClientId =
      '446621147524-jhp47754ufje2p03jt1sk3fgj5ms5p98.apps.googleusercontent.com';

  /// Facebook App ID lấy từ Meta for Developers.
  static const String facebookAppId = '2700557443660865';

  /// Facebook Client Token lấy trong phần Settings -> Advanced.
  static const String facebookClientToken = 'b8b466e81639fa7bde01a744921c7bdb';

  /// Facebook Display Name (tùy chọn).
  static const String facebookDisplayName = 'Smart Travel App';

  static bool get hasGoogleWebClientId =>
      googleWebClientId.isNotEmpty &&
      !googleWebClientId.startsWith('446621147524-jhp47754ufje2p03jt1sk3fgj5ms5p98.apps.googleusercontent.com');

  static bool get hasFacebookConfig =>
      facebookAppId.isNotEmpty &&
      facebookClientToken.isNotEmpty &&
      !facebookAppId.startsWith('YOUR_');
}


