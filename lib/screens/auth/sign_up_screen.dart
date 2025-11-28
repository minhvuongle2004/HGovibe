import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_travel_app/providers/auth/auth_form_provider.dart';
import 'package:smart_travel_app/widgets/auth/auth_form_field.dart';
import 'package:smart_travel_app/widgets/auth/auth_primary_button.dart';
import 'package:smart_travel_app/widgets/auth/auth_secondary_button.dart';
import 'package:smart_travel_app/widgets/auth/auth_header.dart';
import 'package:smart_travel_app/widgets/auth/auth_snackbar.dart';
import 'package:smart_travel_app/widgets/auth/auth_validation_text.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthFormProvider(AuthFormMode.signUp),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  bool _acceptTerms = true;

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
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    AuthHeader(
                      title: 'Tạo tài khoản mới ✨',
                      subtitle:
                          'Cùng bắt đầu hành trình du lịch thông minh của bạn',
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AuthFormField.displayName(
                            label: 'Tên hiển thị',
                            initialValue: formProvider.displayName,
                            onSaved: formProvider.setDisplayName,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập tên hiển thị';
                              }
                              return null;
                            },
                            onChanged: formProvider.setDisplayName,
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          AuthFormField.confirmPassword(
                            initialValue: formProvider.confirmPassword,
                            onSaved: formProvider.setConfirmPassword,
                            validator: (value) =>
                                formProvider.validateConfirmPassword(value),
                            onChanged: formProvider.setConfirmPassword,
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            title: const Text(
                              'Tôi đồng ý với Điều khoản & Chính sách',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AuthValidationText(
                              message: !_acceptTerms
                                  ? 'Bạn phải đồng ý với điều khoản để tiếp tục'
                                  : formProvider.errorMessage,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthPrimaryButton(
                            label: 'Tạo tài khoản',
                            isLoading: formProvider.isLoading,
                            onPressed: () async {
                              formProvider.clearMessages();
                              if (!_acceptTerms) {
                                setState(() {});
                                return;
                              }
                              if (!_formKey.currentState!.validate()) return;
                              _formKey.currentState!.save();
                              await formProvider.submit();
                              if (mounted &&
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
                          AuthSecondaryButton(
                            question: 'Đã có tài khoản?',
                            actionLabel: 'Đăng nhập',
                            onPressed: formProvider.isLoading
                                ? null
                                : () => Navigator.pop(context),
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
}
