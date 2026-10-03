import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../application/maintenance/maintenance_record_service.dart';
import '../../data/database/app_database.dart';
import '../../data/database/schema.dart';
import '../../domain/maintenance/maintenance.dart';
import '../../domain/odometer/odometer_value.dart';
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
  final _odometer = TextEditingController(text: '0.0');
  final _workshop = TextEditingController();
  final _serviceTitle = TextEditingController();
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
      _odometer.text = formatOdometerKm(record.odometerKm, grouped: false);
      _workshop.text = record.workshop ?? '';
      _serviceTitle.text = record.serviceTitle ?? '';
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
        _nextOdometer.text = formatOdometerKm(target, grouped: false);
      }
    }
  }

  @override
  void dispose() {
    _odometer.dispose();
    _workshop.dispose();
    _serviceTitle.dispose();
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
            if (_category == MaintenanceCategory.service) ...[
              const _Label('SERVICE / REMINDER TITLE'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('maintenance-service-title'),
                controller: _serviceTitle,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  hintText: 'e.g. General Service or Tyre Rotation',
                ),
              ),
              const SizedBox(height: 22),
            ],
            const _Label('ODOMETER *'),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('maintenance-odometer'),
              controller: _odometer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                FixedDecimalInputFormatter(decimalPlaces: 1),
              ],
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
                if (parseOdometerKm(value ?? '') == null) {
                  return 'Enter an odometer reading to one decimal place.';
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [
                          FixedDecimalInputFormatter(decimalPlaces: 1),
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
    final result = await showModalBottomSheet<_MaintenanceItemEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaintenanceItemEditorSheet(
        existing: existing,
        canRemove: index != null,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.remove) {
        _items.removeAt(index!);
      } else if (index == null) {
        _items.add(result.item!);
      } else {
        _items[index] = result.item!;
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
        odometerKm: parseOdometerKm(_odometer.text)!,
        category: _category,
        workshop: _workshop.text,
        totalCostSen: ScaledDecimalParser.parse(
          _totalCost.text,
          fractionDigits: 2,
        )!,
        items: List.unmodifiable(_items),
        serviceTitle: _category == MaintenanceCategory.service
            ? _serviceTitle.text
            : null,
        notes: _notes.text,
        nextServiceDate: _category == MaintenanceCategory.service
            ? _nextServiceDate
            : null,
        nextServiceOdometerKm:
            _category == MaintenanceCategory.service &&
                _nextOdometer.text.isNotEmpty
            ? parseOdometerKm(_nextOdometer.text)
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

class _MaintenanceItemEditorResult {
  const _MaintenanceItemEditorResult.save(this.item) : remove = false;
  const _MaintenanceItemEditorResult.remove() : item = null, remove = true;

  final MaintenanceItemInput? item;
  final bool remove;
}

class _MaintenanceItemEditorSheet extends StatefulWidget {
  const _MaintenanceItemEditorSheet({
    required this.existing,
    required this.canRemove,
  });

  final MaintenanceItemInput? existing;
  final bool canRemove;

  @override
  State<_MaintenanceItemEditorSheet> createState() =>
      _MaintenanceItemEditorSheetState();
}

class _MaintenanceItemEditorSheetState
    extends State<_MaintenanceItemEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _cost;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name);
    _description = TextEditingController(text: widget.existing?.description);
    _cost = TextEditingController(
      text: decimalFromScaled(widget.existing?.costSen ?? 0, 2),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final description = _description.text.trim();
    Navigator.pop(
      context,
      _MaintenanceItemEditorResult.save(
        MaintenanceItemInput(
          name: _name.text.trim(),
          description: description.isEmpty ? null : description,
          costSen: ScaledDecimalParser.parse(_cost.text, fractionDigits: 2)!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top - 16;
    final maxHeight = availableHeight.clamp(0.0, media.size.height * 0.82);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? 'Add line item'
                              : 'Edit line item',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('maintenance-item-name'),
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Item name',
                            hintText: 'e.g. Engine oil',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter an item name.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('maintenance-item-description'),
                          controller: _description,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Action / description',
                            hintText: 'Optional details',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('maintenance-item-cost'),
                          controller: _cost,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: const [FixedDecimalInputFormatter()],
                          onFieldSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            labelText: 'Cost',
                            prefixText: 'RM ',
                          ),
                          validator: (value) =>
                              ScaledDecimalParser.parse(
                                    value ?? '',
                                    fractionDigits: 2,
                                  ) ==
                                  null
                              ? 'Enter a valid cost.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        if (widget.canRemove)
                          TextButton.icon(
                            onPressed: () => Navigator.pop(
                              context,
                              const _MaintenanceItemEditorResult.remove(),
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                          ),
                        if (widget.canRemove) const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            key: const Key('save-maintenance-item'),
                            onPressed: _save,
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
