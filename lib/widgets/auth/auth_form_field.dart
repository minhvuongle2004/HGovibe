import 'package:flutter/material.dart';

class AuthFormField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final void Function(String value)? onSaved;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool enableVisibilityToggle;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const AuthFormField({
    super.key,
    required this.label,
    this.initialValue,
    this.onSaved,
    this.validator,
    this.obscureText = false,
    this.enableVisibilityToggle = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.autofocus = false,
    this.onChanged,
  });

  factory AuthFormField.email({
    Key? key,
    String? label,
    String? initialValue,
    void Function(String value)? onSaved,
    String? Function(String?)? validator,
    TextEditingController? controller,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
  }) {
    return AuthFormField(
      key: key,
      label: label ?? 'Email',
      initialValue: initialValue,
      onSaved: onSaved,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
    );
  }

  factory AuthFormField.password({
    Key? key,
    String? label,
    String? initialValue,
    void Function(String value)? onSaved,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return AuthFormField(
      key: key,
      label: label ?? 'Mật khẩu',
      initialValue: initialValue,
      onSaved: onSaved,
      validator: validator,
      obscureText: true,
      enableVisibilityToggle: true,
      onChanged: onChanged,
    );
  }

  factory AuthFormField.confirmPassword({
    Key? key,
    String? initialValue,
    void Function(String value)? onSaved,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return AuthFormField(
      key: key,
      label: 'Xác nhận mật khẩu',
      initialValue: initialValue,
      onSaved: onSaved,
      validator: validator,
      obscureText: true,
      enableVisibilityToggle: true,
      onChanged: onChanged,
    );
  }

  factory AuthFormField.displayName({
    Key? key,
    String? label,
    String? initialValue,
    void Function(String value)? onSaved,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return AuthFormField(
      key: key,
      label: label ?? 'Tên hiển thị',
      initialValue: initialValue,
      onSaved: onSaved,
      validator: validator,
      onChanged: onChanged,
    );
  }

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      onSaved: widget.onSaved != null
          ? (value) => widget.onSaved!(value ?? '')
          : null,
      validator: widget.validator,
      onChanged: widget.onChanged,
      obscureText: widget.enableVisibilityToggle
          ? _obscure
          : widget.obscureText,
      keyboardType: widget.keyboardType,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: widget.enableVisibilityToggle
            ? IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              )
            : null,
      ),
    );
  }
}
