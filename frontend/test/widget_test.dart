import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/auth_repository.dart';
import 'package:frontend/features/auth/login_screen.dart';

void main() {
  testWidgets('Raices login screen renders', (WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    final authRepository = AuthRepository(ApiClient());

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authRepository: authRepository)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Bienvenido a'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
