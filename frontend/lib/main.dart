import 'dart:async';

import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RaicesApp());
}

class RaicesApp extends StatefulWidget {
  const RaicesApp({super.key});

  @override
  State<RaicesApp> createState() => _RaicesAppState();
}

class _RaicesAppState extends State<RaicesApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AuthRepository _authRepository;
  bool _handlingUnauthorized = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(onUnauthorized: _onUnauthorized);
    _authRepository = AuthRepository(apiClient);
  }

  void _onUnauthorized() {
    if (_handlingUnauthorized) {
      return;
    }
    _handlingUnauthorized = true;
    unawaited(_redirectToLoginAfterSessionExpiration());
  }

  Future<void> _redirectToLoginAfterSessionExpiration() async {
    try {
      await _authRepository.logout();
      if (!mounted) {
        return;
      }

      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authRepository: _authRepository),
        ),
        (_) => false,
      );
    } finally {
      _handlingUnauthorized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Raices',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _SessionGate(authRepository: _authRepository),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate({required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: authRepository.getSavedToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          return LoginScreen(authRepository: authRepository);
        }

        return HomeScreen(authRepository: authRepository, token: token);
      },
    );
  }
}
