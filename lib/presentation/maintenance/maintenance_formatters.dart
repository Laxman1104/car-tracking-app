import '../../domain/maintenance/maintenance.dart';

String maintenanceCategoryLabel(MaintenanceCategory category) =>
    switch (category) {
      MaintenanceCategory.service => 'Service',
      MaintenanceCategory.repairs => 'Repairs',
      MaintenanceCategory.accessories => 'Accessories',
    };

String formatMaintenanceDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String formatMaintenanceDateTime(DateTime value) {
  final local = value.toLocal();
  return '${formatMaintenanceDate(local)} · '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String decimalFromScaled(int value, int fractionDigits) {
  final digits = value.toString().padLeft(fractionDigits + 1, '0');
  return '${digits.substring(0, digits.length - fractionDigits)}.'
      '${digits.substring(digits.length - fractionDigits)}';
}
