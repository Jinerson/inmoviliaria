import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_design_system.dart';

class ContactOwnerScreen extends StatelessWidget {
  const ContactOwnerScreen({super.key, required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final owner = _ownerMap(property);
    final ownerName = _ownerName(owner);
    final phone = _firstString(
      {
        ...property,
        ...owner,
      },
      const [
        'phone',
        'mobile',
        'phone_number',
        'contact_phone',
        'owner_phone',
      ],
    );
    final email = _firstString(
      {
        ...property,
        ...owner,
      },
      const [
        'email',
        'mail',
        'contact_email',
        'owner_email',
      ],
    );

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
                    const SizedBox(width: 4),
                    Text(
                      'Contactar propietario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige el canal por el que quieres contactar al propietario.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      _ActionCard(
                        icon: Icons.call_rounded,
                        title: 'Llamar',
                        subtitle: phone ?? 'No hay teléfono disponible',
                        enabled: phone != null,
                        onTap: () => _launchUri(context, _phoneUri(phone)),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.chat_rounded,
                        title: 'Escribir a WhatsApp',
                        subtitle: phone == null ? 'No hay teléfono disponible' : 'Abrir conversación con este número',
                        enabled: phone != null,
                        onTap: () => _launchUri(context, _whatsappUri(phone)),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.email_rounded,
                        title: 'Escribir email',
                        subtitle: email ?? 'No hay correo disponible',
                        enabled: email != null,
                        onTap: () => _launchUri(context, _emailUri(email)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _ownerMap(Map<String, dynamic> property) {
    final direct = property['owner'];
    if (direct is Map<String, dynamic>) {
      return direct;
    }
    return property;
  }

  String _ownerName(Map<String, dynamic> owner) {
    final firstName = _firstString(owner, const ['first_name', 'firstname']);
    final lastName = _firstString(owner, const ['last_name', 'lastname']);
    final fullName = [firstName, lastName].whereType<String>().where((item) => item.trim().isNotEmpty).join(' ').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final fallback = _firstString(owner, const ['name', 'owner_name']);
    if (fallback != null) {
      return fallback;
    }

    return 'Propietario';
  }

  String? _firstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Uri? _phoneUri(String? phone) {
    final normalized = _normalizePhone(phone);
    if (normalized == null) return null;
    return Uri.parse('tel:$normalized');
  }

  Uri? _whatsappUri(String? phone) {
    final normalized = _normalizePhone(phone);
    if (normalized == null) return null;
    return Uri.parse('https://wa.me/$normalized');
  }

  Uri? _emailUri(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    return Uri.parse('mailto:${email.trim()}');
  }

  String? _normalizePhone(String? phone) {
    if (phone == null) return null;
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<void> _launchUri(BuildContext context, Uri? uri) async {
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay informacion de contacto disponible')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) {
      return;
    }

    final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (fallback) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la aplicacion')),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.soft,
            border: Border.all(
              color: enabled ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
