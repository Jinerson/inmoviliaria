import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_design_system.dart';
import 'searches_repository.dart';

class SearchEditScreen extends StatefulWidget {
  const SearchEditScreen({
    super.key,
    required this.token,
    required this.search,
    required this.repository,
    required this.cities,
  });

  final String token;
  final Map<String, dynamic> search;
  final SearchesRepository repository;
  final List<Map<String, dynamic>> cities;

  @override
  State<SearchEditScreen> createState() => _SearchEditScreenState();
}

class _SearchEditScreenState extends State<SearchEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late String _intention;
  int? _cityId;
  int? _districtId;
  int? _neighborhoodId;

  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();
  final _minRoomsController = TextEditingController();
  final _minBathroomsController = TextEditingController();
  final _minParkingController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  List<Map<String, dynamic>> _districts = const [];
  List<Map<String, dynamic>> _neighborhoods = const [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = (widget.search['type'] as String?) ?? 'apartment';
    _intention = (widget.search['intention'] as String?) ?? 'sale';
    _cityId = _asInt(widget.search['city_id']);
    _districtId = _asInt(widget.search['district_id']);
    _neighborhoodId = _asInt(widget.search['neighborhood_id']);

    _minAreaController.text = _asNumberString(widget.search['min_area']);
    _maxAreaController.text = _asNumberString(widget.search['max_area']);
    _minRoomsController.text = _asNumberString(widget.search['min_rooms']);
    _minBathroomsController.text = _asNumberString(widget.search['min_bathrooms']);
    _minParkingController.text = _asNumberString(widget.search['min_parking']);
    _minPriceController.text = _asPriceString(widget.search['min_price']);
    _maxPriceController.text = _asPriceString(widget.search['max_price']);

    _loadInitialGeo();
  }

  @override
  void dispose() {
    _minAreaController.dispose();
    _maxAreaController.dispose();
    _minRoomsController.dispose();
    _minBathroomsController.dispose();
    _minParkingController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialGeo() async {
    if (_cityId != null) {
      final districts = await widget.repository.loadDistricts(
        token: widget.token,
        cityId: _cityId!,
      );
      if (!mounted) return;
      setState(() {
        _districts = districts.whereType<Map<String, dynamic>>().toList();
      });
    }

    if (_districtId != null) {
      final neighborhoods = await widget.repository.loadNeighborhoods(
        token: widget.token,
        districtId: _districtId!,
      );
      if (!mounted) return;
      setState(() {
        _neighborhoods = neighborhoods.whereType<Map<String, dynamic>>().toList();
      });
    }
  }

  Future<void> _onCityChanged(int? value) async {
    setState(() {
      _cityId = value;
      _districtId = null;
      _neighborhoodId = null;
      _districts = const [];
      _neighborhoods = const [];
    });

    if (value == null) return;

    final districts = await widget.repository.loadDistricts(
      token: widget.token,
      cityId: value,
    );

    if (!mounted) return;
    setState(() {
      _districts = districts.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<void> _onDistrictChanged(int? value) async {
    setState(() {
      _districtId = value;
      _neighborhoodId = null;
      _neighborhoods = const [];
    });

    if (value == null) return;

    final neighborhoods = await widget.repository.loadNeighborhoods(
      token: widget.token,
      districtId: value,
    );

    if (!mounted) return;
    setState(() {
      _neighborhoods = neighborhoods.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final searchId = _asInt(widget.search['id']);
    if (searchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busqueda invalida')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.repository.updateSearch(
        token: widget.token,
        searchId: searchId,
        body: {
          'type': _type,
          'intention': _intention,
          'min_area': _toNum(_minAreaController.text),
          'max_area': _toNum(_maxAreaController.text),
          'min_rooms': _toInt(_minRoomsController.text),
          'min_bathrooms': _toInt(_minBathroomsController.text),
          'min_parking': _toInt(_minParkingController.text),
          'min_price': _toNum(_minPriceController.text, allowThousands: true),
          'max_price': _toNum(_maxPriceController.text, allowThousands: true),
          'city_id': _cityId,
          'district_id': _districtId,
          'neighborhood_id': _neighborhoodId,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Busqueda actualizada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
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
                    'Editar busqueda',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Actualiza los criterios de tu busqueda.',
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
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(value: 'apartment', child: Text('Apartamento')),
                            DropdownMenuItem(value: 'house', child: Text('Casa')),
                            DropdownMenuItem(value: 'office', child: Text('Oficina')),
                            DropdownMenuItem(value: 'commercial', child: Text('Local')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _type = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _intention,
                          decoration: const InputDecoration(labelText: 'Intencion'),
                          items: const [
                            DropdownMenuItem(value: 'sale', child: Text('Venta')),
                            DropdownMenuItem(value: 'rent', child: Text('Arriendo')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _intention = value);
                          },
                        ),
                        const SizedBox(height: 12),
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
                          onChanged: _onCityChanged,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _districtId,
                          decoration: const InputDecoration(labelText: 'Localidad'),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._districts.map(
                              (district) => DropdownMenuItem<int>(
                                value: _asInt(district['id']),
                                child: Text('${district['name'] ?? ''}'),
                              ),
                            ),
                          ],
                          onChanged: _cityId == null ? null : _onDistrictChanged,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _neighborhoodId,
                          decoration: const InputDecoration(labelText: 'Barrio'),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._neighborhoods.map(
                              (neighborhood) => DropdownMenuItem<int>(
                                value: _asInt(neighborhood['id']),
                                child: Text('${neighborhood['name'] ?? ''}'),
                              ),
                            ),
                          ],
                          onChanged: _districtId == null
                              ? null
                              : (value) => setState(() => _neighborhoodId = value),
                        ),
                        const SizedBox(height: 12),
                        _numberField(_minAreaController, 'Area minima'),
                        const SizedBox(height: 12),
                        _numberField(_maxAreaController, 'Area maxima'),
                        const SizedBox(height: 12),
                        _numberField(_minRoomsController, 'Min. habitaciones', integer: true),
                        const SizedBox(height: 12),
                        _numberField(_minBathroomsController, 'Min. baños', integer: true),
                        const SizedBox(height: 12),
                        _numberField(_minParkingController, 'Min. parqueaderos', integer: true),
                        const SizedBox(height: 12),
                        _numberField(
                          _minPriceController,
                          'Precio minimo',
                          currencyFormat: true,
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          _maxPriceController,
                          'Precio maximo',
                          currencyFormat: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool integer = false,
    bool currencyFormat = false,
  }) {
    final inputFormatters = currencyFormat
        ? <TextInputFormatter>[_ThousandsSeparatorInputFormatter()]
        : integer
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : <TextInputFormatter>[];

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
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

  String _asNumberString(dynamic value) {
    if (value == null) return '';
    if (value is int) return '$value';
    if (value is double) return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return '$value';
  }

  String _asPriceString(dynamic value) {
    final raw = _asNumberString(value);
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }
    return _formatThousands(digits);
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
