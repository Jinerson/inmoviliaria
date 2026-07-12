import 'package:flutter/material.dart';

import '../../theme/app_design_system.dart';
import 'searches_repository.dart';

class SearchViewScreen extends StatefulWidget {
  const SearchViewScreen({
    super.key,
    required this.search,
    required this.cityName,
    required this.token,
    required this.repository,
  });

  final Map<String, dynamic> search;
  final String cityName;
  final String token;
  final SearchesRepository repository;

  @override
  State<SearchViewScreen> createState() => _SearchViewScreenState();
}

class _SearchViewScreenState extends State<SearchViewScreen> {
  String? _districtName;
  String? _neighborhoodName;

  @override
  void initState() {
    super.initState();
    _loadGeoNames();
  }

  Future<void> _loadGeoNames() async {
    final cityId = _asInt(widget.search['city_id']);
    final districtId = _asInt(widget.search['district_id']);
    final neighborhoodId = _asInt(widget.search['neighborhood_id']);

    String? districtName;
    String? neighborhoodName;

    if (cityId != null && districtId != null) {
      try {
        final districts = await widget.repository.loadDistricts(
          token: widget.token,
          cityId: cityId,
        );

        for (final item in districts) {
          if (item is Map<String, dynamic> && item['id'] == districtId) {
            districtName = item['name']?.toString();
            break;
          }
        }
      } catch (_) {
        // Keep fallback labels if lookup fails.
      }
    }

    if (districtId != null && neighborhoodId != null) {
      try {
        final neighborhoods = await widget.repository.loadNeighborhoods(
          token: widget.token,
          districtId: districtId,
        );

        for (final item in neighborhoods) {
          if (item is Map<String, dynamic> && item['id'] == neighborhoodId) {
            neighborhoodName = item['name']?.toString();
            break;
          }
        }
      } catch (_) {
        // Keep fallback labels if lookup fails.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _districtName = districtName;
      _neighborhoodName = neighborhoodName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = _propertyTypeLabel((widget.search['type'] as String?) ?? 'apartment');
    final intention = _intentionLabel((widget.search['intention'] as String?) ?? 'sale');
    final cityName = widget.cityName;

    final districtId = _asInt(widget.search['district_id']);
    final neighborhoodId = _asInt(widget.search['neighborhood_id']);

    final districtName = _districtName ??
        (districtId != null ? 'Localidad $districtId' : 'Sin localidad');
    final neighborhoodName = _neighborhoodName ??
        (neighborhoodId != null ? 'Barrio $neighborhoodId' : 'Sin barrio');

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
                const SizedBox(height: 4),
                Text(
                  'Detalle de busqueda',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Revisa todos los criterios configurados para esta busqueda.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$type · $intention',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(label: 'Ciudad', value: cityName),
                      _DetailRow(label: 'Localidad', value: districtName),
                      _DetailRow(label: 'Barrio', value: neighborhoodName),
                      _DetailRow(
                        label: 'Area',
                        value: _rangeLabel(
                          widget.search['min_area'],
                          widget.search['max_area'],
                          suffix: ' m2',
                        ),
                      ),
                      _DetailRow(
                        label: 'Precio',
                        value: _rangeLabel(
                          widget.search['min_price'],
                          widget.search['max_price'],
                          money: true,
                        ),
                      ),
                      _DetailRow(
                        label: 'Habitaciones',
                        value: _minimumLabel(widget.search['min_rooms']),
                      ),
                      _DetailRow(
                        label: 'Baños',
                        value: _minimumLabel(widget.search['min_bathrooms']),
                      ),
                      _DetailRow(
                        label: 'Parqueaderos',
                        value: _minimumLabel(widget.search['min_parking']),
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

  String _propertyTypeLabel(String value) {
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

  String _intentionLabel(String value) {
    switch (value) {
      case 'rent':
        return 'Arriendo';
      case 'sale':
      default:
        return 'Venta';
    }
  }

  String _minimumLabel(dynamic value) {
    final parsed = _toNum(value);
    if (parsed == null || parsed <= 0) {
      return 'Sin minimo';
    }
    return 'Desde ${parsed.toStringAsFixed(0)}';
  }

  String _rangeLabel(
    dynamic minValue,
    dynamic maxValue, {
    bool money = false,
    String suffix = '',
  }) {
    final minNum = _toNum(minValue);
    final maxNum = _toNum(maxValue);

    if (minNum == null && maxNum == null) {
      return 'Por definir';
    }

    final minText = minNum == null
        ? 'Sin minimo'
        : money
            ? _formatCop(minNum)
            : '${minNum.toStringAsFixed(0)}$suffix';
    final maxText = maxNum == null
        ? 'Sin maximo'
        : money
            ? _formatCop(maxNum)
            : '${maxNum.toStringAsFixed(0)}$suffix';

    return '$minText - $maxText';
  }

  num? _toNum(dynamic value) {
    if (value is int || value is double) {
      return value as num;
    }
    if (value is String) {
      return num.tryParse(value.trim());
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

  int? _asInt(dynamic value) {
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
