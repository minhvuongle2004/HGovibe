import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_travel_app/widgets/auth/auth_primary_button.dart';

void main() {
  testWidgets('AuthPrimaryButton hiển thị loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthPrimaryButton(
            label: 'Đăng nhập',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
  });
}


