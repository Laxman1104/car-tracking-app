import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/portability/data_portability_service.dart';
import '../theme/app_theme.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({
    super.key,
    required this.service,
    this.vehicleLifecycleBuilder,
  });
  final DataPortabilityService service;
  final WidgetBuilder? vehicleLifecycleBuilder;

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  String? _busy;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings & data')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _InfoPanel(),
        if (widget.vehicleLifecycleBuilder != null) ...[
          const SizedBox(height: 24),
          const Text(
            'VEHICLE',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            key: const Key('open-vehicle-lifecycle'),
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Lifecycle',
            subtitle: 'Retire this vehicle or view past vehicles.',
            enabled: _busy == null,
            onTap: _openVehicleLifecycle,
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'EXPORT & BACKUP',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          key: const Key('export-records-excel'),
          icon: Icons.table_view_outlined,
          title: 'Export Records (Excel)',
          subtitle: 'Four readable sheets. This file cannot restore the app.',
          enabled: _busy == null,
          onTap: () =>
              _export('Excel export', widget.service.createExcelExport),
        ),
        _ActionTile(
          key: const Key('export-maintenance-archive'),
          icon: Icons.folder_zip_outlined,
          title: 'Export Maintenance Archive',
          subtitle: 'Readable workbook plus receipt files.',
          enabled: _busy == null,
          onTap: () => _export(
            'Maintenance archive',
            widget.service.createMaintenanceArchive,
          ),
        ),
        _ActionTile(
          key: const Key('create-full-backup'),
          icon: Icons.backup_outlined,
          title: 'Create Full Backup',
          subtitle: 'Restorable structured data and all attachments.',
          enabled: _busy == null,
          onTap: () => _export('Full backup', widget.service.createFullBackup),
        ),
        const SizedBox(height: 18),
        const Text(
          'RESTORE',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _ActionTile(
          key: const Key('restore-full-backup'),
          icon: Icons.restore_outlined,
          title: 'Restore Full Backup',
          subtitle: 'Validates the ZIP before replacing local app data.',
          enabled: _busy == null,
          onTap: _restore,
        ),
        if (_busy != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(_busy!),
            ],
          ),
        ],
      ],
    ),
  );

  Future<void> _openVehicleLifecycle() async {
    final builder = widget.vehicleLifecycleBuilder;
    if (builder == null) return;
    final newVehicleId = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: builder),
    );
    if (newVehicleId != null && mounted) {
      Navigator.pop(context, newVehicleId);
    }
  }

  Future<void> _export(
    String label,
    Future<PortableFile> Function({DateTime? createdAt}) create,
  ) async {
    setState(() => _busy = 'Creating $label…');
    try {
      final output = await create();
      final directory = await getTemporaryDirectory();
      final file = File(p.join(directory.path, output.fileName));
      await file.writeAsBytes(output.bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          fileNameOverrides: [output.fileName],
          title: output.fileName,
        ),
      );
    } catch (error) {
      if (mounted) _message('Could not create $label: $error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (picked == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text(
          'After validation, the backup will replace the records currently stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Validate & Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = 'Validating backup…');
    try {
      final bytes = picked.path == null
          ? null
          : await File(picked.path!).readAsBytes();
      if (bytes == null) {
        throw const BackupValidationException(
          'The selected file could not be read.',
        );
      }
      final result = await widget.service.restoreFullBackup(
        Uint8List.fromList(bytes),
      );
      if (mounted) {
        _message(
          'Restore complete: ${result.fuelEventCount} fuel events, '
          '${result.maintenanceRecordCount} maintenance records.',
        );
      }
    } on BackupValidationException catch (error) {
      if (mounted) {
        _message(error.message);
      }
    } catch (error) {
      if (mounted) {
        _message('Restore failed without changing your data: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: const Padding(
      padding: EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: AppColors.teal),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your records remain local. Exports and backups are created only when you request them.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
