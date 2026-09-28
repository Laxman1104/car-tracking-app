String formatFuelDate(DateTime value) {
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

String formatFuelDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatFuelDate(local)} · $hour:$minute';
}

String formatRinggitFromSen(int sen) => 'RM${(sen / 100).toStringAsFixed(2)}';

String formatLitresFromMillilitres(int millilitres) {
  return (millilitres / 1000).toStringAsFixed(2);
}

String formatEfficiency(double? value) {
  return value == null ? '—' : value.toStringAsFixed(2);
}

String formatCostPerKm(double? value) {
  return value == null ? '—' : 'RM${value.toStringAsFixed(3)}';
}
