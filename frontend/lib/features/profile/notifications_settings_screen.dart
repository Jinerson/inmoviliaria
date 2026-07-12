import 'package:flutter/material.dart';

import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({
    super.key,
    required this.authRepository,
    required this.token,
    required this.initialApp,
    required this.initialEmail,
    required this.initialWhatsapp,
  });

  final AuthRepository authRepository;
  final String token;
  final bool initialApp;
  final bool initialEmail;
  final bool initialWhatsapp;

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  late bool _appEnabled;
  late bool _emailEnabled;
  late bool _whatsappEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _appEnabled = widget.initialApp;
    _emailEnabled = widget.initialEmail;
    _whatsappEnabled = widget.initialWhatsapp;
  }

  Future<void> _updatePreference({
    required bool app,
    required bool email,
    required bool whatsapp,
  }) async {
    setState(() {
      _saving = true;
    });

    try {
      await widget.authRepository.apiClient.patchJson(
        '/users/me/notifications',
        token: widget.token,
        body: {
          'notification_app': app,
          'notification_email': email,
          'notification_whatsapp': whatsapp,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracion actualizada')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la configuracion')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _onEmailChanged(bool value) async {
    setState(() {
      _emailEnabled = value;
    });
    await _updatePreference(
      app: _appEnabled,
      email: _emailEnabled,
      whatsapp: _whatsappEnabled,
    );
  }

  Future<void> _onWhatsappChanged(bool value) async {
    setState(() {
      _whatsappEnabled = value;
    });
    await _updatePreference(
      app: _appEnabled,
      email: _emailEnabled,
      whatsapp: _whatsappEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.section,
              ),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Notificaciones',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestiona como deseas recibir alertas cuando aparezcan nuevas coincidencias.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.section),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _NotificationSwitchRow(
                        title: 'Correo electronico',
                        value: _emailEnabled,
                        onChanged: _saving ? null : _onEmailChanged,
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      _NotificationSwitchRow(
                        title: 'WhatsApp',
                        value: _whatsappEnabled,
                        onChanged: _saving ? null : _onWhatsappChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  'Recibiras alertas cuando encontremos nuevas coincidencias para tus busquedas activas.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _NotificationSwitchRow extends StatelessWidget {
  const _NotificationSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.secondary,
        ),
      ],
    );
  }
}
