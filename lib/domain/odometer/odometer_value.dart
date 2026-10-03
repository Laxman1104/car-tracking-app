import '../validation/scaled_decimal.dart';

double? parseOdometerKm(String input) {
  final tenths = ScaledDecimalParser.parse(input, fractionDigits: 1);
  return tenths == null ? null : tenths / 10;
}

String formatOdometerKm(num value, {bool grouped = true}) {
  final parts = value.toStringAsFixed(1).split('.');
  final whole = grouped
      ? parts.first.replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        )
      : parts.first;
  return '$whole.${parts.last}';
}
