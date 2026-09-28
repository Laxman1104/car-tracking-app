import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/fuel/create_fuel_event.dart';
import '../../domain/validation/scaled_decimal.dart';
import '../theme/app_theme.dart';

typedef FuelEventSaved = void Function(int eventId);

class FuelEventFormScreen extends StatefulWidget {
  const FuelEventFormScreen({
    super.key,
    required this.vehicleId,
    required this.createFuelEvent,
    this.initialOccurredAt,
    this.onSaved,
  });

  final int vehicleId;
  final CreateFuelEvent createFuelEvent;
  final DateTime? initialOccurredAt;
  final FuelEventSaved? onSaved;

  @override
  State<FuelEventFormScreen> createState() => _FuelEventFormScreenState();
}

class _FuelEventFormScreenState extends State<FuelEventFormScreen> {
  static const _brands = <_FuelBrandChoice>[
    _FuelBrandChoice('PETRONAS', 'assets/fuel_brands/Petronas.png'),
    _FuelBrandChoice('Shell', 'assets/fuel_brands/Shell.png'),
    _FuelBrandChoice('Petron', 'assets/fuel_brands/Petron.png'),
    _FuelBrandChoice('Caltex', 'assets/fuel_brands/cultex.png'),
    _FuelBrandChoice('BHPetrol', 'assets/fuel_brands/bhp.png'),
    _FuelBrandChoice('Other', null),
  ];

  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _litresController = TextEditingController();
  final _costController = TextEditingController();
  final _tripBController = TextEditingController();

  late DateTime _occurredAt;
  String? _selectedBrand;
  bool? _isFullTank;
  String? _brandError;
  String? _fullTankError;
  String? _chronologyError;
  int? _tripDifferenceMetres;
  int _comparisonRequest = 0;
  bool _isSaving = false;

  bool get _showZeroCostCaution {
    final parsed = ScaledDecimalParser.parse(
      _costController.text,
      fractionDigits: 2,
    );
    return _costController.text.trim().isNotEmpty && parsed == 0;
  }

  @override
  void initState() {
    super.initState();
    _occurredAt = widget.initialOccurredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _litresController.dispose();
    _costController.dispose();
    _tripBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Fuel Event')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _FieldLabel(label: 'Current odometer', required: true),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('fuel-odometer-field'),
                controller: _odometerController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Enter current reading',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                onChanged: (_) {
                  if (_chronologyError != null) {
                    setState(() => _chronologyError = null);
                  }
                  _refreshTripComparison();
                },
                validator: (value) {
                  if (_chronologyError != null) return _chronologyError;
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a whole odometer reading.';
                  if (parsed < 0) return 'Odometer cannot be negative.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _FieldLabel(
                label: 'Fuel brand',
                required: true,
                trailing: _brandError == null ? 'Tap to select' : null,
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _brands.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.02,
                ),
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  return _BrandTile(
                    choice: brand,
                    selected: _selectedBrand == brand.name,
                    onTap: () => setState(() {
                      _selectedBrand = brand.name;
                      _brandError = null;
                    }),
                  );
                },
              ),
              if (_brandError != null) ...[
                const SizedBox(height: 8),
                _InlineMessage.error(_brandError!),
              ],
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Litres added', required: true),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('fuel-litres-field'),
                controller: _litresController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_DecimalInputFormatter(3)],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '0.000',
                  suffixText: 'L',
                ),
                validator: (value) {
                  final parsed = ScaledDecimalParser.parse(
                    value ?? '',
                    fractionDigits: 3,
                  );
                  if (parsed == null) {
                    return 'Enter litres using up to 3 decimal places.';
                  }
                  if (parsed <= 0) return 'Litres must be greater than 0.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Total fuel cost', required: true),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('fuel-cost-field'),
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_DecimalInputFormatter(2)],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: 'RM ',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final parsed = ScaledDecimalParser.parse(
                    value ?? '',
                    fractionDigits: 2,
                  );
                  if (parsed == null) {
                    return 'Enter a cost using up to 2 decimal places.';
                  }
                  return null;
                },
              ),
              if (_showZeroCostCaution) ...[
                const SizedBox(height: 8),
                const _InlineMessage.caution(
                  'Fuel cost is RM0.00 — please confirm this is correct.',
                  key: Key('zero-cost-caution'),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Full tank?', required: true),
                    const SizedBox(height: 4),
                    const Text(
                      'Filled to the pump’s first automatic click',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        key: const Key('full-tank-control'),
                        segments: const [
                          ButtonSegment(value: true, label: Text('Yes')),
                          ButtonSegment(value: false, label: Text('No')),
                        ],
                        selected: _isFullTank == null
                            ? const <bool>{}
                            : {_isFullTank!},
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) => setState(() {
                          _isFullTank = selection.single;
                          _fullTankError = null;
                        }),
                      ),
                    ),
                    if (_fullTankError != null) ...[
                      const SizedBox(height: 8),
                      _InlineMessage.error(_fullTankError!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Trip B', trailing: 'Optional'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('fuel-trip-b-field'),
                controller: _tripBController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_DecimalInputFormatter(3)],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Leave blank if not used',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                onChanged: (_) => _refreshTripComparison(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (ScaledDecimalParser.parse(value, fractionDigits: 3) ==
                      null) {
                    return 'Enter Trip B using up to 3 decimal places.';
                  }
                  return null;
                },
              ),
              if (_tripDifferenceMetres case final difference?) ...[
                const SizedBox(height: 8),
                _InlineMessage.caution(
                  'Mismatch detected — Difference of '
                  '${_formatKilometres(difference)} km',
                  key: const Key('trip-b-mismatch'),
                ),
              ],
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Date & time', required: true),
              const SizedBox(height: 8),
              InkWell(
                key: const Key('fuel-date-time-field'),
                borderRadius: BorderRadius.circular(12),
                onTap: _pickOccurrence,
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OCCURRENCE',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDateTime(_occurredAt),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const Key('save-fuel-event-button'),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Saving…' : 'Save Fuel Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshTripComparison() async {
    final request = ++_comparisonRequest;
    final odometer = int.tryParse(_odometerController.text.trim());
    final tripMetres = ScaledDecimalParser.parse(
      _tripBController.text,
      fractionDigits: 3,
    );
    if (odometer == null || tripMetres == null) {
      if (mounted && _tripDifferenceMetres != null) {
        setState(() => _tripDifferenceMetres = null);
      }
      return;
    }

    final difference = await widget.createFuelEvent.tripBDifferenceMetres(
      vehicleId: widget.vehicleId,
      occurredAt: _occurredAt,
      odometerKm: odometer,
      tripDistanceMetres: tripMetres,
    );
    if (!mounted || request != _comparisonRequest) return;
    setState(() {
      _tripDifferenceMetres = difference == null || difference == 0
          ? null
          : difference;
    });
  }

  Future<void> _pickOccurrence() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _chronologyError = null;
    });
    await _refreshTripComparison();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _brandError = _selectedBrand == null ? 'Choose a fuel brand.' : null;
      _fullTankError = _isFullTank == null
          ? 'Choose Yes or No for Full tank.'
          : null;
    });
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || _brandError != null || _fullTankError != null) return;

    setState(() => _isSaving = true);
    try {
      final eventId = await widget.createFuelEvent(
        FuelEventInput(
          vehicleId: widget.vehicleId,
          occurredAt: _occurredAt,
          odometerKm: int.parse(_odometerController.text.trim()),
          fuelBrand: _selectedBrand!,
          fuelVolumeMillilitres: ScaledDecimalParser.parse(
            _litresController.text,
            fractionDigits: 3,
          )!,
          costSen: ScaledDecimalParser.parse(
            _costController.text,
            fractionDigits: 2,
          )!,
          isFullTank: _isFullTank!,
          tripDistanceMetres: _tripBController.text.trim().isEmpty
              ? null
              : ScaledDecimalParser.parse(
                  _tripBController.text,
                  fractionDigits: 3,
                ),
        ),
      );
      if (!mounted) return;
      if (widget.onSaved case final callback?) {
        callback(eventId);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Fuel event saved.')));
        await Navigator.of(context).maybePop();
      }
    } on CreateFuelEventException catch (error) {
      if (!mounted) return;
      if (error.issue == CreateFuelEventIssue.odometerChronologyConflict) {
        setState(() => _chronologyError = error.message);
        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the fuel event.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _FuelBrandChoice {
  const _FuelBrandChoice(this.name, this.assetPath);

  final String name;
  final String? assetPath;
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _FuelBrandChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.name} fuel brand',
      child: InkWell(
        key: Key('fuel-brand-${choice.name.toLowerCase()}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceStrong : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 44,
                        child: choice.assetPath == null
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceStrong,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.more_horiz),
                              )
                            : Image.asset(
                                choice.assetPath!,
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          choice.name,
                          style: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 7,
                  right: 7,
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFFAFC6FF),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    this.required = false,
    this.trailing,
  });

  final String label;
  final bool required;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.teal,
              fontWeight: FontWeight.w700,
            ),
          ),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage.caution(this.message, {super.key})
    : color = AppColors.warning,
      icon = Icons.warning_amber_rounded;

  const _InlineMessage.error(this.message)
    : color = AppColors.error,
      icon = Icons.error_outline;

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter(this.fractionDigits);

  final int fractionDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final pattern = RegExp('^\\d*(?:\\.\\d{0,$fractionDigits})?\$');
    return pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

String _formatKilometres(int metres) {
  if (metres % 1000 == 0) return '${metres ~/ 1000}';
  return (metres / 1000)
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year} · '
      '$hour:$minute';
}
