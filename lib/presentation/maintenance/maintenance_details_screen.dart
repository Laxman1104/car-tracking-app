import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/maintenance/maintenance_record_service.dart';
import '../../application/maintenance/service_calendar_launcher.dart';
import '../../data/database/app_database.dart';
import '../../data/database/schema.dart';
import '../../domain/odometer/odometer_value.dart';
import '../fuel/fuel_formatters.dart';
import '../theme/app_theme.dart';
import 'maintenance_form_screen.dart';
import 'maintenance_formatters.dart';

class MaintenanceDetailsScreen extends StatefulWidget {
  const MaintenanceDetailsScreen({
    super.key,
    required this.recordId,
    required this.service,
    required this.fileStore,
    this.readOnly = false,
    this.calendarLauncher = const PlatformServiceCalendarLauncher(),
  });

  final int recordId;
  final MaintenanceRecordService service;
  final AttachmentFileStore fileStore;
  final bool readOnly;
  final ServiceCalendarLauncher calendarLauncher;

  @override
  State<MaintenanceDetailsScreen> createState() =>
      _MaintenanceDetailsScreenState();
}

class _MaintenanceDetailsScreenState extends State<MaintenanceDetailsScreen> {
  late Future<MaintenanceRecordBundle?> _record;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _record = widget.service.loadRecord(widget.recordId);
  }

  Future<void> _reload() async {
    final future = widget.service.loadRecord(widget.recordId);
    setState(() {
      _record = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: FutureBuilder<MaintenanceRecordBundle?>(
        future: _record,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final bundle = snapshot.data;
          if (bundle == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Record Details')),
              body: const Center(child: Text('This record no longer exists.')),
            );
          }
          return _DetailsBody(
            bundle: bundle,
            fileStore: widget.fileStore,
            onEdit: widget.readOnly ? null : () => _edit(bundle),
            onDelete: widget.readOnly ? null : () => _delete(bundle),
            onAddToCalendar:
                !widget.readOnly &&
                    bundle.reminder?.completedAt == null &&
                    bundle.reminder?.targetDate != null
                ? () => _addToCalendar(bundle)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _edit(MaintenanceRecordBundle bundle) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          vehicleId: bundle.record.vehicleId,
          service: widget.service,
          initialRecord: bundle,
        ),
      ),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _reload();
    }
  }

  Future<void> _delete(MaintenanceRecordBundle bundle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Maintenance Record?'),
        content: const Text(
          'This removes this record and its attachments. The shared odometer '
          'and active service reminder will be recalculated from the records '
          'that remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Record'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.service.delete(bundle.record.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addToCalendar(MaintenanceRecordBundle bundle) async {
    final reminder = bundle.reminder;
    final targetDate = reminder?.targetDate;
    if (reminder == null || targetDate == null) return;
    try {
      await widget.calendarLauncher.addServiceReminder(
        title: bundle.record.serviceTitle ?? 'Service reminder',
        targetDate: targetDate,
        targetOdometerKm: reminder.targetOdometerKm,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Calendar opened. Save the event to add this reminder.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open a calendar app.')),
        );
      }
    }
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.bundle,
    required this.fileStore,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToCalendar,
  });

  final MaintenanceRecordBundle bundle;
  final AttachmentFileStore fileStore;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final record = bundle.record;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          if (onEdit != null)
            IconButton(
              key: const Key('edit-maintenance-record'),
              onPressed: onEdit,
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
                    maintenanceCategoryLabel(record.category),
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.serviceTitle ??
                        (bundle.items.isEmpty
                            ? 'Maintenance Record'
                            : bundle.items.first.name),
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _Fact(
                          label: 'COST',
                          value: formatRinggitFromSen(record.totalCostSen),
                        ),
                      ),
                      if (record.category !=
                          MaintenanceCategory.accessories) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Fact(
                            label: 'ODOMETER',
                            value:
                                '${formatOdometerKm(record.odometerKm)} km',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Fact(
                          label: 'DATE & TIME',
                          value: formatMaintenanceDateTime(record.occurredAt),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Fact(
                          label: 'LOCATION',
                          value: record.workshop ?? '—',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (bundle.reminder case final reminder?) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.teal,
                ),
                title: Text(
                  (record.serviceTitle ?? 'Next whole service').toUpperCase(),
                ),
                subtitle: Text(
                  [
                    if (reminder.targetOdometerKm != null)
                      '${formatOdometerKm(reminder.targetOdometerKm!)} km',
                    if (reminder.targetDate != null)
                      formatMaintenanceDate(reminder.targetDate!.toLocal()),
                  ].join(' or '),
                ),
                trailing: onAddToCalendar == null
                    ? null
                    : IconButton(
                        key: const Key('details-add-reminder-to-calendar'),
                        tooltip: 'Add to calendar',
                        onPressed: onAddToCalendar,
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle('ITEMIZED WORK', count: bundle.items.length),
          const SizedBox(height: 8),
          if (bundle.items.isEmpty)
            const Text(
              'No line items recorded.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...bundle.items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 7),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: item.description == null
                      ? null
                      : Text(item.description!),
                  trailing: Text(formatRinggitFromSen(item.costSen)),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _SectionTitle(
            'ATTACHMENTS / RECEIPTS',
            count: bundle.attachments.length,
          ),
          const SizedBox(height: 8),
          if (bundle.attachments.isEmpty)
            const Text(
              'No attachments.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...bundle.attachments.map(
              (attachment) =>
                  _ReceiptTile(attachment: attachment, fileStore: fileStore),
            ),
          const SizedBox(height: 20),
          const _SectionTitle('NOTES'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 92),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              record.notes?.isNotEmpty == true
                  ? record.notes!
                  : 'No notes recorded.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 36),
          if (onDelete != null)
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
                  const Text(
                    'Delete only if this event should not exist. Its attachments '
                    'will also be removed.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('delete-maintenance-record'),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Record'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      if (count != null) ...[
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(color: AppColors.textMuted)),
      ],
    ],
  );
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.attachment, required this.fileStore});
  final Attachment attachment;
  final AttachmentFileStore fileStore;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(
        attachment.kind == AttachmentKind.pdf
            ? Icons.picture_as_pdf
            : Icons.image_outlined,
      ),
      title: Text(
        attachment.originalFileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatFileSize(attachment.byteSize)),
      onTap: () async {
        final path = await fileStore.absolutePath(attachment.relativePath);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _AttachmentPreview(path: path, attachment: attachment),
          ),
        );
      },
      trailing: IconButton(
        tooltip: 'Share or save a copy',
        onPressed: () async {
          final path = await fileStore.absolutePath(attachment.relativePath);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(path, mimeType: attachment.mimeType)],
              fileNameOverrides: [attachment.originalFileName],
              title: attachment.originalFileName,
            ),
          );
        },
        icon: const Icon(Icons.share_outlined),
      ),
    ),
  );
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.path, required this.attachment});
  final String path;
  final Attachment attachment;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(attachment.originalFileName)),
    body: attachment.kind == AttachmentKind.pdf
        ? PdfViewer.file(path)
        : InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(child: Image.file(File(path))),
          ),
  );
}
