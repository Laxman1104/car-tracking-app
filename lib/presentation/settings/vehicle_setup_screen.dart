import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/odometer/odometer_value.dart';
import '../theme/app_theme.dart';

class VehicleSetupData {
  const VehicleSetupData({
    required this.name,
    required this.startingOdometerKm,
    this.registrationNumber,
  });

  final String name;
  final double startingOdometerKm;
  final String? registrationNumber;
}

class FirstRunVehicleSetupScreen extends StatelessWidget {
  const FirstRunVehicleSetupScreen({super.key, required this.onConfirm});

  final ValueChanged<VehicleSetupData> onConfirm;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            42,
            24,
            32 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 74),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.directions_car_filled_outlined,
                  color: AppColors.teal,
                  size: 70,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start Tracking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Add your car details to create its starting baseline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 34),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: VehicleSetupForm(
                      title: 'Set up your vehicle',
                      submitLabel: 'Confirm vehicle',
                      onSubmit: onConfirm,
                    ),
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

class VehicleSetupForm extends StatefulWidget {
  const VehicleSetupForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.onCancel,
  });

  final String title;
  final String submitLabel;
  final ValueChanged<VehicleSetupData> onSubmit;
  final VoidCallback? onCancel;

  @override
  State<VehicleSetupForm> createState() => _VehicleSetupFormState();
}

class _VehicleSetupFormState extends State<VehicleSetupForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _registration = TextEditingController();
  final _odometer = TextEditingController(text: '0');

  @override
  void dispose() {
    _name.dispose();
    _registration.dispose();
    _odometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        TextFormField(
          key: const Key('new-vehicle-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Vehicle model'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Enter the vehicle model'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('new-vehicle-odometer'),
          controller: _odometer,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Current odometer',
            suffixText: 'km',
          ),
          validator: (value) {
            final parsed = parseOdometerKm(value ?? '');
            return parsed == null || parsed < 0
                ? 'Enter a valid odometer'
                : null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('new-vehicle-registration'),
          controller: _registration,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Registration number (optional)',
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'This odometer is only the starting baseline. It does not create a '
          'Fuel Event or Maintenance Record.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (widget.onCancel != null) ...[
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: widget.onCancel == null ? 1 : 2,
              child: FilledButton(
                key: const Key('continue-new-vehicle'),
                onPressed: _submit,
                child: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final registration = _registration.text.trim();
    widget.onSubmit(
      VehicleSetupData(
        name: _name.text.trim(),
        startingOdometerKm: parseOdometerKm(_odometer.text)!,
        registrationNumber: registration.isEmpty ? null : registration,
      ),
    );
  }
}
