import 'package:flutter/material.dart';

import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../properties/property_detail_screen.dart';
import '../properties/properties_screen.dart';
import '../searches/searches_screen.dart';
import 'home_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authRepository,
    required this.token,
  });

  final AuthRepository authRepository;
  final String token;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository _homeRepository;

  bool _loading = true;
  String? _error;
  int _tabIndex = 0;

  Map<String, dynamic> _profile = const {};
  Map<String, dynamic> _summary = const {};
  List<dynamic> _properties = const [];
  List<dynamic> _results = const [];
  Map<int, String> _neighborhoodNamesById = const {};

  @override
  void initState() {
    super.initState();
    _homeRepository = HomeRepository(widget.authRepository.apiClient);
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _homeRepository.loadHomeData(widget.token);

      setState(() {
        _profile = data['profile'] as Map<String, dynamic>;
        _summary = data['summary'] as Map<String, dynamic>;
        _properties = data['properties'] as List<dynamic>;
        _results = data['results'] as List<dynamic>;
        _neighborhoodNamesById =
            (data['neighborhoodNamesById'] as Map<int, String>?) ?? const {};
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

  Future<void> _logout() async {
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

  void _onSummaryCardTap(String section) {
    if (section == 'busquedas activas') {
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

    if (section == 'propiedades activas') {
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Proximamente: $section')));
  }

  void _onBottomTap(int index) {
    if (index == _tabIndex) {
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

    if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(
            authRepository: widget.authRepository,
            token: widget.token,
          ),
        ),
      );
      return;
    }

    setState(() => _tabIndex = index);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proximamente: seccion en construccion')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: _onBottomTap,
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
                'No pudimos cargar tu inicio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHome,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final firstName = (_profile['first_name'] as String?)?.trim();
    final userName = (firstName == null || firstName.isEmpty)
        ? 'Usuario'
        : firstName;

    final newMatches = _toInt(_summary['new_matches']);
    final activeSearches = _toInt(_summary['active_searches']);
    final activeProperties = _toInt(_summary['active_properties']);
    final totalMatches = _toInt(_summary['active_results']);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHome,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola $userName',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bienvenido a Raices',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                _HighlightMatchesCard(
                  newMatches: newMatches,
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  'Resumen',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.medium),
                _SummaryGrid(
                  activeSearches: activeSearches,
                  activeProperties: activeProperties,
                  newMatches: newMatches,
                  totalMatches: totalMatches,
                  onCardTap: _onSummaryCardTap,
                ),
                const SizedBox(height: AppSpacing.section),
                _SmartSection(
                  properties: _properties,
                  results: _results,
                  neighborhoodNamesById: _neighborhoodNamesById,
                  onOpenProperty: _openPropertyDetail,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPropertyDetail(Map<String, dynamic> property) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyDetailScreen(property: property, isOwner: true),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class _HighlightMatchesCard extends StatelessWidget {
  const _HighlightMatchesCard({required this.newMatches});

  final int newMatches;

  @override
  Widget build(BuildContext context) {
    final matchLabel = newMatches == 1
        ? 'nueva coincidencia'
        : 'nuevas coincidencias';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$newMatches',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  matchLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa las nuevas propiedades que coinciden con tus busquedas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.notifications_active_rounded,
              size: 34,
              color: AppColors.textPrimary.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.activeSearches,
    required this.activeProperties,
    required this.newMatches,
    required this.totalMatches,
    required this.onCardTap,
  });

  final int activeSearches;
  final int activeProperties;
  final int newMatches;
  final int totalMatches;
  final ValueChanged<String> onCardTap;

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          label: 'Busquedas activas',
          value: activeSearches,
          icon: Icons.search_rounded,
          onTap: () => onCardTap('busquedas activas'),
        ),
        _SummaryCard(
          label: 'Propiedades activas',
          value: activeProperties,
          icon: Icons.home_rounded,
          onTap: () => onCardTap('propiedades activas'),
        ),
        _SummaryCard(
          label: 'Nuevos matches',
          value: newMatches,
          icon: Icons.notifications_rounded,
          onTap: () => onCardTap('nuevos matches'),
        ),
        _SummaryCard(
          label: 'Matches totales',
          value: totalMatches,
          icon: Icons.bar_chart_rounded,
          onTap: () => onCardTap('matches totales'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int value;
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartSection extends StatelessWidget {
  const _SmartSection({
    required this.properties,
    required this.results,
    required this.neighborhoodNamesById,
    required this.onOpenProperty,
  });

  final List<dynamic> properties;
  final List<dynamic> results;
  final Map<int, String> neighborhoodNamesById;
  final ValueChanged<Map<String, dynamic>> onOpenProperty;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return _SmartTipCard(
        title: 'Consejo para empezar',
        body:
            'Publica tu primera propiedad para empezar a recibir matches automaticos.',
        cta: 'Crear propiedad',
      );
    }

    final countsByProperty = <int, int>{};
    for (final item in results) {
      if (item is Map<String, dynamic>) {
        final propertyId = item['property_id'];
        if (propertyId is int) {
          countsByProperty[propertyId] =
              (countsByProperty[propertyId] ?? 0) + 1;
        }
      }
    }

    Map<String, dynamic>? lowestProperty;
    int? lowestCount;

    for (final item in properties) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final id = item['id'];
      if (id is! int) {
        continue;
      }
      final count = countsByProperty[id] ?? 0;
      if (lowestCount == null || count < lowestCount) {
        lowestCount = count;
        lowestProperty = item;
      }
    }

    final propertyType = _propertyTypeLabel(lowestProperty?['type'] as String?);
    final neighborhood = _neighborhoodLabel(
      lowestProperty,
      neighborhoodNamesById,
    );
    final price = _formatCop(lowestProperty?['price']);

    return Container(
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
            'Requiere atencion',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            neighborhood.isEmpty
                ? propertyType
                : '$propertyType • $neighborhood',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Precio: $price',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${lowestCount ?? 0} matches en los ultimos 30 dias',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Considera actualizar el precio o la descripcion.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: lowestProperty == null
                  ? null
                  : () => onOpenProperty(lowestProperty!),
              child: const Text('Ver propiedad'),
            ),
          ),
        ],
      ),
    );
  }

  String _propertyTypeLabel(String? type) {
    switch (type) {
      case 'house':
        return 'Casa';
      case 'office':
        return 'Oficina';
      case 'commercial':
        return 'Local';
      case 'apartment':
      default:
        return 'Apartamento';
    }
  }

  String _neighborhoodLabel(
    Map<String, dynamic>? property,
    Map<int, String> namesById,
  ) {
    if (property == null) {
      return '';
    }

    final nested = property['neighborhood'];
    if (nested is Map<String, dynamic>) {
      final name = nested['name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }

    final directName = property['neighborhood_name'];
    if (directName is String && directName.trim().isNotEmpty) {
      return directName.trim();
    }

    final camelName = property['neighborhoodName'];
    if (camelName is String && camelName.trim().isNotEmpty) {
      return camelName.trim();
    }

    final neighborhoodId = _parseInt(property['neighborhood_id']) ??
        _parseInt(property['neighborhoodId']);
    if (neighborhoodId != null) {
      final resolved = namesById[neighborhoodId];
      if (resolved != null && resolved.trim().isNotEmpty) {
        return resolved.trim();
      }
    }

    return '';
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String _formatCop(dynamic rawValue) {
    num? value;
    if (rawValue is int || rawValue is double) {
      value = rawValue as num;
    } else if (rawValue is String) {
      value = num.tryParse(rawValue);
    }

    if (value == null || value <= 0) {
      return 'Por definir';
    }

    final source = value.toStringAsFixed(0);
    final chars = source.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    return '\$${buffer.toString().split('').reversed.join()}';
  }
}

class _SmartTipCard extends StatelessWidget {
  const _SmartTipCard({
    required this.title,
    required this.body,
    required this.cta,
  });

  final String title;
  final String body;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: Text(cta)),
        ],
      ),
    );
  }
}
