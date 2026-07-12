import 'package:flutter/material.dart';

import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../properties/properties_screen.dart';
import '../searches/searches_screen.dart';
import 'change_password_screen.dart';
import 'notifications_settings_screen.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authRepository,
    required this.token,
  });

  final AuthRepository authRepository;
  final String token;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _repository;

  bool _loading = true;
  String? _error;
  final int _tabIndex = 3;
  Map<String, dynamic> _profile = const {};

  @override
  void initState() {
    super.initState();
    _repository = ProfileRepository(widget.authRepository.apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _repository.loadProfile(widget.token);
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onTabTap(int index) {
    if (index == _tabIndex) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            authRepository: widget.authRepository,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SearchesScreen(
            authRepository: widget.authRepository,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PropertiesScreen(
            authRepository: widget.authRepository,
            token: widget.token,
          ),
        ),
      );
      return;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text('Estas seguro de que deseas salir de tu cuenta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.authRepository.logout();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authRepository: widget.authRepository),
      ),
      (_) => false,
    );
  }

  void _openNotifications() {
    final initialApp = _profile['notification_app'] == true;
    final initialEmail = _profile['notification_email'] == true;
    final initialWhatsapp = _profile['notification_whatsapp'] == true;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsSettingsScreen(
          authRepository: widget.authRepository,
          token: widget.token,
          initialApp: initialApp,
          initialEmail: initialEmail,
          initialWhatsapp: initialWhatsapp,
        ),
      ),
    );
  }

  void _openSecurity() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangePasswordScreen(
          token: widget.token,
          repository: _repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _onTabTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Busquedas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_rounded),
            label: 'Propiedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.section),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No pudimos cargar tu perfil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final fullName = _fullName(_profile);
    final email = (_profile['email'] as String?)?.trim() ?? '-';
    final initials = _initials(fullName);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.section,
            ),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.section),
              _ProfileOptionCard(
                title: 'Notificaciones',
                description: 'Gestiona como deseas recibir alertas.',
                icon: Icons.notifications_outlined,
                onTap: _openNotifications,
              ),
              const SizedBox(height: AppSpacing.medium),
              _ProfileOptionCard(
                title: 'Seguridad',
                description: 'Contrasena y acceso a la cuenta.',
                icon: Icons.shield_outlined,
                onTap: _openSecurity,
              ),
              const SizedBox(height: AppSpacing.section),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _confirmLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    foregroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cerrar sesion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fullName(Map<String, dynamic> profile) {
    final first = (profile['first_name'] as String?)?.trim() ?? '';
    final last = (profile['last_name'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) {
      return combined;
    }
    return 'Usuario';
  }

  String _initials(String fullName) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}

class _ProfileOptionCard extends StatelessWidget {
  const _ProfileOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
