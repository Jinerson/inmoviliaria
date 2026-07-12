import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_design_system.dart';
import 'searches_repository.dart';

class CreateSearchScreen extends StatefulWidget {
  const CreateSearchScreen({
    super.key,
    required this.token,
    required this.repository,
    required this.cities,
  });

  final String token;
  final SearchesRepository repository;
  final List<Map<String, dynamic>> cities;

  @override
  State<CreateSearchScreen> createState() => _CreateSearchScreenState();
}

class _CreateSearchScreenState extends State<CreateSearchScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'apartment';
  String _intention = 'sale';

  int? _cityId;
  int? _districtId;
  int? _neighborhoodId;

  List<Map<String, dynamic>> _districts = const [];
  List<Map<String, dynamic>> _neighborhoods = const [];

  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _parkingController = TextEditingController();

  bool _loadingDistricts = false;
  bool _loadingNeighborhoods = false;
  bool _submitting = false;

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _parkingController.dispose();
    super.dispose();
  }

  Future<void> _onCitySelected(int? value) async {
    setState(() {
      _cityId = value;
      _districtId = null;
      _neighborhoodId = null;
      _districts = const [];
      _neighborhoods = const [];
    });

    if (value == null) {
      return;
    }

    setState(() {
      _loadingDistricts = true;
    });

    try {
      final payload = await widget.repository.loadDistricts(
        token: widget.token,
        cityId: value,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _districts = payload.whereType<Map<String, dynamic>>().toList();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar localidades: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingDistricts = false;
        });
      }
    }
  }

  Future<void> _onDistrictSelected(int? value) async {
    setState(() {
      _districtId = value;
      _neighborhoodId = null;
      _neighborhoods = const [];
    });

    if (value == null) {
      return;
    }

    setState(() {
      _loadingNeighborhoods = true;
    });

    try {
      final payload = await widget.repository.loadNeighborhoods(
        token: widget.token,
        districtId: value,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _neighborhoods = payload.whereType<Map<String, dynamic>>().toList();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar barrios: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingNeighborhoods = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ciudad')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.repository.createSearch(
        token: widget.token,
        body: {
          'type': _type,
          'intention': _intention,
          'city_id': _cityId,
          'district_id': _districtId,
          'neighborhood_id': _neighborhoodId,
          'min_price': _toNum(_minBudgetController.text, allowThousands: true),
          'max_price': _toNum(_maxBudgetController.text, allowThousands: true),
          'min_area': _toNum(_minAreaController.text),
          'max_area': _toNum(_maxAreaController.text),
          'min_rooms': _toInt(_roomsController.text),
          'min_bathrooms': _toInt(_bathroomsController.text),
          'min_parking': _toInt(_parkingController.text),
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busqueda creada con exito')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la busqueda: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _CreateSearchHeader(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.section,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva busqueda',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configura tus criterios y Raices encontrara coincidencias por ti.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de inmueble',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                              children: [
                                _TypeCard(
                                  label: 'Apartamento',
                                  icon: Icons.apartment_rounded,
                                  selected: _type == 'apartment',
                                  onTap: () => setState(() => _type = 'apartment'),
                                ),
                                _TypeCard(
                                  label: 'Casa',
                                  icon: Icons.house_rounded,
                                  selected: _type == 'house',
                                  onTap: () => setState(() => _type = 'house'),
                                ),
                                _TypeCard(
                                  label: 'Oficina',
                                  icon: Icons.business_center_rounded,
                                  selected: _type == 'office',
                                  onTap: () => setState(() => _type = 'office'),
                                ),
                                _TypeCard(
                                  label: 'Local',
                                  icon: Icons.storefront_rounded,
                                  selected: _type == 'commercial',
                                  onTap: () => setState(() => _type = 'commercial'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.section),
                            Text(
                              'Intencion',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ChoicePill(
                                    label: 'Comprar',
                                    selected: _intention == 'sale',
                                    onTap: () => setState(() => _intention = 'sale'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ChoicePill(
                                    label: 'Arrendar',
                                    selected: _intention == 'rent',
                                    onTap: () => setState(() => _intention = 'rent'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      _SectionCard(
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _cityId,
                              decoration: const InputDecoration(labelText: 'Ciudad'),
                              items: widget.cities
                                  .map(
                                    (city) => DropdownMenuItem<int>(
                                      value: _asInt(city['id']),
                                      child: Text('${city['name'] ?? ''}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onCitySelected,
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _districtId,
                              decoration: InputDecoration(
                                labelText: _loadingDistricts ? 'Cargando localidades...' : 'Localidad',
                              ),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('Todos')),
                                ..._districts.map(
                                  (district) => DropdownMenuItem<int>(
                                    value: _asInt(district['id']),
                                    child: Text('${district['name'] ?? ''}'),
                                  ),
                                ),
                              ],
                              onChanged: _cityId == null || _loadingDistricts ? null : _onDistrictSelected,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _neighborhoodId,
                              decoration: InputDecoration(
                                labelText: _loadingNeighborhoods ? 'Cargando barrios...' : 'Barrio',
                              ),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('Todos')),
                                ..._neighborhoods.map(
                                  (neighborhood) => DropdownMenuItem<int>(
                                    value: _asInt(neighborhood['id']),
                                    child: Text('${neighborhood['name'] ?? ''}'),
                                  ),
                                ),
                              ],
                              onChanged: _districtId == null || _loadingNeighborhoods
                                  ? null
                                  : (value) => setState(() => _neighborhoodId = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      _SectionCard(
                        child: Column(
                          children: [
                            _numberInput(
                              controller: _minBudgetController,
                              label: 'Presupuesto minimo',
                              currency: true,
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _maxBudgetController,
                              label: 'Presupuesto maximo',
                              currency: true,
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _minAreaController,
                              label: 'Area minima',
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _maxAreaController,
                              label: 'Area maxima',
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _roomsController,
                              label: 'Habitaciones',
                              integer: true,
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _bathroomsController,
                              label: 'Baños',
                              integer: true,
                            ),
                            const SizedBox(height: 12),
                            _numberInput(
                              controller: _parkingController,
                              label: 'Parqueaderos',
                              integer: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Crear busqueda'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberInput({
    required TextEditingController controller,
    required String label,
    bool integer = false,
    bool currency = false,
  }) {
    final inputFormatters = currency
        ? <TextInputFormatter>[_ThousandsSeparatorInputFormatter()]
        : integer
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : <TextInputFormatter>[];

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      inputFormatters: inputFormatters,
      validator: (_) => null,
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  int? _toInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  double? _toNum(String value, {bool allowThousands = false}) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final normalized = allowThousands ? text.replaceAll('.', '') : text;
    return double.tryParse(normalized);
  }
}

class _CreateSearchHeader extends StatelessWidget {
  const _CreateSearchHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Regresar',
          ),
          Text(
            'Crear busqueda',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary.withValues(alpha: 0.35) : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.textPrimary),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _formatThousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatThousands(String digits) {
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    return buffer.toString().split('').reversed.join();
  }
}
