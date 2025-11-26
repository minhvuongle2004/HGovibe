import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_form_provider.dart';
import '../../widgets/auth/auth_form_field.dart';
import '../../widgets/auth/auth_primary_button.dart';
import '../../widgets/auth/auth_secondary_button.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_social_buttons.dart';
import '../../widgets/auth/auth_snackbar.dart';
import '../../widgets/auth/auth_validation_text.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthFormProvider(AuthFormMode.signIn),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<AuthFormProvider>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final padding = EdgeInsets.symmetric(
              horizontal: isWide ? constraints.maxWidth * 0.2 : 24,
              vertical: 24,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthHeader(
                      title: 'Chào mừng trở lại 👋',
                      subtitle: 'Đăng nhập để tiếp tục khám phá những chuyến đi thông minh',
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthFormField.email(
                            label: 'Email',
                            initialValue: formProvider.email,
                            onSaved: formProvider.setEmail,
                            validator: formProvider.validateEmail,
                            onChanged: formProvider.setEmail,
                          ),
                          const SizedBox(height: 16),
                          AuthFormField.password(
                            label: 'Mật khẩu',
                            initialValue: formProvider.password,
                            onSaved: formProvider.setPassword,
                            validator: formProvider.validatePassword,
                            onChanged: formProvider.setPassword,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: formProvider.rememberMe,
                                    onChanged: !formProvider.isLoading
                                        ? formProvider.setRememberMe
                                        : null,
                                  ),
                                  const Text('Nhớ đăng nhập'),
                                ],
                              ),
                              TextButton(
                                onPressed: formProvider.isLoading
                                    ? null
                                    : () => _showForgotPasswordDialog(context),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AuthValidationText(message: formProvider.errorMessage),
                          const SizedBox(height: 16),
                          AuthPrimaryButton(
                            label: 'Đăng nhập',
                            isLoading: formProvider.isLoading,
                            onPressed: () async {
                              formProvider.clearMessages();
                              if (!_formKey.currentState!.validate()) return;
                              _formKey.currentState!.save();
                              await formProvider.submit();
                              if (context.mounted &&
                                  formProvider.successMessage != null) {
                                showAuthSnackBar(
                                  context,
                                  formProvider.successMessage!,
                                  isError: false,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          const AuthSocialButtons(),
                          const SizedBox(height: 24),
                          AuthSecondaryButton(
                            question: 'Chưa có tài khoản?',
                            actionLabel: 'Đăng ký ngay',
                            onPressed: formProvider.isLoading
                                ? null
                                : () => Navigator.pushNamed(context, '/sign-up'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final formProvider = context.read<AuthFormProvider>();
    formProvider.clearMessages();
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: formProvider.email);
        final dialogKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Quên mật khẩu'),
          content: Form(
            key: dialogKey,
            child: AuthFormField.email(
              controller: controller,
              autofocus: true,
              validator: (value) => formProvider.validateEmail(value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!dialogKey.currentState!.validate()) return;
                await formProvider.sendPasswordReset(controller.text.trim());
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  showAuthSnackBar(
                    context,
                    'Đã gửi email đặt lại mật khẩu',
                    isError: false,
                  );
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }
}


