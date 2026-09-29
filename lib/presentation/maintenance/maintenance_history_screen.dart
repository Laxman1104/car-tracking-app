import 'package:flutter/material.dart';

import '../../application/maintenance/maintenance_record_service.dart';
import '../../domain/maintenance/maintenance.dart';
import '../fuel/fuel_formatters.dart';
import '../theme/app_theme.dart';
import 'maintenance_details_screen.dart';
import 'maintenance_form_screen.dart';
import 'maintenance_formatters.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  const MaintenanceHistoryScreen({
    super.key,
    required this.vehicleId,
    required this.service,
    required this.fileStore,
    this.readOnly = false,
  });

  final int vehicleId;
  final MaintenanceRecordService service;
  final AttachmentFileStore fileStore;
  final bool readOnly;

  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  late Future<MaintenanceHistoryData> _history;
  MaintenanceCategory? _filter;

  @override
  void initState() {
    super.initState();
    _history = widget.service.loadHistory(widget.vehicleId);
  }

  Future<void> _reload() async {
    final future = widget.service.loadHistory(widget.vehicleId);
    setState(() {
      _history = future;
    });
    await future;
  }

  Future<void> _openForm([MaintenanceRecordBundle? initial]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          vehicleId: widget.vehicleId,
          service: widget.service,
          initialRecord: initial,
        ),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _openDetails(MaintenanceRecordBundle bundle) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaintenanceDetailsScreen(
          recordId: bundle.record.id,
          service: widget.service,
          fileStore: widget.fileStore,
          readOnly: widget.readOnly,
        ),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _markReminderDone(int maintenanceRecordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark reminder as done?'),
        content: const Text(
          'This removes it from active and upcoming reminders while keeping '
          'the original service record in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as done'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.service.markReminderDone(maintenanceRecordId);
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance History')),
      floatingActionButton: widget.readOnly
          ? null
          : FloatingActionButton(
              key: const Key('add-maintenance-record-fab'),
              onPressed: _openForm,
              tooltip: 'Add Maintenance Record',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              child: const Icon(Icons.add),
            ),
      body: FutureBuilder<MaintenanceHistoryData>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry maintenance history'),
              ),
            );
          }
          final data = snapshot.requireData;
          final records = data.records
              .where(
                (entry) => _filter == null || entry.record.category == _filter,
              )
              .toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              key: const Key('maintenance-history-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _ReminderCard(
                  data: data,
                  onMarkDone: widget.readOnly ? null : _markReminderDone,
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        count: data.records.length,
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      ...MaintenanceCategory.values.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: maintenanceCategoryLabel(category),
                            count: data.records
                                .where((e) => e.record.category == category)
                                .length,
                            selected: _filter == category,
                            onTap: () => setState(() => _filter = category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (records.isEmpty)
                  const _EmptyState()
                else
                  ...records.map(
                    (bundle) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(
                        bundle: bundle,
                        onTap: () => _openDetails(bundle),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.data, required this.onMarkDone});
  final MaintenanceHistoryData data;
  final Future<void> Function(int maintenanceRecordId)? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final reminder = data.activeReminder;
    if (reminder == null) {
      return Card(
        key: const Key('inactive-service-reminder'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'SERVICE REMINDER · INACTIVE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'No Upcoming Service Scheduled',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Current odometer: ${data.currentOdometerKm?.toString() ?? '—'} km',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final target = ServiceReminderTarget(
      vehicleId: reminder.vehicleId,
      maintenanceRecordId: reminder.maintenanceRecordId,
      targetDate: reminder.targetDate,
      targetOdometerKm: reminder.targetOdometerKm,
    );
    final evaluation = const MaintenanceDomainService().evaluateReminder(
      reminder: target,
      now: DateTime.now().toUtc(),
      currentOdometerKm: data.currentOdometerKm ?? 0,
    );
    final sourceRecord = data.records
        .where((bundle) => bundle.record.id == reminder.maintenanceRecordId)
        .firstOrNull;
    final sourceOdometer = sourceRecord?.record.odometerKm;
    final targetOdometer = reminder.targetOdometerKm;
    double? mileageProgress;
    if (sourceOdometer != null &&
        targetOdometer != null &&
        targetOdometer > sourceOdometer) {
      mileageProgress =
          ((data.currentOdometerKm ?? sourceOdometer) - sourceOdometer) /
          (targetOdometer - sourceOdometer);
      mileageProgress = mileageProgress.clamp(0, 1);
    }
    final parts = <String>[
      if (reminder.targetOdometerKm != null) '${reminder.targetOdometerKm} km',
      if (reminder.targetDate != null)
        formatMaintenanceDate(reminder.targetDate!.toLocal()),
    ];
    return Card(
      key: const Key('active-service-reminder'),
      margin: EdgeInsets.zero,
      color: const Color(0xFF173033),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (data.activeReminderTitle ?? 'Next whole service')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  evaluation.isDue ? 'DUE' : 'UPCOMING',
                  style: TextStyle(
                    color: evaluation.isDue
                        ? AppColors.warning
                        : AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              parts.join(' or '),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (parts.length == 2) ...[
              const SizedBox(height: 6),
              const Text(
                'Whichever comes first',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (mileageProgress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: mileageProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 7),
              Text(
                '${(mileageProgress * 100).floor()}% toward mileage target · '
                'alerts at 80%, 90%, and 100%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (onMarkDone != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('mark-service-reminder-done'),
                  onPressed: () => onMarkDone!(reminder.maintenanceRecordId),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as done'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text('$label  $count'),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.bundle, required this.onTap});
  final MaintenanceRecordBundle bundle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = bundle.record;
    final title =
        record.serviceTitle ??
        (bundle.items.isEmpty
            ? '${maintenanceCategoryLabel(record.category)} record'
            : bundle.items.first.name);
    final itemSummary = bundle.items
        .map((item) => item.name)
        .take(3)
        .join(', ');
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: Key('maintenance-record-${record.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryChip(category: record.category),
                  const SizedBox(width: 10),
                  Text(
                    formatMaintenanceDate(record.occurredAt.toLocal()),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    formatRinggitFromSen(record.totalCostSen),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                record.workshop ?? 'Workshop not recorded',
                style: const TextStyle(color: AppColors.teal, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (itemSummary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  itemSummary,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${record.odometerKm} km',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (bundle.attachments.isNotEmpty)
                    Text(
                      '${bundle.attachments.length} attachment${bundle.attachments.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  const Icon(
                    Icons.chevron_right,
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
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final MaintenanceCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category == MaintenanceCategory.service
        ? AppColors.teal
        : category == MaintenanceCategory.repairs
        ? AppColors.textSecondary
        : const Color(0xFFAFC6FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        maintenanceCategoryLabel(category).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('maintenance-empty-state'),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.home_repair_service_outlined,
            color: AppColors.teal,
            size: 52,
          ),
          const SizedBox(height: 18),
          const Text(
            'No Maintenance Records',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use + to record a service, repair, or accessory.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
