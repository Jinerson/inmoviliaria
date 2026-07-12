import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../searches/searches_screen.dart';
import 'create_property_screen.dart';
import 'edit_property_screen.dart';
import 'property_detail_screen.dart';
import 'properties_repository.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({
    super.key,
    required this.authRepository,
    required this.token,
  });

  final AuthRepository authRepository;
  final String token;

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  late final PropertiesRepository _repository;

  bool _loading = true;
  String? _error;
  int _tabIndex = 2;

  List<Map<String, dynamic>> _properties = const [];
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _repository = PropertiesRepository(widget.authRepository.apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = await _repository.loadPropertiesData(widget.token);
      final properties = (payload['properties'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      final results = (payload['results'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      setState(() {
        _properties = properties;
        _results = results;
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

  Future<void> _openCreateProperty() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreatePropertyScreen(
          authRepository: widget.authRepository,
          token: widget.token,
        ),
      ),
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openPropertyDetail(Map<String, dynamic> property) async {
    final counts = _matchesByPropertyId(_results);
    final propertyId = _propertyId(property);

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PropertyDetailScreen(
          property: property,
          isOwner: true,
          activeMatchesCount: propertyId == null ? 0 : (counts[propertyId] ?? 0),
          onEditPressed: () => _openEditProperty(property),
          onDeletePressed: () => _confirmAndDeleteProperty(property),
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadData();
    }
  }

  Future<bool> _openEditProperty(Map<String, dynamic> property) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditPropertyScreen(
          token: widget.token,
          property: property,
          repository: _repository,
        ),
      ),
    );

    return updated == true;
  }

  Future<bool> _confirmAndDeleteProperty(Map<String, dynamic> property) async {
    final propertyId = _propertyId(property);
    if (propertyId == null) {
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar inmueble'),
          content: const Text('Esta accion no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    try {
      await _repository.deleteProperty(token: widget.token, propertyId: propertyId);
      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble eliminado')),
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
      return false;
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

    setState(() {
      _tabIndex = index;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proximamente: seccion en construccion')),
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
                'No pudimos cargar tus inmuebles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final counts = _matchesByPropertyId(_results);
    final totalProperties = _properties.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.section,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis inmuebles',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Administra las propiedades que has publicado.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalProperties inmuebles',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CreatePropertyButton(onTap: _openCreateProperty),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              if (_properties.isEmpty)
                _EmptyState(onCreateTap: _openCreateProperty)
              else ...[
                _TopPropertyCard(
                  property: _bestProperty(_properties, counts),
                  count: _bestPropertyCount(_properties, counts),
                  onTap: () => _openPropertyDetail(
                    _bestProperty(_properties, counts),
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                ..._properties.map(
                  (property) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.section),
                    child: _PropertyCard(
                      property: property,
                      matches: counts[_propertyId(property)] ?? 0,
                      onTap: () => _openPropertyDetail(property),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<int, int> _matchesByPropertyId(List<Map<String, dynamic>> results) {
    final counts = <int, int>{};

    for (final result in results) {
      final propertyId = _resultPropertyId(result);
      if (propertyId == null) {
        continue;
      }
      counts[propertyId] = (counts[propertyId] ?? 0) + 1;
    }

    return counts;
  }

  int? _resultPropertyId(Map<String, dynamic> result) {
    final directId = result['property_id'];
    if (directId is int) {
      return directId;
    }

    final nested = result['property'];
    if (nested is Map<String, dynamic>) {
      final nestedId = nested['id'];
      if (nestedId is int) {
        return nestedId;
      }
    }

    return null;
  }

  int? _propertyId(Map<String, dynamic> property) {
    final id = property['id'];
    return id is int ? id : null;
  }

  Map<String, dynamic> _bestProperty(
    List<Map<String, dynamic>> properties,
    Map<int, int> counts,
  ) {
    var best = properties.first;
    var bestCount = counts[_propertyId(best)] ?? 0;

    for (final property in properties.skip(1)) {
      final count = counts[_propertyId(property)] ?? 0;
      if (count > bestCount) {
        best = property;
        bestCount = count;
      }
    }

    return best;
  }

  int _bestPropertyCount(
    List<Map<String, dynamic>> properties,
    Map<int, int> counts,
  ) {
    final best = _bestProperty(properties, counts);
    return counts[_propertyId(best)] ?? 0;
  }
}

class _CreatePropertyButton extends StatelessWidget {
  const _CreatePropertyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _TopPropertyCard extends StatelessWidget {
  const _TopPropertyCard({
    required this.property,
    required this.count,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 coincidencia encontrada' : '$count coincidencias encontradas';
    final location = _locationText(property);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E0),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu inmueble mas popular',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _propertyTitle(property),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('Ver inmueble'),
            ),
          ),
        ],
      ),
    );
  }

  String _propertyTitle(Map<String, dynamic> property) {
    final name = property['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }

    final type = _typeLabel(property['type'] as String?);
    return type;
  }

  String _locationText(Map<String, dynamic> property) {
    final city = _asText(property['city_name']) ?? _asText(property['city']);
    final district = _asText(property['district_name']) ??
        _asText(property['district']) ??
        _asText(property['locality_name']);
    final neighborhood = _asText(property['neighborhood_name']) ??
        _asText(property['neighborhood']);

    final parts = <String>[];
    if (city != null) {
      parts.add(city);
    }
    if (district != null) {
      parts.add(district);
    }
    if (neighborhood != null) {
      parts.add(neighborhood);
    }

    return parts.join(' • ');
  }

  String? _asText(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  String _typeLabel(String? value) {
    switch (value) {
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
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.matches,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final int matches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreStyle = _matchStyle(matches);
    final location = _locationText(property);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _PhotoPreview(property: property),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _propertyTitle(property),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _intentionLabel(property),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _priceLabel(property),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _featuresLabel(property),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                scoreStyle.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scoreStyle.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (scoreStyle.hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  scoreStyle.hint!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              if (matches == 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Considera revisar el precio o la descripcion.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          'Ver detalle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _propertyTitle(Map<String, dynamic> property) {
    final name = property['name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.trim();
    }

    final type = _typeLabel(property['type'] as String?);
    return type;
  }

  String _locationText(Map<String, dynamic> property) {
    final city = _asText(property['city_name']) ?? _asText(property['city']);
    final district = _asText(property['district_name']) ??
        _asText(property['district']) ??
        _asText(property['locality_name']);
    final neighborhood = _asText(property['neighborhood_name']) ??
        _asText(property['neighborhood']);

    final parts = <String>[];
    if (city != null) {
      parts.add(city);
    }
    if (district != null) {
      parts.add(district);
    }
    if (neighborhood != null) {
      parts.add(neighborhood);
    }

    return parts.join(' • ');
  }

  String? _asText(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  String _intentionLabel(Map<String, dynamic> property) {
    final value = property['intention'] ?? property['listing_type'];
    if (value == 'rent') {
      return 'Arriendo';
    }
    return 'Venta';
  }

  String _featuresLabel(Map<String, dynamic> property) {
    final rooms = property['rooms'] as int?;
    final bathrooms = property['bathrooms'] as int?;

    final parts = <String>[];
    if (rooms != null) {
      parts.add('$rooms hab');
    }
    if (bathrooms != null) {
      parts.add('$bathrooms baños');
    }

    if (parts.isEmpty) {
      return 'Caracteristicas por definir';
    }

    return parts.join(' • ');
  }

  String _priceLabel(Map<String, dynamic> property) {
    final minPrice = _toNum(property['min_price']);
    final maxPrice = _toNum(property['max_price']);
    final singlePrice = _toNum(property['price']);

    if (singlePrice != null && singlePrice > 0) {
      return _formatCop(singlePrice);
    }

    if (minPrice == null && maxPrice == null) {
      return 'Precio por definir';
    }

    final hasOpenLowerBound = minPrice == null || minPrice <= 0;
    if (hasOpenLowerBound) {
      if (maxPrice == null) {
        return 'Hasta';
      }
      return 'Hasta ${_formatCop(maxPrice)}';
    }

    final minText = _formatCop(minPrice);
    final maxText = maxPrice == null ? '-' : _formatCop(maxPrice);
    return '$minText - $maxText';
  }

  _MatchStyle _matchStyle(int count) {
    if (count > 10) {
      final label = count == 1 ? '1 coincidencia' : '$count coincidencias';
      return _MatchStyle(label: label, color: AppColors.success);
    }

    if (count > 0) {
      final label = count == 1 ? '1 coincidencia' : '$count coincidencias';
      return _MatchStyle(label: label, color: AppColors.warning);
    }

    return const _MatchStyle(
      label: '0 coincidencias',
      hint: 'Requiere atencion',
      color: Color(0xFFEF4444),
    );
  }

  String _typeLabel(String? value) {
    switch (value) {
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

  num? _toNum(dynamic value) {
    if (value is int || value is double) {
      return value as num;
    }
    return null;
  }

  String _formatCop(num value) {
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

class _MatchStyle {
  const _MatchStyle({
    required this.label,
    required this.color,
    this.hint,
  });

  final String label;
  final String? hint;
  final Color color;
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final previewUrl = _pickPreviewUrl(property);
    if (previewUrl != null) {
      return Image.network(
        previewUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  String? _pickPreviewUrl(Map<String, dynamic> source) {
    String? normalize(dynamic raw) {
      if (raw is! String) {
        return null;
      }
      final value = raw.trim();
      if (value.isEmpty) {
        return null;
      }
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
      if (value.startsWith('//')) {
        return 'https:$value';
      }
      if (value.startsWith('/')) {
        return '${AppConfig.baseUrl}$value';
      }
      return '${AppConfig.baseUrl}/$value';
    }

    final directCandidates = [
      source['main_photo_url'],
      source['cover_photo_url'],
      source['photo_url'],
      source['image_url'],
    ];

    for (final candidate in directCandidates) {
      final parsed = normalize(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    final photos = source['photos'] ?? source['images'];
    if (photos is List) {
      for (final item in photos) {
        if (item is String) {
          final parsed = normalize(item);
          if (parsed != null) {
            return parsed;
          }
          continue;
        }

        if (item is Map<String, dynamic>) {
          final nestedCandidates = [
            item['url'],
            item['secure_url'],
            item['photo_url'],
            item['image_url'],
            item['src'],
            item['path'],
          ];

          for (final candidate in nestedCandidates) {
            final parsed = normalize(candidate);
            if (parsed != null) {
              return parsed;
            }
          }
        }
      }
    }

    return null;
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 36,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aun no has publicado inmuebles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Publica tu primera propiedad y comienza a recibir coincidencias automaticamente.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onCreateTap,
            child: const Text('Crear inmueble'),
          ),
        ],
      ),
    );
  }
}
