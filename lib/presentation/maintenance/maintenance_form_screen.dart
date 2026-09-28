import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/maintenance/maintenance_record_service.dart';
import '../../data/database/app_database.dart';
import '../../data/database/schema.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/validation/scaled_decimal.dart';
import '../fuel/fuel_formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/fixed_decimal_input_formatter.dart';
import 'maintenance_formatters.dart';

typedef MaintenanceSaved = void Function(int recordId);
typedef MaintenanceAttachmentPicker =
    Future<List<MaintenanceAttachmentInput>> Function();

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({
    super.key,
    required this.vehicleId,
    required this.service,
    this.initialRecord,
    this.initialOccurredAt,
    this.onSaved,
    this.attachmentPicker,
  });

  final int vehicleId;
  final MaintenanceRecordService service;
  final MaintenanceRecordBundle? initialRecord;
  final DateTime? initialOccurredAt;
  final MaintenanceSaved? onSaved;
  final MaintenanceAttachmentPicker? attachmentPicker;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _workshop = TextEditingController();
  final _totalCost = TextEditingController(text: '0.00');
  final _notes = TextEditingController();
  final _nextOdometer = TextEditingController();
  final _items = <MaintenanceItemInput>[];
  final _newAttachments = <MaintenanceAttachmentInput>[];
  final _existingAttachments = <Attachment>[];
  late DateTime _occurredAt;
  DateTime? _nextServiceDate;
  MaintenanceCategory _category = MaintenanceCategory.service;
  String? _chronologyError;
  bool _saving = false;
  bool _pickingAttachment = false;

  bool get _editing => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    if (initial == null) {
      _occurredAt = widget.initialOccurredAt ?? DateTime.now();
    } else {
      final record = initial.record;
      _occurredAt = record.occurredAt.toLocal();
      _category = record.category;
      _odometer.text = record.odometerKm.toString();
      _workshop.text = record.workshop ?? '';
      _totalCost.text = decimalFromScaled(record.totalCostSen, 2);
      _notes.text = record.notes ?? '';
      _items.addAll(
        initial.items.map(
          (item) => MaintenanceItemInput(
            name: item.name,
            description: item.description,
            costSen: item.costSen,
          ),
        ),
      );
      _existingAttachments.addAll(initial.attachments);
      _nextServiceDate = initial.reminder?.targetDate?.toLocal();
      if (initial.reminder?.targetOdometerKm case final target?) {
        _nextOdometer.text = target.toString();
      }
    }
  }

  @override
  void dispose() {
    _odometer.dispose();
    _workshop.dispose();
    _totalCost.dispose();
    _notes.dispose();
    _nextOdometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = ScaledDecimalParser.parse(_totalCost.text, fractionDigits: 2);
    final itemsTotal = _items.fold<int>(0, (sum, item) => sum + item.costSen);
    final difference = total == null ? null : total - itemsTotal;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit Maintenance Record' : 'Maintenance Record',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const _Label('SERVICE CATEGORY *'),
            const SizedBox(height: 8),
            SegmentedButton<MaintenanceCategory>(
              key: const Key('maintenance-category'),
              segments: MaintenanceCategory.values
                  .map(
                    (category) => ButtonSegment(
                      value: category,
                      label: Text(maintenanceCategoryLabel(category)),
                    ),
                  )
                  .toList(),
              selected: {_category},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() {
                _category = selection.single;
                if (_category != MaintenanceCategory.service) {
                  _nextServiceDate = null;
                  _nextOdometer.clear();
                }
              }),
            ),
            const SizedBox(height: 22),
            const _Label('ODOMETER *'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('maintenance-odometer'),
              controller: _odometer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.speed_outlined),
                suffixText: 'km',
              ),
              onChanged: (_) {
                if (_chronologyError != null) {
                  setState(() => _chronologyError = null);
                }
              },
              validator: (value) {
                if (_chronologyError != null) return _chronologyError;
                if (int.tryParse(value ?? '') == null) {
                  return 'Enter a whole odometer reading.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _Label('WORKSHOP / SERVICE CENTRE *'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('maintenance-workshop'),
              controller: _workshop,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a workshop or service centre.'
                  : null,
            ),
            const SizedBox(height: 22),
            const _Label('DATE & TIME *'),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('maintenance-date-time'),
              tileColor: AppColors.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(formatMaintenanceDateTime(_occurredAt)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickOccurrence,
            ),
            const SizedBox(height: 22),
            const _Label('TOTAL VISIT COST *'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('maintenance-total-cost'),
              controller: _totalCost,
              keyboardType: TextInputType.number,
              inputFormatters: const [FixedDecimalInputFormatter()],
              decoration: const InputDecoration(prefixText: 'RM '),
              onChanged: (_) => setState(() {}),
              validator: (value) =>
                  ScaledDecimalParser.parse(value ?? '', fractionDigits: 2) ==
                      null
                  ? 'Enter a valid total cost.'
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: _Label('ITEMIZED WORK')),
                Text(
                  '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Card(
                key: Key('maintenance-item-$index'),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: item.description == null
                      ? null
                      : Text(item.description!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatRinggitFromSen(item.costSen)),
                      PopupMenuButton<_ItemAction>(
                        tooltip: 'Line item actions',
                        onSelected: (action) =>
                            _handleItemAction(index, action),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: _ItemAction.edit,
                            child: Text('Edit'),
                          ),
                          if (index > 0)
                            const PopupMenuItem(
                              value: _ItemAction.moveUp,
                              child: Text('Move up'),
                            ),
                          if (index < _items.length - 1)
                            const PopupMenuItem(
                              value: _ItemAction.moveDown,
                              child: Text('Move down'),
                            ),
                          const PopupMenuItem(
                            value: _ItemAction.remove,
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _editItem(index),
                  onLongPress: () => setState(() => _items.removeAt(index)),
                ),
              );
            }),
            OutlinedButton.icon(
              key: const Key('add-maintenance-item'),
              onPressed: () => _editItem(null),
              icon: const Icon(Icons.add),
              label: const Text('Add line item'),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                difference == 0
                    ? 'Item total matches ${formatRinggitFromSen(total!)}.'
                    : 'Items: ${formatRinggitFromSen(itemsTotal)} · '
                          'Difference: ${formatRinggitFromSen(difference!.abs())}',
                key: const Key('maintenance-item-difference'),
                style: TextStyle(
                  color: difference == 0 ? AppColors.teal : AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
            if (_category == MaintenanceCategory.service) ...[
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('NEXT WHOLE-SERVICE TARGET'),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('next-service-odometer'),
                        controller: _nextOdometer,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Optional target mileage',
                          suffixText: 'km',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        key: const Key('next-service-date'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _nextServiceDate == null
                              ? 'Optional target date'
                              : formatMaintenanceDate(_nextServiceDate!),
                        ),
                        leading: const Icon(Icons.event_outlined),
                        trailing: _nextServiceDate == null
                            ? const Icon(Icons.add)
                            : IconButton(
                                onPressed: () =>
                                    setState(() => _nextServiceDate = null),
                                icon: const Icon(Icons.close),
                              ),
                        onTap: _pickNextServiceDate,
                      ),
                      const Text(
                        'If both are entered, whichever comes first applies.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _Label('ATTACHMENTS & RECEIPTS'),
            const SizedBox(height: 8),
            ..._existingAttachments.map(
              (attachment) => _AttachmentTile(
                name: attachment.originalFileName,
                size: attachment.byteSize,
                kind: attachment.kind,
                onRemove: () =>
                    setState(() => _existingAttachments.remove(attachment)),
              ),
            ),
            ..._newAttachments.map(
              (attachment) => _AttachmentTile(
                name: attachment.fileName,
                size: attachment.byteSize,
                kind: attachment.kind,
                onRemove: () =>
                    setState(() => _newAttachments.remove(attachment)),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('add-maintenance-attachment'),
              onPressed: _pickingAttachment ? null : _pickAttachments,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _pickingAttachment ? 'Opening files…' : 'Add photos or PDFs',
              ),
            ),
            const SizedBox(height: 24),
            const _Label('NOTES'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('maintenance-notes'),
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Optional notes or technician remarks',
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              key: const Key('save-maintenance-record'),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Saving…' : 'Save Maintenance Record'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editItem(int? index) async {
    final existing = index == null ? null : _items[index];
    final name = TextEditingController(text: existing?.name);
    final description = TextEditingController(text: existing?.description);
    final cost = TextEditingController(
      text: decimalFromScaled(existing?.costSen ?? 0, 2),
    );
    final result = await showDialog<MaintenanceItemInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? 'Add line item' : 'Edit line item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('maintenance-item-name'),
                controller: name,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('maintenance-item-description'),
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Action / description',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('maintenance-item-cost'),
                controller: cost,
                keyboardType: TextInputType.number,
                inputFormatters: const [FixedDecimalInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  prefixText: 'RM ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (index != null)
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                const MaintenanceItemInput(name: '', costSen: -1),
              ),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = ScaledDecimalParser.parse(
                cost.text,
                fractionDigits: 2,
              );
              if (name.text.trim().isEmpty || parsed == null) return;
              Navigator.pop(
                context,
                MaintenanceItemInput(
                  name: name.text.trim(),
                  description: description.text.trim().isEmpty
                      ? null
                      : description.text.trim(),
                  costSen: parsed,
                ),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
    name.dispose();
    description.dispose();
    cost.dispose();
    if (!mounted || result == null) return;
    setState(() {
      if (result.costSen < 0) {
        _items.removeAt(index!);
      } else if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  void _handleItemAction(int index, _ItemAction action) {
    switch (action) {
      case _ItemAction.edit:
        _editItem(index);
      case _ItemAction.moveUp:
        setState(() {
          final item = _items.removeAt(index);
          _items.insert(index - 1, item);
        });
      case _ItemAction.moveDown:
        setState(() {
          final item = _items.removeAt(index);
          _items.insert(index + 1, item);
        });
      case _ItemAction.remove:
        setState(() => _items.removeAt(index));
    }
  }

  Future<void> _pickAttachments() async {
    setState(() => _pickingAttachment = true);
    try {
      final picked = await (widget.attachmentPicker ?? _defaultPicker)();
      if (mounted) setState(() => _newAttachments.addAll(picked));
    } finally {
      if (mounted) setState(() => _pickingAttachment = false);
    }
  }

  Future<List<MaintenanceAttachmentInput>> _defaultPicker() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final inputs = <MaintenanceAttachmentInput>[];
    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      final extension = file.extension?.toLowerCase();
      final isPdf = extension == 'pdf';
      inputs.add(
        MaintenanceAttachmentInput(
          sourcePath: path,
          fileName: file.name,
          kind: isPdf ? AttachmentKind.pdf : AttachmentKind.image,
          mimeType: isPdf ? 'application/pdf' : 'image/${extension ?? 'jpeg'}',
          byteSize: (file.lengthSync() ?? await file.length()) ?? 0,
        ),
      );
    }
    return inputs;
  }

  Future<void> _pickOccurrence() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(1),
      lastDate: DateTime(9999),
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
  }

  Future<void> _pickNextServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _nextServiceDate ?? _occurredAt.add(const Duration(days: 180)),
      firstDate: _occurredAt,
      lastDate: DateTime(9999),
    );
    if (picked != null && mounted) setState(() => _nextServiceDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final input = MaintenanceRecordInput(
        vehicleId: widget.vehicleId,
        occurredAt: _occurredAt,
        odometerKm: int.parse(_odometer.text),
        category: _category,
        workshop: _workshop.text,
        totalCostSen: ScaledDecimalParser.parse(
          _totalCost.text,
          fractionDigits: 2,
        )!,
        items: List.unmodifiable(_items),
        notes: _notes.text,
        nextServiceDate: _category == MaintenanceCategory.service
            ? _nextServiceDate
            : null,
        nextServiceOdometerKm:
            _category == MaintenanceCategory.service &&
                _nextOdometer.text.isNotEmpty
            ? int.parse(_nextOdometer.text)
            : null,
        newAttachments: List.unmodifiable(_newAttachments),
        retainedAttachmentIds: _existingAttachments.map((e) => e.id).toSet(),
      );
      final id = widget.initialRecord == null
          ? await widget.service.create(input)
          : widget.initialRecord!.record.id;
      if (widget.initialRecord != null) {
        await widget.service.update(id, input);
      }
      if (!mounted) return;
      widget.onSaved?.call(id);
      if (widget.onSaved == null) Navigator.pop(context, true);
    } on MaintenanceRecordException catch (error) {
      if (!mounted) return;
      if (error.issue == MaintenanceRecordIssue.odometerChronologyConflict) {
        setState(() => _chronologyError = error.message);
        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.name,
    required this.size,
    required this.kind,
    required this.onRemove,
  });

  final String name;
  final int size;
  final AttachmentKind kind;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(
        kind == AttachmentKind.pdf
            ? Icons.picture_as_pdf
            : Icons.image_outlined,
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatFileSize(size)),
      trailing: IconButton(
        tooltip: 'Remove attachment',
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    ),
  );
}

enum _ItemAction { edit, moveUp, moveDown, remove }
