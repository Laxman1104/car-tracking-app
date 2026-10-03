import 'package:flutter/material.dart';

import '../../application/fuel/create_fuel_event.dart';
import '../../application/fuel/delete_fuel_event.dart';
import '../../application/fuel/update_fuel_event.dart';
import '../../domain/fuel/fuel_cycle.dart';
import '../../domain/odometer/odometer_value.dart';
import '../theme/app_theme.dart';
import 'fuel_event_form_screen.dart';
import 'fuel_formatters.dart';

class FuelEventDetailsScreen extends StatelessWidget {
  const FuelEventDetailsScreen({
    super.key,
    required this.event,
    required this.createFuelEvent,
    required this.updateFuelEvent,
    required this.deleteFuelEvent,
  });

  final FuelEventSnapshot event;
  final CreateFuelEvent createFuelEvent;
  final UpdateFuelEvent updateFuelEvent;
  final DeleteFuelEvent deleteFuelEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Event'),
        actions: [
          IconButton(
            key: const Key('edit-fuel-event'),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.isFullTank ? 'FULL TANK' : 'NOT FULL · PARTIAL',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.fuelBrand,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Value(
                    label: 'ODOMETER',
                    value: '${formatOdometerKm(event.odometerKm)} km',
                  ),
                  _Value(
                    label: 'FUEL ADDED',
                    value:
                        '${formatLitresFromMillilitres(event.fuelVolumeMillilitres)} L',
                  ),
                  _Value(
                    label: 'TOTAL COST',
                    value: formatRinggitFromSen(event.costSen),
                  ),
                  _Value(
                    label: 'OCCURRED',
                    value: formatFuelDateTime(event.occurredAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF28171C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CAUTION',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.isFullTank
                      ? 'This is a Full Tank boundary. Deleting it will merge '
                            'and recalculate the surrounding fuel cycles.'
                      : 'Deleting this partial event removes its litres and cost '
                            'from the containing cycle.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('delete-fuel-event'),
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Fuel Event'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (formContext) => FuelEventFormScreen(
          vehicleId: event.vehicleId,
          createFuelEvent: createFuelEvent,
          updateFuelEvent: updateFuelEvent,
          initialEvent: event,
          onSaved: (_) => Navigator.pop(formContext, true),
        ),
      ),
    );
    if (changed == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Fuel Event?'),
        content: Text(
          event.isFullTank
              ? 'This is a Full Tank boundary. Deleting it will merge and '
                    'recalculate the surrounding fuel cycles.'
              : 'This removes the event and recalculates its fuel cycle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Fuel Event'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await deleteFuelEvent(event.id);
    if (context.mounted) Navigator.pop(context, true);
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
