import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../theme/app_theme.dart';
import 'vehicle_setup_screen.dart';

typedef PastVehicleDestination = Widget Function(
  BuildContext context,
  Vehicle vehicle,
);

class VehicleLifecycleScreen extends StatefulWidget {
  const VehicleLifecycleScreen({
    super.key,
    required this.currentVehicle,
    required this.vehicles,
    required this.pastFuelBuilder,
    required this.pastMaintenanceBuilder,
    required this.pastAnalyticsBuilder,
    required this.deletePastVehicle,
    required this.onVehicleRetired,
  });

  final Vehicle currentVehicle;
  final VehicleRepository vehicles;
  final PastVehicleDestination pastFuelBuilder;
  final PastVehicleDestination pastMaintenanceBuilder;
  final PastVehicleDestination pastAnalyticsBuilder;
  final Future<void> Function(int vehicleId) deletePastVehicle;
  final Future<void> Function(int vehicleId) onVehicleRetired;

  @override
  State<VehicleLifecycleScreen> createState() => _VehicleLifecycleScreenState();
}

class _VehicleLifecycleScreenState extends State<VehicleLifecycleScreen> {
  late Future<List<Vehicle>> _pastVehicles;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pastVehicles = widget.vehicles.findRetired();
  }

  Future<void> _reloadPastVehicles() async {
    final future = widget.vehicles.findRetired();
    setState(() {
      _pastVehicles = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vehicle lifecycle')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _SectionLabel('CURRENT VEHICLE'),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF173033),
              child: Icon(Icons.directions_car_outlined, color: AppColors.teal),
            ),
            title: Text(
              widget.currentVehicle.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Starting odometer: '
              '${widget.currentVehicle.startingOdometerKm} km',
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const Key('retire-start-new-vehicle'),
          onPressed: _saving ? null : _startRetirement,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Retire Current / Start New Vehicle'),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('PAST VEHICLES'),
        const SizedBox(height: 10),
        FutureBuilder<List<Vehicle>>(
          future: _pastVehicles,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final vehicles = snapshot.data ?? const <Vehicle>[];
            if (vehicles.isEmpty) {
              return const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'No past vehicles yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return Column(
              children: vehicles
                  .map(
                    (vehicle) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        key: Key('past-vehicle-${vehicle.id}'),
                        leading: const Icon(
                          Icons.history,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(vehicle.displayName),
                        subtitle: const Text('Archived · Read-only'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final deleted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _PastVehicleScreen(
                                vehicle: vehicle,
                                fuelBuilder: widget.pastFuelBuilder,
                                maintenanceBuilder:
                                    widget.pastMaintenanceBuilder,
                                analyticsBuilder: widget.pastAnalyticsBuilder,
                                deleteVehicle: widget.deletePastVehicle,
                              ),
                            ),
                          );
                          if (deleted == true && mounted) {
                            await _reloadPastVehicles();
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );

  Future<void> _startRetirement() async {
    final setup = await showModalBottomSheet<VehicleSetupData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: VehicleSetupForm(
              title: 'Set up new vehicle',
              submitLabel: 'Continue',
              onCancel: () => Navigator.pop(sheetContext),
              onSubmit: (value) => Navigator.pop(sheetContext, value),
            ),
          ),
        ),
      ),
    );
    if (setup == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retire current vehicle?'),
        content: Text(
          '${widget.currentVehicle.displayName} and all its records will remain '
          'available under Past Vehicles as read-only. ${setup.name} will '
          'become the only active vehicle with a fresh, independent history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-retire-vehicle'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retire & Start New'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toUtc();
      final newId = await widget.vehicles.retireAndCreate(
        activeVehicleId: widget.currentVehicle.id,
        retiredAt: now,
        newVehicle: VehiclesCompanion.insert(
          displayName: setup.name,
          registrationNumber: Value(setup.registrationNumber),
          startingOdometerKm: Value(setup.startingOdometerKm),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await widget.onVehicleRetired(widget.currentVehicle.id);
      if (mounted) Navigator.pop(context, newId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change vehicles: $error')),
      );
    }
  }
}

class _PastVehicleScreen extends StatefulWidget {
  const _PastVehicleScreen({
    required this.vehicle,
    required this.fuelBuilder,
    required this.maintenanceBuilder,
    required this.analyticsBuilder,
    required this.deleteVehicle,
  });

  final Vehicle vehicle;
  final PastVehicleDestination fuelBuilder;
  final PastVehicleDestination maintenanceBuilder;
  final PastVehicleDestination analyticsBuilder;
  final Future<void> Function(int vehicleId) deleteVehicle;

  @override
  State<_PastVehicleScreen> createState() => _PastVehicleScreenState();
}

class _PastVehicleScreenState extends State<_PastVehicleScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.vehicle.displayName)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          margin: EdgeInsets.only(bottom: 18),
          child: ListTile(
            leading: Icon(Icons.lock_outline, color: AppColors.teal),
            title: Text('Archived vehicle'),
            subtitle: Text('Its histories and analytics are read-only.'),
          ),
        ),
        _PastDestination(
          icon: Icons.local_gas_station_outlined,
          title: 'Fuel history',
          onTap: () => _open(context, widget.fuelBuilder),
        ),
        _PastDestination(
          icon: Icons.build_outlined,
          title: 'Maintenance history',
          onTap: () => _open(context, widget.maintenanceBuilder),
        ),
        _PastDestination(
          icon: Icons.bar_chart_outlined,
          title: 'Analytics',
          onTap: () => _open(context, widget.analyticsBuilder),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          key: const Key('delete-past-vehicle'),
          onPressed: _deleting ? null : _delete,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          icon: _deleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(_deleting ? 'Deleting…' : 'Delete Past Vehicle'),
        ),
      ],
    ),
  );

  void _open(BuildContext context, PastVehicleDestination builder) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => builder(context, widget.vehicle)),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete this vehicle?'),
        content: Text(
          '${widget.vehicle.displayName}, its fuel history, maintenance '
          'records, reminders, and attachments will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-past-vehicle'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.deleteVehicle(widget.vehicle.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete this vehicle: $error')),
      );
    }
  }
}

class _PastDestination extends StatelessWidget {
  const _PastDestination({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}
