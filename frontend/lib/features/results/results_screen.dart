import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../theme/app_design_system.dart';
import '../properties/property_detail_screen.dart';
import 'results_repository.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.token,
    required this.search,
    required this.cityName,
    required this.repository,
  });

  final String token;
  final Map<String, dynamic> search;
  final String cityName;
  final ResultsRepository repository;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _loading = true;
  bool _hasFailure = false;
  List<Map<String, dynamic>> _results = const [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final searchId = widget.search['id'] as int?;
    if (searchId == null) {
      setState(() {
        _hasFailure = true;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasFailure = false;
    });

    try {
      final items = await widget.repository.loadResultsForSearch(
        token: widget.token,
        searchId: searchId,
      );

      items.sort((a, b) {
        final scoreA = _scoreValue(a['match_percentage']);
        final scoreB = _scoreValue(b['match_percentage']);
        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _results = items;
      });
    } catch (_) {
      setState(() {
        _hasFailure = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.section),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Muy pronto podras filtrar por compatibilidad minima, precio y fecha de publicacion.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  void _openPropertyDetail(Map<String, dynamic> result) {
    final property = (result['property'] as Map<String, dynamic>?) ?? const {};
    if (property.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay detalle disponible para este inmueble')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyDetailScreen(
          property: property,
          isOwner: false,
          activeMatchesCount: 1,
          demandScore: _scoreValue(result['match_percentage']),
          compatibleSearches: [widget.search],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsCount = _results.length;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              onRefresh: _loadResults,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.section,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Regresar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Resultados',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_intentionLabel(widget.search['intention'] as String?)} ${_typeLabel(widget.search['type'] as String?)} • ${widget.cityName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$resultsCount coincidencias encontradas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ordenadas por nivel de compatibilidad',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_results.isEmpty || _hasFailure)
                    const _NoResultsState()
                  else
                    ..._results.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.section,
                        ),
                        child: _ResultCard(
                          result: item,
                          search: widget.search,
                          isBestMatch: index == 0,
                          onTap: () => _openPropertyDetail(item),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _scoreValue(dynamic raw) {
    if (raw is num) {
      if (raw <= 1) {
        return raw * 100;
      }
      return raw.toDouble();
    }
    return 0;
  }

  String _intentionLabel(String? value) {
    switch (value) {
      case 'rent':
        return 'Arrendar';
      case 'sale':
      default:
        return 'Comprar';
    }
  }

  String _typeLabel(String? value) {
    switch (value) {
      case 'house':
        return 'casa';
      case 'office':
        return 'oficina';
      case 'commercial':
        return 'local';
      case 'apartment':
      default:
        return 'apartamento';
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.search,
    required this.isBestMatch,
    required this.onTap,
  });

  final Map<String, dynamic> result;
  final Map<String, dynamic> search;
  final bool isBestMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final property = (result['property'] as Map<String, dynamic>?) ?? {};

    final score = _normalizedScore(result['match_percentage']);
    final scoreColor = _compatibilityColor(score);
    final scoreText = '${score.round()}%';

    final chips = _whyItMatches(search: search, property: property);
    final price = _formatCop(_toNum(property['price']) ?? 0);

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
                aspectRatio: 4 / 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _PhotoPreview(property: property),
                    ),
                    if (isBestMatch)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mejor coincidencia',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _propertyTitle(property),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _propertyLocation(property),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _softChip(_areaLabel(property)),
                  _softChip(_roomsLabel(property)),
                  _softChip(_bathroomsLabel(property)),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: _CompatibilityCircle(
                  score: score,
                  color: scoreColor,
                  scoreText: scoreText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coincide con:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips
                          .map(
                            (reason) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reason,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
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

  Widget _softChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _propertyTitle(Map<String, dynamic> property) {
    final type = (property['type'] as String?) ?? 'apartment';
    final typeLabel = _typeLabel(type);

    final neighborhood = _firstNonEmpty(
      property,
      const ['neighborhood_name', 'neighborhood', 'zone_name'],
    );

    if (neighborhood != null) {
      return '$typeLabel • $neighborhood';
    }

    return typeLabel;
  }

  String _propertyLocation(Map<String, dynamic> property) {
    final neighborhood = _firstNonEmpty(
      property,
      const ['neighborhood_name', 'neighborhood', 'zone_name'],
    );
    final district = _firstNonEmpty(
      property,
      const ['district_name', 'district', 'locality_name', 'locality'],
    );

    final parts = <String>[];
    if (neighborhood != null) {
      parts.add(neighborhood);
    }
    if (district != null) {
      parts.add(district);
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return 'Ubicacion por confirmar';
  }

  String? _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  List<String> _whyItMatches({
    required Map<String, dynamic> search,
    required Map<String, dynamic> property,
  }) {
    final reasons = <String>[];

    final price = _toNum(property['price']);
    final minPrice = _toNum(search['min_price']);
    final maxPrice = _toNum(search['max_price']);

    if (price != null) {
      final meetsMin = minPrice == null || price >= minPrice;
      final meetsMax = maxPrice == null || price <= maxPrice;
      if (meetsMin && meetsMax) {
        reasons.add('Precio');
      }
    }

    final rooms = property['rooms'] as int?;
    final minRooms = search['min_rooms'] as int?;
    if (rooms != null && minRooms != null && rooms >= minRooms) {
      reasons.add('Habitaciones');
    }

    final area = _toNum(property['area']);
    final minArea = _toNum(search['min_area']);
    final maxArea = _toNum(search['max_area']);
    if (area != null) {
      final meetsMin = minArea == null || area >= minArea;
      final meetsMax = maxArea == null || area <= maxArea;
      if (meetsMin && meetsMax) {
        reasons.add('Area');
      }
    }

    if (search['city_id'] != null ||
        search['district_id'] != null ||
        search['neighborhood_id'] != null) {
      reasons.add('Ubicacion');
    }

    if (reasons.isEmpty) {
      reasons.add('Perfil de busqueda');
    }

    return reasons;
  }

  String _typeLabel(String value) {
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

  String _areaLabel(Map<String, dynamic> property) {
    final area = _toNum(property['area']);
    if (area == null) {
      return 'Area n/d';
    }
    return '${area.toStringAsFixed(0)} m²';
  }

  String _roomsLabel(Map<String, dynamic> property) {
    final rooms = property['rooms'] as int?;
    return '${rooms ?? 0} hab';
  }

  String _bathroomsLabel(Map<String, dynamic> property) {
    final bathrooms = property['bathrooms'] as int?;
    return '${bathrooms ?? 0} banos';
  }

  double _normalizedScore(dynamic raw) {
    if (raw is num) {
      final value = raw <= 1 ? raw * 100 : raw.toDouble();
      return value.clamp(0, 100).toDouble();
    }
    return 0;
  }

  Color _compatibilityColor(double score) {
    if (score >= 90) {
      return AppColors.success;
    }
    if (score >= 80) {
      return AppColors.primary;
    }
    if (score >= 70) {
      return AppColors.warning;
    }
    return const Color(0xFFF87171);
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

class _CompatibilityCircle extends StatelessWidget {
  const _CompatibilityCircle({
    required this.score,
    required this.color,
    required this.scoreText,
  });

  final double score;
  final Color color;
  final String scoreText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  color: color,
                  backgroundColor: AppColors.border,
                ),
              ),
              Center(
                child: Text(
                  scoreText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Compatibilidad',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 46,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Aun no hay coincidencias',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Raices seguira buscando propiedades que coincidan contigo.\nTe notificaremos cuando encontremos nuevas coincidencias.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
