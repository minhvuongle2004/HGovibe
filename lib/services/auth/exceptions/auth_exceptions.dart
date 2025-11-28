class AuthCancelledException implements Exception {
  final String message;
  const AuthCancelledException([
    this.message = 'Ban da huy thao tac dang nhap.',
  ]);

  @override
  String toString() => message;
}

/// Exception khi email đã tồn tại với provider khác (ví dụ: đăng ký bằng email/password,
/// sau đó đăng nhập bằng Google với cùng email)
class AccountExistsWithDifferentCredentialException implements Exception {
  final String email;
  final List<String>
  providers; // Danh sách providers hiện tại (ví dụ: ['password'])
  final String
  attemptedProvider; // Provider đang cố đăng nhập (ví dụ: 'google.com')

  const AccountExistsWithDifferentCredentialException({
    required this.email,
    required this.providers,
    required this.attemptedProvider,
  });

  @override
  String toString() {
    final providerNames = providers
        .map((p) {
          switch (p) {
            case 'password':
              return 'Email/Mật khẩu';
            case 'google.com':
              return 'Google';
            case 'facebook.com':
              return 'Facebook';
            default:
              return p;
          }
        })
        .join(', ');

    return 'Email này đã được đăng ký bằng $providerNames. '
        'Vui lòng đăng nhập bằng phương thức đó trước, sau đó liên kết tài khoản $attemptedProvider trong phần Tài khoản.';
  }
}
