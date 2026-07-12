import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../theme/app_design_system.dart';
import 'contact_owner_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.property,
    this.isOwner = false,
    this.activeMatchesCount,
    this.compatibleSearches = const [],
    this.demandScore,
    this.onEditPressed,
    this.onDeletePressed,
  });

  final Map<String, dynamic> property;
  final bool isOwner;
  final int? activeMatchesCount;
  final List<Map<String, dynamic>> compatibleSearches;
  final double? demandScore;
  final Future<bool> Function()? onEditPressed;
  final Future<bool> Function()? onDeletePressed;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _descriptionExpanded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final photos = _extractPhotoUrls(property);

    final type = _typeLabel(property['type']);
    final intention = _intentionLabel(property['intention']);
    final price = _formatCop(_toNum(property['price']));
    final location = _locationLabel(property);
    final description = ((property['description'] as String?) ?? '').trim();
    final chips = _featureChips(property);
    final summary = _summaryItems(property);

    final compatible = _resolvedCompatibleSearches();
    final demand = _demandLabel(
      widget.demandScore,
      widget.activeMatchesCount,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: AppSpacing.section,
                bottom: 32,
              ),
              children: [
                _buildPhotoCarousel(photos),
                const SizedBox(height: AppSpacing.section),
                Text(
                  '$type · $intention',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                _SectionTitle(title: 'Resumen rapido'),
                const SizedBox(height: AppSpacing.medium),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final item = summary[index];
                    return _SummaryCard(
                      icon: item.icon,
                      label: item.label,
                      value: item.value,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.section),
                _SectionTitle(title: 'Descripcion'),
                const SizedBox(height: AppSpacing.small),
                _DescriptionBlock(
                  text: description,
                  expanded: _descriptionExpanded,
                  onToggle: () {
                    setState(() {
                      _descriptionExpanded = !_descriptionExpanded;
                    });
                  },
                ),
                
                const SizedBox(height: AppSpacing.section),
                _SectionTitle(title: 'Informacion adicional'),
                const SizedBox(height: AppSpacing.small),
                _InfoBlock(property: property),
                const SizedBox(height: AppSpacing.section),
                _SectionTitle(title: 'Coincidencias activas'),
                const SizedBox(height: AppSpacing.small),
                _MatchesBlock(
                  activeCount: widget.activeMatchesCount ?? compatible.length,
                  demandLabel: demand,
                  compatibleSearches: compatible,
                ),
                const SizedBox(height: AppSpacing.section),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.isOwner && widget.onEditPressed != null) {
                        final changed = await widget.onEditPressed!();
                        if (!mounted) {
                          return;
                        }
                        if (changed) {
                          Navigator.of(context).pop(true);
                        }
                        return;
                      }

                      if (!widget.isOwner) {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ContactOwnerScreen(property: property),
                          ),
                        );
                        return;
                      }

                      final label = widget.isOwner
                          ? 'Proximamente: editar inmueble'
                          : 'Proximamente: contactar propietario';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(label)),
                      );
                    },
                    child: Text(
                      widget.isOwner
                          ? 'Editar inmueble'
                          : 'Contactar propietario',
                    ),
                  ),
                ),
                if (widget.isOwner) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (widget.onDeletePressed == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proximamente: eliminar inmueble')),
                          );
                          return;
                        }

                        final deleted = await widget.onDeletePressed!();
                        if (!mounted) {
                          return;
                        }
                        if (deleted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: const Text('Eliminar inmueble'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F8FE), Color(0xFFE9EEFA)],
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.photo_library_outlined,
                size: 52,
                color: AppColors.textSecondary,
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _FloatingActionChip(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _FloatingTag(label: 'Sin fotos'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _FloatingActionChip(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _FloatingTag(label: '${_currentPage + 1}/${photos.length}'),
          ),
          if (_currentPage > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _FloatingActionChip(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentPage < photos.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _FloatingActionChip(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_SummaryItem> _summaryItems(Map<String, dynamic> property) {
    return [
      _SummaryItem(
        icon: Icons.square_foot_rounded,
        label: 'Area',
        value: _areaText(property['area']),
      ),
      _SummaryItem(
        icon: Icons.bed_rounded,
        label: 'Habitaciones',
        value: _countText(property['rooms']),
      ),
      _SummaryItem(
        icon: Icons.bathtub_outlined,
        label: 'Baños',
        value: _countText(property['bathrooms']),
      ),
      _SummaryItem(
        icon: Icons.directions_car_rounded,
        label: 'Parqueaderos',
        value: _countText(property['parking_spots']),
      ),
    ];
  }

  List<String> _featureChips(Map<String, dynamic> property) {
    final chips = <String>[];

    final features = property['features'];
    if (features is List) {
      for (final item in features) {
        if (item is String && item.trim().isNotEmpty) {
          chips.add(item.trim());
        }
      }
    }

    if (_isTrue(property['elevator'])) chips.add('Ascensor');
    if (_isTrue(property['pool'])) chips.add('Piscina');
    if (_isTrue(property['balcony'])) chips.add('Balcón');
    if (_isTrue(property['gym'])) chips.add('Gimnasio');

    return chips.toSet().toList();
  }

  List<Map<String, dynamic>> _resolvedCompatibleSearches() {
    if (widget.compatibleSearches.isNotEmpty) {
      return widget.compatibleSearches;
    }

    final fallback = widget.property['compatible_searches'];
    if (fallback is List) {
      return fallback.whereType<Map<String, dynamic>>().toList();
    }

    return const [];
  }

  List<String> _extractPhotoUrls(Map<String, dynamic> property) {
    final urls = <String>[];

    void addIfValid(dynamic rawUrl) {
      if (rawUrl is! String) {
        return;
      }
      final normalized = _normalizeUrl(rawUrl);
      if (normalized != null) {
        urls.add(normalized);
      }
    }

    void extractFromMap(Map<String, dynamic> map) {
      addIfValid(map['url']);
      addIfValid(map['secure_url']);
      addIfValid(map['photo_url']);
      addIfValid(map['image_url']);
      addIfValid(map['main_photo_url']);
      addIfValid(map['cover_photo_url']);
      addIfValid(map['src']);
      addIfValid(map['path']);

      final nested = map['photo'] ?? map['image'] ?? map['file'];
      if (nested is Map<String, dynamic>) {
        extractFromMap(nested);
      }
    }

    void extractFromDynamic(dynamic raw) {
      if (raw == null) {
        return;
      }

      if (raw is String) {
        final trimmed = raw.trim();
        if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
          try {
            final decoded = jsonDecode(trimmed);
            extractFromDynamic(decoded);
          } catch (_) {
            addIfValid(trimmed);
          }
          return;
        }
        addIfValid(trimmed);
        return;
      }

      if (raw is Map<String, dynamic>) {
        extractFromMap(raw);

        final containers = [
          raw['photos'],
          raw['images'],
          raw['items'],
          raw['results'],
          raw['data'],
        ];

        for (final container in containers) {
          extractFromDynamic(container);
        }
        return;
      }

      if (raw is List) {
        for (final item in raw) {
          extractFromDynamic(item);
        }
      }
    }

    addIfValid(property['main_photo_url']);
    addIfValid(property['cover_photo_url']);
    addIfValid(property['photo_url']);
    addIfValid(property['image_url']);
    addIfValid(property['url']);

    extractFromDynamic(property['main_photo']);
    extractFromDynamic(property['cover_photo']);
    extractFromDynamic(property['photo']);
    extractFromDynamic(property['images']);
    extractFromDynamic(property['photos']);

    return urls.toSet().toList();
  }

  String? _normalizeUrl(String raw) {
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

  String _locationLabel(Map<String, dynamic> property) {
    final neighborhood = _fieldAsString(
      property,
      const ['neighborhood_name', 'neighborhood', 'zone_name'],
    );
    final district = _fieldAsString(
      property,
      const ['district_name', 'district', 'locality_name'],
    );
    final city = _fieldAsString(property, const ['city_name', 'city']);

    final parts = <String>[];
    if (neighborhood.isNotEmpty) {
      parts.add(neighborhood);
    }
    if (district.isNotEmpty) {
      parts.add(district);
    }
    if (city.isNotEmpty) {
      parts.add(city);
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    final address = ((property['address'] as String?) ?? '').trim();
    if (address.isNotEmpty) {
      return address;
    }

    return 'Ubicacion por definir';
  }

  String _fieldAsString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _typeLabel(dynamic value) {
    switch ('$value') {
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

  String _intentionLabel(dynamic value) {
    switch ('$value') {
      case 'rent':
        return 'Arriendo';
      case 'sale':
      default:
        return 'Venta';
    }
  }

  String _areaText(dynamic value) {
    final numValue = _toNum(value);
    if (numValue == null || numValue <= 0) {
      return 'n/d';
    }
    return '${numValue.toStringAsFixed(0)} m²';
  }

  String _countText(dynamic value) {
    final parsed = _toNum(value);
    if (parsed == null) {
      return '0';
    }
    return parsed.toStringAsFixed(0);
  }

  num? _toNum(dynamic value) {
    if (value is int || value is double) {
      return value as num;
    }
    if (value is String) {
      return num.tryParse(value.trim().replaceAll('.', '').replaceAll(',', '.'));
    }
    return null;
  }

  bool _isTrue(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) {
      return value > 0;
    }
    return false;
  }

  String _formatCop(num? value) {
    if (value == null || value <= 0) {
      return 'Precio por definir';
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

  String _demandLabel(double? score, int? activeCount) {
    if (score != null) {
      if (score >= 85) {
        return 'Alta';
      }
      if (score >= 70) {
        return 'Media';
      }
      return 'Baja';
    }

    final count = activeCount ?? 0;
    if (count >= 10) {
      return 'Alta';
    }
    if (count >= 4) {
      return 'Media';
    }
    return 'Baja';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FloatingActionChip extends StatelessWidget {
  const _FloatingActionChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        12,
        AppSpacing.cardPadding,
        AppSpacing.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return _MutedCard(
        child: Text(
          'Sin descripcion disponible.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return _MutedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            maxLines: expanded ? null : 4,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (text.length > 140) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(expanded ? 'Ver menos' : 'Ver mas'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRowData>[
      _InfoRowData('Direccion', _text(property['address'])),
      _InfoRowData('Estrato', _text(property['stratum'])),
      _InfoRowData('Fecha de publicacion', _publishedAtText(property['published_at'])),
      _InfoRowData('Ciudad', _text(property['city_name'])),
      _InfoRowData('Localidad', _text(property['district_name'])),
      _InfoRowData('Barrio', _text(property['neighborhood_name'])),
    ]
        .where((row) => row.value != '-')
        .toList();

    if (rows.isEmpty) {
      return _MutedCard(
        child: Text(
          'No hay informacion adicional.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return _MutedCard(
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _text(dynamic value) {
    if (value == null) {
      return '-';
    }
    final asText = '$value'.trim();
    if (asText.isEmpty) {
      return '-';
    }
    return asText;
  }

  String _publishedAtText(dynamic value) {
    final raw = _text(value);
    if (raw == '-') {
      return raw;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}

class _InfoRowData {
  const _InfoRowData(this.label, this.value);

  final String label;
  final String value;
}

class _MatchesBlock extends StatelessWidget {
  const _MatchesBlock({
    required this.activeCount,
    required this.demandLabel,
    required this.compatibleSearches,
  });

  final int activeCount;
  final String demandLabel;
  final List<Map<String, dynamic>> compatibleSearches;

  @override
  Widget build(BuildContext context) {
    final hasCompatible = compatibleSearches.isNotEmpty;

    return _MutedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount activas',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Demanda $demandLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasCompatible)
            Text(
              'No hay busquedas compatibles listadas en este momento.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...compatibleSearches.take(4).map((search) {
              final type = _friendlyType(search['type']);
              final intention = _friendlyIntention(search['intention']);
              final city = (search['city_name'] ?? search['city'] ?? '').toString();

              final label = city.trim().isEmpty
                  ? '$type · $intention'
                  : '$type · $intention · $city';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _friendlyType(dynamic value) {
    switch ('$value') {
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

  String _friendlyIntention(dynamic value) {
    switch ('$value') {
      case 'rent':
        return 'Arriendo';
      case 'sale':
      default:
        return 'Venta';
    }
  }
}

class _MutedCard extends StatelessWidget {
  const _MutedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}
