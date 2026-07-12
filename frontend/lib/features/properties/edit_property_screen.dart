import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_design_system.dart';
import 'properties_repository.dart';

class EditPropertyScreen extends StatefulWidget {
  const EditPropertyScreen({
    super.key,
    required this.token,
    required this.property,
    required this.repository,
  });

  final String token;
  final Map<String, dynamic> property;
  final PropertiesRepository repository;

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late String _intention;

  int? _cityId;
  int? _districtId;
  int? _neighborhoodId;

  List<Map<String, dynamic>> _cities = const [];
  List<Map<String, dynamic>> _districts = const [];
  List<Map<String, dynamic>> _neighborhoods = const [];

  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _parkingController = TextEditingController();
  final _stratumController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loadingCities = false;
  bool _loadingDistricts = false;
  bool _loadingNeighborhoods = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = (widget.property['type'] as String?) ?? 'apartment';
    _intention = (widget.property['intention'] as String?) ?? 'sale';

    _cityId = _asInt(widget.property['city_id']);
    _districtId = _asInt(widget.property['district_id']);
    _neighborhoodId = _asInt(widget.property['neighborhood_id']);

    _priceController.text = _asPriceString(widget.property['price']);
    _areaController.text = _asNumberString(widget.property['area']);
    _roomsController.text = _asNumberString(widget.property['rooms']);
    _bathroomsController.text = _asNumberString(widget.property['bathrooms']);
    _parkingController.text = _asNumberString(widget.property['parking_spots']);
    _stratumController.text = _asNumberString(widget.property['stratum']);
    _addressController.text = _asText(widget.property['address']);
    _descriptionController.text = _asText(widget.property['description']);

    _loadInitialGeography();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _parkingController.dispose();
    _stratumController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialGeography() async {
    setState(() {
      _loadingCities = true;
    });

    try {
      final cities = await widget.repository.loadCities(token: widget.token);
      if (!mounted) return;

      setState(() {
        _cities = cities.whereType<Map<String, dynamic>>().toList();
      });

      if (_cityId != null) {
        await _loadDistricts(_cityId!);
      }

      if (_districtId != null) {
        await _loadNeighborhoods(_districtId!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar geografia: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingCities = false;
        });
      }
    }
  }

  Future<void> _loadDistricts(int cityId) async {
    setState(() {
      _loadingDistricts = true;
    });

    try {
      final districts = await widget.repository.loadDistricts(
        token: widget.token,
        cityId: cityId,
      );
      if (!mounted) return;

      setState(() {
        _districts = districts.whereType<Map<String, dynamic>>().toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDistricts = false;
        });
      }
    }
  }

  Future<void> _loadNeighborhoods(int districtId) async {
    setState(() {
      _loadingNeighborhoods = true;
    });

    try {
      final neighborhoods = await widget.repository.loadNeighborhoods(
        token: widget.token,
        districtId: districtId,
      );
      if (!mounted) return;

      setState(() {
        _neighborhoods = neighborhoods.whereType<Map<String, dynamic>>().toList();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingNeighborhoods = false;
        });
      }
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
    await _loadDistricts(value);
  }

  Future<void> _onDistrictChanged(int? value) async {
    setState(() {
      _districtId = value;
      _neighborhoodId = null;
      _neighborhoods = const [];
    });

    if (value == null) return;
    await _loadNeighborhoods(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final propertyId = _resolvePropertyId(widget.property);
    if (propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble invalido')),
      );
      return;
    }

    if (_neighborhoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un barrio')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.repository.updateProperty(
        token: widget.token,
        propertyId: propertyId,
        body: {
          'type': _type,
          'intention': _intention,
          'description': _descriptionController.text.trim(),
          'stratum': _toInt(_stratumController.text) ?? 1,
          'neighborhood_id': _neighborhoodId,
          'address': _addressController.text.trim(),
          'rooms': _toInt(_roomsController.text) ?? 0,
          'bathrooms': _toInt(_bathroomsController.text) ?? 0,
          'parking_spots': _toInt(_parkingController.text) ?? 0,
          'price': _toNum(_priceController.text, allowThousands: true) ?? 0,
          'area': _toNum(_areaController.text) ?? 0,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble actualizado')),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Regresar',
                  ),
                  Text(
                    'Editar inmueble',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.section,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _SectionCard(
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _type,
                              decoration: const InputDecoration(labelText: 'Tipo de inmueble'),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      _SectionCard(
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _cityId,
                              decoration: InputDecoration(
                                labelText: _loadingCities ? 'Cargando ciudades...' : 'Ciudad',
                              ),
                              items: _cities
                                  .map(
                                    (city) => DropdownMenuItem<int>(
                                      value: _asInt(city['id']),
                                      child: Text('${city['name'] ?? ''}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _loadingCities ? null : _onCityChanged,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _districtId,
                              decoration: InputDecoration(
                                labelText: _loadingDistricts ? 'Cargando localidades...' : 'Localidad',
                              ),
                              items: _districts
                                  .map(
                                    (district) => DropdownMenuItem<int>(
                                      value: _asInt(district['id']),
                                      child: Text('${district['name'] ?? ''}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _cityId == null || _loadingDistricts ? null : _onDistrictChanged,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _neighborhoodId,
                              decoration: InputDecoration(
                                labelText: _loadingNeighborhoods ? 'Cargando barrios...' : 'Barrio',
                              ),
                              items: _neighborhoods
                                  .map(
                                    (neighborhood) => DropdownMenuItem<int>(
                                      value: _asInt(neighborhood['id']),
                                      child: Text('${neighborhood['name'] ?? ''}'),
                                    ),
                                  )
                                  .toList(),
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
                            _numberField(
                              _priceController,
                              'Precio',
                              currency: true,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              _areaController,
                              'Area',
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _numberField(_roomsController, 'Habitaciones', integer: true),
                            const SizedBox(height: 12),
                            _numberField(_bathroomsController, 'Baños', integer: true),
                            const SizedBox(height: 12),
                            _numberField(_parkingController, 'Parqueaderos', integer: true),
                            const SizedBox(height: 12),
                            _numberField(_stratumController, 'Estrato', integer: true),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(labelText: 'Direccion'),
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(labelText: 'Descripcion'),
                              minLines: 3,
                              maxLines: 5,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
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
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool integer = false,
    bool currency = false,
    String? Function(String?)? validator,
  }) {
    final inputFormatters = currency
        ? <TextInputFormatter>[_ThousandsSeparatorInputFormatter()]
        : integer
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : <TextInputFormatter>[];

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  String _asText(dynamic value) {
    if (value == null) return '';
    return '$value';
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  int? _resolvePropertyId(Map<String, dynamic> property) {
    final candidates = [
      property['id'],
      property['property_id'],
      property['propertyId'],
    ];

    for (final candidate in candidates) {
      final parsed = _asInt(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    final nested = property['property'];
    if (nested is Map<String, dynamic>) {
      final nestedId = _asInt(nested['id']) ?? _asInt(nested['property_id']);
      if (nestedId != null) {
        return nestedId;
      }
    }

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
