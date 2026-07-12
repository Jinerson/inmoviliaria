import 'package:flutter/material.dart';

import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../properties/properties_screen.dart';
import '../results/results_repository.dart';
import '../results/results_screen.dart';
import 'create_search_screen.dart';
import 'search_edit_screen.dart';
import 'search_view_screen.dart';
import 'searches_repository.dart';

class SearchesScreen extends StatefulWidget {
  const SearchesScreen({
    super.key,
    required this.authRepository,
    required this.token,
  });

  final AuthRepository authRepository;
  final String token;

  @override
  State<SearchesScreen> createState() => _SearchesScreenState();
}

class _SearchesScreenState extends State<SearchesScreen> {
  late final SearchesRepository _repository;

  bool _loading = true;
  String? _error;
  int _tabIndex = 1;

  List<Map<String, dynamic>> _searches = const [];
  List<Map<String, dynamic>> _results = const [];
  Map<int, String> _citiesById = const {};

  @override
  void initState() {
    super.initState();
    _repository = SearchesRepository(widget.authRepository.apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = await _repository.loadSearchesData(widget.token);

      final searches = (payload['searches'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      final results = (payload['results'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      final cities = (payload['cities'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      final cityMap = <int, String>{};
      for (final city in cities) {
        final id = city['id'];
        final name = city['name'];
        if (id is int && name is String) {
          cityMap[id] = name;
        }
      }

      setState(() {
        _searches = searches;
        _results = results;
        _citiesById = cityMap;
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

  Future<void> _openCreateSearch() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateSearchScreen(
          token: widget.token,
          repository: _repository,
          cities: _citiesById.entries
              .map((entry) => {'id': entry.key, 'name': entry.value})
              .toList(),
        ),
      ),
    );

    if (created == true && mounted) {
      await _loadData();
    }
  }

  void _openSearchDetail(Map<String, dynamic> search) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          token: widget.token,
          search: search,
          cityName: _cityName(search),
          repository: ResultsRepository(widget.authRepository.apiClient),
        ),
      ),
    );
  }

  void _openSearchView(Map<String, dynamic> search) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchViewScreen(
          search: search,
          cityName: _cityName(search),
          token: widget.token,
          repository: _repository,
        ),
      ),
    );
  }

  Future<void> _openSearchEdit(Map<String, dynamic> search) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SearchEditScreen(
          token: widget.token,
          search: search,
          repository: _repository,
          cities: _citiesById.entries
              .map((entry) => {'id': entry.key, 'name': entry.value})
              .toList(),
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteSearch(Map<String, dynamic> search) async {
    final searchId = search['id'];
    if (searchId is! int) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar busqueda'),
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
      return;
    }

    try {
      await _repository.deleteSearch(token: widget.token, searchId: searchId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busqueda eliminada')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  Future<void> _showSearchOptions(Map<String, dynamic> search) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Ver'),
                onTap: () => Navigator.of(context).pop('view'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Eliminar'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == 'view') {
      _openSearchView(search);
      return;
    }

    if (action == 'edit') {
      await _openSearchEdit(search);
      return;
    }

    if (action == 'delete') {
      await _deleteSearch(search);
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
                'No pudimos cargar tus busquedas',
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
                          'Mis busquedas',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Administra las busquedas que has creado.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CreateSearchButton(onTap: _openCreateSearch),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              if (_searches.isEmpty)
                _EmptyState(onCreateTap: _openCreateSearch)
              else
                ..._searches.map(
                  (search) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _SearchCard(
                      search: search,
                      newMatches: _newMatchesForSearch(
                        searchId: search['id'] as int?,
                      ),
                      cityName: _cityName(search),
                      onTap: () => _openSearchDetail(search),
                      onOptionsTap: () => _showSearchOptions(search),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _newMatchesForSearch({required int? searchId}) {
    if (searchId == null) {
      return 0;
    }

    return _results.where((item) {
      final isSameSearch = item['search_id'] == searchId;
      final notified = item['notified'] == true;
      return isSameSearch && !notified;
    }).length;
  }

  String _cityName(Map<String, dynamic> search) {
    final cityId = search['city_id'];
    if (cityId is int && _citiesById.containsKey(cityId)) {
      return _citiesById[cityId]!;
    }

    final districtId = search['district_id'];
    final neighborhoodId = search['neighborhood_id'];

    if (districtId is int) {
      return 'Sector $districtId';
    }
    if (neighborhoodId is int) {
      return 'Zona $neighborhoodId';
    }

    return 'Ubicacion por definir';
  }
}

class _CreateSearchButton extends StatelessWidget {
  const _CreateSearchButton({required this.onTap});

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

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.search,
    required this.newMatches,
    required this.cityName,
    required this.onTap,
    required this.onOptionsTap,
  });

  final Map<String, dynamic> search;
  final int newMatches;
  final String cityName;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final type = (search['type'] as String?) ?? 'apartment';
    final intention = (search['intention'] as String?) ?? 'sale';

    final typeLabel = _propertyTypeLabel(type);
    final intentionLabel = _intentionLabel(intention);

    final minRooms = search['min_rooms'] as int?;
    final minBathrooms = search['min_bathrooms'] as int?;
    final minPrice = _toNum(search['min_price']);
    final maxPrice = _toNum(search['max_price']);

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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _propertyTypeIcon(type),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onOptionsTap,
                    icon: const Icon(Icons.more_vert_rounded),
                    color: AppColors.textSecondary,
                    tooltip: 'Opciones',
                  ),
                ],
              ),
              Text(
                typeLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                intentionLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(cityName, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text(
                _featuresLabel(minRooms: minRooms, minBathrooms: minBathrooms),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _priceLabel(minPrice: minPrice, maxPrice: maxPrice),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _matchesStatus(context, newMatches: newMatches),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchesStatus(BuildContext context, {required int newMatches}) {
    if (newMatches > 0) {
      final label = newMatches == 1
          ? '1 coincidencia nueva'
          : '$newMatches coincidencias nuevas';

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Text(
      'Sin novedades',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _propertyTypeIcon(String value) {
    switch (value) {
      case 'house':
        return Icons.house_rounded;
      case 'office':
        return Icons.business_center_rounded;
      case 'commercial':
        return Icons.storefront_rounded;
      case 'apartment':
      default:
        return Icons.apartment_rounded;
    }
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
        return 'Arrendar';
      case 'sale':
      default:
        return 'Comprar';
    }
  }

  String _featuresLabel({required int? minRooms, required int? minBathrooms}) {
    final parts = <String>[];

    if (minRooms != null) {
      parts.add('$minRooms hab');
    }
    if (minBathrooms != null) {
      parts.add('$minBathrooms baños');
    }

    if (parts.isEmpty) {
      return 'Caracteristicas por definir';
    }

    return parts.join(' • ');
  }

  String _priceLabel({required num? minPrice, required num? maxPrice}) {
    if (minPrice == null && maxPrice == null) {
      return 'Rango de precio por definir';
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
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aun no tienes busquedas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una busqueda y Raices encontrara propiedades que coincidan contigo.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onCreateTap,
            child: const Text('Nueva busqueda'),
          ),
        ],
      ),
    );
  }
}
