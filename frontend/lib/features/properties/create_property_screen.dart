import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_design_system.dart';
import '../auth/auth_repository.dart';
import 'create_property_repository.dart';
import 'property_draft.dart';

class CreatePropertyScreen extends StatefulWidget {
  const CreatePropertyScreen({
    super.key,
    required this.authRepository,
    required this.token,
  });

  final AuthRepository authRepository;
  final String token;

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  static const int _totalSteps = 4;

  final _imagePicker = ImagePicker();
  final _basicInfoFormKey = GlobalKey<FormState>();

  late final CreatePropertyRepository _repository;

  int _currentStep = 1;
  bool _publishing = false;
  String? _publishError;

  final PropertyDraft _draft = PropertyDraft();
  List<GeographyOption> _cities = const [];
  List<GeographyOption> _districts = const [];
  List<GeographyOption> _neighborhoods = const [];
  bool _loadingCities = false;
  bool _loadingDistricts = false;
  bool _loadingNeighborhoods = false;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = CreatePropertyRepository(widget.authRepository.apiClient);
    _loadCities();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _loadingCities = true;
    });

    try {
      final options = await _repository.fetchCities(token: widget.token);
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = options;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar ciudades: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingCities = false;
        });
      }
    }
  }

  Future<void> _onCitySelected(int? cityId) async {
    setState(() {
      _draft.cityId = cityId;
      _draft.cityName = _nameById(_cities, cityId);
      _draft.districtId = null;
      _draft.districtName = null;
      _draft.neighborhoodId = null;
      _draft.neighborhoodName = null;
      _districts = const [];
      _neighborhoods = const [];
    });

    if (cityId == null) {
      return;
    }

    setState(() {
      _loadingDistricts = true;
    });

    try {
      final options = await _repository.fetchDistricts(
        token: widget.token,
        cityId: cityId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _districts = options;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar localidades: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingDistricts = false;
        });
      }
    }
  }

  Future<void> _onDistrictSelected(int? districtId) async {
    setState(() {
      _draft.districtId = districtId;
      _draft.districtName = _nameById(_districts, districtId);
      _draft.neighborhoodId = null;
      _draft.neighborhoodName = null;
      _neighborhoods = const [];
    });

    if (districtId == null) {
      return;
    }

    setState(() {
      _loadingNeighborhoods = true;
    });

    try {
      final options = await _repository.fetchNeighborhoods(
        token: widget.token,
        districtId: districtId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _neighborhoods = options;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar barrios: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingNeighborhoods = false;
        });
      }
    }
  }

  void _onNeighborhoodSelected(int? neighborhoodId) {
    setState(() {
      _draft.neighborhoodId = neighborhoodId;
      _draft.neighborhoodName = _nameById(_neighborhoods, neighborhoodId);
    });
  }

  String? _nameById(List<GeographyOption> options, int? id) {
    if (id == null) {
      return null;
    }
    for (final option in options) {
      if (option.id == id) {
        return option.name;
      }
    }
    return null;
  }

  void _goPreviousStep() {
    if (_currentStep == 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _currentStep -= 1;
      _publishError = null;
    });
  }

  Future<void> _goNextStep() async {
    final isValid = _validateCurrentStep();
    if (!isValid) {
      return;
    }

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep += 1;
        _publishError = null;
      });
      return;
    }

    await _publishProperty();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 1) {
      if (!_draft.hasStep1Completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona tipo de inmueble e intencion.'),
          ),
        );
        return false;
      }
      return true;
    }

    if (_currentStep == 2) {
      final valid = _basicInfoFormKey.currentState?.validate() ?? false;
      if (!valid) {
        return false;
      }
      if (!_draft.hasStep2Completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa toda la informacion basica.')),
        );
        return false;
      }
      return true;
    }

    return true;
  }

  Future<void> _pickPhotos() async {
    final remaining = 10 - _draft.photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximo 10 fotos.')),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );

    if (picked.isEmpty) {
      return;
    }

    setState(() {
      _draft.photos.addAll(picked.take(remaining));
    });
  }

  void _removePhotoAt(int index) {
    if (index < 0 || index >= _draft.photos.length) {
      return;
    }

    setState(() {
      _draft.photos.removeAt(index);
    });
  }

  Future<void> _publishProperty() async {
    setState(() {
      _publishing = true;
      _publishError = null;
    });

    try {
      await _repository.publishDraft(token: widget.token, draft: _draft);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inmueble publicado con exito')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _publishError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _publishing = false;
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
            _WizardHeader(currentStep: _currentStep, onBack: _goPreviousStep),
            const SizedBox(height: 6),
            _ProgressBar(currentStep: _currentStep),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.section,
                ),
                child: _buildStep(),
              ),
            ),
            _BottomActions(
              currentStep: _currentStep,
              isPublishing: _publishing,
              publishError: _publishError,
              onPrevious: _goPreviousStep,
              onNext: _goNextStep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _buildStepOne();
      case 2:
        return _buildStepTwo();
      case 3:
        return _buildStepThree();
      case 4:
      default:
        return _buildStepFour();
    }
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Que vas a publicar?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.section),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _TypeCard(
              label: 'Apartamento',
              icon: Icons.apartment_rounded,
              selected: _draft.propertyType == 'apartment',
              onTap: () => setState(() => _draft.propertyType = 'apartment'),
            ),
            _TypeCard(
              label: 'Casa',
              icon: Icons.house_rounded,
              selected: _draft.propertyType == 'house',
              onTap: () => setState(() => _draft.propertyType = 'house'),
            ),
            _TypeCard(
              label: 'Oficina',
              icon: Icons.business_center_rounded,
              selected: _draft.propertyType == 'office',
              onTap: () => setState(() => _draft.propertyType = 'office'),
            ),
            _TypeCard(
              label: 'Local',
              icon: Icons.storefront_rounded,
              selected: _draft.propertyType == 'commercial',
              onTap: () => setState(() => _draft.propertyType = 'commercial'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        Text('Intencion', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'Venta',
                selected: _draft.intention == 'sale',
                onTap: () => setState(() => _draft.intention = 'sale'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                label: 'Arriendo',
                selected: _draft.intention == 'rent',
                onTap: () => setState(() => _draft.intention = 'rent'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Form(
      key: _basicInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacion basica',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.section),
          DropdownButtonFormField<int>(
            key: ValueKey<String>('city-${_draft.cityId ?? 'none'}'),
            initialValue: _draft.cityId,
            decoration: const InputDecoration(labelText: 'Ciudad'),
            isExpanded: true,
            items: _cities
                .map(
                  (option) => DropdownMenuItem<int>(
                    value: option.id,
                    child: Text(option.name),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null) {
                return 'Selecciona una ciudad';
              }
              return null;
            },
            onChanged: _loadingCities ? null : _onCitySelected,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey<String>('district-${_draft.districtId ?? 'none'}'),
            initialValue: _draft.districtId,
            decoration: const InputDecoration(labelText: 'Localidad'),
            isExpanded: true,
            items: _districts
                .map(
                  (option) => DropdownMenuItem<int>(
                    value: option.id,
                    child: Text(option.name),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null) {
                return 'Selecciona una localidad';
              }
              return null;
            },
            onChanged:
                (_draft.cityId == null || _loadingDistricts)
                ? null
                : _onDistrictSelected,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey<String>(
              'neighborhood-${_draft.neighborhoodId ?? 'none'}',
            ),
            initialValue: _draft.neighborhoodId,
            decoration: const InputDecoration(labelText: 'Barrio'),
            isExpanded: true,
            items: _neighborhoods
                .map(
                  (option) => DropdownMenuItem<int>(
                    value: option.id,
                    child: Text(option.name),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null) {
                return 'Selecciona un barrio';
              }
              return null;
            },
            onChanged:
                (_draft.districtId == null || _loadingNeighborhoods)
                ? null
                : _onNeighborhoodSelected,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Direccion'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa la direccion';
              }
              return null;
            },
            onChanged: (value) => _draft.address = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
            inputFormatters: const [_CopCurrencyInputFormatter()],
            textInputAction: TextInputAction.next,
            validator: (value) {
              final parsed = _parseCurrencyInput(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Ingresa un precio valido';
              }
              return null;
            },
            onChanged: (value) => _draft.price = _parseCurrencyInput(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _areaController,
            decoration: const InputDecoration(labelText: 'Area m2'),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final parsed = num.tryParse((value ?? '').trim());
              if (parsed == null || parsed <= 0) {
                return 'Ingresa un area valida';
              }
              return null;
            },
            onChanged: (value) => _draft.area = num.tryParse(value.trim()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey<String>('stratum-${_draft.stratum}'),
            initialValue: _draft.stratum,
            decoration: const InputDecoration(labelText: 'Estrato'),
            isExpanded: true,
            items: const [1, 2, 3, 4, 5, 6]
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('Estrato $value'),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null || value <= 0) {
                return 'Selecciona un estrato';
              }
              return null;
            },
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _draft.stratum = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.section),
          _StepperField(
            label: 'Habitaciones',
            value: _draft.bedrooms,
            onDecrement: () {
              if (_draft.bedrooms == 0) {
                return;
              }
              setState(() => _draft.bedrooms -= 1);
            },
            onIncrement: () => setState(() => _draft.bedrooms += 1),
          ),
          const SizedBox(height: 12),
          _StepperField(
            label: 'Baños',
            value: _draft.bathrooms,
            onDecrement: () {
              if (_draft.bathrooms == 0) {
                return;
              }
              setState(() => _draft.bathrooms -= 1);
            },
            onIncrement: () => setState(() => _draft.bathrooms += 1),
          ),
          const SizedBox(height: 12),
          _StepperField(
            label: 'Parqueaderos',
            value: _draft.parkingSpots,
            onDecrement: () {
              if (_draft.parkingSpots == 0) {
                return;
              }
              setState(() => _draft.parkingSpots -= 1);
            },
            onIncrement: () => setState(() => _draft.parkingSpots += 1),
          ),
          const SizedBox(height: AppSpacing.section),
          TextFormField(
            controller: _descriptionController,
            maxLength: 500,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Descripcion'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa una descripcion';
              }
              return null;
            },
            onChanged: (value) => _draft.description = value,
          ),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.section),
        _UploadCard(
          currentCount: _draft.photos.length,
          onTap: _pickPhotos,
        ),
        if (_draft.photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          GridView.builder(
            itemCount: _draft.photos.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              return _PhotoTile(
                file: _draft.photos[index],
                isPrimary: index == 0,
                onRemove: () => _removePhotoAt(index),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStepFour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen', style: Theme.of(context).textTheme.headlineSmall),
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
              if (_draft.photos.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _DraftPhotoView(file: _draft.photos.first),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _SummaryLine(
                label: 'Tipo inmueble',
                value: _typeLabel(_draft.propertyType),
              ),
              _SummaryLine(
                label: 'Intencion',
                value: _intentionLabel(_draft.intention),
              ),
              _SummaryLine(
                label: 'Ubicacion',
                value:
                    '${_draft.cityName ?? '-'} - ${_draft.districtName ?? '-'} - ${_draft.neighborhoodName ?? '-'}',
              ),
              _SummaryLine(
                label: 'Direccion',
                value: _draft.address.trim().isEmpty ? '-' : _draft.address.trim(),
              ),
              _SummaryLine(
                label: 'Estrato',
                value: '${_draft.stratum}',
              ),
              _SummaryLine(
                label: 'Precio',
                value: _draft.price == null ? '-' : _formatCop(_draft.price!),
              ),
              _SummaryLine(
                label: 'Area',
                value: _draft.area == null ? '-' : '${_draft.area!.toStringAsFixed(0)} m2',
              ),
              _SummaryLine(label: 'Habitaciones', value: '${_draft.bedrooms}'),
              _SummaryLine(label: 'Baños', value: '${_draft.bathrooms}'),
              _SummaryLine(label: 'Parqueaderos', value: '${_draft.parkingSpots}'),
              _SummaryLine(
                label: 'Descripcion',
                value:
                    _draft.description.trim().isEmpty
                    ? '-'
                    : _draft.description.trim(),
              ),
              _SummaryLine(label: 'Fotos', value: '${_draft.photos.length}'),
            ],
          ),
        ),
      ],
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

  String _intentionLabel(String? value) {
    if (value == 'rent') {
      return 'Arriendo';
    }
    return 'Venta';
  }

  num? _parseCurrencyInput(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }
    return num.tryParse(digits);
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

    return buffer.toString().split('').reversed.join();
  }
}

class _CopCurrencyInputFormatter extends TextInputFormatter {
  const _CopCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatDigits(String digits) {
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();

    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }

    final value = buffer.toString().split('').reversed.join();
    return value;
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.currentStep, required this.onBack});

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Nuevo inmueble', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Publica una propiedad y comienza a recibir coincidencias.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Paso $currentStep/4',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Row(
        children: List.generate(4, (index) {
          final step = index + 1;
          final active = step <= currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
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
            color: selected ? const Color(0xFFFFF7E0) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: AppColors.textPrimary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF7E0) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.currentCount, required this.onTap});

  final int currentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.add_a_photo_rounded, size: 36, color: AppColors.primary),
              const SizedBox(height: 10),
              Text('Agregar fotografias', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Maximo 10 fotos. La primera sera la foto principal.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '$currentCount/10',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
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

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.file,
    required this.isPrimary,
    required this.onRemove,
  });

  final XFile file;
  final bool isPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DraftPhotoView(file: file),
          if (isPrimary)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Principal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftPhotoView extends StatelessWidget {
  const _DraftPhotoView({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: AppColors.background,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.background,
            child: const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.currentStep,
    required this.isPublishing,
    required this.publishError,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentStep;
  final bool isPublishing;
  final String? publishError;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isFinalStep = currentStep == 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (publishError != null) ...[
            Text(
              publishError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFEF4444),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isPublishing ? null : onPrevious,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPublishing ? null : onNext,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isPublishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isFinalStep ? 'Publicar inmueble' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
